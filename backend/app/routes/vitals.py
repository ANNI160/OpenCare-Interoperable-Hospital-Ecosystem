"""Vitals routes — record and retrieve patient vitals."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Vitals, Patient, User, AuditLog
from app.auth import get_current_user
from app.schemas import VitalsCreate, VitalsResponse
import uuid

router = APIRouter(prefix="/vitals", tags=["Vitals"])

# Normal ranges for auto-alerting
NORMAL_RANGES = {
    "heart_rate": (60, 100),
    "oxygen_saturation": (95, 100),
    "temperature": (36.1, 37.2),
    "respiratory_rate": (12, 20),
    "glucose_level": (70, 140),
    "systolic_bp": (90, 120),
    "diastolic_bp": (60, 80),
}


def calculate_alerts(data: VitalsCreate) -> dict:
    alerts = {}
    d = data.model_dump()
    for key, (lo, hi) in NORMAL_RANGES.items():
        val = d.get(key)
        if val is not None:
            alerts[key] = not (lo <= val <= hi)
    return alerts


@router.get("/{patient_id}", response_model=list[VitalsResponse])
def get_vitals(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Vitals)
        .filter(Vitals.patient_id == patient_id)
        .order_by(Vitals.timestamp.desc())
        .limit(50)
        .all()
    )


@router.get("/{patient_id}/latest", response_model=VitalsResponse | None)
def get_latest_vitals(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Vitals)
        .filter(Vitals.patient_id == patient_id)
        .order_by(Vitals.timestamp.desc())
        .first()
    )


@router.post("", response_model=VitalsResponse, status_code=201)
def add_vitals(
    data: VitalsCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    alerts = calculate_alerts(data)
    vitals = Vitals(
        id=str(uuid.uuid4()),
        patient_id=data.patient_id,
        recorded_by_id=user.id,
        recorded_by_name=user.name,
        heart_rate=data.heart_rate,
        systolic_bp=data.systolic_bp,
        diastolic_bp=data.diastolic_bp,
        oxygen_saturation=data.oxygen_saturation,
        temperature=data.temperature,
        respiratory_rate=data.respiratory_rate,
        glucose_level=data.glucose_level,
        notes=data.notes,
        alerts=alerts,
    )
    db.add(vitals)
    db.add(AuditLog(id=str(uuid.uuid4()), user_id=user.id, action="record_vitals", entity_type="vitals", entity_id=vitals.id, metadata_={"patient_id": data.patient_id, "alerts": alerts}))

    # Auto-update patient status if alerts triggered
    has_alerts = any(alerts.values())
    if has_alerts:
        patient = db.query(Patient).filter(Patient.id == data.patient_id).first()
        if patient:
            patient.status = "pending"
            patient.updated_at = datetime.utcnow()

    db.commit()
    db.refresh(vitals)
    return vitals
