#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> lint-staged"
(cd "$ROOT" && npx --yes lint-staged@15.5.2)

echo "==> typecheck staged areas"
bash "$ROOT/scripts/pre-commit-analyze.sh"
