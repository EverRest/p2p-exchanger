# Architecture

Modular **NestJS monolith** with a **privileged worker** process. Domain logic lives in bounded modules; infrastructure adapters implement ports. Aligns with [design v0.3](./superpowers/specs/2026-08-21-p2p-exchanger-design.md) and [SECURITY.md](./SECURITY.md).

## Backend modules

Single deployable API (`backend/`) plus worker (`backend/src/worker/`). Each module owns its aggregates, commands, queries, and infrastructure adapters.

| Module | Responsibility |
|--------|----------------|
| **auth** | Customer and operator sessions; email/phone login; step-up OTP on sensitive changes |
| **customers** | Customer profile, locale, Telegram link |
| **kyc** | KycCase lifecycle; `KycProvider` orchestration; VERIFIED gate before orders |
| **quotes** | Immutable quotes; TTL **120s**; fee pipeline |
| **orders** | Order aggregate; state machine (`PAYOUT_APPROVED` is operator-visible status) |
| **payments** | Pay-in detection signals; payment methods (Card, IBAN, Monobank, PrivatBank) |
| **payouts** | Pay-out execution after operator approval |
| **rates** | Market rate snapshots via `RateProvider` |
| **exchange** | Liquidity routing via `ExchangeProvider` (Binance primary, hot wallet fallback) |
| **ledger** | Double-entry ledger entries on money-affecting transitions |
| **risk** | Limits, mismatch flags, exception queue inputs |
| **notifications** | Customer/operator notification dispatch |
| **admin** | Operator RBAC shell; confirm/approve; settings; kill-switch |
| **explain** | AI explain/copy; allowlisted context only (see SECURITY.md) |
| **shared** | Cross-cutting types, guards, outbox, idempotency helpers |
| **worker processors** | BullMQ job handlers — privileged detect, route, payout, sync, notify |

Modules do **not** import another module's repository. Cross-module reactions use **domain events** (prefer transactional outbox → worker publish).

## CQRS

```text
Controller → DTO → CommandBus / QueryBus → Handler → Domain → Port → Adapter / DB / Queue
```

- **Commands** mutate state (create order, confirm payment, approve payout, enqueue jobs).
- **Queries** read only — no side effects in query handlers.
- Never mix read and write in one handler.

See [patterns.md](./patterns.md) for event, idempotency, and state-machine patterns.

## Domain events (cross-module)

```text
PaymentDetectedEvent   → notifications, risk
PaymentConfirmedEvent  → ledger, payouts, exchange routing
PayoutApprovedEvent    → worker enqueue payout.execute
OrderCompletedEvent    → notifications, audit
```

Handlers in the owning module emit events; subscribers in other modules react without reaching into foreign tables.

## Job queues (BullMQ / Redis)

Privileged and async work runs on the **worker** only. API enqueues with idempotency keys.

| Queue | Purpose | Trigger |
|-------|---------|---------|
| `payment.detect` | Poll/webhook pay-in signals | Order awaiting payment |
| `payout.execute` | Sign and send payout (after approval) | Operator approved payout |
| `rates.sync` | Refresh market rates | Schedule / stale rate |
| `exchange.route` | Reserve/route liquidity (Binance → hot wallet policy) | Post-confirm processing |
| `notify.send` | Email/Telegram/push notifications | Domain events |

**Not queued as silent auto:** `confirm_payment` and `approve_payout` are **operator API commands** (RBAC). The worker may detect payment automatically, but state advances to confirmed payout path only after explicit operator actions — Assisted settlement per [SECURITY.md](./SECURITY.md).

## Provider ports

Domain defines interfaces; adapters live in `infrastructure/`. No vendor SDK imports in domain code.

| Port | Role | MVP |
|------|------|-----|
| `RateProvider` | Market prices for quote engine | Mock + sync job |
| `ExchangeProvider` | Liquidity (Binance primary, hot wallet fallback) | Mock; real adapter in worker |
| `PaymentProvider` | Pay-in detection (bank/card/crypto inbound) | Mock + method-specific stubs |
| `PayoutProvider` | Pay-out execution | Mock; real signing in worker only |
| `KycProvider` | Identity verification | **Mock + admin manual approve**; vendor TBD |

Secrets for exchange and wallet adapters exist **only** in the worker process.

## Frontend (React + Vite)

| App | Path | Notes |
|-----|------|-------|
| Customer web | `frontend/` | Feature folders (quotes, orders, kyc, explain); TanStack Query → public API |
| Admin | `admin/` | Operator dashboards; separate auth; confirm/approve actions |

**i18n:** Ukrainian (`uk`) and English (`en`). Locale from `Accept-Language` (web) or Telegram `language_code`; fallback **uk**.

Tailwind + TypeScript. No business rules duplicated in the client beyond presentation and form validation — server is source of truth.

## Telegram bot (grammY)

- Thin client: grammY handlers call the **same public REST API** as the web app.
- **No business rules** in the bot beyond routing user input to API calls and rendering responses.
- Bot token and session linking live in API/bot process — never in frontend bundles.

## Stack summary

| Layer | Choice |
|-------|--------|
| Frontend | React + Vite + TS + Tailwind + TanStack Query + i18n (uk/en) |
| API | NestJS + CQRS + Prisma + PostgreSQL |
| Worker | Nest + **BullMQ** + Redis |
| Bot | **grammY** → public API |
| Runtime | Node **22** |

## Related docs

- [system-overview.md](./system-overview.md) — process diagram and channels
- [patterns.md](./patterns.md) — CQRS, hexagonal, events, idempotency
- [domain/](./domain/) — entities and state machine (handbook)
