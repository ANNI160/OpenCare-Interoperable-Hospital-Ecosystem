"""Appointment routes for doctor-patient scheduling."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models import Appointment, Patient, User, AuditLog, PatientAccount
from app.schemas import AppointmentCreate, AppointmentResponse, AppointmentUpdate
import uuid

router = APIRouter(prefix="/appointments", tags=["Appointments"])


@router.get("/patient/{patient_id}", response_model=list[AppointmentResponse])
def get_appointments_for_patient(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.role == "patient":
        link = (
            db.query(PatientAccount)
            .filter(PatientAccount.user_id == user.id, PatientAccount.patient_id == patient_id)
            .first()
        )
        if not link:
            raise HTTPException(403, "You can only view your own appointments")

    return (
        db.query(Appointment)
        .filter(Appointment.patient_id == patient_id)
        .order_by(Appointment.appointment_time.asc())
        .all()
    )


@router.post("", response_model=AppointmentResponse, status_code=201)
def create_appointment(
    data: AppointmentCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    if user.role not in {"doctor", "admin"}:
        raise HTTPException(403, "Only doctor/admin can create appointments")

    patient = db.query(Patient).filter(Patient.id == data.patient_id).first()
    if not patient:
        raise HTTPException(404, "Patient not found")

    appt = Appointment(
        id=str(uuid.uuid4()),
        patient_id=patient.id,
        patient_name=patient.name,
        doctor_id=user.id,
        doctor_name=user.name,
        appointment_time=data.appointment_time,
        reason=data.reason,
        notes=data.notes,
    )
    db.add(appt)
    db.add(AuditLog(
        id=str(uuid.uuid4()),
        user_id=user.id,
        action="create_appointment",
        entity_type="appointment",
        entity_id=appt.id,
        metadata_={"patient_id": patient.id, "doctor_id": user.id},
    ))
    db.commit()
    db.refresh(appt)
    return appt


@router.patch("/{appointment_id}", response_model=AppointmentResponse)
def update_appointment(
    appointment_id: str,
    data: AppointmentUpdate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    appt = db.query(Appointment).filter(Appointment.id == appointment_id).first()
    if not appt:
        raise HTTPException(404, "Appointment not found")

    if user.role not in {"doctor", "admin"}:
        raise HTTPException(403, "Only doctor/admin can update appointments")

    if user.role == "doctor" and appt.doctor_id != user.id:
        raise HTTPException(403, "You can only update your own appointments")

    changes = data.model_dump(exclude_unset=True)
    for key, val in changes.items():
        setattr(appt, key, val)
    appt.updated_at = datetime.utcnow()

    db.add(AuditLog(
        id=str(uuid.uuid4()),
        user_id=user.id,
        action="update_appointment",
        entity_type="appointment",
        entity_id=appointment_id,
        metadata_=changes,
    ))
    db.commit()
    db.refresh(appt)
    return appt
