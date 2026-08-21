# P2P Exchanger — Spec Kit step-by-step guide

Project path: `~/code/p2p-exchanger`  
Toolkit: [github/spec-kit](https://github.com/github/spec-kit) (`specify-cli` **v0.16.5**)  
Agent integration: **Cursor** (`cursor-agent` skills in `.cursor/skills/`)

Spec Kit flips the usual flow: **write the what/why first**, then plan tech, then tasks, then code.

---

## Prerequisites (done on this machine)

| Tool | Status |
|------|--------|
| `uv` | installed (`~/.local/bin`) |
| `specify` CLI | `0.16.5` |
| Project | `specify init p2p-exchanger --integration cursor-agent` |

Keep `~/.local/bin` on your PATH:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

Open this folder in Cursor:

```bash
cd ~/code/p2p-exchanger
cursor .
```

---

## Workflow overview

```
constitution → specify → clarify (optional) → plan → checklist (optional)
    → tasks → analyze (optional) → implement → converge (as needed)
```

In Cursor Agent chat, invoke skills with `/speckit-…` (or pick the matching skill).

| Step | Skill | Purpose |
|------|--------|---------|
| 1 | `/speckit-constitution` | Project principles & guardrails |
| 2 | `/speckit-specify` | Product requirements (what/why, not stack) |
| 3 | `/speckit-clarify` | Structured Q&A on ambiguous areas |
| 4 | `/speckit-plan` | Tech stack + architecture |
| 5 | `/speckit-checklist` | Quality checklist for the spec/plan |
| 6 | `/speckit-tasks` | Actionable task breakdown |
| 7 | `/speckit-analyze` | Cross-check spec ↔ plan ↔ tasks |
| 8 | `/speckit-implement` | Build according to tasks |
| 9 | `/speckit-converge` | Gap analysis → new tasks |
| — | `/speckit-taskstoissues` | Optional: push tasks to GitHub issues |

Artifacts live under `.specify/` (memory, templates, workflows) and generated `specs/` as you run the skills.

---

## Step-by-step (copy/paste prompts)

### Step 0 — Open the project

1. `cd ~/code/p2p-exchanger`
2. Open in Cursor and start **Agent** chat in this workspace so skills under `.cursor/skills` are visible.

Product decisions live in `docs/SCOPE.md`. Raw notes: `docs/product/`.

### Step 1 — Constitution (principles)

Run:

```text
/speckit-constitution

Create principles for an **Assisted** client↔platform exchanger (not a peer marketplace), focused on:
- safety of funds; Assisted settlement (detect may be automatic; confirm payment and approve payout require operators); kill-switches and risk limits that can force human review
- explicit order state machine including PAYOUT_APPROVED; no ad-hoc status writes
- durable ledger + full audit trail for every financial transition
- provider boundaries (rates, payments, payouts, exchange liquidity, KYC) — no vendor SDK in domain; privileged secrets only in BullMQ worker (transl8.ai pattern)
- CQRS + DDD module boundaries; cross-module via domain events
- money as typed amounts (never JS number); idempotent payment/payout operations
- KYC VERIFIED before any order; limits as configurable policy
- strong tests on money paths (TDD default); no silent failures on payment or release
- one-task-per-screen UX; AI only as explain/copy layer with no privileged system access (no order tools)
- docs-first: domain/workflows/ADR before new patterns (transl8.ai discipline)
```

Review the generated constitution; adjust until it matches how you want the team/agent to work.

### Step 2 — Specify (product, not stack)

Focus on **what** and **why**. Use `docs/SCOPE.md` + `docs/product/`. Example starter:

```text
/speckit-specify

Build an **Assisted** exchange platform (client ↔ platform, not peer marketplace) that supports ALL pair types:
A) fiat↔crypto (e.g. UAH↔USDT)
B) crypto↔crypto (e.g. USDT↔BTC)
C) fiat↔fiat (e.g. UAH↔EUR)

Core flow: create quote (immutable snapshot) → create order → client pays via issued details →
payment confirmed (system/operator) → processing → payout → completed.
Also: expired/cancelled/refunded/failed terminals; admin actions; Telegram as second client surface;
ledger + audit; risk/limits hooks.

Ship order may phase A then B then C, but the specification must cover all three pair types
with one generic pair/order/payment/payout model.

Out of scope for first release: microservices, many liquidity venues, fully autonomous money movement,
mobile apps, AI that moves funds, peer-offer matching marketplace.
```

Iterate until user stories and acceptance criteria feel complete.

### Step 3 — Clarify (recommended)

```text
/speckit-clarify
```

Answer the skill's questions (assets, custody model, fiat rails, jurisdictions, who holds funds, etc.). This de-risks planning.

### Step 4 — Plan (now pick the stack)

Only after the spec is solid. Example (replace with your choices):

```text
/speckit-plan

Tech preferences for MVP (locked for this repo — see design v0.3):
- Monorepo: backend (NestJS API + privileged worker) + frontend (React+Vite) + bot (grammY)
- Backend: NestJS + CQRS + Prisma + PostgreSQL; Node 22
- Web: React + Vite + TanStack Query + uk/en i18n; clear trade status UI
- Auth: email or phone + step-up OTP; Telegram link to same Customer
- Payments: Assisted path — detect may auto; operator confirm + approve payout; UAH Card/IBAN/Monobank/PrivatBank
- Liquidity: Binance primary + hot wallet fallback via ports (secrets in worker only)
- Observability: structured logs + audit trail for every trade state transition
```

### Step 5 — Checklist (optional quality gate)

```text
/speckit-checklist
```

Use it to catch missing requirements before coding.

### Step 6 — Tasks

```text
/speckit-tasks
```

You should get an ordered, implementable task list (DB, auth, offers, trades, escrow, disputes, admin).

### Step 7 — Analyze (optional)

```text
/speckit-analyze
```

Fix mismatches between spec, plan, and tasks before implementation.

### Step 8 — Implement

```text
/speckit-implement
```

Prefer implementing in vertical slices (e.g. “create offer end-to-end”) rather than all UI then all backend.

### Step 9 — Converge when stuck or after big changes

```text
/speckit-converge
```

Compares codebase to spec/plan/tasks and appends remaining work.

---

## Suggested MVP slice order

1. Auth + user profile  
2. Offer CRUD + listing/search  
3. Trade state machine + persistence  
4. Escrow/hold + release/cancel paths  
5. Payment proof + dispute stub  
6. Basic admin tools  
7. Hardening (idempotency, rate limits, audit log)

Do **not** start coding until Steps 1–2 (and ideally 3–4) are done — that is the point of Spec Kit.

---

## Useful CLI commands

```bash
export PATH="$HOME/.local/bin:$PATH"

specify self check          # newer release available?
specify self upgrade        # upgrade specify-cli

# From project root, after init:
specify extension search
specify preset search
specify bundle search
```

Pin upgrades carefully for a live project; read Spec Kit’s upgrade docs if you bump major templates.

---

## Upgrade note

Installed from:

```bash
uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@v0.16.5
```

Docs: https://github.github.com/spec-kit/

---

## Next action in this chat

Decide product scope (who trades what, custody model), then run **Step 1** (`/speckit-constitution`) in Cursor Agent inside this folder.
