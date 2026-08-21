# Product scope (decisions)

Source notes: `docs/product/` (copied from `~/code/p2p-docs`).

## Product model

**Client ↔ platform exchanger** (not a peer marketplace).

Flow: quote → order → client pays → payment detected/confirmed → processing → payout → complete  
(with terminal states: expired / cancelled / refunded / failed).

Happy path is **mostly automatic**; operators handle **exceptions and disputes**.

## Pair types — all three (product goal)

| Type | Example | Notes |
|------|---------|--------|
| **A. Fiat ↔ crypto** | UAH ↔ USDT | Primary corridor |
| **B. Crypto ↔ crypto** | USDT ↔ BTC | Same provider path; different pair |
| **C. Fiat ↔ fiat** | UAH ↔ EUR | Two payment rails + FX; after A+B |

Domain: generic pairs (`input_asset` / `output_asset`) + pluggable payment, payout, rate, and exchange providers.

## Launch corridors (decided)

| Corridor | Directions |
|----------|------------|
| Fiat ↔ crypto | `USDT ↔ UAH` (both ways) |
| Crypto ↔ crypto | `USDT ↔ BTC` (both ways) |

## Networks & payment methods (decided)

| Asset / rail | Launch choices |
|--------------|----------------|
| USDT | **TRC20** and **ERC20** |
| BTC | Mainnet (address format validated in ops) |
| UAH | **2–3 methods**: card and/or IBAN (banks via config) |

## Liquidity (decided)

`ExchangeProvider` abstraction:

1. **Primary:** Binance  
2. **Fallback:** own **hot wallet**

No vendor SDK inside domain.

## Automation (decided)

Mostly automatic settlement; operators on exceptions/disputes.  
Mandatory: state machine, idempotency, ledger, audit, kill-switches, risk limits → human review.

## Client channels (decided)

**Web + Telegram** (both full clients → same API/domain).  
Web also hosts **admin**.

## AI (decided)

**Copy / explain layer only** — no order tools, no DB/PII access, sanitized prompt context.

## Stack (decided) — option B + privileged worker

Aligned with **transl8.ai** engineering practices — see [`DEVELOPMENT-DIRECTION.md`](./DEVELOPMENT-DIRECTION.md).

| Layer | Tech | Privilege |
|-------|------|-----------|
| Web | **React + Vite** + TypeScript + Tailwind + TanStack Query + feature folders (mirrors transl8.ai) | Public / session only |
| API | NestJS + CQRS + TypeScript + Prisma + PostgreSQL | Business logic, RBAC, ledger writes; **no** wallet private keys |
| Queue | Redis + BullMQ | Job transport |
| Worker | Separate Nest application context (`worker.main`) | **Only place** for hot-wallet keys, Binance signing secrets, payout execution |
| Bot | grammY/Telegraf thin client → API | Bot token only |
| DX | pnpm or npm workspaces, Makefile, Docker Compose, GitHub Actions, ADRs, TDD | — |
| Observability | Pino structured logs + tracing (as in transl8) + Sentry | — |

Modular monolith API (not microservices). Domain modules mirror transl8 layout; cross-module via **events**, not foreign repositories.

## Delivery strategy

1. Foundation: monorepo, state machine, ledger, provider interfaces, admin, web + bot stubs  
2. Launch: `USDT ↔ UAH` + `USDT ↔ BTC`, USDT TRC20+ERC20, UAH 2–3 methods, Binance + hot wallet, auto happy path  
3. Then: fiat↔fiat corridor; optional order-aware AI later  

Specs cover all three pair types; tasks may phase C.

## Explicit non-goals for first release

Microservices/K8s, many liquidity venues, mobile apps, AI that moves funds or reads privileged order data, peer-offer marketplace, event-sourcing the whole system.

## Repo phase

**Preparation only (now):** Spec Kit artifacts, DevOps (Make/Docker/CI/hooks), and engineering principles (`AGENTS.md`, coding-standards, patterns).  
**Feature implementation:** deferred — start later from `specs/001-exchange-platform/tasks.md` when explicitly kicked off.
