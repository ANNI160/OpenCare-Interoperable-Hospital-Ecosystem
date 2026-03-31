# OpenCare: Hospital Coordination System

OpenCare is a fully open-source, self-hosted hospital coordination platform designed to streamline healthcare operations through real-time collaboration and structured digital workflows. It reduces dependency on manual systems by digitizing critical hospital processes and improving coordination between doctors, nurses, and administrative staff.

Built as a full-stack system consisting of:

- A **FastAPI** backend (REST API) backed by **PostgreSQL**
- A **Flutter** client app (mobile/web) with role-based dashboards (admin, nurse, doctor, patient)

This repository is intended for local development and demonstrations, with Docker Compose providing a repeatable backend + database environment.

## Contents

- [Key features](#key-features)
- [Architecture](#architecture)
- [Technology stack](#technology-stack)
- [Project tree](#project-tree)
- [Module documentation](#module-documentation)
- [Quick start (recommended: Docker)](#quick-start-recommended-docker)
- [Running locally without Docker (backend)](#running-locally-without-docker-backend)
- [Running the Flutter app](#running-the-flutter-app)
- [Environment variables](#environment-variables)
- [Database: seed and reset](#database-seed-and-reset)
- [API reference](#api-reference)
- [Common workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

## Key features

- **ICU-centric automation**: Nurses can capture vitals at the bedside (tablet/mobile), enabling immediate data capture. Updates reflect on the doctor dashboard for near real-time monitoring and faster clinical response.
- **Role-based dashboards**: Purpose-built dashboards for doctors, nurses, administrators, and patients to reduce operational complexity and keep workflows focused.
- **Patient admission and bed management**: Structured workflows for admission and ward/bed allocation to keep occupancy and assignments accurate.
- **Vitals monitoring and alerts**: Digital vitals capture with alerting cues for abnormal readings to support timely intervention.
- **Medication and treatment tracking**: Digital prescribing and real-time administration tracking to improve accountability and reduce errors.
- **Communication and task management**: Patient-context communication plus ward-level task assignment for coordinated team delivery.
- **Audit logs and administrative control**: Administrative controls and audit trails to support transparency and operational governance.

## Architecture

At a high level:

- **PostgreSQL** stores all system data (users, patients, vitals, medications, tasks, appointments, messages, audit logs, emergency escalations).
- **FastAPI backend** exposes REST endpoints for authentication and all clinical/workflow modules.
- **Flutter app** talks to the backend over HTTP and routes users to role-specific dashboards after login.

The backend auto-creates tables on startup and can auto-seed demo data on first run when the database is empty.

## Technology stack

- **Backend**
  - Python 3.11 (Docker image uses `python:3.11-slim`)
  - FastAPI + Uvicorn
  - SQLAlchemy (ORM)
  - PostgreSQL driver: `psycopg2-binary`
  - JWT auth via `python-jose`
  - Pydantic v2 + `pydantic-settings`
- **Database**
  - PostgreSQL 15 (Compose uses `postgres:15-alpine`)
- **Frontend**
  - Flutter (SDK constraint in `flutter_app/pubspec.yaml`: Dart SDK `^3.5.0`)
  - Provider (state management)
  - HTTP (networking)

## Project tree

The full workspace contains Flutter build artifacts (for example `.dart_tool/`, `build/`, plugin symlinks, and `__pycache__/`). For clarity, this tree focuses on the *source* and operational files you typically edit.

```text
OPENCARE/
├─ .env.example
├─ docker-compose.yml
├─ seed_db.sql
├─ reset_db.sql
├─ CONTRIBUTING.md
├─ LICENSE
├─ backend/
│  ├─ Dockerfile
│  ├─ requirements.txt
│  ├─ seed_db.sql
│  └─ app/
│     ├─ main.py
│     ├─ config.py
│     ├─ database.py
│     ├─ auth.py
│     ├─ models.py
│     ├─ schemas.py
│     └─ routes/
│        ├─ auth_routes.py
│        ├─ patients.py
│        ├─ vitals.py
│        ├─ medications.py
│        ├─ messages.py
│        ├─ tasks.py
│        ├─ appointments.py
│        ├─ emergencies.py
│        ├─ staff_config.py
│        ├─ audit_logs.py
│        └─ patient_portal.py
└─ flutter_app/
   ├─ pubspec.yaml
   └─ lib/
      ├─ main.dart
      ├─ config/
      │  ├─ api_config.dart
      │  ├─ app_theme.dart
      │  ├─ routes.dart
      │  └─ constants.dart
      ├─ models/
      ├─ providers/
      ├─ screens/
      │  ├─ login_screen.dart
      │  ├─ settings_screen.dart
      │  ├─ splash_screen.dart
      │  ├─ admin/
      │  ├─ doctor/
      │  ├─ nurse/
      │  └─ patient/
      ├─ services/
      │  ├─ auth_service.dart
      │  └─ database_service.dart
      ├─ utils/
      └─ widgets/
```

## Module documentation

- Backend (FastAPI): `backend/README.md`
- Flutter app: `flutter_app/README.md`
- Full run guide (stack): `HOW_TO_RUN.md`

## Quick start (recommended: Docker)

### Prerequisites

- Docker Desktop (with Docker Compose)
- Flutter SDK (to run the client app)

### Start backend + database

From the repository root:

```bash
# 1) Create your local env file
cp .env.example .env

# 2) Start PostgreSQL + FastAPI
docker-compose up -d --build

# 3) Confirm containers are running
docker-compose ps
```

### Verify the API

- **API**: `http://localhost:8000/`
- **Swagger UI**: `http://localhost:8000/docs`

## Running locally without Docker (backend)

You can also run the backend directly with a local Python installation, but you must have a PostgreSQL instance available and a correct `DATABASE_URL`.

### Prerequisites

- Python 3.11+
- PostgreSQL 15+

### Setup

```bash
cd backend
python -m venv .venv

# Windows (PowerShell)
.venv\Scripts\Activate.ps1

pip install -r requirements.txt
```

### Run

Set `DATABASE_URL` to point to your database (example for local Postgres on port 5432):

```bash
set DATABASE_URL=postgresql://hospital:hospital123@localhost:5432/hospital_db
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## Running the Flutter app

### Install dependencies

```bash
cd flutter_app
flutter pub get
```

### Configure API base URL

The client’s base URL is defined in `flutter_app/lib/config/api_config.dart`:

- For **Android emulator**, use `http://10.0.2.2:8000`
- For **web** and many **physical device** workflows, use `http://localhost:8000`

If you run on a physical Android device over USB, you can forward the backend port:

```bash
adb reverse tcp:8000 tcp:8000
```

### Run

```bash
# Web
flutter run -d chrome

# Android (emulator or device)
flutter run
```

## Environment variables

The backend container reads environment variables from Compose. Start with `.env.example` and create `.env`.

### Required (Docker Compose)

- **POSTGRES_USER**
- **POSTGRES_PASSWORD**
- **POSTGRES_DB**
- **POSTGRES_PORT**: host port mapped to container 5432
- **DATABASE_URL**: used by the backend (in Compose it points to `postgres` service)
- **FASTAPI_PORT**
- **SECRET_KEY**

Note: the backend settings loader (`backend/app/config.py`) uses `env_file = ".env"`. In Docker, Compose provides env vars directly; locally, you can rely on `.env` if you run from the correct working directory.

## Database: seed and reset

### Auto-seed behavior

On backend startup, if the `users` table exists and is empty, the backend attempts to load `/app/seed_db.sql` (mounted from the repository’s `seed_db.sql`) and inserts demo data.

### Demo accounts (seeded)

The provided `seed_db.sql` includes example users:

- **Admin**: `admin@geu.ac.in`
- **Doctor**: `doctor@geu.ac.in`
- **Nurse**: `nurse@geu.ac.in`

Passwords are stored as SHA-256 hashes in the seed. In this dataset, the hash corresponds to the common demo password `123456`.

### Reset the database

To wipe the schema and let SQLAlchemy recreate tables:

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
```

After reset, restart the backend container to trigger auto-seed (only runs when the DB is empty):

```bash
docker-compose restart backend
```

## API reference

### Base URL

- Local (Compose): `http://localhost:8000`

### Documentation

- Swagger UI: `GET /docs`
- OpenAPI JSON: `GET /openapi.json`

### Main modules (high level)

Routes are organized under `backend/app/routes/`:

- **Authentication**: `/auth/*` (signup, login, current user, logout)
- **Patients**: `/patients/*`
- **Vitals**: `/vitals/*`
- **Medications**: `/medications/*` (including pending/administration flows)
- **Tasks**: `/tasks/*`
- **Messages**: `/messages/*`
- **Appointments**: `/appointments/*`
- **Emergencies**: `/emergencies/*`
- **Audit logs**: `/audit/*`
- **Patient portal**: `/patient-portal/*` (patient self-service endpoints)
- **Staff/config**: `/staff/*`, `/config`

### Exporting demo seed data

The backend exposes an admin endpoint to export current data into a seed SQL file:

- `GET /export-seed` (returns SQL and writes `/app/seed_db.sql` in the container)

## Common workflows

### Add a new backend module

- Create a new router in `backend/app/routes/`
- Register it in `backend/app/main.py` via `app.include_router(...)`
- Add models in `backend/app/models.py` and request/response schemas in `backend/app/schemas.py` as needed

### Add or update Flutter screens

- UI lives under `flutter_app/lib/screens/` grouped by role (`admin/`, `doctor/`, `nurse/`, `patient/`)
- API calls are centralized in `flutter_app/lib/services/`
- Base URL configuration is in `flutter_app/lib/config/api_config.dart`

## Troubleshooting

### Backend container is up but Flutter can’t reach it

- If running on **Android emulator**, confirm the app uses `10.0.2.2` (not `localhost`).
- If running on a **physical device**, use:
  - `adb reverse tcp:8000 tcp:8000` (USB)
  - or update the base URL to your machine’s LAN IP and ensure firewall rules allow inbound traffic.

### Database changes not reflected

- The backend auto-creates tables on startup via `Base.metadata.create_all(...)`.
- If your schema is in a bad state during development, run the reset script (`reset_db.sql`) and restart the backend to re-seed.

## Contributing

See `CONTRIBUTING.md` for development guidelines, recommended tooling, and project structure notes.

## License

MIT License. See `LICENSE`.
