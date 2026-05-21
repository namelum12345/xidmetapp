from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from database import init_db
from routers.auth_router import router as auth_router
from routers.users_router import router as users_router
from routers.workers_router import router as workers_router
from routers.listings_router import router as listings_router
from routers.jobs_router import router as jobs_router
from routers.chats_router import router as chats_router
from routers.admin_router import router as admin_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    await init_db()
    await _seed_superadmin()
    yield


async def _seed_superadmin():
    from database import SessionLocal
    from sqlalchemy import select
    import models, uuid
    from auth import hash_password

    async with SessionLocal() as db:
        r = await db.execute(select(models.User).where(models.User.role == "superadmin"))
        if not r.scalar_one_or_none():
            sa = models.User(
                id=str(uuid.uuid4()),
                name="Super", surname="Admin",
                email="super@admin.az",
                password_hash=hash_password("superadmin123"),
                role="superadmin",
            )
            db.add(sa)
            await db.commit()
            print("✅ Superadmin yaradıldı: super@admin.az / superadmin123")


app = FastAPI(title="Qonşudan Xidmət API", version="2.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve uploaded images
uploads_dir = os.path.join(os.path.dirname(__file__), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

app.include_router(auth_router)
app.include_router(users_router)
app.include_router(workers_router)
app.include_router(listings_router)
app.include_router(jobs_router)
app.include_router(chats_router)
app.include_router(admin_router)


@app.get("/health")
async def health():
    return {"status": "ok", "version": "2.0.0"}
