# Data Model: Core Exchange Platform

**Feature**: `001-exchange-platform`  
**Date**: 2026-08-21  
**Aligned**: design v0.3 (2026-08-21)

## Entities

### Customer

| Field | Notes |
|-------|--------|
| id | UUID |
| email / phone | At least one identifier for web auth |
| telegram_user_id | Optional, unique when set |
| kyc_status | UNVERIFIED / PENDING / VERIFIED / REJECTED / BLOCKED (denormalized from latest KycCase; see [kyc.md](../../docs/domain/kyc.md)) |
| locale | uk / en (optional preference) |
| status | active / blocked |
| risk_level | default / elevated / blocked |
| created_at, updated_at | |

**Rules**: Web and Telegram link to one Customer when identities are associated. Order create requires `kyc_status = VERIFIED`.

### KycCase

| Field | Notes |
|-------|--------|
| id | UUID |
| customer_id | FK |
| status | UNVERIFIED / PENDING / VERIFIED / REJECTED / BLOCKED |
| provider | mock / vendor_key (TBD) |
| external_ref | Vendor case id when applicable |
| submitted_at | |
| decided_at | |
| decided_by_admin_id | Nullable until manual **admin** approve/reject |
| decision_reason | Sanitized notes |
| payload_ref | Encrypted/tokenized PII storage pointer (not raw PII in audit) |
| created_at, updated_at | |

**Rules**: One active case per customer at a time; VERIFIED required before order create. MVP: mock provider + manual admin approve/reject.

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
| min_amount / max_amount | Config placeholders per direction |
| spread_pct | e.g. 1.0 for USDT↔UAH, 0.8 for USDT↔BTC |
| service_fee_pct | e.g. 0.2 |
| min_service_fee_uah_equiv | e.g. 10 UAH equivalent (config) |
| network_fee_usdt_trc20 | Placeholder for USDT TRC20 network fee |
| network_fee_usdt_erc20 | Placeholder for USDT ERC20 network fee |

**Launch enabled**: USDT↔UAH, USDT↔BTC (both directions as separate pair rows or bidirectional flag).  
**Disabled initially**: fiat↔fiat examples (e.g. UAH↔EUR).

### PaymentMethod

| Field | Notes |
|-------|--------|
| id | |
| code | card / iban / monobank / privatbank / crypto_deposit / … |
| rail | card / iban / bank_app / crypto_deposit / … |
| asset | |
| direction | payin / payout / both |
| payment_fee_pct | e.g. 0.5 for Card, 0 for IBAN/Monobank/PrivatBank |
| provider_key | Adapter id |
| config | JSON (bank labels, etc.) |
| enabled | |

**Launch UAH seeds (enabled)**: Card, IBAN, Monobank, PrivatBank.

### Quote

| Field | Notes |
|-------|--------|
| id | |
| customer_id | Optional until confirm |
| pair_id | |
| side / input_asset / output_asset / network | Snapshot |
| input_amount / output_amount | Decimal strings |
| market_rate / final_rate | |
| fees breakdown | spread, network, service, payment_method |
| ttl_seconds | Default **120** |
| expires_at | created_at + ttl_seconds |
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
| expires_at | Payment window — **30 minutes** from AWAITING_PAYMENT |
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
| confirmed_by_operator_id | Required for final confirm (Assisted) |
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
| approved_by_operator_id | Required before execution (Assisted) |
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
| action | e.g. confirm_payment, approve_payout, kyc_decide |
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
| quote_ttl_seconds | Default **120** |
| payment_window_minutes | Default **30** |
| explain_feature_enabled | bool (prod default on if API key present) |

### OperatorUser

| Field | Notes |
|-------|--------|
| id | |
| email | |
| roles | viewer / operator / admin |
| status | |

## Order state machine

```text
CREATED
  → AWAITING_PAYMENT
  → PAYMENT_DETECTED
  → PAYMENT_CONFIRMED        ★ operator confirm_payment
  → PROCESSING
  → PAYOUT_PENDING
  → PAYOUT_APPROVED          ★ operator approve_payout
  → COMPLETED

From eligible states → EXPIRED | CANCELLED | FAILED | REFUNDED
PAYMENT_* / PROCESSING / PAYOUT_* → EXCEPTION (human queue) on mismatch/risk/payout failure
```

**Transition rules**:
- Only allowlisted from→to edges.
- Money-affecting transitions MUST write LedgerEntry + AuditEvent (+ outbox if notifying async).
- **Assisted**: confirm payment and approve payout require authorized operator; detection may auto-advance to PAYMENT_DETECTED only.
- Kill-switch blocks CREATED→AWAITING_PAYMENT (or quote confirm → order create).
- Order create gates: unexpired quote + KYC VERIFIED + kill-switch off + limits OK.

## Relationships (summary)

```text
Customer 1──* KycCase
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

- Amounts &gt; 0; within pair min/max (config placeholders)  
- Network required for crypto legs; address valid for asset/network  
- Quote not expired on confirm (120s TTL)  
- Order payment window 30 minutes from awaiting payment  
- KYC VERIFIED before order create  
- Currency of Money ops must match  
- Idempotency keys unique per payment detect / operator action / payout execute  
