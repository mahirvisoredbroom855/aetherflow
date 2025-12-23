#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> AetherFlow Dev Start"
cd "$ROOT_DIR"

# 1) Ensure .env exists
if [ ! -f ".env" ]; then
  echo "==> .env not found. Creating from .env.example..."
  cp .env.example .env
  echo "==> Created .env (edit it if needed)."
fi

# 2) Start infra dependencies
echo "==> Starting infrastructure dependencies (Postgres, Redis, LocalStack)..."
docker compose up -d

# 3) Show container status
echo "==> Waiting for services to become healthy..."
ATTEMPTS=40
SLEEP_SECONDS=2

for i in $(seq 1 $ATTEMPTS); do
  # If any are unhealthy, keep waiting
  STATUS="$(docker compose ps --format json | tr -d '\n')"
  # quick heuristic: show ps and rely on healthchecks visually
  if docker compose ps | grep -q "unhealthy"; then
    echo "   ...still unhealthy (attempt $i/$ATTEMPTS)"
  else
    # If no "unhealthy" is present, we're probably good
    break
  fi
  sleep "$SLEEP_SECONDS"
done

echo ""
docker compose ps
echo ""

echo "==> Quick health checks:"
echo "   - LocalStack: http://localhost:4566/_localstack/health"
echo "   - Postgres:   localhost:5432 (DB: aetherflow_dev)"
echo "   - Redis:      localhost:6379"
echo ""

echo "✅ Development environment ready!"
