-- PostgreSQL extensions required by the application
CREATE EXTENSION IF NOT EXISTS plpgsql;

-- Create postgres role
CREATE ROLE postgres WITH SUPERUSER CREATEDB CREATEROLE PASSWORD 'postgres';

-- Update existing alex role to be superuser
ALTER ROLE alex WITH SUPERUSER CREATEDB CREATEROLE PASSWORD 'super_secure_password_2025';
