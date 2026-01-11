# Backend Setup Guide

## Prerequisites

- Node.js 18+ installed
- Docker and Docker Compose installed
- npm or yarn

## Quick Start

### 1. Install Dependencies

```bash
cd backend
npm install
```

### 2. Setup Environment Variables

Create a `.env` file in the `backend` directory:

```bash
cp .env.example .env
```

Or create `.env` manually with these values:

```env
# Node Environment
NODE_ENV=development

# Database Configuration (PostgreSQL)
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha
DATABASE_PASSWORD=szybkafucha_dev_password
DATABASE_NAME=szybkafucha

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d

# Application Port
PORT=3000

# CORS Configuration
CORS_ORIGIN=http://localhost:3000,http://localhost:5173
```

### 3. Start Docker Services (PostgreSQL & Redis)

**Option A: Using the startup script (Recommended)**

From the `backend` directory:

```bash
./start-dev.sh
```

This script will:
- Check/create `.env` file
- Start Docker services
- Wait for PostgreSQL to be ready
- Start the NestJS backend

**Option B: Manual Docker setup**

From the project root directory:

```bash
# Login to Docker Hub (if required)
docker login

# Start services
docker-compose up -d postgres redis
```

This will start:
- PostgreSQL on port 5432
- Redis on port 6379
- pgAdmin on port 5050 (optional)

**Option C: Install PostgreSQL locally (if Docker doesn't work)**

```bash
# macOS
brew install postgresql@15
brew services start postgresql@15

# Create database and user
createdb szybkafucha
createuser szybkafucha
psql -c "ALTER USER szybkafucha WITH PASSWORD 'szybkafucha_dev_password';"
psql -c "GRANT ALL PRIVILEGES ON DATABASE szybkafucha TO szybkafucha;"
```

### 4. Verify Docker Services

Check if services are running:

```bash
docker-compose ps
```

You should see `postgres` and `redis` services running.

### 5. Start the Backend

```bash
cd backend
npm run start:dev
```

The application will start on `http://localhost:3000`

## Troubleshooting

### Database Connection Error

If you see `Unable to connect to the database`:

1. **Check if Docker is running:**
   ```bash
   docker ps
   ```

2. **Check if PostgreSQL container is running:**
   ```bash
   docker-compose ps
   ```

3. **Start Docker services:**
   ```bash
   docker-compose up -d
   ```

4. **Check PostgreSQL logs:**
   ```bash
   docker-compose logs postgres
   ```

5. **Verify connection manually:**
   ```bash
   docker exec -it szybkafucha-postgres psql -U szybkafucha -d szybkafucha
   ```

### Docker Login Required

If you see "authentication required" when running `docker-compose up`:

1. **Login to Docker Hub:**
   ```bash
   docker login
   ```

2. **Or use public images without login** - the images should be publicly available

### Alternative: Install PostgreSQL Locally

If you prefer not to use Docker:

1. **Install PostgreSQL:**
   ```bash
   # macOS
   brew install postgresql@15
   brew services start postgresql@15
   
   # Create database and user
   createdb szybkafucha
   createuser szybkafucha
   psql -c "ALTER USER szybkafucha WITH PASSWORD 'szybkafucha_dev_password';"
   psql -c "GRANT ALL PRIVILEGES ON DATABASE szybkafucha TO szybkafucha;"
   ```

2. **Update `.env` file** with your local PostgreSQL credentials

### Redis Connection Error

If Redis is not available:

1. **Start Redis container:**
   ```bash
   docker-compose up -d redis
   ```

2. **Or install Redis locally:**
   ```bash
   # macOS
   brew install redis
   brew services start redis
   ```

## Health Check

Once the backend is running, check health endpoint:

```bash
curl http://localhost:3000/health
```

You should see a JSON response with database and Redis status.

## Database Migrations

The application uses TypeORM with `synchronize: true` in development mode, which automatically creates/updates database schema.

For production, use migrations:

```bash
npm run migration:generate -- -n MigrationName
npm run migration:run
```

## Seed Database (Optional)

To populate database with test data:

```bash
npm run seed
```

Or to reset and seed:

```bash
npm run seed:fresh
```

