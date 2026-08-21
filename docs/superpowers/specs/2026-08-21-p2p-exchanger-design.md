# P2P Exchanger — Design (v0.1)

Date: 2026-08-21  
Status: approved (2026-08-21)  
Sources: `docs/SCOPE.md`, `docs/DEVELOPMENT-DIRECTION.md`, `docs/product/*`, transl8.ai practices

## 1. Problem

Build a **client ↔ platform** currency/asset exchanger (not a peer marketplace) that can eventually support fiat↔crypto, crypto↔crypto, and fiat↔fiat, with a mostly automatic settlement path and operators only on exceptions.

## 2. Goals

- One generic order/quote/ledger engine for all pair types  
- Launch corridors: **USDT ↔ UAH** and **USDT ↔ BTC**  
- Rails: USDT **TRC20 + ERC20**; UAH **2–3** card/IBAN methods (config-driven)  
- Liquidity: **Binance primary**, **hot wallet fallback** via provider interface  
- Channels: **Web + Telegram** (same API/domain) + **Admin**  
- Engineering DNA from **transl8.ai**: Nest modular monolith, CQRS/DDD, separate BullMQ worker, providers, docs/ADR, TDD  

## 3. Non-goals (v1)

Microservices/K8s, many venues, mobile apps, peer-offer matching, AI that reads privileged order data or moves funds, full multi-tenant SaaS billing.

## 4. Architecture

```text
React (Vite) web + Admin     Telegram bot (thin)
         │                         │
         └──────────┬──────────────┘
                    ▼
            NestJS API (CQRS)
                    │
         PostgreSQL ◄── Ledger / Orders (truth)
                    │
                 Redis/BullMQ
                    ▼
         Privileged Worker
         (Binance + hot wallet keys ONLY)
```

| Process | May hold |
|---------|----------|
| Web / Bot | Session/bot token only |
| API | DB credentials, business rules, enqueue jobs |
| Worker | Exchange API secrets, hot-wallet keys, execute payouts |

Cross-module communication: **domain events** (transl8 pattern). Long work **never** on HTTP thread.

## 5. Domain sketch

**Aggregates / entities:** Customer, Quote (immutable snapshot), Order, Payment, Payout, LedgerEntry, ExchangeRate, PaymentMethod, AuditLog, OperatorAction / Dispute.

**Order lifecycle (happy path):**  
`CREATED → AWAITING_PAYMENT → PAYMENT_DETECTED → PAYMENT_CONFIRMED → PROCESSING → PAYOUT_PENDING → COMPLETED`  

**Terminals:** `EXPIRED | CANCELLED | REFUNDED | FAILED` (+ dispute/exception side-path to human queue).

Transitions only via state machine; every money-affecting transition writes **ledger + audit** idempotently.

**Pairs:** `input_asset` / `output_asset` (+ network where applicable). Pair types A/B/C share the same engine; C enabled later via config.

## 6. Provider layer

| Port | Launch adapters |
|------|-----------------|
| `RateProvider` | Binance market (and FX stub for future fiat↔fiat) |
| `ExchangeProvider` | Binance, HotWallet |
| `PaymentProvider` | Manual/bank detect stubs → real rails; crypto deposit watchers |
| `PayoutProvider` | Bank payout, crypto withdrawal via ExchangeProvider |

Failover policy configurable (e.g. Binance → hot wallet). Domain never imports SDKs.

## 7. Automation & risk

- Auto: quote, order create, payment detection (when provider supports), confirm, process, payout, notify  
- Human: mismatches, risk flags, kill-switch pauses, disputes, manual overrides  
- Required: idempotency keys, kill-switch, limits, RBAC on admin  

## 8. AI

Explain/copy layer only: sanitized UI context in prompt; no DB/API tools; must not invent payment confirmation.

## 9. Stack (locked)

| Layer | Choice |
|-------|--------|
| Frontend | React + Vite + TS + Tailwind + TanStack Query (transl8-style `features/`) |
| API | NestJS + CQRS + Prisma + PostgreSQL |
| Worker | Separate Nest context + BullMQ |
| Bot | Telegram → API |
| DX | Makefile, Docker Compose, ADRs, AGENTS.md, Spec Kit for feature specs |

## 10. Repo target

```text
p2p-exchanger/
├── AGENTS.md, Makefile, docker-compose.yml, VERSION
├── backend/   # API + worker.main + prisma
├── frontend/  # Vite React
├── bot/
├── docs/      # system-overview, domain, workflows, adr
├── specs/     # Spec Kit feature specs
└── .specify/
```

## 11. Delivery phases

1. Foundation (repo like transl8, ledger, state machine, providers stubs, admin shell)  
2. Launch pairs + rails + Binance/hot wallet + auto path + Telegram  
3. Fiat↔fiat corridor  
4. Optional order-aware AI later  

## 12. Spec Kit next

1. `/speckit-constitution` from `SPEC-KIT-GUIDE.md` + this design  
2. `/speckit-specify` covering A/B/C with launch focus A+B  
3. `/speckit-plan` locking transl8-aligned stack  
4. tasks → implement  

## Open items (ops, not blockers for architecture)

- Exact UAH banks/methods list  
- BTC address validation rules / min amounts  
- Legal entity / KYC thresholds per corridor  
