import uuid
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, or_
from database import get_db
import models
from auth import get_current_user

router = APIRouter(prefix="/chats", tags=["chats"])


class SendMessageBody(BaseModel):
    text: str
    thread_id: str | None = None
    other_user_id: str | None = None
    listing_id: str | None = None


def _thread_dict(t: models.ChatThread, viewer_id: str, other: models.User | None) -> dict:
    return {
        "id": t.id, "listing_id": t.listing_id,
        "owner_id": t.owner_id, "worker_id": t.worker_id,
        "last_message": t.last_message,
        "unread": t.unread_owner if viewer_id == t.owner_id else t.unread_worker,
        "updated_at": t.updated_at.isoformat(),
        "other_name": f"{other.name} {other.surname}" if other else "",
        "other_photo": other.photo_url if other else "",
    }


def _msg_dict(m: models.ChatMessage) -> dict:
    return {
        "id": m.id, "thread_id": m.thread_id,
        "sender_id": m.sender_id, "text": m.text,
        "sent_at": m.sent_at.isoformat(),
    }


@router.get("")
async def my_threads(
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(models.ChatThread).where(
            or_(models.ChatThread.owner_id == user.id, models.ChatThread.worker_id == user.id)
        ).order_by(models.ChatThread.updated_at.desc())
    )
    out = []
    for t in result.scalars():
        other_id = t.worker_id if t.owner_id == user.id else t.owner_id
        ur = await db.execute(select(models.User).where(models.User.id == other_id))
        other = ur.scalar_one_or_none()
        out.append(_thread_dict(t, user.id, other))
    return out


@router.get("/{thread_id}/messages")
async def get_messages(
    thread_id: str,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    tr = await db.execute(select(models.ChatThread).where(models.ChatThread.id == thread_id))
    thread = tr.scalar_one_or_none()
    if not thread:
        raise HTTPException(404, "Söhbət tapılmadı")
    if thread.owner_id != user.id and thread.worker_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    if thread.owner_id == user.id and thread.unread_owner > 0:
        thread.unread_owner = 0
        await db.commit()
    elif thread.worker_id == user.id and thread.unread_worker > 0:
        thread.unread_worker = 0
        await db.commit()
    result = await db.execute(
        select(models.ChatMessage).where(models.ChatMessage.thread_id == thread_id)
        .order_by(models.ChatMessage.sent_at.asc())
    )
    return [_msg_dict(m) for m in result.scalars()]


@router.post("/send")
async def send_message(
    body: SendMessageBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not body.text.strip():
        raise HTTPException(400, "Mesaj boş ola bilməz")

    thread: models.ChatThread | None = None

    if body.thread_id:
        tr = await db.execute(select(models.ChatThread).where(models.ChatThread.id == body.thread_id))
        thread = tr.scalar_one_or_none()
        if not thread:
            raise HTTPException(404, "Söhbət tapılmadı")
    elif body.other_user_id:
        other_id = body.other_user_id
        tr = await db.execute(
            select(models.ChatThread).where(
                or_(
                    (models.ChatThread.owner_id == user.id) & (models.ChatThread.worker_id == other_id),
                    (models.ChatThread.owner_id == other_id) & (models.ChatThread.worker_id == user.id),
                )
            )
        )
        thread = tr.scalar_one_or_none()
        if not thread:
            thread = models.ChatThread(
                id=str(uuid.uuid4()),
                owner_id=user.id,
                worker_id=other_id,
                listing_id=body.listing_id,
            )
            db.add(thread)
            await db.flush()
    else:
        raise HTTPException(400, "thread_id və ya other_user_id tələb olunur")

    msg = models.ChatMessage(
        id=str(uuid.uuid4()),
        thread_id=thread.id,
        sender_id=user.id,
        text=body.text.strip(),
    )
    db.add(msg)

    thread.last_message = body.text.strip()[:100]
    thread.updated_at = datetime.utcnow()
    if thread.owner_id == user.id:
        thread.unread_worker += 1
    else:
        thread.unread_owner += 1

    await db.commit()
    await db.refresh(msg)
    return {"message": _msg_dict(msg), "thread_id": thread.id}
