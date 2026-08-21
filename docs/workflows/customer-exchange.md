# Customer exchange workflow

End-to-end flow for a verified customer exchanging assets on **web** or **Telegram bot**. Both channels call the same API and follow the [order state machine](../domain/order-state-machine.md). Settlement is **Assisted**: operators confirm payment and approve payout (see [SECURITY.md](../SECURITY.md)).

## Prerequisites

| Gate | Rule |
|------|------|
| Authentication | Email or phone login; session valid on web or Telegram link |
| KYC | Status **VERIFIED** — see [kyc-onboarding.md](./kyc-onboarding.md) and [kyc.md](../domain/kyc.md) |
| Kill-switch | Off — see [kill-switch.md](./kill-switch.md) |
| Limits | Within PlatformSettings — see [risk-and-limits.md](../domain/risk-and-limits.md) |

## Step-by-step

### 1. Authenticate

Customer signs in on web or opens the bot. Locale is detected from `Accept-Language` (web) or Telegram `language_code` (bot); fallback **uk**. UI copy is **UK + EN** (design v0.3 §4).

### 2. Verify KYC

If not **VERIFIED**, the customer is routed to KYC onboarding. Order creation is blocked until verification completes.

### 3. Select pair and payment method

Customer chooses corridor (e.g. USDT ↔ UAH) and, for UAH legs, method: Card, IBAN, Monobank, or PrivatBank. See [quote-and-pricing.md](../domain/quote-and-pricing.md) for fees.

### 4. Request quote (120s TTL)

API creates an immutable **Quote** with rates and fees snapshotted. Quote expires **120 seconds** after creation. Expired quotes cannot bind orders.

### 5. Confirm order

Customer confirms at the quoted price. API validates:

- Quote not expired
- KYC still **VERIFIED**
- Kill-switch off
- Limits OK

On success, order enters `CREATED` → `AWAITING_PAYMENT`. Customer receives payment instructions and a **30 min** payment window starts ([payment-and-payout.md](../domain/payment-and-payout.md)).

### 6. Pay (30 min window)

Customer sends funds via the selected method within the payment window. Unpaid orders after 30 min → terminal `EXPIRED`.

Optional: customer taps **“I paid”** or uploads a receipt. This is a **hint only** — it does not confirm payment. Operators and detection systems use it as a signal ([SECURITY.md](../SECURITY.md) §Assisted settlement).

### 7. Payment detected

Worker or `PaymentProvider` signals inbound funds → order `PAYMENT_DETECTED`. This step may be automatic. Customer is notified on both channels (web push/in-app + Telegram when linked).

### 8. Wait for operator confirm

Order stays at `PAYMENT_DETECTED` until an authorized operator runs **`confirm_payment`**. Customer “I paid” does not advance state. See [operator-exception.md](./operator-exception.md).

When confirmed → `PAYMENT_CONFIRMED` → `PROCESSING` (liquidity routing, internal checks).

### 9. Payout pending

After processing, payout is prepared → order `PAYOUT_PENDING`. Customer sees payout is awaiting operator approval.

### 10. Operator approve payout

Authorized operator runs **`approve_payout`** → order `PAYOUT_APPROVED`. Worker then executes payout with signing secrets (worker only).

### 11. Completed

Successful payout execution → order `COMPLETED`. Customer receives completion notification on both channels.

## Notifications

| Event | Channels |
|-------|----------|
| Order created / payment instructions | Web + Telegram (if linked) |
| Payment detected | Web + Telegram |
| Payment confirmed / processing | Web + Telegram |
| Payout approved / completed | Web + Telegram |
| Expiry, cancel, refund, failure | Web + Telegram |

Notification payloads use locale-appropriate copy; no secrets or full payment credentials in messages.

## AI explain (MVP)

When enabled, customers may see AI-generated explanations of steps, fees, or status. AI uses **allowlisted** fields only — no PII, no invented payment confirmation ([SECURITY.md](../SECURITY.md) §AI explain/copy).

## Terminal outcomes

Besides **COMPLETED**, an order may end as `EXPIRED`, `CANCELLED`, `REFUNDED`, or `FAILED`. See [order-state-machine.md](../domain/order-state-machine.md).

## Related docs

- [payment-and-payout.md](../domain/payment-and-payout.md) — pay-in/out aggregates
- [ledger.md](../domain/ledger.md) — accounting entries on money transitions
- [audit.md](../domain/audit.md) — audit trail for customer and system actions
