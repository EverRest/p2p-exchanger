# Phase 2 Foundational — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish Phase 1 leftover tooling, then ship Phase 2 foundational building blocks (Money VO, Assisted state machine, Prisma, ledger, shared Nest platform) as **separate PRs to `master`**, each a TDD pair where applicable, with **version bump on product behavior**.

**Architecture:** NestJS modular monolith under `backend/` (API + privileged worker). Domain value objects and state machine are pure TypeScript (no Nest DI required). Persistence via Prisma; money paths never use JS `number`. Follow design v0.3 Assisted settlement and constitution Principles I–III.

**Tech Stack:** Node 22, NestJS 11, Prisma, decimal.js (already in backend deps), Jest, BullMQ, Pino, React/Vite (later PRs), grammY bot (eslint in PR1).

## Global Constraints

- SoT: **p2p-exchanger only** — never edit `p2p-docs`
- Design: [docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md](../specs/2026-08-21-p2p-exchanger-design.md) v0.3
- Tasks: [specs/001-exchange-platform/tasks.md](../../../specs/001-exchange-platform/tasks.md)
- Money: never JS `number`; decimal string + currency; `decimal.js`
- Order transitions: Assisted allowlist only; operator ★ for confirm payment + approve payout
- Privileged secrets: worker only
- PR granularity: **TDD pair** (failing tests + implementation in one PR)
- Base branch: **`master`**
- Branch naming: `feat/T0xx-T0yy-short-slug` or `chore/T007-bot-eslint`
- Version: `./scripts/bump-version.sh` on product PRs; **skip** for pure chore/docs
- DoD: `make typecheck` / `make lint` / `make test` (or scoped); mark tasks `[x]` in `tasks.md` in the same PR
- English docs/comments only

## Delivery rules (locked)

| Rule | Value |
|------|--------|
| One PR | One TDD pair (or one chore task) |
| Merge target | `master` |
| Bump | Product behavior yes; chore/docs no |
| TDD money paths | Red → green → refactor inside the PR |

## PR queue (Phase 2)

| PR | Tasks | Branch slug | Bump | Notes |
|----|-------|-------------|------|-------|
| **1** | T007 | `chore/T007-bot-eslint` | no | Close Phase 1 |
| **2** | T009+T012 | `feat/T009-T012-money-vo` | yes | Pure domain |
| **3** | T010+T013 | `feat/T010-T013-order-state-machine` | yes | Pure domain |
| **4** | T014+T015 | `feat/T014-T015-prisma-schema` | yes | Schema + migration |
| **5** | T016 | `feat/T016-prisma-module` | yes | Nest Prisma + tx helper |
| **6** | T011+T023 | `feat/T011-T023-ledger` | yes | Needs Prisma from PR4–5 |
| **7** | T017+T018 | `feat/T017-T018-obs-api-bootstrap` | yes | Pino + `/api/v1` |
| **8** | T019+T020 | `feat/T019-T020-queues-worker` | yes | BullMQ + worker entry |
| **9** | T021+T022 | `feat/T021-T022-provider-ports-mocks` | yes | Ports + MOCK_PROVIDERS |
| **10** | T024 | `feat/T024-audit` | yes | Audit service |
| **11** | T025 | `feat/T025-customer-auth` | yes | JWT register/login |
| **12** | T026 | `feat/T026-operator-rbac` | yes | Admin auth + RBAC |
| **13** | T027 | `feat/T027-platform-settings` | yes | Kill-switch |
| **14** | T082+T083 | `feat/T082-T083-kyc-core` | yes | KycCase + mock provider |
| **15** | T084+T085 | `feat/T084-T085-kyc-admin-gate` | yes | Admin decide + CreateOrder gate |
| **16** | T086+T029 | `feat/T086-T029-kyc-auth-ui` | yes | Frontend KYC + auth scaffold |
| **17** | T028+T030+T031 | `feat/T028-T031-seed-admin-health` | yes | Seed, admin shell, health/Swagger |

After PR17 checkpoint: `make dev-infra && make db-migrate && make db-seed && make dev-api && make dev-worker`; Money + state machine + ledger tests green; KYC gate 403 until VERIFIED → then start US1 plan (separate plan file).

---

## File map (early PRs)

| Path | Responsibility |
|------|----------------|
| `bot/eslint.config.mjs` | ESLint flat config for bot |
| `bot/package.json` | Add typescript-eslint / prettier plugin deps if missing |
| `backend/src/shared/domain/money/money.ts` | Money VO |
| `backend/src/shared/domain/money/money.spec.ts` | Money unit tests |
| `backend/src/orders/domain/order-state-machine.ts` | Assisted transition allowlist |
| `backend/src/orders/domain/order-state-machine.spec.ts` | State machine tests |
| `backend/prisma/schema.prisma` | Domain entities skeleton |
| `backend/prisma/migrations/` | Initial migration |
| `backend/src/shared/prisma/` | PrismaModule + transactional helper |
| `backend/src/ledger/` | Append-only ledger + idempotency |

---

### PR1 — T007: Bot ESLint/Prettier

**Files:**
- Create: `bot/eslint.config.mjs`
- Modify: `bot/package.json` (devDeps if needed), `specs/001-exchange-platform/tasks.md` (check T007)
- Possibly: root Makefile lint target already covers bot — verify

- [ ] **Step 1: Branch from master**

```bash
git checkout master && git pull
git checkout -b chore/T007-bot-eslint
```

- [ ] **Step 2: Add eslint flat config mirroring backend (Node, lighter)**

Create `bot/eslint.config.mjs` based on `backend/eslint.config.mjs` but without Jest globals if unused. Install missing packages (`typescript-eslint`, `@eslint/js`, `globals`, `eslint-plugin-prettier`, `eslint-config-prettier`) in `bot/`.

- [ ] **Step 3: Verify**

```bash
cd bot && npm run lint:check && npm run format:check && npm run typecheck
```

- [ ] **Step 4: Mark T007 done in tasks.md; commit; open PR to master; merge**

No version bump (chore).

---

### PR2 — T009+T012: Money VO

**Files:**
- Create: `backend/src/shared/domain/money/money.ts`
- Create: `backend/src/shared/domain/money/money.spec.ts`
- Modify: `specs/001-exchange-platform/tasks.md`, `VERSION` + package.json via bump script

- [ ] **Step 1: Branch**

```bash
git checkout master && git pull
git checkout -b feat/T009-T012-money-vo
```

- [ ] **Step 2: Write failing tests first** (`money.spec.ts`)

Cover at minimum:

1. Construct from decimal string + currency; reject empty/invalid amount
2. Reject JS `number` constructor path (if API exposes it — prefer factory `Money.fromDecimalString` only)
3. `add` / `sub` same currency succeeds
4. `add` / `sub` mismatched currency throws
5. Compare `equals` / `gt` / `lt` same currency
6. Serialize to `{ amount: string, currency: string }`
7. Scale rules smoke: UAH 2 dp, BTC 8 dp, USDT configurable default (document in test names)

- [ ] **Step 3: Run tests — expect FAIL**

```bash
cd backend && npx jest src/shared/domain/money/money.spec.ts
```

- [ ] **Step 4: Implement `Money` with `decimal.js`**

Pure VO: immutable; no Nest imports; throw domain errors on currency mismatch.

- [ ] **Step 5: Tests green; typecheck/lint**

```bash
cd backend && npx jest src/shared/domain/money/money.spec.ts && npm run typecheck && npm run lint:check
```

- [ ] **Step 6: Mark T009+T012; bump; commit; PR → master**

```bash
./scripts/bump-version.sh
```

---

### PR3 — T010+T013: Assisted order state machine

**Files:**
- Create: `backend/src/orders/domain/order-state-machine.ts`
- Create: `backend/src/orders/domain/order-state-machine.spec.ts`
- Modify: `tasks.md`, bump

Happy path allowlist (must match docs):

```text
CREATED → AWAITING_PAYMENT → PAYMENT_DETECTED
  → PAYMENT_CONFIRMED → PROCESSING → PAYOUT_PENDING
  → PAYOUT_APPROVED → COMPLETED
```

Also: terminals `EXPIRED | CANCELLED | REFUNDED | FAILED`; forbid reverse/illegal edges; operator-only transitions are still **allowed** by the machine (authorization is elsewhere) but must exist as explicit edges.

- [ ] **Step 1: Failing tests** — every happy-path edge allowed; sample forbidden edges rejected; `PAYOUT_APPROVED` present
- [ ] **Step 2: Implement** `canTransition` / `assertTransition` / status enum
- [ ] **Step 3: Green + bump + PR**

---

### PR4 — T014+T015: Prisma schema + migration

**Files:**
- Create/modify: `backend/prisma/schema.prisma`
- Create: `backend/prisma/migrations/...`
- Entities per tasks.md: Customer, KycCase, Asset refs, ExchangePair, PaymentMethod, Quote, Order, Payment, Payout, LedgerEntry, AuditEvent, ExceptionCase, OperatorUser, PlatformSettings

- [ ] Align enums with design (KYC statuses, OrderStatus incl. `PAYOUT_APPROVED`)
- [ ] `prisma migrate` against local docker Postgres (`make dev-infra`)
- [ ] Document migration; bump; PR

---

### PR5 — T016: Prisma Nest module

**Files:** `backend/src/shared/prisma/*` — PrismaService, PrismaModule, `runInTransaction` helper

- [ ] Unit/smoke test or compile-time wiring in AppModule
- [ ] Bump; PR

---

### PR6 — T011+T023: Ledger + idempotency

**Depends on:** PR4–5

- [ ] Failing tests: duplicate idempotency key does not double-post; append-only
- [ ] Implement ledger service
- [ ] Bump; PR

---

### PR7+ — follow queue table above

Each subsequent PR: same ritual — branch from `master`, TDD when money-related, mark tasks, bump if product, PR to `master`, merge, next.

---

## Spec self-review (this plan)

- No TBD placeholders in PR1–3 steps
- Ledger explicitly after Prisma (no contradiction with earlier draft)
- Scope = Phase 2 only; US1 is a follow-up plan
- Ambiguity resolved: authorization for ★ transitions is **not** in the state machine PR (RBAC later)

## Checkpoint before US1

All of T007–T031 and T082–T086 checked in `tasks.md`; local boot works; foundational unit tests green.
