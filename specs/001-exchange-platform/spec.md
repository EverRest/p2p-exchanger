# Feature Specification: Core Exchange Platform

**Feature Branch**: `001-exchange-platform`

**Created**: 2026-08-21

**Status**: Draft — Aligned to design v0.3

**Input**: User description: "Build a client↔platform exchange supporting fiat↔crypto, crypto↔crypto, and fiat↔fiat; launch USDT↔UAH and USDT↔BTC; Assisted settlement with operator confirm/approve; KYC before orders; Web + Telegram; immutable quotes; ledger/audit; AI explain-only; not a peer marketplace."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Complete a fiat↔crypto exchange (Priority: P1)

A customer with **VERIFIED KYC** wants to exchange between UAH and USDT (either direction). They open the web app or Telegram (UK or EN locale), choose the corridor and network (for USDT: TRC20 or ERC20), enter an amount, receive a locked quote (120s TTL), provide payout details, confirm the order, pay using the issued payment instructions, and receive the output asset when the exchange completes. On the happy path, payment may be **detected** automatically, but an **authorized operator confirms payment** and later **approves payout** before completion. Status updates are visible throughout, including `PAYOUT_APPROVED` before final completion.

**Why this priority**: Primary revenue corridor and the first launch pair family; without this there is no product.

**Independent Test**: With VERIFIED KYC, liquidity, and one UAH method available, complete USDT→UAH and UAH→USDT end-to-end on web (or Telegram) including quote lock, payment, operator confirm/approve, and payout receipt.

**Acceptance Scenarios**:

1. **Given** the customer is authenticated with KYC status VERIFIED and USDT↔UAH is enabled, **When** they request a quote for a valid amount, **Then** they see input amount, output amount, rate, fees, expiry time (120s), and network options for USDT.
2. **Given** a valid unexpired quote and VERIFIED KYC, **When** the customer confirms with required payout details, **Then** an order is created bound to that quote with a 30-minute payment window and payment instructions are issued.
3. **Given** an order awaiting payment, **When** the correct payment is detected and an operator confirms payment, **Then** the order moves through processing to payout pending, an operator approves payout, the order reaches `PAYOUT_APPROVED` then completed, and the customer is notified.
4. **Given** a quote that has expired, **When** the customer tries to confirm it, **Then** confirmation is rejected and they must obtain a new quote.
5. **Given** the customer is authenticated but KYC is not VERIFIED, **When** they attempt to create an order, **Then** order creation is rejected with a clear message to complete KYC first.

---

### User Story 2 - Complete a crypto↔crypto exchange (Priority: P1)

A customer with **VERIFIED KYC** exchanges USDT↔BTC (either direction), selecting USDT network when USDT is involved, locking a quote (120s TTL), paying in the input asset, and receiving the output asset after operator confirm payment and approve payout on the happy path.

**Why this priority**: Explicit launch corridor alongside UAH pairs; validates the generic pair model beyond fiat rails.

**Independent Test**: Complete USDT→BTC and BTC→USDT with valid addresses/networks, operator confirm/approve on happy path, and observe completed payout.

**Acceptance Scenarios**:

1. **Given** USDT↔BTC is enabled and KYC is VERIFIED, **When** the customer creates a quote, **Then** amounts, rate, fees, networks, and expiry (120s) are shown and locked on confirm.
2. **Given** an order awaiting crypto payment, **When** the correct amount arrives on the specified network/address and an operator confirms payment and approves payout, **Then** the order completes payout of the output asset.
3. **Given** the customer selects an unsupported network or invalid address, **When** they attempt to continue, **Then** the system blocks progression with a clear error.

---

### User Story 3 - Track order status and get plain-language help (Priority: P2)

During or after an exchange, the customer views clear status (what happened, what to do next) in their locale (UK or EN). Optional explain/help text (feature flag; prod default on when API key present) answers questions about fees, networks, or steps using only non-sensitive screen context—never inventing that a payment was received unless the system already confirmed it.

**Why this priority**: Reduces support load and anxiety; AI/copy is secondary to money movement but part of agreed UX.

**Independent Test**: Open an in-progress and a completed order; verify statuses and help explanations match system state and never claim unconfirmed payment.

**Acceptance Scenarios**:

1. **Given** an order in awaiting payment, **When** the customer views it, **Then** they see payment instructions, deadline (30 min window), and next step in plain language.
2. **Given** payment is confirmed by an operator (or authorized system action), **When** help text explains status, **Then** it may state payment received; **Given** payment is not confirmed, **Then** help MUST NOT claim it was received.
3. **Given** the customer uses Telegram or web, **When** they list their orders, **Then** the same statuses and amounts appear on both channels.

---

### User Story 4 - Operator handles Assisted settlement and exceptions (Priority: P2)

An operator uses an admin console to **confirm payment** and **approve payout** on happy-path orders, see orders needing human attention (payment mismatch, risk flag, failed payout, customer dispute), add notes, apply allowed overrides (within RBAC: viewer read-only; operator confirm/approve and exception queue; admin kill-switch, settings, fee/config, user management), pause trading via kill-switch when needed, and leave an auditable trail.

**Why this priority**: Settlement is Assisted; operators are mandatory for money movement on the happy path and the safety net for exceptions.

**Independent Test**: Complete a happy-path order with operator confirm and approve recorded in audit; force an exception (e.g. wrong amount), confirm order appears in exception queue, resolve or escalate with audit entry, and verify kill-switch stops new orders.

**Acceptance Scenarios**:

1. **Given** payment is detected on an order, **When** an operator with permission confirms payment, **Then** the order advances to payment confirmed with actor and timestamp in the audit trail.
2. **Given** an order in payout pending, **When** an operator approves payout, **Then** the order moves to `PAYOUT_APPROVED` and proceeds to completion with audit attribution.
3. **Given** a payment amount mismatch, **When** detection finishes, **Then** the order enters an exception state visible to operators and is not paid out without resolution.
4. **Given** kill-switch is enabled, **When** a customer tries to create a new order, **Then** creation is refused with a clear message.

---

### User Story 5 - Fiat↔fiat exchange (same engine, later corridor) (Priority: P3)

A customer with VERIFIED KYC exchanges between two fiat currencies (e.g. UAH↔EUR) using the same quote→order→pay→payout lifecycle, with payment and payout both on fiat rails and an FX rate snapshot.

**Why this priority**: In product scope for the generic model but ships after UAH/USDT and USDT/BTC are stable.

**Independent Test**: With a fiat↔fiat pair enabled in configuration, complete one direction end-to-end using two fiat methods.

**Acceptance Scenarios**:

1. **Given** a fiat↔fiat pair is enabled and KYC is VERIFIED, **When** the customer quotes and confirms, **Then** the order follows the same Assisted lifecycle states as other pair types.
2. **Given** the pair is disabled, **When** the customer requests it, **Then** it is unavailable without breaking other corridors.

---

### Edge Cases

- Quote expires (120s TTL) while the customer is filling payout details.
- Customer pays wrong amount, wrong asset, wrong network, or after the 30-minute payment window.
- Duplicate payment or double-submit of “I paid” / confirm (customer self-report may trigger detection but is not final confirm).
- Liquidity provider unavailable; fallback liquidity path used or order fails safely to exception.
- Payout fails after payment confirmed (refund/exception path, no silent drop).
- Concurrent modification / repeated webhook or detection events for the same payment.
- Customer cancels before payment; paid orders cannot be casually cancelled without policy.
- Risk limits exceeded (amount, velocity, cumulative) → block or force human review.
- KYC pending or rejected → order creation blocked until VERIFIED.
- Telegram and web sessions for the same person must not create conflicting identities without linking rules.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support exchange pair types fiat↔crypto, crypto↔crypto, and fiat↔fiat through one generic pair model (`input` asset / `output` asset, optional network).
- **FR-002**: System MUST enable launch corridors USDT↔UAH and USDT↔BTC (both directions); fiat↔fiat MAY be disabled until configured but MUST be representable without a separate product engine.
- **FR-003**: System MUST support USDT on TRC20 and ERC20; BTC on mainnet with address validation appropriate to the asset.
- **FR-004**: System MUST support exactly **four** UAH payment/payout methods at launch: **Card, IBAN, Monobank, PrivatBank**, selectable via configuration.
- **FR-005**: System MUST produce immutable quotes (rate, fees, input/output amounts, expiry) with **120-second TTL** and MUST bind an order to a specific quote snapshot that cannot change silently after confirmation.
- **FR-006**: System MUST advance orders only through an explicit lifecycle including at least: created, awaiting payment, payment detected, payment confirmed, processing, payout pending, **payout approved**, completed; plus terminals expired, cancelled, refunded, failed; and an exception/dispute path for human handling.
- **FR-007**: System MUST issue clear payment instructions per order (amount, asset/network, destination, **30-minute payment deadline**) and accept **final** payment confirmation only from authorized **operator** action (after optional automated detection)—not from unverified customer self-assertion alone.
- **FR-008**: System MUST require an authorized **operator to confirm payment** and **approve payout** on the happy path before payout execution completes; automated detection MAY assist but MUST NOT bypass operator attribution in audit.
- **FR-009**: System MUST route mismatches, risk flags, payout failures, and disputes to an operator-visible exception queue and MUST NOT complete payout in those cases without operator resolution.
- **FR-010**: System MUST maintain a durable ledger of money-affecting movements and an audit trail of order transitions and operator actions (including confirm payment and approve payout with actor identity).
- **FR-011**: System MUST enforce idempotent handling of payment detection, operator actions, and payout execution so retries cannot double-pay or double-credit.
- **FR-012**: System MUST provide a kill-switch (or equivalent) to pause new orders and configurable risk/limit hooks that can block or require human review.
- **FR-013**: System MUST expose the full customer exchange journey on Web and on Telegram with the same business rules and consistent order data.
- **FR-014**: System MUST provide an admin console for operators to inspect orders, confirm payment, approve payout, act on exceptions, and apply RBAC-protected overrides.
- **FR-015**: System MUST enforce RBAC roles: **viewer** (read-only), **operator** (confirm_payment, approve_payout, exception queue), **admin** (kill-switch, platform settings, fee/config, operator user management).
- **FR-016**: System MUST obtain liquidity primarily from a designated primary exchange venue, with configurable fallback to a platform-controlled hot wallet, without exposing custody keys to customer clients.
- **FR-017**: Customers MUST authenticate before creating orders; Telegram identity MAY be linked to the same customer record as web.
- **FR-018**: System MUST require **KYC status VERIFIED** before any order creation; KYC vendor is TBD for production; MVP uses mock provider plus manual admin approval path.
- **FR-019**: System MUST expose KYC submission and status to customers and manual approve/reject to authorized admin/operator per RBAC.
- **FR-020**: Optional explain/help assistance MUST be available behind a feature flag (prod default on when API key present), use only sanitized, non-privileged context, and MUST NOT move funds or assert unconfirmed payment.
- **FR-021**: System MUST notify customers of material status changes (at least: awaiting payment, payout approved, completed, failed/exception) on their active channel(s).
- **FR-022**: System MUST reject expired quotes, invalid addresses/networks, disabled pairs, non-VERIFIED KYC, and kill-switched creations with actionable errors.
- **FR-023**: System MUST support client UI in **Ukrainian and English**; locale from Accept-Language or Telegram `language_code` with fallback **uk**.
- **FR-024**: Fees, spreads, limits (min/max as config placeholders), and enabled pairs/networks/methods MUST be configuration-driven so ops can change them without redesigning the exchange lifecycle.

### Key Entities

- **Customer**: Person using web and/or Telegram; authentication and optional channel link; KYC status reference.
- **KycCase**: Customer identity verification case (status, vendor ref, admin decision).
- **Exchange pair**: Allowed input/output assets (and networks) with enablement and limits.
- **Quote**: Immutable priced offer with fees and 120s expiry.
- **Order**: Customer commitment bound to a quote; carries lifecycle state including `PAYOUT_APPROVED`.
- **Payment**: Inbound funds attempt/record for an order (amount, rail, detection/confirmation state).
- **Payout**: Outbound funds to customer details (amount, rail, execution state).
- **Ledger entry**: Append-only business record of value movement related to orders.
- **Audit event**: Who/what changed an order or performed an operator action (confirm/approve attributed).
- **Payment method**: Configured fiat or crypto rail option for pay-in or pay-out (Card, IBAN, Monobank, PrivatBank for UAH).
- **Exception / dispute**: Human-attention case linked to an order.
- **Risk policy**: Limits and flags that alter automatic vs human handling.
- **Operator user**: Admin console user with viewer / operator / admin role.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A new customer with VERIFIED KYC can complete a first USDT↔UAH exchange (quote → pay → operator confirm/approve → receive) in under 15 minutes when rails are healthy, excluding external bank/chain delays beyond the platform’s control.
- **SC-002**: **100%** of happy-path payment confirmations and payout approvals are attributed to an authorized operator (or equivalent authorized system actor) in the audit trail with actor identity and timestamp.
- **SC-003**: 100% of completed or failed money-affecting orders have matching ledger and audit records sufficient to reconstruct what happened.
- **SC-004**: Duplicate payment-detection, operator action, or payout retries never result in double payout in test scenarios designed for idempotency.
- **SC-005**: Customers see consistent order status between Web and Telegram within 30 seconds of a status change under normal operation.
- **SC-006**: Kill-switch activation stops new order creation within 1 minute and is verifiable in admin.
- **SC-007**: Explain/help never claims payment received in moderated review samples when system state is not payment-confirmed (**0 false claims** in sampled scripts).
- **SC-008**: USDT↔BTC launch corridor supports both directions with the same Assisted lifecycle UX as UAH pairs.

## Assumptions

- Target market initially centers on Ukrainian hryvnia corridors plus USDT/BTC; exact legal entity and licensing thresholds are handled outside this feature spec but KYC hooks enforce VERIFIED before orders.
- KYC vendor for production is **TBD**; MVP uses mock provider and manual admin approval.
- Min/max order amounts are **configuration placeholders** only (no fixed numeric defaults in product docs).
- “Primary exchange venue” and “hot wallet fallback” are product capabilities; specific vendor contracts and key custody procedures are operational concerns constrained by the constitution’s privilege rules.
- Customer self-report of payment may start detection workflows but **final** payment confirmation requires authorized operator confirmation (Assisted settlement).
- Fiat↔fiat is specified for model completeness; enabling EUR (or other) methods can follow launch without changing lifecycle semantics.
- Auth is account-based (email **or** phone and session) plus Telegram identity linking; step-up OTP on sensitive profile changes; social SSO is optional later.
- Mobile native apps are out of scope; responsive web is sufficient.
- Peer-to-peer offer matching between two customers is out of scope.
- UAH launch methods are Card, IBAN, Monobank, PrivatBank (configuration-driven labels and fees).
- AI explain/copy is in MVP behind a feature flag; prod default on when API key present; behavior rules apply whenever it is enabled.
