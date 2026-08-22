-- CreateEnum
CREATE TYPE "AssetKind" AS ENUM ('FIAT', 'CRYPTO');

-- CreateEnum
CREATE TYPE "CustomerStatus" AS ENUM ('ACTIVE', 'BLOCKED');

-- CreateEnum
CREATE TYPE "CustomerRiskLevel" AS ENUM ('DEFAULT', 'ELEVATED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "CustomerLocale" AS ENUM ('UK', 'EN');

-- CreateEnum
CREATE TYPE "KycStatus" AS ENUM ('UNVERIFIED', 'PENDING', 'VERIFIED', 'REJECTED', 'BLOCKED');

-- CreateEnum
CREATE TYPE "PaymentDirection" AS ENUM ('PAYIN', 'PAYOUT', 'BOTH');

-- CreateEnum
CREATE TYPE "OrderStatus" AS ENUM ('CREATED', 'AWAITING_PAYMENT', 'PAYMENT_DETECTED', 'PAYMENT_CONFIRMED', 'PROCESSING', 'PAYOUT_PENDING', 'PAYOUT_APPROVED', 'COMPLETED', 'EXPIRED', 'CANCELLED', 'REFUNDED', 'FAILED');

-- CreateEnum
CREATE TYPE "PaymentStatus" AS ENUM ('PENDING', 'DETECTED', 'CONFIRMED', 'MISMATCHED', 'EXPIRED');

-- CreateEnum
CREATE TYPE "PayoutStatus" AS ENUM ('PENDING', 'SUBMITTED', 'COMPLETED', 'FAILED');

-- CreateEnum
CREATE TYPE "ExceptionStatus" AS ENUM ('OPEN', 'IN_PROGRESS', 'RESOLVED');

-- CreateEnum
CREATE TYPE "ActorType" AS ENUM ('SYSTEM', 'CUSTOMER', 'OPERATOR');

-- CreateEnum
CREATE TYPE "OperatorRole" AS ENUM ('VIEWER', 'OPERATOR', 'ADMIN');

-- CreateEnum
CREATE TYPE "OperatorStatus" AS ENUM ('ACTIVE', 'DISABLED');

-- CreateTable
CREATE TABLE "assets" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "kind" "AssetKind" NOT NULL,
    "decimals" INTEGER NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "assets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "asset_networks" (
    "id" UUID NOT NULL,
    "asset_id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "asset_networks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exchange_pairs" (
    "id" UUID NOT NULL,
    "input_asset_id" UUID NOT NULL,
    "output_asset_id" UUID NOT NULL,
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "min_amount" DECIMAL(36,18),
    "max_amount" DECIMAL(36,18),
    "spread_pct" DECIMAL(8,4) NOT NULL DEFAULT 0,
    "service_fee_pct" DECIMAL(8,4) NOT NULL DEFAULT 0,
    "min_service_fee_uah_equiv" DECIMAL(36,2),
    "network_fee_usdt_trc20" DECIMAL(36,18),
    "network_fee_usdt_erc20" DECIMAL(36,18),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "exchange_pairs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payment_methods" (
    "id" UUID NOT NULL,
    "code" TEXT NOT NULL,
    "rail" TEXT NOT NULL,
    "asset_id" UUID NOT NULL,
    "direction" "PaymentDirection" NOT NULL,
    "payment_fee_pct" DECIMAL(8,4) NOT NULL DEFAULT 0,
    "provider_key" TEXT NOT NULL,
    "config" JSONB NOT NULL DEFAULT '{}',
    "enabled" BOOLEAN NOT NULL DEFAULT false,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payment_methods_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "platform_settings" (
    "id" TEXT NOT NULL DEFAULT 'default',
    "kill_switch" BOOLEAN NOT NULL DEFAULT false,
    "limits" JSONB NOT NULL DEFAULT '{}',
    "quote_ttl_seconds" INTEGER NOT NULL DEFAULT 120,
    "payment_window_minutes" INTEGER NOT NULL DEFAULT 30,
    "explain_feature_enabled" BOOLEAN NOT NULL DEFAULT true,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "customers" (
    "id" UUID NOT NULL,
    "email" TEXT,
    "phone" TEXT,
    "password_hash" TEXT,
    "telegram_user_id" TEXT,
    "kyc_status" "KycStatus" NOT NULL DEFAULT 'UNVERIFIED',
    "locale" "CustomerLocale",
    "status" "CustomerStatus" NOT NULL DEFAULT 'ACTIVE',
    "risk_level" "CustomerRiskLevel" NOT NULL DEFAULT 'DEFAULT',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "customers_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kyc_cases" (
    "id" UUID NOT NULL,
    "customer_id" UUID NOT NULL,
    "status" "KycStatus" NOT NULL DEFAULT 'PENDING',
    "provider" TEXT NOT NULL DEFAULT 'mock',
    "external_ref" TEXT,
    "submitted_at" TIMESTAMP(3),
    "decided_at" TIMESTAMP(3),
    "decided_by_admin_id" UUID,
    "decision_reason" TEXT,
    "payload_ref" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kyc_cases_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "operator_users" (
    "id" UUID NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "roles" "OperatorRole"[],
    "status" "OperatorStatus" NOT NULL DEFAULT 'ACTIVE',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "operator_users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "quotes" (
    "id" UUID NOT NULL,
    "customer_id" UUID,
    "pair_id" UUID NOT NULL,
    "side" TEXT NOT NULL,
    "input_asset" TEXT NOT NULL,
    "output_asset" TEXT NOT NULL,
    "network" TEXT,
    "input_amount" DECIMAL(36,18) NOT NULL,
    "output_amount" DECIMAL(36,18) NOT NULL,
    "market_rate" DECIMAL(36,18) NOT NULL,
    "final_rate" DECIMAL(36,18) NOT NULL,
    "fees" JSONB NOT NULL DEFAULT '{}',
    "ttl_seconds" INTEGER NOT NULL DEFAULT 120,
    "expires_at" TIMESTAMP(3) NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "quotes_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "orders" (
    "id" UUID NOT NULL,
    "public_id" TEXT NOT NULL,
    "customer_id" UUID NOT NULL,
    "quote_id" UUID NOT NULL,
    "pair_id" UUID NOT NULL,
    "input_asset" TEXT NOT NULL,
    "output_asset" TEXT NOT NULL,
    "network" TEXT,
    "input_amount" DECIMAL(36,18) NOT NULL,
    "output_amount" DECIMAL(36,18) NOT NULL,
    "market_rate" DECIMAL(36,18) NOT NULL,
    "final_rate" DECIMAL(36,18) NOT NULL,
    "fees" JSONB NOT NULL DEFAULT '{}',
    "status" "OrderStatus" NOT NULL DEFAULT 'CREATED',
    "payin_method_id" UUID,
    "payout_method_id" UUID,
    "payout_destination" JSONB,
    "expires_at" TIMESTAMP(3),
    "kill_switch_at_create" BOOLEAN NOT NULL DEFAULT false,
    "completed_at" TIMESTAMP(3),
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "orders_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payments" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "expected_amount" DECIMAL(36,18) NOT NULL,
    "asset" TEXT NOT NULL,
    "network" TEXT,
    "destination" JSONB NOT NULL,
    "status" "PaymentStatus" NOT NULL DEFAULT 'PENDING',
    "detected_amount" DECIMAL(36,18),
    "confirmed_by_operator_id" UUID,
    "external_ref" TEXT,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "payouts" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "amount" DECIMAL(36,18) NOT NULL,
    "asset" TEXT NOT NULL,
    "network" TEXT,
    "destination" JSONB NOT NULL,
    "status" "PayoutStatus" NOT NULL DEFAULT 'PENDING',
    "approved_by_operator_id" UUID,
    "provider" TEXT,
    "external_ref" TEXT,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "payouts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ledger_entries" (
    "id" UUID NOT NULL,
    "order_id" UUID,
    "account" TEXT NOT NULL,
    "amount" DECIMAL(36,18) NOT NULL,
    "asset" TEXT NOT NULL,
    "entry_type" TEXT NOT NULL,
    "idempotency_key" TEXT NOT NULL,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ledger_entries_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_events" (
    "id" UUID NOT NULL,
    "actor_type" "ActorType" NOT NULL,
    "actor_id" TEXT,
    "order_id" UUID,
    "action" TEXT NOT NULL,
    "payload" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "exception_cases" (
    "id" UUID NOT NULL,
    "order_id" UUID NOT NULL,
    "reason" TEXT NOT NULL,
    "status" "ExceptionStatus" NOT NULL DEFAULT 'OPEN',
    "assignee_operator_id" UUID,
    "resolution_notes" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "exception_cases_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "assets_code_key" ON "assets"("code");

-- CreateIndex
CREATE UNIQUE INDEX "asset_networks_asset_id_code_key" ON "asset_networks"("asset_id", "code");

-- CreateIndex
CREATE UNIQUE INDEX "exchange_pairs_input_asset_id_output_asset_id_key" ON "exchange_pairs"("input_asset_id", "output_asset_id");

-- CreateIndex
CREATE UNIQUE INDEX "payment_methods_code_key" ON "payment_methods"("code");

-- CreateIndex
CREATE UNIQUE INDEX "customers_email_key" ON "customers"("email");

-- CreateIndex
CREATE UNIQUE INDEX "customers_phone_key" ON "customers"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "customers_telegram_user_id_key" ON "customers"("telegram_user_id");

-- CreateIndex
CREATE INDEX "kyc_cases_customer_id_status_idx" ON "kyc_cases"("customer_id", "status");

-- CreateIndex
CREATE UNIQUE INDEX "operator_users_email_key" ON "operator_users"("email");

-- CreateIndex
CREATE UNIQUE INDEX "orders_public_id_key" ON "orders"("public_id");

-- CreateIndex
CREATE INDEX "orders_customer_id_status_idx" ON "orders"("customer_id", "status");

-- CreateIndex
CREATE INDEX "orders_status_created_at_idx" ON "orders"("status", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "payments_idempotency_key_key" ON "payments"("idempotency_key");

-- CreateIndex
CREATE INDEX "payments_order_id_idx" ON "payments"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "payouts_idempotency_key_key" ON "payouts"("idempotency_key");

-- CreateIndex
CREATE INDEX "payouts_order_id_idx" ON "payouts"("order_id");

-- CreateIndex
CREATE UNIQUE INDEX "ledger_entries_idempotency_key_key" ON "ledger_entries"("idempotency_key");

-- CreateIndex
CREATE INDEX "ledger_entries_order_id_idx" ON "ledger_entries"("order_id");

-- CreateIndex
CREATE INDEX "ledger_entries_account_asset_idx" ON "ledger_entries"("account", "asset");

-- CreateIndex
CREATE INDEX "audit_events_order_id_created_at_idx" ON "audit_events"("order_id", "created_at");

-- CreateIndex
CREATE UNIQUE INDEX "exception_cases_order_id_key" ON "exception_cases"("order_id");

-- CreateIndex
CREATE INDEX "exception_cases_status_created_at_idx" ON "exception_cases"("status", "created_at");

-- AddForeignKey
ALTER TABLE "asset_networks" ADD CONSTRAINT "asset_networks_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exchange_pairs" ADD CONSTRAINT "exchange_pairs_input_asset_id_fkey" FOREIGN KEY ("input_asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exchange_pairs" ADD CONSTRAINT "exchange_pairs_output_asset_id_fkey" FOREIGN KEY ("output_asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payment_methods" ADD CONSTRAINT "payment_methods_asset_id_fkey" FOREIGN KEY ("asset_id") REFERENCES "assets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kyc_cases" ADD CONSTRAINT "kyc_cases_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kyc_cases" ADD CONSTRAINT "kyc_cases_decided_by_admin_id_fkey" FOREIGN KEY ("decided_by_admin_id") REFERENCES "operator_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotes" ADD CONSTRAINT "quotes_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "quotes" ADD CONSTRAINT "quotes_pair_id_fkey" FOREIGN KEY ("pair_id") REFERENCES "exchange_pairs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_customer_id_fkey" FOREIGN KEY ("customer_id") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_quote_id_fkey" FOREIGN KEY ("quote_id") REFERENCES "quotes"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_pair_id_fkey" FOREIGN KEY ("pair_id") REFERENCES "exchange_pairs"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_payin_method_id_fkey" FOREIGN KEY ("payin_method_id") REFERENCES "payment_methods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "orders" ADD CONSTRAINT "orders_payout_method_id_fkey" FOREIGN KEY ("payout_method_id") REFERENCES "payment_methods"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payments" ADD CONSTRAINT "payments_confirmed_by_operator_id_fkey" FOREIGN KEY ("confirmed_by_operator_id") REFERENCES "operator_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payouts" ADD CONSTRAINT "payouts_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "payouts" ADD CONSTRAINT "payouts_approved_by_operator_id_fkey" FOREIGN KEY ("approved_by_operator_id") REFERENCES "operator_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ledger_entries" ADD CONSTRAINT "ledger_entries_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "audit_events" ADD CONSTRAINT "audit_events_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exception_cases" ADD CONSTRAINT "exception_cases_order_id_fkey" FOREIGN KEY ("order_id") REFERENCES "orders"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "exception_cases" ADD CONSTRAINT "exception_cases_assignee_operator_id_fkey" FOREIGN KEY ("assignee_operator_id") REFERENCES "operator_users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
