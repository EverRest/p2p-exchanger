# Implementation Plan: Core Exchange Platform

**Branch**: `001-exchange-platform` | **Date**: 2026-08-21 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/001-exchange-platform/spec.md`

## Summary

Deliver a client↔platform exchange with generic pairs (fiat↔crypto, crypto↔crypto, fiat↔fiat), launching **USDT↔UAH** and **USDT↔BTC**, mostly automatic settlement, Web + Telegram + admin. Implementation follows **transl8.ai** engineering: NestJS CQRS modular monolith, separate privileged BullMQ worker, Prisma/PostgreSQL, React+Vite frontend, provider ports with Binance primary + hot-wallet fallback.

## Technical Context

**Language/Version**: TypeScript 5.x on Node.js 20+

**Primary Dependencies**: NestJS (CQRS), Prisma, BullMQ, React 18+, Vite, TanStack Query, Zod (shared validation), grammY or Telegraf (Telegram bot), Pino

**Storage**: PostgreSQL (source of truth), Redis (queue/cache only)

**Testing**: Jest (backend unit/e2e), Vitest (frontend), Playwright for critical UI happy path (later)

**Target Platform**: Linux containers (Docker Compose local; VPS/cloud deploy)

**Project Type**: Multi-app monorepo (API + worker + web + bot)

**Performance Goals**: Quote create &lt; 2s p95 under normal load; status propagation to clients &lt; 30s (per SC-005); not aiming for HFT

**Constraints**: Wallet/exchange secrets only in worker; no JS `number` for money; idempotent payment/payout; kill-switch; constitution gates

**Scale/Scope**: Single-operator desk MVP; launch 2 corridors × 2 directions; 2–3 UAH methods; USDT TRC20+ERC20; BTC mainnet; fiat↔fiat model ready but disabled

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate | Status | Notes |
|------|--------|-------|
| I. Funds safety / state machine / ledger+audit | PASS | Designed in data-model + order transitions |
| II. Privilege separation / providers / no HTTP blocking | PASS | Worker-only secrets; provider ports; queues for detect/payout |
| III. TDD for money paths | PASS | Plan requires tests with domain modules |
| IV. Spec/docs-first / ADR for new patterns | PASS | Spec Kit + docs/ADR path from DEVELOPMENT-DIRECTION |
| V. Modular monolith / generic pairs / YAGNI | PASS | No microservices; pair config; bot is thin client |

**Post–Phase 1 re-check**: PASS — contracts and data model keep money mutations in API/domain with worker executing privileged providers; no constitution violations requiring Complexity Tracking.

## Project Structure

### Documentation (this feature)

```text
specs/001-exchange-platform/
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
└── tasks.md              # /speckit-tasks (not this command)
```

### Source Code (repository root)

```text
p2p-exchanger/
├── AGENTS.md
├── Makefile
├── docker-compose.yml
├── VERSION
├── backend/
│   ├── prisma/
│   ├── src/
│   │   ├── main.ts                 # HTTP API
│   │   ├── worker.main.ts          # Privileged worker
│   │   ├── auth/
│   │   ├── customers/
│   │   ├── quotes/
│   │   ├── orders/
│   │   ├── payments/
│   │   ├── payouts/
│   │   ├── rates/
│   │   ├── exchange/               # ExchangeProvider adapters orchestration
│   │   ├── ledger/
│   │   ├── risk/
│   │   ├── notifications/
│   │   ├── admin/
│   │   ├── explain/                # AI copy layer (sanitized prompts)
│   │   ├── shared/                 # money VO, prisma, queues, logging
│   │   └── worker/                 # processors only
│   └── test/
├── frontend/
│   └── src/features/               # exchange, orders, admin, auth, …
├── bot/                            # Telegram → API
├── docs/                           # system-overview, domain, workflows, adr
└── scripts/
```

**Structure Decision**: Mirror transl8.ai (`backend` with `main` + `worker.main`, `frontend` Vite features). Add `bot/` as thin Telegram client. No Nest logic inside frontend.

## Complexity Tracking

> No constitution violations requiring justification.

## Phase 0 & 1 Artifacts

- [research.md](./research.md) — stack & pattern decisions  
- [data-model.md](./data-model.md) — entities & state machine  
- [contracts/](./contracts/) — REST API surface  
- [quickstart.md](./quickstart.md) — local validation scenarios  
