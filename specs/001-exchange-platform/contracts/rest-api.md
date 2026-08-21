# API Contract — REST `/api/v1`

**Feature**: `001-exchange-platform`  
**Style**: transl8-like URI versioning under `/api/v1`  
**Auth**: Bearer access token (customer or operator); Telegram bot uses service credentials or user-linked tokens issued after bot auth

Errors: JSON envelope `{ "statusCode", "message", "error", "details?" }` — no stack traces in production.

## Public / Customer

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/auth/register` | Create customer account |
| POST | `/api/v1/auth/login` | Session/JWT |
| POST | `/api/v1/auth/telegram` | Link/login via Telegram identity |
| GET | `/api/v1/me` | Current customer |
| GET | `/api/v1/pairs` | Enabled pairs + networks + limits |
| GET | `/api/v1/payment-methods` | Enabled methods for asset/direction |
| POST | `/api/v1/quotes` | Create immutable quote |
| GET | `/api/v1/quotes/:id` | Fetch quote |
| POST | `/api/v1/orders` | Confirm quote → order + payment instructions |
| GET | `/api/v1/orders` | List my orders |
| GET | `/api/v1/orders/:id` | Order detail + payment instructions + status |
| POST | `/api/v1/orders/:id/cancel` | Cancel if policy allows (pre-payment) |
| POST | `/api/v1/explain` | Sanitized explain/copy (optional flag) |

### POST `/quotes` (body sketch)

```json
{
  "inputAsset": "USDT",
  "outputAsset": "UAH",
  "network": "TRC20",
  "inputAmount": "500.00"
}
```

### POST `/orders` (body sketch)

```json
{
  "quoteId": "uuid",
  "payinMethodId": "uuid",
  "payoutMethodId": "uuid",
  "payoutDestination": { "type": "iban", "value": "…" }
}
```

## Admin / Operator

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/admin/auth/login` | Operator login |
| GET | `/api/v1/admin/orders` | Filter by status/exception |
| GET | `/api/v1/admin/orders/:id` | Detail + timeline + payments/payouts |
| POST | `/api/v1/admin/orders/:id/actions` | confirm_payment / retry_payout / resolve_exception / cancel / refund (RBAC) |
| GET | `/api/v1/admin/exceptions` | Open exception queue |
| GET | `/api/v1/admin/settings` | Kill-switch, limits |
| PATCH | `/api/v1/admin/settings` | Update kill-switch / limits |

### Admin action body sketch

```json
{
  "type": "resolve_exception",
  "note": "Customer paid remainder manually",
  "idempotencyKey": "op-…"
}
```

## Internal / Worker triggers (not public)

Enqueued jobs (not HTTP from internet):

| Job | Purpose |
|-----|---------|
| `rates.sync` | Refresh market rates |
| `quote.expire` | Mark expired quotes/orders |
| `payment.detect` | Poll/watch payin |
| `payment.confirm` | Finalize confirmation + ledger |
| `exchange.route` | Choose Binance vs hot wallet |
| `payout.execute` | Privileged send |
| `notify.send` | Web/Telegram notifications |
| `reconcile.run` | Periodic reconciliation |

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
```

Implementations: `BinanceExchangeProvider`, `HotWalletExchangeProvider`, bank/manual fiat adapters.

## OpenAPI

Generate Swagger from Nest decorators at `/api/docs` (v1) during implementation; this file is the planning contract source.
