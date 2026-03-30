"""Emergency escalation routes — trigger, list, and resolve emergencies."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import EmergencyEscalation, AuditLog, User
from app.auth import get_current_user
from app.schemas import EmergencyCreate, EmergencyResolve, EmergencyResponse
import uuid

router = APIRouter(prefix="/emergencies", tags=["Emergencies"])


@router.post("", response_model=EmergencyResponse, status_code=201)
def trigger_emergency(
    data: EmergencyCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Trigger a new emergency escalation (Code Blue, etc.)."""
    emergency = EmergencyEscalation(
        id=str(uuid.uuid4()),
        patient_id=data.patient_id,
        patient_name=data.patient_name,
        ward_number=data.ward_number,
        bed_number=data.bed_number,
        severity=data.severity,
        reason=data.reason,
        status="active",
        triggered_by_id=user.id,
        triggered_by_name=user.name,
    )
    db.add(emergency)

    # Audit log
    log = AuditLog(
        id=str(uuid.uuid4()),
        user_id=user.id,
        action="trigger_emergency",
        entity_type="emergency",
        entity_id=emergency.id,
        metadata_={
            "patient_id": data.patient_id,
            "severity": data.severity,
            "reason": data.reason,
        },
    )
    db.add(log)

    db.commit()
    db.refresh(emergency)
    return emergency


@router.get("", response_model=list[EmergencyResponse])
def get_emergencies(
    status: str | None = None,
    ward_number: int | None = None,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List emergencies. Defaults to active if no filter provided."""
    q = db.query(EmergencyEscalation)
    if status:
        q = q.filter(EmergencyEscalation.status == status)
    if ward_number is not None:
        q = q.filter(EmergencyEscalation.ward_number == ward_number)
    return q.order_by(EmergencyEscalation.triggered_at.desc()).limit(50).all()


@router.get("/active", response_model=list[EmergencyResponse])
def get_active_emergencies(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get all currently active emergencies."""
    return (
        db.query(EmergencyEscalation)
        .filter(EmergencyEscalation.status == "active")
        .order_by(EmergencyEscalation.triggered_at.desc())
        .all()
    )


@router.patch("/{emergency_id}/acknowledge", response_model=EmergencyResponse)
def acknowledge_emergency(
    emergency_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Doctor acknowledges an emergency."""
    em = db.query(EmergencyEscalation).filter(EmergencyEscalation.id == emergency_id).first()
    if not em:
        raise HTTPException(404, "Emergency not found")
    em.status = "acknowledged"

    log = AuditLog(
        id=str(uuid.uuid4()),
        user_id=user.id,
        action="acknowledge_emergency",
        entity_type="emergency",
        entity_id=emergency_id,
    )
    db.add(log)
    db.commit()
    db.refresh(em)
    return em


@router.patch("/{emergency_id}/resolve", response_model=EmergencyResponse)
def resolve_emergency(
    emergency_id: str,
    data: EmergencyResolve,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Resolve an emergency."""
    em = db.query(EmergencyEscalation).filter(EmergencyEscalation.id == emergency_id).first()
    if not em:
        raise HTTPException(404, "Emergency not found")

    em.status = "resolved"
    em.resolved_by_id = user.id
    em.resolved_by_name = user.name
    em.resolved_at = datetime.utcnow()
    em.resolution_notes = data.resolution_notes

    log = AuditLog(
        id=str(uuid.uuid4()),
        user_id=user.id,
        action="resolve_emergency",
        entity_type="emergency",
        entity_id=emergency_id,
        metadata_={"resolution_notes": data.resolution_notes},
    )
    db.add(log)
    db.commit()
    db.refresh(em)
    return em
