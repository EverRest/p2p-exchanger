# Research: Core Exchange Platform

**Date**: 2026-08-21  
**Feature**: `001-exchange-platform`

## R1 — Application architecture

**Decision**: NestJS modular monolith + separate BullMQ worker process (transl8.ai pattern).

**Rationale**: Matches constitution privilege separation; CQRS/DDD already proven in transl8; one deployable API with clear module boundaries; cheaper than microservices for MVP.

**Alternatives considered**:
- Next.js monolith (API routes + UI) — rejected: larger blast radius for secrets and weaker module boundaries for money.
- Microservices from day one — rejected: YAGNI, operational cost, distributed transaction pain.

## R2 — Frontend

**Decision**: React + Vite + TypeScript + Tailwind + TanStack Query + feature folders (transl8-style); UK+EN i18n.

**Rationale**: Maximum reuse of agent playbooks and UI patterns; all money logic stays in Nest API.

**Alternatives considered**:
- Next.js app router for customer UI — deferred; optional marketing site later, not the exchange shell.

## R3 — Persistence & ORM

**Decision**: PostgreSQL + Prisma.

**Rationale**: ACID, row locks, numeric types; Prisma aligns with transl8 migrations/DX; ledger and order updates in transactions.

**Alternatives considered**:
- Drizzle — viable for SQL transparency; deferred to keep transl8 parity.
- Event sourcing entire system — rejected for MVP complexity (constitution non-goal).

## R4 — Async & privilege

**Decision**: Redis + BullMQ; privileged jobs (`payment.detect`, `payout.execute`, `rates.sync`, `exchange.route`, `notify.send`) only on worker; API enqueues with idempotency keys.

**Rationale**: Constitution II; never block HTTP; secrets only in worker env.

**Alternatives considered**:
- Inline payout in API — rejected (keys in API process).
- Kafka — overkill for MVP.

## R5 — Liquidity providers

**Decision**: `ExchangeProvider` port with **Binance** primary adapter and **HotWallet** fallback; configurable failover.

**Rationale**: Product decision; domain stays vendor-agnostic (transl8 `AiProvider` analogue).

**Alternatives considered**:
- Binance only — weaker resilience.
- Hot wallet only — worse liquidity/ops for launch volume.

## R6 — Money representation

**Decision**: Domain `Money` value object using decimal string or bigint minor units + currency code; Prisma `Decimal`/`numeric`; forbid JS `number` in domain/money paths.

**Rationale**: Constitution; avoid float bugs on UAH/USDT/BTC.

**Alternatives considered**: Native `number` — rejected.

## R7 — Order orchestration

**Decision**: Explicit **Assisted** state machine service in `orders` module; transitions emit domain events; operator `confirm_payment` and `approve_payout` on happy path; ledger+audit in same DB transaction (or transactional outbox row) as state change.

**Rationale**: Constitution I; design v0.3 Assisted settlement; transl8 event + outbox patterns.

**Alternatives considered**:
- Ad-hoc `status =` updates — rejected.
- **Full auto settlement for MVP** — **rejected**: product requires operator attribution for confirm/approve; detection may assist but not bypass audit.

## R8 — Telegram

**Decision**: Separate `bot/` process using **grammY**; calls same `/api/v1` as web; no direct DB.

**Rationale**: Spec FR-013; thin client; shared rules; design locks grammY.

**Alternatives considered**:
- Bot inside Nest process — acceptable later; separate process clearer for scaling/restarts.
- **Telegraf as bot framework** — **rejected**: grammY chosen for design v0.3 (typing, middleware, transl8-adjacent DX).

## R9 — Auth

**Decision**: Session/JWT for web customers and operators (RBAC); Telegram `initData`/bot auth linked to Customer; admin routes role-guarded.

**Rationale**: Spec FR-016/FR-014; standard for transl8-like apps.

**Alternatives considered**: API keys for customers — not needed for MVP desk product.

## R10 — Explain / AI copy

**Decision**: Optional `explain` module: server builds sanitized prompt context from known UI state labels; LLM returns text only; feature-flagged with **prod default on when API key present**; no tools.

**Rationale**: Spec FR-020; constitution AI rules; design v0.3.

**Alternatives considered**: Order-aware tool agent — deferred post-launch.

## R11 — Fiat rails

**Decision**: `PaymentProvider` / `PayoutProvider` with config-driven methods; launch with stub/manual detection + path to real bank integrations; crypto deposit watchers via exchange/wallet adapters.

**Rationale**: Spec FR-004/FR-007; ship lifecycle before every bank API is live.

**Alternatives considered**: Full PSP integration day one — delays launch.

## R12 — Monorepo tooling

**Decision**: npm or pnpm workspaces; root `Makefile` (`dev-infra`, `dev-api`, `dev-worker`, `dev-frontend`, `dev-bot`, `test`, `ci`) mirroring transl8 DX; **Node 22** runtime.

**Rationale**: Agent and human familiarity; consistent scripts; design locks Node 22.

**Alternatives considered**:
- Turborepo immediately — optional later.
- Node 20 LTS — **rejected** for this repo; design v0.3 standardizes on Node 22.

## R13 — KYC gate

**Decision**: **`KycProvider` port**; MVP mock + admin manual approve/reject; **`KYC VERIFIED` required before `CreateOrder`**; `KycCase` entity tracks status.

**Rationale**: Spec FR-018/FR-019; design v0.3 and ADR-0003; regulatory/ops posture for desk product.

**Alternatives considered**:
- **Defer KYC until post-MVP** — **rejected**: order creation blocked without VERIFIED; vendor TBD but gate and admin path ship in foundation.
- KYC only above threshold — deferred numeric thresholds; gate itself is not deferred.

## R14 — Settlement mode (Assisted)

**Decision**: Automated **detection** may run on worker; **confirm payment** (after `PAYMENT_DETECTED`) and **approve payout** (before `payout.execute`) are **operator-only** actions with audit attribution; order shows `PAYOUT_APPROVED` before completion.

**Rationale**: Design v0.3 Assisted model; ADR-0002; prevents silent payout on ambiguous detection.

**Alternatives considered**: End-to-end auto on happy path — **rejected for MVP** (see R7).
