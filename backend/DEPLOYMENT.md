# Speto Backend Deployment

This deployment path targets a zero-cost MVP setup:

- Render Free Web Service for the NestJS API.
- Neon Free Postgres for the persistent database.
- No Render Postgres, paid instances, or paid custom domain.

## Neon

1. Create a Neon Free project.
2. Copy the Postgres connection string with `sslmode=require`.
3. Use that value as `DATABASE_URL` in Render.
4. Push the Prisma schema once from a trusted local shell:

```bash
cd backend
DATABASE_URL="postgresql://USER:PASSWORD@HOST/DB?sslmode=require" npm run prisma:push
```

Repeat this schema push after backend Prisma model changes, including the
stock app operator registration fields. This Render service uses the Free plan,
so keep schema sync as a trusted local/CI step instead of relying on a Render
pre-deploy command.

## Render

Create two Render Web Services from this repository with the root-level
`render.yaml` Blueprint after committing and pushing the deployment files:

- `speto-backend`
  - Instance: `free`
  - Service type: Web Service
  - Runtime: Docker
  - Dockerfile path: `backend/Dockerfile`
  - Build context: repository root (`.`)
  - Port: Render default `10000`
  - Health check path: `/api/health`
  - Start command: leave empty; the Dockerfile starts `node dist/main`

- `speto-admin-backend`
  - Instance: `free`
  - Service type: Web Service
  - Runtime: Docker
  - Dockerfile path: `backend/admin_backend/Dockerfile`
  - Build context: repository root (`.`)
  - Port: Render default `10000`
  - Health check path: `/api/health`
  - Start command: leave empty; the Dockerfile starts `node admin_backend/dist/main.js`

Render Blueprint prompts for `sync: false` values during initial setup. Set:

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST/DB?sslmode=require
CORS_ALLOWED_ORIGINS=
RESEND_API_KEY=
ADMIN_CORS_ALLOWED_ORIGINS=
ADMIN_REFRESH_COOKIE_SAMESITE=None
ADMIN_UPLOAD_PROVIDER=
ADMIN_NOTIFICATION_PROVIDER=
```

The Blueprint generates `JWT_ACCESS_SECRET`, `INTEGRATION_WEBHOOK_SECRET`, and
`ADMIN_JWT_ACCESS_SECRET` for you. Leave `RESEND_API_KEY` empty if real password
reset emails are not needed yet.

For a Flutter web origin, add the exact HTTPS origins to `CORS_ALLOWED_ORIGINS`
as a comma-separated list. For the admin web panel, add the exact HTTPS origins
to `ADMIN_CORS_ALLOWED_ORIGINS`. Production admin auth uses the HttpOnly
`speto_admin_refresh` cookie; for cross-site panel/backend deployments keep
`ADMIN_REFRESH_COOKIE_SAMESITE=None` so the browser sends the cookie with
credentialed requests.

Render Free Web Services sleep after inactivity and wake on the next request.
The Flutter shared API client waits on `/api/health` for explicit remote API
URLs so this cold start is handled when the app opens.

### Render CLI

The Render CLI can validate this Blueprint, but Blueprint creation/import still
has to be done from the Render Dashboard for this setup:

```bash
render login
render workspace set <workspace-id>
render blueprints validate render.yaml
```

Use the Dashboard to create a new Blueprint from the repository so Render uses
the `dockerfilePath` and `dockerContext: .` settings for both services.

## Admin Panel

The web admin panel talks only to the admin backend and should be configured
with:

```env
VITE_ADMIN_API_BASE_URL=https://speto-admin-backend.onrender.com/api
```

For local development:

```bash
cd admin_panel
cp .env.example .env
npm install
npm run dev
```

## Flutter builds

Build both apps with the Render API URL:

```bash
flutter build apk --dart-define=SPETO_API_BASE_URL=https://speto-backend.onrender.com/api
```

For `stock_app`:

```bash
cd stock_app
flutter build apk --dart-define=SPETO_API_BASE_URL=https://speto-backend.onrender.com/api
```
