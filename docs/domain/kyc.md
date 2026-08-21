# KYC

Identity verification is mandatory **before any order**. The domain orchestrates KYC through a **`KycProvider` port** — no vendor SDK in domain code.

## KycCase statuses

| Status | Meaning |
|--------|---------|
| **UNVERIFIED** | No submission or not yet started |
| **PENDING** | Submitted; awaiting provider or admin review |
| **VERIFIED** | Approved — customer may create orders |
| **REJECTED** | Failed verification; may re-submit per policy |
| **BLOCKED** | Hard block; no orders until admin override |

Only **VERIFIED** passes the order-creation gate. Other statuses reject quote binding and order create.

## Gate before order

Order creation requires:

```text
customer.kycStatus == VERIFIED
AND quote valid (not expired, 120s TTL)
AND kill-switch off
AND limits OK
```

KYC status is checked at order create, not only at quote time — a customer who was verified at quote but blocked before confirm must still be rejected.

## KycProvider port

Defined in domain; implemented in infrastructure.

| Concern | Domain rule |
|---------|-------------|
| Submit identity | Command → `KycProvider.submit()` |
| Poll/webhook status | Worker or provider callback → update KycCase |
| Admin manual review | Operator command overrides mock/TBD vendor |

**MVP:** mock provider + **manual admin approve/reject** in admin UI. Real vendor adapter is future work.

**Vendor:** TBD for production. Handbook and code must not assume a specific vendor API shape in the domain layer.

## PII handling

KYC documents and PII stay in KYC storage with masked logging. AI explain features must not receive raw PII (see [SECURITY.md](../SECURITY.md)).

## Audit

Status transitions on KycCase emit [audit events](./audit.md): who/when/why (system, provider callback, or operator id).
