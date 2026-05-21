import uuid
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from database import get_db
import models
from auth import get_current_user, require_admin, require_superadmin, hash_password

router = APIRouter(prefix="/admin", tags=["admin"])


# ── Users ──────────────────────────────────────────────────────────────────
@router.get("/users")
async def list_users(
    q: str = Query(""),
    limit: int = Query(100, le=500),
    _: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    stmt = select(models.User).order_by(models.User.created_at.desc()).limit(limit)
    result = await db.execute(stmt)
    users = result.scalars().all()
    if q:
        ql = q.lower()
        users = [u for u in users if ql in u.name.lower() or ql in u.surname.lower() or ql in u.email.lower()]
    return [_ud(u) for u in users]


@router.post("/users/{uid}/block")
async def block_user(
    uid: str,
    actor: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.User).where(models.User.id == uid))
    u = r.scalar_one_or_none()
    if not u:
        raise HTTPException(404, "İstifadəçi tapılmadı")
    u.is_blocked = not u.is_blocked
    await _log(db, actor.id, "block_toggle", uid, f"blocked={u.is_blocked}")
    await db.commit()
    return {"blocked": u.is_blocked}


@router.delete("/users/{uid}")
async def delete_user(
    uid: str,
    actor: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.User).where(models.User.id == uid))
    u = r.scalar_one_or_none()
    if not u:
        raise HTTPException(404, "İstifadəçi tapılmadı")
    await db.delete(u)
    await _log(db, actor.id, "delete_user", uid)
    await db.commit()
    return {"ok": True}


# ── Workers ─────────────────────────────────────────────────────────────────
@router.get("/workers")
async def list_workers(
    _: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.Worker))
    out = []
    for w in r.scalars():
        ur = await db.execute(select(models.User).where(models.User.id == w.id))
        u = ur.scalar_one_or_none()
        if u:
            out.append({**_ud(u), "rating": w.rating, "rating_count": w.rating_count, "availability": w.availability})
    return out


# ── Listings ─────────────────────────────────────────────────────────────────
@router.get("/listings")
async def list_listings(
    _: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.Listing).order_by(models.Listing.created_at.desc()).limit(200))
    return [_ld(j) for j in r.scalars()]


@router.delete("/listings/{listing_id}")
async def delete_listing(
    listing_id: str,
    actor: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.Listing).where(models.Listing.id == listing_id))
    j = r.scalar_one_or_none()
    if not j:
        raise HTTPException(404, "Elan tapılmadı")
    await db.delete(j)
    await _log(db, actor.id, "delete_listing", listing_id)
    await db.commit()
    return {"ok": True}


# ── Chats ─────────────────────────────────────────────────────────────────────
@router.get("/chats")
async def list_chats(
    _: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.ChatThread).order_by(models.ChatThread.updated_at.desc()).limit(100))
    return [
        {"id": t.id, "owner_id": t.owner_id, "worker_id": t.worker_id,
         "last_message": t.last_message, "updated_at": t.updated_at.isoformat()}
        for t in r.scalars()
    ]


# ── SuperAdmin only ───────────────────────────────────────────────────────────
class CreateAdminBody(BaseModel):
    name: str
    surname: str
    email: str
    password: str = "admin123"


@router.post("/create-admin")
async def create_admin(
    body: CreateAdminBody,
    actor: models.User = Depends(require_superadmin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.User).where(models.User.email == body.email.lower()))
    if r.scalar_one_or_none():
        raise HTTPException(400, "Bu e-poçt mövcuddur")
    u = models.User(
        id=str(uuid.uuid4()),
        name=body.name.strip(),
        surname=body.surname.strip(),
        email=body.email.lower().strip(),
        password_hash=hash_password(body.password),
        role="admin",
    )
    db.add(u)
    await _log(db, actor.id, "create_admin", u.id)
    await db.commit()
    return _ud(u)


@router.put("/users/{uid}/role")
async def change_role(
    uid: str,
    role: str,
    actor: models.User = Depends(require_superadmin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.User).where(models.User.id == uid))
    u = r.scalar_one_or_none()
    if not u:
        raise HTTPException(404)
    if role not in ("user", "worker", "admin", "superadmin"):
        raise HTTPException(400, "Yanlış rol")
    u.role = role
    await _log(db, actor.id, "change_role", uid, role)
    await db.commit()
    return _ud(u)


@router.get("/stats")
async def stats(
    _: models.User = Depends(require_admin),
    db: AsyncSession = Depends(get_db),
):
    users_count = (await db.execute(func.count(models.User.id))).scalar()
    workers_count = (await db.execute(func.count(models.Worker.id))).scalar()
    listings_count = (await db.execute(func.count(models.Listing.id))).scalar()
    chats_count = (await db.execute(func.count(models.ChatThread.id))).scalar()
    return {"users": users_count, "workers": workers_count, "listings": listings_count, "chats": chats_count}


@router.get("/audit-logs")
async def audit_logs(
    _: models.User = Depends(require_superadmin),
    db: AsyncSession = Depends(get_db),
):
    r = await db.execute(select(models.AuditLog).order_by(models.AuditLog.created_at.desc()).limit(200))
    return [
        {"id": l.id, "actor_id": l.actor_id, "action": l.action,
         "target_id": l.target_id, "detail": l.detail, "created_at": l.created_at.isoformat()}
        for l in r.scalars()
    ]


# ── helpers ──────────────────────────────────────────────────────────────────
def _ud(u: models.User) -> dict:
    return {
        "id": u.id, "name": u.name, "surname": u.surname,
        "email": u.email, "phone": u.phone, "role": u.role,
        "photo_url": u.photo_url, "is_blocked": u.is_blocked,
        "created_at": u.created_at.isoformat(),
    }


def _ld(j: models.Listing) -> dict:
    return {
        "id": j.id, "title": j.title, "category": j.category,
        "worker_id": j.worker_id, "min_price": j.min_price, "max_price": j.max_price,
        "is_active": j.is_active, "created_at": j.created_at.isoformat(),
    }


async def _log(db: AsyncSession, actor_id: str, action: str, target_id: str = "", detail: str = ""):
    log = models.AuditLog(id=str(uuid.uuid4()), actor_id=actor_id, action=action, target_id=target_id, detail=detail)
    db.add(log)
