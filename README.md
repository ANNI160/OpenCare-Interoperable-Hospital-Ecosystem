# OpenCare: Open-Source Hospital Coordination System

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Built with Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688.svg)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg)](https://www.postgresql.org)

OpenCare is a fully open-source, self-hosted hospital coordination platform built for FOSS Hack 2026. It enables real-time collaboration for doctors, nurses, and administrators through a Flutter client application backed by a FastAPI service and PostgreSQL database.

## Overview

OpenCare provides core hospital workflow capabilities:

- Role-based dashboards for nurse, doctor, and administrator users
- Patient admission and ward/bed management
- Vitals recording with status alerting support
- Medication prescription and administration tracking
- Per-patient staff messaging and ward-level task management
- Audit logging and staff/configuration controls

## Architecture

The platform uses a simple local stack:

- Flutter app (mobile/web client)
- FastAPI backend (Python 3.11)
- PostgreSQL database (Docker)

All backend services run locally through Docker Compose.

## Quick Start

### Prerequisites

- Docker Desktop with Docker Compose
- Flutter SDK 3.5+
- Android Studio (emulator) or a physical Android device

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/opencare.git
cd opencare
```

### 2. Configure Environment Variables

Create `.env` from `.env.example`:

```bash
cp .env.example .env
```

Default values in `.env.example`:

| Variable | Default |
|---|---|
| `POSTGRES_USER` | `hospital` |
| `POSTGRES_PASSWORD` | `hospital123` |
| `POSTGRES_DB` | `hospital_db` |
| `POSTGRES_PORT` | `5433` |
| `FASTAPI_PORT` | `8000` |
| `SECRET_KEY` | `opencare-super-secret-key-change-in-production` |

### 3. Start Backend Services

```bash
docker-compose up -d --build
```

Verify containers:

```bash
docker-compose ps
```

Verify API:

```bash
curl http://localhost:8000/
```

API documentation:

- http://localhost:8000/docs

### 4. Run the Flutter Application

```bash
cd flutter_app
flutter pub get
flutter run
```

For Android emulators, use `http://10.0.2.2:8000` as the backend URL. For physical devices, update `flutter_app/lib/config/api_config.dart` to use your machine's LAN IP.

### 5. Optional: Reset the Database

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
docker-compose restart backend
```

## Detailed Run Guide

For complete Windows-focused setup and troubleshooting, see [HOW_TO_RUN.md](HOW_TO_RUN.md).

## Project Structure

```text
OPENCARE/
|-- backend/
|   |-- Dockerfile
|   |-- requirements.txt
|   `-- app/
|       |-- main.py
|       |-- config.py
|       |-- database.py
|       |-- models.py
|       |-- schemas.py
|       |-- auth.py
|       `-- routes/
|-- flutter_app/
|   |-- pubspec.yaml
|   `-- lib/
|-- docker-compose.yml
|-- reset_db.sql
|-- seed_db.sql
`-- README.md
```

## API Endpoints

### Authentication

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/auth/signup` | Register a new staff member |
| `POST` | `/auth/login` | Log in and receive JWT |
| `GET` | `/auth/me` | Get current user profile |
| `PATCH` | `/auth/me` | Update current user profile |
| `POST` | `/auth/logout` | Set user offline |

### Patients

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/patients` | List patients (filter by ward, doctor, status) |
| `GET` | `/patients/{id}` | Get one patient |
| `GET` | `/patients/ward/{w}/bed/{b}` | Lookup by ward and bed |
| `POST` | `/patients` | Admit a new patient |
| `PUT` | `/patients/{id}` | Update patient details |

### Vitals

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/vitals/{patient_id}` | Vitals history |
| `GET` | `/vitals/{patient_id}/latest` | Latest vitals |
| `POST` | `/vitals` | Record vitals |

### Medications

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/medications/{patient_id}` | List patient medications |
| `GET` | `/medications/{patient_id}/pending` | List pending medications |
| `POST` | `/medications` | Prescribe medication |
| `PATCH` | `/medications/{id}/administer` | Mark medication administered |

### Messages

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/messages/{patient_id}` | Patient message thread |
| `GET` | `/messages/unread/count` | Unread message count |
| `POST` | `/messages` | Send message |
| `PATCH` | `/messages/{id}/read` | Mark message as read |

### Tasks

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/tasks/ward/{ward_number}` | Ward tasks |
| `POST` | `/tasks` | Create task |
| `PATCH` | `/tasks/{id}` | Update completion state |
| `DELETE` | `/tasks/{id}` | Delete task |

### Staff and Configuration

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/staff` | List active staff |
| `GET` | `/staff/doctors` | List doctors |
| `GET` | `/staff/nurses` | List nurses |
| `DELETE` | `/staff/{id}` | Remove staff (admin) |
| `GET` | `/config` | Get hospital configuration |
| `PUT` | `/config` | Update hospital configuration (admin) |

## Technology Stack

| Layer | Technology |
|---|---|
| Mobile App | Flutter (Dart) |
| State Management | Provider |
| Backend API | FastAPI |
| ORM | SQLAlchemy |
| Database | PostgreSQL |
| Containerization | Docker and Docker Compose |
| Authentication | JWT (`python-jose`) |

## Contributing

1. Fork the repository.
2. Create a feature branch: `git checkout -b feature/my-feature`.
3. Commit your changes: `git commit -m "Add my feature"`.
4. Push your branch: `git push origin feature/my-feature`.
5. Open a pull request.

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

