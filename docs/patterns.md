# Patterns

How cross-cutting design patterns are applied. New patterns require an ADR in `docs/adr/`.

## CQRS

```text
Controller → DTO → CommandBus/QueryBus → Handler → Domain/Service → Port → Adapter/DB/Queue
```

- Commands mutate; queries are read-only.
- Never mix “read and also side-effect” in one handler.

## Hexagonal (ports & adapters)

Domain defines ports; infrastructure implements them.

```text
orders/application
       ↓
ExchangeProvider (port)
       ↓
┌──────────────┬─────────────────┐
│ BinanceAdapter│ HotWalletAdapter│  (+ Mock* for tests/CI)
└──────────────┴─────────────────┘
```

Failover policy lives outside domain entities (worker/routing service).

## Domain events

Modules react via events, not by importing another module’s repository.

```text
PaymentConfirmedEvent → Payout module / Ledger / Notifications
```

Prefer transactional outbox: write state + outbox row in one DB transaction; worker publishes.

## State machine

Order status changes only through an allowlisted transition table. Illegal transitions throw. Every money-affecting transition writes ledger + audit.

## Saga / process manager

Long flows (detect → confirm → route liquidity → payout) are orchestrated as steps with compensations where the business requires (e.g. mark FAILED / EXCEPTION, never silent drop). Each step is idempotent.

## Idempotency

- Unique `idempotencyKey` on payment detection and payout execution.
- Assume every BullMQ job can run twice.
- Admin actions carry client-supplied or generated idempotency keys.

## Repository

Prisma access stays in `infrastructure/`. Application layer talks to repository interfaces or narrow services owned by the module.

## Value objects

`Money`, asset/network refs — equality by value, validation on construction, no primitive obsession in domain APIs.

## Strategy / registry

Provider registry selects adapter by config (method id, asset, venue). Same idea as transl8 `ProviderRegistry` / attempt schedules — simpler at launch, same extension point.

## Factory

Centralize Quote/Order snapshot creation so fees/rates cannot be partially applied.

## Circuit breaker / graceful degradation

When primary liquidity fails, policy may fail over to hot wallet or open an EXCEPTION for operators — never invent balances in the API process.

## Privilege boundary (security pattern)

```text
Web / Bot / API  →  enqueue jobs, read DB
Worker           →  holds BINANCE_* / HOT_WALLET_*, executes payouts
```

Treat violation of this boundary as a release blocker.

## Anti-patterns

| Avoid | Prefer |
|-------|--------|
| `order.status = 'COMPLETED'` anywhere | State machine service |
| Binance SDK in `quotes` domain | `ExchangeProvider` in worker |
| `amount: number` | `Money` |
| God `ExchangeService` | Small CQRS handlers |
| Copy-paste corridor forks | Generic pair + config |
| Chatbot that “confirms payment” from LLM | System state → then copy layer |
