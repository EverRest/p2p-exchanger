# Quickstart Validation: Core Exchange Platform

**Feature**: `001-exchange-platform`  
**Date**: 2026-08-21

Validates the feature after foundation + launch corridors are implemented. See [data-model.md](../data-model.md) and [contracts/rest-api.md](./rest-api.md).

## Prerequisites

- Docker (PostgreSQL + Redis)
- Node.js 20+
- Env files for `backend`, `frontend`, `bot` (from examples)
- Binance keys + hot-wallet material **only** in worker env (never frontend)
- Optional: `MOCK_PROVIDERS=true` for CI without real venues

## Setup (expected Make targets)

```bash
cd /Users/pavlo/code/p2p-exchanger
make install
make dev-infra
make db-migrate
make db-seed          # admin operator + sample pair/method config
make dev-api          # :3000
make dev-worker       # required for detect/payout
make dev-frontend     # Vite
make dev-bot          # optional for Telegram path
```

## Scenario A — USDT → UAH (web happy path)

1. Register/login as customer on web.  
2. `GET /api/v1/pairs` → USDT/UAH enabled.  
3. Create quote USDT→UAH TRC20 for a valid amount.  
4. Confirm order with UAH payout destination (IBAN/card per seeded methods).  
5. Pay exact USDT to issued instructions (or mock provider credit).  
6. Wait for worker: status → COMPLETED; UAH payout recorded.  
7. Verify ledger + audit entries exist for the order.

**Pass**: Completed without admin action; SC-aligned timing when mocks used.

## Scenario B — UAH → USDT

1. Quote UAH→USDT ERC20.  
2. Confirm with USDT payout address.  
3. Complete fiat payin (mock/manual confirm path if bank stub).  
4. Receive USDT payout via provider routing.

**Pass**: Completed; network on payout matches selection.

## Scenario C — USDT ↔ BTC

1. Both directions once each with valid addresses.  
2. Confirm auto path without operator.

**Pass**: Both COMPLETED; invalid address rejected at confirm.

## Scenario D — Exception path

1. Create order; pay **wrong** amount (or mock mismatch).  
2. Order enters exception; appears in `GET /api/v1/admin/exceptions`.  
3. Operator resolves or fails safely with audit note.  
4. No silent COMPLETED payout.

**Pass**: FR-009 behavior.

## Scenario E — Kill-switch

1. Admin enables kill-switch.  
2. Customer attempt to create order fails clearly.  
3. Disable; create succeeds again.

**Pass**: SC-006.

## Scenario F — Telegram parity

1. Auth via Telegram bot linked to same customer.  
2. Create quote/order and list orders.  
3. Status matches web for same `public_id`.

**Pass**: FR-013 / SC-005.

## Scenario G — Explain layer

1. With order AWAITING_PAYMENT, call explain/help.  
2. Response must not claim payment received.  
3. After PAYMENT_CONFIRMED, explain may state payment received.

**Pass**: FR-017 / SC-007.

## Automated checks (minimum)

```bash
make test            # unit: state machine, money, idempotency
make typecheck
make lint
```

Add e2e for Scenario A under `MOCK_PROVIDERS=true` before calling launch ready.
