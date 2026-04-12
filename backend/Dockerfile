# syntax=docker/dockerfile:1

FROM node:22-bookworm-slim AS deps

WORKDIR /app/backend

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates openssl python3 make g++ \
  && rm -rf /var/lib/apt/lists/*

COPY backend/package.json backend/package-lock.json ./
RUN npm ci

FROM deps AS build

COPY backend/nest-cli.json backend/tsconfig.json ./
COPY backend/prisma ./prisma
COPY backend/src ./src
COPY assets /app/assets

RUN npm run prisma:generate && npm run build

FROM build AS prod-deps

RUN npm prune --omit=dev && npm cache clean --force

FROM node:22-bookworm-slim AS runtime

WORKDIR /app/backend

ENV NODE_ENV=production
ENV PORT=10000

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates openssl \
  && rm -rf /var/lib/apt/lists/*

COPY --from=prod-deps /app/backend/node_modules ./node_modules
COPY --from=build /app/backend/dist ./dist
COPY --from=build /app/backend/prisma ./prisma
COPY --from=build /app/assets /app/assets
COPY backend/package.json backend/package-lock.json ./

EXPOSE 10000

CMD ["node", "dist/main"]
