import json
from datetime import datetime
from sqlalchemy import String, Float, Boolean, DateTime, ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from database import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    name: Mapped[str] = mapped_column(String(100))
    surname: Mapped[str] = mapped_column(String(100))
    email: Mapped[str] = mapped_column(String(200), unique=True, index=True)
    phone: Mapped[str] = mapped_column(String(30), default="")
    password_hash: Mapped[str] = mapped_column(String)
    role: Mapped[str] = mapped_column(String(20), default="user")
    photo_url: Mapped[str] = mapped_column(String, default="")
    lat: Mapped[float] = mapped_column(Float, default=40.4093)
    lng: Mapped[float] = mapped_column(Float, default=49.8671)
    address: Mapped[str] = mapped_column(String(300), default="")
    is_blocked: Mapped[bool] = mapped_column(Boolean, default=False)
    is_online: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    worker_profile: Mapped["Worker"] = relationship("Worker", back_populates="user", uselist=False)
    favorites: Mapped[list["Favorite"]] = relationship("Favorite", back_populates="user")


class Worker(Base):
    __tablename__ = "workers"

    id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), primary_key=True)
    bio: Mapped[str] = mapped_column(Text, default="")
    categories: Mapped[str] = mapped_column(Text, default="[]")   # JSON array
    experience_years: Mapped[int] = mapped_column(Integer, default=0)
    min_price: Mapped[float] = mapped_column(Float, default=0.0)
    hourly_rate: Mapped[float] = mapped_column(Float, default=0.0)
    work_hours: Mapped[str] = mapped_column(String(100), default="09:00-18:00")
    is_urgent_available: Mapped[bool] = mapped_column(Boolean, default=False)
    home_service: Mapped[bool] = mapped_column(Boolean, default=False)
    contact_phone: Mapped[str] = mapped_column(String(30), default="")
    availability: Mapped[str] = mapped_column(String(20), default="available")
    rating: Mapped[float] = mapped_column(Float, default=0.0)
    rating_count: Mapped[int] = mapped_column(Integer, default=0)
    completed_count: Mapped[int] = mapped_column(Integer, default=0)

    user: Mapped["User"] = relationship("User", back_populates="worker_profile")
    listings: Mapped[list["Listing"]] = relationship("Listing", back_populates="worker")
    reviews: Mapped[list["Review"]] = relationship("Review", back_populates="worker_rel")

    def get_categories(self) -> list:
        try:
            return json.loads(self.categories)
        except Exception:
            return []


class Listing(Base):
    __tablename__ = "listings"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    worker_id: Mapped[str] = mapped_column(String, ForeignKey("workers.id"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    category: Mapped[str] = mapped_column(String(50), index=True)
    images: Mapped[str] = mapped_column(Text, default="[]")        # JSON array of URLs
    min_price: Mapped[float] = mapped_column(Float, default=0.0)
    max_price: Mapped[float] = mapped_column(Float, default=0.0)
    address: Mapped[str] = mapped_column(String(300), default="")
    lat: Mapped[float] = mapped_column(Float, default=40.4093)
    lng: Mapped[float] = mapped_column(Float, default=49.8671)
    work_hours: Mapped[str] = mapped_column(String(100), default="09:00-18:00")
    is_urgent: Mapped[bool] = mapped_column(Boolean, default=False)
    home_service: Mapped[bool] = mapped_column(Boolean, default=False)
    contact_phone: Mapped[str] = mapped_column(String(30), default="")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    view_count: Mapped[int] = mapped_column(Integer, default=0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    worker: Mapped["Worker"] = relationship("Worker", back_populates="listings")
    reviews: Mapped[list["Review"]] = relationship("Review", back_populates="listing")
    favorites: Mapped[list["Favorite"]] = relationship("Favorite", back_populates="listing")

    def get_images(self) -> list:
        try:
            return json.loads(self.images)
        except Exception:
            return []


class Favorite(Base):
    __tablename__ = "favorites"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), index=True)
    listing_id: Mapped[str] = mapped_column(String, ForeignKey("listings.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship("User", back_populates="favorites")
    listing: Mapped["Listing"] = relationship("Listing", back_populates="favorites")


class Review(Base):
    __tablename__ = "reviews"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    listing_id: Mapped[str] = mapped_column(String, ForeignKey("listings.id"), index=True)
    worker_id: Mapped[str] = mapped_column(String, ForeignKey("workers.id"), index=True)
    reviewer_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"))
    rating: Mapped[float] = mapped_column(Float)
    comment: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    worker_rel: Mapped["Worker"] = relationship("Worker", back_populates="reviews")
    listing: Mapped["Listing"] = relationship("Listing", back_populates="reviews")


class ChatThread(Base):
    __tablename__ = "chat_threads"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    listing_id: Mapped[str | None] = mapped_column(String, ForeignKey("listings.id"), nullable=True)
    owner_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"))
    worker_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"))
    last_message: Mapped[str] = mapped_column(Text, default="")
    unread_owner: Mapped[int] = mapped_column(Integer, default=0)
    unread_worker: Mapped[int] = mapped_column(Integer, default=0)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    messages: Mapped[list["ChatMessage"]] = relationship("ChatMessage", back_populates="thread")


class ChatMessage(Base):
    __tablename__ = "chat_messages"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    thread_id: Mapped[str] = mapped_column(String, ForeignKey("chat_threads.id"))
    sender_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"))
    text: Mapped[str] = mapped_column(Text)
    sent_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    thread: Mapped["ChatThread"] = relationship("ChatThread", back_populates="messages")


class Job(Base):
    __tablename__ = "jobs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(String, ForeignKey("users.id"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    category: Mapped[str] = mapped_column(String(50), index=True)
    budget_min: Mapped[float] = mapped_column(Float, default=0.0)
    budget_max: Mapped[float] = mapped_column(Float, default=0.0)
    address: Mapped[str] = mapped_column(String(300), default="")
    lat: Mapped[float] = mapped_column(Float, default=40.4093)
    lng: Mapped[float] = mapped_column(Float, default=49.8671)
    is_urgent: Mapped[bool] = mapped_column(Boolean, default=False)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    status: Mapped[str] = mapped_column(String(20), default="open")  # open, in_progress, completed
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    user: Mapped["User"] = relationship("User")
    applications: Mapped[list["JobApplication"]] = relationship("JobApplication", back_populates="job")


class JobApplication(Base):
    __tablename__ = "job_applications"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    job_id: Mapped[str] = mapped_column(String, ForeignKey("jobs.id"), index=True)
    worker_id: Mapped[str] = mapped_column(String, ForeignKey("workers.id"), index=True)
    cover_letter: Mapped[str] = mapped_column(Text, default="")
    status: Mapped[str] = mapped_column(String(20), default="pending")  # pending, accepted, rejected
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)

    job: Mapped["Job"] = relationship("Job", back_populates="applications")
    worker: Mapped["Worker"] = relationship("Worker")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id: Mapped[str] = mapped_column(String, primary_key=True)
    actor_id: Mapped[str] = mapped_column(String)
    action: Mapped[str] = mapped_column(String(100))
    target_id: Mapped[str] = mapped_column(String, default="")
    detail: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow)
