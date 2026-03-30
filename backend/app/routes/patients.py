"""Patient routes — CRUD, ward/bed queries."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.models import Patient, User, AuditLog
from app.auth import get_current_user
from app.schemas import PatientCreate, PatientUpdate, PatientResponse
import uuid

router = APIRouter(prefix="/patients", tags=["Patients"])


@router.get("", response_model=list[PatientResponse])
def get_patients(
    ward_number: Optional[int] = None,
    doctor_id: Optional[str] = None,
    status: Optional[str] = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    q = db.query(Patient)
    if ward_number is not None:
        q = q.filter(Patient.ward_number == ward_number)
    if doctor_id is not None:
        q = q.filter(Patient.attending_doctor_id == doctor_id)
    if status is not None:
        q = q.filter(Patient.status == status)
    return q.order_by(Patient.ward_number, Patient.bed_number).limit(100).all()


@router.get("/ward/{ward_number}/bed/{bed_number}", response_model=Optional[PatientResponse])
def get_patient_by_ward_bed(
    ward_number: int,
    bed_number: int,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = db.query(Patient).filter(
        Patient.ward_number == ward_number,
        Patient.bed_number == bed_number,
    ).first()
    return patient


@router.get("/{patient_id}", response_model=PatientResponse)
def get_patient(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(404, "Patient not found")
    return patient


@router.post("", response_model=PatientResponse, status_code=201)
def create_patient(
    data: PatientCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = Patient(
        id=str(uuid.uuid4()),
        **data.model_dump(),
    )
    db.add(patient)
    db.add(AuditLog(id=str(uuid.uuid4()), user_id=user.id, action="create_patient", entity_type="patient", entity_id=patient.id, metadata_={"name": data.name, "ward": data.ward_number, "bed": data.bed_number}))
    db.commit()
    db.refresh(patient)
    return patient


@router.put("/{patient_id}", response_model=PatientResponse)
def update_patient(
    patient_id: str,
    data: PatientUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(404, "Patient not found")

    changes = data.model_dump(exclude_unset=True)
    for key, val in changes.items():
        setattr(patient, key, val)
    patient.updated_at = datetime.utcnow()
    db.add(AuditLog(id=str(uuid.uuid4()), user_id=user.id, action="update_patient", entity_type="patient", entity_id=patient_id, metadata_=changes))
    db.commit()
    db.refresh(patient)
    return patient
