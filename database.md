# OpenCare Database Guide

This document describes how OpenCare uses PostgreSQL, how demo seeding works, and the operational scripts included in this repository.

## Overview

OpenCare uses PostgreSQL as the primary datastore for:

- users and roles
- patients and ward/bed assignment
- vitals (time-series)
- medications and reactions
- tasks and coordination workflows
- messaging and attachments metadata
- audit logs and emergency escalations
- hospital configuration
- patient portal linkage (patient accounts)

## Connection configuration

The backend reads its database connection string from:

- `DATABASE_URL`

In the Docker Compose workflow, `DATABASE_URL` points to the Compose service name `postgres` at port 5432 inside the Docker network.

In local (non-Docker) runs, `DATABASE_URL` typically points to `localhost`.

Example local configuration:

```text
postgresql://hospital:hospital123@localhost:5432/hospital_db
```

## Schema creation

On backend startup, the backend creates tables via SQLAlchemy metadata. This is suitable for demos and local development.

If you adopt a production deployment, you should formalize schema changes with migrations (Alembic is included as a dependency).

## Seed data

### Repository seed file

At the repository root:

- `seed_db.sql`

This file contains demo data for key tables and enables a functional environment immediately after startup.

### Auto-seed behavior

On backend startup, if the database is empty, the backend attempts to read a seed file from:

- `/app/seed_db.sql`

In Docker Compose, the root `seed_db.sql` is mounted into the backend container at `/app/seed_db.sql`.

## Reset script

The repository provides:

- `reset_db.sql`

This script drops and recreates the `public` schema. It is intended for local development when you want to wipe everything and start fresh.

Docker usage:

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql
docker-compose restart backend
```

## Exporting seed data

The backend includes an endpoint to export current database contents as SQL:

- `GET /export-seed`

This returns a SQL dump in the response and also writes a seed file to:

- `/app/seed_db.sql` (inside the backend container)

If you want to persist an exported seed back into the repository, copy it out of the container and replace the root `seed_db.sql` manually.

## Common operational tasks

### Inspect the database (Docker)

```bash
docker exec -it opencare-postgres psql -U hospital -d hospital_db
```

### Backup and restore (development)

Backup:

```bash
docker exec -t opencare-postgres pg_dump -U hospital -d hospital_db > backup.sql
```

Restore:

```bash
docker exec -i opencare-postgres psql -U hospital -d hospital_db < backup.sql
```

