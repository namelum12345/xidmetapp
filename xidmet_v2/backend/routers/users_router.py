from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
import models
from auth import get_current_user, hash_password, verify_password

router = APIRouter(prefix="/users", tags=["users"])


class UpdateProfileBody(BaseModel):
    name: str | None = None
    surname: str | None = None
    phone: str | None = None
    photo_url: str | None = None
    lat: float | None = None
    lng: float | None = None


class ChangePasswordBody(BaseModel):
    old_password: str
    new_password: str


def _user_dict(u: models.User) -> dict:
    return {
        "id": u.id, "name": u.name, "surname": u.surname,
        "email": u.email, "phone": u.phone, "role": u.role,
        "photo_url": u.photo_url, "lat": u.lat, "lng": u.lng,
        "is_blocked": u.is_blocked, "created_at": u.created_at.isoformat(),
    }


@router.put("/me")
async def update_profile(
    body: UpdateProfileBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if body.name is not None:
        user.name = body.name.strip()
    if body.surname is not None:
        user.surname = body.surname.strip()
    if body.phone is not None:
        user.phone = body.phone.strip()
    if body.photo_url is not None:
        user.photo_url = body.photo_url
    if body.lat is not None:
        user.lat = body.lat
    if body.lng is not None:
        user.lng = body.lng
    await db.commit()
    await db.refresh(user)
    return _user_dict(user)


@router.post("/me/change-password")
async def change_password(
    body: ChangePasswordBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not verify_password(body.old_password, user.password_hash):
        raise HTTPException(400, "Köhnə şifrə yanlışdır")
    if len(body.new_password) < 6:
        raise HTTPException(400, "Yeni şifrə ən az 6 simvol olmalıdır")
    user.password_hash = hash_password(body.new_password)
    await db.commit()
    return {"ok": True}


@router.get("/{user_id}")
async def get_user(user_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User).where(models.User.id == user_id))
    u = result.scalar_one_or_none()
    if not u:
        raise HTTPException(404, "İstifadəçi tapılmadı")
    return _user_dict(u)
