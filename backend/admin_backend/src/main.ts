import { existsSync, readFileSync } from 'node:fs';
import { resolve } from 'node:path';

import { ValidationPipe } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';

import { AppModule } from './app.module';

function loadLocalEnv() {
  const candidates = [
    resolve(process.cwd(), '.env'),
    resolve(process.cwd(), '..', '.env'),
  ];
  for (const envPath of candidates) {
    if (!existsSync(envPath)) {
      continue;
    }
    const contents = readFileSync(envPath, 'utf8');
    for (const line of contents.split(/\r?\n/)) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith('#')) {
        continue;
      }
      const separatorIndex = trimmed.indexOf('=');
      if (separatorIndex <= 0) {
        continue;
      }
      const key = trimmed.slice(0, separatorIndex).trim();
      if (!key || process.env[key]) {
        continue;
      }
      let value = trimmed.slice(separatorIndex + 1).trim();
      if (
        (value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }
      process.env[key] = value;
    }
  }
}

function resolveAllowedCorsOrigins() {
  const configuredOrigins = (process.env.ADMIN_CORS_ALLOWED_ORIGINS ??
    process.env.CORS_ALLOWED_ORIGINS ??
    '')
    .split(',')
    .map((origin) => origin.trim())
    .filter((origin) => origin.length > 0);
  const appEnv = (process.env.APP_ENV ?? process.env.NODE_ENV ?? 'development')
    .trim()
    .toLowerCase();
  if (appEnv === 'production') {
    return new Set<string>(configuredOrigins);
  }
  return new Set<string>([
    ...configuredOrigins,
    'http://127.0.0.1:3000',
    'http://127.0.0.1:4000',
    'http://127.0.0.1:4100',
    'http://127.0.0.1:5173',
    'http://localhost:3000',
    'http://localhost:4000',
    'http://localhost:4100',
    'http://localhost:5173',
  ]);
}

async function bootstrap() {
  loadLocalEnv();
  const app = await NestFactory.create<NestFastifyApplication>(
    AppModule,
    new FastifyAdapter(),
  );

  app.setGlobalPrefix('api');
  app.enableCors({
    origin: (origin, callback) => {
      if (origin == null || origin.trim().length === 0) {
        callback(null, true);
        return;
      }
      callback(null, resolveAllowedCorsOrigins().has(origin));
    },
    credentials: false,
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Accept', 'Authorization', 'Content-Type'],
  });
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidUnknownValues: false,
    }),
  );

  const swaggerConfig = new DocumentBuilder()
    .setTitle('SepetPro Admin Backend')
    .setDescription('God-mode admin backend for SepetPro')
    .setVersion('0.1.0')
    .addBearerAuth()
    .build();
  const swaggerDocument = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup('docs', app, swaggerDocument);

  const port = Number.parseInt(process.env.PORT ?? process.env.ADMIN_PORT ?? '4100', 10);
  await app.listen(port, '0.0.0.0');
}

void bootstrap();
