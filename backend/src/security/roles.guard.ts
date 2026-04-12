import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { Role as PrismaRole } from '@prisma/client';

import { ROLES_KEY } from './roles.decorator';
import { AccessTokenPayload } from './jwt-payload.interface';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext) {
    const requiredRoles = this.reflector.getAllAndOverride<PrismaRole[]>(
      ROLES_KEY,
      [context.getHandler(), context.getClass()],
    );
    if (!requiredRoles || requiredRoles.length === 0) {
      return true;
    }
    const request = context
      .switchToHttp()
      .getRequest<{ user?: AccessTokenPayload }>();
    const role = request.user?.role;
    if (role != null && requiredRoles.includes(role)) {
      return true;
    }
    throw new ForbiddenException('Forbidden');
  }
}
