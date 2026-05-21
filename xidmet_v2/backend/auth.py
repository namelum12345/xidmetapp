from datetime import datetime, timedelta
from typing import Optional
import bcrypt
from jose import JWTError, jwt
from fastapi import Depends, HTTPException
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from database import get_db
import models

SECRET_KEY = "xidmet-secret-key-change-in-production-2024"
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_DAYS = 30

bearer_scheme = HTTPBearer(auto_error=False)


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(plain.encode(), hashed.encode())
    except Exception:
        return False


def create_token(user_id: str, role: str) -> str:
    expire = datetime.utcnow() + timedelta(days=ACCESS_TOKEN_EXPIRE_DAYS)
    return jwt.encode({"sub": user_id, "role": role, "exp": expire}, SECRET_KEY, algorithm=ALGORITHM)


def decode_token(token: str) -> Optional[dict]:
    try:
        return jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
    except JWTError:
        return None


async def get_current_user(
    cred: Optional[HTTPAuthorizationCredentials] = Depends(bearer_scheme),
    db: AsyncSession = Depends(get_db),
) -> models.User:
    if not cred:
        raise HTTPException(status_code=401, detail="Token yoxdur")
    payload = decode_token(cred.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Token etibarsızdır")
    result = await db.execute(select(models.User).where(models.User.id == payload["sub"]))
    user = result.scalar_one_or_none()
    if not user:
        raise HTTPException(status_code=401, detail="İstifadəçi tapılmadı")
    if user.is_blocked:
        raise HTTPException(status_code=403, detail="Hesab bloklanıb")
    return user


async def require_admin(user: models.User = Depends(get_current_user)) -> models.User:
    if user.role not in ("admin", "superadmin"):
        raise HTTPException(status_code=403, detail="Admin icazəsi tələb olunur")
    return user


async def require_superadmin(user: models.User = Depends(get_current_user)) -> models.User:
    if user.role != "superadmin":
        raise HTTPException(status_code=403, detail="Superadmin icazəsi tələb olunur")
    return user
