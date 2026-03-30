"""OpenCare — Hospital Management System API."""
import os, subprocess
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import PlainTextResponse
from sqlalchemy import text
from app.database import engine, Base, SessionLocal
from app.routes import (
    auth_routes,
    patients,
    vitals,
    medications,
    messages,
    tasks,
    staff_config,
    audit_logs,
    emergencies,
    appointments,
    patient_portal,
)

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="OpenCare Hospital Management API",
    description="FOSS hospital coordination system",
    version="1.0.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all routers
app.include_router(auth_routes.router)
app.include_router(patients.router)
app.include_router(vitals.router)
app.include_router(medications.router)
app.include_router(messages.router)
app.include_router(tasks.router)
app.include_router(staff_config.router)
app.include_router(audit_logs.router)
app.include_router(emergencies.router)
app.include_router(appointments.router)
app.include_router(patient_portal.router)


@app.get("/")
def root():
    return {"message": "OpenCare API", "version": "1.0.0"}


# ── Auto-seed on first run if DB is empty ──────────────────
@app.on_event("startup")
def auto_seed():
    """If the users table is empty, run seed_db.sql to populate demo data."""
    db = SessionLocal()
    try:
        count = db.execute(text("SELECT COUNT(*) FROM users")).scalar()
        if count == 0:
            seed_path = "/app/seed_db.sql"
            if os.path.exists(seed_path):
                with open(seed_path, "r") as f:
                    sql = f.read()
                db.execute(text(sql))
                db.commit()
                print("✅ Database seeded with demo data from seed_db.sql")
            else:
                print("⚠️  No seed_db.sql found — starting with empty database")
        else:
            print(f"ℹ️  Database already has {count} users — skipping seed")
    except Exception as e:
        db.rollback()
        print(f"⚠️  Auto-seed skipped: {e}")
    finally:
        db.close()


# ── Export current DB as seed SQL ──────────────────────────
EXPORT_TABLE_ORDER = [
    "hospital_config", "users", "patients", "vitals",
    "patient_accounts", "appointments", "medications", "medication_reactions",
    "messages", "tasks", "emergency_escalations", "audit_logs",
]


@app.get("/export-seed", response_class=PlainTextResponse, tags=["admin"])
def export_seed():
    """Export all current data as a seed_db.sql file."""
    db = SessionLocal()
    lines = [
        "-- OpenCare — Auto-exported seed data",
        f"-- Exported at: {__import__('datetime').datetime.utcnow().isoformat()}",
        "",
        "TRUNCATE audit_logs, emergency_escalations, messages, medication_reactions, medications, appointments, patient_accounts, vitals, tasks, patients, users, hospital_config CASCADE;",
        "",
    ]
    try:
        for table in EXPORT_TABLE_ORDER:
            rows = db.execute(text(f"SELECT * FROM {table}")).fetchall()
            if not rows:
                continue
            # Get column names
            cols = db.execute(
                text(f"SELECT column_name FROM information_schema.columns WHERE table_name=:t ORDER BY ordinal_position"),
                {"t": table},
            ).fetchall()
            col_names = [c[0] for c in cols]

            lines.append(f"-- ─── {table} ───")
            for row in rows:
                vals = []
                for v in row:
                    if v is None:
                        vals.append("NULL")
                    elif isinstance(v, bool):
                        vals.append("true" if v else "false")
                    elif isinstance(v, (int, float)):
                        vals.append(str(v))
                    else:
                        vals.append("'" + str(v).replace("'", "''") + "'")
                lines.append(
                    f"INSERT INTO {table} ({', '.join(col_names)}) VALUES ({', '.join(vals)});"
                )
            lines.append("")

        # Write to file as well
        seed_path = "/app/seed_db.sql"
        with open(seed_path, "w") as f:
            f.write("\n".join(lines))

        return "\n".join(lines)
    finally:
        db.close()
