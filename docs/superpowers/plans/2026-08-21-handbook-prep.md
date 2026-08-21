# Handbook Prep (H1–H7) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `p2p-exchanger` documentation and `specs/001-exchange-platform` into full alignment with design v0.3 so feature implementation can start from a single English source of truth.

**Architecture:** Documentation-only prep. Write handbook under `docs/` (SECURITY, system-overview, architecture, domain, workflows, product rewrite, ADRs), then sync `SCOPE.md` and Spec Kit artifacts, then update indexes. No Nest/React feature code in this plan. Do not modify `~/code/p2p-docs`.

**Tech Stack:** Markdown docs in `p2p-exchanger`; Spec Kit under `specs/001-exchange-platform/`; design SoT at `docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md` (v0.3).

## Global Constraints

- SoT repo: **p2p-exchanger only** — never edit `p2p-docs`
- Docs language: **English only**
- Settlement: **Assisted** — operator must **confirm payment** and **approve payout**
- Quote TTL: **120 seconds**; payment window: **30 minutes**
- UAH methods: **Card, IBAN, Monobank, PrivatBank**
- KYC: **VERIFIED before any order**; vendor TBD; mock + manual admin for MVP
- Auth: email **or** phone; step-up OTP on sensitive changes
- i18n: **uk + en**; locale from Accept-Language / Telegram `language_code`; fallback **uk**
- Fees: USDT↔UAH spread **1.0%** service **0.2%**; USDT↔BTC spread **0.8%** service **0.2%**; Card payment fee **0.5%**; IBAN/Mono/Privat **0%**; min service fee **10 UAH** equivalent
- Min/max order amounts: **config placeholders only** (no invented hard numbers)
- AI: explain/copy in MVP; prod default **on** if API key; **no** tools/DB/PII; never invent payment confirmation
- RBAC: **viewer / operator / admin**
- Runtime: **Node 22**; bot: **grammY**
- Order status includes **PAYOUT_APPROVED** (order-visible)
- After each task: commit with a clear message

---

## File map (create / modify)

| Path | Responsibility |
|------|----------------|
| `docs/SECURITY.md` | Trust boundaries, AI, Assisted, KYC/PII, RBAC, secrets, logging |
| `docs/system-overview.md` | C4-lite processes and trust |
| `docs/architecture.md` | Modules, queues, providers, data flow |
| `docs/domain/*.md` | Domain entities and rules |
| `docs/workflows/*.md` | End-to-end flows |
| `docs/product/*.md` | EN product docs aligned to v0.3 |
| `docs/adr/0002`–`0005` | Decision records |
| `docs/SCOPE.md` | Product decisions sync |
| `docs/README.md` | Reading order |
| `specs/001-exchange-platform/*` | Spec Kit sync |
| `README.md`, `AGENTS.md` | Point agents at handbook |
| Design v0.3 | Status → approved after H7 |

---

### Task 1: Mark design approved + create docs index stub

**Files:**
- Modify: `docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md` (status line only)
- Create: `docs/README.md`

- [ ] **Step 1: Update design status**

In `docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md`, set:

```markdown
Status: approved (2026-08-21)
```

- [ ] **Step 2: Create `docs/README.md`**

```markdown
# p2p-exchanger documentation

**Source of truth:** this repo only. Do not use `p2p-docs` for decisions.

## Read in this order

1. [superpowers/specs/2026-08-21-p2p-exchanger-design.md](./superpowers/specs/2026-08-21-p2p-exchanger-design.md) — locked design v0.3
2. [SCOPE.md](./SCOPE.md) — product decisions
3. [SECURITY.md](./SECURITY.md) — funds, secrets, AI isolation, RBAC
4. [system-overview.md](./system-overview.md) — processes & trust boundaries
5. [architecture.md](./architecture.md) — modules & data flow
6. [domain/](./domain/) — domain model
7. [workflows/](./workflows/) — customer & operator flows
8. [product/](./product/) — product narrative (EN, aligned to design)
9. [../specs/001-exchange-platform/](../specs/001-exchange-platform/) — Spec Kit feature spec/plan/tasks
10. [AGENTS.md](../AGENTS.md) — agent playbook

Engineering: [coding-standards.md](./coding-standards.md), [patterns.md](./patterns.md), [adr/](./adr/), [DEVELOPMENT-DIRECTION.md](./DEVELOPMENT-DIRECTION.md).
```

- [ ] **Step 3: Verify files exist**

Run: `test -f docs/README.md && rg -n '^Status: approved' docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md`

Expected: exit 0; status line matches.

- [ ] **Step 4: Commit**

```bash
git add docs/README.md docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md
git commit -m "$(cat <<'EOF'
Approve design v0.3 and add docs reading-order index.

EOF
)"
```

---

### Task 2: Write SECURITY.md

**Files:**
- Create: `docs/SECURITY.md`

- [ ] **Step 1: Write `docs/SECURITY.md`** with at least these sections and rules (English):

1. **Trust boundaries** — table matching design §5 (Web/Bot, API, Worker, AI).
2. **Assisted settlement** — detect may be automatic; `confirm_payment` and `approve_payout` require operator RBAC; customer “I paid” is not final confirm.
3. **AI explain/copy** — allowlisted prompt fields only; no tools; no DB/API; no PII (no names, cards, IBANs, full addresses, emails, phones, telegram ids); never claim payment received unless status already implies system-confirmed; feature flag; prod default on if API key present.
4. **KYC / PII** — no order until VERIFIED; vendor TBD; mock + manual admin; retention/access: only API/admin need KYC data; never send KYC docs to AI.
5. **RBAC** — `viewer` read-only; `operator` confirm payment, approve payout, exceptions; `admin` kill-switch, settings, operator users.
6. **Secrets** — Binance/hot-wallet keys only in worker env; never frontend, never API process, never logs.
7. **Logging** — mask destinations; no secrets.
8. **Kill-switch** — blocks new orders; document that in-flight handling is in workflows.
9. **PR checklist** — bullets: money path? AI context allowlisted? secrets in worker only? audit/ledger?

- [ ] **Step 2: Verify required phrases**

Run:

```bash
rg -n 'Assisted|confirm_payment|approve_payout|allowlisted|viewer|operator|admin|worker' docs/SECURITY.md
```

Expected: matches for each concept.

- [ ] **Step 3: Commit**

```bash
git add docs/SECURITY.md
git commit -m "$(cat <<'EOF'
Add SECURITY handbook for funds, AI isolation, and RBAC.

EOF
)"
```

---

### Task 3: Write system-overview.md and architecture.md

**Files:**
- Create: `docs/system-overview.md`
- Create: `docs/architecture.md`

- [ ] **Step 1: Write `docs/system-overview.md`**

Include:
- One-paragraph product summary (client↔platform exchanger)
- ASCII diagram: Web + Admin, Bot (grammY), API, Postgres, Redis/BullMQ, Worker
- Trust boundary callouts pointing to SECURITY.md
- Channels: web + Telegram same API; admin separate auth

- [ ] **Step 2: Write `docs/architecture.md`**

Include:
- Modular Nest monolith modules list: auth, customers, kyc, quotes, orders, payments, payouts, rates, exchange, ledger, risk, notifications, admin, explain, shared, worker processors
- CQRS: commands mutate, queries read
- Cross-module via domain events (not foreign repos)
- Queues: `payment.detect`, `payout.execute`, `rates.sync`, `exchange.route`, `notify.send` (and note confirm/approve are API commands by operators, not silent auto)
- Provider ports table from design §8
- Frontend: Vite feature folders + i18n uk/en
- Explicit: no business rules in bot beyond API calls

- [ ] **Step 3: Verify**

Run: `test -f docs/system-overview.md && test -f docs/architecture.md && rg -n 'grammY|PAYOUT_APPROVED|KycProvider|BullMQ' docs/architecture.md docs/system-overview.md`

Expected: files exist; key terms present in architecture (PAYOUT_APPROVED may appear in domain later — at least grammY, BullMQ, KycProvider in architecture).

- [ ] **Step 4: Commit**

```bash
git add docs/system-overview.md docs/architecture.md
git commit -m "$(cat <<'EOF'
Add system overview and architecture handbook docs.

EOF
)"
```

---

### Task 4: Write domain handbook

**Files:**
- Create: `docs/domain/overview.md`
- Create: `docs/domain/money.md`
- Create: `docs/domain/quote-and-pricing.md`
- Create: `docs/domain/order-state-machine.md`
- Create: `docs/domain/payment-and-payout.md`
- Create: `docs/domain/ledger.md`
- Create: `docs/domain/risk-and-limits.md`
- Create: `docs/domain/kyc.md`
- Create: `docs/domain/audit.md`

- [ ] **Step 1: Create all domain files** with content covering:

**overview.md** — entity list from design §7; ubiquitous language (Customer, Quote, Order, Payment, Payout, KycCase).

**money.md** — never JS `number`; decimal string / minor units + currency; currency match on arithmetic.

**quote-and-pricing.md** — immutable quote; TTL **120s**; fee pipeline market→spread→fees→final; defaults from Global Constraints; min/max = config placeholders.

**order-state-machine.md** — full happy path including **PAYOUT_APPROVED**; terminals; exception side-path; forbidden reverse transitions example (`COMPLETED` ↛ `AWAITING_PAYMENT`).

**payment-and-payout.md** — separate aggregates; detect vs confirm; approve before execute; idempotency keys; 30 min payment window.

**ledger.md** — append-only; double-entry intent; written with money-affecting transitions.

**risk-and-limits.md** — kill-switch; limits config-driven; elevated risk → exception not auto payout.

**kyc.md** — statuses UNVERIFIED/PENDING/VERIFIED/REJECTED/BLOCKED; gate before order; `KycProvider` port; mock + manual; vendor TBD.

**audit.md** — who/when/why for transitions and operator actions; immutable events.

- [ ] **Step 2: Verify state machine and fees**

Run:

```bash
rg -n 'PAYOUT_APPROVED|120|30 min|1\.0%|0\.8%|KycProvider' docs/domain/
```

Expected: hits across domain files.

- [ ] **Step 3: Commit**

```bash
git add docs/domain/
git commit -m "$(cat <<'EOF'
Add domain handbook covering money, KYC, and Assisted order lifecycle.

EOF
)"
```

---

### Task 5: Write workflows handbook

**Files:**
- Create: `docs/workflows/customer-exchange.md`
- Create: `docs/workflows/operator-exception.md`
- Create: `docs/workflows/kyc-onboarding.md`
- Create: `docs/workflows/kill-switch.md`

- [ ] **Step 1: Write customer-exchange.md**

Step-by-step: auth → KYC verified → select pair/method → quote (120s) → confirm order → pay (30m) → optional “I paid” → PAYMENT_DETECTED → wait for operator confirm → processing → payout pending → operator approve → completed; notifications on both channels; i18n note.

- [ ] **Step 2: Write operator-exception.md**

Exception queue; mismatch; confirm_payment; approve_payout; resolve/refund/cancel within policy; audit; RBAC which role can do what.

- [ ] **Step 3: Write kyc-onboarding.md**

Submit → PENDING → mock/manual or future provider → VERIFIED/REJECTED; cannot create order until VERIFIED.

- [ ] **Step 4: Write kill-switch.md**

Admin enables; new orders refused; pointer to in-flight policy (operators finish or exception existing orders — state explicitly: **in-flight orders continue; only new creates blocked** unless admin also pauses processing via separate flag documented as future — for MVP document: kill-switch blocks **new order creation only**).

- [ ] **Step 5: Verify**

Run: `rg -n 'confirm_payment|approve_payout|VERIFIED|kill-switch' docs/workflows/`

Expected: matches in workflows.

- [ ] **Step 6: Commit**

```bash
git add docs/workflows/
git commit -m "$(cat <<'EOF'
Add customer, operator, KYC, and kill-switch workflows.

EOF
)"
```

---

### Task 6: Rewrite docs/product/* in English

**Files:**
- Modify (replace contents): `docs/product/idea.md`
- Modify: `docs/product/mvp.md`
- Modify: `docs/product/design.md`
- Modify: `docs/product/roadmap.md`
- Modify: `docs/product/spec.md`

- [ ] **Step 1: Replace each file** so they are concise EN product docs aligned to v0.3 (not Ukrainian chat dumps). Required headers:

**idea.md** — problem, client↔platform (not peer marketplace), why Assisted + KYC.

**mvp.md** — launch corridors, 4 UAH methods, Assisted steps, KYC gate, web+Telegram, admin RBAC, AI explain flag, non-goals.

**design.md** — UX sketch for quote/pay/status; AI as copy layer only (security pointer); Gloss-like optional note without mandating.

**roadmap.md** — H handbook → foundation → US1… phases from design §12.

**spec.md** — short product summary linking to `specs/001-exchange-platform/spec.md` and design v0.3; list locked decisions table.

Each file must start with:

```markdown
> Aligned to design v0.3. Supersedes earlier brainstorm notes.
```

- [ ] **Step 2: Verify no Next.js/Drizzle as chosen stack; no AI tools**

Run:

```bash
rg -n 'Next\.js|Drizzle|function-calling|peer marketplace' docs/product/ || true
rg -n 'Assisted|grammY|Node 22|PAYOUT_APPROVED' docs/product/
```

Expected: no Next.js/Drizzle as the selected stack (mentioning “rejected Next.js” is OK); Assisted/grammY/Node 22 present; if “Next.js” appears it must be clearly rejected.

- [ ] **Step 3: Commit**

```bash
git add docs/product/
git commit -m "$(cat <<'EOF'
Rewrite product docs in English aligned to design v0.3.

EOF
)"
```

---

### Task 7: Add ADRs 0002–0005 and sync 0001 pointer

**Files:**
- Create: `docs/adr/0002-assisted-settlement.md`
- Create: `docs/adr/0003-kyc-before-orders.md`
- Create: `docs/adr/0004-privilege-separation-worker.md`
- Create: `docs/adr/0005-ai-explain-only.md`
- Modify: `docs/adr/0001-engineering-principles-and-patterns.md` (add “See also” links at end if missing)

- [ ] **Step 1: Write each ADR** with sections Status (Accepted), Context, Decision, Consequences. Decisions must match Global Constraints.

- [ ] **Step 2: Verify**

Run: `ls docs/adr/0002-assisted-settlement.md docs/adr/0003-kyc-before-orders.md docs/adr/0004-privilege-separation-worker.md docs/adr/0005-ai-explain-only.md`

Expected: all four exist.

- [ ] **Step 3: Commit**

```bash
git add docs/adr/
git commit -m "$(cat <<'EOF'
Add ADRs for Assisted settlement, KYC gate, worker privilege, and AI explain-only.

EOF
)"
```

---

### Task 8: Sync SCOPE.md and DEVELOPMENT-DIRECTION.md

**Files:**
- Modify: `docs/SCOPE.md`
- Modify: `docs/DEVELOPMENT-DIRECTION.md`

- [ ] **Step 1: Update SCOPE.md** so every Global Constraint is reflected: Assisted (not mostly-automatic end-to-end), 4 UAH methods, TTL/window, KYC before order, fees defaults, i18n, Node 22, grammY, AI explain in MVP with isolation, RBAC roles, PAYOUT_APPROVED. Keep non-goals. Point to design v0.3 and SECURITY.md.

- [ ] **Step 2: Update DEVELOPMENT-DIRECTION.md** — frontend Vite (already); bot grammY; Node 22; note handbook paths `docs/domain`, `docs/workflows` now exist; privileged worker unchanged.

- [ ] **Step 3: Verify contradiction scan**

Run:

```bash
rg -n 'mostly automatic|2–3|Next\.js|Telegraf|Node 20' docs/SCOPE.md docs/DEVELOPMENT-DIRECTION.md || true
rg -n 'Assisted|Monobank|120|grammY|Node 22' docs/SCOPE.md
```

Expected: no stale “mostly automatic” happy path without operator; Assisted and methods present.

- [ ] **Step 4: Commit**

```bash
git add docs/SCOPE.md docs/DEVELOPMENT-DIRECTION.md
git commit -m "$(cat <<'EOF'
Sync SCOPE and development direction to design v0.3.

EOF
)"
```

---

### Task 9: Sync specs/001-exchange-platform (spec, data-model, contracts)

**Files:**
- Modify: `specs/001-exchange-platform/spec.md`
- Modify: `specs/001-exchange-platform/data-model.md`
- Modify: `specs/001-exchange-platform/contracts/rest-api.md`
- Modify: `specs/001-exchange-platform/checklists/requirements.md` (note re-validation date)

- [ ] **Step 1: Update spec.md**

- Status: align to design (e.g. `Approved` or keep Draft but add “Aligned to design v0.3”)
- User stories: Assisted operator steps on happy path; KYC before order
- FR: add/adjust KYC gate, Assisted confirm/approve, 4 methods, TTL 120s, window window 30m, i18n, RBAC roles, explain with flag
- SC: remove “≥95% without operator”; add operator-attributed confirm/approve 100% in audit; idempotency; explain false-claim 0
- Assumptions: KYC vendor TBD; min/max config placeholders

- [ ] **Step 2: Update data-model.md**

- Add KycCase
- Order statuses include PAYOUT_APPROVED
- Fee/spread config fields; quote TTL; order expires_at 30m
- PaymentMethod seeds: Card, IBAN, Monobank, PrivatBank

- [ ] **Step 3: Update contracts/rest-api.md**

Add at minimum:

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/kyc/submissions` | Start KYC |
| GET | `/api/v1/kyc/status` | Current KYC status |
| POST | `/api/v1/admin/kyc/:id/decide` | Manual approve/reject (admin/operator per RBAC) |
| POST | `/api/v1/admin/orders/:id/actions` | include `confirm_payment`, `approve_payout`, … |
| POST | `/api/v1/explain` | Sanitized explain (flag) |

Document that order create returns 403 if KYC not VERIFIED.

- [ ] **Step 4: Verify**

Run:

```bash
rg -n 'PAYOUT_APPROVED|KycCase|120|Assisted|≥95%' specs/001-exchange-platform/spec.md specs/001-exchange-platform/data-model.md specs/001-exchange-platform/contracts/rest-api.md
```

Expected: PAYOUT_APPROVED/KycCase/Assisted/120 present; `≥95%` absent or clearly removed.

- [ ] **Step 5: Commit**

```bash
git add specs/001-exchange-platform/spec.md specs/001-exchange-platform/data-model.md specs/001-exchange-platform/contracts/rest-api.md specs/001-exchange-platform/checklists/requirements.md
git commit -m "$(cat <<'EOF'
Align feature spec, data model, and REST contract with Assisted KYC design.

EOF
)"
```

---

### Task 10: Sync plan, research, tasks, quickstart

**Files:**
- Modify: `specs/001-exchange-platform/plan.md`
- Modify: `specs/001-exchange-platform/research.md`
- Modify: `specs/001-exchange-platform/tasks.md`
- Modify: `specs/001-exchange-platform/quickstart.md`

- [ ] **Step 1: plan.md** — Node **22**; grammY; Assisted; KycProvider; i18n; fee defaults referenced.

- [ ] **Step 2: research.md** — Add R-entries (or update existing) for: Assisted vs full auto; grammY; KYC-before-order; Node 22. Mark rejected: full auto MVP, Telegraf as choice, deferred KYC.

- [ ] **Step 3: tasks.md**

- Mark Phase 1 setup tasks that already exist in repo as done **only if** directories/package files truly exist (verify with `ls`); do not mark domain Money/state machine done
- Add foundational KYC tasks (schema KycCase, KycProvider port, mock, admin decide, gate on CreateOrder)
- US1 steps: after PAYMENT_DETECTED require operator confirm; before payout execute require approve_payout
- Explain tasks: keep; note prod flag default on if key
- Bot: specify **grammY**
- Node references: **22**

- [ ] **Step 4: quickstart.md** — Scenarios include operator confirm + approve; KYC verified prerequisite; MOCK_PROVIDERS; Node 22

- [ ] **Step 5: Verify**

Run:

```bash
rg -n 'grammY|Node 22|approve_payout|KycProvider|Assisted' specs/001-exchange-platform/plan.md specs/001-exchange-platform/tasks.md specs/001-exchange-platform/quickstart.md specs/001-exchange-platform/research.md
```

Expected: all terms present.

- [ ] **Step 6: Commit**

```bash
git add specs/001-exchange-platform/plan.md specs/001-exchange-platform/research.md specs/001-exchange-platform/tasks.md specs/001-exchange-platform/quickstart.md
git commit -m "$(cat <<'EOF'
Sync plan, research, tasks, and quickstart to design v0.3.

EOF
)"
```

---

### Task 11: Update root README + AGENTS.md + handbook DoD check

**Files:**
- Modify: `README.md`
- Modify: `AGENTS.md`
- Modify: `docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md` (§13 checkboxes → mark done notes or leave checklist for human — prefer add “Handbook completed: YYYY-MM-DD” under §13)

- [ ] **Step 1: Update README.md** quick links to include SECURITY, docs/README reading order, design v0.3; status line: handbook prep complete / feature impl from tasks.md; architecture blurb Assisted + privileged worker.

- [ ] **Step 2: Update AGENTS.md**

- Current phase: handbook done; implement from `specs/001-exchange-platform/tasks.md`
- BEFORE coding: read constitution, coding-standards, patterns, **SECURITY.md**, design v0.3, relevant domain/workflow
- Explicit: ignore `p2p-docs`; SoT is this repo
- Bot: grammY; Node 22; Assisted rules one-liner

- [ ] **Step 3: Contradiction sweep**

Run:

```bash
rg -n 'mostly automatic settlement|2–3 methods|Telegraf|Next\.js \+ TypeScript|Drizzle ORM' docs/SCOPE.md docs/product/ specs/001-exchange-platform/ AGENTS.md README.md || true
```

Expected: no unresolved contradictions presenting those as current choices. Fix any hits before commit.

- [ ] **Step 4: File existence DoD**

Run:

```bash
test -f docs/SECURITY.md && test -f docs/system-overview.md && test -f docs/architecture.md && test -f docs/domain/order-state-machine.md && test -f docs/workflows/customer-exchange.md && test -f docs/adr/0005-ai-explain-only.md && test -f docs/README.md
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add README.md AGENTS.md docs/superpowers/specs/2026-08-21-p2p-exchanger-design.md
git commit -m "$(cat <<'EOF'
Point agents and README at completed handbook; ready for feature tasks.

EOF
)"
```

---

## Self-review (plan author)

| Spec v0.3 area | Tasks |
|----------------|-------|
| SECURITY / AI / RBAC | T2, T7 ADR 0005 |
| system-overview / architecture | T3 |
| domain + PAYOUT_APPROVED + fees + KYC | T4 |
| workflows Assisted | T5 |
| product EN rewrite | T6 |
| ADRs | T7 |
| SCOPE sync | T8 |
| specs/001 | T9, T10 |
| indexes / AGENTS | T1, T11 |
| Prep order H1–H7 | T2→T11 |
| p2p-docs untouched | Global constraint |
| Fee defaults | Global + T4 + T8 |
| i18n | T5, T6, T8, T9 |

No intentional TBD steps; open numeric min/max and KYC vendor remain documented as placeholders per spec.

---

## Execution handoff

Plan complete and saved to `docs/superpowers/plans/2026-08-21-handbook-prep.md`. Two execution options:

**1. Subagent-Driven (recommended)** — fresh subagent per task, review between tasks  
**2. Inline Execution** — execute tasks in this session with executing-plans checkpoints  

Which approach?
