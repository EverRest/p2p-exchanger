# Data Model: Core Exchange Platform

**Feature**: `001-exchange-platform`  
**Date**: 2026-08-21

## Entities

### Customer

| Field | Notes |
|-------|--------|
| id | UUID |
| email / phone | At least one identifier for web auth |
| telegram_user_id | Optional, unique when set |
| status | active / blocked |
| risk_level | default / elevated / blocked |
| created_at, updated_at | |

**Rules**: Web and Telegram link to one Customer when identities are associated.

### Asset & Network (reference / config)

| Field | Notes |
|-------|--------|
| code | e.g. USDT, UAH, BTC, EUR |
| kind | fiat / crypto |
| networks | e.g. TRC20, ERC20, bitcoin-mainnet (crypto only) |
| decimals | Display/settlement precision |

### ExchangePair

| Field | Notes |
|-------|--------|
| id | |
| input_asset | FK/code |
| output_asset | FK/code |
| enabled | bool |
| min/max amounts | Per direction limits |
| fee/spread config refs | |

**Launch enabled**: USDT↔UAH, USDT↔BTC (both directions as separate pair rows or bidirectional flag).  
**Disabled initially**: fiat↔fiat examples (e.g. UAH↔EUR).

### PaymentMethod

| Field | Notes |
|-------|--------|
| id | |
| rail | card / iban / crypto_deposit / … |
| asset | |
| direction | payin / payout / both |
| provider_key | Adapter id |
| config | JSON (bank labels, etc.) |
| enabled | |

### Quote

| Field | Notes |
|-------|--------|
| id | |
| customer_id | Optional until confirm |
| pair_id | |
| side / input_asset / output_asset / network | Snapshot |
| input_amount / output_amount | Decimal strings |
| market_rate / final_rate | |
| fees breakdown | spread, network, service |
| expires_at | |
| created_at | |

**Rules**: Immutable after create. Order MUST reference `quote_id` and copy snapshot fields onto Order.

### Order

| Field | Notes |
|-------|--------|
| id, public_id | External-friendly id |
| customer_id | |
| quote_id | |
| pair_id | |
| input_asset, output_asset, network | Snapshot |
| input_amount, output_amount, rates, fees | Snapshot |
| status | See state machine |
| payin_method_id, payout_method_id | |
| payout_destination | Encrypted/tokenized details as appropriate |
| expires_at | Payment window |
| kill_switch / risk flags | Denormalized markers optional |
| timestamps | created, updated, completed |

### Payment

| Field | Notes |
|-------|--------|
| id | |
| order_id | |
| expected_amount / asset / network | |
| destination | Deposit address or fiat requisites |
| status | pending / detected / confirmed / mismatched / expired |
| detected_amount | |
| external_ref | Tx hash / bank ref |
| idempotency_key | Unique |

### Payout

| Field | Notes |
|-------|--------|
| id | |
| order_id | |
| amount / asset / network | |
| destination | |
| status | pending / submitted / completed / failed |
| provider | binance / hot_wallet / bank_… |
| external_ref | |
| idempotency_key | Unique |

### LedgerEntry

| Field | Notes |
|-------|--------|
| id | |
| order_id | Optional but usual |
| account | e.g. customer_payable, treasury_usdt, fees |
| amount | Signed decimal |
| asset | |
| entry_type | |
| idempotency_key | Unique |
| created_at | |

**Rules**: Append-only; corrections via reversing entries.

### AuditEvent

| Field | Notes |
|-------|--------|
| id | |
| actor_type | system / customer / operator |
| actor_id | |
| order_id | |
| action | |
| payload | Sanitized JSON |
| created_at | |

### ExceptionCase / Dispute

| Field | Notes |
|-------|--------|
| id | |
| order_id | |
| reason | mismatch / risk / payout_failed / customer_dispute / … |
| status | open / in_progress / resolved |
| assignee_operator_id | |
| resolution_notes | |

### RiskPolicy / PlatformSettings

| Field | Notes |
|-------|--------|
| kill_switch | bool |
| limits | per asset/customer/velocity |
| pair enablement | |

### OperatorUser

| Field | Notes |
|-------|--------|
| id | |
| email | |
| roles | admin / operator / viewer |
| status | |

## Order state machine

```text
CREATED
  → AWAITING_PAYMENT
  → PAYMENT_DETECTED
  → PAYMENT_CONFIRMED
  → PROCESSING
  → PAYOUT_PENDING
  → COMPLETED

From eligible states → EXPIRED | CANCELLED | FAILED | REFUNDED
PAYMENT_* / PROCESSING / PAYOUT_* → EXCEPTION (human queue) on mismatch/risk/payout failure
```

**Transition rules**:
- Only allowlisted from→to edges.
- Money-affecting transitions MUST write LedgerEntry + AuditEvent (+ outbox if notifying async).
- Happy path auto; EXCEPTION requires operator before payout completion.
- Kill-switch blocks CREATED→AWAITING_PAYMENT (or quote confirm → order create).

## Relationships (summary)

```text
Customer 1──* Order *──1 Quote
Order 1──* Payment
Order 1──* Payout
Order 1──* LedgerEntry
Order 1──* AuditEvent
Order 0..1──1 ExceptionCase
ExchangePair 1──* Quote|Order
PaymentMethod 1──* Order (payin/payout)
```

## Validation highlights

- Amounts &gt; 0; within pair min/max  
- Network required for crypto legs; address valid for asset/network  
- Quote not expired on confirm  
- Currency of Money ops must match  
- Idempotency keys unique per payment detect / payout execute  
