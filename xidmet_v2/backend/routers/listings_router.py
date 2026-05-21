import json
import math
import os
import shutil
import uuid
from typing import Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import models
from auth import get_current_user
from database import get_db

router = APIRouter(tags=["listings"])

UPLOAD_DIR = os.path.join(os.path.dirname(__file__), "..", "uploads")
os.makedirs(UPLOAD_DIR, exist_ok=True)


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

def _haversine(lat1, lng1, lat2, lng2) -> float:
    """Returns distance in km."""
    R = 6371.0
    dlat = math.radians(lat2 - lat1)
    dlng = math.radians(lng2 - lng1)
    a = math.sin(dlat / 2) ** 2 + math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) * math.sin(dlng / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


async def _listing_dict(listing: models.Listing, db: AsyncSession, user_id: str | None = None) -> dict:
    wr = await db.execute(select(models.Worker).where(models.Worker.id == listing.worker_id))
    worker = wr.scalar_one_or_none()
    ur = await db.execute(select(models.User).where(models.User.id == listing.worker_id))
    user = ur.scalar_one_or_none()

    is_favorite = False
    if user_id:
        fav = await db.execute(
            select(models.Favorite).where(
                models.Favorite.user_id == user_id,
                models.Favorite.listing_id == listing.id,
            )
        )
        is_favorite = fav.scalar_one_or_none() is not None

    return {
        "id": listing.id,
        "worker_id": listing.worker_id,
        "title": listing.title,
        "description": listing.description,
        "category": listing.category,
        "images": listing.get_images(),
        "min_price": listing.min_price,
        "max_price": listing.max_price,
        "address": listing.address,
        "lat": listing.lat,
        "lng": listing.lng,
        "work_hours": listing.work_hours,
        "is_urgent": listing.is_urgent,
        "home_service": listing.home_service,
        "contact_phone": listing.contact_phone,
        "is_active": listing.is_active,
        "view_count": listing.view_count,
        "created_at": listing.created_at.isoformat(),
        "worker_name": f"{user.name} {user.surname}" if user else "",
        "worker_photo": user.photo_url if user else "",
        "worker_is_online": user.is_online if user else False,
        "worker_rating": worker.rating if worker else 0.0,
        "worker_rating_count": worker.rating_count if worker else 0,
        "is_favorite": is_favorite,
    }


# ──────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────

class ListingCreateBody(BaseModel):
    title: str
    description: str = ""
    category: str
    images: list[str] = []
    min_price: float = 0.0
    max_price: float = 0.0
    address: str = ""
    lat: float = 40.4093
    lng: float = 49.8671
    work_hours: str = "09:00-18:00"
    is_urgent: bool = False
    home_service: bool = False
    contact_phone: str = ""


class ListingUpdateBody(BaseModel):
    title: str | None = None
    description: str | None = None
    category: str | None = None
    images: list[str] | None = None
    min_price: float | None = None
    max_price: float | None = None
    address: str | None = None
    lat: float | None = None
    lng: float | None = None
    work_hours: str | None = None
    is_urgent: bool | None = None
    home_service: bool | None = None
    contact_phone: str | None = None
    is_active: bool | None = None


class ReviewCreateBody(BaseModel):
    rating: float
    comment: str = ""


# ──────────────────────────────────────────────
# Image upload
# ──────────────────────────────────────────────

@router.post("/upload")
async def upload_image(
    file: UploadFile = File(...),
    _user: models.User = Depends(get_current_user),
):
    ext = os.path.splitext(file.filename or "img.jpg")[1].lower() or ".jpg"
    if ext not in {".jpg", ".jpeg", ".png", ".webp"}:
        raise HTTPException(400, "Yalnız şəkil faylları qəbul edilir")
    filename = f"{uuid.uuid4()}{ext}"
    dest = os.path.join(UPLOAD_DIR, filename)
    with open(dest, "wb") as f:
        shutil.copyfileobj(file.file, f)
    return {"url": f"/uploads/{filename}"}


# ──────────────────────────────────────────────
# Listing CRUD
# ──────────────────────────────────────────────

@router.get("/listings")
async def list_listings(
    category: str | None = Query(None),
    q: str | None = Query(None),
    lat: float | None = Query(None),
    lng: float | None = Query(None),
    radius: float | None = Query(None),
    is_urgent: bool | None = Query(None),
    home_service: bool | None = Query(None),
    db: AsyncSession = Depends(get_db),
    user: models.User | None = Depends(get_current_user),
):
    result = await db.execute(select(models.Listing).where(models.Listing.is_active == True))
    listings = result.scalars().all()
    out = []
    for listing in listings:
        if category and listing.category != category:
            continue
        if q and q.lower() not in listing.title.lower() and q.lower() not in listing.description.lower():
            continue
        if is_urgent is not None and listing.is_urgent != is_urgent:
            continue
        if home_service is not None and listing.home_service != home_service:
            continue
        d = None
        if lat is not None and lng is not None:
            d = _haversine(lat, lng, listing.lat, listing.lng)
            if radius is not None and d > radius:
                continue
        item = await _listing_dict(listing, db, user.id if user else None)
        if d is not None:
            item["distance_km"] = round(d, 2)
        out.append(item)
    if lat is not None and lng is not None:
        out.sort(key=lambda x: x.get("distance_km", 999))
    return out


@router.post("/listings")
async def create_listing(
    body: ListingCreateBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if user.is_blocked:
        raise HTTPException(403, "Hesab bloklanıb")
    listing = models.Listing(
        id=str(uuid.uuid4()),
        worker_id=user.id,
        title=body.title,
        description=body.description,
        category=body.category,
        images=json.dumps(body.images),
        min_price=body.min_price,
        max_price=body.max_price,
        address=body.address,
        lat=body.lat,
        lng=body.lng,
        work_hours=body.work_hours,
        is_urgent=body.is_urgent,
        home_service=body.home_service,
        contact_phone=body.contact_phone,
    )
    db.add(listing)
    await db.commit()
    await db.refresh(listing)
    return await _listing_dict(listing, db, user.id)


@router.get("/listings/my")
async def my_listings(
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(models.Listing).where(models.Listing.worker_id == user.id)
        .order_by(models.Listing.created_at.desc())
    )
    out = []
    for listing in result.scalars():
        out.append(await _listing_dict(listing, db, user.id))
    return out


@router.get("/listings/favorites")
async def my_favorites(
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(models.Favorite).where(models.Favorite.user_id == user.id)
    )
    out = []
    for fav in result.scalars():
        lr = await db.execute(select(models.Listing).where(models.Listing.id == fav.listing_id))
        listing = lr.scalar_one_or_none()
        if listing and listing.is_active:
            out.append(await _listing_dict(listing, db, user.id))
    return out


@router.get("/listings/{listing_id}")
async def get_listing(
    listing_id: str,
    db: AsyncSession = Depends(get_db),
    user: models.User | None = Depends(get_current_user),
):
    result = await db.execute(select(models.Listing).where(models.Listing.id == listing_id))
    listing = result.scalar_one_or_none()
    if not listing:
        raise HTTPException(404, "Elan tapılmadı")
    listing.view_count += 1
    await db.commit()
    return await _listing_dict(listing, db, user.id if user else None)


@router.put("/listings/{listing_id}")
async def update_listing(
    listing_id: str,
    body: ListingUpdateBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(models.Listing).where(models.Listing.id == listing_id))
    listing = result.scalar_one_or_none()
    if not listing:
        raise HTTPException(404, "Elan tapılmadı")
    if listing.worker_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    if body.title is not None:
        listing.title = body.title
    if body.description is not None:
        listing.description = body.description
    if body.category is not None:
        listing.category = body.category
    if body.images is not None:
        listing.images = json.dumps(body.images)
    if body.min_price is not None:
        listing.min_price = body.min_price
    if body.max_price is not None:
        listing.max_price = body.max_price
    if body.address is not None:
        listing.address = body.address
    if body.lat is not None:
        listing.lat = body.lat
    if body.lng is not None:
        listing.lng = body.lng
    if body.work_hours is not None:
        listing.work_hours = body.work_hours
    if body.is_urgent is not None:
        listing.is_urgent = body.is_urgent
    if body.home_service is not None:
        listing.home_service = body.home_service
    if body.contact_phone is not None:
        listing.contact_phone = body.contact_phone
    if body.is_active is not None:
        listing.is_active = body.is_active
    await db.commit()
    await db.refresh(listing)
    return await _listing_dict(listing, db, user.id)


@router.delete("/listings/{listing_id}")
async def delete_listing(
    listing_id: str,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(models.Listing).where(models.Listing.id == listing_id))
    listing = result.scalar_one_or_none()
    if not listing:
        raise HTTPException(404, "Elan tapılmadı")
    if listing.worker_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    await db.delete(listing)
    await db.commit()
    return {"ok": True}


# ──────────────────────────────────────────────
# Favorites
# ──────────────────────────────────────────────

@router.post("/listings/{listing_id}/favorite")
async def toggle_favorite(
    listing_id: str,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    lr = await db.execute(select(models.Listing).where(models.Listing.id == listing_id))
    if not lr.scalar_one_or_none():
        raise HTTPException(404, "Elan tapılmadı")
    fr = await db.execute(
        select(models.Favorite).where(
            models.Favorite.user_id == user.id,
            models.Favorite.listing_id == listing_id,
        )
    )
    fav = fr.scalar_one_or_none()
    if fav:
        await db.delete(fav)
        await db.commit()
        return {"is_favorite": False}
    new_fav = models.Favorite(
        id=str(uuid.uuid4()),
        user_id=user.id,
        listing_id=listing_id,
    )
    db.add(new_fav)
    await db.commit()
    return {"is_favorite": True}


# ──────────────────────────────────────────────
# Reviews
# ──────────────────────────────────────────────

@router.get("/listings/{listing_id}/reviews")
async def listing_reviews(listing_id: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(models.Review).where(models.Review.listing_id == listing_id)
        .order_by(models.Review.created_at.desc())
    )
    out = []
    for r in result.scalars():
        ur = await db.execute(select(models.User).where(models.User.id == r.reviewer_id))
        reviewer = ur.scalar_one_or_none()
        out.append({
            "id": r.id,
            "rating": r.rating,
            "comment": r.comment,
            "created_at": r.created_at.isoformat(),
            "reviewer_name": f"{reviewer.name} {reviewer.surname}" if reviewer else "İstifadəçi",
            "reviewer_photo": reviewer.photo_url if reviewer else "",
        })
    return out


@router.post("/listings/{listing_id}/reviews")
async def add_listing_review(
    listing_id: str,
    body: ReviewCreateBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    if not (1 <= body.rating <= 5):
        raise HTTPException(400, "Reytinq 1-5 arasında olmalıdır")
    lr = await db.execute(select(models.Listing).where(models.Listing.id == listing_id))
    listing = lr.scalar_one_or_none()
    if not listing:
        raise HTTPException(404, "Elan tapılmadı")
    existing = await db.execute(
        select(models.Review).where(
            models.Review.listing_id == listing_id,
            models.Review.reviewer_id == user.id,
        )
    )
    if existing.scalar_one_or_none():
        raise HTTPException(400, "Artıq rəy bildirmisiz")
    review = models.Review(
        id=str(uuid.uuid4()),
        listing_id=listing_id,
        worker_id=listing.worker_id,
        reviewer_id=user.id,
        rating=body.rating,
        comment=body.comment,
    )
    db.add(review)
    wr = await db.execute(select(models.Worker).where(models.Worker.id == listing.worker_id))
    worker = wr.scalar_one_or_none()
    if worker:
        total = worker.rating * worker.rating_count + body.rating
        worker.rating_count += 1
        worker.rating = round(total / worker.rating_count, 2)
    await db.commit()
    return {"ok": True}
