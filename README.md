# p2p-exchanger

Client↔platform currency/asset exchange. **Spec-driven** ([Spec Kit](https://github.com/github/spec-kit)) with engineering DNA from [transl8.ai](../translate.ai) (Nest modular monolith + privileged worker).

## Status

**Repository preparation** — product specs and DevOps are in place; feature implementation starts later from `specs/001-exchange-platform/tasks.md`.

## Quick links

| Doc | Purpose |
|-----|---------|
| [AGENTS.md](AGENTS.md) | Agent playbook + principles |
| [docs/coding-standards.md](docs/coding-standards.md) | DDD, TDD, SOLID, DRY, KISS |
| [docs/patterns.md](docs/patterns.md) | Design patterns for flexibility |
| [docs/SCOPE.md](docs/SCOPE.md) | Product decisions |
| [specs/001-exchange-platform/](specs/001-exchange-platform/) | Spec / plan / tasks |
| [docs/ci.md](docs/ci.md) | CI |
| [docs/deploy/staging.md](docs/deploy/staging.md) | Staging |

## Tooling

```bash
make help
make hooks-install
make install          # when lockfiles exist: npm ci in apps
make docker-env
make dev-infra        # postgres :5435 + redis :6380
make ci               # lint, format-check, typecheck, test, build
```

Node **22** (`.nvmrc`).

## Architecture (target)

```text
React (Vite) + Telegram bot → NestJS API → PostgreSQL
                                    ↓
                              Redis/BullMQ → Privileged worker
                                             (Binance + hot wallet secrets)
```
