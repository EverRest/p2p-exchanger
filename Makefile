.PHONY: help install install-backend install-frontend install-bot \
	lint lint-backend lint-frontend lint-bot format format-check \
	typecheck typecheck-backend typecheck-frontend typecheck-bot \
	test test-backend test-frontend test-e2e e2e-prepare \
	build build-backend build-frontend build-bot \
	ci ci-backend ci-frontend \
	dev-infra dev-backend dev-worker dev-frontend dev-bot dev \
	db-migrate db-generate db-studio db-push db-seed \
	docker-env docker-up docker-down docker-app \
	hooks-install pre-commit smoke clean \
	deploy-staging-docs bump-version

SHELL := /bin/bash
BACKEND := backend
FRONTEND := frontend
BOT := bot
E2E_DATABASE_URL ?= postgresql://exchange:exchange@127.0.0.1:5435/p2p_exchange_e2e?schema=public&sslmode=disable
E2E_ENV := DATABASE_URL='$(E2E_DATABASE_URL)' REDIS_HOST=localhost REDIS_PORT=6380 JWT_SECRET=e2e-test-secret NODE_ENV=test MOCK_PROVIDERS=true

help: ## Show available targets
	@grep -E '^[a-zA-Z0-9_-]+:.*##' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

install: install-backend install-frontend install-bot ## Install all dependencies

install-backend: ## npm ci in backend
	cd $(BACKEND) && npm ci

install-frontend: ## npm ci in frontend
	cd $(FRONTEND) && npm ci

install-bot: ## npm ci in bot
	cd $(BOT) && npm ci

hooks-install: ## Point git at .husky hooks (run after clone)
	git config core.hooksPath .husky
	@chmod +x .husky/pre-commit \
		scripts/pre-commit.sh \
		scripts/pre-commit-analyze.sh \
		scripts/setup-docker-env.sh \
		scripts/ensure-e2e-db.sh \
		scripts/bump-version.sh \
		scripts/smoke-test.sh \
		scripts/bootstrap-staging-server.sh \
		scripts/deploy-staging-remote.sh
	@echo "Git hooks path set to .husky/"

lint: lint-backend lint-frontend lint-bot ## Run linters (check mode)

lint-backend: ## ESLint backend (no auto-fix)
	cd $(BACKEND) && npm run lint:check

lint-frontend: ## ESLint/oxlint frontend (check mode)
	cd $(FRONTEND) && npm run lint:check

lint-bot: ## ESLint bot (check mode)
	cd $(BOT) && npm run lint:check

format: ## Format all code with Prettier
	cd $(BACKEND) && npm run format
	cd $(FRONTEND) && npm run format
	cd $(BOT) && npm run format

format-check: ## Verify formatting without writing
	cd $(BACKEND) && npm run format:check
	cd $(FRONTEND) && npm run format:check
	cd $(BOT) && npm run format:check

typecheck: typecheck-backend typecheck-frontend typecheck-bot ## TypeScript check all apps

typecheck-backend:
	cd $(BACKEND) && npm run typecheck

typecheck-frontend:
	cd $(FRONTEND) && npm run typecheck

typecheck-bot:
	cd $(BOT) && npm run typecheck

test: test-backend test-frontend ## Run unit tests

test-backend:
	cd $(BACKEND) && npm test -- --passWithNoTests

test-frontend:
	cd $(FRONTEND) && npm test -- --passWithNoTests

e2e-prepare: dev-infra ## Ensure e2e DB exists and schema is synced
	bash scripts/ensure-e2e-db.sh
	cd $(BACKEND) && $(E2E_ENV) npx prisma db push --accept-data-loss

test-e2e: e2e-prepare ## Backend e2e tests (isolated DB)
	cd $(BACKEND) && $(E2E_ENV) npm run test:e2e

build: build-backend build-frontend build-bot ## Build all apps

build-backend:
	cd $(BACKEND) && npm run build

build-frontend:
	cd $(FRONTEND) && npm run build

build-bot:
	cd $(BOT) && npm run build

ci-backend: ## Backend CI pipeline
	cd $(BACKEND) && npm run format:check
	cd $(BACKEND) && npm run lint:check
	cd $(BACKEND) && npm run typecheck
	cd $(BACKEND) && npm test -- --passWithNoTests
	cd $(BACKEND) && npm run build

ci-frontend: ## Frontend CI pipeline
	cd $(FRONTEND) && npm run format:check
	cd $(FRONTEND) && npm run lint:check
	cd $(FRONTEND) && npm run typecheck
	cd $(FRONTEND) && npm test -- --passWithNoTests
	cd $(FRONTEND) && npm run build

pre-commit: ## Same checks as the git pre-commit hook
	bash scripts/pre-commit.sh

ci: lint format-check typecheck test build ## Quick CI (no e2e / docker)
	@echo "CI checks passed."

dev-infra: ## Start postgres + redis
	docker compose up -d postgres redis

dev-backend: ## NestJS API watch mode
	cd $(BACKEND) && npm run start:dev

dev-worker: ## BullMQ privileged worker watch mode
	cd $(BACKEND) && npm run start:worker

dev-frontend: ## Vite dev server
	cd $(FRONTEND) && npm run dev

dev-bot: ## Telegram bot watch mode
	cd $(BOT) && npm run start:dev

dev: dev-infra ## Print dev startup hints
	@echo "Run in separate terminals:"
	@echo "  make dev-backend"
	@echo "  make dev-worker"
	@echo "  make dev-frontend"
	@echo "  make dev-bot"
	@echo ""
	@echo "Wallet/Binance secrets MUST only be in worker env (see backend/.env.example)."

db-generate: ## Prisma generate
	cd $(BACKEND) && npm run prisma:generate

db-migrate: ## Prisma migrate dev
	cd $(BACKEND) && npm run prisma:migrate

db-push: ## Prisma db push (dev)
	cd $(BACKEND) && npx prisma db push

db-seed: ## Seed operator + launch pairs/methods
	cd $(BACKEND) && npm run db:seed

db-studio: ## Prisma Studio
	cd $(BACKEND) && npm run prisma:studio

docker-env: ## Copy .env.docker templates to .env if missing
	bash scripts/setup-docker-env.sh

docker-up: ## docker compose up -d (postgres + redis)
	docker compose up -d postgres redis

docker-down: ## docker compose down
	docker compose down

docker-app: docker-env ## Build and start full stack
	docker compose up -d --build postgres redis api worker frontend bot

smoke: ## Live API smoke test (requires running API)
	bash scripts/smoke-test.sh

bump-version: ## Bump VERSION + package.json (transl8 rules)
	bash scripts/bump-version.sh

deploy-staging-docs: ## Staging deploy runbook
	@echo "See docs/deploy/staging.md"

clean: ## Remove build artifacts
	rm -rf $(BACKEND)/dist $(BACKEND)/coverage $(FRONTEND)/dist $(BOT)/dist
