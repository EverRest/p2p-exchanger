# Risk and limits

Risk controls protect the platform from abuse, operational error, and out-of-policy payouts. Limits are **config-driven** via PlatformSettings — handbook does not fix numeric thresholds.

## Kill-switch

A platform-wide **kill-switch** (admin-controlled) blocks:

- New quote creation (optional policy)
- **New order creation** (required)
- Optionally payout execution while allowing operator review

When kill-switch is on, order creation gates fail with a clear customer-facing error. Existing in-flight orders follow exception workflows; no silent auto-payout.

## Limits (config placeholders)

Enforced at quote and/or order creation:

| Limit type | Source |
|------------|--------|
| Min / max order amount per pair | PlatformSettings |
| Daily / monthly volume per customer | PlatformSettings |
| Per-method caps | PlatformSettings |
| Concurrent open orders | PlatformSettings |

Violations reject the operation before `AWAITING_PAYMENT`. No hardcoded min/max numbers in domain docs.

## Elevated risk → exception, not auto payout

Automatic payment **detection** may set `PAYMENT_DETECTED`, but elevated risk **must not** auto-confirm payment or auto-approve payout.

Risk signals include (non-exhaustive):

- Amount mismatch vs quote
- Duplicate detection references
- Velocity / limit breaches mid-flight
- Sanctions or blocklist hits (when integrated)
- Payout provider failure or ambiguous status

On elevated risk:

1. Open or update an **ExceptionCase**
2. Halt forward transitions toward `PAYOUT_APPROVED` and `payout.execute`
3. Route to operator queue for manual resolution
4. Resolution outcomes: resume happy path, `REFUNDED`, or `FAILED` — each audited

## Relationship to KYC

KYC **VERIFIED** is a prerequisite gate, not a substitute for transaction risk checks. A verified customer can still trigger an exception on a specific order.

See [order-state-machine.md](./order-state-machine.md) exception side-path and [kyc.md](./kyc.md) for identity verification.
