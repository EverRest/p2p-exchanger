# Quickstart Validation: Core Exchange Platform

**Feature**: `001-exchange-platform`  
**Date**: 2026-08-21

Validates the feature after foundation + launch corridors are implemented. See [data-model.md](./data-model.md) and [contracts/rest-api.md](./contracts/rest-api.md).

## Prerequisites

- Docker (PostgreSQL + Redis)
- **Node 22**
- Env files for `backend`, `frontend`, `bot` (from examples)
- Customer with **KYC status VERIFIED** (seed or admin approve via mock KYC path)
- Operator account (seeded) for Assisted confirm/approve steps
- Binance keys + hot-wallet material **only** in worker env (never frontend)
- **`MOCK_PROVIDERS=true`** recommended for local/CI without real venues (includes mock `KycProvider`)

## Setup (expected Make targets)

```bash
cd /Users/pavlo/code/p2p-exchanger
make install
make dev-infra
make db-migrate
make db-seed          # admin operator + sample pair/method config + KYC fixtures
make dev-api          # :3000
make dev-worker       # required for detect/payout
make dev-frontend     # Vite
make dev-bot          # optional grammY Telegram path
```

## Scenario A — USDT → UAH (web Assisted happy path)

1. Register/login as customer; complete KYC → **VERIFIED** (mock submit + admin approve if needed).  
2. `GET /api/v1/pairs` → USDT/UAH enabled.  
3. Create quote USDT→UAH TRC20 for a valid amount (120s TTL).  
4. Confirm order with UAH payout destination (IBAN/card/Monobank/PrivatBank per seeded methods).  
5. Pay exact USDT to issued instructions (or mock provider credit) → status `PAYMENT_DETECTED`.  
6. **Operator** calls admin **confirm payment** → `PAYMENT_CONFIRMED` → processing → `PAYOUT_PENDING`.  
7. **Operator** calls admin **approve payout** → `PAYOUT_APPROVED`; worker executes payout → `COMPLETED`.  
8. Verify ledger + audit entries (operator actor on confirm/approve).

**Pass**: Completed with operator confirm + approve recorded; SC-aligned timing when mocks used.

## Scenario B — UAH → USDT

1. Customer **KYC VERIFIED**.  
2. Quote UAH→USDT ERC20.  
3. Confirm with USDT payout address.  
4. Complete fiat payin (mock/manual detect path if bank stub) → operator **confirm payment**.  
5. Operator **approve payout**; receive USDT via provider routing.

**Pass**: Completed with operator steps; network on payout matches selection.

## Scenario C — USDT ↔ BTC

1. Customer **KYC VERIFIED**; both directions once each with valid addresses.  
2. After detect, operator **confirm payment** and **approve payout** on each order.

**Pass**: Both COMPLETED with Assisted audit trail; invalid address rejected at confirm.

## Scenario D — Exception path

1. Create order (KYC VERIFIED); pay **wrong** amount (or mock mismatch).  
2. Order enters exception; appears in `GET /api/v1/admin/exceptions`.  
3. Operator resolves or fails safely with audit note.  
4. No silent COMPLETED payout without approve_payout.

**Pass**: FR-009 behavior.

## Scenario E — Kill-switch

1. Admin enables kill-switch.  
2. Customer attempt to create order fails clearly (even with VERIFIED KYC).  
3. Disable; create succeeds again.

**Pass**: SC-006.

## Scenario F — Telegram parity (grammY)

1. Auth via Telegram bot linked to same **VERIFIED** customer.  
2. Create quote/order and list orders.  
3. Status matches web for same `public_id` (including `PAYOUT_APPROVED` when applicable).

**Pass**: FR-013 / SC-005.

## Scenario G — Explain layer

1. With order AWAITING_PAYMENT, call explain/help.  
2. Response must not claim payment received.  
3. After operator **confirm payment**, explain may state payment received.  
4. With `EXPLAIN_ENABLED` / API key present, prod default is **on**.

**Pass**: FR-020 / SC-007.

## Scenario H — KYC gate

1. Authenticated customer with KYC **not** VERIFIED attempts `POST /orders`.  
2. Receives 403 with clear message to complete KYC.  
3. After admin approves KYC, order create succeeds.

**Pass**: FR-018 / FR-022.

## Automated checks (minimum)

```bash
make test            # unit: state machine, money, idempotency
make typecheck
make lint
```

Add e2e for Scenario A under `MOCK_PROVIDERS=true` before calling launch ready.
