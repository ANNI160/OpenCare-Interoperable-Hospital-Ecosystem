"""Pydantic schemas for OpenCare API."""
from pydantic import BaseModel
from typing import Optional, List, Dict, Any
from datetime import datetime


# ─── Auth ─────────────────────────────────────────
class LoginRequest(BaseModel):
    email: str
    password: str

class SignUpRequest(BaseModel):
    email: str
    password: str
    name: str
    employee_id: str
    role: str  # nurse, doctor, admin, patient
    assigned_ward: Optional[str] = None
    specialization: Optional[str] = None
    patient_id: Optional[str] = None

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str = ""
    token_type: str = "bearer"
    expires_in: int = 86400
    role: Optional[str] = None

class UserResponse(BaseModel):
    id: str
    name: str
    email: str
    employee_id: str
    role: str
    assigned_ward: Optional[str] = None
    specialization: Optional[str] = None
    profile_image: Optional[str] = None
    is_active: bool = True
    is_online: bool = False
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class UserUpdate(BaseModel):
    name: Optional[str] = None
    assigned_ward: Optional[str] = None
    specialization: Optional[str] = None
    is_online: Optional[bool] = None


# ─── Patient ─────────────────────────────────────
class PatientCreate(BaseModel):
    name: str
    age: int
    gender: str
    diagnosis_summary: Optional[str] = None
    ward_number: int
    bed_number: int
    attending_doctor_id: Optional[str] = None
    attending_doctor_name: Optional[str] = None
    allergies: List[str] = []
    special_notes: Optional[str] = None
    is_critical: bool = False
    status: str = "stable"
    assigned_nurse_id: Optional[str] = None

class PatientUpdate(BaseModel):
    name: Optional[str] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    diagnosis_summary: Optional[str] = None
    ward_number: Optional[int] = None
    bed_number: Optional[int] = None
    attending_doctor_id: Optional[str] = None
    attending_doctor_name: Optional[str] = None
    allergies: Optional[List[str]] = None
    special_notes: Optional[str] = None
    is_critical: Optional[bool] = None
    status: Optional[str] = None
    assigned_nurse_id: Optional[str] = None

class PatientResponse(BaseModel):
    id: str
    name: str
    age: int
    gender: str
    diagnosis_summary: Optional[str] = None
    ward_number: int
    bed_number: int
    admission_date: datetime
    attending_doctor_id: Optional[str] = None
    attending_doctor_name: Optional[str] = None
    allergies: List[str] = []
    special_notes: Optional[str] = None
    is_critical: bool = False
    status: str
    assigned_nurse_id: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─── Vitals ──────────────────────────────────────
class VitalsCreate(BaseModel):
    patient_id: str
    heart_rate: Optional[int] = None
    systolic_bp: Optional[int] = None
    diastolic_bp: Optional[int] = None
    oxygen_saturation: Optional[float] = None
    temperature: Optional[float] = None
    respiratory_rate: Optional[int] = None
    glucose_level: Optional[float] = None
    notes: Optional[str] = None

class VitalsResponse(BaseModel):
    id: str
    patient_id: str
    recorded_by_id: str
    recorded_by_name: str
    timestamp: datetime
    heart_rate: Optional[int] = None
    systolic_bp: Optional[int] = None
    diastolic_bp: Optional[int] = None
    oxygen_saturation: Optional[float] = None
    temperature: Optional[float] = None
    respiratory_rate: Optional[int] = None
    glucose_level: Optional[float] = None
    notes: Optional[str] = None
    alerts: Dict[str, bool] = {}

    class Config:
        from_attributes = True


# ─── Medication ──────────────────────────────────
class MedicationCreate(BaseModel):
    patient_id: str
    name: str
    dosage: str
    route: str = "oral"
    frequency: str = "once"
    scheduled_time: Optional[datetime] = None
    is_injection: bool = False
    notes: Optional[str] = None

class MedicationAdminister(BaseModel):
    pass  # User info comes from token

class MedicationResponse(BaseModel):
    id: str
    patient_id: str
    name: str
    dosage: str
    route: str
    frequency: str
    scheduled_time: Optional[datetime] = None
    administered_time: Optional[datetime] = None
    administered_by_id: Optional[str] = None
    administered_by_name: Optional[str] = None
    is_injection: bool
    is_administered: bool
    notes: Optional[str] = None
    prescribed_by_id: str
    prescribed_by_name: str
    created_at: datetime

    class Config:
        from_attributes = True


class MedicationReactionCreate(BaseModel):
    medication_id: str
    reaction: str
    severity: str = "mild"
    started_at: Optional[datetime] = None
    notes: Optional[str] = None


class MedicationReactionResponse(BaseModel):
    id: str
    medication_id: str
    patient_id: str
    patient_name: str
    reported_by_id: str
    reported_by_name: str
    reaction: str
    severity: str
    started_at: Optional[datetime] = None
    notes: Optional[str] = None
    is_resolved: bool
    created_at: datetime

    class Config:
        from_attributes = True


class AppointmentCreate(BaseModel):
    patient_id: str
    appointment_time: datetime
    reason: Optional[str] = None
    notes: Optional[str] = None


class AppointmentUpdate(BaseModel):
    appointment_time: Optional[datetime] = None
    reason: Optional[str] = None
    status: Optional[str] = None
    notes: Optional[str] = None


class AppointmentResponse(BaseModel):
    id: str
    patient_id: str
    patient_name: str
    doctor_id: str
    doctor_name: str
    appointment_time: datetime
    reason: Optional[str] = None
    status: str
    notes: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ─── Message ────────────────────────────────────
class MessageCreate(BaseModel):
    receiver_id: str
    receiver_name: str
    patient_id: str
    patient_name: str
    content: str
    type: str = "text"
    voice_note_path: Optional[str] = None
    voice_duration_seconds: Optional[int] = None

class MessageResponse(BaseModel):
    id: str
    sender_id: str
    sender_name: str
    sender_role: str
    receiver_id: str
    receiver_name: str
    patient_id: str
    patient_name: str
    content: str
    type: str
    sent_at: datetime
    is_delivered: bool
    is_read: bool
    delivered_at: Optional[datetime] = None
    read_at: Optional[datetime] = None
    attachment_url: Optional[str] = None
    voice_note_path: Optional[str] = None
    voice_duration_seconds: Optional[int] = None

    class Config:
        from_attributes = True


# ─── Task ───────────────────────────────────────
class TaskCreate(BaseModel):
    title: str
    description: Optional[str] = None
    due_date: Optional[datetime] = None
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None
    ward_number: int

class TaskUpdate(BaseModel):
    is_completed: bool

class TaskResponse(BaseModel):
    id: str
    title: str
    description: Optional[str] = None
    is_completed: bool
    due_date: Optional[datetime] = None
    patient_id: Optional[str] = None
    patient_name: Optional[str] = None
    assigned_nurse_id: str
    assigned_nurse_name: str
    ward_number: int
    created_at: datetime
    completed_by_nurse_id: Optional[str] = None
    completed_by_nurse_name: Optional[str] = None
    completed_at: Optional[datetime] = None

    class Config:
        from_attributes = True


# ─── Hospital Config ────────────────────────────
class HospitalConfigResponse(BaseModel):
    total_wards: int = 5
    beds_per_ward: int = 10

class HospitalConfigUpdate(BaseModel):
    total_wards: int
    beds_per_ward: int


# ─── Audit Log ──────────────────────────────────
class AuditLogCreate(BaseModel):
    action: str
    entity_type: str
    entity_id: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None

class AuditLogResponse(BaseModel):
    id: str
    user_id: str
    action: str
    entity_type: str
    entity_id: Optional[str] = None
    timestamp: datetime
    metadata_: Optional[Dict[str, Any]] = None

    class Config:
        from_attributes = True


# ─── Emergency Escalation ───────────────────────
class EmergencyCreate(BaseModel):
    patient_id: str
    patient_name: str
    ward_number: int
    bed_number: int
    severity: str = "critical"  # critical, urgent, warning
    reason: str = "Code Blue"

class EmergencyResolve(BaseModel):
    resolution_notes: Optional[str] = None

class EmergencyResponse(BaseModel):
    id: str
    patient_id: str
    patient_name: str
    ward_number: int
    bed_number: int
    severity: str
    reason: str
    status: str
    triggered_by_id: str
    triggered_by_name: str
    triggered_at: datetime
    resolved_by_id: Optional[str] = None
    resolved_by_name: Optional[str] = None
    resolved_at: Optional[datetime] = None
    resolution_notes: Optional[str] = None

    class Config:
        from_attributes = True
