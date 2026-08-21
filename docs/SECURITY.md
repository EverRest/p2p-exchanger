# Security handbook

Funds, secrets, AI isolation, and operator controls for the P2P exchanger. Aligns with [design v0.3](./superpowers/specs/2026-08-21-p2p-exchanger-design.md) §5–§6.

## Trust boundaries

Each process has a fixed privilege envelope. Cross-boundary calls must not expand authority (e.g. the bot never signs payouts; the worker never accepts customer session as proof of payment).

| Process | May hold / do | Must not |
|---------|---------------|----------|
| **Web / Bot** | Customer session; bot token; render UI; call public API | Wallet keys, exchange secrets, DB as source of truth |
| **API** | DB access; business rules; enqueue jobs; KYC orchestration; audit writes | Hot-wallet / Binance signing secrets |
| **Worker** | Exchange + wallet secrets; payment detect; route liquidity; execute payout | Customer session as authority; bypass operator confirm/approve |
| **AI** | Allowlisted sanitized prompt fields for explain/copy | DB, APIs, tools, raw PII |

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

## Assisted settlement

Settlement mode is **Assisted**: automation may assist detection, but money movement requires explicit operator actions.

| Step | Who | Rule |
|------|-----|------|
| Payment **detect** | Worker / providers | May run automatically (webhooks, polling, provider signals) |
| `confirm_payment` | **Operator** (RBAC) | Required before processing; not delegated to customer or AI |
| `approve_payout` | **Operator** (RBAC) | Required before funds leave platform custody |

**Customer “I paid” is not final confirm.** A client marking payment or uploading a receipt creates a signal only; order state advances to `PAYMENT_CONFIRMED` only after an authorized operator runs `confirm_payment`. Likewise, payout execution requires `approve_payout`.

Exceptions (mismatch, risk, failed payout) go to an operator queue — no automatic payout on ambiguous signals.

## AI explain / copy

MVP includes AI-generated explanations and copy. Treat the AI as an untrusted text generator behind a strict allowlist.

**Allowed**

- Feature flag controls exposure (`AI_EXPLAIN_ENABLED` or equivalent)
- Production default: **on** when an API key is present; off in dev/test unless explicitly enabled
- Prompt context built from **allowlisted** fields only (e.g. pair, side, status label, fee breakdown summaries, generic step text)
- Sanitized, non-identifying order metadata already visible to the customer in UI

**Forbidden**

- Function-calling, tools, or agent loops
- Direct DB or internal API access from the AI path
- PII in prompts: no names, card numbers, IBANs, full addresses, emails, phones, or Telegram IDs
- KYC documents or verification payloads
- Claiming payment was received unless the order status **already** reflects system- or operator-confirmed payment (e.g. `PAYMENT_CONFIRMED` or later)

The API layer builds prompts; the model never reads secrets or ledger internals beyond the allowlist.

## KYC / PII

| Rule | Detail |
|------|--------|
| Order gate | No order until customer KYC status is **VERIFIED** |
| Provider | Vendor **TBD**; MVP uses mock provider + manual admin approval |
| Storage & access | KYC data readable only by API (orchestration) and admin surfaces that need it |
| AI | **Never** send KYC documents, verification images, or raw identity fields to AI |
| Retention | Follow product/legal policy (TBD); restrict export to authorized admin roles |

PII in logs follows the logging rules below (mask, minimize).

## RBAC

Admin and operator actions use role-based access. Default roles:

| Role | Permissions |
|------|-------------|
| **viewer** | Read-only: orders, audit, dashboards, settings visibility where non-sensitive |
| **operator** | `confirm_payment`, `approve_payout`, exception queue handling, operational notes |
| **admin** | Kill-switch, platform settings, fee/config edits, operator user management, **KYC approve/reject** |

Sensitive mutations require authenticated operator identity and emit **audit** events. Step-up OTP applies to auth profile changes per product auth rules.

## Secrets

| Secret class | Location | Never |
|--------------|----------|-------|
| Binance API keys | **Worker** env / secret store | Frontend, API process, bot, logs, CI artifacts |
| Hot-wallet signing keys | **Worker** env / secret store | Frontend, API process, bot, logs, CI artifacts |
| DB credentials | API + worker (scoped) | Frontend, client bundles |
| Bot token | API / bot process | Frontend, logs |

Rotate and scope keys per environment. Domain code imports **ports**, not vendor SDKs with embedded credentials.

## Logging

- **Mask destinations** in logs: card numbers, IBANs, wallet addresses (truncate or hash per standard), phone/email where logged for support
- **No secrets**: never log API keys, wallet mnemonics, webhook signing secrets, or raw Authorization headers
- Prefer structured audit events (`AuditEvent`) for money-path actions instead of ad-hoc debug prints
- AI prompt/response logging: redact allowlist violations; do not persist full prompts containing customer-entered free text unless reviewed and scrubbed

## Kill-switch

Platform **kill-switch** (admin RBAC):

- **Blocks new orders** immediately when enabled (quote acceptance / order create returns unavailable)
- Does **not** silently auto-complete or auto-cancel in-flight orders — handling of active orders (awaiting payment, detected, processing, payout pending) is defined in [workflows/](./workflows/) and operator runbooks
- Toggle and actor recorded in audit log

## Pull request checklist

Before merging code that touches orders, payments, payouts, AI, or configuration:

- [ ] **Money path?** State transitions and ledger entries match the Assisted model; idempotent handlers; operator gates preserved
- [ ] **AI context allowlisted?** No new PII fields, tools, or DB/API calls on the explain path
- [ ] **Secrets in worker only?** No Binance or hot-wallet material in API, web, bot, or tests committed to repo
- [ ] **Audit / ledger?** Money-moving actions append audit + ledger entries; logs mask destinations and omit secrets
