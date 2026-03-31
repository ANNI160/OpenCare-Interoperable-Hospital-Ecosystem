# OpenCare — Flutter App

The OpenCare Flutter app is the primary client for the OpenCare system. It connects to the FastAPI backend over HTTP and provides role-based dashboards for:

- **Admin** — system and user management
- **Doctor** — patient records, vitals, appointments
- **Nurse** — task management, medication administration
- **Patient** — self-service portal

This directory is a standard Flutter multi-platform project supporting Android, iOS, Web, Windows, macOS, and Linux.

## Contents

- [Prerequisites](#prerequisites)
- [Install Dependencies](#install-dependencies)
- [Configure Backend URL](#configure-backend-url)
- [Run the App](#run-the-app)
- [Role-Based Navigation](#role-based-navigation)
- [Project Structure](#project-structure)
- [API Integration](#api-integration)
- [Build Outputs and Git](#build-outputs-and-git)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

- Flutter SDK (Dart SDK `^3.5.0` — see `pubspec.yaml`)
- A running OpenCare backend (recommended: Docker Compose from repository root)

---

## Install Dependencies

```bash
cd flutter_app
flutter pub get
```

---

## Configure Backend URL

The API base URL is set in:

```
lib/config/api_config.dart
```

| Target | Base URL |
|--------|----------|
| Android emulator | `http://10.0.2.2:8000` |
| Web (browser) | `http://localhost:8000` |
| Physical device (USB) | `http://localhost:8000` + run `adb reverse tcp:8000 tcp:8000` |
| Physical device (LAN) | `http://<your-machine-LAN-IP>:8000` |

> **Note for LAN usage**: Ensure your firewall allows inbound connections on port 8000.

---

## Run the App

From `flutter_app/`:

```bash
# Web
flutter run -d chrome

# Android (emulator or connected device)
flutter run

# iOS (macOS only)
flutter run -d ios
```

---

## Role-Based Navigation

After sign-in, the app reads the authenticated user's role from the backend response and navigates accordingly:

| Role | Destination |
|------|-------------|
| `admin` | Admin Dashboard |
| `doctor` | Doctor Dashboard |
| `nurse` | Nurse Dashboard |
| `patient` | Patient Portal |

Authentication uses the `/auth/*` endpoints (login, signup, current user, logout). Session tokens are persisted locally using **Shared Preferences**.

---

## Project Structure

```text
flutter_app/
└─ lib/
   ├─ main.dart                  # App entry point
   ├─ config/
   │  ├─ api_config.dart         # Backend base URL
   │  ├─ app_theme.dart          # Global theme
   │  ├─ routes.dart             # Named route definitions
   │  └─ constants.dart          # App-wide constants
   ├─ models/                    # JSON models for API responses
   ├─ providers/                 # State management (Provider)
   ├─ screens/
   │  ├─ login_screen.dart
   │  ├─ splash_screen.dart
   │  ├─ settings_screen.dart
   │  ├─ admin/                  # Admin dashboard screens
   │  ├─ doctor/                 # Doctor dashboard screens
   │  ├─ nurse/                  # Nurse dashboard screens
   │  └─ patient/                # Patient portal screens
   ├─ services/
   │  ├─ auth_service.dart       # Sign-in/sign-up + token persistence
   │  └─ database_service.dart   # All other API calls (patients, vitals, etc.)
   ├─ utils/                     # Utility helpers (device, audio, etc.)
   └─ widgets/                   # Reusable UI components
```

---

## API Integration

All network communication is centralized in `lib/services/`:

- **`auth_service.dart`** — handles sign-in, sign-up, and persists the JWT access token via Shared Preferences.
- **`database_service.dart`** — covers all remaining API calls: patients, vitals, medications, tasks, messages, appointments, config, audit trail, emergencies, and patient portal endpoints.

The base URL used by both services is pulled from `lib/config/api_config.dart`.

---

## Build Outputs and Git

Do **not** commit generated build output. These directories are already excluded in `.gitignore`:

```
build/
.dart_tool/
```

They are created by Flutter tooling and can be regenerated at any time with `flutter pub get` and `flutter build`.

---

## Troubleshooting

**App opens but shows network errors**
- Confirm the backend is running and reachable at the configured base URL.
- Android emulator: make sure you are using `10.0.2.2` rather than `localhost`.
- Physical device: use `adb reverse tcp:8000 tcp:8000` (USB) or switch to a LAN-reachable IP.

**Dependency resolution issues**

```bash
flutter clean
flutter pub get
```

**Token not persisting between sessions**
- Check that Shared Preferences is initialized before reading the token on app start (see `main.dart` and `auth_service.dart`).
