# 🏥 OpenCare — Open-Source Hospital Coordination System

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Built with Flutter](https://img.shields.io/badge/Flutter-3.x-blue.svg)](https://flutter.dev)
[![FastAPI](https://img.shields.io/badge/FastAPI-0.109-009688.svg)](https://fastapi.tiangolo.com)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791.svg)](https://www.postgresql.org)

A **fully open-source, self-hosted** hospital coordination system built for **FOSS Hack 2026**. OpenCare enables real-time coordination between **Doctors**, **Nurses**, and **Administrators** through a mobile-first Flutter app backed by a FastAPI REST API and PostgreSQL database.

> **Origin:** OpenCare is a clean-room, FOSS-compliant reimplementation of a hospital management concept originally prototyped on Firebase. Every dependency in this stack is open-source and self-hostable — no proprietary services required.

---

## ✨ Key Features

| Feature | Description |
|---|---|
| **Role-Based Dashboards** | Dedicated UIs for Nurse, Doctor, and Admin roles |
| **Patient Management** | Ward/bed assignment, admission tracking, diagnosis notes |
| **Live Vitals Monitoring** | Record & chart heart rate, BP, SpO₂, temperature, glucose with auto-alerting |
| **Medication Workflow** | Prescribe → Schedule → Administer with full audit trail |
| **Communication Hub** | Per-patient messaging between staff (text, voice notes, attachments) |
| **Task Management** | Ward-scoped task assignment and completion tracking |
| **Text-to-Speech** | TTS readback of patient data for hands-free use |
| **Admin Controls** | Staff management, ward/bed configuration, audit logs |
| **JWT Authentication** | Stateless, local auth with no external IdP dependency |
| **Offline-Ready Architecture** | Local caching via `sqflite` and `SharedPreferences` |

---

## 🏗️ Architecture

```
┌─────────────────┐        HTTP/REST        ┌─────────────────┐        SQL        ┌─────────────────┐
│   Flutter App    │ ─────────────────────▶  │   FastAPI API    │ ───────────────▶  │   PostgreSQL    │
│   (Mobile/Web)   │  ◀─────────────────── │   (Python 3.11)  │  ◀─────────────── │   (v15-alpine)  │
└─────────────────┘        JSON             └────────┬────────┘                    └─────────────────┘
                                                     │
                                              JWT Auth (local)
                                              HS256 tokens
                                                     │
                                             ┌───────▼────────┐
                                             │   Keycloak      │  (optional, for
                                             │   (v24.0)       │   enterprise SSO)
                                             └────────────────┘
```

**All services run locally via Docker Compose** — zero cloud dependencies.

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Install |
|---|---|---|
| **Docker** + Docker Compose | v20+ | [docker.com](https://docs.docker.com/get-docker/) |
| **Flutter SDK** | 3.5+ | [flutter.dev](https://docs.flutter.dev/get-started/install) |
| **Android Emulator** or physical device | API 21+ | Via Android Studio |

### 1. Clone & Configure

```bash
git clone https://github.com/YOUR_USERNAME/opencare.git
cd opencare
```

The `.env` file is pre-configured for local development. Default values:

| Variable | Default |
|---|---|
| `POSTGRES_USER` | `hospital` |
| `POSTGRES_PASSWORD` | `hospital123` |
| `POSTGRES_DB` | `hospital_db` |
| `FASTAPI_PORT` | `8000` |
| `KEYCLOAK_PORT` | `8080` |
| `SECRET_KEY` | `opencare-super-secret-key-change-in-production` |

### 2. Start Backend Services

```bash
docker-compose up -d
```

This starts three containers:
- **PostgreSQL** on `localhost:5432`
- **Keycloak** on `localhost:8080` (optional SSO)
- **FastAPI** on `localhost:8000`

Wait ~30 seconds for all services to initialize, then verify:

```bash
# Check all containers are healthy
docker-compose ps

# Test the API
curl http://localhost:8000/
# → {"message":"OpenCare API","version":"1.0.0"}

# Browse the interactive API docs
# → http://localhost:8000/docs
```

### 3. Reset Database (if upgrading from an older schema)

If you have remnant tables from a previous setup:

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
docker-compose restart backend
```

This drops the old `public` schema entirely and lets SQLAlchemy recreate all tables cleanly on backend restart.

### 4. Run the Flutter App

```bash
cd flutter_app
flutter pub get
flutter run
```

> **Emulator note:** The API base URL is set to `http://10.0.2.2:8000` (Android emulator loopback to host). For physical devices, update `lib/config/api_config.dart` with your machine's LAN IP.

### 5. Create Your First User

1. Open the app → tap **Sign Up**
2. Fill in: Name, Email, Employee ID, Password, Role (Nurse/Doctor/Admin)
3. You'll be redirected to the appropriate role dashboard

---

## 📁 Project Structure

```
OPENCARE/
├── docker-compose.yml              # Orchestrates PostgreSQL, Keycloak, FastAPI
├── .env                            # Environment variables (gitignored)
├── .gitignore
├── LICENSE                         # MIT License
├── README.md
├── reset_db.sql                    # Database reset helper script
│
├── backend/                        # ── FastAPI Backend ──
│   ├── Dockerfile
│   ├── requirements.txt            # Python dependencies
│   └── app/
│       ├── main.py                 # App entry point, CORS, router registration
│       ├── config.py               # Pydantic settings (reads .env)
│       ├── database.py             # SQLAlchemy engine & session
│       ├── models.py               # 8 ORM models (User, Patient, Vitals, etc.)
│       ├── schemas.py              # Pydantic request/response schemas
│       ├── auth.py                 # JWT creation, password hashing, role guards
│       └── routes/
│           ├── auth_routes.py      # POST /auth/signup, /login, /logout, GET /auth/me
│           ├── patients.py         # CRUD patients, ward/bed queries
│           ├── vitals.py           # Record vitals with auto-alerting
│           ├── medications.py      # Prescribe & administer medications
│           ├── messages.py         # Per-patient messaging, read receipts
│           ├── tasks.py            # Ward-scoped task management
│           └── staff_config.py     # Staff listing, hospital config (admin)
│
├── keycloak/
│   └── realm-export.json           # Pre-configured OpenCare realm (optional SSO)
│
└── flutter_app/                    # ── Flutter Mobile App ──
    ├── pubspec.yaml                # Flutter dependencies
    └── lib/
        ├── main.dart               # MultiProvider root, MaterialApp
        ├── config/
        │   ├── api_config.dart     # API base URL & endpoint paths
        │   ├── app_theme.dart      # Material 3 theme (Poppins/Inter)
        │   ├── constants.dart      # Role enums, vitals normal ranges
        │   └── routes.dart         # Named route definitions
        ├── models/                 # Dart data classes (fromJson/toJson)
        │   ├── user_model.dart
        │   ├── patient_model.dart
        │   ├── vitals_model.dart
        │   ├── medication_model.dart
        │   ├── message_model.dart
        │   └── task_model.dart
        ├── providers/              # ChangeNotifier state management
        │   ├── auth_provider.dart
        │   ├── patient_provider.dart
        │   └── message_provider.dart
        ├── services/
        │   ├── auth_service.dart       # Login/signup/token persistence
        │   └── database_service.dart   # All REST API calls
        ├── screens/
        │   ├── splash_screen.dart
        │   ├── login_screen.dart
        │   ├── settings_screen.dart
        │   ├── nurse/
        │   │   ├── nurse_dashboard.dart
        │   │   ├── patient_details_tab.dart
        │   │   ├── clinical_data_tab.dart
        │   │   ├── communication_hub_tab.dart
        │   │   └── tasks_tab.dart
        │   ├── doctor/
        │   │   ├── doctor_dashboard.dart
        │   │   └── patient_detail_view.dart
        │   └── admin/
        │       └── admin_dashboard.dart
        ├── utils/
        │   └── tts_helper.dart     # Text-to-speech utility
        └── widgets/
            ├── common/
            │   └── logo_widget.dart
            └── patient_search_delegate.dart
```

---

## 🔌 API Endpoints

### Authentication
| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/auth/signup` | Register a new staff member |
| `POST` | `/auth/login` | Login with email + password → JWT |
| `GET` | `/auth/me` | Get current user profile |
| `PATCH` | `/auth/me` | Update profile |
| `POST` | `/auth/logout` | Set user offline |

### Patients
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/patients` | List patients (filter by ward, doctor, status) |
| `GET` | `/patients/{id}` | Get single patient |
| `GET` | `/patients/ward/{w}/bed/{b}` | Lookup by ward+bed |
| `POST` | `/patients` | Admit new patient |
| `PUT` | `/patients/{id}` | Update patient info |

### Vitals
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/vitals/{patient_id}` | Vitals history (last 50) |
| `GET` | `/vitals/{patient_id}/latest` | Most recent reading |
| `POST` | `/vitals` | Record vitals (auto-alerts on abnormal values) |

### Medications
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/medications/{patient_id}` | All medications |
| `GET` | `/medications/{patient_id}/pending` | Un-administered only |
| `POST` | `/medications` | Prescribe medication |
| `PATCH` | `/medications/{id}/administer` | Mark as administered |

### Messages
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/messages/{patient_id}` | Message thread for a patient |
| `GET` | `/messages/unread/count` | Unread count for current user |
| `POST` | `/messages` | Send message |
| `PATCH` | `/messages/{id}/read` | Mark as read |

### Tasks
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/tasks/ward/{ward_number}` | Tasks for a ward |
| `POST` | `/tasks` | Create task |
| `PATCH` | `/tasks/{id}` | Complete/uncomplete |
| `DELETE` | `/tasks/{id}` | Delete task |

### Staff & Config
| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/staff` | All active staff |
| `GET` | `/staff/doctors` | Doctors list |
| `GET` | `/staff/nurses` | Nurses list |
| `DELETE` | `/staff/{id}` | Remove staff (admin only) |
| `GET` | `/config` | Hospital ward/bed config |
| `PUT` | `/config` | Update config (admin only) |

---

## 🛠️ Tech Stack

| Layer | Technology | License |
|---|---|---|
| **Mobile App** | Flutter 3.x (Dart) | BSD-3-Clause |
| **State Management** | Provider | MIT |
| **Charts** | fl_chart | MIT |
| **Backend API** | FastAPI (Python 3.11) | MIT |
| **ORM** | SQLAlchemy 2.0 | MIT |
| **Database** | PostgreSQL 15 | PostgreSQL License (OSI) |
| **Auth (optional)** | Keycloak 24.0 | Apache-2.0 |
| **Containerization** | Docker & Docker Compose | Apache-2.0 |
| **JWT Library** | python-jose | MIT |
| **TTS** | flutter_tts | MIT |

All dependencies are **OSI-approved open-source licenses**.

---

## 🧪 Testing Checklist

Use this checklist for end-to-end validation on the Android emulator:

- [ ] **Sign Up** — Create Nurse, Doctor, and Admin accounts
- [ ] **Login** — Verify JWT persistence (app restart → auto-login)
- [ ] **Nurse Dashboard** — Ward grid renders, bed selector works
- [ ] **Admit Patient** — Register patient to ward/bed
- [ ] **Record Vitals** — Enter values, verify chart renders (fl_chart)
- [ ] **Auto-Alerts** — Enter abnormal vitals → patient status changes to "pending"
- [ ] **Prescribe Medication** — Doctor prescribes, nurse administers
- [ ] **Communication Hub** — Send messages, verify polling retrieves them
- [ ] **Task Management** — Create, complete, delete tasks per ward
- [ ] **Admin Dashboard** — View all staff, change ward/bed configuration
- [ ] **TTS** — Tap speak button, verify readback
- [ ] **Settings** — Update profile, logout, verify cleanup

---

## 📝 Attribution

OpenCare was developed as a FOSS reimplementation of a hospital management system concept originally designed for Graphic Era Hospital. The original system used Firebase (Firestore, Firebase Auth, Cloud Messaging). This version replaces all proprietary/cloud dependencies with fully open-source, self-hostable alternatives:

- **Firebase Auth** → Local JWT authentication via `python-jose`
- **Cloud Firestore** → PostgreSQL with SQLAlchemy ORM
- **Firebase Cloud Messaging** → HTTP polling-based messaging
- **Firebase Hosting** → Docker Compose self-hosting

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -m 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.
