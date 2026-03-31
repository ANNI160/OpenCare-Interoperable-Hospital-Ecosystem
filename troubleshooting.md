# OpenCare Troubleshooting

This guide contains common issues when running OpenCare locally and how to resolve them.

## Backend and Docker

### Backend container starts, but API is not reachable

Checklist:

- Confirm containers are running:

```bash
docker-compose ps
```

- Check backend logs:

```bash
docker-compose logs -f backend
```

- Verify the mapped port in `.env`:
  - `FASTAPI_PORT` should match what you are using in the browser.

### Postgres is unhealthy or backend cannot connect

Checklist:

- Confirm Postgres health:

```bash
docker-compose ps
docker-compose logs -f postgres
```

- Ensure `.env` values match `DATABASE_URL`:
  - Compose expects `DATABASE_URL` to point to host `postgres` at port 5432 inside the Docker network.

### Port already in use (8000 or 5433)

Fix:

- Change `FASTAPI_PORT` or `POSTGRES_PORT` in `.env`
- Restart:

```bash
docker-compose down
docker-compose up -d
```

### Database schema is inconsistent

Reset schema (Docker workflow):

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
docker-compose restart backend
```

## Flutter app connectivity

### Android emulator cannot reach `localhost`

Symptom:

- The app shows connection errors when base URL is set to `http://localhost:8000`.

Fix:

- Use `http://10.0.2.2:8000` for Android emulator access (host machine loopback).
- Update `flutter_app/lib/config/api_config.dart` accordingly.

### Physical Android device cannot reach backend

Options:

- USB forwarding:

```bash
adb reverse tcp:8000 tcp:8000
```

- LAN access:
  - Set the base URL to your computer’s LAN IP (for example `http://192.168.x.x:8000`).
  - Allow inbound connections in Windows Firewall.

### Flutter web cannot reach backend

Checklist:

- Ensure backend is running on `http://localhost:8000`.
- Ensure browser can access `http://localhost:8000/docs`.
- If you deploy backend separately, update the base URL accordingly.

## Authentication issues

### Login succeeds but subsequent calls fail with 401

Checklist:

- Confirm the app is sending `Authorization: Bearer <token>`.
- Confirm token is being stored and reused (Flutter uses Shared Preferences).
- Restart the app and re-login to refresh the session.

## Build and dependency issues

### Flutter dependency conflicts

```bash
cd flutter_app
flutter clean
flutter pub get
```

### Python dependency issues (local backend)

- Ensure you are in a virtual environment.
- Reinstall dependencies:

```bash
pip install -r backend/requirements.txt
```

## Logs and diagnostics

### Backend logs

```bash
docker-compose logs -f backend
```

### Postgres logs

```bash
docker-compose logs -f postgres
```

