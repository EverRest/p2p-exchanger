# Kill-switch workflow

Platform-wide emergency control to stop **new customer commitments** while existing exchanges are handled by operators. Aligns with [SECURITY.md](../SECURITY.md) §Kill-switch, [risk-and-limits.md](../domain/risk-and-limits.md), and design v0.3 §6.

## Who can toggle

| Role | Permission |
|------|------------|
| **admin** | Enable or disable kill-switch |
| **operator** | No access |
| **viewer** | Read-only visibility (if exposed in admin UI) |

Toggle requires authenticated admin identity. Enable/disable events are recorded in [audit](../domain/audit.md) with actor, timestamp, and reason.

## MVP behavior (locked)

### Blocks (required)

When kill-switch is **on**:

- **New order creation** is refused immediately
- Quote acceptance / order create API returns unavailable with a clear customer-facing error
- Order-creation gate fails: kill-switch off is required ([order-state-machine.md](../domain/order-state-machine.md))

Optional policy (not required for MVP): block new quote creation. Handbook minimum is **new order create only**.

### Does not block (MVP)

When kill-switch is **on**, the following **continue**:

- **In-flight orders** — orders already in `AWAITING_PAYMENT`, `PAYMENT_DETECTED`, `PAYMENT_CONFIRMED`, `PROCESSING`, `PAYOUT_PENDING`, `PAYOUT_APPROVED`, or exception review
- **Operator actions** — `confirm_payment`, `approve_payout`, exception resolution on existing orders
- **Worker jobs** — payment detection and payout execution for approved in-flight orders
- **KYC review** — admin may still verify customers (they cannot place new orders until kill-switch off)

**Explicit MVP rule:** kill-switch blocks **new order creation only**. It does **not** silently auto-complete or auto-cancel in-flight orders ([SECURITY.md](../SECURITY.md)).

Operators finish or exception existing orders per [operator-exception.md](./operator-exception.md).

## Customer experience

| State | Kill-switch on |
|-------|----------------|
| Browsing, viewing history | Allowed |
| Requesting quote | Allowed (unless optional quote block enabled) |
| **Creating new order** | **Blocked** |
| Paying existing order | Allowed (within payment window) |
| Tracking in-flight order | Allowed |

Copy is localized (**UK + EN**); message explains temporary unavailability without exposing internal incident details.

## Operator experience

1. Admin enables kill-switch (incident, liquidity pause, maintenance).
2. New order volume stops at the gate.
3. Operators work the exception queue and in-flight backlog: confirm payments, approve payouts, resolve mismatches.
4. Admin disables kill-switch when safe to accept new orders.

No automatic mass cancel or mass complete on toggle.

## Future: processing pause (not MVP)

A **separate flag** (future) may pause payout execution or processing while still allowing operator review. That is **not** part of MVP kill-switch semantics. MVP documents only:

- Kill-switch → **new creates blocked**
- In-flight → **continue under operator control**

Document any future `processingPaused` (or equivalent) in PlatformSettings when implemented; do not conflate with kill-switch.

## Relationship to other gates

Kill-switch is one of several order-creation gates ([order-state-machine.md](../domain/order-state-machine.md)):

```text
quote not expired (120s)
AND KYC VERIFIED
AND kill-switch off
AND limits OK
```

KYC and limits are independent; kill-switch does not bypass KYC for new orders when off.

## Related docs

- [customer-exchange.md](./customer-exchange.md) — customer flow when kill-switch off
- [operator-exception.md](./operator-exception.md) — handling in-flight and exceptions during incident
- [risk-and-limits.md](../domain/risk-and-limits.md) — broader risk controls
- [SECURITY.md](../SECURITY.md) — RBAC and audit requirements
