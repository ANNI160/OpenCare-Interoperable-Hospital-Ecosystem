# OpenCare — Backend (FastAPI)

This directory contains the OpenCare backend API built with FastAPI and SQLAlchemy, using PostgreSQL as the primary datastore.

The recommended way to run the backend for local development is via the repository root `docker-compose.yml`, which starts both PostgreSQL and the backend together with sensible defaults.

## Contents

- [Overview](#overview)
- [Key Modules](#key-modules)
- [Run with Docker Compose](#run-with-docker-compose-recommended)
- [Run Locally Without Docker](#run-locally-without-docker)
- [Configuration](#configuration)
- [Database: Schema, Seed, Reset](#database-schema-seed-reset)
- [API Documentation](#api-documentation)
- [Code Structure](#code-structure)

---

## Overview

| Concern | Technology |
|---------|-----------|
| Framework | FastAPI |
| Server | Uvicorn |
| ORM | SQLAlchemy |
| Auth | JWT bearer tokens (`python-jose`) |
| Database | PostgreSQL 15 |
| Settings | `pydantic-settings` |

**Entry point**: `app.main:app`

---

## Key Modules

Routes are split into separate files under `app/routes/`:

| Route Prefix | Module File | Description |
|-------------|-------------|-------------|
| `/auth/*` | `auth_routes.py` | Signup, login, current user, logout |
| `/patients/*` | `patients.py` | Patient records CRUD |
| `/vitals/*` | `vitals.py` | Vital signs recording and retrieval |
| `/medications/*` | `medications.py` | Medication orders, pending/administration flows |
| `/tasks/*` | `tasks.py` | Clinical task management |
| `/messages/*` | `messages.py` | In-system messaging |
| `/appointments/*` | `appointments.py` | Appointment scheduling |
| `/emergencies/*` | `emergencies.py` | Emergency escalation workflows |
| `/audit/*` | `audit_logs.py` | Audit trail |
| `/config` | `staff_config.py` | Hospital configuration |
| `/staff/*` | `staff_config.py` | Staff listing and management |
| `/patient-portal/*` | `patient_portal.py` | Patient self-service endpoints |
| `GET /export-seed` | `main.py` | Export current DB data as seed SQL |

---

## Run with Docker Compose (Recommended)

From the **repository root**:

```bash
cp .env.example .env
docker-compose up -d --build
```

**Verify the API is running:**

| Endpoint | URL |
|----------|-----|
| API root | `http://localhost:8000/` |
| Swagger UI | `http://localhost:8000/docs` |

**View logs:**

```bash
docker-compose logs -f backend
```

---

## Run Locally Without Docker

### Prerequisites

- Python 3.11+
- PostgreSQL 15+ (running and accessible)

### Setup

```bash
# From the backend/ directory
python -m venv .venv
```

**Activate the virtual environment:**

```bash
# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# macOS / Linux
source .venv/bin/activate
```

**Install dependencies:**

```bash
pip install -r requirements.txt
```

### Configure Environment

Set the minimum required variable:

```bash
# Windows (PowerShell)
$env:DATABASE_URL="postgresql://hospital:hospital123@localhost:5432/hospital_db"

# macOS / Linux
export DATABASE_URL="postgresql://hospital:hospital123@localhost:5432/hospital_db"
```

### Start the Server

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

---

## Configuration

Settings are defined in `app/config.py` using `pydantic-settings`.

| Variable | Description |
|----------|-------------|
| `DATABASE_URL` | Full PostgreSQL connection string |
| `SECRET_KEY` | JWT signing secret |
| `FASTAPI_PORT` | Port the server listens on |

- In **Docker**, environment variables are provided directly by Compose.
- In **local runs**, you can use a `.env` file (see root `.env.example`) if running from the correct working directory.

---

## Database: Schema, Seed, Reset

### Schema Creation

On startup, the backend calls `Base.metadata.create_all(...)` to create all tables. This is intended for development and demo usage — not for production migrations.

### Auto-Seed

If the `users` table exists and is **empty**, the backend automatically loads and executes:

```
/app/seed_db.sql
```

In the Docker Compose workflow, the root-level `seed_db.sql` is mounted into the container at this path.

### Demo Accounts

| Role | Email | Password |
|------|-------|----------|
| Admin | `admin@geu.ac.in` | `123456` |
| Doctor | `doctor@geu.ac.in` | `123456` |
| Nurse | `nurse@geu.ac.in` | `123456` |

Passwords are stored as SHA-256 hashes in the seed file.

### Reset the Database

Wipe the schema and re-seed from scratch:

```bash
# From repository root
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
docker-compose restart backend
```

The backend will auto-seed again on restart when it detects an empty `users` table.

---

## API Documentation

| Type | URL |
|------|-----|
| Swagger UI (interactive) | `GET http://localhost:8000/docs` |
| OpenAPI JSON | `GET http://localhost:8000/openapi.json` |

---

## Code Structure

```text
backend/
├─ Dockerfile
├─ requirements.txt
└─ app/
   ├─ main.py        # App init, router registration, seed/export logic
   ├─ config.py      # Settings loader (pydantic-settings)
   ├─ database.py    # Engine, session factory, get_db dependency
   ├─ auth.py        # Password hashing, JWT helpers, auth dependency
   ├─ models.py      # SQLAlchemy ORM models
   ├─ schemas.py     # Pydantic request/response schemas
   └─ routes/
      ├─ auth_routes.py
      ├─ patients.py
      ├─ vitals.py
      ├─ medications.py
      ├─ messages.py
      ├─ tasks.py
      ├─ appointments.py
      ├─ emergencies.py
      ├─ staff_config.py
      ├─ audit_logs.py
      └─ patient_portal.py
```
