import { Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Role as PrismaRole } from '@prisma/client';

import { AccessTokenPayload } from './jwt-payload.interface';

export interface AccessTokenSubject {
  userId: string;
  email: string;
  role: PrismaRole;
  vendorId: string | null;
}

export interface SignedAccessToken {
  token: string;
  expiresAt: Date;
}

export function getJwtAccessSecret() {
  const secret = (process.env.JWT_ACCESS_SECRET ?? '').trim();
  if (secret.length === 0) {
    throw new Error('JWT_ACCESS_SECRET is not configured');
  }
  return secret;
}

export function getJwtAccessTtlSeconds() {
  const parsed = Number.parseInt(
    (process.env.JWT_ACCESS_TTL_SECONDS ?? '900').trim(),
    10,
  );
  if (!Number.isFinite(parsed) || parsed <= 0) {
    throw new Error('JWT_ACCESS_TTL_SECONDS must be a positive integer');
  }
  return parsed;
}

@Injectable()
export class JwtTokenService {
  constructor(private readonly jwtService: JwtService) {}

  async issueAccessToken(subject: AccessTokenSubject): Promise<SignedAccessToken> {
    const expiresInSeconds = getJwtAccessTtlSeconds();
    const token = await this.jwtService.signAsync({
      sub: subject.userId,
      email: subject.email,
      role: subject.role,
      vendorId: subject.vendorId,
    } satisfies AccessTokenPayload);
    return {
      token,
      expiresAt: new Date(Date.now() + expiresInSeconds * 1000),
    };
  }

  verifyAccessToken(token: string): AccessTokenPayload | null {
    const normalized = token.trim();
    if (normalized.length === 0) {
      return null;
    }
    try {
      return this.jwtService.verify<AccessTokenPayload>(normalized, {
        secret: getJwtAccessSecret(),
      });
    } catch {
      return null;
    }
  }
}
