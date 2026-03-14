# 📋 OpenCare Project Status & TODO List

This document provides a comprehensive overview of what has been implemented and what remains to be done for OpenCare.

## ✅ Completed (Implemented)

### 🖥️ Backend (FastAPI & PostgreSQL)
- **Core Architecture**: SQLAlchemy ORM models, Pydantic schemas, and JWT Authentication.
- **Patient Management**: CRUD operations, ward/bed assignment logic.
- **Vitals Tracking**: Recording history for HR, BP, SpO₂, Temp, RR, and Glucose.
- **Medication Workflow**: Prescribing by doctors and administration by nurses.
- **Communication Hub**: API for per-patient messaging with sender/receiver roles.
- **Task Management**: Ward-scoped task creation, completion, and deletion.
- **Audit Logging**: Backend infrastructure for logging actions (partially integrated).
- **Emergency Escalation**: Backend logic for "Code Blue" triggers, acknowledgments, and resolution.
- **Staff Config**: Admin API for managing hospital wards, beds, and staff.

### 📱 Flutter Mobile App
- **Role-Based Dashboards**: Basic layout and navigation for Nurse, Doctor, and Admin roles.
- **Authentication**: Login screen with JWT token persistence.
- **Nurse Workflow**:
    - Patient registration and edit details.
    - Clinical data tab with "Live" vitals charts (`fl_chart`).
    - Medication administration interface.
    - Communication hub (Text-only messaging).
    - Task management tab.
- **Doctor Workflow**:
    - Dashboard with ward-wise patient filtering.
    - Emergency alert banner with ACK/RESOLVE capabilities.
    - Patient detail view.
- **Admin Workflow**:
    - Staff management and hospital configuration UI.
- **Real-time Simulation**: Polling mechanism for messages and emergency alerts.

---

## 🚀 Remaining Work (TODO)

### 🛠️ High Priority (Missing Core Features)
- [ ] **Offline Support (sqflite)**:
    - [ ] Add `sqflite` dependency to `pubspec.yaml`.
    - [ ] Implement local database caching for Patients and Messages.
    - [ ] Implement background synchronization when connection is restored.
- [ ] **Voice Notes in Communication Hub**:
    - [ ] Implement audio recording UI in `CommunicationHubTab`.
    - [ ] Implement audio playback for received voice notes.
    - [ ] Backend: Ensure file storage logic for voice notes is functional.
- [ ] **Push Notifications**:
    - [ ] Replace or augment polling with a more efficient real-time mechanism (e.g., WebSockets or Firebase FCM as a fallback, though the goal is zero-cloud).
    - [ ] Implement local notifications for emergency alerts when the app is in background.

### 📈 Medium Priority (Improvements)
- [ ] **Advanced Vitals Analysis**:
    - [ ] Implement auto-alerting logic on the **Frontend** (currently backend-only status changes).
    - [ ] Expand `fl_chart` to support multi-axis vitals comparison.
- [ ] **Audit Logs UI**:
    - [ ] Create a dedicated screen for Admins to view the hospital audit trail.
- [ ] **Text-to-Speech (TTS)**:
    - [ ] Fully integrate `tts_helper.dart` across all dashboard summary cards for hands-free mode.
- [ ] **Media Attachments**:
    - [ ] Extend messaging to support image attachments (X-rays, prescriptions).

### 🎨 Low Priority (Polish)
- [ ] **Dark Mode Support**: Implement a secondary theme for better usage in night shifts.
- [ ] **Biometric Login**: Integration with Fingerprint/FaceID for faster access.
- [ ] **Ward Map Visualization**: A graphical grid of beds for the Nurse dashboard.

---

## 🧪 Verification Status (Testing)
- [x] **Sign Up / Login**: Functional.
- [x] **Patient Admission**: Functional.
- [x] **Vitals Recording**: Functional with chart visualization.
- [x] **Emergency Alerts**: Functional via 10s polling.
- [ ] **Offline Mode**: **NOT TESTED** (Infrastructure missing).
- [ ] **Voice Notes**: **NOT IMPLEMENTED**.
