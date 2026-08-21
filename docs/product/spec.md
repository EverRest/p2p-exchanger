Так. Я б будував це не як «автоматичний обмінник», а як **напівавтоматичну P2P exchange platform**, де MVP вже має правильні доменні межі, щоб потім без переписування додати повну автоматизацію, Telegram, AI-agent, нові платіжні методи й інші біржі.

### 1. Що має вийти в MVP

Основний flow:

**Клієнт → створює заявку → отримує реквізити → оплачує → система/оператор підтверджує оплату → оператор/система виконує обмін → клієнт отримує кошти → заявка закривається.**

Напівавтоматичність означає:

* заявки створюються автоматично;
* курс і комісія рахуються автоматично;
* реквізити видаються автоматично;
* статуси змінюються автоматично;
* Telegram повідомляє про всі важливі події;
* оператор бачить заявки в адмінці;
* **критичні фінансові дії на MVP підтверджує оператор**;
* усі дії логуються.

Це набагато безпечніше для першої версії, ніж одразу намагатися автоматично рухати гроші.

---

# 2. Архітектура

Я б почав із **modular monolith**, а не мікросервісів.

```text
┌─────────────────┐
│   Web Client    │
│ Next.js         │
└────────┬────────┘
│
┌────────▼────────┐
│     API         │
│   NestJS        │
└────────┬────────┘
│
┌─────────────────────┼──────────────────────┐
│                     │                      │
┌──────▼──────┐       ┌──────▼──────┐       ┌──────▼──────┐
│   Orders    │       │   Pricing   │       │   Payments  │
│             │       │             │       │             │
└──────┬──────┘       └─────────────┘       └──────┬──────┘
│                                            │
┌──────▼──────┐       ┌─────────────┐       ┌──────▼──────┐
│   Ledger    │       │ Notifications│       │  Exchange   │
│             │       │             │       │  Providers  │
└──────┬──────┘       └──────┬──────┘       └─────────────┘
│                      │
└──────────┬───────────┘
│
┌───────▼────────┐
│   PostgreSQL   │
└────────────────┘

┌────────────────┐
│ Redis / Queue  │
└───────┬────────┘
│
┌───────▼────────┐
│ Telegram Bot   │
└────────────────┘
```

### Стек

Я б взяв:

**Frontend**

* Next.js
* TypeScript
* Tailwind
* shadcn/ui

**Backend**

* NestJS
* TypeScript
* Prisma
* PostgreSQL
* Redis
* BullMQ

**Bot**

* grammY або Telegraf

**Infra**

* Docker
* GitHub Actions
* VPS / cloud
* S3-compatible storage для документів/скріншотів

Це достатньо простий стек, але не «іграшковий».

---

# 3. Головне — правильно спроєктувати домен

Не роби одну таблицю `orders` із 50 статусами.

Я б розділив:

```text
User
Customer
Order
Quote
Payment
Payout
Wallet
Transaction
LedgerEntry
ExchangeRate
PaymentMethod
Notification
OperatorAction
AuditLog
```

Наприклад:

```text
Order
├── Quote
├── Payment
├── Payout
├── Transactions
├── Notifications
└── AuditLog
```

### Order lifecycle

```text
DRAFT
↓
CREATED
↓
AWAITING_PAYMENT
↓
PAYMENT_DETECTED
↓
PAYMENT_CONFIRMED
↓
PROCESSING
↓
PAYOUT_PENDING
↓
COMPLETED
```

І окремі terminal/error states:

```text
EXPIRED
CANCELLED
REFUNDED
FAILED
```

**Важливо:** статуси повинні переходити через state machine, а не через довільні `order.status = ...`.

---

# 4. MVP Phase 0 — фундамент

Спочатку:

### Repository

```text
/apps
/web
/api
/bot

/packages
/shared
/config
/domain
/ui

/infrastructure
docker-compose.yml
```

Monorepo через Turborepo/pnpm.

### Backend modules

```text
auth
users
customers
orders
quotes
payments
payouts
rates
wallets
notifications
telegram
audit
admin
```

---

# 5. MVP Phase 1 — Quote Engine

Це одна з найважливіших частин.

Користувач вводить:

```text
Віддаю:
1000 USDT

Отримую:
UAH

Метод:
Monobank
```

Backend:

```text
market rate
↓
spread
↓
payment method fee
↓
network fee
↓
final quote
```

Наприклад:

```text
Market rate:       41.20
Spread:             0.80%
Payment fee:        0.30%
Final rate:        40.75

1000 USDT
↓
40 750 UAH
```

Quote повинен бути **immutable**.

Тобто якщо курс змінився через 5 хвилин, старий order не повинен раптом отримати новий курс.

```text
Quote
id
base_asset
quote_asset
amount
rate
fees
expires_at
created_at
```

---

# 6. MVP Phase 2 — Order Engine

Користувач:

```text
1. Вибирає напрямок
2. Вводить суму
3. Отримує quote
4. Вводить реквізити
5. Створює order
```

Система генерує:

```text
ORDER #10428

USDT → UAH

Amount:
500 USDT

You receive:
20 375 UAH

Payment:
USDT TRC20

Payout:
Monobank ****1234

Status:
Awaiting payment
```

---

# 7. MVP Phase 3 — Payment detection

Тут починається «напівавтомат».

Не робив би одразу 20 інтеграцій.

Спочатку зробити abstraction:

```ts
interface PaymentProvider {
createPayment(): Promise<Payment>;
    getPaymentStatus(): Promise<PaymentStatus>;
        verifyPayment(): Promise<VerificationResult>;
            }
            ```

            Тоді:

            ```text
            PaymentProvider
            │
            ├── Binance
            ├── Crypto wallet
            ├── Manual
            └── Future providers
            ```

            На MVP можна навіть мати:

            ```text
            MANUAL_PAYMENT
            ```

            Оператор натискає:

            > Confirm payment

            А система вже все інше робить сама.

            ---

            # 8. MVP Phase 4 — Crypto

            Якщо орієнтир — Binance/P2P, я б **не прив'язував domain logic напряму до Binance API**.

            Зробити:

            ```text
            ExchangeProvider
            ```

            і:

            ```text
            BinanceProvider
            ```

            Наприклад:

            ```ts
            interface ExchangeProvider {
            getBalance(asset): Promise<Balance>;
                getDepositAddress(asset, network): Promise<Address>;
                    getDepositTransactions(...): Promise<Transaction[]>;
                    createWithdrawal(...): Promise<Withdrawal>;
                        getWithdrawalStatus(...): Promise<WithdrawalStatus>;
                            }
                            ```

                            Тоді пізніше:

                            ```text
                            Binance
                            Bybit
                            OKX
                            Own wallet
                            ```

                            можуть бути взаємозамінними.

                            ---

                            # 9. MVP Phase 5 — Admin Panel

                            Це фактично серце напівавтоматичного бізнесу.

                            Оператор бачить:

                            ```text
                            ┌──────────────────────────────────────────┐
                            │ Orders                                   │
                            ├──────────────────────────────────────────┤
                            │ #10428  USDT → UAH    500    PROCESSING │
                            │ #10429  UAH → USDT    25k    PAYMENT    │
                            │ #10430  USDT → UAH    1200   COMPLETED  │
                            └──────────────────────────────────────────┘
                            ```

                            Order detail:

                            ```text
                            Customer
                            Order
                            Quote
                            Payment
                            Payout
                            Risk
                            Timeline
                            Notes
                            Audit log
                            ```

                            І action buttons:

                            ```text
                            ✓ Confirm payment
                            ✓ Approve exchange
                            ✓ Mark payout sent
                            ✕ Cancel
                            ↩ Refund
                            ```

                            ---

                            # 10. Telegram Bot

                            Я б не робив Telegram просто як notification bot.

                            Він має бути **другим інтерфейсом продукту**.

                            ### Customer

                            ```text
                            /start

                            💱 Обміняти
                            📋 Мої заявки
                            💰 Курси
                            🆘 Підтримка
                            ```

                            Створення заявки:

                            ```text
                            💱 Що продаєте?

                            [ USDT ]
                            [ BTC ]
                            [ UAH ]
                            ```

                            ↓

                            ```text
                            Скільки?

                            [ 500 USDT ]
                            ```

                            ↓

                            ```text
                            Отримаєте приблизно:

                            20 375 UAH

                            Курс: 40.75

                            [ Продовжити ]
                            ```

                            ↓

                            ```text
                            Надайте картку для виплати
                            ```

                            ↓

                            ```text
                            Order #10428 створено

                            Оплатіть:

                            500 USDT
                            TRC20

                            Address:
                            T...
                            ```

                            ↓

                            ```text
                            ⏳ Очікуємо оплату
                            ```

                            ↓

                            ```text
                            ✅ Оплату отримано

                            Ваша заявка обробляється.
                            ```

                            ↓

                            ```text
                            💸 Виплату відправлено

                            20 375 UAH
                            ```

                            ---

                            # 11. Telegram для оператора

                            Оце може бути дуже сильним MVP-фічером.

                            Наприклад:

                            ```text
                            🚨 NEW PAYMENT

                            Order #10428

                            500 USDT → 20 375 UAH

                            Customer:
                            @user

                            Payment:
                            Detected ✓

                            Payout:
                            Monobank ****1234

                            [ CONFIRM ]
                            [ OPEN ORDER ]
                            [ REJECT ]
                            ```

                            Оператор буквально може працювати з телефону.

                            ---

                            # 12. Notification Engine

                            Не робити Telegram calls прямо всередині `OrderService`.

                            Замість цього:

                            ```text
                            OrderService
                            ↓
                            Domain Event
                            ↓
                            Event Handler
                            ↓
                            NotificationService
                            ↓
                            Telegram
                            Email
                            Web Push
                            ```

                            Events:

                            ```text
                            OrderCreated
                            PaymentDetected
                            PaymentConfirmed
                            PayoutStarted
                            PayoutCompleted
                            OrderExpired
                            OrderCancelled
                            ```

                            Це дуже допоможе при масштабуванні.

                            ---

                            # 13. Ledger — закласти одразу

                            Навіть якщо MVP ще не потребує повноцінної бухгалтерії.

                            Не роби:

                            ```text
                            balance = balance + 500
                            ```

                            Краще:

                            ```text
                            Ledger

                            +500 USDT
                            -500 USDT
                            +20375 UAH
                            -20375 UAH
                            ```

                            тобто double-entry / append-only accounting model.

                            Пізніше це дозволить побудувати:

                            * P&L;
                            * баланс;
                            * прибуток по ордерах;
                            * прибуток по напрямках;
                            * reconciliation;
                            * operator accounting;
                            * treasury management.

                            ---

                            # 14. Security

                            Для фінансового продукту це треба закладати з першого дня.

                            ### Обов'язково:

                            * RBAC;
                            * operator/admin roles;
                            * 2FA для адмінів;
                            * audit log;
                            * idempotency keys;
                            * rate limiting;
                            * webhook signature verification;
                            * encrypted secrets;
                            * encrypted sensitive customer data;
                            * immutable orders/quotes;
                            * withdrawal approval;
                            * transaction limits.

                            Особливо:

                            ```text
                            API request
                            ↓
                            Idempotency key
                            ↓
                            Transaction
                            ↓
                            External provider
                            ↓
                            Webhook
                            ↓
                            Idempotent handler
                            ```

                            Щоб retry не відправив гроші двічі.

                            ---

                            # 15. Risk Engine

                            Не обов'язково повноцінний AML engine у MVP.

                            Але зробити abstraction:

                            ```text
                            RiskEngine
                            ```

                            який повертає:

                            ```text
                            LOW
                            MEDIUM
                            HIGH
                            BLOCKED
                            ```

                            На MVP правила можуть бути примітивні:

                            ```text
                            amount > limit
                            new customer
                            multiple failed payments
                            suspicious velocity
                            manual flag
                            ```

                            Пізніше туди можна підключити зовнішні compliance/risk providers.

                            ---

                            # 16. AI Agent — не викидав би з архітектури

                            Ти раніше питав про AI-сапорт — я б його **заклав архітектурно, але не робив core MVP-фічею**.

                            Наприклад:

                            ```text
                            User
                            ↓
                            Telegram/Web
                            ↓
                            AI Agent
                            ├── FAQ
                            ├── Order status
                            ├── Explain fees
                            ├── Explain payment
                            ├── Collect information
                            └── Escalate to operator
                            ```

                            Але агент **не має напряму мати право рухати гроші**.

                            Правильна модель:

                            ```text
                            AI
                            ↓
                            Tool
                            ↓
                            Permission layer
                            ↓
                            Domain service
                            ```

                            Наприклад:

                            ```text
                            AI: "Покажи статус заявки"

                            → getOrderStatus(orderId)
                            ```

                            але:

                            ```text
                            AI: "Відправ 500 USDT"

                            → ❌ direct execution
                            ```

                            замість цього:

                            ```text
                            AI
                            ↓
                            createWithdrawalRequest
                            ↓
                            operator approval
                            ↓
                            execution
                            ```

                            ---

                            # 17. Roadmap

                            Я б розбив роботу так:

                            ### Milestone 1 — Foundation

                            * [ ] Monorepo
                            * [ ] Docker
                            * [ ] PostgreSQL
                            * [ ] Redis
                            * [ ] NestJS
                            * [ ] Next.js
                            * [ ] Prisma
                            * [ ] CI/CD
                            * [ ] env/secrets management
                            * [ ] logging
                            * [ ] error handling

                            ### Milestone 2 — Core domain

                            * [ ] User
                            * [ ] Customer
                            * [ ] Order
                            * [ ] Quote
                            * [ ] Payment
                            * [ ] Payout
                            * [ ] Transaction
                            * [ ] Ledger
                            * [ ] State machine
                            * [ ] Audit log

                            ### Milestone 3 — Exchange logic

                            * [ ] Rate provider
                            * [ ] Quote engine
                            * [ ] Spread
                            * [ ] Fees
                            * [ ] Quote expiration
                            * [ ] Order creation
                            * [ ] Order lifecycle

                            ### Milestone 4 — Manual operations

                            * [ ] Admin authentication
                            * [ ] Orders dashboard
                            * [ ] Order detail
                            * [ ] Confirm payment
                            * [ ] Approve payout
                            * [ ] Cancel
                            * [ ] Refund
                            * [ ] Operator notes
                            * [ ] Audit timeline

                            ### Milestone 5 — Semi-automation

                            * [ ] Payment provider abstraction
                            * [ ] Binance integration
                            * [ ] Blockchain monitoring
                            * [ ] Deposit detection
                            * [ ] Webhooks
                            * [ ] Automatic status updates
                            * [ ] Automatic notifications
                            * [ ] Automatic quote refresh

                            ### Milestone 6 — Telegram

                            * [ ] Customer bot
                            * [ ] Order creation
                            * [ ] Order status
                            * [ ] Payment instructions
                            * [ ] Notifications
                            * [ ] Operator bot
                            * [ ] Inline actions
                            * [ ] Deep links

                            ### Milestone 7 — Risk

                            * [ ] Limits
                            * [ ] Velocity checks
                            * [ ] Customer flags
                            * [ ] Risk score
                            * [ ] Manual review
                            * [ ] Transaction limits

                            ### Milestone 8 — AI

                            * [ ] AI support
                            * [ ] Order lookup tool
                            * [ ] FAQ knowledge base
                            * [ ] Payment explanation
                            * [ ] Human handoff
                            * [ ] AI action permissions

                            ---

                            # 18. А ось як я б виглядав MVP v1

                            ```text
                            CUSTOMER
                            │
                            ┌─────────┴─────────┐
                            │                   │
                            WEB              TELEGRAM
                            │                   │
                            └─────────┬─────────┘
                            │
                            ▼
                            ┌──────────────┐
                            │     API      │
                            │   NestJS     │
                            └──────┬───────┘
                            │
                            ┌───────────────┼────────────────┐
                            ▼               ▼                ▼
                            QUOTES           ORDERS          PAYMENTS
                            │               │                │
                            └───────────────┼────────────────┘
                            │
                            ┌────▼─────┐
                            │  LEDGER  │
                            └────┬─────┘
                            │
                            ┌───────┴────────┐
                            ▼                ▼
                            Binance/API       Operator
                            │
                            ┌─────▼─────┐
                            │  ADMIN    │
                            └───────────┘
                            ```

                            І головний принцип:

                            > **Автоматизуємо workflow, але не автоматизуємо безконтрольно рух грошей.**

                            Це дозволить запустити MVP досить швидко, а потім поступово перетворювати його на повністю автоматичний exchange без переписування core.

                            ### Я б наступним кроком зробив уже не загальну roadmap, а **технічну карту реалізації**:

                            `epics → modules → DB schema → API endpoints → events → integrations → dependencies → порядок розробки`

                            і саме під **Spec-Driven Development + GitHub Spec Kit**, про який ти згадував раніше. Це дасть нам фактично backlog, за яким можна починати писати MVP.
