#!/bin/sh
set -e
cd /app
if [ -f prisma/schema.prisma ]; then
  npx prisma migrate deploy || npx prisma db push --accept-data-loss
fi
if [ -x scripts/post-deploy.sh ]; then
  bash scripts/post-deploy.sh || true
fi
exec node dist/main.js
