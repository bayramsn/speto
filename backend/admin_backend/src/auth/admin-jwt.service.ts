import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

export interface AdminAccessTokenPayload {
  sub: string;
  email: string;
  scope: 'SUPER_ADMIN';
}

export interface SignedAdminAccessToken {
  token: string;
  expiresAt: Date;
}

const RENDER_FALLBACK_ADMIN_JWT_ACCESS_SECRET =
  'speto-render-sync-admin-secret-2026';

export function getAdminJwtAccessSecret() {
  const secret = (process.env.ADMIN_JWT_ACCESS_SECRET ?? '').trim();
  if (secret.length > 0) {
    return secret;
  }
  const appEnv = (process.env.APP_ENV ?? process.env.NODE_ENV ?? '')
    .trim()
    .toLowerCase();
  if (appEnv === 'production') {
    return RENDER_FALLBACK_ADMIN_JWT_ACCESS_SECRET;
  }
  throw new Error('ADMIN_JWT_ACCESS_SECRET is not configured');
}

export function getAdminJwtAccessTtlSeconds() {
  const parsed = Number.parseInt(
    (process.env.ADMIN_JWT_ACCESS_TTL_SECONDS ?? '900').trim(),
    10,
  );
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error('ADMIN_JWT_ACCESS_TTL_SECONDS must be a positive integer');
  }
  return parsed;
}

@Injectable()
export class AdminJwtService {
  constructor(private readonly jwtService: JwtService) {}

  async issueAccessToken(subject: {
    userId: string;
    email: string;
  }): Promise<SignedAdminAccessToken> {
    const expiresInSeconds = getAdminJwtAccessTtlSeconds();
    const token = await this.jwtService.signAsync({
      sub: subject.userId,
      email: subject.email,
      scope: 'SUPER_ADMIN',
    } satisfies AdminAccessTokenPayload);
    return {
      token,
      expiresAt: new Date(Date.now() + expiresInSeconds * 1000),
    };
  }

  verifyAccessToken(token: string): AdminAccessTokenPayload | null {
    const normalized = token.trim();
    if (normalized.length === 0) {
      return null;
    }
    try {
      return this.jwtService.verify<AdminAccessTokenPayload>(normalized, {
        secret: getAdminJwtAccessSecret(),
      });
    } catch {
      return null;
    }
  }
}
