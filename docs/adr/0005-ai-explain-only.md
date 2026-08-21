# ADR 0005: AI explain-only (no tools, no PII)

## Status

Accepted — 2026-08-21

## Context

MVP includes AI-generated explanations and UI copy to help customers understand fees, status, and next steps. An agent with tools or database access would violate trust boundaries and could leak PII or invent payment confirmation. AI must stay a sandboxed text generator.

## Decision

1. Ship **AI explain/copy in MVP**, controlled by a feature flag (e.g. `AI_EXPLAIN_ENABLED`).
2. Production default: **on** when an API key is present; off in dev/test unless explicitly enabled.
3. Prompts are built from an **allowlist** of sanitized fields only (pair, side, status labels, fee summaries, generic step text already visible in UI).
4. **Forbidden:** function-calling, tools, agent loops, direct DB or internal API access from the AI path.
5. **Forbidden in prompts:** PII (names, card numbers, IBANs, addresses, email, phone, Telegram IDs), KYC documents, verification images, secrets, ledger internals beyond the allowlist.
6. The model **must not** claim payment was received unless order status **already** reflects system- or operator-confirmed payment (e.g. `PAYMENT_CONFIRMED` or later).
7. The API layer owns prompt construction and response validation; the model never reads raw customer free-text unless scrubbed and reviewed for allowlist compliance.

## Consequences

- Explain endpoints are rate-limited; logging redacts allowlist violations.
- New UI fields proposed for AI context require security review before allowlist expansion.
- Tests cover “I paid” user messages — AI responses must not advance order state or assert confirmation.
- Feature flag allows disabling explain in incident response without redeploying core exchange logic.
- Operational detail in [SECURITY.md](../SECURITY.md) §AI explain / copy.
