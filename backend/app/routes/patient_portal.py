"""Patient portal routes for patient self-service module."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.auth import get_current_user
from app.database import get_db
from app.models import (
    Appointment,
    Message,
    Medication,
    MedicationReaction,
    Patient,
    PatientAccount,
    User,
    AuditLog,
)
from app.schemas import (
    AppointmentResponse,
    MedicationReactionCreate,
    MedicationReactionResponse,
    MedicationResponse,
    MessageResponse,
    PatientResponse,
)
import uuid

router = APIRouter(prefix="/patient-portal", tags=["Patient Portal"])


class PatientMessageCreate(BaseModel):
    content: str
    type: str = "text"
    voice_note_path: str | None = None
    voice_duration_seconds: int | None = None


def _get_linked_patient(db: Session, user: User) -> Patient:
    if user.role != "patient":
        raise HTTPException(403, "Patient role required")

    link = db.query(PatientAccount).filter(PatientAccount.user_id == user.id).first()
    if not link:
        raise HTTPException(404, "No patient profile linked to this account")

    patient = db.query(Patient).filter(Patient.id == link.patient_id).first()
    if not patient:
        raise HTTPException(404, "Linked patient not found")
    return patient


@router.get("/me", response_model=PatientResponse)
def get_my_patient_profile(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return _get_linked_patient(db, user)


@router.get("/me/appointments", response_model=list[AppointmentResponse])
def get_my_appointments(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _get_linked_patient(db, user)
    return (
        db.query(Appointment)
        .filter(Appointment.patient_id == patient.id)
        .order_by(Appointment.appointment_time.asc())
        .all()
    )


@router.get("/me/messages", response_model=list[MessageResponse])
def get_my_messages(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _get_linked_patient(db, user)
    return (
        db.query(Message)
        .filter(Message.patient_id == patient.id)
        .order_by(Message.sent_at.asc())
        .all()
    )


@router.post("/me/messages", response_model=MessageResponse, status_code=201)
def send_message_to_doctor(
    data: PatientMessageCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _get_linked_patient(db, user)

    if not patient.attending_doctor_id:
        raise HTTPException(400, "No attending doctor assigned")

    doctor = db.query(User).filter(User.id == patient.attending_doctor_id).first()
    if not doctor:
        raise HTTPException(404, "Assigned doctor not found")

    msg = Message(
        id=str(uuid.uuid4()),
        sender_id=user.id,
        sender_name=user.name,
        sender_role=user.role,
        receiver_id=doctor.id,
        receiver_name=doctor.name,
        patient_id=patient.id,
        patient_name=patient.name,
        content=data.content,
        type=data.type,
        voice_note_path=data.voice_note_path,
        voice_duration_seconds=data.voice_duration_seconds,
        delivered_at=datetime.utcnow(),
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)
    return msg


@router.get("/me/medications", response_model=list[MedicationResponse])
def get_my_medications(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _get_linked_patient(db, user)
    return (
        db.query(Medication)
        .filter(Medication.patient_id == patient.id)
        .order_by(Medication.created_at.desc())
        .all()
    )


@router.get("/me/reactions", response_model=list[MedicationReactionResponse])
def get_my_medication_reactions(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _get_linked_patient(db, user)
    return (
        db.query(MedicationReaction)
        .filter(MedicationReaction.patient_id == patient.id)
        .order_by(MedicationReaction.created_at.desc())
        .all()
    )


@router.post("/me/reactions", response_model=MedicationReactionResponse, status_code=201)
def report_medication_reaction(
    data: MedicationReactionCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    patient = _get_linked_patient(db, user)
    med = db.query(Medication).filter(Medication.id == data.medication_id).first()
    if not med:
        raise HTTPException(404, "Medication not found")
    if med.patient_id != patient.id:
        raise HTTPException(403, "Medication does not belong to your profile")

    reaction = MedicationReaction(
        id=str(uuid.uuid4()),
        medication_id=med.id,
        patient_id=patient.id,
        patient_name=patient.name,
        reported_by_id=user.id,
        reported_by_name=user.name,
        reaction=data.reaction,
        severity=data.severity,
        started_at=data.started_at,
        notes=data.notes,
    )
    db.add(reaction)
    db.add(AuditLog(
        id=str(uuid.uuid4()),
        user_id=user.id,
        action="report_medication_reaction",
        entity_type="medication_reaction",
        entity_id=reaction.id,
        metadata_={"medication_id": med.id, "severity": data.severity},
    ))
    db.commit()
    db.refresh(reaction)
    return reaction
