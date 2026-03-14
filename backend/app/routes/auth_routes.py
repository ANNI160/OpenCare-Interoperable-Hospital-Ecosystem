"""Auth routes — signup, login, user management."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User
from app.auth import hash_password, verify_password, create_access_token, get_current_user
from app.schemas import (
    LoginRequest, SignUpRequest, TokenResponse, UserResponse, UserUpdate
)

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post("/signup", response_model=TokenResponse)
def signup(data: SignUpRequest, db: Session = Depends(get_db)):
    existing = db.query(User).filter(User.email == data.email).first()
    if existing:
        raise HTTPException(400, "Email already registered")

    existing_emp = db.query(User).filter(User.employee_id == data.employee_id).first()
    if existing_emp:
        raise HTTPException(400, "Employee ID already registered")

    user = User(
        name=data.name,
        email=data.email,
        password_hash=hash_password(data.password),
        employee_id=data.employee_id,
        role=data.role,
        assigned_ward=data.assigned_ward,
        specialization=data.specialization,
        last_login_at=datetime.utcnow(),
    )
    db.add(user)
    db.commit()
    db.refresh(user)

    token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(access_token=token, role=user.role)


@router.post("/login", response_model=TokenResponse)
def login(data: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == data.email).first()
    if not user or not verify_password(data.password, user.password_hash):
        raise HTTPException(401, "Invalid email or password")

    user.last_login_at = datetime.utcnow()
    user.is_online = True
    db.commit()

    token = create_access_token({"sub": user.id, "role": user.role})
    return TokenResponse(access_token=token, role=user.role)


@router.get("/me", response_model=UserResponse)
def get_me(user: User = Depends(get_current_user)):
    return user


@router.patch("/me", response_model=UserResponse)
def update_me(
    data: UserUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    for key, val in data.model_dump(exclude_unset=True).items():
        setattr(user, key, val)
    db.commit()
    db.refresh(user)
    return user


@router.post("/logout")
def logout(user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    user.is_online = False
    db.commit()
    return {"message": "Logged out"}
