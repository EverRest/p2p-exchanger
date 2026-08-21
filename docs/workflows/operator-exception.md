# Operator and exception workflow

How operators handle the **Assisted** settlement path and the **exception queue**. All money-moving commands require RBAC and emit [audit events](../domain/audit.md). See [SECURITY.md](../SECURITY.md) §Assisted settlement and §RBAC.

## Roles (RBAC)

| Role | Can do | Cannot do |
|------|--------|-----------|
| **viewer** | Read orders, exceptions, audit, dashboards | Any mutation |
| **operator** | `confirm_payment`, `approve_payout`, exception queue actions, operational notes | Kill-switch, platform settings, operator user management |
| **admin** | Everything operator can do, plus kill-switch, fees/config, operator user management | — |

Sensitive mutations require authenticated operator identity. Step-up OTP applies to auth profile changes per product auth rules.

## Happy-path operator actions

### confirm_payment

**When:** Order is `PAYMENT_DETECTED` (automatic detection has fired).

**Who:** **operator** or **admin**.

**Action:** Operator verifies inbound amount, method, and payer match the order. Runs **`confirm_payment`** command.

**Result:** Order → `PAYMENT_CONFIRMED` → `PROCESSING`. Ledger recognizes inbound funds ([ledger.md](../domain/ledger.md)). Audit records operator id, timestamp, and reason.

**Not equivalent to:** Customer “I paid”, receipt upload, or AI text. Those are signals only ([payment-and-payout.md](../domain/payment-and-payout.md)).

### approve_payout

**When:** Order is `PAYOUT_PENDING` (payout prepared, not yet approved).

**Who:** **operator** or **admin**.

**Action:** Operator reviews payout destination, amount, and risk. Runs **`approve_payout`** command.

**Result:** Order → `PAYOUT_APPROVED`. Worker may then execute payout (signing secrets in worker only). Audit + ledger entries on approval and execution.

**Rule:** Worker must not sign or send payout until approval is persisted ([payment-and-payout.md](../domain/payment-and-payout.md)).

## Exception queue

Risk, mismatch, or failed payout does **not** auto-advance to payout. Instead an **ExceptionCase** is opened or updated ([order-state-machine.md](../domain/order-state-machine.md) exception side-path).

### Common triggers

| Trigger | Typical state | Notes |
|---------|---------------|-------|
| Amount mismatch | `PAYMENT_DETECTED` | Detected amount ≠ quoted amount |
| Duplicate provider reference | `PAYMENT_DETECTED` | Same ref on multiple orders |
| Velocity / limit breach mid-flight | Any non-terminal | May block payout |
| Payout provider failure | `PAYOUT_PENDING` / `PAYOUT_APPROVED` | Ambiguous or failed execution |
| Elevated risk score | Before `PAYOUT_APPROVED` | Blocks auto payout ([risk-and-limits.md](../domain/risk-and-limits.md)) |

### Operator resolution (within policy)

Authorized **operator** or **admin** resolves the exception. Outcomes depend on policy and case facts:

| Resolution | Effect |
|------------|--------|
| **Resume happy path** | e.g. confirm_payment after manual verification, then continue to approve_payout |
| **Refund** | Order → `REFUNDED`; funds returned per policy |
| **Cancel** | Order → `CANCELLED` when allowed before irreversible steps |
| **Fail** | Order → `FAILED` when unrecoverable (e.g. payout exhausted retries) |

Every resolution requires audit: who, when, reason code, linked `exceptionCaseId` and `orderId`.

### Mismatch workflow (example)

1. Detection sets `PAYMENT_DETECTED` with amount X; quote expected Y.
2. System opens ExceptionCase (mismatch).
3. Operator contacts customer if needed; verifies bank/provider records.
4. If acceptable: operator **`confirm_payment`** with documented variance reason, or adjust per policy.
5. If not acceptable: **refund** or **cancel** within policy; never auto-payout on ambiguous signals.

## Idempotency

Operator commands use idempotency keys to prevent double confirm or double approve ([payment-and-payout.md](../domain/payment-and-payout.md)). Duplicate requests return the original outcome.

## Kill-switch interaction

When kill-switch is on, **new orders** are refused ([kill-switch.md](./kill-switch.md)). **In-flight orders continue** — operators finish confirm/approve or resolve exceptions on existing orders. MVP kill-switch does not pause processing.

## Query and tooling

Operators use admin UI (and future runbooks) to:

- Filter exception queue by type, age, pair
- View order timeline, payment/payout sub-states, and audit trail
- Attach operational notes (audited where configured)

**viewer** role may monitor but not act.

## Related docs

- [order-state-machine.md](../domain/order-state-machine.md) — states and forbidden transitions
- [risk-and-limits.md](../domain/risk-and-limits.md) — limits and elevated risk
- [audit.md](../domain/audit.md) — required audit categories
- [SECURITY.md](../SECURITY.md) — trust boundaries and logging
