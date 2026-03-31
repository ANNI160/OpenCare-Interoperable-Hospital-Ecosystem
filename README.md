# OpenCare

> **Note on commit history**: Due to a GitHub issue where commits made in feature branches were not being reflected on my contribution graph, I committed all changes directly to `main` today. All work was done progressively — the single commit represents the full project, not a one-day build.

OpenCare is a full-stack hospital coordination system consisting of:

- A **FastAPI** backend (REST API) backed by **PostgreSQL**
- A **Flutter** client app (mobile/web) with role-based dashboards (admin, nurse, doctor, patient)

This repository is intended for local development and demonstrations, with Docker Compose providing a repeatable backend + database environment.

## Contents

- [Architecture](#architecture)
- [Technology Stack](#technology-stack)
- [Project Tree](#project-tree)
- [Module Documentation](#module-documentation)
- [Quick Start (Docker)](#quick-start-recommended-docker)
- [Running Locally Without Docker](#running-locally-without-docker-backend)
- [Running the Flutter App](#running-the-flutter-app)
- [Environment Variables](#environment-variables)
- [Database: Seed and Reset](#database-seed-and-reset)
- [API Reference](#api-reference)
- [Common Workflows](#common-workflows)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## Architecture

```
Flutter App  ──HTTP──▶  FastAPI Backend  ──SQLAlchemy──▶  PostgreSQL
```

- **PostgreSQL** stores all system data: users, patients, vitals, medications, tasks, appointments, messages, audit logs, and emergency escalations.
- **FastAPI backend** exposes REST endpoints for authentication and all clinical/workflow modules.
- **Flutter app** talks to the backend over HTTP and routes users to role-specific dashboards after login.

The backend auto-creates tables on startup and seeds demo data on first run when the database is empty.

---

## Technology Stack

**Backend**
- Python 3.11 (`python:3.11-slim` Docker image)
- FastAPI + Uvicorn
- SQLAlchemy (ORM)
- PostgreSQL driver: `psycopg2-binary`
- JWT auth via `python-jose`
- Pydantic v2 + `pydantic-settings`

**Database**
- PostgreSQL 15 (`postgres:15-alpine`)

**Frontend**
- Flutter (Dart SDK `^3.5.0`)
- Provider (state management)
- HTTP (networking)

---

## Project Tree

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

---

## Module Documentation

| Module | README |
|--------|--------|
| Backend (FastAPI) | [`backend/README.md`](./backend/README.md) |
| Flutter App | [`flutter_app/README.md`](./flutter_app/README.md) |

---

## Quick Start (Recommended: Docker)

### Prerequisites

- Docker Desktop (with Docker Compose)
- Flutter SDK (to run the client app)

### Steps

```bash
# 1. Copy environment file
cp .env.example .env

# 2. Start PostgreSQL + FastAPI
docker-compose up -d --build

# 3. Confirm containers are running
docker-compose ps
```

### Verify

| Service | URL |
|---------|-----|
| API root | `http://localhost:8000/` |
| Swagger UI | `http://localhost:8000/docs` |

---

## Running Locally Without Docker (Backend)

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

```bash
# Set your database URL
set DATABASE_URL=postgresql://hospital:hospital123@localhost:5432/hospital_db

uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## Running the Flutter App

### Install dependencies

```bash
cd flutter_app
flutter pub get
```

### Configure API Base URL

Edit `flutter_app/lib/config/api_config.dart`:

| Target | URL |
|--------|-----|
| Android emulator | `http://10.0.2.2:8000` |
| Web / localhost | `http://localhost:8000` |
| Physical device (USB) | Run `adb reverse tcp:8000 tcp:8000`, then use `http://localhost:8000` |

### Run

```bash
# Web
flutter run -d chrome

# Android (emulator or device)
flutter run
```

---

## Environment Variables

Create `.env` from `.env.example`. Required variables:

| Variable | Description |
|----------|-------------|
| `POSTGRES_USER` | PostgreSQL username |
| `POSTGRES_PASSWORD` | PostgreSQL password |
| `POSTGRES_DB` | Database name |
| `POSTGRES_PORT` | Host port mapped to container 5432 |
| `DATABASE_URL` | Full connection string used by the backend |
| `FASTAPI_PORT` | Host port for FastAPI |
| `SECRET_KEY` | JWT signing secret |

---

## Database: Seed and Reset

### Auto-seed

On backend startup, if the `users` table is empty, the backend loads `/app/seed_db.sql` and inserts demo data automatically.

### Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@geu.ac.in` | `123456` |
| Doctor | `doctor@geu.ac.in` | `123456` |
| Nurse | `nurse@geu.ac.in` | `123456` |

### Reset the Database

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
docker-compose restart backend
```

---

## API Reference

**Base URL**: `http://localhost:8000`

**Docs**: Swagger UI at `GET /docs` · OpenAPI JSON at `GET /openapi.json`

| Module | Route Prefix |
|--------|-------------|
| Authentication | `/auth/*` |
| Patients | `/patients/*` |
| Vitals | `/vitals/*` |
| Medications | `/medications/*` |
| Tasks | `/tasks/*` |
| Messages | `/messages/*` |
| Appointments | `/appointments/*` |
| Emergencies | `/emergencies/*` |
| Audit Logs | `/audit/*` |
| Patient Portal | `/patient-portal/*` |
| Staff / Config | `/staff/*`, `/config` |
| Seed Export | `GET /export-seed` |

---

## Common Workflows

### Add a new backend module

1. Create a router in `backend/app/routes/`
2. Register it in `backend/app/main.py` via `app.include_router(...)`
3. Add models in `backend/app/models.py`
4. Add schemas in `backend/app/schemas.py`

### Add or update Flutter screens

- UI lives under `flutter_app/lib/screens/` grouped by role (`admin/`, `doctor/`, `nurse/`, `patient/`)
- API calls go in `flutter_app/lib/services/`
- Base URL config is in `flutter_app/lib/config/api_config.dart`

---

## Troubleshooting

**Flutter can't reach the backend**
- Android emulator: use `10.0.2.2` not `localhost`
- Physical device: run `adb reverse tcp:8000 tcp:8000` or set the base URL to your machine's LAN IP

**Database changes not reflected**
- Run the reset script (`reset_db.sql`) and restart the backend container to re-trigger auto-seed

---

## Contributing

See [`CONTRIBUTING.md`](./CONTRIBUTING.md) for development guidelines, recommended tooling, and project structure notes.

---

## License

MIT License — see [`LICENSE`](./LICENSE).
