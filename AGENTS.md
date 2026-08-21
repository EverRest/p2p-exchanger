# AGENTS.md

Canonical instructions for AI coding agents working on **p2p-exchanger**.

Client↔platform exchange (not a peer marketplace). Stack and DX mirror **transl8.ai**: NestJS modular monolith + privileged BullMQ worker, React+Vite, PostgreSQL+Prisma, Redis.

> **Current phase:** repository & Spec Kit preparation. Feature implementation starts later from `specs/001-exchange-platform/tasks.md`. Do not invent product code outside agreed specs.

> **Rule:** Read `.specify/memory/constitution.md`, `docs/coding-standards.md`, and `docs/patterns.md` before coding. If you cannot explain the change with domain + workflow docs in 60 seconds, you do not understand it yet.

---

## Agent system prompt (use this)

```text
You are a senior engineer on p2p-exchanger (NestJS CQRS modular monolith + React + privileged worker).

BEFORE writing code:
1. Read constitution + docs/coding-standards.md + docs/patterns.md
2. Read relevant specs/001-exchange-platform/* and docs/domain|workflows when they exist
3. Find an existing similar handler/component (prefer transl8.ai patterns)
4. Plan the smallest correct diff (KISS, DRY, SOLID, YAGNI)
5. If more than one reasonable approach exists, propose options and ask

WHILE implementing:
- DDD: Nest modules = bounded contexts; no cross-module repository imports
- CQRS: commands mutate, queries read-only; thin controllers
- TDD default for money paths: red → green → refactor (constitution III)
- Never call Binance / hot-wallet / heavy I/O from HTTP handlers — enqueue BullMQ
- Privileged secrets ONLY in worker process
- Money: never use JS number; typed Money VO
- Ask, don't assume on ambiguous requirements

WHEN done:
- make typecheck && make lint && make test (or scoped equivalents)
- Update docs/ADR if architecture or contracts changed
- Bump VERSION only when shipping product behavior (see Versioning)
```

**Spec-driven:** `specs/` + future `docs/domain|workflows` are the specification. Drift between docs and code → ask which is stale.

---

## Engineering principles (NON-NEGOTIABLE)

| Principle | In this codebase |
|-----------|------------------|
| **DDD** | Bounded contexts as Nest modules (`orders`, `quotes`, `payments`, `payouts`, `ledger`, `exchange`, …). Ubiquitous language from spec. Aggregates own invariants (Order state machine). |
| **CQRS** | `@CommandHandler` / `@QueryHandler`; controllers only validate + dispatch. |
| **TDD** | Money, ledger, state machine, payment/payout idempotency: failing test first. Other code: tests with behavior, not optional afterthought. |
| **SOLID** | S: one reason to change per handler/service. O: new providers via ports, not editing domain. L/I: small provider interfaces. D: domain depends on abstractions (`ExchangeProvider`, …). |
| **DRY** | Shared Money, errors, auth guards; extract only after second real use with same semantics. |
| **KISS / YAGNI** | Modular monolith first. No microservices, no event-sourcing-everything, no extra venues/networks without product need. |
| **Security by isolation** | API never holds wallet/exchange signing secrets. Web/bot never hold business source of truth. |

Full detail: [docs/coding-standards.md](docs/coding-standards.md), [docs/patterns.md](docs/patterns.md).

---

## Design patterns (preferred for flexibility & scale)

Use these deliberately; new cross-cutting patterns need an **ADR** under `docs/adr/`.

| Pattern | Where |
|---------|--------|
| **Ports & Adapters (Hexagonal)** | `domain/` ports; `infrastructure/` Binance, HotWallet, bank mocks |
| **Strategy / Provider registry** | Rate, payment, payout, exchange failover (like transl8 AiProvider) |
| **State machine** | Order lifecycle — no ad-hoc `status =` |
| **Domain events** | Cross-module reactions (payment confirmed → payout), not foreign repos |
| **Outbox** | Persist event with state change; worker publishes |
| **Saga / process manager** | Multi-step settle with compensations where needed |
| **Idempotency key** | Payment detect, payout execute, admin actions |
| **Repository** | Persistence behind module boundary (Prisma in infrastructure) |
| **Factory** | Quote/order snapshot construction |
| **Value Object** | Money, AssetRef, Network |
| **Circuit breaker / failover** | Binance → hot wallet (policy in worker) |

Anti-patterns: god services, SDK imports in domain, money as `number`, secrets in Next/Vite/API, business rules in Telegram bot.

---

## Repository layout

```text
p2p-exchanger/
├── AGENTS.md
├── Makefile
├── docker-compose.yml
├── docker-compose.staging.yml
├── backend/          # Nest API + worker.main + Prisma
├── frontend/         # React + Vite
├── bot/              # Thin Telegram client
├── docs/             # standards, patterns, deploy, product
├── specs/            # Spec Kit feature specs
├── scripts/          # CI helpers, hooks, deploy
└── .specify/         # Spec Kit toolkit + constitution
```

---

## Versioning

Semver in `VERSION`, `backend/package.json`, `frontend/package.json`, `bot/package.json`.

Bump on product commits via `./scripts/bump-version.sh` (patch +1; if patch ≥ 10 → minor +1, patch = 1). Skip for pure chore/docs with no shipped behavior.

---

## Definition of done (when feature work starts)

- [ ] Behavior covered by tests (money paths: TDD)
- [ ] `make typecheck` / `make lint` / `make test` pass
- [ ] Prisma migration if schema changed
- [ ] No privileged secrets in API/frontend
- [ ] Docs/ADR updated if architecture changed
- [ ] Smallest diff — no drive-by refactors

---

## Docs map

| Doc | Purpose |
|-----|---------|
| [.specify/memory/constitution.md](.specify/memory/constitution.md) | Governance |
| [docs/coding-standards.md](docs/coding-standards.md) | Naming, layers, TDD/SOLID/DDD practice |
| [docs/patterns.md](docs/patterns.md) | CQRS, providers, outbox, saga, idempotency |
| [docs/DEVELOPMENT-DIRECTION.md](docs/DEVELOPMENT-DIRECTION.md) | Reuse from transl8.ai |
| [docs/SCOPE.md](docs/SCOPE.md) | Product decisions |
| [specs/001-exchange-platform/](specs/001-exchange-platform/) | Spec, plan, tasks |
| [docs/ci.md](docs/ci.md) | CI |
| [docs/deploy/staging.md](docs/deploy/staging.md) | Staging deploy |
