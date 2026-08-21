> Aligned to design v0.3. Supersedes earlier brainstorm notes.

# MVP scope

## Launch corridors

| Direction | Assets / networks |
|-----------|-------------------|
| Fiat ↔ crypto | **USDT ↔ UAH** (USDT TRC20 + ERC20) |
| Crypto ↔ crypto | **USDT ↔ BTC** (BTC mainnet) |

Liquidity: Binance primary, hot wallet fallback (via provider ports). Fiat↔fiat is post-MVP (config only later).

## UAH payment methods (4)

Card, IBAN, Monobank, PrivatBank — all four at launch for UAH legs.

## Assisted lifecycle

```text
CREATED → AWAITING_PAYMENT → PAYMENT_DETECTED
  → PAYMENT_CONFIRMED ★operator → PROCESSING → PAYOUT_PENDING
  → PAYOUT_APPROVED ★operator → COMPLETED
```

Terminals: `EXPIRED | CANCELLED | REFUNDED | FAILED`. Exceptions (mismatch, risk, failed payout) queue for operators — no auto payout.

**Order gates:** unexpired quote (TTL **120s**), payment window **30 min**, KYC **VERIFIED**, kill-switch off, limits OK.

## KYC gate

Mandatory before first order. MVP: mock `KycProvider` + admin manual approve/reject. Real vendor TBD.

## Surfaces

| Surface | Role |
|---------|------|
| Web | Customer exchange + account (UK + EN) |
| Telegram | Customer parity via **grammY** → same API |
| Admin | Orders, KYC, settings, operator actions |

Auth: email **or** phone; step-up OTP on sensitive changes.

## Admin RBAC

Roles: **viewer** (read), **operator** (`confirm_payment`, `approve_payout`), **admin** (settings, KYC, users). All money-moving actions audited.

## AI explain (MVP)

Feature-flagged explain/copy layer — **not** an agent with tools. Production default **on** when API key present. Allowlisted context only; see [SECURITY.md](../SECURITY.md).

## Non-goals (MVP)

Microservices/K8s, mobile apps, peer marketplace, AI with DB/API/tools access, many venues or payment methods, production key ceremony, fixed min/max amounts (config placeholders only), touching `p2p-docs` as source of truth.
