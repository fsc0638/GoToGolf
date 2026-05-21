# GoToGolf Web Fullstack (Enterprise Phase 2)

這版是第二階段：RBAC、CI/CD、部署腳本、OpenAPI 都已加入。

## 新增能力
- RBAC：`ADMIN / COACH / PLAYER`
- API 權限
  - `GET /api/rounds` -> PLAYER+
  - `POST /api/rounds` -> COACH+
  - `PATCH /api/rounds/:id/score` -> PLAYER+
  - `GET /api/admin/health` -> ADMIN
- 結構化日誌（JSON）
- Docker Compose 啟動
- GitHub Actions CI
- OpenAPI 文件

## 啟動
```bash
cp .env.example .env
npm install
npx prisma generate
npx prisma migrate dev --name phase2_rbac
npm run db:seed
npm run dev
```

## Docker
```bash
docker compose up --build
```

## CI
- `.github/workflows/ci.yml` 會在 push / PR 跑 lint + build。

## OpenAPI
- `docs/openapi.yaml`
