"""Medication routes — prescribe and administer medications."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Medication, User, AuditLog
from app.auth import get_current_user
from app.schemas import MedicationCreate, MedicationResponse
import uuid

router = APIRouter(prefix="/medications", tags=["Medications"])


@router.get("/{patient_id}", response_model=list[MedicationResponse])
def get_medications(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Medication)
        .filter(Medication.patient_id == patient_id)
        .order_by(Medication.created_at.desc())
        .limit(50)
        .all()
    )


@router.get("/{patient_id}/pending", response_model=list[MedicationResponse])
def get_pending_medications(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Medication)
        .filter(Medication.patient_id == patient_id, Medication.is_administered == False)
        .order_by(Medication.scheduled_time.asc())
        .all()
    )


@router.post("", response_model=MedicationResponse, status_code=201)
def add_medication(
    data: MedicationCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    med = Medication(
        id=str(uuid.uuid4()),
        patient_id=data.patient_id,
        name=data.name,
        dosage=data.dosage,
        route=data.route,
        frequency=data.frequency,
        scheduled_time=data.scheduled_time,
        is_injection=data.is_injection,
        notes=data.notes,
        prescribed_by_id=user.id,
        prescribed_by_name=user.name,
    )
    db.add(med)
    db.add(AuditLog(id=str(uuid.uuid4()), user_id=user.id, action="prescribe_medication", entity_type="medication", entity_id=med.id, metadata_={"patient_id": data.patient_id, "name": data.name, "dosage": data.dosage}))
    db.commit()
    db.refresh(med)
    return med


@router.patch("/{medication_id}/administer", response_model=MedicationResponse)
def administer_medication(
    medication_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    med = db.query(Medication).filter(Medication.id == medication_id).first()
    if not med:
        raise HTTPException(404, "Medication not found")

    med.is_administered = True
    med.administered_time = datetime.utcnow()
    med.administered_by_id = user.id
    med.administered_by_name = user.name
    db.add(AuditLog(id=str(uuid.uuid4()), user_id=user.id, action="administer_medication", entity_type="medication", entity_id=medication_id, metadata_={"patient_id": med.patient_id, "name": med.name}))
    db.commit()
    db.refresh(med)
    return med
