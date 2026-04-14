import * as bcrypt from 'bcrypt';
import { Role as PrismaRole } from '@prisma/client';

import { AdminAuthService } from '../admin_backend/src/auth/admin-auth.service';

describe('AdminAuthService', () => {
  let prisma: any;
  let adminJwtService: any;
  let service: AdminAuthService;

  beforeEach(() => {
    process.env.ADMIN_REFRESH_TOKEN_TTL_DAYS = '30';

    prisma = {
      $transaction: jest.fn(),
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      adminRefreshSession: {
        create: jest.fn(),
        findUnique: jest.fn(),
        updateMany: jest.fn(),
      },
      adminAuditLog: {
        create: jest.fn(),
      },
    };
    adminJwtService = {
      issueAccessToken: jest.fn().mockResolvedValue({
        token: 'access-token',
        expiresAt: new Date('2026-04-15T10:30:00.000Z'),
      }),
    };
    service = new AdminAuthService(prisma, adminJwtService);
  });

  afterEach(() => {
    delete process.env.ADMIN_REFRESH_TOKEN_TTL_DAYS;
  });

  it('logs in a super admin and writes refresh session audit state', async () => {
    const passwordHash = await bcrypt.hash('admin123', 10);
    prisma.user.findUnique.mockResolvedValue({
      id: 'admin-1',
      email: 'admin@speto.app',
      passwordHash,
      displayName: 'Speto Admin',
      avatarUrl: null,
      role: PrismaRole.ADMIN,
      isBanned: false,
      isSuspended: false,
      lastLoginAt: null,
      createdAt: new Date('2026-04-01T09:00:00.000Z'),
    });
    prisma.adminRefreshSession.create.mockResolvedValue({
      id: 'session-1',
      expiresAt: new Date('2026-05-15T10:30:00.000Z'),
    });

    const session = await service.login('admin@speto.app', 'admin123');

    expect(adminJwtService.issueAccessToken).toHaveBeenCalledWith({
      userId: 'admin-1',
      email: 'admin@speto.app',
    });
    expect(prisma.user.update).toHaveBeenCalledWith({
      where: { id: 'admin-1' },
      data: { lastLoginAt: expect.any(Date) },
    });
    expect(prisma.adminRefreshSession.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        adminUserId: 'admin-1',
        tokenHash: expect.any(String),
        expiresAt: expect.any(Date),
      }),
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        adminUserId: 'admin-1',
        action: 'auth.login',
        entityType: 'admin-session',
        entityId: 'session-1',
      }),
    });
    expect(session).toEqual({
      user: {
        id: 'admin-1',
        email: 'admin@speto.app',
        displayName: 'Speto Admin',
        avatarUrl: '',
        role: 'SUPER_ADMIN',
        lastLoginAt: expect.any(String),
        createdAt: '2026-04-01T09:00:00.000Z',
      },
      tokens: {
        accessToken: 'access-token',
        refreshToken: expect.any(String),
        accessTokenExpiresAt: '2026-04-15T10:30:00.000Z',
        refreshTokenExpiresAt: expect.any(String),
      },
    });
    expect(new Date(session.tokens.refreshTokenExpiresAt).getTime()).toBeGreaterThan(Date.now());
  });

  it('rejects suspended admin accounts', async () => {
    prisma.user.findUnique.mockResolvedValue({
      id: 'admin-2',
      email: 'blocked@speto.app',
      passwordHash: await bcrypt.hash('admin123', 10),
      displayName: 'Blocked Admin',
      avatarUrl: null,
      role: PrismaRole.ADMIN,
      isBanned: false,
      isSuspended: true,
      createdAt: new Date('2026-04-01T09:00:00.000Z'),
    });

    await expect(service.login('blocked@speto.app', 'admin123')).rejects.toThrow(
      'Invalid admin credentials',
    );
  });

  it('rotates refresh tokens on refresh', async () => {
    const revokedAt = new Date('2026-04-15T10:05:00.000Z');
    const rotatedExpiresAt = new Date('2026-05-20T10:30:00.000Z');
    const tx = {
      adminRefreshSession: {
        update: jest.fn(),
        create: jest.fn().mockResolvedValue({
          id: 'session-2',
          expiresAt: rotatedExpiresAt,
        }),
      },
    };
    prisma.adminRefreshSession.findUnique.mockResolvedValue({
      id: 'session-1',
      adminUserId: 'admin-1',
      revokedAt: null,
      expiresAt: new Date('2026-05-01T10:00:00.000Z'),
      adminUser: {
        id: 'admin-1',
        email: 'admin@speto.app',
        displayName: 'Speto Admin',
        avatarUrl: null,
        role: PrismaRole.ADMIN,
        isBanned: false,
        isSuspended: false,
        lastLoginAt: new Date('2026-04-15T09:55:00.000Z'),
        createdAt: new Date('2026-04-01T09:00:00.000Z'),
      },
    });
    prisma.$transaction.mockImplementation(async (callback: (client: typeof tx) => Promise<unknown>) =>
      callback(tx),
    );

    const session = await service.refresh('refresh-token');

    expect(tx.adminRefreshSession.update).toHaveBeenCalledWith({
      where: { id: 'session-1' },
      data: {
        revokedAt: expect.any(Date),
        lastUsedAt: expect.any(Date),
      },
    });
    expect(session.tokens).toEqual({
      accessToken: 'access-token',
      refreshToken: expect.any(String),
      accessTokenExpiresAt: '2026-04-15T10:30:00.000Z',
      refreshTokenExpiresAt: expect.any(String),
    });
    expect(new Date(session.tokens.refreshTokenExpiresAt).getTime()).toBeGreaterThan(Date.now());
    expect(tx.adminRefreshSession.update.mock.calls[0][0].data.revokedAt).not.toEqual(revokedAt);
  });

  it('revokes refresh sessions on logout', async () => {
    prisma.adminRefreshSession.findUnique.mockResolvedValue({
      id: 'session-logout',
      adminUserId: 'admin-1',
    });

    await expect(service.logout('refresh-token')).resolves.toEqual({ success: true });

    expect(prisma.adminRefreshSession.updateMany).toHaveBeenCalledWith({
      where: { id: 'session-logout', revokedAt: null },
      data: { revokedAt: expect.any(Date) },
    });
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith({
      data: expect.objectContaining({
        adminUserId: 'admin-1',
        action: 'auth.logout',
        entityType: 'admin-session',
        entityId: 'session-logout',
      }),
    });
  });
});
