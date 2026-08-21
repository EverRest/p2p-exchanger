# Domain overview

The P2P Exchanger domain models a **client ↔ platform** exchange (not a peer marketplace). Customers request quotes, create orders, pay in, and receive payouts after **Assisted** operator confirm/approve steps. All money-moving rules live here; adapters implement ports defined in [architecture.md](../architecture.md).

## Ubiquitous language

| Term | Meaning |
|------|---------|
| **Customer** | End user who authenticates (email or phone), completes KYC, and places exchange orders. Not an operator. |
| **Quote** | Immutable price snapshot for a pair, amount, and payment method. Expires after **120s**. Binds fees and rates at creation time. |
| **Order** | Customer commitment to exchange at a quoted price. Owns lifecycle status from `CREATED` through `COMPLETED` or a terminal outcome. |
| **Payment** | Pay-in aggregate linked to an order. Tracks detection signals separately from operator **confirmation**. |
| **Payout** | Pay-out aggregate linked to an order. Requires operator **approval** before execution. |
| **KycCase** | Identity verification record for a customer. Order creation requires status **VERIFIED**. |

**Assisted settlement:** automatic detection may advance an order to `PAYMENT_DETECTED`, but only an operator may confirm payment and approve payout. Customer “I paid” is a hint, not confirmation.

## Entities

From design v0.3 §7. Each entity has a single owning module; cross-module coordination uses domain events (see [architecture.md](../architecture.md)).

| Entity | Role |
|--------|------|
| **Customer** | Profile, auth identity, locale, Telegram link |
| **KycCase** | KYC lifecycle; gate before orders |
| **ExchangePair** | Configured corridor (e.g. USDT↔UAH, USDT↔BTC) |
| **PaymentMethod** | UAH rails: Card, IBAN, Monobank, PrivatBank |
| **Quote** | Immutable pricing snapshot with TTL |
| **Order** | Exchange request and state machine |
| **Payment** | Inbound funds tracking for an order |
| **Payout** | Outbound funds tracking for an order |
| **LedgerEntry** | Append-only double-entry money record |
| **AuditEvent** | Immutable who/when/why for transitions and operator actions |
| **ExceptionCase** | Mismatch, risk, or failed payout requiring operator review |
| **PlatformSettings** | Admin-editable config (fees, limits, kill-switch) |
| **OperatorUser** | Admin user with RBAC role (viewer / operator / admin) |

## Related handbook

- [money.md](./money.md) — amount representation
- [quote-and-pricing.md](./quote-and-pricing.md) — fees and TTL
- [order-state-machine.md](./order-state-machine.md) — order lifecycle
- [payment-and-payout.md](./payment-and-payout.md) — pay-in/out aggregates
- [ledger.md](./ledger.md) — accounting entries
- [risk-and-limits.md](./risk-and-limits.md) — limits and exceptions
- [kyc.md](./kyc.md) — verification gate
- [audit.md](./audit.md) — audit trail
