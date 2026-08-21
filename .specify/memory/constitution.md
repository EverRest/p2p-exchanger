<!--
Sync Impact Report
- Version change: 1.0.0 → 1.1.0
- Modified principles: Development Workflow expanded (DDD/TDD/SOLID/patterns + prep phase)
- Added sections: none (workflow amendment)
- Removed sections: N/A
- Follow-up TODOs: none
-->

# P2P Exchanger Constitution

## Core Principles

### I. Funds Safety First (NON-NEGOTIABLE)

Every money-affecting path MUST treat PostgreSQL ledger + order state as source of
truth. Order status MUST change only through an explicit state machine. Payment and
payout operations MUST be idempotent. Critical transitions MUST write ledger entries
and audit records in the same transactional boundary as the state change (or via an
outbox committed with that transaction). Silent failures on payment detection,
confirmation, or payout are forbidden: failures MUST surface as failed/exception
states with operator visibility. Kill-switches and risk limits MUST be able to pause
trading and force human review.

**Rationale:** Automated settlement without these invariants risks irreversible loss
and unreconcilable books.

### II. Privilege Separation & Provider Boundaries

Hot-wallet private keys and exchange signing secrets MUST exist only in the
privileged BullMQ worker process—never in the web app, Telegram bot, or HTTP API
process. Domain modules MUST depend on provider ports (`RateProvider`,
`ExchangeProvider`, `PaymentProvider`, `PayoutProvider`); vendor SDKs MUST NOT be
imported into domain/application command handlers. Long-running or external I/O
(payment sync, payouts, rate sync, chain watches) MUST run on queues, never block
HTTP request threads. Cross-module effects MUST use domain events (or buses), not
foreign module repositories.

**Rationale:** Matches transl8.ai worker isolation and limits blast radius under
automated money movement.

### III. Test-First for Money Paths (NON-NEGOTIABLE)

Behavior that creates quotes, transitions orders, posts ledger entries, or executes
payments/payouts MUST follow TDD: failing test → minimal implementation → refactor.
Unit tests cover state machine rules, money arithmetic, and idempotency. Integration
tests MUST cover provider contracts and at least one end-to-end happy path plus one
failure/exception path per rail family in scope. Controllers remain thin; logic lives
in CQRS handlers/services.

**Rationale:** Untested financial rules are unacceptable; TDD is the default, not an
optional extra.

### IV. Spec-Driven, Docs-First Delivery

Product behavior is specified before implementation (Spec Kit: constitution → specify
→ plan → tasks → implement). Runtime architecture guidance lives under `docs/`
(system overview, domain, workflows, ADRs). New cross-cutting patterns REQUIRE an ADR
before adoption. Specs describe what/why; plans lock stack and structure. Agents and
humans MUST resolve doc/code drift by asking which is stale—never silently picking
convenience.

**Rationale:** Prevents vibe-coding on a funds-moving system and keeps AI agents
aligned with transl8.ai discipline.

### V. Simplicity With Extensible Pairs

Ship a modular NestJS monolith (API + worker), React+Vite web, and thin Telegram
client—not microservices. Pair types (fiat↔crypto, crypto↔crypto, fiat↔fiat) MUST
share one generic `input_asset` / `output_asset` engine so corridors are
configuration and adapters, not forks. YAGNI applies to venues, chains, and
channels: do not add providers or networks without a product need. Prefer the
smallest correct diff; complexity MUST be justified in review or ADR.

**Rationale:** One engine keeps A/B/C affordable; premature distribution increases
risk without value.

## Security & Money Safety

- Product model is **client ↔ platform** exchange, not a peer-offer marketplace.
- Happy path MAY be automatic; operators MUST handle exceptions, disputes, and
  risk-flagged cases. Admin actions MUST be RBAC-protected and audited.
- Money amounts MUST use typed decimal/bigint representations—never JavaScript
  `number` for balances, quotes, or ledger posts. Currency mismatch on arithmetic
  MUST fail closed.
- Quotes are immutable snapshots once bound to an order; rates MUST NOT silently
  rewrite an in-flight order.
- AI (if present) is an explain/copy layer only: sanitized prompt context, no
  privileged order/DB tools, and MUST NOT assert payment received unless the system
  already confirmed it.
- KYC/AML and corridor limits are policy hooks: configurable, enforceable, and
  testable—not hardcoded one-off checks scattered in UI.

## Development Workflow

- Engineering direction follows transl8.ai and this project's **AGENTS.md**:
  DDD, CQRS, TDD (money paths), SOLID, DRY, KISS/YAGNI, and the design
  patterns in `docs/patterns.md` (ports/adapters, state machine, outbox,
  idempotency, provider registry).
- NestJS CQRS/DDD modules, Prisma + PostgreSQL, Redis/BullMQ, separate
  `worker.main`, feature-folder React+Vite UI, Makefile/Docker Compose,
  structured logging (Pino) + tracing, versioned REST API.
- Definition of done for behavior changes: tests green for touched money/domain
  logic, typecheck/lint clean, Prisma migration when schema changes, docs/ADR
  updated when architecture or contracts change.
- Web and Telegram are peers over the same API; business rules MUST NOT diverge by
  channel.
- Spec Kit artifacts (`.specify/`, `specs/`) govern feature delivery; `docs/SCOPE.md`
  and ratified design specs constrain product scope.
- Feature implementation begins only when explicitly kicked off; until then,
  prefer repository, docs, and Spec Kit hygiene over speculative product code.

## Governance

This constitution supersedes informal practice and conflicting draft notes when they
disagree on safety, privilege, testing, or architecture boundaries. Amendments
REQUIRE: (1) documented change with version bump, (2) explicit rationale, (3) update
to `LAST_AMENDED_DATE`, and (4) migration notes if existing code/docs violate the
new rule. Versioning: MAJOR for incompatible principle removals/redefinitions; MINOR
for new principles or material expansions; PATCH for clarifications.

All PRs and agent implementations MUST be reviewable against these principles.
Violations of Principles I–III block merge until remediated. Guidance for day-to-day
agent work SHOULD live in `AGENTS.md` once created and MUST remain consistent with
this constitution and `docs/DEVELOPMENT-DIRECTION.md`.

**Version**: 1.1.0 | **Ratified**: 2026-08-21 | **Last Amended**: 2026-08-21
