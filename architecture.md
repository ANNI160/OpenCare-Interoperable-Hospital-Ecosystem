# OpenCare Architecture

This document describes the current architecture of OpenCare as implemented in this repository. It is written to match the existing code and runtime behavior.

## System overview

OpenCare is a two-tier application:

- **Flutter client** (`flutter_app/`): role-based UI for admin, nurse, doctor, and patient workflows.
- **FastAPI backend** (`backend/`): REST API providing authentication, coordination workflows, and data access.
- **PostgreSQL**: single primary datastore for users, patients, clinical records, messaging, tasks, audit logging, and emergency escalation.

The recommended local setup uses Docker Compose to run PostgreSQL and the backend. The Flutter app runs on the developer machine and calls the backend over HTTP.

## Runtime components

### Flutter app

- **Entry point**: `flutter_app/lib/main.dart`
- **Routing**: `flutter_app/lib/config/routes.dart` (role-based navigation after authentication)
- **State management**: Provider (`flutter_app/lib/providers/`)
- **API access**:
  - `flutter_app/lib/services/auth_service.dart` (authentication + token persistence)
  - `flutter_app/lib/services/database_service.dart` (domain API calls)
- **Backend URL**: `flutter_app/lib/config/api_config.dart`

### FastAPI backend

- **Entry point**: `backend/app/main.py`
- **Routing**: routers under `backend/app/routes/` are registered in `app.main`.
- **CORS**: permissive in development (allows all origins).
- **Database integration**:
  - `backend/app/config.py` loads settings (including `database_url`).
  - `backend/app/database.py` creates engine and provides a session dependency.
  - `backend/app/models.py` defines SQLAlchemy ORM models.
  - `backend/app/schemas.py` defines Pydantic request/response shapes.
- **Authentication**:
  - `backend/app/auth.py` provides JWT helpers and a bearer-token dependency (`get_current_user`).

### PostgreSQL

The database stores the application state and is the source of truth. In the Compose workflow:

- The Postgres container persists data in a named volume (`postgres_data`).
- The backend connects using `DATABASE_URL` (from `.env` / Compose environment).

## Data model (conceptual)

OpenCare uses a relational model with the following major entities:

- **User**: staff and patient accounts; includes `role`, `assigned_ward`, `specialization`, online status.
- **Patient**: ward/bed assignment, diagnosis summary, allergies, critical/stable status.
- **Vitals**: time-series vitals recorded for a patient with optional alert flags.
- **Medication**: orders and administrations linked to a patient and staff.
- **MedicationReaction**: reactions reported against a medication with severity and audit logging.
- **Message**: communication between roles linked to a patient context (text/voice/image metadata).
- **Task**: nurse tasks with completion metadata and ward association.
- **Appointment**: scheduled doctor/patient appointments with status.
- **EmergencyEscalation**: escalation events by severity and acknowledgement/resolution lifecycle.
- **AuditLog**: immutable record of key actions.
- **HospitalConfig**: ward/bed capacity configuration.
- **PatientAccount**: links a patient user account to a Patient record for portal access.

## Request flow

Typical request lifecycle:

1. Flutter sends HTTP request to the backend (base URL from `ApiConfig`).
2. For protected endpoints, Flutter includes `Authorization: Bearer <token>`.
3. FastAPI validates the JWT, resolves the user, and enforces role checks where needed.
4. FastAPI handlers use a SQLAlchemy session from the request dependency.
5. Data is read/written in Postgres and returned as JSON.

## Authentication and authorization

- **Authentication**: JWT bearer tokens created by the backend on login/signup.
- **Authorization**:
  - Many endpoints require an authenticated user.
  - Some flows enforce role requirements (admin overrides are typically allowed).

Operational note: the current backend implementation is intended for development/demo usage and should be hardened for production (see `DEPLOYMENT.md`).

## Seeding and demo data

The backend includes a development-oriented auto-seed flow:

- On startup, if the `users` table exists and is empty, it attempts to execute a seed SQL file inside the container at `/app/seed_db.sql`.
- In Docker Compose, the repository `seed_db.sql` is mounted into the backend container.

The backend also provides:

- `GET /export-seed`: exports the current database state to SQL (and writes `/app/seed_db.sql`).

## Deployment topology (recommended)

For production-like deployments, the common topology is:

- Reverse proxy (TLS termination) → FastAPI service
- Postgres on a managed service or dedicated host
- Object storage for user uploads (instead of local disk) if uploads are required at scale

See `DEPLOYMENT.md` for hardening and deployment notes aligned to this repository.

