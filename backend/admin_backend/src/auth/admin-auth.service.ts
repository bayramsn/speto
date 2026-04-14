import { randomBytes, createHash } from 'node:crypto';

import {
  UnauthorizedException,
  Injectable,
} from '@nestjs/common';
import { Prisma, Role as PrismaRole, User as PrismaUser } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { PrismaService } from '../prisma/prisma.service';
import { AdminJwtService } from './admin-jwt.service';

function getAdminRefreshTokenTtlDays() {
  const parsed = Number.parseInt(
    (process.env.ADMIN_REFRESH_TOKEN_TTL_DAYS ?? '30').trim(),
    10,
  );
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error('ADMIN_REFRESH_TOKEN_TTL_DAYS must be a positive integer');
  }
  return parsed;
}

@Injectable()
export class AdminAuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly adminJwtService: AdminJwtService,
  ) {}

  async login(email: string, password: string) {
    const adminUser = await this.prisma.user.findUnique({
      where: { email: email.trim().toLowerCase() },
    });
    if (
      !adminUser ||
      adminUser.role !== PrismaRole.ADMIN ||
      adminUser.isBanned ||
      adminUser.isSuspended ||
      !(await bcrypt.compare(password, adminUser.passwordHash))
    ) {
      throw new UnauthorizedException('Invalid admin credentials');
    }

    const now = new Date();
    const accessToken = await this.adminJwtService.issueAccessToken({
      userId: adminUser.id,
      email: adminUser.email,
    });

    const refreshSession = await this.createRefreshSession(adminUser.id);
    await this.prisma.user.update({
      where: { id: adminUser.id },
      data: { lastLoginAt: now },
    });
    await this.prisma.adminAuditLog.create({
      data: {
        adminUserId: adminUser.id,
        action: 'auth.login',
        entityType: 'admin-session',
        entityId: refreshSession.id,
        metadata: { email: adminUser.email },
      },
    });

    return {
      user: this.toAdminUser({
        ...adminUser,
        lastLoginAt: now,
      }),
      tokens: {
        accessToken: accessToken.token,
        refreshToken: refreshSession.token,
        accessTokenExpiresAt: accessToken.expiresAt.toISOString(),
        refreshTokenExpiresAt: refreshSession.expiresAt.toISOString(),
      },
    };
  }

  async refresh(refreshToken: string) {
    const normalized = refreshToken.trim();
    if (!normalized) {
      throw new UnauthorizedException('Invalid refresh token');
    }
    const session = await this.prisma.adminRefreshSession.findUnique({
      where: { tokenHash: this.hashToken(normalized) },
      include: { adminUser: true },
    });
    if (
      !session ||
      session.revokedAt ||
      session.expiresAt.getTime() <= Date.now() ||
      session.adminUser.role !== PrismaRole.ADMIN ||
      session.adminUser.isBanned ||
      session.adminUser.isSuspended
    ) {
      throw new UnauthorizedException('Invalid refresh token');
    }

    const accessToken = await this.adminJwtService.issueAccessToken({
      userId: session.adminUser.id,
      email: session.adminUser.email,
    });
    const rotatedSession = await this.prisma.$transaction(async (tx) => {
      await tx.adminRefreshSession.update({
        where: { id: session.id },
        data: {
          revokedAt: new Date(),
          lastUsedAt: new Date(),
        },
      });
      return this.createRefreshSession(session.adminUserId, tx);
    });

    return {
      user: this.toAdminUser(session.adminUser),
      tokens: {
        accessToken: accessToken.token,
        refreshToken: rotatedSession.token,
        accessTokenExpiresAt: accessToken.expiresAt.toISOString(),
        refreshTokenExpiresAt: rotatedSession.expiresAt.toISOString(),
      },
    };
  }

  async logout(refreshToken: string) {
    const normalized = refreshToken.trim();
    if (!normalized) {
      return { success: true };
    }
    const session = await this.prisma.adminRefreshSession.findUnique({
      where: { tokenHash: this.hashToken(normalized) },
    });
    if (!session) {
      return { success: true };
    }

    await this.prisma.adminRefreshSession.updateMany({
      where: { id: session.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    await this.prisma.adminAuditLog.create({
      data: {
        adminUserId: session.adminUserId,
        action: 'auth.logout',
        entityType: 'admin-session',
        entityId: session.id,
      },
    });
    return { success: true };
  }

  me(adminUser?: PrismaUser) {
    if (!adminUser || adminUser.role !== PrismaRole.ADMIN) {
      throw new UnauthorizedException('Unauthorized');
    }
    return {
      user: this.toAdminUser(adminUser),
    };
  }

  private toAdminUser(user: PrismaUser) {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl ?? '',
      role: 'SUPER_ADMIN',
      lastLoginAt: user.lastLoginAt?.toISOString() ?? null,
      createdAt: user.createdAt.toISOString(),
    };
  }

  private async createRefreshSession(
    adminUserId: string,
    tx: Prisma.TransactionClient | PrismaService = this.prisma,
  ) {
    const token = randomBytes(48).toString('base64url');
    const expiresAt = new Date(
      Date.now() + getAdminRefreshTokenTtlDays() * 24 * 60 * 60 * 1000,
    );
    const session = await tx.adminRefreshSession.create({
      data: {
        adminUserId,
        tokenHash: this.hashToken(token),
        expiresAt,
      },
    });
    return {
      id: session.id,
      token,
      expiresAt,
    };
  }

  private hashToken(token: string) {
    return createHash('sha256').update(token).digest('hex');
  }
}
