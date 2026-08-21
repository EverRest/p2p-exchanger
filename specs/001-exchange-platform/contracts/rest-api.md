# API Contract — REST `/api/v1`

**Feature**: `001-exchange-platform`  
**Style**: transl8-like URI versioning under `/api/v1`  
**Auth**: Bearer access token (customer or operator); Telegram bot uses service credentials or user-linked tokens issued after bot auth  
**Aligned**: design v0.3 (Assisted settlement, KYC gate, RBAC)

Errors: JSON envelope `{ "statusCode", "message", "error", "details?" }` — no stack traces in production.

## Public / Customer

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/auth/register` | Create customer account |
| POST | `/api/v1/auth/login` | Session/JWT |
| POST | `/api/v1/auth/telegram` | Link/login via Telegram identity |
| GET | `/api/v1/me` | Current customer (includes kycStatus summary) |
| POST | `/api/v1/kyc/submissions` | Start KYC (mock/vendor orchestration) |
| GET | `/api/v1/kyc/status` | Current KYC status for authenticated customer |
| GET | `/api/v1/pairs` | Enabled pairs + networks + limits |
| GET | `/api/v1/payment-methods` | Enabled methods for asset/direction (Card, IBAN, Monobank, PrivatBank for UAH) |
| POST | `/api/v1/quotes` | Create immutable quote (120s TTL) |
| GET | `/api/v1/quotes/:id` | Fetch quote |
| POST | `/api/v1/orders` | Confirm quote → order + payment instructions (**403 if KYC not VERIFIED**) |
| GET | `/api/v1/orders` | List my orders |
| GET | `/api/v1/orders/:id` | Order detail + payment instructions + status (includes PAYOUT_APPROVED) |
| POST | `/api/v1/orders/:id/cancel` | Cancel if policy allows (pre-payment) |
| POST | `/api/v1/explain` | Sanitized explain/copy (feature flag; allowlisted context only) |

### POST `/quotes` (body sketch)

```json
{
  "inputAsset": "USDT",
  "outputAsset": "UAH",
  "network": "TRC20",
  "inputAmount": "500.00"
}
```

Response includes `expiresAt` (~120s from create) and fee breakdown per corridor config.

### POST `/orders` (body sketch)

```json
{
  "quoteId": "uuid",
  "payinMethodId": "uuid",
  "payoutMethodId": "uuid",
  "payoutDestination": { "type": "iban", "value": "…" }
}
```

**KYC gate**: Returns **403 Forbidden** with actionable error when customer `kycStatus !== VERIFIED`. Does not create an order.

### POST `/kyc/submissions` (body sketch)

```json
{
  "documentType": "passport",
  "idempotencyKey": "kyc-…"
}
```

Returns case id and status `pending` / `in_review`.

### GET `/kyc/status`

Returns `{ "status": "pending|in_review|verified|rejected|expired", "caseId": "…", "updatedAt": "…" }`.

### POST `/explain` (body sketch)

```json
{
  "context": "order_status",
  "orderId": "uuid",
  "locale": "uk"
}
```

Feature-flagged; must not access DB/PII beyond allowlisted sanitized fields; must not claim unconfirmed payment.

## Admin / Operator

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/admin/auth/login` | Operator login |
| GET | `/api/v1/admin/orders` | Filter by status/exception |
| GET | `/api/v1/admin/orders/:id` | Detail + timeline + payments/payouts |
| POST | `/api/v1/admin/orders/:id/actions` | Operator actions (RBAC): `confirm_payment`, `approve_payout`, `retry_payout`, `resolve_exception`, `cancel`, `refund` |
| POST | `/api/v1/admin/kyc/:id/decide` | Manual approve/reject KYC case (admin; operator per RBAC policy) |
| GET | `/api/v1/admin/exceptions` | Open exception queue |
| GET | `/api/v1/admin/settings` | Kill-switch, limits, quote TTL, payment window, fees |
| PATCH | `/api/v1/admin/settings` | Update kill-switch / limits / fee config (admin) |

### Admin order action body sketch

```json
{
  "type": "confirm_payment",
  "note": "Bank ref matched",
  "idempotencyKey": "op-…"
}
```

```json
{
  "type": "approve_payout",
  "note": "Payout authorized",
  "idempotencyKey": "op-…"
}
```

**RBAC**:
- **viewer**: GET endpoints only  
- **operator**: `confirm_payment`, `approve_payout`, exception queue actions  
- **admin**: settings, kill-switch, fee/config, operator user management, KYC decide (if not delegated to operator)

### POST `/admin/kyc/:id/decide` (body sketch)

```json
{
  "decision": "verified",
  "reason": "Documents OK",
  "idempotencyKey": "kyc-decide-…"
}
```

## Internal / Worker triggers (not public)

Enqueued jobs (not HTTP from internet):

| Job | Purpose |
|-----|---------|
| `rates.sync` | Refresh market rates |
| `quote.expire` | Mark expired quotes (120s TTL) |
| `order.expire` | Mark orders past 30m payment window |
| `payment.detect` | Poll/watch payin (advances to PAYMENT_DETECTED only) |
| `exchange.route` | Choose Binance vs hot wallet |
| `payout.execute` | Privileged send (after operator approve_payout) |
| `notify.send` | Web/Telegram notifications |
| `reconcile.run` | Periodic reconciliation |

Note: `payment.confirm` and payout approval are **operator HTTP actions**, not autonomous worker finalization on the happy path.

## Provider ports (internal TypeScript contracts)

```ts
interface RateProvider {
  getRate(input: AssetRef, output: AssetRef): Promise<RateQuote>;
}

interface ExchangeProvider {
  getDepositAddress(asset: AssetRef, network: string): Promise<Address>;
  listDeposits(filter: DepositFilter): Promise<Deposit[]>;
  withdraw(req: WithdrawRequest): Promise<WithdrawResult>;
  getBalances(): Promise<Balance[]>;
}

interface PaymentProvider {
  createPayinInstructions(order: OrderSnapshot): Promise<PayinInstructions>;
  verifyPayin(ref: string): Promise<PayinVerification>;
}

interface PayoutProvider {
  executePayout(req: PayoutRequest): Promise<PayoutResult>;
}

interface KycProvider {
  submitCase(req: KycSubmitRequest): Promise<KycCaseRef>;
  getStatus(caseRef: string): Promise<KycStatus>;
}
```

Implementations: `BinanceExchangeProvider`, `HotWalletExchangeProvider`, bank/manual fiat adapters, `MockKycProvider` (MVP).

## OpenAPI

Generate Swagger from Nest decorators at `/api/docs` (v1) during implementation; this file is the planning contract source.
