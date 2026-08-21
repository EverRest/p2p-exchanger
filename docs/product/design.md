> Aligned to design v0.3. Supersedes earlier brainstorm notes.

# Product design (UX)

## Principles

- **One task per screen** — amount → rate → pay → wait → done.
- **Truth from backend** — UI and copy reflect order state; never invent payment confirmation.
- **UK + EN** — locale from Accept-Language / Telegram `language_code`; fallback **uk**.

Optional reference: a **Gloss-like** clean, mobile-first feel (premium consumer fintech) — inspiration only, not a mandated design system.

## Quote screen

```text
┌─────────────────────────────┐
│  You send    500 USDT       │
│         ↓                   │
│  You receive  ≈ 20 345 UAH  │
│  Rate 1 USDT = 40.69 UAH    │
│  Fee breakdown (expand)     │
│  ⏱ Locked 120s              │
│       [ Continue ]            │
└─────────────────────────────┘
```

Inline “Why this fee?” triggers **AI explain** (copy only — fee components from allowlisted quote fields).

## Payment screen

```text
Send exactly 500 USDT · TRC20
Address: T…xxxx  [ Copy ]
Before sending: confirm network is TRC20.
[ I paid ]   ← signal only, not final confirm

Status: AWAITING_PAYMENT → PAYMENT_DETECTED (auto may apply)
```

Microcopy for “How do I send USDT?” is AI-generated from topic templates — no wallet balances or PII in prompts.

## Status / waiting

Show machine state in human labels. When operator confirms:

```text
✓ Payment confirmed
● Payout pending approval   ← PAYOUT_APPROVED visible to customer when set
○ Completed
```

“Explain this order” button: AI summarizes allowlisted status + fee snapshot — never claims funds received unless state is `PAYMENT_CONFIRMED` or later.

## AI = copy layer only

Not an agent. No function-calling, tools, or database access.

| AI may | AI must not |
|--------|-------------|
| Explain fees, steps, network choice | Read orders/DB directly |
| Localize tone (UK/EN) | Move money or confirm payments |
| Answer FAQ from allowlisted context | See KYC docs or raw PII |

Full rules: [SECURITY.md](../SECURITY.md) § AI explain / copy.

## Telegram (grammY)

Same flows as web: quote → order → payment instructions → status updates. Thin bot — all business logic in NestJS API on **Node 22**.
