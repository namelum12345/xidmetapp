import json
import uuid
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, EmailStr
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
import models
from auth import hash_password, verify_password, create_token, get_current_user

router = APIRouter(prefix="/auth", tags=["auth"])


class RegisterBody(BaseModel):
    name: str
    surname: str
    email: EmailStr
    phone: str = ""
    password: str
    role: str = "user"  # user | worker
    categories: list[str] = []
    lat: float = 40.4093
    lng: float = 49.8671
    address: str = ""


class LoginBody(BaseModel):
    email: str
    password: str


class TokenOut(BaseModel):
    token: str
    role: str
    user_id: str


@router.post("/register", response_model=TokenOut)
async def register(body: RegisterBody, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User).where(models.User.email == body.email.lower()))
    if result.scalar_one_or_none():
        raise HTTPException(400, "Bu e-poçt artıq qeydiyyatdan keçib")

    uid = str(uuid.uuid4())
    user = models.User(
        id=uid,
        name=body.name.strip(),
        surname=body.surname.strip(),
        email=body.email.lower().strip(),
        phone=body.phone.strip(),
        password_hash=hash_password(body.password),
        role=body.role if body.role in ("user", "worker") else "user",
        lat=body.lat,
        lng=body.lng,
        address=body.address,
    )
    db.add(user)

    if body.role == "worker":
        worker = models.Worker(
            id=uid,
            categories=json.dumps(body.categories),
        )
        db.add(worker)

    await db.commit()
    return TokenOut(token=create_token(uid, user.role), role=user.role, user_id=uid)


@router.post("/login", response_model=TokenOut)
async def login(body: LoginBody, db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.User).where(models.User.email == body.email.lower().strip()))
    user = result.scalar_one_or_none()
    if not user or not verify_password(body.password, user.password_hash):
        raise HTTPException(401, "E-poçt və ya şifrə yanlışdır")
    if user.is_blocked:
        raise HTTPException(403, "Hesab bloklanıb")
    return TokenOut(token=create_token(user.id, user.role), role=user.role, user_id=user.id)


@router.get("/me")
async def me(user: models.User = Depends(get_current_user)):
    return _user_dict(user)


def _user_dict(u: models.User) -> dict:
    return {
        "id": u.id, "name": u.name, "surname": u.surname,
        "email": u.email, "phone": u.phone, "role": u.role,
        "photo_url": u.photo_url, "lat": u.lat, "lng": u.lng,
        "is_blocked": u.is_blocked, "created_at": u.created_at.isoformat(),
    }
