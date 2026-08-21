# ADR 0003: KYC before orders

## Status

Accepted — 2026-08-21

## Context

The exchanger handles regulated assets and fiat rails. Allowing orders before identity verification increases fraud, chargeback, and compliance risk. The design locks a hard gate: no exchange order until the customer is verified.

## Decision

1. **No order** may be created until customer KYC status is **VERIFIED**.
2. Order-create gates enforce KYC at commit time (not only at quote time): unexpired quote + **KYC VERIFIED** + kill-switch off + limits OK.
3. **KycProvider** is a port; domain never imports vendor SDKs. Real vendor is **TBD**.
4. **MVP** uses a mock provider plus **manual admin approval** of pending cases.
5. KYC documents and raw identity fields are stored and accessed only via API orchestration and authorized admin surfaces.
6. KYC payloads are **never** sent to AI explain/copy paths (see [0005-ai-explain-only.md](./0005-ai-explain-only.md)).

## Consequences

- Quote and order endpoints must return a clear blocked response when KYC is not VERIFIED.
- **Admin** RBAC only for KYC approve/reject in MVP (operators handle confirm_payment / approve_payout, not KYC decide); transitions emit audit events.
- Web and Telegram onboarding flows must surface KYC before exchange (see [kyc-onboarding.md](../workflows/kyc-onboarding.md)).
- Future real-vendor adapter replaces mock implementation without changing the order gate contract.
- PII handling follows [SECURITY.md](../SECURITY.md) §KYC/PII.
