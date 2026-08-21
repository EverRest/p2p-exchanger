#!/usr/bin/env bash
set -euo pipefail

# Create isolated e2e database on the compose postgres (host port 5435).
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTAINER="${POSTGRES_CONTAINER:-$(docker compose -f "$ROOT/docker-compose.yml" ps -q postgres)}"

if [[ -z "$CONTAINER" ]]; then
  echo "Postgres container not running. Start with: make dev-infra" >&2
  exit 1
fi

docker exec -i "$CONTAINER" psql -U exchange -d postgres -c \
  "SELECT 1 FROM pg_database WHERE datname = 'p2p_exchange_e2e'" | grep -q 1 \
  || docker exec -i "$CONTAINER" psql -U exchange -d postgres -c \
    "CREATE DATABASE p2p_exchange_e2e OWNER exchange;"

echo "e2e database ready: p2p_exchange_e2e"
