# ADR 0004: Privilege separation — privileged worker

## Status

Accepted — 2026-08-21

## Context

Exchange liquidity (Binance) and hot-wallet signing material are high-value secrets. Collocating them with the public API, web client, or Telegram bot expands blast radius: a single compromise could sign payouts or leak keys. The architecture separates a **privileged worker** from the NestJS API.

## Decision

1. Run a **separate worker process** (Nest + BullMQ) for payment detect, liquidity routing, and payout execution.
2. **Worker only** may hold Binance API keys and hot-wallet signing secrets (env / secret store per environment).
3. **API** may access DB, business rules, job enqueue, and KYC orchestration — it **must not** hold or use hot-wallet / Binance signing secrets.
4. **Web / bot** may hold customer session or bot token only — **must not** hold wallet keys, exchange secrets, or treat DB as SoT.
5. Worker **must not** treat customer session or client assertions as authority for confirm/approve; operator gates remain on the API/domain layer ([0002-assisted-settlement.md](./0002-assisted-settlement.md)).
6. Domain code imports **ports** (`ExchangeProvider`, `PayoutProvider`, etc.), not vendor SDKs with embedded credentials.

## Consequences

- CI, Docker, and deployment manifests define distinct API and worker services with scoped env vars.
- PR review rejects Binance or wallet material in API, frontend, bot, or committed test fixtures.
- Job payloads use order IDs and idempotency keys — not raw secrets or session tokens as proof of payment.
- Security handbook and PR checklist enforce the boundary ([SECURITY.md](../SECURITY.md) §Trust boundaries, §Secrets).
- Aligns with modular monolith + worker pattern from transl8.ai reference architecture.
