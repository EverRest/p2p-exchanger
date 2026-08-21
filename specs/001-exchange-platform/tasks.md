# Tasks: Core Exchange Platform

**Input**: Design documents from `/specs/001-exchange-platform/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/, quickstart.md

**Tests**: Included for money paths (constitution Principle III — TDD NON-NEGOTIABLE). Write failing tests before implementation where marked.

**Organization**: Phases by user story (US1–US5) for independent delivery.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no incomplete dependencies)
- **[Story]**: US1–US5 maps to spec user stories
- Paths relative to repo root `p2p-exchanger/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Monorepo skeleton mirroring transl8.ai / plan.md

- [x] T001 Create monorepo directories `backend/`, `frontend/`, `bot/`, `docs/`, `scripts/` per `specs/001-exchange-platform/plan.md`
- [x] T002 Initialize `backend/package.json` with NestJS, CQRS, Prisma, BullMQ, Pino, Jest and TypeScript 5 / **Node 22**
- [x] T003 [P] Initialize `frontend/package.json` with Vite, React, TanStack Query, Tailwind, Vitest
- [x] T004 [P] Initialize `bot/package.json` with **grammY** TypeScript client (**Node 22**)
- [x] T005 [P] Add root `Makefile`, `docker-compose.yml` (Postgres + Redis), `VERSION`, and `.gitignore`
- [x] T006 [P] Add `backend/.env.example`, `frontend/.env.example`, `bot/.env.example` (worker secrets documented as worker-only)
- [ ] T007 [P] Configure ESLint/Prettier for `backend/`, `frontend/`, `bot/` (backend + frontend present; **bot** still needs eslint config file)
- [x] T008 Create `AGENTS.md` stub pointing at constitution + `docs/DEVELOPMENT-DIRECTION.md`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Shared platform that ALL stories need — MUST finish before US1+

**⚠️ CRITICAL**: No user story implementation until this phase completes

### Tests (TDD — money primitives)

- [ ] T009 [P] Add failing unit tests for `Money` VO (no JS number; currency match) in `backend/src/shared/domain/money/money.spec.ts`
- [ ] T010 [P] Add failing unit tests for **Assisted** order state machine allowlist (incl. `PAYOUT_APPROVED`; operator confirm/approve transitions) in `backend/src/orders/domain/order-state-machine.spec.ts`
- [ ] T011 [P] Add failing unit tests for ledger idempotency key uniqueness behavior in `backend/src/ledger/application/ledger.service.spec.ts`

### Implementation

- [ ] T012 Implement `Money` value object in `backend/src/shared/domain/money/money.ts` (make T009 pass)
- [ ] T013 Implement **Assisted** order state machine in `backend/src/orders/domain/order-state-machine.ts` (make T010 pass)
- [ ] T014 Create Prisma schema skeleton (Customer, **KycCase**, Asset refs, ExchangePair, PaymentMethod, Quote, Order, Payment, Payout, LedgerEntry, AuditEvent, ExceptionCase, OperatorUser, PlatformSettings) in `backend/prisma/schema.prisma`
- [ ] T015 Run initial migration + `prisma generate`; document in `backend/prisma/migrations/`
- [ ] T016 Implement Prisma module + transactional helper in `backend/src/shared/prisma/`
- [ ] T017 [P] Implement Pino logging + tracing bootstrap in `backend/src/shared/observability/` for API and worker
- [ ] T018 [P] Configure Nest global prefix `/api`, URI version `v1`, validation pipe, exception filter in `backend/src/main.ts`
- [ ] T019 [P] Wire Redis + BullMQ module and queue name constants in `backend/src/shared/queues/`
- [ ] T020 Create `backend/src/worker.main.ts` + `backend/src/worker/worker.module.ts` (no wallet secrets in API env)
- [ ] T021 Implement provider ports (`RateProvider`, `ExchangeProvider`, `PaymentProvider`, `PayoutProvider`, **`KycProvider`**) in `backend/src/exchange/domain/`, `backend/src/payments/domain/`, and `backend/src/kyc/domain/`
- [ ] T022 [P] Implement Mock providers behind `MOCK_PROVIDERS` in `backend/src/exchange/infrastructure/mock/`, `backend/src/payments/infrastructure/mock/`, and `backend/src/kyc/infrastructure/mock/`
- [ ] T023 Implement ledger service (append-only + idempotency) in `backend/src/ledger/` (make T011 pass)
- [ ] T024 Implement audit service in `backend/src/audit/`
- [ ] T025 [P] Implement customer auth (register/login/JWT) in `backend/src/auth/` and `backend/src/customers/` per `contracts/rest-api.md`
- [ ] T026 [P] Implement operator auth + RBAC guards in `backend/src/admin/auth/`
- [ ] T027 Implement PlatformSettings + kill-switch read/write in `backend/src/risk/`

### KYC foundation (blocking for US1)

- [ ] T082 Implement `KycCase` repository + customer submit/status handlers in `backend/src/kyc/` per `contracts/rest-api.md`
- [ ] T083 [P] Wire mock `KycProvider` adapter (submit → pending; admin decision) in `backend/src/kyc/infrastructure/mock/`
- [ ] T084 Implement admin KYC approve/reject REST + audit in `backend/src/admin/` (RBAC: operator/admin)
- [ ] T085 Gate `CreateOrder` on **KYC VERIFIED** (403 with actionable message) in `backend/src/orders/application/create-order.handler.ts`
- [ ] T086 [P] Scaffold customer KYC UI flow in `frontend/src/features/kyc/`

- [ ] T028 Seed script: pairs USDT↔UAH + USDT↔BTC, UAH methods, operator user, sample VERIFIED KYC fixture in `backend/prisma/seed.ts`
- [ ] T029 [P] Scaffold frontend auth + API client in `frontend/src/features/auth/` and `frontend/src/shared/api/`
- [ ] T030 [P] Scaffold admin shell route in `frontend/src/features/admin/`
- [ ] T031 Add health endpoints and Swagger bootstrap in `backend/src/shared/presentation/`

**Checkpoint**: `make dev-infra && make db-migrate && make db-seed && make dev-api && make dev-worker` boot; Money + Assisted state machine + ledger tests green; KYC gate returns 403 until VERIFIED

---

## Phase 3: User Story 1 — Fiat↔crypto USDT↔UAH (Priority: P1) 🎯 MVP

**Goal**: Customer with VERIFIED KYC completes USDT↔UAH both directions on web (quote → pay → **operator confirm** → **operator approve payout** → complete)

**Independent Test**: Quickstart Scenario A + B with `MOCK_PROVIDERS=true` and operator confirm/approve

### Tests

- [ ] T032 [P] [US1] Failing unit tests for quote expiry + immutability in `backend/src/quotes/application/create-quote.handler.spec.ts`
- [ ] T033 [P] [US1] Failing e2e Assisted happy path USDT→UAH (detect → confirm → approve_payout) in `backend/test/exchange-uah-usdt.e2e-spec.ts`
- [ ] T034 [P] [US1] Failing idempotency test for double payment.detect in `backend/src/payments/application/detect-payment.handler.spec.ts`

### Implementation

- [ ] T035 [US1] Implement rates sync job + RateProvider mock/Binance stub in `backend/src/rates/` and worker processor `backend/src/worker/processors/rates-sync.processor.ts`
- [ ] T036 [US1] Implement CreateQuote command/handler in `backend/src/quotes/` (make T032 pass)
- [ ] T037 [US1] Implement confirm quote → CreateOrder + payin instructions in `backend/src/orders/` (KYC gate from T085)
- [ ] T038 [US1] Implement PaymentMethod config + UAH Card/IBAN/Monobank/PrivatBank adapters (mock) in `backend/src/payments/`
- [ ] T039 [US1] Implement `payment.detect` processor → `PAYMENT_DETECTED` with ledger+audit in `backend/src/worker/processors/payment-*.processor.ts` (make T034 pass); **no auto confirm**
- [ ] T087 [US1] Implement operator **confirm_payment** (`PAYMENT_DETECTED` → `PAYMENT_CONFIRMED`) admin action + audit in `backend/src/admin/application/`
- [ ] T040 [US1] Implement exchange routing to `PAYOUT_PENDING` after payment confirmed in `backend/src/payouts/`
- [ ] T088 [US1] Implement operator **approve_payout** (`PAYOUT_PENDING` → `PAYOUT_APPROVED`) admin action + audit in `backend/src/admin/application/`
- [ ] T089 [US1] Implement `payout.execute` worker processor **only after** `PAYOUT_APPROVED` in `backend/src/worker/processors/payout-*.processor.ts`
- [ ] T041 [US1] Expose customer REST: pairs, payment-methods, quotes, orders per `specs/001-exchange-platform/contracts/rest-api.md` in `backend/src/*/presentation/`
- [ ] T042 [US1] Enforce kill-switch on order create in `backend/src/orders/application/create-order.handler.ts`
- [ ] T043 [US1] Notifications stub (in-app/log) on status changes incl. `PAYOUT_APPROVED` in `backend/src/notifications/`
- [ ] T044 [US1] Build web exchange flow UI in `frontend/src/features/exchange/` (amount → quote → confirm → status incl. Assisted steps)
- [ ] T045 [US1] Build web orders list/detail in `frontend/src/features/orders/`
- [ ] T090 [US1] Build admin order actions UI: confirm payment + approve payout in `frontend/src/features/admin/`
- [ ] T046 [US1] Make T033 e2e pass under mocks; document in `specs/001-exchange-platform/quickstart.md` notes if needed

**Checkpoint**: USDT↔UAH Assisted happy path works on web with operator confirm + approve; MVP demoable

---

## Phase 4: User Story 2 — Crypto↔crypto USDT↔BTC (Priority: P1)

**Goal**: USDT↔BTC both directions using same Assisted engine + address/network validation

**Independent Test**: Quickstart Scenario C

### Tests

- [ ] T047 [P] [US2] Failing unit tests for BTC/USDT address+network validation in `backend/src/shared/domain/crypto/address-validation.spec.ts`
- [ ] T048 [P] [US2] Failing e2e USDT→BTC with operator confirm/approve in `backend/test/exchange-usdt-btc.e2e-spec.ts`

### Implementation

- [ ] T049 [US2] Implement address validation helpers in `backend/src/shared/domain/crypto/address-validation.ts` (make T047 pass)
- [ ] T050 [US2] Enable USDT↔BTC pair seeding/config and network rules in `backend/prisma/seed.ts` + pair service
- [ ] T051 [US2] Extend HotWallet/Binance mock adapters for BTC deposit/withdraw in `backend/src/exchange/infrastructure/`
- [ ] T052 [US2] Wire crypto payin watchers for BTC/USDT in `backend/src/worker/processors/payment-detect.processor.ts`
- [ ] T053 [US2] Update frontend pair/network selectors for BTC in `frontend/src/features/exchange/`
- [ ] T054 [US2] Make T048 e2e pass

**Checkpoint**: USDT↔BTC works independently with same Assisted lifecycle as US1

---

## Phase 5: User Story 3 — Track status & explain help (Priority: P2)

**Goal**: Clear statuses on web; explain/copy never invents payment confirmation; **grammY** Telegram parity for list/detail

**Independent Test**: Quickstart Scenario F + G

### Tests

- [ ] T055 [P] [US3] Failing unit tests for explain prompt guard (no false payment claims) in `backend/src/explain/application/explain.service.spec.ts`

### Implementation

- [ ] T056 [US3] Implement order timeline/status DTO enrichment in `backend/src/orders/presentation/`
- [ ] T057 [US3] Implement `POST /api/v1/explain` sanitized context builder in `backend/src/explain/` (make T055 pass); feature flag with **prod default on when API key present**
- [ ] T058 [US3] Add explain/help UI affordances in `frontend/src/features/orders/` and `frontend/src/features/exchange/`
- [ ] T059 [US3] Implement **grammY** Telegram auth link + quote/order/list commands calling API in `bot/src/`
- [ ] T060 [US3] Push/notify status changes to Telegram when linked in `backend/src/notifications/`

**Checkpoint**: Web+Telegram show consistent status; explain safe

---

## Phase 6: User Story 4 — Operator exceptions & disputes (Priority: P2)

**Goal**: Exception queue, admin actions, kill-switch UI, audit trail

**Independent Test**: Quickstart Scenario D + E

### Tests

- [ ] T061 [P] [US4] Failing e2e mismatch → exception (no auto payout) in `backend/test/exception-mismatch.e2e-spec.ts`
- [ ] T062 [P] [US4] Failing unit test admin action audit in `backend/src/admin/application/order-actions.handler.spec.ts`

### Implementation

- [ ] T063 [US4] Create ExceptionCase on mismatch/risk/payout failure in `backend/src/orders/` + payments/payouts handlers
- [ ] T064 [US4] Implement admin REST: orders, exceptions, settings, actions per `contracts/rest-api.md` in `backend/src/admin/`
- [ ] T065 [US4] Ensure admin actions write AuditEvent + idempotency keys in `backend/src/admin/application/` (make T062 pass)
- [ ] T066 [US4] Build admin exceptions + order detail + kill-switch UI in `frontend/src/features/admin/`
- [ ] T067 [US4] Make T061 e2e pass

**Checkpoint**: Operators can resolve exceptions; kill-switch blocks new orders

---

## Phase 7: User Story 5 — Fiat↔fiat same engine (Priority: P3)

**Goal**: Generic engine supports fiat↔fiat pair (e.g. UAH↔EUR) when enabled; disabled by default

**Independent Test**: Enable pair in seed/config; one direction end-to-end with dual fiat mocks

### Tests

- [ ] T068 [P] [US5] Failing e2e UAH→EUR with mocks in `backend/test/exchange-fiat-fiat.e2e-spec.ts`

### Implementation

- [ ] T069 [US5] Add disabled UAH↔EUR pair + EUR method stubs in `backend/prisma/seed.ts`
- [ ] T070 [US5] Ensure quote/order validation allows fiat↔fiat without crypto network in `backend/src/quotes/` and `backend/src/orders/`
- [ ] T071 [US5] Fiat payin + fiat payout mock providers path in `backend/src/payments/` and `backend/src/payouts/`
- [ ] T072 [US5] Frontend shows fiat↔fiat only when pair.enabled in `frontend/src/features/exchange/`
- [ ] T073 [US5] Make T068 pass when pair enabled via env/seed flag

**Checkpoint**: Enabling fiat↔fiat requires config only — no engine fork

---

## Phase 8: Polish & Cross-Cutting

**Purpose**: Production hardening across stories

- [ ] T074 [P] Add `docs/system-overview.md` and `docs/workflows/order-lifecycle.md` aligned with implementation
- [ ] T075 [P] ADR `docs/adr/0001-modular-monolith-and-privileged-worker.md` capturing privilege boundary
- [ ] T076 Implement Binance `ExchangeProvider` adapter (non-mock) in `backend/src/exchange/infrastructure/binance/` with secrets only in worker env
- [ ] T077 Implement HotWallet `ExchangeProvider` fallback in `backend/src/exchange/infrastructure/hot-wallet/`
- [ ] T078 [P] Reconciliation job stub `reconcile.run` in `backend/src/worker/processors/reconcile.processor.ts`
- [ ] T079 Security review checklist: no secrets in frontend/API logs; RBAC on admin; rate limits on auth in `backend/src/auth/`
- [ ] T080 Run full `specs/001-exchange-platform/quickstart.md` scenarios A–H and record results in `specs/001-exchange-platform/checklists/quickstart-results.md`
- [ ] T081 [P] CI workflow lint + typecheck + test in `.github/workflows/ci.yml`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 Setup** → **Phase 2 Foundational** (blocks all stories) → **US1 (Phase 3)** → **US2 (Phase 4)** → **US3 / US4 (Phases 5–6, parallelizable)** → **US5 (Phase 7)** → **Polish (Phase 8)**

### User Story Dependencies

| Story | Depends on | Notes |
|-------|------------|--------|
| US1 | Phase 2 + KYC foundation (T082–T086) | MVP Assisted UAH corridor |
| US2 | Phase 2 + largely US1 engine | Same Assisted confirm/approve pipeline |
| US3 | Phase 2 + order read APIs (US1) | grammY/explain after orders exist |
| US4 | Phase 2 + payment mismatch hooks (US1) | Parallel with US3 after US1 |
| US5 | Phase 2 + generic pair engine (US1) | Config enablement only |

### Parallel Opportunities

- T003–T004, T005–T008 after T001  
- T009–T011 together; T017–T019, T025–T026, T029–T030, T083/T086 after core prisma  
- T082–T086 KYC block after T021–T022  
- After Phase 2: US3 and US4 in parallel once US1 checkpoint done  
- Polish T074/T075/T081 in parallel with T076–T077 if staffed  

### Parallel Example: User Story 1 tests

```bash
# After foundational green, start US1 tests together:
# T032 quotes handler spec
# T033 e2e USDT→UAH Assisted path
# T034 payment detect idempotency
```

---

## Implementation Strategy

### MVP First (recommended stop)

1. Phase 1 + Phase 2 (incl. KYC T082–T086)  
2. Phase 3 (US1) only  
3. Validate quickstart A+B (+ H for KYC gate)  
4. Demo / soft-launch desk on UAH↔USDT  

### Incremental Delivery

1. US1 MVP → US2 crypto corridor → US3 Telegram/explain → US4 ops safety → US5 fiat↔fiat flag → Binance/hot-wallet real adapters (T076–T077)

### Suggested MVP scope

**T001–T046, T082–T090** (Setup + Foundational + KYC + US1 Assisted). Defer US2+ until US1 e2e is green.

---

## Notes

- Constitution: money-path tasks include tests first (T009–T011, T032–T034, etc.)  
- Worker is the only process that may load Binance/hot-wallet secrets (T020, T076–T077)  
- Do not put business rules in `frontend/` or `bot/` beyond API calls  
- **Assisted**: `payout.execute` MUST NOT run before operator `approve_payout` (T088–T089)  
- **KYC**: no order without VERIFIED (T085)  
- **Explain**: keep T057; prod flag default **on** when API key present  
- Commit after each task or small group; keep diffs story-scoped  
