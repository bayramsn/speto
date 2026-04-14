import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role as PrismaRole, User as PrismaUser } from '@prisma/client';

import { PrismaService } from '../prisma/prisma.service';
import { AdminJwtService } from './admin-jwt.service';
import { IS_PUBLIC_KEY } from './public.decorator';

type AdminRequest = {
  headers: Record<string, string | string[] | undefined>;
  adminUser?: PrismaUser;
};

@Injectable()
export class AdminAuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly adminJwtService: AdminJwtService,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }

    const request = context.switchToHttp().getRequest<AdminRequest>();
    const authorization = request.headers.authorization;
    const rawHeader = Array.isArray(authorization) ? authorization[0] : authorization;
    const token = rawHeader?.startsWith('Bearer ') ? rawHeader.slice(7).trim() : '';
    const payload = this.adminJwtService.verifyAccessToken(token ?? '');
    if (!payload) {
      throw new UnauthorizedException('Unauthorized');
    }

    const adminUser = await this.prisma.user.findUnique({
      where: { id: payload.sub },
    });
    if (
      !adminUser ||
      adminUser.role !== PrismaRole.ADMIN ||
      adminUser.isBanned ||
      adminUser.isSuspended
    ) {
      throw new UnauthorizedException('Unauthorized');
    }

    request.adminUser = adminUser;
    return true;
  }
}
