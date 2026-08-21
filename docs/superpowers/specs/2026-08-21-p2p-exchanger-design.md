# P2P Exchanger — Design (v0.2)

Date: 2026-08-21  
Status: brainstorm sections approved; awaiting user review of this written spec  
Supersedes: v0.1 (mostly-automatic settlement; 2–3 UAH methods; KYC deferred)  
Sources: brainstorm decisions, `docs/SCOPE.md` (to sync), Spec Kit `specs/001-exchange-platform/`

## 1. Problem

Build a **client ↔ platform** currency/asset exchanger (not a peer marketplace) supporting fiat↔crypto, crypto↔crypto, and (later) fiat↔fiat, with **Assisted** settlement: automation where safe, **mandatory human confirmation** for payment confirm and payout approve, and strict isolation of secrets and AI.

## 2. Goals

- One generic order/quote/ledger engine for all pair types  
- Launch corridors: **USDT ↔ UAH** and **USDT ↔ BTC** (both directions)  
- Rails: USDT **TRC20 + ERC20**; BTC mainnet; UAH methods **Card, IBAN, Monobank, PrivatBank** (config-driven)  
- Liquidity: **Binance primary**, **hot wallet fallback** via provider ports  
- Channels: **Web + Telegram (grammY)** → same API/domain + **Admin**  
- **KYC VERIFIED required before any order** (`KycProvider` port + mock + one real adapter later)  
- Auth: **email or phone** (verified); step-up OTP on sensitive changes; Telegram links to same Customer  
- Engineering DNA from **transl8.ai**: Nest modular monolith, CQRS/DDD, privileged BullMQ worker, providers, docs/ADR, TDD  
- **Full handbook first** (Approach 3): complete English documentation before feature implementation  

## 3. Non-goals (v1 / handbook phase)

Microservices/K8s, many venues, mobile apps, peer-offer matching, AI with tools or DB/API access, full multi-tenant SaaS billing, legal opinions, production key-ceremony runbooks, complete OpenAPI YAML (stubs OK).

## 4. Locked product decisions (brainstorm)

| Topic | Decision |
|-------|----------|
| Documentation language | **English only** |
| Product docs | **Rewrite** `docs/product/*` to match this design (not archive-only) |
| Documentation delivery | **Full handbook** before feature code |
| Settlement posture | **Assisted**: detection may be automatic; **confirm payment** and **approve payout** always require operator (RBAC) |
| Quote TTL | **120 seconds** |
| Order payment window | **30 minutes** (`AWAITING_PAYMENT` → else `EXPIRED`) |
| UAH methods | **Card + IBAN + Monobank + PrivatBank** |
| KYC | **Strict before any order**; port `KycProvider` + mock + one real adapter (vendor TBD) |
| Web auth | Email **or** phone; step-up OTP for payout destination change, Telegram link, sensitive profile |
| Node | **22** (align plan/CI/docs with `.nvmrc`) |
| Telegram library | **grammY** |
| AI | Explain/copy only; sanitized allowlisted context; no tools; no PII/DB; never invent payment confirmation |
| `PAYOUT_APPROVED` | **Order-visible status** (not only payout sub-state) |

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

| Process | May hold | Must not hold |
|---------|----------|----------------|
| Web / Bot | Session / bot token / linked API tokens | DB as SoT, wallet keys, exchange secrets |
| API | DB creds, business rules, enqueue jobs, KYC flow | Hot-wallet keys, Binance signing secrets |
| Worker | Exchange + wallet secrets; detect/route/payout jobs | Customer UI session as authority |
| AI layer | Allowlisted sanitized prompt fields only | DB, APIs, tools, raw PII, balances |

Cross-module: **domain events**. Long work **never** on HTTP thread.

## 6. Security (handbook core)

See planned `docs/SECURITY.md`. Summary:

- Trust boundaries as in §5  
- AI: no function-calling; allowlisted context only; feature-flagged  
- Funds: state machine only; ledger + audit with money transitions; idempotency on detect/execute  
- Assisted: customer “I paid” may start detect — **not** final confirm  
- Kill-switch; RBAC on admin actions; masked destinations in logs; rate limits on auth/OTP/explain  

## 7. Domain & Assisted lifecycle

**Entities:** Customer, KycCase, ExchangePair, PaymentMethod, Quote, Order, Payment, Payout, LedgerEntry, AuditEvent, ExceptionCase, PlatformSettings, OperatorUser.

**Happy path (Assisted):**

```text
CREATED
  → AWAITING_PAYMENT
  → PAYMENT_DETECTED          (system/mock/watcher)
  → PAYMENT_CONFIRMED         ★ operator only
  → PROCESSING
  → PAYOUT_PENDING
  → PAYOUT_APPROVED           ★ operator only (order-visible)
  → COMPLETED                 (after worker execute success)
```

**Terminals:** `EXPIRED | CANCELLED | REFUNDED | FAILED`  
**Side-path:** mismatch / risk / payout failure → exception queue (no auto payout).

**Gates on order create:** valid unexpired quote + KYC VERIFIED + kill-switch off + limits OK.

**Pricing:** market → spread → fees → final amounts; all stored on immutable Quote and copied to Order.

## 8. Provider layer

| Port | Launch adapters |
|------|-----------------|
| `RateProvider` | Binance (mock for early e2e) |
| `ExchangeProvider` | Binance, HotWallet |
| `PaymentProvider` | UAH rails + crypto deposit watchers (mock first) |
| `PayoutProvider` | Bank / crypto via exchange or wallet |
| `KycProvider` | Mock + one real adapter (vendor TBD) |

Domain never imports vendor SDKs.

## 9. Stack (locked)

| Layer | Choice |
|-------|--------|
| Frontend | React + Vite + TS + Tailwind + TanStack Query |
| API | NestJS + CQRS + Prisma + PostgreSQL |
| Worker | Separate Nest context + BullMQ |
| Bot | **grammY** → API only |
| Runtime | **Node 22** |
| DX | Makefile, Docker Compose, ADRs, AGENTS.md, Spec Kit |

## 10. Handbook documentation map (Approach 3)

```text
docs/
├── README.md                 # reading order
├── SCOPE.md                  # sync to this design
├── SECURITY.md               # NEW
├── system-overview.md        # NEW
├── architecture.md           # NEW
├── DEVELOPMENT-DIRECTION.md  # minor sync
├── coding-standards.md / patterns.md / ci.md / deploy/
├── product/                  # REWRITE all EN
│   ├── idea.md, mvp.md, design.md, roadmap.md, spec.md
├── domain/                   # NEW
│   ├── overview.md, money.md, quote-and-pricing.md
│   ├── order-state-machine.md, payment-and-payout.md
│   ├── ledger.md, risk-and-limits.md, kyc.md, audit.md
├── workflows/                # NEW
│   ├── customer-exchange.md, operator-exception.md
│   ├── kyc-onboarding.md, kill-switch.md
└── adr/
    ├── 0001 (sync)
    ├── 0002-assisted-settlement.md
    ├── 0003-kyc-before-orders.md
    ├── 0004-privilege-separation-worker.md
    └── 0005-ai-explain-only.md
```

Also sync: `specs/001-exchange-platform/*`, root `README.md`, `AGENTS.md`.

**Write order:** SECURITY + system-overview → domain → workflows → product rewrite → ADRs → SCOPE/design already here → specs/001 → indexes.

**Placeholders OK:** vendor KYC name, BTC exact min amounts, full OpenAPI file, production key ceremony.

## 11. Delivery phases

0. **Handbook** (this design) — DoD below; **no feature domain code until Done**  
1. Foundation (Money, state machine, ledger, providers mocks, auth, KYC port, admin shell)  
2. US1 USDT↔UAH Assisted path on web  
3. US2 USDT↔BTC  
4. Telegram parity + explain layer  
5. Operator exceptions polish  
6. Fiat↔fiat config enablement  
7. Real Binance / hot wallet / KYC adapters  

## 12. Handbook Definition of Done

- [ ] No contradictions between product, SCOPE, and `specs/001`  
- [ ] Security / AI / privilege rules unambiguous  
- [ ] Assisted path + state machine documented  
- [ ] KYC-before-order + `KycProvider` documented  
- [ ] Launch methods, corridors, TTL, payment window, auth, bot, Node documented  
- [ ] `AGENTS.md` / `docs/README.md` point at handbook reading order  
- [ ] `docs/product/*` rewritten in English to match this design  

After DoD → implementation plan (`writing-plans`) → execute `tasks.md`.

## 13. Success criteria adjustments (for spec sync)

Replace “≥95% completed without operator” with Assisted-appropriate metrics, e.g.:

- 100% of payment confirms and payout approves are operator-attributed in audit  
- Zero double-payout in idempotency tests  
- Median operator confirm/approve latency targets (ops-defined)  
- Explain/help: zero false “payment received” claims in review samples  

## 14. Open items (do not block handbook)

- Exact BTC/USDT min/max amounts and address validation rule details  
- KYC vendor selection for the real adapter  
- Legal entity / licensing thresholds (policy plugs into KYC/limits)  
- Fee/spread numeric defaults per corridor  

## 15. Next step after user reviews this file

1. Spec self-review complete (this document)  
2. User approves this file  
3. Invoke **writing-plans** for handbook implementation tasks  
4. Execute handbook write + specs sync  
5. Only then start feature code from `tasks.md`  
