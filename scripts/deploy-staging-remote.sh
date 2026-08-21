#!/usr/bin/env bash
# Remote staging deploy steps (pulled by GitHub Actions SSH).
set -euo pipefail
DEPLOY_PATH="${DEPLOY_PATH:-/opt/p2p-exchanger}"
DEPLOY_BRANCH="${DEPLOY_BRANCH:-develop}"
COMPOSE_FILE="${COMPOSE_FILE:-docker-compose.yml:docker-compose.staging.yml}"

cd "$DEPLOY_PATH"
git fetch origin
git checkout "$DEPLOY_BRANCH"
git pull --ff-only origin "$DEPLOY_BRANCH"
docker compose -f ${COMPOSE_FILE//:/ -f } up -d --build
echo "Deploy finished at $(date -u +%Y-%m-%dT%H:%M:%SZ)"
