#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${API_BASE_URL:-http://localhost:3000/api/v1}"

echo "==> Smoke test against ${BASE_URL}"

health_code="$(curl -s -o /dev/null -w '%{http_code}' "${BASE_URL}/health" || true)"
if [[ "$health_code" != "200" ]]; then
  echo "Health check failed: HTTP $health_code"
  echo "(API not implemented yet — expected until feature work starts.)"
  exit 1
fi
echo "OK health"
