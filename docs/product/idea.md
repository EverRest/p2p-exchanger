> Aligned to design v0.3. Supersedes earlier brainstorm notes.

# Product idea

## Problem

Customers need a reliable way to convert between fiat and crypto (and later crypto↔crypto, fiat↔fiat) without navigating a peer marketplace, negotiating with strangers, or trusting opaque settlement.

## What we build

A **client ↔ platform** exchanger: the platform quotes, holds workflow state, and settles under operator control. This is **not** a peer marketplace — there are no counterparty ads, escrow between users, or user-to-user matching.

## Why Assisted settlement

Money movement is too risky to fully automate at launch. **Assisted** mode means:

- Detection may run automatically (webhooks, polling, provider signals).
- **Confirm payment** and **approve payout** are operator-only actions.
- Customer “I paid” is a signal, not final confirmation.

This keeps the first release safe while still automating quotes, order lifecycle, notifications, and ledger entries.

## Why KYC before orders

Regulatory and fraud risk require identity verification before any order is created. No quote converts to an order until the customer is **KYC VERIFIED** (mock provider + manual admin approval in MVP; real vendor TBD).

## Channels

Same domain and API for **web** (React + Vite, UK + EN) and **Telegram** (grammY bot, thin client). Admin dashboard for operators with RBAC (viewer / operator / admin).

## Stack direction (high level)

TypeScript end-to-end on **Node 22**: NestJS API (CQRS) + Prisma + PostgreSQL, privileged worker for exchange/wallet secrets, BullMQ + Redis. Earlier brainstorms suggested Next.js + Drizzle — **rejected** in favor of the handbook stack above.
