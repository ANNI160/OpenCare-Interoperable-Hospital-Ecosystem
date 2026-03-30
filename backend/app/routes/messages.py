"""Message routes — per-patient communication hub."""
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.database import get_db
from app.models import Message, User
from app.auth import get_current_user
from app.schemas import MessageCreate, MessageResponse
import uuid

router = APIRouter(prefix="/messages", tags=["Messages"])


@router.get("/{patient_id}", response_model=list[MessageResponse])
def get_messages(
    patient_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    return (
        db.query(Message)
        .filter(Message.patient_id == patient_id)
        .order_by(Message.sent_at.asc())
        .all()
    )


@router.get("/unread/count")
def get_unread_count(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    count = (
        db.query(Message)
        .filter(Message.receiver_id == user.id, Message.is_read == False)
        .count()
    )
    return {"unread_count": count}


@router.post("", response_model=MessageResponse, status_code=201)
def send_message(
    data: MessageCreate,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    msg = Message(
        id=str(uuid.uuid4()),
        sender_id=user.id,
        sender_name=user.name,
        sender_role=user.role,
        receiver_id=data.receiver_id,
        receiver_name=data.receiver_name,
        patient_id=data.patient_id,
        patient_name=data.patient_name,
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


@router.patch("/{message_id}/read")
def mark_as_read(
    message_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    msg = db.query(Message).filter(Message.id == message_id).first()
    if not msg:
        raise HTTPException(404, "Message not found")
    msg.is_read = True
    msg.read_at = datetime.utcnow()
    db.commit()
    return {"message": "Marked as read"}
