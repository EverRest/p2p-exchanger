# ADR 0002: Assisted settlement

## Status

Accepted — 2026-08-21

## Context

The platform moves customer funds through inbound payment detection and outbound payout. Fully automated settlement is too risky at launch: provider signals can be ambiguous, amounts can mismatch, and outbound transfers are irreversible. The product requires operator oversight on money movement while still allowing automation where safe.

## Decision

1. Settlement mode is **Assisted** for all corridors at launch.
2. **Payment detect** may run automatically (worker, webhooks, provider polling).
3. **`confirm_payment`** requires an authorized **operator** (RBAC). Customer “I paid”, receipts, or bot messages are signals only — they do **not** advance the order to `PAYMENT_CONFIRMED`.
4. **`approve_payout`** requires an authorized **operator** before funds leave platform custody.
5. Order lifecycle includes **`PAYOUT_APPROVED`** as an order-visible status before `COMPLETED`.
6. Risk, mismatch, or failed payout opens an **exception queue** — no automatic payout on ambiguous signals.
7. Payment window is **30 minutes** from `AWAITING_PAYMENT`; quote TTL remains **120 seconds** (see order gates).

## Consequences

- State machine and API must reject transitions to `PAYMENT_CONFIRMED` or payout execution without operator actions.
- UI and bot copy must not imply payment is confirmed until operator action and system state reflect it.
- Metrics and SLAs attribute confirm/approve to operators; idempotency keys protect duplicate operator commands.
- Worker jobs may detect payments but cannot bypass operator gates (see [0004-privilege-separation-worker.md](./0004-privilege-separation-worker.md)).
- Full operational rules live in [SECURITY.md](../SECURITY.md) §Assisted settlement and [order-state-machine.md](../domain/order-state-machine.md).
