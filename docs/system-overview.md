# System overview

**P2P Exchanger** is a **client ↔ platform** currency and asset exchanger (not a peer marketplace). Customers get quotes, create orders, pay in fiat or crypto, and receive payout through assisted settlement: automation may detect payments, but operators must confirm payment and approve payout before funds move. Launch corridors include **USDT ↔ UAH** and **USDT ↔ BTC**; KYC must be **VERIFIED** before any order. See [design v0.3](./superpowers/specs/2026-08-21-p2p-exchanger-design.md) for locked product decisions.

## Processes

```text
React (Vite) web          React (Vite) Admin
         │                         │
         │    Telegram bot (grammY, thin)
         │                         │
         └──────────┬──────────────┘
                    ▼
            NestJS API (CQRS)
         KYC orchestration · business rules
                    │
         PostgreSQL ◄── Ledger / Orders / KYC (source of truth)
                    │
                 Redis / BullMQ
                    ▼
         Privileged Worker
    payment detect · route liquidity · execute payout
         (Binance + hot wallet keys ONLY here)
```

## Trust boundaries

Each process has a fixed privilege envelope. Cross-boundary calls must not expand authority — for example, the bot never signs payouts; the worker never treats a customer session as proof of payment.

| Process | May hold / do | Must not |
|---------|---------------|----------|
| **Web / Bot** | Customer session; bot token; render UI; call public API | Wallet keys, exchange secrets, DB as source of truth |
| **API** | DB access; business rules; enqueue jobs; KYC orchestration; audit writes | Hot-wallet / Binance signing secrets |
| **Worker** | Exchange + wallet secrets; payment detect; route liquidity; execute payout | Customer session as authority; bypass operator confirm/approve |
| **AI** | Allowlisted sanitized prompt fields for explain/copy | DB, APIs, tools, raw PII |

Full rules — Assisted settlement, AI isolation, RBAC, secrets, logging, kill-switch — are in **[SECURITY.md](./SECURITY.md)**.

## Channels

| Channel | Auth | API surface |
|---------|------|-------------|
| **Web** | Customer session (email or phone + OTP) | Public REST API — quotes, orders, KYC status, explain |
| **Telegram** | Linked customer via bot | **Same public API** as web; grammY bot is a thin client (no business rules beyond API calls) |
| **Admin** | **Separate** operator auth (RBAC: viewer / operator / admin) | Admin API — confirm payment, approve payout, exceptions, settings, audit |

Web and Telegram share domain logic and order state through the API. Admin uses distinct credentials and permissions; operator actions (`confirm_payment`, `approve_payout`) are API commands, not silent automation.

## Related docs

- [architecture.md](./architecture.md) — Nest modules, CQRS, queues, provider ports
- [SECURITY.md](./SECURITY.md) — trust boundaries and money-path controls
- [superpowers/specs/2026-08-21-p2p-exchanger-design.md](./superpowers/specs/2026-08-21-p2p-exchanger-design.md) — design v0.3
