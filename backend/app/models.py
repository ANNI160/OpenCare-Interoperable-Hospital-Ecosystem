"""SQLAlchemy models for OpenCare Hospital Management System."""
import uuid
from datetime import datetime
from sqlalchemy import (
    Column, String, Integer, Float, Boolean, DateTime, Text, JSON,
    ForeignKey, Enum as SAEnum
)
from sqlalchemy.orm import relationship
from app.database import Base


def gen_uuid():
    return str(uuid.uuid4())


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False)
    password_hash = Column(String, nullable=False)
    employee_id = Column(String, unique=True, nullable=False)
    role = Column(String, nullable=False)  # 'nurse', 'doctor', 'admin', 'patient'
    assigned_ward = Column(String, nullable=True)
    specialization = Column(String, nullable=True)
    profile_image = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    is_online = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    last_login_at = Column(DateTime, nullable=True)


class Patient(Base):
    __tablename__ = "patients"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, nullable=False)
    age = Column(Integer, nullable=False)
    gender = Column(String, nullable=False)
    diagnosis_summary = Column(Text, nullable=True)
    ward_number = Column(Integer, nullable=False)
    bed_number = Column(Integer, nullable=False)
    admission_date = Column(DateTime, default=datetime.utcnow)
    attending_doctor_id = Column(String, nullable=True)
    attending_doctor_name = Column(String, nullable=True)
    allergies = Column(JSON, default=list)
    special_notes = Column(Text, nullable=True)
    is_critical = Column(Boolean, default=False)
    status = Column(String, default="stable")  # stable, critical, pending
    assigned_nurse_id = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Vitals(Base):
    __tablename__ = "vitals"

    id = Column(String, primary_key=True, default=gen_uuid)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    recorded_by_id = Column(String, nullable=False)
    recorded_by_name = Column(String, nullable=False)
    timestamp = Column(DateTime, default=datetime.utcnow)
    heart_rate = Column(Integer, nullable=True)
    systolic_bp = Column(Integer, nullable=True)
    diastolic_bp = Column(Integer, nullable=True)
    oxygen_saturation = Column(Float, nullable=True)
    temperature = Column(Float, nullable=True)
    respiratory_rate = Column(Integer, nullable=True)
    glucose_level = Column(Float, nullable=True)
    notes = Column(Text, nullable=True)
    alerts = Column(JSON, default=dict)


class Medication(Base):
    __tablename__ = "medications"

    id = Column(String, primary_key=True, default=gen_uuid)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    name = Column(String, nullable=False)
    dosage = Column(String, nullable=False)
    route = Column(String, default="oral")  # oral, iv, im, sc, topical
    frequency = Column(String, default="once")  # once, bid, tid, qid, prn
    scheduled_time = Column(DateTime, nullable=True)
    administered_time = Column(DateTime, nullable=True)
    administered_by_id = Column(String, nullable=True)
    administered_by_name = Column(String, nullable=True)
    is_injection = Column(Boolean, default=False)
    is_administered = Column(Boolean, default=False)
    notes = Column(Text, nullable=True)
    prescribed_by_id = Column(String, nullable=False)
    prescribed_by_name = Column(String, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class PatientAccount(Base):
    __tablename__ = "patient_accounts"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, ForeignKey("users.id"), unique=True, nullable=False)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Appointment(Base):
    __tablename__ = "appointments"

    id = Column(String, primary_key=True, default=gen_uuid)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    patient_name = Column(String, nullable=False)
    doctor_id = Column(String, ForeignKey("users.id"), nullable=False)
    doctor_name = Column(String, nullable=False)
    appointment_time = Column(DateTime, nullable=False)
    reason = Column(Text, nullable=True)
    status = Column(String, default="scheduled")  # scheduled, completed, cancelled
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class MedicationReaction(Base):
    __tablename__ = "medication_reactions"

    id = Column(String, primary_key=True, default=gen_uuid)
    medication_id = Column(String, ForeignKey("medications.id"), nullable=False)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    patient_name = Column(String, nullable=False)
    reported_by_id = Column(String, ForeignKey("users.id"), nullable=False)
    reported_by_name = Column(String, nullable=False)
    reaction = Column(Text, nullable=False)
    severity = Column(String, default="mild")  # mild, moderate, severe
    started_at = Column(DateTime, nullable=True)
    notes = Column(Text, nullable=True)
    is_resolved = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)


class Message(Base):
    __tablename__ = "messages"

    id = Column(String, primary_key=True, default=gen_uuid)
    sender_id = Column(String, nullable=False)
    sender_name = Column(String, nullable=False)
    sender_role = Column(String, nullable=False)
    receiver_id = Column(String, nullable=False)
    receiver_name = Column(String, nullable=False)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    patient_name = Column(String, nullable=False)
    content = Column(Text, nullable=False)
    type = Column(String, default="text")  # text, voice, image
    sent_at = Column(DateTime, default=datetime.utcnow)
    is_delivered = Column(Boolean, default=True)
    is_read = Column(Boolean, default=False)
    delivered_at = Column(DateTime, nullable=True)
    read_at = Column(DateTime, nullable=True)
    attachment_url = Column(String, nullable=True)
    voice_note_path = Column(String, nullable=True)
    voice_duration_seconds = Column(Integer, nullable=True)


class Task(Base):
    __tablename__ = "tasks"

    id = Column(String, primary_key=True, default=gen_uuid)
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    is_completed = Column(Boolean, default=False)
    due_date = Column(DateTime, nullable=True)
    patient_id = Column(String, nullable=True)
    patient_name = Column(String, nullable=True)
    assigned_nurse_id = Column(String, nullable=False)
    assigned_nurse_name = Column(String, nullable=False)
    ward_number = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    completed_by_nurse_id = Column(String, nullable=True)
    completed_by_nurse_name = Column(String, nullable=True)
    completed_at = Column(DateTime, nullable=True)


class HospitalConfig(Base):
    __tablename__ = "hospital_config"

    id = Column(String, primary_key=True, default="default")
    total_wards = Column(Integer, default=5)
    beds_per_ward = Column(Integer, default=10)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=gen_uuid)
    user_id = Column(String, nullable=False)
    action = Column(String, nullable=False)
    entity_type = Column(String, nullable=False)
    entity_id = Column(String, nullable=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    metadata_ = Column("metadata", JSON, nullable=True)


class EmergencyEscalation(Base):
    __tablename__ = "emergency_escalations"

    id = Column(String, primary_key=True, default=gen_uuid)
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    patient_name = Column(String, nullable=False)
    ward_number = Column(Integer, nullable=False)
    bed_number = Column(Integer, nullable=False)
    severity = Column(String, default="critical")  # critical, urgent, warning
    reason = Column(String, default="Code Blue")
    status = Column(String, default="active")  # active, acknowledged, resolved
    triggered_by_id = Column(String, nullable=False)
    triggered_by_name = Column(String, nullable=False)
    triggered_at = Column(DateTime, default=datetime.utcnow)
    resolved_by_id = Column(String, nullable=True)
    resolved_by_name = Column(String, nullable=True)
    resolved_at = Column(DateTime, nullable=True)
    resolution_notes = Column(Text, nullable=True)
