import json
import math
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

import models
from auth import get_current_user
from database import get_db

router = APIRouter(prefix="/jobs", tags=["jobs"])


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


async def _job_dict(job: models.Job, db: AsyncSession, user_id: str | None = None) -> dict:
    """Convert job to dict with user info."""
    ur = await db.execute(select(models.User).where(models.User.id == job.user_id))
    user = ur.scalar_one_or_none()

    # Count applications
    app_result = await db.execute(
        select(models.JobApplication).where(models.JobApplication.job_id == job.id)
    )
    applications_count = len(app_result.scalars().all())

    # Check if current user applied
    has_applied = False
    if user_id:
        app_result = await db.execute(
            select(models.JobApplication).where(
                models.JobApplication.job_id == job.id,
                models.JobApplication.worker_id == user_id,
            )
        )
        has_applied = app_result.scalar_one_or_none() is not None

    return {
        "id": job.id,
        "user_id": job.user_id,
        "title": job.title,
        "description": job.description,
        "category": job.category,
        "budget_min": job.budget_min,
        "budget_max": job.budget_max,
        "address": job.address,
        "lat": job.lat,
        "lng": job.lng,
        "is_urgent": job.is_urgent,
        "is_active": job.is_active,
        "status": job.status,
        "applications_count": applications_count,
        "has_applied": has_applied,
        "created_at": job.created_at.isoformat(),
        "updated_at": job.updated_at.isoformat(),
        "user_name": f"{user.name} {user.surname}" if user else "",
        "user_photo": user.photo_url if user else "",
        "user_is_online": user.is_online if user else False,
    }


# ──────────────────────────────────────────────
# Schemas
# ──────────────────────────────────────────────

class JobCreateBody(BaseModel):
    title: str
    description: str = ""
    category: str
    budget_min: float = 0.0
    budget_max: float = 0.0
    address: str = ""
    lat: float = 40.4093
    lng: float = 49.8671
    is_urgent: bool = False


class JobUpdateBody(BaseModel):
    title: str | None = None
    description: str | None = None
    category: str | None = None
    budget_min: float | None = None
    budget_max: float | None = None
    address: str | None = None
    lat: float | None = None
    lng: float | None = None
    is_urgent: bool | None = None
    status: str | None = None
    is_active: bool | None = None


class JobApplicationBody(BaseModel):
    cover_letter: str = ""


class JobApplicationUpdateBody(BaseModel):
    status: str  # pending, accepted, rejected


# ──────────────────────────────────────────────
# Job CRUD
# ──────────────────────────────────────────────

@router.get("")
async def list_jobs(
    category: str | None = Query(None),
    q: str | None = Query(None),
    lat: float | None = Query(None),
    lng: float | None = Query(None),
    radius: float | None = Query(None),
    is_urgent: bool | None = Query(None),
    status: str | None = Query(None),
    db: AsyncSession = Depends(get_db),
    user: models.User | None = Depends(get_current_user),
):
    """List all active jobs with optional filters."""
    result = await db.execute(select(models.Job).where(models.Job.is_active == True))
    jobs = result.scalars().all()
    out = []
    for job in jobs:
        if status and job.status != status:
            continue
        if category and job.category != category:
            continue
        if q and q.lower() not in job.title.lower() and q.lower() not in job.description.lower():
            continue
        if is_urgent is not None and job.is_urgent != is_urgent:
            continue
        d = None
        if lat is not None and lng is not None:
            d = _haversine(lat, lng, job.lat, job.lng)
            if radius is not None and d > radius:
                continue
        item = await _job_dict(job, db, user.id if user else None)
        if d is not None:
            item["distance_km"] = round(d, 2)
        out.append(item)
    if lat is not None and lng is not None:
        out.sort(key=lambda x: x.get("distance_km", 999))
    else:
        out.sort(key=lambda x: x["created_at"], reverse=True)
    return out


@router.post("")
async def create_job(
    body: JobCreateBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Create a new job (user/employer only)."""
    if user.is_blocked:
        raise HTTPException(403, "Hesab bloklanıb")
    if user.role == "worker":
        raise HTTPException(403, "İşçilər iş elanı verə bilməzlər")
    
    job = models.Job(
        id=str(uuid.uuid4()),
        user_id=user.id,
        title=body.title,
        description=body.description,
        category=body.category,
        budget_min=body.budget_min,
        budget_max=body.budget_max,
        address=body.address,
        lat=body.lat,
        lng=body.lng,
        is_urgent=body.is_urgent,
    )
    db.add(job)
    await db.commit()
    await db.refresh(job)
    return await _job_dict(job, db, user.id)


@router.get("/mine")
async def my_jobs(
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get jobs posted by current user."""
    if user.role == "worker":
        raise HTTPException(403, "İşçilər bu əməliyyatı icra edə bilməzlər")
    
    result = await db.execute(
        select(models.Job).where(models.Job.user_id == user.id)
        .order_by(models.Job.created_at.desc())
    )
    out = []
    for job in result.scalars():
        out.append(await _job_dict(job, db, user.id))
    return out


@router.get("/{job_id}")
async def get_job(
    job_id: str,
    db: AsyncSession = Depends(get_db),
    user: models.User | None = Depends(get_current_user),
):
    """Get job details."""
    result = await db.execute(select(models.Job).where(models.Job.id == job_id))
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(404, "İş tapılmadı")
    return await _job_dict(job, db, user.id if user else None)


@router.put("/{job_id}")
async def update_job(
    job_id: str,
    body: JobUpdateBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update job (owner only)."""
    result = await db.execute(select(models.Job).where(models.Job.id == job_id))
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(404, "İş tapılmadı")
    if job.user_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    
    if body.title is not None:
        job.title = body.title
    if body.description is not None:
        job.description = body.description
    if body.category is not None:
        job.category = body.category
    if body.budget_min is not None:
        job.budget_min = body.budget_min
    if body.budget_max is not None:
        job.budget_max = body.budget_max
    if body.address is not None:
        job.address = body.address
    if body.lat is not None:
        job.lat = body.lat
    if body.lng is not None:
        job.lng = body.lng
    if body.is_urgent is not None:
        job.is_urgent = body.is_urgent
    if body.status is not None:
        job.status = body.status
    if body.is_active is not None:
        job.is_active = body.is_active
    
    await db.commit()
    await db.refresh(job)
    return await _job_dict(job, db, user.id)


@router.delete("/{job_id}")
async def delete_job(
    job_id: str,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete job (owner only)."""
    result = await db.execute(select(models.Job).where(models.Job.id == job_id))
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(404, "İş tapılmadı")
    if job.user_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    
    await db.delete(job)
    await db.commit()
    return {"status": "ok"}


# ──────────────────────────────────────────────
# Job Applications
# ──────────────────────────────────────────────

@router.post("/{job_id}/apply")
async def apply_to_job(
    job_id: str,
    body: JobApplicationBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Apply to a job (workers only)."""
    if user.role != "worker":
        raise HTTPException(403, "Yalnız işçilər iş elanlarına müraciət edə bilərlər")
    if user.is_blocked:
        raise HTTPException(403, "Hesab bloklanıb")
    
    # Check if job exists
    result = await db.execute(select(models.Job).where(models.Job.id == job_id))
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(404, "İş tapılmadı")
    if not job.is_active:
        raise HTTPException(400, "Bu iş artıq aktiv deyil")
    
    # Check if already applied
    app_result = await db.execute(
        select(models.JobApplication).where(
            models.JobApplication.job_id == job_id,
            models.JobApplication.worker_id == user.id,
        )
    )
    if app_result.scalar_one_or_none() is not None:
        raise HTTPException(400, "Siz artıq bu işə müraciət etmisiniz")
    
    # Create application
    application = models.JobApplication(
        id=str(uuid.uuid4()),
        job_id=job_id,
        worker_id=user.id,
        cover_letter=body.cover_letter,
    )
    db.add(application)
    await db.commit()
    await db.refresh(application)
    
    return {
        "id": application.id,
        "job_id": application.job_id,
        "worker_id": application.worker_id,
        "cover_letter": application.cover_letter,
        "status": application.status,
        "created_at": application.created_at.isoformat(),
    }


@router.get("/{job_id}/applications")
async def get_job_applications(
    job_id: str,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get applications for a job (job owner only)."""
    result = await db.execute(select(models.Job).where(models.Job.id == job_id))
    job = result.scalar_one_or_none()
    if not job:
        raise HTTPException(404, "İş tapılmadı")
    if job.user_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    
    app_result = await db.execute(
        select(models.JobApplication).where(models.JobApplication.job_id == job_id)
    )
    applications = []
    for app in app_result.scalars():
        # Get worker info
        wr = await db.execute(select(models.Worker).where(models.Worker.id == app.worker_id))
        worker = wr.scalar_one_or_none()
        ur = await db.execute(select(models.User).where(models.User.id == app.worker_id))
        worker_user = ur.scalar_one_or_none()
        
        applications.append({
            "id": app.id,
            "job_id": app.job_id,
            "worker_id": app.worker_id,
            "cover_letter": app.cover_letter,
            "status": app.status,
            "created_at": app.created_at.isoformat(),
            "worker_name": f"{worker_user.name} {worker_user.surname}" if worker_user else "",
            "worker_photo": worker_user.photo_url if worker_user else "",
            "worker_rating": worker.rating if worker else 0.0,
            "worker_rating_count": worker.rating_count if worker else 0,
        })
    
    return applications


@router.get("/worker/my-applications")
async def my_job_applications(
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Get jobs worker has applied to."""
    if user.role != "worker":
        raise HTTPException(403, "Yalnız işçilər bu əməliyyatı icra edə bilərlər")
    
    app_result = await db.execute(
        select(models.JobApplication).where(models.JobApplication.worker_id == user.id)
        .order_by(models.JobApplication.created_at.desc())
    )
    applications = []
    for app in app_result.scalars():
        job_result = await db.execute(select(models.Job).where(models.Job.id == app.job_id))
        job = job_result.scalar_one_or_none()
        if job:
            job_dict = await _job_dict(job, db, user.id)
            applications.append({
                **job_dict,
                "application_id": app.id,
                "application_status": app.status,
                "application_cover_letter": app.cover_letter,
                "applied_at": app.created_at.isoformat(),
            })
    
    return applications


@router.put("/{job_id}/applications/{application_id}")
async def update_application_status(
    job_id: str,
    application_id: str,
    body: JobApplicationUpdateBody,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Update application status (job owner only)."""
    result = await db.execute(
        select(models.JobApplication).where(models.JobApplication.id == application_id)
    )
    application = result.scalar_one_or_none()
    if not application:
        raise HTTPException(404, "Müraciət tapılmadı")
    
    # Check if user is job owner
    job_result = await db.execute(select(models.Job).where(models.Job.id == application.job_id))
    job = job_result.scalar_one_or_none()
    if job.user_id != user.id and user.role not in ("admin", "superadmin"):
        raise HTTPException(403, "İcazə yoxdur")
    
    application.status = body.status
    await db.commit()
    await db.refresh(application)
    
    return {
        "id": application.id,
        "job_id": application.job_id,
        "worker_id": application.worker_id,
        "status": application.status,
        "created_at": application.created_at.isoformat(),
    }


@router.delete("/{job_id}/applications/{application_id}")
async def delete_application(
    job_id: str,
    application_id: str,
    user: models.User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Delete application (worker or job owner)."""
    result = await db.execute(
        select(models.JobApplication).where(models.JobApplication.id == application_id)
    )
    application = result.scalar_one_or_none()
    if not application:
        raise HTTPException(404, "Müraciət tapılmadı")
    
    # Check permissions
    job_result = await db.execute(select(models.Job).where(models.Job.id == application.job_id))
    job = job_result.scalar_one_or_none()
    
    is_worker = user.id == application.worker_id
    is_job_owner = job.user_id == user.id
    is_admin = user.role in ("admin", "superadmin")
    
    if not (is_worker or is_job_owner or is_admin):
        raise HTTPException(403, "İcazə yoxdur")
    
    await db.delete(application)
    await db.commit()
    return {"status": "ok"}
