Так. Тоді я б підійшов до цього як до **реального production-oriented MVP**, а не просто набору CRUD-ів. Головна мета: за мінімум часу отримати працюючий напівавтоматичний обмінник, але так, щоб через 3–6 місяців не довелося переписувати домен, платежі та order flow.

Нижче — roadmap від архітектури до конкретних модулів, БД, інтеграцій, черг, Telegram і подальшої автоматизації.

---

# 0. Яку систему ми будуємо

Я б зафіксував scope приблизно таким:

```text
┌───────────────────┐
│      CLIENT       │
└─────────┬─────────┘
│
┌──────────────┴──────────────┐
│                             │
Web App                      Telegram
│                             │
└──────────────┬──────────────┘
│
REST API
│
┌─────────▼─────────┐
│   Exchange Core  │
└─────────┬─────────┘
│
┌───────────────┬───────────┼───────────────┬──────────────┐
│               │           │               │              │
▼               ▼           ▼               ▼              ▼
Quotes          Orders      Payments         Payouts       Customers
│               │           │               │              │
└───────────────┴───────────┼───────────────┴──────────────┘
│
Event Bus
│
┌───────────────────┼───────────────────┐
▼                   ▼                   ▼
Notifications        Risk Engine          Ledger
│
┌──────┴──────┐
▼             ▼
Telegram        Email/Web
```

А оператор:

```text
┌──────────────┐
│   OPERATOR   │
└──────┬───────┘
│
Admin Dashboard
│
┌──────▼───────┐
│ Exchange API │
└──────────────┘
```

---

# 1. Найважливіше архітектурне рішення — Modular Monolith

**Не мікросервіси.**

Для MVP:

```text
Next.js
│
▼
NestJS
│
├── Auth
├── Customers
├── Quotes
├── Orders
├── Payments
├── Payouts
├── Rates
├── Exchange
├── Ledger
├── Risk
├── Notifications
├── Telegram
└── Admin
```

Одна backend application, одна PostgreSQL.

Але всередині вона поділена на **чіткі domain modules**.

Це дає нам:

* простіший deployment;
* простіший debugging;
* менше infrastructure;
* швидшу розробку;
* транзакції PostgreSQL між модулями;
* можливість пізніше винести окремий модуль у сервіс.

Наприклад:

```text
PaymentsModule
```

пізніше можна винести в:

```text
payment-service
```

без зміни всього Order domain.

---

# 2. Стек

Я б зафіксував:

| Частина       | Технологія                    |
| ------------- | ----------------------------- |
| Frontend      | Next.js + TypeScript          |
| UI            | Tailwind + shadcn/ui          |
| Backend       | NestJS + TypeScript           |
| ORM           | Prisma                        |
| DB            | PostgreSQL                    |
| Queue         | BullMQ                        |
| Queue backend | Redis                         |
| Telegram      | grammY                        |
| Validation    | Zod / class-validator         |
| Auth          | JWT + refresh token / session |
| API docs      | OpenAPI                       |
| Tests         | Vitest/Jest + Playwright      |
| Monorepo      | pnpm + Turborepo              |
| Containers    | Docker                        |
| CI/CD         | GitHub Actions                |
| Logs          | structured JSON logs          |
| Monitoring    | Sentry + metrics              |
| Storage       | S3-compatible                 |

Я б не додавав Kubernetes, Kafka, Elasticsearch та іншу інфраструктуру на старті.

---

# 3. Структура repository

Приблизно:

```text
p2p-exchange/
│
├── apps/
│   ├── web/
│   │   ├── app/
│   │   ├── components/
│   │   └── lib/
│   │
│   ├── api/
│   │   ├── src/
│   │   │   ├── auth/
│   │   │   ├── customers/
│   │   │   ├── quotes/
│   │   │   ├── orders/
│   │   │   ├── payments/
│   │   │   ├── payouts/
│   │   │   ├── rates/
│   │   │   ├── exchange/
│   │   │   ├── ledger/
│   │   │   ├── risk/
│   │   │   ├── notifications/
│   │   │   ├── telegram/
│   │   │   └── admin/
│   │   │
│   │   └── main.ts
│   │
│   └── bot/
│       └── src/
│
├── packages/
│   ├── domain/
│   ├── shared/
│   ├── config/
│   └── ui/
│
├── prisma/
│   ├── schema.prisma
│   └── migrations/
│
├── docs/
│   ├── architecture/
│   ├── specs/
│   └── adr/
│
├── docker-compose.yml
├── turbo.json
└── package.json
```

---

# 4. Domain model

Це фундамент.

Не треба починати з UI.

Спочатку треба визначити:

```text
Customer
│
└── Order
│
├── Quote
├── Payment
├── Payout
├── Transactions
└── Audit Events
```

## Основні entities

### Customer

```text
Customer
---------
id
telegram_id?
phone?
email?
status
risk_level
created_at
updated_at
```

---

### Order

```text
Order
-----
id
public_id
customer_id

side
input_asset
output_asset

input_amount
output_amount

quote_id

status

payment_method_id
payout_method_id

expires_at

created_at
updated_at
completed_at
```

---

### Quote

Quote повинен бути **snapshot**.

```text
Quote
-----
id

base_asset
quote_asset

input_amount
output_amount

market_rate
exchange_rate

spread
network_fee
payment_fee
service_fee

final_rate

expires_at
created_at
```

Наприклад:

```text
Market BTC/UAH
= 4 800 000

Spread
= 1%

Payment fee
= 0.3%

Final rate
= ...
```

Після створення Order ми більше не перераховуємо Quote.

---

# 5. Order State Machine

Це одна з найважливіших частин.

Не:

```ts
order.status = "completed"
```

де завгодно в коді.

А:

```text
CREATED
│
▼
AWAITING_PAYMENT
│
▼
PAYMENT_DETECTED
│
▼
PAYMENT_CONFIRMED
│
▼
PROCESSING
│
▼
PAYOUT_PENDING
│
▼
COMPLETED
```

Додатково:

```text
EXPIRED
CANCELLED
FAILED
REFUND_PENDING
REFUNDED
```

Наприклад:

```text
AWAITING_PAYMENT
│
├── payment detected
▼
PAYMENT_DETECTED
│
├── operator confirms
▼
PAYMENT_CONFIRMED
```

Але:

```text
COMPLETED → AWAITING_PAYMENT
```

заборонено.

Це захищає систему від великої кількості помилок.

---

# 6. Quote Engine

Це буде окремий module.

```text
RateProvider
↓
MarketRate
↓
PricingEngine
↓
Quote
```

## Rate Provider

Наприклад:

```ts
interface RateProvider {
getRate(
base: Asset,
quote: Asset
): Promise<MarketRate>;
    }
    ```

    Можна мати:

    ```text
    BinanceRateProvider
    BybitRateProvider
    CoinGeckoRateProvider
    ManualRateProvider
    ```

    Але Order domain взагалі не повинен знати, звідки прийшов rate.

    ---

    # 7. Pricing Engine

    Наприклад:

    ```text
    Market rate
    ↓
    spread
    ↓
    fixed fee
    ↓
    payment fee
    ↓
    network fee
    ↓
    final quote
    ```

    Конфіг:

    ```text
    USDT → UAH

    market rate: 41.10
    spread:       0.8%
    service fee:  0.2%
    ```

    Quote:

    ```text
    41.10
    ↓
    40.69
    ```

    Краще зберігати всі компоненти окремо.

    Тоді оператор зможе бачити:

    ```text
    Revenue
    ├── spread
    ├── service fee
    ├── payment fee
    └── network fee
    ```

    ---

    # 8. Quote expiration

    Quote не повинен жити вічно.

    Наприклад:

    ```text
    Quote TTL = 60 sec
    ```

    Frontend:

    ```text
    Rate locked for:
    00:43
    ```

    Коли закінчився:

    ```text
    QUOTE_EXPIRED
    ```

    Користувач отримує:

    > Курс змінився. Оновити пропозицію?

    Це дуже важливо для volatile assets.

    ---

    # 9. Order creation

    Frontend робить:

    ```http
    POST /quotes
    ```

    отримує:

    ```json
    {
    "quoteId": "...",
    "rate": 40.69,
    "inputAmount": 500,
    "outputAmount": 20345,
    "expiresAt": "..."
    }
    ```

    Потім:

    ```http
    POST /orders
    ```

    Backend:

    ```text
    validate customer
    ↓
    validate quote
    ↓
    validate limits
    ↓
    create order
    ↓
    reserve quote
    ↓
    create payment
    ↓
    emit OrderCreated
    ```

    ---

    # 10. Payment abstraction

    Оце дуже важливо.

    Не робити:

    ```text
    OrderService → BinanceService
    ```

    Краще:

    ```text
    OrderService
    ↓
    PaymentService
    ↓
    PaymentProvider
    ↓
    Binance / Blockchain / Bank / Manual
    ```

    Інтерфейс:

    ```ts
    interface PaymentProvider {
    createPaymentRequest(): Promise<PaymentRequest>;

        checkPayment(
        paymentId: string
        ): Promise<PaymentStatus>;

            verifyPayment(
            paymentId: string
            ): Promise<VerificationResult>;
                }
                ```

                ---

                # 11. На MVP — Manual Provider

                Я б навіть **не починав з повної автоматизації Binance**.

                Спочатку:

                ```text
                ManualPaymentProvider
                ```

                Оператор бачить:

                ```text
                Payment expected:
                500 USDT

                Network:
                TRC20

                Address:
                T...
                ```

                Користувач платить.

                Оператор:

                ```text
                [ Confirm payment ]
                ```

                Після цього система автоматично продовжує workflow.

                Це дозволить протестувати весь бізнес-процес **без складної інтеграції**.

                ---

                # 12. Потім Blockchain/Binance Provider

                Коли базовий workflow працює:

                ```text
                Payment
                ↓
                Provider
                ↓
                Blockchain/API
                ↓
                transaction detected
                ↓
                verification
                ↓
                PaymentDetected event
                ```

                І оператор вже отримує:

                > Payment detected automatically.

                А не шукає транзакцію вручну.

                ---

                # 13. Idempotency — must have

                У фінансових системах це критично.

                Уявімо:

                ```text
                POST /withdraw
                ```

                API відправив withdrawal.

                Система не отримала response.

                Відбувається retry.

                Якщо просто повторити:

                ```text
                withdraw 500 USDT
                ```

                можемо отримати **два withdrawal**.

                Тому:

                ```text
                idempotency_key
                ```

                повинен бути всюди, де є фінансова операція.

                ```text
                client request
                ↓
                idempotency key
                ↓
                DB
                ↓
                execute
                ```

                Повторний request повертає результат першого.

                ---

                # 14. Payout

                Payout — окрема entity.

                ```text
                Payout
                ------
                id
                order_id

                asset
                amount

                destination
                destination_type

                provider
                provider_reference

                status

                requested_at
                approved_at
                completed_at
                ```

                Lifecycle:

                ```text
                PENDING
                ↓
                APPROVAL_REQUIRED
                ↓
                APPROVED
                ↓
                PROCESSING
                ↓
                SENT
                ↓
                CONFIRMED
                ```

                Або:

                ```text
                FAILED
                ```

                ---

                # 15. Чому Payment і Payout окремі

                Наприклад:

                ```text
                Customer
                ↓
                500 USDT
                ↓
                Payment
                ↓
                Exchange
                ↓
                20 350 UAH
                ↓
                Payout
                ```

                Це дві різні фінансові операції.

                Не можна зберігати все як:

                ```text
                order.payment_status
                ```

                Бо потім буде неможливо нормально робити reconciliation.

                ---

                # 16. Ledger

                Я б додав його **вже в MVP**, хоча б базовий.

                Наприклад:

                ```text
                LedgerAccount

                TREASURY_USDT
                TREASURY_UAH
                CUSTOMER_USDT
                CUSTOMER_UAH
                FEES
                ```

                І операції:

                ```text
                +500 USDT
                -500 USDT

                +20 350 UAH
                -20 350 UAH

                +150 UAH fee
                ```

                Ще краще — double-entry.

                ```text
                Customer USDT      -500
                Exchange inventory +500
                ```

                потім:

                ```text
                Exchange inventory -20 350 UAH
                Customer UAH       +20 350 UAH
                ```

                Таким чином:

                ```text
                sum(debits) = sum(credits)
                ```

                і завжди можна перевірити цілісність.

                ---

                # 17. Wallet/Treasury

                Окремо від Ledger:

                ```text
                Wallet
                ------
                id
                provider
                asset
                network
                address
                balance
                status
                ```

                Наприклад:

                ```text
                Binance
                ├── USDT
                │    ├── TRC20
                │    └── ERC20
                ├── BTC
                └── ETH
                ```

                Але баланс provider не треба вважати нашим internal accounting.

                Потрібно:

                ```text
                Internal Ledger
                ↕
                Provider Balance
                ```

                і reconciliation job.

                ---

                # 18. Reconciliation

                Пізніше worker:

                ```text
                every 10 min
                ↓
                fetch Binance balances
                ↓
                fetch internal ledger
                ↓
                compare
                ↓
                difference?
                │
                ├── no → OK
                │
                └── yes → ALERT
                ```

                Це одна з тих речей, які не видно користувачу, але вони роблять фінансову систему нормальною.

                ---

                # 19. Event architecture

                Я б використав domain events.

                Наприклад:

                ```text
                OrderCreated
                QuoteCreated
                PaymentCreated
                PaymentDetected
                PaymentConfirmed
                PayoutRequested
                PayoutApproved
                PayoutSent
                OrderCompleted
                OrderCancelled
                ```

                Flow:

                ```text
                PaymentConfirmed
                │
                ├── OrderService
                │       → PROCESSING
                │
                ├── NotificationService
                │       → Telegram
                │
                ├── LedgerService
                │       → accounting entry
                │
                └── AnalyticsService
                → metrics
                ```

                ---

                # 20. Redis + BullMQ

                Не треба робити всю систему synchronous.

                Наприклад:

                ```text
                OrderCompleted
                ↓
                queue
                ↓
                Telegram notification
                ```

                Якщо Telegram лежить — order все одно completed.

                Queue jobs:

                ```text
                sendTelegramMessage
                checkPayment
                checkPayout
                expireQuote
                expireOrder
                syncRates
                syncBalances
                reconcile
                calculateRisk
                ```

                ---

                # 21. Background workers

                Наприклад:

                ### Rate worker

                ```text
                every 5 sec
                ↓
                get market prices
                ↓
                update rate cache
                ```

                ### Payment worker

                ```text
                every 10-30 sec
                ↓
                find pending payments
                ↓
                check provider
                ↓
                update payment
                ```

                ### Quote expiration

                ```text
                every minute
                ↓
                find expired quotes
                ↓
                mark expired
                ```

                ### Reconciliation

                ```text
                every 10 minutes
                ↓
                compare balances
                ```

                ---

                # 22. Telegram Bot

                Telegram я б робив не окремим «CRUD-додатком».

                Він повинен використовувати ті самі use cases:

                ```text
                Telegram
                ↓
                Application layer
                ↓
                Domain
                ```

                а не:

                ```text
                Telegram → directly DB
                ```

                Тоді:

                ```text
                Web
                Telegram
                Admin
                AI
                ```

                можуть викликати однакові application commands.

                Наприклад:

                ```text
                CreateQuote
                CreateOrder
                GetOrder
                CancelOrder
                GetCustomerOrders
                ```

                ---

                # 23. Telegram customer flow

                ### `/start`

                ```text
                💱 P2P Exchange

                Що хочете зробити?

                [ Обміняти ]
                [ Мої заявки ]
                [ Курси ]
                [ Підтримка ]
                ```

                ### Exchange

                ```text
                Що віддаєте?

                [ USDT ]
                [ BTC ]
                [ UAH ]
                ```

                ↓

                ```text
                Що отримуєте?

                [ UAH ]
                [ USDT ]
                ```

                ↓

                ```text
                Сума:
                500 USDT
                ```

                ↓

                ```text
                💱 Курс

                1 USDT = 40.69 UAH

                Ви віддаєте:
                500 USDT

                Отримаєте:
                20 345 UAH

                ⏱ Курс зафіксовано на 60 сек.

                [ Обміняти ]
                ```

                ---

                # 24. Telegram order tracking

                ```text
                📦 Order #10428

                USDT → UAH

                500 USDT
                ↓
                20 345 UAH

                Статус:
                🟡 Очікуємо оплату
                ```

                Потім:

                ```text
                🟢 Оплату отримано

                Перевіряємо транзакцію...
                ```

                Потім:

                ```text
                💸 Виплату відправлено

                20 345 UAH

                Monobank ****1234
                ```

                ---

                # 25. Telegram operator interface

                Оператор отримує:

                ```text
                🚨 New order

                #10428

                500 USDT → 20 345 UAH

                Customer:
                @username

                Payment:
                ✅ Detected

                Risk:
                🟢 LOW

                [ APPROVE ]
                [ OPEN ]
                [ REJECT ]
                ```

                Після approve:

                ```text
                Payout:

                20 345 UAH
                Monobank ****1234

                [ SEND ]
                [ CANCEL ]
                ```

                Для MVP це дуже сильна функція.

                Оператор може фактично працювати **без відкриття адмінки** для простих кейсів.

                ---

                # 26. Admin dashboard

                Я б зробив 5 головних screens.

                ### Dashboard

                ```text
                Today

                Volume
                ₴ 1 240 500

                Profit
                ₴ 18 240

                Orders
                147

                Pending
                8

                Failed
                2
                ```

                ### Orders

                Фільтри:

                ```text
                status
                asset
                payment method
                date
                customer
                amount
                operator
                ```

                ### Order detail

                ```text
                Order
                Quote
                Customer
                Payment
                Payout
                Risk
                Timeline
                Audit log
                ```

                ### Treasury

                ```text
                USDT
                BTC
                UAH

                Available
                Reserved
                Pending
                ```

                ### Settings

                ```text
                Rates
                Spreads
                Fees
                Limits
                Payment methods
                Payout methods
                Operators
                ```

                ---

                # 27. Audit Log

                Кожна важлива дія:

                ```text
                Operator Ivan
                2026-08-21 10:42

                PAYMENT_CONFIRMED

                Order #10428

                IP:
                ...

                Reason:
                Payment verified manually
                ```

                Не:

                ```text
                updated_at
                ```

                а саме immutable audit events.

                Це дуже допоможе, коли буде питання:

                > Хто і коли підтвердив цю оплату?

                ---

                # 28. Risk Engine

                MVP:

                ```text
                RiskService
                ```

                Rules:

                ```text
                amount > max_limit
                customer is new
                too many orders/hour
                too many failed payments
                destination recently changed
                manual blacklist
                ```

                Output:

                ```text
                score: 25
                level: LOW
                ```

                або:

                ```text
                score: 87
                level: HIGH
                ```

                Тоді:

                ```text
                LOW
                → automatic flow

                MEDIUM
                → operator review

                HIGH
                → blocked/manual review
                ```

                ---

                # 29. Limits

                Обов'язково мати:

                ```text
                min_order
                max_order

                daily_customer_limit
                daily_global_limit

                asset_limit
                payment_method_limit
                ```

                Наприклад:

                ```text
                USDT → UAH
                min: 50
                max: 10 000
                ```

                Це повинно бути configuration-driven.

                Не:

                ```ts
                if (amount > 10000)
                ```

                а:

                ```text
                ExchangeLimit
                ---------------
                asset_pair
                min_amount
                max_amount
                customer_limit
                daily_limit
                ```

                ---

                # 30. Customer verification

                Навіть якщо на MVP це буде мінімально.

                Структура:

                ```text
                Customer
                │
                ├── Identity
                ├── Verification
                ├── Risk
                └── Limits
                ```

                Стани:

                ```text
                UNVERIFIED
                PENDING
                VERIFIED
                REJECTED
                BLOCKED
                ```

                А конкретний рівень KYC/AML, ліцензування та допустимі платіжні/криптооперації треба окремо визначити під вашу юрисдикцію та бізнес-модель до production launch.

                ---

                # 31. AI Agent

                Тут я б зробив дуже цікаву архітектуру.

                Не:

                ```text
                LLM → database
                ```

                а:

                ```text
                AI
                │
                Tool Gateway
                │
                ┌─────────┼─────────┐
                ▼         ▼         ▼
                Orders      Quotes    Support
                ```

                Tools:

                ```text
                get_current_rate()
                create_quote()
                get_order_status()
                get_order_details()
                get_customer_orders()
                explain_fee()
                get_payment_instructions()
                create_support_ticket()
                handoff_to_operator()
                ```

                На першому етапі AI **read-only + support**.

                Потім можна додати:

                ```text
                create_order()
                cancel_order()
                ```

                але з permission layer.

                І ніколи не давати LLM напряму:

                ```text
                withdraw()
                ```

                ---

                # 32. AI як support agent

                Приклад:

                Користувач:

                > Я оплатив, чому ще не отримав гроші?

                AI:

                ```text
                → getOrderStatus()
                → getPaymentStatus()
                → getPayoutStatus()
                ```

                і відповідає:

                > Ми отримали вашу оплату. Зараз заявка знаходиться на етапі перевірки виплати. Орієнтовно наступний етап — відправлення коштів.

                Це вже реально може зняти значну частину сапорту.

                ---

                # 33. Web architecture

                На frontend я б зробив дуже простий UX.

                Homepage:

                ```text
                ┌────────────────────────────────────┐
                │             P2P Exchange            │
                │                                    │
                │  You send                          │
                │  ┌──────────────────────────────┐  │
                │  │ 500          USDT ▼          │  │
                │  └──────────────────────────────┘  │
                │                                    │
                │              ↓                     │
                │                                    │
                │  You receive                       │
                │  ┌──────────────────────────────┐  │
                │  │ 20 345       UAH ▼            │  │
                │  └──────────────────────────────┘  │
                │                                    │
                │  Rate: 40.69                       │
                │  Fee: 0.2%                         │
                │                                    │
                │       [ Continue ]                 │
                └────────────────────────────────────┘
                ```

                Не треба на першій версії робити складний dashboard для клієнта.

                ---

                # 34. API structure

                Наприклад:

                ```text
                /api/v1/auth
                /api/v1/customers
                /api/v1/quotes
                /api/v1/orders
                /api/v1/payments
                /api/v1/payouts
                /api/v1/rates
                /api/v1/payment-methods
                /api/v1/admin/orders
                /api/v1/admin/customers
                /api/v1/admin/settings
                ```

                ---

                # 35. Application layer

                Я б використовував CQRS-подібний підхід, але без фанатизму.

                Наприклад:

                ```text
                CreateQuote
                CreateOrder
                ConfirmPayment
                ApprovePayout
                CancelOrder
                CompleteOrder
                ```

                Це набагато чистіше, ніж:

                ```text
                OrderService.update(...)
                ```

                Уяви:

                ```text
                Telegram
                │
                Web
                │
                Admin
                │
                AI
                │
                └──→ CreateOrder
                │
                ▼
                OrderUseCase
                │
                ▼
                Domain Model
                ```

                Ось це і робить систему extensible.

                ---

                # 36. Що має бути автоматичним у MVP

                Я б поставив так:

                | Процес                 | MVP                     |
                | ---------------------- | ----------------------- |
                | Quote calculation      | ✅ automatic             |
                | Rate update            | ✅ automatic             |
                | Order creation         | ✅ automatic             |
                | Payment instructions   | ✅ automatic             |
                | Telegram notifications | ✅ automatic             |
                | Payment detection      | 🟡 semi-auto            |
                | Payment confirmation   | 🟡 operator             |
                | Risk check             | 🟡 automatic + operator |
                | Payout calculation     | ✅ automatic             |
                | Payout approval        | 🟡 operator             |
                | Payout execution       | 🟡 semi-auto            |
                | Ledger                 | ✅ automatic             |
                | Reconciliation         | 🟡 automatic alerts     |
                | Support                | 🟡 Telegram + human     |
                | AI                     | 🟡 optional             |

                ---

                # 37. Потім автоматизація рівнями

                Це важливо.

                Не треба переходити:

                ```text
                manual → 100% automatic
                ```

                за один раз.

                Робимо:

                ### Level 0 — Manual

                ```text
                Order
                ↓
                Operator
                ↓
                Payment
                ↓
                Operator
                ↓
                Payout
                ```

                ### Level 1 — Assisted

                ```text
                Order
                ↓
                System
                ↓
                Payment detected
                ↓
                Operator approve
                ↓
                Payout
                ```

                ### Level 2 — Automated low-risk

                ```text
                Order
                ↓
                Risk Engine
                ↓
                Payment detected
                ↓
                LOW risk?
                ├── YES → automatic
                └── NO  → operator
                ```

                ### Level 3 — Fully automated

                ```text
                Order
                ↓
                Risk
                ↓
                Payment
                ↓
                Settlement
                ↓
                Payout
                ↓
                Completed
                ```

                Це значно здоровіший шлях.

                ---

                # 38. Roadmap по етапах

                Тепер конкретно.

                ## Phase 1 — Architecture & Spec

                **Результат:** нічого ще не продаємо, але маємо повну модель системи.

                Створюємо:

                ```text
                domain model
                state machines
                API contracts
                database schema
                event catalog
                provider interfaces
                security model
                roles
                ```

                Документи:

                ```text
                docs/
                ├── architecture.md
                ├── domain-model.md
                ├── order-state-machine.md
                ├── payment-flow.md
                ├── payout-flow.md
                ├── ledger.md
                ├── security.md
                └── ADR/
                ```

                ---

                # 39. Phase 2 — Infrastructure

                ```text
                Docker
                Postgres
                Redis
                NestJS
                Next.js
                Telegram bot
                CI/CD
                Environment config
                Logging
                ```

                На цьому етапі:

                ```text
                docker compose up
                ```

                має підняти весь local environment.

                ---

                # 40. Phase 3 — Core domain

                Реалізуємо:

                ```text
                Customer
                Asset
                PaymentMethod
                PayoutMethod
                Quote
                Order
                Payment
                Payout
                Transaction
                LedgerEntry
                AuditLog
                ```

                Після цього пишемо unit tests для state transitions.

                ---

                # 41. Phase 4 — Quote + Order

                Користувач уже може:

                ```text
                select pair
                ↓
                enter amount
                ↓
                get quote
                ↓
                create order
                ↓
                receive payment instructions
                ```

                Це перший справжній vertical slice.

                ---

                # 42. Phase 5 — Admin

                Оператор може:

                ```text
                see orders
                open order
                confirm payment
                approve payout
                cancel
                refund
                see history
                ```

                На цьому етапі вже можна тестувати процес на реальних операціях у контрольованому середовищі.

                ---

                # 43. Phase 6 — Telegram

                Повний customer flow:

                ```text
                /start
                ↓
                exchange
                ↓
                quote
                ↓
                order
                ↓
                payment
                ↓
                status
                ↓
                completion
                ```

                І operator notifications.

                ---

                # 44. Phase 7 — Payment automation

                Підключаємо перший реальний provider.

                Не п'ять.

                **Один.**

                Повністю доводимо:

                ```text
                create
                detect
                verify
                confirm
                reconcile
                ```

                ---

                # 45. Phase 8 — Payout automation

                Потім:

                ```text
                Payout
                ↓
                Risk
                ↓
                Approval
                ↓
                Provider
                ↓
                Transaction
                ↓
                Confirmation
                ↓
                Ledger
                ```

                ---

                # 46. Phase 9 — Risk + Limits

                Додаємо:

                ```text
                customer limits
                order limits
                velocity
                risk score
                manual review
                blacklist
                ```

                ---

                # 47. Phase 10 — AI

                Тільки після того, як нормальний support workflow уже працює.

                ```text
                AI
                ↓
                knowledge
                ↓
                tools
                ↓
                order context
                ↓
                support
                ↓
                human handoff
                ```

                ---

                # 48. Phase 11 — Full automation

                Тоді вже можна поступово включати:

                ```text
                auto payment detection
                auto risk
                auto settlement
                auto payout
                auto reconciliation
                auto notifications
                ```

                ---

                # 49. GitHub / Spec-Driven Development

                Оскільки ти хочеш працювати через **GitHub Spec Kit**, я б не робив задачі типу:

                ```text
                Implement exchange
                ```

                Це занадто велике.

                Робимо:

                ```text
                /specs
                │
                ├── 001-create-quote
                ├── 002-create-order
                ├── 003-confirm-payment
                ├── 004-process-payout
                ├── 005-telegram-order-flow
                ├── 006-payment-detection
                └── ...
                ```

                Кожна feature має:

                ```text
                /spec.md
                /plan.md
                /tasks.md
                ```

                Наприклад:

                ```text
                001-create-quote

                /spec.md
                ```

                визначає:

                ```text
                User can request quote
                Quote contains:
                - pair
                - amount
                - rate
                - fees
                - expiration

                Quote expires after 60 seconds.
                ```

                Потім:

                ```text
                /plan.md
                ```

                визначає:

                ```text
                DB changes
                API
                domain service
                tests
                frontend
                ```

                Потім:

                ```text
                /tasks.md
                ```

                розбиває це на конкретні GitHub tasks.

                ---

                # 50. Порядок реалізації

                Ось це я вважаю найважливішим.

                Не:

                ```text
                Frontend
                → Telegram
                → Binance
                → AI
                → Admin
                ```

                А vertical slices:

                ```text
                FOUNDATION
                │
                ▼
                DOMAIN MODEL
                │
                ▼
                QUOTE + PRICING
                │
                ▼
                ORDER
                │
                ▼
                PAYMENT
                │
                ▼
                PAYOUT
                │
                ▼
                LEDGER
                │
                ┌───────────┴───────────┐
                ▼                       ▼
                ADMIN                  TELEGRAM
                │                       │
                └───────────┬───────────┘
                ▼
                AUTOMATION
                │
                ▼
                RISK
                │
                ▼
                AI
                ```

                ---

                # 51. Що НЕ робити в MVP

                Я б навмисно не робив:

                ❌ microservices
                ❌ Kubernetes
                ❌ mobile apps
                ❌ 10 exchanges
                ❌ 30 payment methods
                ❌ складний loyalty system
                ❌ referral network
                ❌ AI trader
                ❌ fully autonomous money movement
                ❌ власний blockchain
                ❌ складний analytics warehouse
                ❌ event sourcing всієї системи

                Це все може прийти після product-market fit.

                ---

                # 52. Що закласти зараз, щоб потім не переписувати

                Ось ці речі — **must have з першого дня**:

                ```text
                ✓ State machine
                ✓ Domain modules
                ✓ Provider interfaces
                ✓ Quote snapshot
                ✓ Idempotency
                ✓ Ledger
                ✓ Audit log
                ✓ Domain events
                ✓ Background jobs
                ✓ RBAC
                ✓ Risk abstraction
                ✓ Payment abstraction
                ✓ Payout abstraction
                ✓ Configuration-driven fees
                ✓ Configuration-driven limits
                ✓ API versioning
                ```

                А ось це можна відкласти:

                ```text
                AI
                advanced AML
                multiple exchanges
                multiple chains
                advanced analytics
                mobile app
                microservices
                ```

                ---

                # 53. Фінальна архітектура MVP

                У підсумку я бачу її приблизно так:

                ```text
                ┌─────────────────┐
                │      WEB        │
                └────────┬────────┘
                │
                ┌────────▼────────┐
                │    TELEGRAM     │
                └────────┬────────┘
                │
                ┌────────▼────────┐
                │    API/BFF      │
                └────────┬────────┘
                │
                ┌──────────────────────────┼─────────────────────────┐
                │                          │                         │
                ▼                          ▼                         ▼
                CUSTOMER                    QUOTES                    ORDERS
                │                         │
                ▼                         ▼
                PRICING                    PAYMENTS
                │
                ▼
                PAYOUTS
                │
                ┌───────────────────────────────────────┤
                │                                       │
                ▼                                       ▼
                RISK                                     LEDGER
                │                                       │
                └──────────────────┬────────────────────┘
                │
                DOMAIN EVENTS
                │
                ┌───────────────────┼───────────────────┐
                ▼                   ▼                   ▼
                Telegram             Queue              Audit Log
                │
                ┌──────────┼──────────┐
                ▼          ▼          ▼
                Rates      Payments   Reconcile
                │
                ▼
                PROVIDER LAYER
                │
                ┌─────────────┼─────────────┐
                ▼             ▼             ▼
                Binance      Blockchain      Bank
                ```

                І це вже архітектура, на якій можна будувати не просто MVP, а поступово **операційну систему самого обмінного бізнесу**.

                ---

                ## Який MVP я б реально взяв у перший реліз

                **Один напрямок**, наприклад:

                ```text
                USDT → UAH
                UAH → USDT
                ```

                **2–3 способи оплати/отримання**, а не десятки.

                **Web + Telegram.**

                **Одна біржа/provider.**

                **Manual approval для фінальних money-moving операцій.**

                **Автоматичні quote, order lifecycle, notifications, ledger і частина payment detection.**

                Після цього вже дивимося, де саме оператор витрачає час, і автоматизуємо **найболючіші 20% процесу**, а не будуємо automation заради automation.

                Якщо йти далі саме в такому форматі, наступний логічний крок — розписати **конкретний технічний backlog MVP від `001` до `050`: кожна feature → spec → DB tables → API → events → залежності → acceptance criteria → тести**, щоб це вже можна було безпосередньо закидати в GitHub/Spec Kit і розробляти по порядку.
