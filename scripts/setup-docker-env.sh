#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

copy_if_missing() {
  local src="$1"
  local dest="$2"
  if [[ -f "$dest" ]]; then
    echo "skip  $dest (already exists)"
    return
  fi
  cp "$src" "$dest"
  echo "create $dest from $(basename "$src")"
}

copy_if_missing "$ROOT/backend/.env.docker" "$ROOT/backend/.env"
copy_if_missing "$ROOT/backend/.env.worker.example" "$ROOT/backend/.env.worker"
copy_if_missing "$ROOT/frontend/.env.docker" "$ROOT/frontend/.env"
copy_if_missing "$ROOT/bot/.env.docker" "$ROOT/bot/.env"

echo
echo "Docker env files are ready."
echo "  backend/.env        — API (no wallet secrets)"
echo "  backend/.env.worker — privileged worker secrets only"
echo "  frontend/.env / bot/.env"
echo
echo "Start stack:  make docker-app"
echo "Local infra:  make dev-infra"
