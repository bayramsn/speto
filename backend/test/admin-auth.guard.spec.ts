import 'reflect-metadata';

import { UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role as PrismaRole } from '@prisma/client';

import { AdminAuthGuard } from '../admin_backend/src/auth/admin-auth.guard';

describe('AdminAuthGuard', () => {
  let reflector: Reflector;
  let adminJwtService: any;
  let prisma: any;
  let guard: AdminAuthGuard;

  beforeEach(() => {
    reflector = {
      getAllAndOverride: jest.fn(),
    } as unknown as Reflector;
    adminJwtService = {
      verifyAccessToken: jest.fn(),
    };
    prisma = {
      user: {
        findUnique: jest.fn(),
      },
    };
    guard = new AdminAuthGuard(reflector, adminJwtService, prisma);
  });

  function createContext(request: Record<string, unknown>) {
    return {
      getHandler: () => 'handler',
      getClass: () => 'class',
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    } as any;
  }

  it('skips auth checks on public routes', async () => {
    (reflector.getAllAndOverride as jest.Mock).mockReturnValue(true);

    await expect(
      guard.canActivate(createContext({ headers: {} })),
    ).resolves.toBe(true);
    expect(adminJwtService.verifyAccessToken).not.toHaveBeenCalled();
  });

  it('attaches the admin user for valid access tokens', async () => {
    const request = {
      headers: {
        authorization: 'Bearer access-token',
      },
    };
    (reflector.getAllAndOverride as jest.Mock).mockReturnValue(false);
    adminJwtService.verifyAccessToken.mockReturnValue({
      sub: 'admin-1',
      email: 'admin@speto.app',
      scope: 'SUPER_ADMIN',
    });
    prisma.user.findUnique.mockResolvedValue({
      id: 'admin-1',
      role: PrismaRole.ADMIN,
      isBanned: false,
      isSuspended: false,
    });

    await expect(guard.canActivate(createContext(request))).resolves.toBe(true);
    expect(request).toEqual(
      expect.objectContaining({
        adminUser: expect.objectContaining({ id: 'admin-1' }),
      }),
    );
  });

  it('rejects non-admin users', async () => {
    (reflector.getAllAndOverride as jest.Mock).mockReturnValue(false);
    adminJwtService.verifyAccessToken.mockReturnValue({
      sub: 'user-1',
      email: 'vendor@speto.app',
      scope: 'SUPER_ADMIN',
    });
    prisma.user.findUnique.mockResolvedValue({
      id: 'user-1',
      role: PrismaRole.VENDOR,
      isBanned: false,
      isSuspended: false,
    });

    await expect(
      guard.canActivate(
        createContext({
          headers: { authorization: 'Bearer access-token' },
        }),
      ),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
