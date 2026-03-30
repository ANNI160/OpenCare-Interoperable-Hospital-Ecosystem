-- reset_db.sql
-- Run this inside the PostgreSQL container to wipe all old tables and let SQLAlchemy recreate them.
-- Usage:  docker exec -i opencare-postgres psql -U hospital -d hospital_db < reset_db.sql

DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO hospital;
GRANT ALL ON SCHEMA public TO public;
