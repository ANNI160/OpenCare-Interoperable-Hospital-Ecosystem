# Contributing to OpenCare

Thank you for your interest in contributing to **OpenCare**! This guide will help you get started.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Making Changes](#making-changes)
- [Coding Guidelines](#coding-guidelines)
- [Submitting a Pull Request](#submitting-a-pull-request)
- [Reporting Issues](#reporting-issues)

## Code of Conduct

By participating in this project you agree to treat all contributors with respect and foster an inclusive, welcoming environment.

## Getting Started

1. **Fork** this repository
2. **Clone** your fork locally
3. **Create a branch** for your feature or fix
4. **Make your changes** and test them
5. **Submit a Pull Request**

## Development Setup

### Prerequisites

| Tool | Version |
|------|---------|
| Docker & Docker Compose | Latest |
| Flutter SDK | 3.5+ |
| Dart | 3.0+ |
| Git | 2.x+ |

### Backend (Docker)

```bash
# 1. Copy the environment file
cp .env.example .env

# 2. Start PostgreSQL + FastAPI
docker-compose up -d

# 3. Verify services are running
docker-compose ps

# 4. API is now available at http://localhost:8000
# 5. Swagger docs at http://localhost:8000/docs
```

### Flutter App

```bash
cd flutter_app

# Install dependencies
flutter pub get

# Run on Chrome (web)
flutter run -d chrome

# Run on Android emulator
flutter run

# Run on a physical device (USB debugging enabled)
adb reverse tcp:8000 tcp:8000
flutter run
```

### Database

The database schema is auto-created on first backend startup. To reset:

```bash
# Connect to the running PostgreSQL container
docker exec -it opencare-postgres psql -U hospital -d hospital_db

# Or use the reset script
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
```

## Project Structure

```
OpenCare/
├── backend/                 # FastAPI REST API
│   ├── app/
│   │   ├── main.py          # App entrypoint & router registration
│   │   ├── models.py        # SQLAlchemy ORM models
│   │   ├── schemas.py       # Pydantic request/response schemas
│   │   ├── config.py        # Settings (reads from .env)
│   │   ├── database.py      # DB session management
│   │   ├── auth.py          # JWT authentication helpers
│   │   └── routes/          # API route modules
│   ├── Dockerfile
│   └── requirements.txt
├── flutter_app/             # Flutter mobile/web client
│   ├── lib/
│   │   ├── main.dart        # App entrypoint
│   │   ├── config/          # Theme, routes, API config
│   │   ├── models/          # Data models
│   │   ├── providers/       # State management (Provider)
│   │   ├── screens/         # UI screens (nurse/, doctor/, admin/)
│   │   ├── services/        # API clients (auth, database)
│   │   ├── utils/           # Helpers (TTS, etc.)
│   │   └── widgets/         # Reusable widgets
│   └── pubspec.yaml
├── docker-compose.yml
├── .env.example             # Environment variable template
└── reset_db.sql             # Database reset script
```

## Making Changes

### Backend

- All routes go in `backend/app/routes/` — one file per resource
- Register new routers in `main.py`
- Add ORM models in `models.py` and Pydantic schemas in `schemas.py`
- All endpoints require JWT auth via `Depends(get_current_user)`

### Flutter App

- Screens are organized by role: `screens/nurse/`, `screens/doctor/`, `screens/admin/`
- API calls go through `services/database_service.dart`
- State is managed via Provider (`providers/`)
- API base URL is configured in `config/api_config.dart`

## Coding Guidelines

### Python (Backend)

- Follow PEP 8 style
- Use type hints for all function signatures
- Use Pydantic models for request/response validation
- Keep route handlers thin — extract business logic into helpers if needed

### Dart (Flutter)

- Follow the [Dart style guide](https://dart.dev/guides/language/effective-dart/style)
- Use `const` constructors wherever possible
- Prefer `StatelessWidget` unless local state is needed
- Dispose controllers and timers in `dispose()`
- Keep widgets under 200 lines — extract sub-widgets

### General

- Write descriptive commit messages: `feat: add patient discharge workflow`
- One feature per branch, one feature per PR
- No hardcoded secrets — use `.env`

## Submitting a Pull Request

1. Ensure your code builds without errors (`flutter analyze`, backend starts cleanly)
2. Test your changes manually across nurse, doctor, and admin roles
3. Update the README if you add new features or change setup steps
4. Push your branch and open a PR against `main`
5. Describe **what** you changed and **why** in the PR description

## Reporting Issues

Use [GitHub Issues](../../issues) to report bugs or request features. Please include:

- **Description** — What happened? What did you expect?
- **Steps to reproduce** — How can we trigger the issue?
- **Environment** — OS, Flutter version, browser (if web)
- **Screenshots** — If it's a UI issue

---

**License:** MIT — see [LICENSE](LICENSE) for details.
