import { Global, Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';

import { RequestContextModule } from '../app-data/request-context.module';
import { JwtAuthGuard } from './jwt-auth.guard';
import { JwtStrategy } from './jwt.strategy';
import { JwtTokenService, getJwtAccessSecret, getJwtAccessTtlSeconds } from './jwt-token.service';
import { RolesGuard } from './roles.guard';
import { WebhookSecretGuard } from './webhook-secret.guard';

@Global()
@Module({
  imports: [
    RequestContextModule,
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: getJwtAccessSecret(),
        signOptions: { expiresIn: getJwtAccessTtlSeconds() },
      }),
    }),
    ThrottlerModule.forRoot([
      {
        ttl: 60_000,
        limit: 120,
      },
    ]),
  ],
  providers: [
    JwtTokenService,
    JwtStrategy,
    WebhookSecretGuard,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
  exports: [JwtTokenService, WebhookSecretGuard],
})
export class SecurityModule {}
