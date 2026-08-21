#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STAGED="$(git diff --cached --name-only --diff-filter=ACM || true)"

if [[ -z "$STAGED" ]]; then
  exit 0
fi

if echo "$STAGED" | grep -q '^backend/'; then
  echo "==> Typecheck backend (staged changes)"
  (cd "$ROOT/backend" && npm run typecheck)
fi

if echo "$STAGED" | grep -q '^frontend/'; then
  echo "==> Typecheck frontend (staged changes)"
  (cd "$ROOT/frontend" && npm run typecheck)
fi

if echo "$STAGED" | grep -q '^bot/'; then
  echo "==> Typecheck bot (staged changes)"
  (cd "$ROOT/bot" && npm run typecheck)
fi
