#!/usr/bin/env bash
# Bump product version across VERSION + backend/frontend/bot package.json.
# Rules (see AGENTS.md): patch += 1; if patch >= 10 then minor += 1, patch = 1
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

current="$(tr -d '[:space:]' < VERSION)"
if [[ ! "$current" =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
  echo "Invalid VERSION: $current" >&2
  exit 1
fi

major="${BASH_REMATCH[1]}"
minor="${BASH_REMATCH[2]}"
patch="${BASH_REMATCH[3]}"

if [[ "${1:-}" != "" ]]; then
  next="$1"
  if [[ ! "$next" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Invalid target version: $next" >&2
    exit 1
  fi
else
  if (( patch >= 10 )); then
    minor=$((minor + 1))
    patch=1
  else
    patch=$((patch + 1))
  fi
  next="${major}.${minor}.${patch}"
fi

printf '%s\n' "$next" > VERSION

for pkg in backend/package.json frontend/package.json bot/package.json; do
  node -e "
    const fs = require('fs');
    const p = process.argv[1];
    const j = JSON.parse(fs.readFileSync(p, 'utf8'));
    j.version = process.argv[2];
    fs.writeFileSync(p, JSON.stringify(j, null, 2) + '\n');
  " "$pkg" "$next"
done

echo "Bumped version: ${current} → ${next}"
echo "Files: VERSION, backend/frontend/bot package.json"
echo "Remember: promote Unreleased changelog when you start shipping features."
