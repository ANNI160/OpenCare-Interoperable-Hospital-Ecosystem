"""Staff and Config routes — admin operations."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import User, HospitalConfig
from app.auth import get_current_user, hash_password
from app.schemas import (
    UserResponse, HospitalConfigResponse, HospitalConfigUpdate, SignUpRequest
)

router = APIRouter(tags=["Staff & Config"])


# ─── Staff ────────────────────────────────────
@router.get("/staff/doctors", response_model=list[UserResponse])
def get_doctors(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(User).filter(User.role == "doctor", User.is_active == True).all()


@router.get("/staff/nurses", response_model=list[UserResponse])
def get_nurses(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(User).filter(User.role == "nurse", User.is_active == True).all()


@router.get("/staff", response_model=list[UserResponse])
def get_all_staff(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return db.query(User).filter(User.is_active == True).all()


@router.delete("/staff/{user_id}")
def delete_staff(
    user_id: str,
    admin: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if admin.role != "admin":
        raise HTTPException(403, "Admin access required")
    target = db.query(User).filter(User.id == user_id).first()
    if not target:
        raise HTTPException(404, "User not found")
    db.delete(target)
    db.commit()
    return {"message": "Staff member deleted"}


# ─── Hospital Config ──────────────────────────
@router.get("/config", response_model=HospitalConfigResponse)
def get_config(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    config = db.query(HospitalConfig).filter(HospitalConfig.id == "default").first()
    if not config:
        config = HospitalConfig(id="default")
        db.add(config)
        db.commit()
        db.refresh(config)
    return config


@router.put("/config", response_model=HospitalConfigResponse)
def update_config(
    data: HospitalConfigUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.role != "admin":
        raise HTTPException(403, "Admin access required")
    config = db.query(HospitalConfig).filter(HospitalConfig.id == "default").first()
    if not config:
        config = HospitalConfig(id="default")
        db.add(config)
    config.total_wards = data.total_wards
    config.beds_per_ward = data.beds_per_ward
    config.updated_at = datetime.utcnow()
    db.commit()
    db.refresh(config)
    return config
