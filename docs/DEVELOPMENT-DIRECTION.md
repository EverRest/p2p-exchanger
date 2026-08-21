# Development direction — reuse from transl8.ai (`~/code/translate.ai`)

**Decision:** treat **transl8.ai** as the engineering reference for p2p-exchanger: modular NestJS monolith, CQRS/DDD, separate BullMQ worker, provider abstractions, docs-first + ADR, TDD, Makefile/CI habits.

Product domain differs (exchange ≠ localization); **patterns and repo shape** should match.

## Direct reuse (do the same)

| Practice | transl8.ai | Exchanger mapping |
|----------|------------|-------------------|
| Modular monolith | Nest modules as bounded contexts | `orders`, `quotes`, `payments`, `payouts`, `rates`, `exchange`, `ledger`, `risk`, `audit`, … |
| Separate worker process | `worker.main.ts` + `WorkerModule` | **Privileged** worker: Binance, hot wallet, payouts, reconciliation — secrets only here |
| Never block HTTP | AI/export only on queues | Payment sync, payout, rate sync, notifications only on queues |
| Provider abstraction | `AiProvider` + registry + fallback | `ExchangeProvider`, `PaymentProvider`, `PayoutProvider`, `RateProvider` + failover (Binance → hot wallet) |
| CQRS | CommandBus / QueryBus, thin controllers | Same; money mutations = commands |
| Cross-module | Domain events, not foreign repositories | e.g. `PaymentConfirmedEvent` → payout / ledger handlers |
| Idempotent jobs | Unique job keys, safe retries | Payment detect / payout / reconcile must be idempotent |
| Outbox (when needed) | State + outbox in one TX | Order status + notify/enqueue |
| Audit | Dedicated audit module | Every financial transition + admin override |
| Docs-first | `docs/domain`, `workflows`, `adr`, `AGENTS.md` | Same tree under exchanger `docs/` |
| ADR before new pattern | `docs/adr/NNNN-*.md` | Same |
| TDD | Jest next to handlers; e2e with Supertest | Critical for ledger/state machine |
| Make + Docker Compose | `make dev-*`, `make ci` | Same DX |
| Observability | Pino, tracing bootstrap on API + worker | Same; plus money-path metrics |
| API conventions | versioned REST `/api/v1`, Swagger | Same |
| Semver + changelog discipline | `VERSION` + package.json sync | Adopt when shipping |

## Adapt (same idea, exchange semantics)

| transl8.ai | Exchanger |
|------------|-----------|
| `TranslationJob` saga | `Order` state machine + payment/payout saga |
| Provider fallback chain (OpenAI→…) | Liquidity routing (Binance→hot wallet) + rail failover |
| Multi-tenant `tenantId` on every query | Start **single-tenant ops platform**; keep `organizationId`/`tenantId` column ready if multi-desk later |
| Approval workflow (human review copy) | Exception/dispute queue for operators (happy path auto) |
| Copilot / AI in product | **Explain/copy layer only** (no privileged tools) — still isolate like AI calls (no secrets in web) |

## Frontend choice vs transl8.ai — decided

**React + Vite + feature folders + TanStack Query + Zustand + Tailwind** (same as transl8.ai).

Rationale: maximize reuse of agent playbooks, folder layout, and API-layer patterns; keep all money logic in Nest API/worker. Marketing/landing can be a separate static or Next site later if needed — not the app shell.

## Repo shape target (mirrors transl8.ai)

```text
p2p-exchanger/
├── AGENTS.md
├── Makefile
├── docker-compose.yml
├── VERSION
├── backend/                 # NestJS API + worker.main + Prisma
│   └── src/{module}/        # domain | application | infrastructure | presentation
├── frontend/                # React (Vite) or Next — see decision below
├── bot/                     # Telegram thin client → API (extra vs transl8)
├── docs/
│   ├── system-overview.md
│   ├── architecture.md
│   ├── patterns.md
│   ├── domain/
│   ├── workflows/
│   ├── adr/
│   └── api/
└── scripts/
```

Spec Kit stays in `.specify/` + `specs/`; **runtime architecture docs** follow transl8.ai `docs/` so agents have one playbook.

## Explicit non-copy

- Localization / glossary / TM / Copilot catalog — not relevant  
- Multi-tenant SaaS billing complexity — defer  
- Putting wallet keys in API process — **forbidden** (stricter than transl8 AI keys-in-worker norm)
