# Ledger

The ledger is the financial source of truth for platform balances and order-level money movement. Entries are **append-only** — no updates or deletes in normal operation; corrections use reversing entries.

## Double-entry intent

Every money-affecting business event produces balanced journal lines:

- Each event has at least one **debit** and one **credit** in the same currency (or explicit multi-currency legs with documented conversion reference).
- Amounts use [money.md](./money.md) rules (decimal string + currency, never JS `number`).
- Imbalanced journals are rejected at write time.

Conceptual accounts (names illustrative):

| Account type | Examples |
|--------------|----------|
| Customer liability | Customer UAH balance, customer USDT balance |
| Platform revenue | Spread income, service fee income, payment fee income |
| Suspense / in-transit | Awaiting confirm, payout pending |
| External / clearing | Bank, on-chain wallet clearing |

Exact chart of accounts is implementation detail; handbook requires **balanced double-entry** per event.

## When entries are written

Ledger entries are created **with** money-affecting order transitions — not lazily or in batch without audit linkage.

| Trigger | Typical entries |
|---------|-----------------|
| Order created | Optional hold/reservation per product policy |
| `PAYMENT_CONFIRMED` | Debit clearing/suspense; credit customer liability or recognize inbound |
| Fee recognition | Credit fee revenue accounts per quote snapshot |
| `PAYOUT_APPROVED` / execution | Debit customer liability; credit clearing/outbound |
| Refund / failure | Reversing or compensating entries linked to original journal |

Each `LedgerEntry` references:

- `orderId` (and optionally `paymentId`, `payoutId`)
- Journal id grouping debits/credits
- Amount, currency, account code
- Causation id (domain event or command id)
- Timestamp (UTC)

## Immutability

- No `UPDATE` on posted entries.
- Corrections: new reversing entries + explanatory [audit event](./audit.md).
- Read models for reporting may project from the append-only log.

## Consistency with Assisted flow

Because operator **confirm** and **approve** gate ledger recognition of final inbound/outbound settlement, ledger writes for settlement align with `PAYMENT_CONFIRMED` and post-approval payout execution — not with mere `PAYMENT_DETECTED` or customer “I paid”.
