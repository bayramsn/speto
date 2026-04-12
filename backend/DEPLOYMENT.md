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

## Render

Create one Render Web Service from this repository with the root-level
`render.yaml` Blueprint after committing and pushing the deployment files:

- Instance: `free`
- Service type: Web Service
- Runtime: Docker
- Dockerfile path: `backend/Dockerfile`
- Build context: repository root (`.`)
- Port: Render default `10000`
- Health check path: `/api/health`
- Start command: leave empty; the Dockerfile starts `node dist/main`

Render Blueprint prompts for `sync: false` values during initial setup. Set:

```env
DATABASE_URL=postgresql://USER:PASSWORD@HOST/DB?sslmode=require
CORS_ALLOWED_ORIGINS=
RESEND_API_KEY=
```

The Blueprint generates `JWT_ACCESS_SECRET` and `INTEGRATION_WEBHOOK_SECRET`
for you. Leave `RESEND_API_KEY` empty if real password reset emails are not
needed yet.

For a Flutter web origin or admin web origin, add the exact HTTPS origins to
`CORS_ALLOWED_ORIGINS` as a comma-separated list.

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
the `dockerfilePath: ./backend/Dockerfile` and `dockerContext: .` settings.

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
