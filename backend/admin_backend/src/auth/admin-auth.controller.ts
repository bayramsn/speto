import { Body, Controller, Get, Post, Req, Res } from '@nestjs/common';
import { User as PrismaUser } from '@prisma/client';
import { FastifyReply } from 'fastify';

import { Public } from './public.decorator';
import { AdminAuthService } from './admin-auth.service';

type AdminRequest = {
  headers?: Record<string, string | string[] | undefined>;
  adminUser?: PrismaUser;
};

const REFRESH_COOKIE_NAME = 'speto_admin_refresh';

function isProduction() {
  return (process.env.APP_ENV ?? process.env.NODE_ENV ?? 'development')
    .trim()
    .toLowerCase() === 'production';
}

function resolveSameSite() {
  const configured = (process.env.ADMIN_REFRESH_COOKIE_SAMESITE ?? '').trim();
  if (['Strict', 'Lax', 'None'].includes(configured)) {
    return configured;
  }
  return isProduction() ? 'None' : 'Lax';
}

function parseCookie(header: string | string[] | undefined, name: string) {
  const raw = Array.isArray(header) ? header.join(';') : header;
  if (!raw) {
    return '';
  }
  for (const part of raw.split(';')) {
    const [key, ...valueParts] = part.trim().split('=');
    if (key === name) {
      return decodeURIComponent(valueParts.join('='));
    }
  }
  return '';
}

function setRefreshCookie(reply: FastifyReply, refreshToken: string, expiresAt: string) {
  const expires = new Date(expiresAt);
  const maxAge = Math.max(0, Math.floor((expires.getTime() - Date.now()) / 1000));
  const secure = isProduction() || resolveSameSite() === 'None';
  reply.header(
    'Set-Cookie',
    [
      `${REFRESH_COOKIE_NAME}=${encodeURIComponent(refreshToken)}`,
      'Path=/api/admin/auth',
      'HttpOnly',
      `SameSite=${resolveSameSite()}`,
      secure ? 'Secure' : '',
      `Max-Age=${maxAge}`,
      `Expires=${expires.toUTCString()}`,
    ].filter(Boolean).join('; '),
  );
}

function clearRefreshCookie(reply: FastifyReply) {
  reply.header(
    'Set-Cookie',
    [
      `${REFRESH_COOKIE_NAME}=`,
      'Path=/api/admin/auth',
      'HttpOnly',
      `SameSite=${resolveSameSite()}`,
      isProduction() || resolveSameSite() === 'None' ? 'Secure' : '',
      'Max-Age=0',
      'Expires=Thu, 01 Jan 1970 00:00:00 GMT',
    ].filter(Boolean).join('; '),
  );
}

function withoutRefreshToken(session: Awaited<ReturnType<AdminAuthService['login']>>) {
  return {
    user: session.user,
    tokens: {
      accessToken: session.tokens.accessToken,
      accessTokenExpiresAt: session.tokens.accessTokenExpiresAt,
    },
  };
}

@Controller('admin/auth')
export class AdminAuthController {
  constructor(private readonly adminAuthService: AdminAuthService) {}

  @Post('login')
  @Public()
  async login(
    @Body() payload: Record<string, unknown> | undefined,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const session = await this.adminAuthService.login(
      typeof payload?.email === 'string' ? payload.email : '',
      typeof payload?.password === 'string' ? payload.password : '',
    );
    setRefreshCookie(
      reply,
      session.tokens.refreshToken,
      session.tokens.refreshTokenExpiresAt,
    );
    return withoutRefreshToken(session);
  }

  @Post('refresh')
  @Public()
  async refresh(
    @Req() req: AdminRequest,
    @Body() payload: Record<string, unknown> | undefined,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const refreshToken =
      typeof payload?.refreshToken === 'string'
        ? payload.refreshToken
        : parseCookie(req.headers?.cookie, REFRESH_COOKIE_NAME);
    const session = await this.adminAuthService.refresh(refreshToken);
    setRefreshCookie(
      reply,
      session.tokens.refreshToken,
      session.tokens.refreshTokenExpiresAt,
    );
    return withoutRefreshToken(session);
  }

  @Post('logout')
  @Public()
  async logout(
    @Req() req: AdminRequest,
    @Body() payload: Record<string, unknown> | undefined,
    @Res({ passthrough: true }) reply: FastifyReply,
  ) {
    const refreshToken =
      typeof payload?.refreshToken === 'string'
        ? payload.refreshToken
        : parseCookie(req.headers?.cookie, REFRESH_COOKIE_NAME);
    const result = await this.adminAuthService.logout(refreshToken);
    clearRefreshCookie(reply);
    return result;
  }

  @Get('me')
  me(@Req() req: AdminRequest) {
    return this.adminAuthService.me(req.adminUser);
  }
}
