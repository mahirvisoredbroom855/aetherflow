#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT_DIR"

echo "==> AetherFlow Dev Stop"
echo "==> Stopping containers..."
docker compose down

echo "✅ Development environment stopped."

echo ""
echo "Tip: If you want to remove volumes too (wipe DB/cache/localstack state):"
echo "  docker compose down -v"
