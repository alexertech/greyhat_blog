-- PostgreSQL extensions required by the application
CREATE EXTENSION IF NOT EXISTS plpgsql;

-- Note: User roles and passwords should be managed via environment variables
-- The postgres user is created automatically by the postgres Docker image
-- Additional roles should be created via POSTGRES_USER and POSTGRES_PASSWORD env vars
