# OpenCare Deployment Guide

This guide outlines production-oriented deployment considerations for OpenCare. It is intentionally conservative: the current repository is optimized for local development and demos, and production deployments should harden configuration and infrastructure.

## Recommended deployment architecture

- **Reverse proxy** (TLS termination, compression, request size limits)
  - Examples: Nginx, Caddy, Traefik, cloud load balancer
- **Backend API** (FastAPI + Uvicorn/Gunicorn)
- **PostgreSQL** (managed database recommended)
- **Optional**: object storage for user uploads (S3-compatible) if persistent uploads are required

## Production checklist

### Backend configuration

- **Set a strong `SECRET_KEY`**
  - Do not use the development default.
- **Set an explicit allowed CORS policy**
  - Restrict allowed origins to your deployed frontend domains.
- **Disable auto-reload**
  - Do not run Uvicorn with `--reload` in production.
- **Run with a process manager**
  - Use Gunicorn with Uvicorn workers, or a platform-native process manager.

### Database configuration

- **Use a managed Postgres** or dedicated Postgres host.
- **Backups**: enable automated backups, point-in-time recovery if possible.
- **Migrations**: adopt and enforce a migration workflow (Alembic is included in dependencies).
- **Credentials**: store secrets in a secret manager and rotate them.

### Security

- **HTTPS only**
- **Rate limiting** for auth endpoints
- **Audit log retention** policies
- **Least privilege** database user permissions

### Observability

- Centralized logs (structured logging)
- Basic health checks (backend and database)
- Request tracing if deployed at scale

## Environment variables

The following environment variables are expected by the Compose workflow and are appropriate for production configuration as well:

- `DATABASE_URL`
- `SECRET_KEY`

When using Docker Compose locally, `.env.example` provides the baseline. In production, use your platform’s secret storage and environment injection rather than committing a `.env`.

## Docker deployment options

### Option 1: Single host with Docker Compose (small deployments)

This resembles local development but should be adapted:

- Remove bind mounts in production (do not mount source code into the container).
- Use a production server command (no reload).
- Place Postgres behind a private network and do not expose it publicly.

Example direction (not an exact file for this repo):

- Backend container runs:
  - `uvicorn app.main:app --host 0.0.0.0 --port 8000`
  - or Gunicorn with Uvicorn workers

### Option 2: Managed platform

Typical paths:

- Backend on a container platform (Azure Container Apps, AWS ECS/Fargate, GCP Cloud Run, etc.)
- Postgres on a managed database
- Flutter web hosted on static hosting/CDN (if you deploy web)

## Flutter deployment

### Web

- Build:

```bash
cd flutter_app
flutter build web
```

- Deploy the generated output from `flutter_app/build/web/` to your static host (or use CI to build and publish).

Important:

- Do not commit `build/` to the main repository in normal workflows.
- Prefer CI/CD pipelines that produce artifacts.

### Mobile

- Use platform-specific release pipelines (Android App Bundle / iOS archive).
- Store signing keys securely and never commit them.

## Hardening notes (current codebase)

The backend is currently configured with development conveniences:

- Broad CORS settings
- Development-style JWT handling suitable for local usage
- Auto-seeding demo data

For production:

- Replace development defaults with strict configuration
- Remove or restrict demo-only endpoints and seeding behavior
- Add explicit role authorization checks where required by your policy

