# Docker Setup Recipe for Rails Applications

This recipe documents the complete, battle-tested Docker setup for Rails applications with PostgreSQL, including production deployment with Caddy reverse proxy.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [File Structure](#file-structure)
- [Step-by-Step Setup](#step-by-step-setup)
- [Common Operations](#common-operations)
- [Troubleshooting](#troubleshooting)
- [Production Deployment](#production-deployment)

---

## Overview

**Philosophy: Simple, Clean, Maintainable**

- Single `docker-compose.yml` for both development and production
- Environment-based configuration via `.env` files
- Standard PostgreSQL (not Alpine) for maximum compatibility
- Explicit naming to avoid DNS collisions on shared networks
- Automatic database restoration from SQL dumps

---

## Prerequisites

- Docker & Docker Compose installed
- Git repository initialized
- Rails application ready

---

## File Structure

```
your-rails-app/
├── Dockerfile
├── docker-compose.yml
├── .env                    # Not committed (add to .gitignore)
├── .env.example           # Committed template
├── config/
│   └── database.yml       # Rails database config
├── db/
│   └── init/              # Optional: SQL dumps for initialization
│       └── 01-restore.sql
└── postgres/              # Created by Docker (add to .gitignore)
```

---

## Step-by-Step Setup

### 1. Create Dockerfile

**File: `Dockerfile`**

```dockerfile
FROM ruby:3.3.4-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libvips \
    curl \
    nodejs \
    npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Copy Gemfile and install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Create necessary directories
RUN mkdir -p log tmp/pids tmp/cache storage

EXPOSE 3000

CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0"]
```

**Key Points:**
- Use official Ruby slim image (not Alpine)
- Install only runtime dependencies
- Simple single-stage build
- Keep it under 30 lines

---

### 2. Create docker-compose.yml

**File: `docker-compose.yml`**

```yaml
name: your_app_name

services:
  database:
    image: postgres:15
    container_name: yourapp_postgres
    environment:
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - ./postgres:/var/lib/postgresql/data
      - ./db/init:/docker-entrypoint-initdb.d:ro
    restart: unless-stopped
    networks:
      - yourapp_network

  web:
    build: .
    container_name: yourapp_web
    environment:
      RAILS_ENV: ${RAILS_ENV}
      POSTGRES_HOST: yourapp_postgres
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      RAILS_MASTER_KEY: ${RAILS_MASTER_KEY}
      SECRET_KEY_BASE: ${SECRET_KEY_BASE}
      RAILS_SERVE_STATIC_FILES: "true"
      RAILS_LOG_TO_STDOUT: "true"
    depends_on:
      - database
    volumes:
      - .:/app
      - ./storage:/app/storage
    ports:
      - "${RAILS_PORT:-3000}:3000"
    expose:
      - "3000"
    networks:
      - yourapp_network
      - caddy_net
    restart: unless-stopped
    command: bundle exec rails server -b 0.0.0.0
    labels:
      - "com.centurylinklabs.watchtower.enable=true"

networks:
  yourapp_network:
    name: yourapp_network
    driver: bridge
  caddy_net:
    name: caddy_net
    external: true
```

**Critical Configuration Points:**

1. **Unique Container Names**: Use `yourapp_postgres` and `yourapp_web` (not generic names like `database` or `web`)
   - **WHY**: Prevents DNS collisions on shared networks like `caddy_net`

2. **POSTGRES_HOST**: Must match the container name (`yourapp_postgres`)
   - **WHY**: The hostname `database` might resolve to other postgres containers on shared networks

3. **Explicit Network Names**: Use `name:` property in network definitions
   - **WHY**: Prevents Docker from auto-generating names like `yourapp_yourapp_network`

4. **Two Networks**:
   - `yourapp_network`: Internal, for database communication
   - `caddy_net`: External, for reverse proxy access (production only)

5. **Volume Mounts**:
   - `./postgres`: Persistent database data
   - `./db/init`: SQL files run on first initialization only
   - `.:/app`: Live code reload in development

---

### 3. Configure Rails Database

**File: `config/database.yml`**

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: <%= ENV['POSTGRES_HOST'] || 'localhost' %>
  username: <%= ENV['POSTGRES_USER'] %>
  password: <%= ENV['POSTGRES_PASSWORD'] %>
  database: <%= ENV['POSTGRES_DB'] %>

development:
  <<: *default

test:
  <<: *default
  database: yourapp_test

production:
  <<: *default
```

**Key Points:**
- Use individual env vars (not DATABASE_URL)
- Same config for all environments
- Only test database has hardcoded name

---

### 4. Create Environment Files

**File: `.env.example`** (committed to git)

```bash
# Rails Environment
RAILS_ENV=development

# Database (REQUIRED)
POSTGRES_USER=yourapp
POSTGRES_PASSWORD=yourapp
POSTGRES_DB=yourapp_development

# Rails Keys (REQUIRED for production)
RAILS_MASTER_KEY=
SECRET_KEY_BASE=

# Optional
RAILS_PORT=3000

# Production Example:
# RAILS_ENV=production
# POSTGRES_USER=yourapp
# POSTGRES_PASSWORD=secure_random_password
# POSTGRES_DB=yourapp_production
# RAILS_MASTER_KEY=your_master_key_from_config_master_key
# SECRET_KEY_BASE=generate_with_rails_secret
```

**File: `.env`** (NOT committed - add to .gitignore)

```bash
RAILS_ENV=development
POSTGRES_USER=yourapp
POSTGRES_PASSWORD=yourapp
POSTGRES_DB=yourapp_development
```

---

### 5. Update .gitignore

**File: `.gitignore`**

```
# Docker
postgres/
.env

# Keep the example
!.env.example
```

---

### 6. Initialize Database

#### Option A: Fresh Database (Migrations)

```bash
# Start containers
docker compose up -d

# Create and migrate database
docker compose exec web bundle exec rails db:create db:migrate

# Seed data (optional)
docker compose exec web bundle exec rails db:seed
```

#### Option B: Restore from SQL Dump

```bash
# Place SQL dump in db/init/
mkdir -p db/init
cp your_backup.sql db/init/01-restore.sql

# Wipe postgres data if exists
docker compose down
rm -rf postgres

# Start fresh (will auto-restore)
docker compose up -d

# Wait for initialization (check logs)
docker logs yourapp_postgres -f
```

**Important**: SQL files in `db/init/` only run on **first initialization** when `postgres/` directory is empty.

---

## Common Operations

### Start Development Environment

```bash
docker compose up -d
docker compose logs -f web
```

### Stop Everything

```bash
docker compose down
```

### Rebuild After Gemfile Changes

```bash
docker compose down
docker compose build --no-cache
docker compose up -d
```

### Run Rails Commands

```bash
# Rails console
docker compose exec web bundle exec rails console

# Run migrations
docker compose exec web bundle exec rails db:migrate

# Run tests
docker compose exec web bundle exec rspec

# Generate something
docker compose exec web bundle exec rails generate model Post title:string
```

### Database Operations

```bash
# Access PostgreSQL CLI
docker exec -it yourapp_postgres psql -U yourapp -d yourapp_production

# Create database backup
docker exec yourapp_postgres pg_dump -U yourapp yourapp_production > backup_$(date +%Y%m%d).sql

# Reset database (DESTRUCTIVE)
docker compose down
sudo rm -rf postgres
docker compose up -d
docker compose exec web bundle exec rails db:create db:migrate db:seed
```

### View Logs

```bash
# All logs
docker compose logs -f

# Just web
docker compose logs -f web

# Just database
docker compose logs -f database
```

---

## Troubleshooting

### Connection Refused / Can't Connect to Database

**Symptoms:**
```
connection to server at "172.x.x.x" failed: Connection refused
```

**Check:**
```bash
# Verify postgres is running
docker ps | grep postgres

# Check if containers are on same network
docker network inspect yourapp_network | grep -E "yourapp_web|yourapp_postgres"

# Verify DNS resolution
docker exec yourapp_web getent hosts yourapp_postgres
```

**Common Causes:**
1. Database container not started yet (use `depends_on`)
2. Wrong network configuration
3. Containers on different networks

---

### Password Authentication Failed

**Symptoms:**
```
FATAL: password authentication failed for user "yourapp"
```

**This is THE most common issue. Here's the checklist:**

1. **Check if old postgres data exists:**
   ```bash
   ls -la postgres/
   ```
   If the directory exists with data, the password was set during **first initialization** and your current `.env` password doesn't match.

2. **Solution - Complete Database Reset:**
   ```bash
   docker compose down
   sudo rm -rf postgres  # DESTRUCTIVE - deletes all data
   docker compose up -d
   ```

3. **Verify initialization logs:**
   ```bash
   docker logs yourapp_postgres 2>&1 | grep -i "init"
   ```
   Should see: `PostgreSQL init process complete; ready for start up`
   Should NOT see: `Database directory appears to contain a database; Skipping initialization`

4. **Check environment variables are loaded:**
   ```bash
   docker exec yourapp_postgres env | grep POSTGRES
   docker exec yourapp_web env | grep POSTGRES
   ```

**Key Insight**: Postgres sets the password ONCE during initialization. Changing `.env` later doesn't update an existing database.

---

### Wrong Postgres Container (DNS Collision)

**Symptoms:**
```
Password authentication failed
# But postgres logs show no connection attempts
```

**Diagnosis:**
```bash
# Check what IP "database" resolves to
docker exec yourapp_web getent hosts yourapp_postgres

# Check what other postgres containers exist
docker ps | grep postgres

# Check what containers are on caddy_net
docker network inspect caddy_net | grep -i postgres
```

**Common Cause:**
Using generic hostname like `database` on a shared network (caddy_net) where multiple apps have postgres containers.

**Solution:**
Use **explicit, unique container names** in docker-compose.yml:
- Container name: `yourapp_postgres` (not `database`)
- POSTGRES_HOST: `yourapp_postgres` (not `database`)

---

### Database Doesn't Exist

**Symptoms:**
```
FATAL: database "yourapp_production" does not exist
```

**Solution:**
```bash
docker compose exec web bundle exec rails db:create
```

Or check your `POSTGRES_DB` env var matches what Rails expects.

---

### Port Already in Use

**Symptoms:**
```
Bind for 0.0.0.0:3000 failed: port is already allocated
```

**Solution:**
```bash
# Find what's using the port
lsof -i :3000

# Either stop that process or change RAILS_PORT in .env
echo "RAILS_PORT=3001" >> .env
docker compose up -d
```

---

### pg_hba.conf Confusion

**If you see auth errors**, check what pg_hba.conf says:

```bash
docker exec yourapp_postgres cat /var/lib/postgresql/data/pg_hba.conf | tail -10
```

Default should be:
```
host all all all scram-sha-256
```

**Don't mess with this unless you know what you're doing.** The auth issue is almost always wrong password, not wrong auth method.

---

## Production Deployment

### Prerequisites on Server

1. **Caddy network must exist:**
   ```bash
   docker network create caddy_net
   ```

2. **Setup .env for production:**
   ```bash
   cd ~/docker/docker_deploy/yourapp
   cp .env.example .env
   nano .env
   ```

   Set:
   ```bash
   RAILS_ENV=production
   POSTGRES_PASSWORD=strong_random_password
   RAILS_MASTER_KEY=your_master_key_from_config_master_key
   SECRET_KEY_BASE=$(docker compose run --rm web bundle exec rails secret)
   ```

### Deploy

```bash
cd ~/docker/docker_deploy/yourapp
git pull
docker compose down
docker compose build
docker compose up -d

# First time only: create database
docker compose exec web bundle exec rails db:create db:migrate

# Or restore from backup
docker compose down
rm -rf postgres
cp backup.sql db/init/01-restore.sql
docker compose up -d
```

### Caddy Configuration

**File: `~/docker/caddy/Caddyfile`**

```
yourapp.yourdomain.com {
    reverse_proxy yourapp_web:3000

    log {
        output file /data/logs/yourapp_access.log
    }
}
```

**Reload Caddy:**
```bash
docker exec caddy caddy reload --config /etc/caddy/Caddyfile
```

---

## Key Lessons Learned

### 1. DNS Collisions Are Real
On shared networks like `caddy_net`, using generic names like `database` can resolve to the wrong container. **Always use unique, prefixed names.**

### 2. Postgres Password is Set Once
The `POSTGRES_PASSWORD` env var only matters during **first initialization**. If you change it later, you must wipe the `postgres/` directory.

### 3. Network Troubleshooting
If Rails can't connect, verify both containers are on the same network:
```bash
docker network inspect yourapp_network
```

### 4. Keep It Simple
- No multi-stage builds unless needed
- No Redis unless you actually use it
- No complex security hardening for simple apps
- Standard Postgres (not Alpine) for compatibility

### 5. Environment Variables Win
Use explicit env vars instead of DATABASE_URL for clarity and debuggability.

---

## Checklist for New Projects

- [ ] Copy Dockerfile
- [ ] Copy docker-compose.yml
- [ ] Update all `yourapp` references to your app name
- [ ] Update container names to be unique
- [ ] Update POSTGRES_HOST to match database container name
- [ ] Create .env from .env.example
- [ ] Add postgres/ and .env to .gitignore
- [ ] Update config/database.yml
- [ ] Test locally: `docker compose up -d`
- [ ] Create database: `docker compose exec web bundle exec rails db:create db:migrate`
- [ ] Verify: `docker compose exec web bundle exec rails console`

---

## Quick Reference

```bash
# Start
docker compose up -d

# Stop
docker compose down

# Logs
docker compose logs -f web

# Rails console
docker compose exec web bundle exec rails console

# Database backup
docker exec yourapp_postgres pg_dump -U yourapp yourapp_production > backup.sql

# Complete reset (DESTRUCTIVE)
docker compose down && sudo rm -rf postgres && docker compose up -d

# Check networks
docker network inspect yourapp_network | grep -E "Name|Container"

# Verify DNS
docker exec yourapp_web getent hosts yourapp_postgres
```

---

## Support

If you encounter issues not covered here:

1. Check container logs: `docker compose logs -f`
2. Verify environment variables: `docker exec yourapp_web env | grep POSTGRES`
3. Test database connectivity: `docker exec yourapp_postgres psql -U yourapp -d yourapp_production -c "SELECT 1;"`
4. Check network connectivity: `docker exec yourapp_web getent hosts yourapp_postgres`

---

**Generated from battle-tested setup at greyhat.cl - September 2025**