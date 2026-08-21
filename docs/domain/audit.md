# Audit

**AuditEvent** records are immutable evidence of who did what, when, and why. They complement the append-only [ledger](./ledger.md) and order state history.

## Principles

- **Append-only** — audit events are never updated or deleted.
- **Who / when / why** — every operator action and automated state transition carries actor, timestamp, and reason/code.
- **Correlation** — link to `orderId`, `paymentId`, `payoutId`, `kycCaseId`, or `exceptionCaseId` as applicable.

## What must be audited

| Category | Examples |
|----------|----------|
| **Order transitions** | `AWAITING_PAYMENT` → `PAYMENT_DETECTED` → `PAYMENT_CONFIRMED` → … → `PAYOUT_APPROVED` → `COMPLETED` |
| **Operator actions** | Confirm payment, approve payout, reject KYC, resolve exception, toggle kill-switch, fee config change |
| **Customer actions** | Order create, cancel, “I paid” hint (not treated as payment confirm) |
| **System actions** | Expiry (quote **120s**, payment window **30 min**), worker detection, payout execution result |
| **KYC** | Status changes on KycCase via `KycProvider` or admin |

## Event shape (conceptual)

Each audit event includes at minimum:

- `eventType` — e.g. `order.status_changed`, `operator.payment_confirmed`, `kyc.status_changed`
- `actorType` — `customer`, `operator`, `system`, `worker`
- `actorId` — user id or service identity
- `occurredAt` — UTC timestamp
- `resourceType` / `resourceId`
- `payload` — from/to status, reason code, idempotency key reference (no secrets)
- `reason` — human or machine-readable justification for operator actions

## Relationship to security

- RBAC: only authorized roles perform auditable operator commands (viewer read-only).
- Audit supports dispute resolution and regulatory inquiry without exposing wallet secrets or full PII in log payloads.
- AI must not invent audit entries or payment confirmation (see [SECURITY.md](../SECURITY.md)).

## Query expectations

Admin and compliance read models query audit by order, customer, operator, and time range. Audit is not a substitute for ledger balances but explains **decisions** behind ledger and state changes.
