"""Audit log routes — query the full audit trail."""
from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import Optional
from app.database import get_db
from app.models import AuditLog, User
from app.auth import get_current_user
from app.schemas import AuditLogResponse

router = APIRouter(prefix="/audit", tags=["Audit Trail"])


@router.get("", response_model=list[AuditLogResponse])
def get_audit_logs(
    entity_type: Optional[str] = None,
    user_id: Optional[str] = None,
    limit: int = Query(default=100, le=500),
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """List audit log entries with optional filters."""
    q = db.query(AuditLog)
    if entity_type:
        q = q.filter(AuditLog.entity_type == entity_type)
    if user_id:
        q = q.filter(AuditLog.user_id == user_id)
    return q.order_by(AuditLog.timestamp.desc()).limit(limit).all()
