# KYC onboarding workflow

Identity verification is **mandatory before any order**. Customers cannot create quotes that bind to orders, or create orders directly, until KYC status is **VERIFIED**. See [kyc.md](../domain/kyc.md) and [SECURITY.md](../SECURITY.md) §KYC/PII.

## Status lifecycle

```text
UNVERIFIED  →  (customer submits)  →  PENDING
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    ▼                      ▼                      ▼
               VERIFIED               REJECTED                BLOCKED
            (may order)          (re-submit per policy)   (admin override only)
```

| Status | Customer experience |
|--------|---------------------|
| **UNVERIFIED** | Prompted to start KYC before exchange |
| **PENDING** | “Verification in progress”; **cannot create order** |
| **VERIFIED** | Full exchange flow unlocked |
| **REJECTED** | Shown reason (policy-dependent); may re-submit |
| **BLOCKED** | No orders; contact support / admin |

Only **VERIFIED** passes the order-creation gate. Other statuses reject quote binding and order create ([kyc.md](../domain/kyc.md)).

## Customer steps

### 1. Start verification

After authentication, customer opens KYC flow on web or bot. Locale **UK + EN** per design v0.3 §4.

### 2. Submit identity

Customer provides required fields and documents per product policy. API sends **`KycProvider.submit()`** via the domain port — no vendor SDK in domain code.

**MVP:** mock provider accepts submission and sets status **PENDING**. Production vendor is **TBD**; adapter is future work.

### 3. Await review

Status **PENDING**. Customer sees in-progress state on both channels. **Order creation remains blocked.**

Review path (MVP):

- **Mock provider** — may auto-advance in test environments only
- **Manual admin approve/reject** — admin in admin UI (primary MVP path)
- **Future provider** — webhook or poll updates KycCase without changing domain rules

### 4. Outcome

| Outcome | Next step |
|---------|-----------|
| **VERIFIED** | Customer may request quotes and create orders (subject to kill-switch and limits) |
| **REJECTED** | Customer may re-submit per policy; still blocked from orders |
| **BLOCKED** | Hard stop until admin override |

KYC is re-checked at **order create**, not only at quote time. A customer verified at quote but blocked before confirm is still rejected ([kyc.md](../domain/kyc.md)).

## Admin review (MVP)

| Action | Role | Effect |
|--------|------|--------|
| Approve KYC | **admin** | **PENDING** → **VERIFIED** |
| Reject KYC | **admin** | **PENDING** → **REJECTED** |
| Block customer | **admin** | → **BLOCKED** |

*Future: KYC decide may be delegated to operator per policy.*

Each transition emits [audit events](../domain/audit.md): actor, timestamp, reason.

## PII and AI

- KYC documents and raw identity fields are stored and accessed only via API orchestration and authorized admin surfaces ([SECURITY.md](../SECURITY.md)).
- **Never** send KYC documents, verification images, or raw PII to AI explain features.
- Logs mask sensitive fields; no full document content in application logs.

## Order gate (recap)

Order creation requires:

```text
customer.kycStatus == VERIFIED
AND quote valid (not expired, 120s TTL)
AND kill-switch off
AND limits OK
```

See [customer-exchange.md](./customer-exchange.md) for the post-verification exchange flow.

## Related docs

- [kyc.md](../domain/kyc.md) — KycCase statuses and KycProvider port
- [risk-and-limits.md](../domain/risk-and-limits.md) — KYC is not a substitute for per-order risk
- [audit.md](../domain/audit.md) — KYC status change auditing
