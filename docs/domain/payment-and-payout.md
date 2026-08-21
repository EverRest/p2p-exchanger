# Payment and payout

**Payment** (pay-in) and **Payout** (pay-out) are **separate aggregates** from Order. Each has its own id, status history, and idempotency scope. Order status reflects aggregate progress but does not replace payment/payout records.

## Payment aggregate

Tracks inbound funds for an order.

| Concept | Rule |
|---------|------|
| **Detection** | Worker or `PaymentProvider` may signal that funds arrived → order `PAYMENT_DETECTED`. Automatic. |
| **Confirmation** | Operator explicitly confirms amount, method, and match → order `PAYMENT_CONFIRMED`. **Not** automatic. |
| **Customer “I paid”** | Hint for operators/notifications only. Never equivalent to confirm. |

Detection and confirmation are distinct events with separate audit records.

### Payment window

When order enters `AWAITING_PAYMENT`, a **30 min** window starts. Unpaid orders after window expiry → `EXPIRED`.

### UAH methods

Card, IBAN, Monobank, PrivatBank — each may use different detection adapters. Payment-method fees from [quote-and-pricing.md](./quote-and-pricing.md) (Card **0.5%**; IBAN/Monobank/PrivatBank **0%**).

## Payout aggregate

Tracks outbound funds after payment is confirmed and processing completes.

| Concept | Rule |
|---------|------|
| **Pending** | Payout prepared; order `PAYOUT_PENDING` |
| **Approval** | Operator **approve payout** command required before execution → order `PAYOUT_APPROVED` |
| **Execution** | Worker runs `payout.execute` job with signing secrets (worker only) |
| **Completion** | Successful execution → order `COMPLETED` |

**Approve before execute:** the worker must not sign or send payout until operator approval is persisted and auditable.

## Idempotency keys

All mutating commands that touch money use idempotency keys:

| Command | Key scope |
|---------|-----------|
| Create payment detection record | `payment.detect:{orderId}:{providerRef}` |
| Confirm payment (operator) | Client-supplied or `confirm:{orderId}:{operatorId}:{version}` |
| Approve payout (operator) | Client-supplied or `approve:{orderId}:{operatorId}:{version}` |
| Execute payout (worker) | `payout.execute:{payoutId}` |

Duplicate requests with the same key return the original outcome without double-spend.

## Relationship to order state machine

```text
Order AWAITING_PAYMENT     ← Payment: waiting for inbound
Order PAYMENT_DETECTED     ← Payment: detected, unconfirmed
Order PAYMENT_CONFIRMED    ← Payment: operator confirmed
Order PAYOUT_PENDING       ← Payout: ready, unapproved
Order PAYOUT_APPROVED      ← Payout: approved, may execute
Order COMPLETED            ← Payout: executed successfully
```

See [order-state-machine.md](./order-state-machine.md) for full lifecycle and terminals.
