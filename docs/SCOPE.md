# Product scope (decisions)

**Authoritative design:** [design v0.3](./superpowers/specs/2026-08-21-p2p-exchanger-design.md)  
**Security:** [SECURITY.md](./SECURITY.md)

Source notes: `docs/product/` (English rewrite from design v0.3).

## Product model

**Client ↔ platform exchanger** (not a peer marketplace).

Flow: quote → order → client pays → payment detected → **operator confirms payment** → processing → **operator approves payout** → complete  
(with terminal states: expired / cancelled / refunded / failed).

Settlement is **Assisted**: automation may detect payments, but **confirm payment** and **approve payout** require an authorized operator. Customer “I paid” is not final confirm. Operators also handle exceptions and disputes.

Order-visible status includes **`PAYOUT_APPROVED`** before completion.

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
| UAH | **4 methods:** Card, IBAN, Monobank, PrivatBank |

## Timing (decided)

| Parameter | Default |
|-----------|---------|
| Quote TTL | **120s** |
| Payment window | **30 min** |

Min/max order amounts: config placeholders only (no fixed numbers in docs).

## Fees (decided — config; admin-editable)

| Corridor | Spread | Service fee | Notes |
|----------|--------|-------------|--------|
| USDT ↔ UAH | **1.0%** | **0.2%** | USDT network fees via `network_fee_usdt_trc20` / `_erc20` placeholders |
| USDT ↔ BTC | **0.8%** | **0.2%** | BTC network fee from provider estimate; snapshot on quote |

| UAH payment fee | Rate |
|-----------------|------|
| Card | **0.5%** |
| IBAN | **0%** |
| Monobank | **0%** |
| PrivatBank | **0%** |

**Minimum absolute service fee:** equivalent of **10 UAH** on small orders (config).

## KYC (decided)

**VERIFIED** KYC required before any order. Vendor **TBD**; MVP uses mock provider + manual admin approval. See [SECURITY.md](./SECURITY.md) for PII and AI isolation rules.

## Auth & i18n (decided)

- Auth: email **or** phone; step-up OTP on sensitive profile changes  
- Client UI **UK + EN**; locale from Accept-Language / Telegram `language_code`; fallback **uk**

## Liquidity (decided)

`ExchangeProvider` abstraction:

1. **Primary:** Binance  
2. **Fallback:** own **hot wallet**

No vendor SDK inside domain.

## Operator controls (decided)

Assisted settlement with mandatory state machine, idempotency, ledger, audit, kill-switches, risk limits, and RBAC.

| Role | Scope |
|------|-------|
| **viewer** | Read-only orders, audit, dashboards |
| **operator** | `confirm_payment`, `approve_payout`, exception queue |
| **admin** | Kill-switch, platform settings, fee/config, operator user management |

## Client channels (decided)

**Web + Telegram** (both full clients → same API/domain).  
Web also hosts **admin**.

## AI (decided)

**Explain / copy in MVP** — feature flag; prod default **on** if API key present. No tools, no DB/PII access, allowlisted sanitized prompt context only. See [SECURITY.md](./SECURITY.md).

## Stack (decided) — option B + privileged worker

Aligned with **transl8.ai** engineering practices — see [`DEVELOPMENT-DIRECTION.md`](./DEVELOPMENT-DIRECTION.md).

| Layer | Tech | Privilege |
|-------|------|-----------|
| Web | **React + Vite** + TypeScript + Tailwind + TanStack Query + i18n (uk/en) | Public / session only |
| API | NestJS + CQRS + TypeScript + Prisma + PostgreSQL | Business logic, RBAC, ledger writes, KYC orchestration; **no** wallet private keys |
| Queue | Redis + BullMQ | Job transport |
| Worker | Separate Nest application context (`worker.main`) | **Only place** for hot-wallet keys, Binance signing secrets, payout execution |
| Bot | **grammY** thin client → API | Bot token only |
| Runtime | **Node 22** | — |
| DX | pnpm or npm workspaces, Makefile, Docker Compose, GitHub Actions, ADRs, TDD | — |
| Observability | Pino structured logs + tracing (as in transl8) + Sentry | — |

Modular monolith API (not microservices). Domain modules mirror transl8 layout; cross-module via **events**, not foreign repositories.

## Delivery strategy

1. Foundation: monorepo, state machine, ledger, provider interfaces, auth, KYC port, admin RBAC shell, web + bot stubs  
2. Launch: `USDT ↔ UAH` Assisted on web (+ explain with flag), then `USDT ↔ BTC`; USDT TRC20+ERC20; UAH 4 methods; Binance + hot wallet  
3. Then: Telegram parity; fiat↔fiat corridor; real Binance / hot wallet / KYC vendor adapters  

Specs cover all three pair types; tasks may phase C.

## Explicit non-goals for first release

Microservices/K8s, many liquidity venues, mobile apps, AI with tools or data access, peer-offer marketplace, event-sourcing the whole system, touching **`p2p-docs`**, legal opinions, production key ceremony, complete OpenAPI YAML.

## Repo phase

**Handbook first (now):** design v0.3, [SECURITY.md](./SECURITY.md), domain/workflows, product rewrite, ADRs, sync specs/001.  
**Feature implementation:** deferred — start from `specs/001-exchange-platform/tasks.md` when handbook DoD is green.
