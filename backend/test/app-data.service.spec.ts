import { UnauthorizedException } from '@nestjs/common';
import { Role as PrismaRole } from '@prisma/client';
import * as bcrypt from 'bcrypt';

import { AppDataService } from '../src/app-data/app-data.service';

describe('AppDataService auth hardening', () => {
  let prisma: any;
  let requestContext: any;
  let jwtTokenService: any;
  let service: AppDataService;

  beforeEach(() => {
    prisma = {
      $transaction: jest.fn(),
      refreshSession: {
        findUnique: jest.fn(),
        updateMany: jest.fn(),
      },
      user: {
        create: jest.fn(),
        findUnique: jest.fn(),
      },
    };
    requestContext = { userId: undefined };
    jwtTokenService = {};
    service = new AppDataService(prisma, requestContext, jwtTokenService);
    jest
      .spyOn(service as any, 'ensureInitialized')
      .mockResolvedValue(undefined);
  });

  it('register hashes passwords before persisting', async () => {
    prisma.user.findUnique.mockResolvedValue(null);
    prisma.user.create.mockImplementation(async ({ data }: { data: any }) => ({
      id: 'usr_customer_123',
      email: data.email,
      passwordHash: data.passwordHash,
      displayName: data.displayName,
      phone: data.phone,
      role: PrismaRole.CUSTOMER,
      vendorId: null,
      studentVerifiedAt: null,
      notificationsEnabled: true,
      avatarUrl: data.avatarUrl,
      createdAt: new Date(),
      updatedAt: new Date(),
    }));
    jest.spyOn(service as any, 'buildSessionResponse').mockResolvedValue({
      user: { id: 'usr_customer_123' },
      tokens: { accessToken: 'access', refreshToken: 'refresh' },
    });

    await service.register({
      email: 'user@example.com',
      displayName: 'User Example',
      phone: '+90 555 000 00 00',
      password: 'StrongPass123',
      studentEmail: undefined,
    });

    const createPayload = prisma.user.create.mock.calls[0][0].data;
    expect(createPayload.passwordHash).toBeDefined();
    expect(createPayload.passwordHash).not.toBe('StrongPass123');
    await expect(
      bcrypt.compare('StrongPass123', createPayload.passwordHash),
    ).resolves.toBe(true);
  });

  it('login accepts valid hashes and rejects wrong passwords', async () => {
    const passwordHash = await bcrypt.hash('Correct123', 10);
    prisma.user.findUnique.mockResolvedValue({
      id: 'usr_customer_123',
      email: 'user@example.com',
      passwordHash,
      displayName: 'User Example',
      phone: '',
      role: PrismaRole.CUSTOMER,
      vendorId: null,
      studentVerifiedAt: null,
      notificationsEnabled: true,
      avatarUrl: '',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    jest.spyOn(service as any, 'buildSessionResponse').mockResolvedValue({
      user: { id: 'usr_customer_123' },
      tokens: { accessToken: 'access', refreshToken: 'refresh' },
    });

    await expect(
      service.login('user@example.com', 'Correct123'),
    ).resolves.toEqual({
      user: { id: 'usr_customer_123' },
      tokens: { accessToken: 'access', refreshToken: 'refresh' },
    });
    await expect(
      service.login('user@example.com', 'Wrong123'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('refresh rotates sessions and rejects reuse of the old token', async () => {
    const activeSession = {
      id: 'refresh_session_1',
      userId: 'usr_customer_123',
      tokenHash: 'hashed-refresh-token',
      expiresAt: new Date(Date.now() + 60_000),
      revokedAt: null,
      createdAt: new Date(),
      lastUsedAt: null,
    };
    prisma.refreshSession.findUnique
      .mockResolvedValueOnce(activeSession)
      .mockResolvedValueOnce({
        ...activeSession,
        revokedAt: new Date(),
      });
    prisma.user.findUnique.mockResolvedValue({
      id: 'usr_customer_123',
      email: 'user@example.com',
      passwordHash: 'hashed-password',
      displayName: 'User Example',
      phone: '',
      role: PrismaRole.CUSTOMER,
      vendorId: null,
      studentVerifiedAt: null,
      notificationsEnabled: true,
      avatarUrl: '',
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const tx = {
      refreshSession: {
        update: jest.fn(),
      },
    };
    prisma.$transaction.mockImplementation(
      async (callback: (tx: any) => Promise<unknown>) => callback(tx),
    );
    jest
      .spyOn(service as any, 'hashRefreshToken')
      .mockReturnValue('hashed-refresh-token');
    jest.spyOn(service as any, 'buildSessionResponse').mockResolvedValue({
      user: { id: 'usr_customer_123' },
      tokens: { accessToken: 'rotated-access', refreshToken: 'rotated-refresh' },
    });

    const response = await service.refreshSession('opaque-refresh-token');

    expect(response.tokens.refreshToken).toBe('rotated-refresh');
    expect(tx.refreshSession.update).toHaveBeenCalledWith({
      where: { id: 'refresh_session_1' },
      data: {
        revokedAt: expect.any(Date),
        lastUsedAt: expect.any(Date),
      },
    });
    await expect(
      service.refreshSession('opaque-refresh-token'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
