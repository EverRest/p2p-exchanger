# Quote and pricing

A **Quote** is an immutable snapshot of exchange terms. Once created, its rates and fees do not change. Customers bind an order to a specific quote id.

## Immutability and TTL

- Quotes are **read-only** after persistence.
- **TTL: 120 seconds** from creation. Expired quotes cannot create orders.
- Order creation validates: quote exists, not expired, pair/method still allowed, customer KYC **VERIFIED**, kill-switch off, limits OK.

## Fee pipeline

Pricing runs in a fixed pipeline. Each stage produces intermediate values stored on the quote for audit and display.

```text
market rate  →  spread  →  corridor + payment fees  →  final customer rate / amounts
```

| Stage | Description |
|-------|-------------|
| **Market** | Mid or reference rate from `RateProvider` at quote time |
| **Spread** | Platform spread applied to the corridor |
| **Fees** | Service fee, payment-method fee, network fee placeholders |
| **Final** | Customer-facing send/receive amounts and effective rate |

Network fees for USDT use config placeholders (`network_fee_usdt_trc20`, `network_fee_usdt_erc20`). BTC network fee comes from provider estimate and is snapshotted on the quote.

## Default fee configuration

Admin-editable defaults (from design v0.3 §4.1). Min/max order amounts are **config placeholders only** — no fixed numbers in handbook.

### Corridor fees

| Corridor | Spread | Service fee |
|----------|--------|-------------|
| USDT ↔ UAH | **1.0%** | **0.2%** |
| USDT ↔ BTC | **0.8%** | **0.2%** |

### UAH payment-method fees

| Method | Fee |
|--------|-----|
| Card | **0.5%** |
| IBAN | **0%** |
| Monobank | **0%** |
| PrivatBank | **0%** |

### Minimum service fee

**Minimum absolute service fee:** equivalent of **10 UAH** on small orders (config). Applied after percentage service fee calculation when the computed fee would otherwise be below the floor.

## Min / max amounts

Minimum and maximum order sizes per pair and method are loaded from **PlatformSettings** at quote time. Handbook does not fix numeric min/max values — they remain config placeholders until product sets them.

## Quote contents (conceptual)

Each quote records at minimum:

- `exchangePairId`, `paymentMethodId` (when applicable)
- Input amount + currency, output amount + currency
- Market rate, spread %, service fee %, payment fee %, network fee snapshot
- `expiresAt` (createdAt + **120s**)
- Idempotency key for quote creation (optional client-supplied)

Orders reference `quoteId` and reject stale or mismatched quotes.
