# Staging deploy

Pattern aligned with transl8.ai: CI on `develop` → optional SSH deploy to a VPS with Compose.

## Prerequisites

1. Server with Docker Engine + Compose plugin (`scripts/bootstrap-staging-server.sh` is a checklist stub).
2. Clone this repo to e.g. `/opt/p2p-exchanger`.
3. Create env files (never commit secrets):

   - `backend/.env` (API)
   - `backend/.env.worker` (**only** place for Binance / hot-wallet secrets)
   - `frontend/.env`, `bot/.env`

4. TLS: place certs under `./certs` and set `server_name` in `infra/nginx/staging.conf`.

## Compose

```bash
docker compose -f docker-compose.yml -f docker-compose.staging.yml up -d --build
```

Nginx terminates TLS and proxies `/api/` → `api:3000`, `/` → `frontend:5173`.

## GitHub Actions

Workflow: [`.github/workflows/deploy-staging.yml`](../../.github/workflows/deploy-staging.yml).

Required secrets:

| Secret | Purpose |
|--------|---------|
| `DEPLOY_SSH_HOST` | VPS host |
| `DEPLOY_SSH_USER` | SSH user |
| `DEPLOY_SSH_PRIVATE_KEY` | Deploy key |
| `DEPLOY_SSH_PORT` | Optional, default 22 |
| `DEPLOY_PATH` | Optional, default `/opt/p2p-exchanger` |

Remote script: `scripts/deploy-staging-remote.sh`.

## Privilege reminder

Staging **must** keep wallet/exchange secrets out of the `api` service env. Only `worker` loads `.env.worker`.
