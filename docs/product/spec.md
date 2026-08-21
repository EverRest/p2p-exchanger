> Aligned to design v0.3. Supersedes earlier brainstorm notes.

# Product specification (summary)

Client ↔ platform currency exchanger with **Assisted** settlement, mandatory KYC before orders, web + Telegram + admin on a shared NestJS API (**Node 22**, **grammY** bot).

**Detailed requirements:** [specs/001-exchange-platform/spec.md](../../specs/001-exchange-platform/spec.md)  
**Approved design:** [design v0.3](../superpowers/specs/2026-08-21-p2p-exchanger-design.md)  
**Security:** [SECURITY.md](../SECURITY.md)

## Locked decisions

| Topic | Decision |
|-------|----------|
| Product model | Client ↔ platform; **not** peer marketplace |
| SoT repo | `p2p-exchanger` only |
| Prep approach | Handbook → sync specs/001 → code |
| Settlement | **Assisted** — operator `confirm_payment` + `approve_payout` |
| Quote TTL | 120s |
| Payment window | 30 min |
| Launch corridors | USDT ↔ UAH, USDT ↔ BTC |
| UAH methods | Card, IBAN, Monobank, PrivatBank |
| KYC | Before order; mock + admin manual; vendor TBD |
| Auth | Email or phone + step-up OTP |
| i18n | UK + EN; fallback **uk** |
| AI | Explain/copy only; feature flag; no tools/DB/PII |
| RBAC | viewer / operator / admin |
| Runtime | **Node 22** |
| Bot | **grammY** |
| Order status | **PAYOUT_APPROVED** visible to customer |
| Frontend | React + Vite + Tailwind + TanStack Query |
| API | NestJS + CQRS + Prisma + PostgreSQL |
| Worker | Nest + BullMQ; exchange/wallet secrets here only |
| Min/max amounts | Config placeholders (no fixed numbers in docs) |

Fee defaults: see design v0.3 §4.1 (admin-editable).
