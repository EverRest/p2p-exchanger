# Money

Money values in the domain **must never use JavaScript `number`**. Floating-point arithmetic causes rounding errors that are unacceptable for financial operations.

## Representation

Use one of these patterns consistently per layer:

| Layer | Representation |
|-------|------------------|
| **Domain / API JSON** | Decimal string (e.g. `"1234.567890"`) plus ISO 4217 **currency** code (e.g. `UAH`, `USDT`, `BTC`) |
| **Persistence (optional)** | Minor units (integer) plus currency — e.g. kopecks for UAH, satoshis for BTC — when the storage layer requires integers |

Rules:

1. **Never** parse money amounts with `parseFloat` or `Number()` for business logic.
2. Use a dedicated decimal library (e.g. `decimal.js`, `big.js`) or integer minor-unit math end-to-end.
3. Every arithmetic operation requires **matching currency**. Adding UAH to USDT is forbidden unless an explicit conversion step (with its own quote snapshot) is applied.
4. Comparisons (`<`, `>`, `=`) must use the same representation and scale rules as defined for that currency (e.g. UAH: 2 decimal places; BTC: 8; USDT: configurable per network config).
5. Display formatting (locale, symbols) belongs in the presentation layer — not in domain calculations.

## Currency match on arithmetic

```text
amountA (UAH) + amountB (UAH)     → OK
amountA (UAH) + amountB (USDT)    → FORBIDDEN without conversion
fee (UAH) on order (UAH leg)      → OK
network fee (USDT) on USDT leg    → OK
```

When a quote spans two legs (e.g. USDT ↔ UAH), each leg carries its own currency. Cross-leg totals are expressed as separate amounts, not merged into one number.

## Fees and minimums

Fee calculations produce decimal strings in the **fee currency** of that leg. The minimum absolute service fee (equivalent of **10 UAH** on small orders) is applied in config — see [quote-and-pricing.md](./quote-and-pricing.md).

## Ledger alignment

[Ledger entries](./ledger.md) reference the same decimal-string + currency pairs. Debits and credits for a single journal event must balance in the relevant currency(ies).
