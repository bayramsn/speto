import { AdminAuthController } from '../admin_backend/src/auth/admin-auth.controller';

describe('AdminAuthController', () => {
  const session = {
    user: {
      id: 'admin-1',
      email: 'admin@speto.app',
      displayName: 'Speto Admin',
      role: 'SUPER_ADMIN',
      avatarUrl: '',
      createdAt: '2026-04-15T00:00:00.000Z',
      lastLoginAt: null,
    },
    tokens: {
      accessToken: 'access-token',
      accessTokenExpiresAt: '2026-04-15T01:00:00.000Z',
      refreshToken: 'refresh-token',
      refreshTokenExpiresAt: '2026-04-16T01:00:00.000Z',
    },
  };

  let service: any;
  let controller: AdminAuthController;
  let reply: { header: jest.Mock };

  beforeEach(() => {
    service = {
      login: jest.fn(),
      refresh: jest.fn(),
      logout: jest.fn(),
      me: jest.fn(),
    };
    controller = new AdminAuthController(service);
    reply = {
      header: jest.fn().mockReturnThis(),
    };
  });

  it('sets HttpOnly refresh cookie on login and strips refresh token from body', async () => {
    service.login.mockResolvedValue(session);

    const response = await controller.login(
      { email: 'admin@speto.app', password: 'admin123' },
      reply as any,
    );

    expect(service.login).toHaveBeenCalledWith('admin@speto.app', 'admin123');
    expect(reply.header).toHaveBeenCalledWith(
      'Set-Cookie',
      expect.stringContaining('speto_admin_refresh=refresh-token'),
    );
    expect(reply.header).toHaveBeenCalledWith(
      'Set-Cookie',
      expect.stringContaining('HttpOnly'),
    );
    expect(response.tokens).toEqual({
      accessToken: 'access-token',
      accessTokenExpiresAt: '2026-04-15T01:00:00.000Z',
    });
  });

  it('reads refresh token from cookie when refresh body is empty', async () => {
    service.refresh.mockResolvedValue({
      ...session,
      tokens: {
        ...session.tokens,
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token',
      },
    });

    const response = await controller.refresh(
      { headers: { cookie: 'speto_admin_refresh=refresh-cookie' } },
      undefined,
      reply as any,
    );

    expect(service.refresh).toHaveBeenCalledWith('refresh-cookie');
    expect(reply.header).toHaveBeenCalledWith(
      'Set-Cookie',
      expect.stringContaining('speto_admin_refresh=new-refresh-token'),
    );
    expect(response.tokens.accessToken).toBe('new-access-token');
    expect('refreshToken' in response.tokens).toBe(false);
  });

  it('clears refresh cookie on logout', async () => {
    service.logout.mockResolvedValue({ success: true });

    await expect(
      controller.logout(
        { headers: { cookie: 'speto_admin_refresh=refresh-cookie' } },
        undefined,
        reply as any,
      ),
    ).resolves.toEqual({ success: true });

    expect(service.logout).toHaveBeenCalledWith('refresh-cookie');
    expect(reply.header).toHaveBeenCalledWith(
      'Set-Cookie',
      expect.stringContaining('Max-Age=0'),
    );
  });
});
