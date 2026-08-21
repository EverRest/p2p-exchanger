# P2P Exchanger — Design (v0.3)

Date: 2026-08-21  
Status: approved (2026-08-21)  
Supersedes: v0.2  
Sources: brainstorm (prep-for-implementation), exchanger SoT only (`p2p-docs` ignored)

## 1. Problem

Build a **client ↔ platform** currency/asset exchanger (not a peer marketplace) supporting fiat↔crypto, crypto↔crypto, and (later) fiat↔fiat, with **Assisted** settlement, mandatory operator confirm/approve for money movement, strict KYC before orders, and hard isolation of secrets and AI.

## 2. Goals

- Generic order/quote/ledger engine for pair types A/B/C  
- Launch: **USDT ↔ UAH**, **USDT ↔ BTC**; USDT TRC20+ERC20; BTC mainnet  
- UAH methods: **Card, IBAN, Monobank, PrivatBank**  
- Liquidity: Binance primary, hot wallet fallback (ports)  
- Web + **grammY** Telegram + Admin; same API/domain  
- KYC VERIFIED before any order (`KycProvider`; vendor TBD; MVP mock + admin manual)  
- Auth: email **or** phone; step-up OTP on sensitive changes  
- Client UI **UK + EN**; locale from Accept-Language / Telegram `language_code`, fallback **uk**  
- AI explain/copy **in MVP** (feature flag; prod default **on** if API key present); no tools/DB/PII  
- Admin RBAC: **viewer / operator / admin**  
- transl8.ai engineering DNA; **Node 22**  
- **Full handbook first**, then sync specs, then feature code  

## 3. Non-goals (handbook + early MVP)

Microservices/K8s, many venues, mobile apps, peer marketplace, AI with tools or data access, touching **`p2p-docs`**, legal opinions, production key ceremony, complete OpenAPI YAML, fixed min/max order amounts (config placeholders only).

## 4. Locked decisions

| Topic | Decision |
|-------|----------|
| SoT repo | **`p2p-exchanger` only**; do not update `p2p-docs` |
| Docs language | English only |
| Product docs | Rewrite `docs/product/*` from this design |
| Prep approach | **Handbook → sync specs/001 → code** |
| Settlement | **Assisted**: detect may auto; **confirm payment** + **approve payout** = operator only |
| Quote TTL | **120s** |
| Payment window | **30 min** |
| UAH methods | Card, IBAN, Monobank, PrivatBank |
| Min/max amounts | Config placeholders (no fixed numbers in docs) |
| Fee defaults | See §4.1 |
| KYC | Before order; vendor **TBD**; mock + manual admin approve |
| Auth | Email or phone + step-up OTP |
| i18n | UK + EN; detect locale; fallback **uk** |
| AI explain | In MVP; flag; prod **on** if key; allowlisted context only |
| RBAC | viewer / operator / admin |
| Node | **22** |
| Bot | **grammY** |
| `PAYOUT_APPROVED` | Order-visible status |

### 4.1 Fee defaults (config; admin-editable)

| Corridor | Spread | Service fee | Notes |
|----------|--------|-------------|--------|
| USDT ↔ UAH | **1.0%** | **0.2%** | Network fees for USDT via `network_fee_usdt_trc20` / `_erc20` placeholders |
| USDT ↔ BTC | **0.8%** | **0.2%** | BTC network fee from provider estimate; snapshot on quote |

| UAH payment fee | Rate |
|-----------------|------|
| Card | **0.5%** |
| IBAN | **0%** |
| Monobank | **0%** |
| PrivatBank | **0%** |

**Minimum absolute service fee:** equivalent of **10 UAH** on small orders (config).

## 5. Architecture

```text
React (Vite) web + Admin     Telegram bot (grammY, thin)
         │                         │
         └──────────┬──────────────┘
                    ▼
            NestJS API (CQRS) + KYC orchestration
                    │
         PostgreSQL ◄── Ledger / Orders / KYC (truth)
                    │
                 Redis/BullMQ
                    ▼
         Privileged Worker
         (Binance + hot wallet keys ONLY)
```

| Process | May hold | Must not |
|---------|----------|----------|
| Web / Bot | Session / bot token | Wallet keys, exchange secrets, DB as SoT |
| API | DB, rules, enqueue, KYC orchestration | Hot-wallet / Binance signing secrets |
| Worker | Exchange + wallet secrets; detect/route/payout | Customer session as authority |
| AI | Allowlisted sanitized prompt fields | DB, APIs, tools, raw PII |

## 6. Security (summary → `docs/SECURITY.md`)

- Trust boundaries §5  
- AI: no function-calling; allowlist only; never invent payment confirmation  
- Assisted: “I paid” ≠ final confirm  
- State machine + ledger + audit + idempotency  
- Kill-switch; RBAC; masked logs; rate limits on auth/OTP/explain  

## 7. Domain & Assisted lifecycle

**Entities:** Customer, KycCase, ExchangePair, PaymentMethod, Quote, Order, Payment, Payout, LedgerEntry, AuditEvent, ExceptionCase, PlatformSettings, OperatorUser.

```text
CREATED → AWAITING_PAYMENT → PAYMENT_DETECTED
  → PAYMENT_CONFIRMED ★operator → PROCESSING → PAYOUT_PENDING
  → PAYOUT_APPROVED ★operator → COMPLETED
```

Terminals: `EXPIRED | CANCELLED | REFUNDED | FAILED`  
Exceptions: mismatch/risk/failed payout → queue (no auto payout).

**Order create gates:** unexpired quote + KYC VERIFIED + kill-switch off + limits OK.

## 8. Providers

`RateProvider`, `ExchangeProvider`, `PaymentProvider`, `PayoutProvider`, `KycProvider` (mock + TBD real). Domain never imports SDKs.

## 9. Stack

| Layer | Choice |
|-------|--------|
| Frontend | React + Vite + TS + Tailwind + TanStack Query + i18n (uk/en) |
| API | NestJS + CQRS + Prisma + PostgreSQL |
| Worker | Nest + BullMQ |
| Bot | grammY → API |
| Runtime | Node **22** |

## 10. Handbook map

Unchanged from v0.2 file tree under `docs/` (SECURITY, system-overview, architecture, domain/*, workflows/*, product rewrite, ADRs 0002–0005). Sync `specs/001-exchange-platform/*`, root README, AGENTS.md.

## 11. Prep execution order (Approach 1)

```text
H0  This design v0.3 committed
H1  SECURITY + system-overview + architecture
H2  domain/* + workflows/*
H3  Rewrite docs/product/* (EN)
H4  ADRs 0002–0005 (+ sync 0001)
H5  Sync SCOPE.md + specs/001/*
H6  docs/README.md + root README + AGENTS.md
H7  Handbook DoD green → writing-plans / feature tasks.md
```

### Spec sync deltas (H5)

- Assisted + KYC gate + PAYOUT_APPROVED  
- Remove SC “≥95% without operator”; use operator-attributed confirms/approves + idempotency + explain safety  
- Fees §4.1; i18n; RBAC; Node 22; grammY  
- KYC endpoints + admin confirm/approve + explain in contracts  
- tasks.md: KYC foundation; Assisted US1; Phase 1 scaffold marked realistically  

## 12. Delivery after handbook

1. Foundation (Money, state machine, ledger, mocks, auth, KYC port, admin RBAC shell)  
2. US1 USDT↔UAH Assisted on web (+ explain with flag)  
3. US2 USDT↔BTC  
4. Telegram parity  
5. Exceptions polish  
6. Fiat↔fiat config  
7. Real Binance / hot wallet / KYC vendor adapter  

## 13. Handbook Definition of Done

- [ ] No contradictions: product ↔ SCOPE ↔ specs/001 ↔ this design  
- [ ] SECURITY covers AI, secrets, Assisted, RBAC, KYC  
- [ ] State machine + workflows documented  
- [ ] Fee defaults + i18n + Node 22 + grammY documented  
- [ ] `docs/product/*` English rewrite complete  
- [ ] Indexes point to handbook; `p2p-docs` not SoT  
- [ ] tasks.md ready for Assisted implementation  

**Out of prep:** feature code, KYC vendor pick, real keys, min/max numbers, `p2p-docs` changes.

## 14. Open items (non-blocking)

- BTC/USDT min/max numeric values  
- KYC vendor for real adapter  
- Legal/licensing thresholds  
- Exact median operator SLA numbers  

## 15. Next after user approves this file

1. Invoke **writing-plans** for H1–H7 handbook tasks  
2. Execute handbook + specs sync  
3. Then feature implementation from `tasks.md`  
