FROM node:22-alpine AS base
WORKDIR /app

FROM base AS deps
COPY package*.json ./
RUN npm ci

FROM base AS build
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV DATABASE_URL=postgresql://exchange:exchange@postgres:5432/p2p_exchange?schema=public
RUN npx prisma generate || true
RUN npm run build

FROM base AS production
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/scripts ./scripts
COPY package*.json ./
RUN chmod +x scripts/docker-entrypoint-api.sh scripts/post-deploy.sh 2>/dev/null || true
EXPOSE 3000
CMD ["/app/scripts/docker-entrypoint-api.sh"]

# Privileged worker — same image family; secrets injected via env only at runtime
FROM base AS worker
WORKDIR /app
ENV NODE_ENV=production
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/prisma ./prisma
COPY --from=build /app/scripts ./scripts
COPY package*.json ./
CMD ["node", "dist/worker.main.js"]
