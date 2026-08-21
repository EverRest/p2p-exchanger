# Order state machine

The **Order** aggregate owns exchange lifecycle status. Payment and payout have their own sub-states (see [payment-and-payout.md](./payment-and-payout.md)); order status reflects the overall customer-visible progress.

## Happy path (Assisted)

Operator actions marked with ★.

```text
CREATED
  → AWAITING_PAYMENT          (customer must pay within payment window)
  → PAYMENT_DETECTED          (worker/provider signal; may be automatic)
  → PAYMENT_CONFIRMED ★       (operator confirms inbound funds)
  → PROCESSING                (liquidity routing, internal checks)
  → PAYOUT_PENDING            (payout prepared; awaiting approval)
  → PAYOUT_APPROVED ★         (operator approved outbound transfer)
  → COMPLETED
```

`PAYOUT_APPROVED` is an **order-visible status** — customers and operators see that payout was approved before final completion.

## Payment window

From `AWAITING_PAYMENT`, the customer has **30 min** to pay. Expiry transitions the order to terminal `EXPIRED` unless cancelled earlier.

## Terminal states

No forward progress after reaching a terminal state.

| Status | Meaning |
|--------|---------|
| **COMPLETED** | Exchange fulfilled; payout executed |
| **EXPIRED** | Quote or payment window elapsed |
| **CANCELLED** | Customer or system cancelled before completion |
| **REFUNDED** | Funds returned after partial progress |
| **FAILED** | Unrecoverable failure (e.g. payout failed after retries) |

## Exception side-path

Risk, amount mismatch, or failed payout does **not** auto-advance to payout. Instead:

```text
(any non-terminal state)
  → ExceptionCase opened (risk queue)
  → operator resolution → may resume happy path, REFUNDED, or FAILED
```

Elevated risk blocks automatic transition to `PAYOUT_APPROVED` or payout execution. See [risk-and-limits.md](./risk-and-limits.md).

## Order creation gates

Before `CREATED → AWAITING_PAYMENT`:

- Quote not expired (**120s** TTL)
- Customer KYC **VERIFIED**
- Kill-switch off
- Limits within config (placeholders)

## Forbidden transitions

The state machine is **forward-only** except explicit operator exception resolution. Examples of **forbidden** transitions:

| From | To | Reason |
|------|-----|--------|
| `COMPLETED` | `AWAITING_PAYMENT` | Completed orders are terminal |
| `COMPLETED` | `PAYOUT_PENDING` | Cannot reopen payout |
| `PAYMENT_CONFIRMED` | `AWAITING_PAYMENT` | Confirmed payment is not reversible in-place |
| `EXPIRED` | `PROCESSING` | Terminal state |
| `PAYOUT_APPROVED` | `PAYMENT_DETECTED` | Cannot roll back past confirm |

Implementation must reject illegal transitions at the domain layer (not only in UI).

## Ledger and audit coupling

Money-affecting transitions emit [ledger entries](./ledger.md) and [audit events](./audit.md):

- `PAYMENT_CONFIRMED` — recognize inbound funds
- `PAYOUT_APPROVED` / `COMPLETED` — recognize outbound settlement
