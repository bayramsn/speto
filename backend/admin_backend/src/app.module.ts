import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { JwtModule } from '@nestjs/jwt';

import { AdminController } from './admin/admin.controller';
import { AdminService } from './admin/admin.service';
import { AdminAuthController } from './auth/admin-auth.controller';
import { AdminAuthGuard } from './auth/admin-auth.guard';
import { AdminAuthService } from './auth/admin-auth.service';
import { AdminJwtService, getAdminJwtAccessSecret, getAdminJwtAccessTtlSeconds } from './auth/admin-jwt.service';
import { PrismaModule } from './prisma/prisma.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    PrismaModule,
    JwtModule.registerAsync({
      useFactory: () => ({
        secret: getAdminJwtAccessSecret(),
        signOptions: { expiresIn: getAdminJwtAccessTtlSeconds() },
      }),
    }),
  ],
  controllers: [HealthController, AdminAuthController, AdminController],
  providers: [
    AdminJwtService,
    AdminAuthService,
    AdminService,
    { provide: APP_GUARD, useClass: AdminAuthGuard },
  ],
})
export class AppModule {}
