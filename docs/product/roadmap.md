> Aligned to design v0.3. Supersedes earlier brainstorm notes.

# Roadmap

## Phase H — Handbook (before feature code)

Complete documentation so specs and implementation stay aligned.

| Step | Deliverable |
|------|-------------|
| H0 | Design v0.3 committed |
| H1 | SECURITY, system-overview, architecture |
| H2 | domain/*, workflows/* |
| H3 | **docs/product/** rewrite (this set) |
| H4 | ADRs 0002–0005 (+ sync 0001) |
| H5 | Sync SCOPE.md + specs/001/* |
| H6 | docs/README, root README, AGENTS.md |
| H7 | Handbook DoD green → writing-plans / tasks.md |

Prep order: **Handbook → sync specs/001 → code**.

## Phase 1 — Foundation

Money types, order state machine (incl. **PAYOUT_APPROVED**), ledger, mocks, auth (email/phone + step-up OTP), KYC port + admin shell, RBAC, kill-switch, idempotency + audit.

Runtime: **Node 22**. API: NestJS + CQRS + Prisma + PostgreSQL. Worker: BullMQ + Redis.

## Phase 2 — US1: USDT ↔ UAH (Assisted)

Web vertical slice: quote (120s TTL) → order → payment (4 UAH methods) → operator confirm/approve → complete. AI explain behind feature flag.

## Phase 3 — US2: USDT ↔ BTC

Second corridor on same engine; BTC network fee from provider estimate on quote.

## Phase 4 — Telegram parity

grammY bot as thin client to same API; UK + EN from `language_code`.

## Phase 5 — Exceptions polish

Exception queue UX, mismatch/risk flows, operator SLA tooling (targets TBD).

## Phase 6 — Fiat↔fiat config

Pair-type C as configuration — no new product surface required for handbook.

## Phase 7 — Real adapters

Binance, hot wallet, and KYC vendor implementations behind existing ports.

## Explicitly later

Microservices, K8s, mobile apps, peer marketplace, AI tools/agents, multi-venue arbitrage, production key ceremony.
