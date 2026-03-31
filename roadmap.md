# OpenCare Roadmap — March 2026 (30-Day Journey)

This roadmap is a week-wise and date-wise execution plan for **March 1, 2026 to March 31, 2026**. Tasks are intentionally distributed across:

- Pranav
- Shruti
- Anirudh
- Aditya

It is designed for steady progress across product, backend, Flutter app, data, QA, and deployment readiness.

## Conventions

- Each task is written as a concrete deliverable.
- Assignments are intentionally mixed (randomized) across the four contributors.
- Dates are written as `YYYY-MM-DD`.

## Week 1 — Foundation and baseline stabilization (2026-03-01 to 2026-03-07)

### 2026-03-01
- **Pranav**: Create a one-page product scope (roles, modules, priority workflows) and sync it with the current implementation.
- **Shruti**: Validate Docker Compose boot on Windows and document any environment gotchas (ports, permissions).

### 2026-03-02
- **Anirudh**: Review `backend/app/main.py` startup behaviors (auto-create tables, auto-seed) and list production hardening changes.
- **Aditya**: Verify Flutter runs on Chrome and Android emulator; note any runtime warnings/errors and capture reproducible steps.

### 2026-03-03
- **Pranav**: Standardize API base URL usage in Flutter (confirm `ApiConfig` behavior for emulator vs localhost) and document expected settings.
- **Shruti**: Audit `.gitignore` coverage for Flutter, Python, IDE files; propose any missing ignores.

### 2026-03-04
- **Anirudh**: Enumerate backend route modules and produce an endpoint inventory (paths + methods + auth requirements).
- **Aditya**: Verify login/sign-up flows for nurse/doctor/admin/patient in Flutter; record any gaps in UX/validation.

### 2026-03-05
- **Pranav**: Add a minimal “smoke test plan” checklist (manual) for core flows: login, view patients, add vitals, message, tasks.
- **Shruti**: Validate seeded demo accounts in `seed_db.sql` and confirm the demo password used end-to-end.

### 2026-03-06
- **Anirudh**: Add backend health validation notes (how to check `/docs`, DB connection) and propose a `/health` endpoint spec.
- **Aditya**: Review role dashboards (admin/nurse/doctor/patient) and list missing/unfinished screens or navigation breaks.

### 2026-03-07
- **Pranav**: Draft a naming and folder convention guide for Flutter screens/providers/services to keep structure consistent.
- **Shruti**: Prepare a “clean reset” workflow for local DB (reset script + restart + reseed) and verify it works.

## Week 2 — Core workflows and quality improvements (2026-03-08 to 2026-03-14)

### 2026-03-08
- **Aditya**: Review patient listing and patient detail screens for performance and layout issues; capture UI improvement list.
- **Anirudh**: Verify staff listing endpoints used by Flutter (`/staff/doctors`, `/staff/nurses`) and confirm response shapes.

### 2026-03-09
- **Shruti**: Validate task workflows (create/complete) from nurse perspective; note API/UX issues.
- **Pranav**: Validate messaging workflows (nurse↔doctor) and document supported message types (text/voice/image metadata).

### 2026-03-10
- **Anirudh**: Review medication flows (create, pending, administered) and document expected lifecycle states and endpoints.
- **Aditya**: Verify vitals capture flow in Flutter; check data validation and alert indicators.

### 2026-03-11
- **Pranav**: Patient portal smoke test: profile, appointments, messages, medications, reactions; report gaps.
- **Shruti**: Verify audit log flows for key actions (emergency escalation, reactions) and confirm they appear via API.

### 2026-03-12
- **Anirudh**: Confirm appointment scheduling endpoints and expected sorting; verify time fields and timezone assumptions.
- **Aditya**: Improve error messaging patterns in Flutter (consistent snackbars, timeouts, “retry” entry points).

### 2026-03-13
- **Shruti**: Validate hospital config read/update from admin screens and confirm persistence.
- **Pranav**: Draft a role-based access matrix (which roles can call which endpoints/screens).

### 2026-03-14
- **Anirudh**: Identify any endpoints missing auth enforcement and propose fixes.
- **Aditya**: Create a list of top 10 UI/UX polish items with estimated effort and expected user impact.

## Week 3 — Testing, data integrity, and operational readiness (2026-03-15 to 2026-03-21)

### 2026-03-15
- **Pranav**: Add a structured QA checklist for release readiness (backend, Flutter, database reset/seed, performance sanity).
- **Shruti**: Validate SQL scripts (`seed_db.sql`, `reset_db.sql`) for idempotence and safe execution order in local environments.

### 2026-03-16
- **Anirudh**: Define minimal backend test strategy (unit tests for auth helpers + route-level smoke tests proposal).
- **Aditya**: Validate offline/poor connectivity behavior in Flutter (timeouts, retry, messaging to user).

### 2026-03-17
- **Shruti**: Verify Docker networking assumptions and document how to run Postgres locally + backend locally if needed.
- **Pranav**: Review data model relationships conceptually; list any missing constraints or referential issues seen in runtime.

### 2026-03-18
- **Anirudh**: Review emergency escalation flow (trigger/ack/resolve) and document expected statuses and audit behavior.
- **Aditya**: Validate patient search/filtering capabilities (if present); if absent, define desired behavior and minimal UI plan.

### 2026-03-19
- **Pranav**: Draft “production hardening” notes for README/Deployment (CORS, secret key, debug flags, seed/export endpoint exposure).
- **Shruti**: Validate uploads directory behavior in backend container (`backend/uploads`) and confirm `.gitkeep` handling.

### 2026-03-20
- **Anirudh**: Review JWT expiration behavior and session persistence; document expected token lifetime and refresh strategy (if any).
- **Aditya**: Validate role switching and sign-out behavior; confirm token clearing and online status update.

### 2026-03-21
- **Shruti**: Confirm database backup/restore steps for development and document them.
- **Pranav**: Consolidate open issues list from Weeks 1–3 into prioritized backlog (P0/P1/P2).

## Week 4 — Final polish, documentation completeness, and demo readiness (2026-03-22 to 2026-03-31)

### 2026-03-22
- **Aditya**: UI polish pass: typography/spacing consistency and dashboard layout alignment across roles.
- **Anirudh**: Validate OpenAPI docs completeness; confirm tags, summaries, and response models render well in `/docs`.

### 2026-03-23
- **Shruti**: Define a release demo script (step-by-step) covering the most important workflows.
- **Pranav**: Verify that all new documentation files are linked from the root README and reflect actual behavior.

### 2026-03-24
- **Anirudh**: Identify any database queries that need indexes (patients by ward, messages by patient, vitals by patient/time) and propose index plan.
- **Aditya**: Validate critical patient highlighting and alert indicators in UI; list improvements for clarity.

### 2026-03-25
- **Pranav**: Create a “first-time developer onboarding” checklist (tools, commands, expected outputs, troubleshooting).
- **Shruti**: Audit for accidental secrets or local artifacts before publishing to GitHub (ensure `.env` and build folders are excluded).

### 2026-03-26
- **Aditya**: Verify Android build (debug) from a clean checkout; note any Gradle/NDK issues and resolution steps.
- **Anirudh**: Confirm seed export endpoint behavior and document how to capture exported SQL for future demos.

### 2026-03-27
- **Shruti**: Confirm Docker Compose works with a non-default Postgres port (`POSTGRES_PORT`) and document.
- **Pranav**: Define minimal “Definition of Done” for new features (docs + UI + API + basic validation).

### 2026-03-28
- **Anirudh**: Perform a security review pass: CORS, auth bypass risks, role checks; produce an action list.
- **Aditya**: Accessibility review pass (contrast, touch targets, focus) and list issues.

### 2026-03-29
- **Pranav**: Review and finalize user stories for the next month based on March learnings; propose April priorities.
- **Shruti**: Validate database reset/reseed from scratch and confirm the demo script still works after resets.

### 2026-03-30
- **Aditya**: Final full demo run on at least one target (web or Android) and capture any last-minute issues.
- **Anirudh**: Final backend validation: start from clean DB, ensure seed loads, ensure `/docs` is accessible and core endpoints behave.

### 2026-03-31
- **Pranav**: Publish final “March 2026 release notes” summary (what works, known gaps, next steps).
- **Shruti**: Tag and package the repository for GitHub upload readiness (ignore list verified, docs complete, scripts validated).

## Task count

This roadmap contains **62 tasks** (2 tasks per day across 31 days), meeting the requirement of at least 50 tasks.

