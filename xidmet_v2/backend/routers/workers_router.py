import json
import uuid

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import models
from auth import get_current_user
from database import get_db

router = APIRouter(prefix="/workers", tags=["workers"])


class UpdateWorkerBody(BaseModel):
    bio: str | None = None
    categories: list[str] | None = None
    experience_years: int | None = None
    min_price: float | None = None
    hourly_rate: float | None = None
    work_hours: str | None = None
    is_urgent_available: bool | None = None
    home_service: bool | None = None
    contact_phone: str | None = None
    availability: str | None = None


def _worker_dict(u: models.User, w: models.Worker) -> dict:
    return {
        "id": u.id,
        "name": u.name,
        "surname": u.surname,
        "email": u.email,
        "phone": u.phone,
        "photo_url": u.photo_url,
        "address": u.address,
        "lat": u.lat,
        "lng": u.lng,
        "is_online": u.is_online,
        "bio": w.bio,
        "categories": w.get_categories(),
        "experience_years": w.experience_years,
        "min_price": w.min_price,
        "hourly_rate": w.hourly_rate,
        "work_hours": w.work_hours,
        "is_urgent_available": w.is_urgent_available,
        "home_service": w.home_service,
        "contact_phone": w.contact_phone,
        "availability": w.availability,
        "rating": w.rating,
        "rating_count": w.rating_count,
        "completed_count": w.completed_count,
    }


@router.get("")
async def list_workers(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(models.Worker))
    out = []
    for w in result.scalars():
        ur = await db.execute(select(models.User).where(models.User.id == w.id))
        u = ur.scalar_one_or_none()
        if u and not u.is_blocked:
            out.append(_worker_dict(u, w))
    return out


@router.get("/me")
async def my_worker_profile(
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(models.Worker).where(models.Worker.id == user.id))
    w = result.scalar_one_or_none()
    if not w:
        raise HTTPException(404, "İcraçı profili tapılmadı")
    return _worker_dict(user, w)


@router.put("/me")
async def update_worker_profile(
    body: UpdateWorkerBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(models.Worker).where(models.Worker.id == user.id))
    w = result.scalar_one_or_none()
    if not w:
        raise HTTPException(404, "İcraçı profili tapılmadı")
    if body.bio is not None:
        w.bio = body.bio
    if body.categories is not None:
        w.categories = json.dumps(body.categories)
    if body.experience_years is not None:
        w.experience_years = body.experience_years
    if body.min_price is not None:
        w.min_price = body.min_price
    if body.hourly_rate is not None:
        w.hourly_rate = body.hourly_rate
    if body.work_hours is not None:
        w.work_hours = body.work_hours
    if body.is_urgent_available is not None:
        w.is_urgent_available = body.is_urgent_available
    if body.home_service is not None:
        w.home_service = body.home_service
    if body.contact_phone is not None:
        w.contact_phone = body.contact_phone
    if body.availability is not None:
        w.availability = body.availability
    await db.commit()
    await db.refresh(w)
    return _worker_dict(user, w)


@router.get("/{worker_id}")
async def get_worker(worker_id: str, db: AsyncSession = Depends(get_db)):
    wr = await db.execute(select(models.Worker).where(models.Worker.id == worker_id))
    w = wr.scalar_one_or_none()
    if not w:
        raise HTTPException(404, "İcraçı tapılmadı")
    ur = await db.execute(select(models.User).where(models.User.id == worker_id))
    u = ur.scalar_one_or_none()
    if not u:
        raise HTTPException(404, "İstifadəçi tapılmadı")
    return _worker_dict(u, w)
