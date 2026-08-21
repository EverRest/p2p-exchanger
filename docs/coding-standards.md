# Coding standards

Companion to [AGENTS.md](../AGENTS.md) and the [constitution](../.specify/memory/constitution.md).

## Principles in practice

### DDD

- One Nest module ≈ one bounded context.
- Folder habit inside a module (transl8-style):

  ```text
  module/
  ├── domain/           # entities, VOs, ports, domain events, state machine
  ├── application/      # commands, queries, handlers, sagas
  ├── infrastructure/   # Prisma repos, provider adapters, queue processors
  └── presentation/     # controllers, DTOs
  ```

- Speak the language of the spec: Quote, Order, Payment, Payout, LedgerEntry — not “row”, “txn blob”.
- Invariants live on aggregates (Order transitions), not in controllers.

### CQRS

- Commands change state; queries never mutate.
- Controllers: auth + DTO validation + `commandBus.execute` / `queryBus.execute`.
- One command → one handler.

### TDD

Mandatory for: Money arithmetic, order state machine, ledger posts, payment/payout idempotency, risk kill-switch gates.

Loop: write failing test → minimal code → refactor. Do not “add tests later” for money paths.

### SOLID

- **S**: Prefer small handlers over mega-services.
- **O/D**: Add `OkxExchangeProvider` by implementing `ExchangeProvider`, not by `if (vendor === …)` in domain.
- **I**: Split fat ports (`ExchangeProvider` vs `PaymentProvider`).
- **L**: Mocks and real adapters must honor the same contract (including failure modes).

### DRY / KISS / YAGNI

- Share Zod/DTO schemas and Money helpers when used twice with the same meaning.
- Do not introduce Kafka, microservices, or full event sourcing “for scale” before product proof.
- Prefer configuration (pairs, methods, fees) over new code paths.

## Naming

| Kind | Convention |
|------|------------|
| Commands | `CreateQuoteCommand`, `ConfirmPaymentCommand` |
| Queries | `GetOrderQuery`, `ListPairsQuery` |
| Handlers | `CreateQuoteHandler` |
| Ports | `ExchangeProvider`, `RateProvider` |
| Adapters | `BinanceExchangeProvider`, `MockPaymentProvider` |
| Jobs | `payment.detect`, `payout.execute`, `rates.sync` |

## Money & time

- Use `Money` VO (`decimal.js` / Prisma `Decimal`); never `number` for amounts.
- Store timestamps in UTC; display locale in UI only.
- Quotes are immutable snapshots once created.

## Logging & errors

- Structured logs (Pino); include `orderId` / `publicId` where relevant; never log secrets or full PANs/private keys.
- Domain errors → mapped HTTP problems; no stack traces to clients in production.

## Frontend

- Feature folders: `frontend/src/features/{exchange,orders,admin,auth}/` with `api/`, `hooks/`, `pages/`.
- No business invariants in React components — API is source of truth.
- TanStack Query for server state.

## Bot

- Thin client: auth + call API + render messages. No ledger or payout logic.

## Tooling

- Format: Prettier. Lint: ESLint (backend), oxlint/eslint (frontend).
- Pre-commit: lint-staged + typecheck of touched apps (`make pre-commit` / `.husky`).
- CI: `.github/workflows/ci.yml`. Prefer `make ci` locally before push.
