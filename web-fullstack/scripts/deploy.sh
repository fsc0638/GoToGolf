#!/usr/bin/env bash
set -euo pipefail

echo "[deploy] starting GoToGolf web deployment"
if [ ! -f .env ]; then
  cp .env.example .env
fi

npm ci
npx prisma generate
npm run build

echo "[deploy] build done"
echo "[deploy] launching service on port 638"
npm run start
