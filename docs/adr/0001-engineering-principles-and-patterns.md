# ADR 0001: Engineering principles and pattern catalogue

## Status

Accepted — 2026-08-21

## Context

Before feature implementation, the team needs a single place that binds Spec Kit
constitution rules to day-to-day coding: DDD, CQRS, TDD, SOLID, DRY, KISS, and
patterns that keep liquidity/payment rails swappable.

## Decision

1. **AGENTS.md** is the agent/human entrypoint.  
2. **docs/coding-standards.md** details principle practice.  
3. **docs/patterns.md** lists allowed patterns (hexagonal ports, state machine,
   outbox, saga, idempotency, provider registry, Money VO).  
4. New cross-cutting patterns require a new ADR before adoption.  
5. Feature code starts only from `specs/001-exchange-platform/tasks.md` when
   explicitly kicked off.

## Consequences

- Reviews can reject PRs that violate privilege isolation or use `number` for money.  
- Agents default to TDD on money paths.  
- Transl8.ai remains the structural reference for Nest/worker/DX.

## See also

- [0002-assisted-settlement.md](./0002-assisted-settlement.md) — operator confirm/approve gates  
- [0003-kyc-before-orders.md](./0003-kyc-before-orders.md) — KYC VERIFIED before orders  
- [0004-privilege-separation-worker.md](./0004-privilege-separation-worker.md) — worker-only secrets  
- [0005-ai-explain-only.md](./0005-ai-explain-only.md) — AI copy without tools or PII
