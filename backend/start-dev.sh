#!/bin/bash

# Szybka Fucha - Development Startup Script

echo "🚀 Starting Szybka Fucha Backend Development Environment"
echo ""

# Check if .env exists
if [ ! -f .env ]; then
  echo "⚠️  .env file not found. Creating from .env.example..."
  if [ -f .env.example ]; then
    cp .env.example .env
    echo "✅ Created .env file. Please review and update if needed."
  else
    echo "❌ .env.example not found. Please create .env manually."
    exit 1
  fi
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
  echo "❌ Docker is not running. Please start Docker Desktop."
  exit 1
fi

# Check if Docker services are running
echo "📦 Checking Docker services..."
if ! docker-compose ps | grep -q "szybkafucha-postgres.*Up"; then
  echo "🐘 Starting PostgreSQL and Redis..."
  
  # Try to start services
  if docker-compose up -d postgres redis 2>&1 | grep -q "authentication required"; then
    echo ""
    echo "⚠️  Docker Hub authentication required."
    echo "   Please run: docker login"
    echo "   Then try again, or install PostgreSQL locally:"
    echo ""
    echo "   macOS:"
    echo "   brew install postgresql@15"
    echo "   brew services start postgresql@15"
    echo "   createdb szybkafucha"
    echo "   createuser szybkafucha"
    echo ""
    exit 1
  fi
  
  echo "⏳ Waiting for PostgreSQL to be ready..."
  sleep 5
else
  echo "✅ Docker services are already running"
fi

# Verify PostgreSQL is ready
if docker exec szybkafucha-postgres pg_isready -U szybkafucha > /dev/null 2>&1; then
  echo "✅ PostgreSQL is ready"
else
  echo "⚠️  PostgreSQL might not be ready yet. Waiting a bit more..."
  sleep 3
fi

# Start the backend
echo ""
echo "🎯 Starting NestJS backend..."
echo ""
npm run start:dev

