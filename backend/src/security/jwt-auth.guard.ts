import { ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';

import { RequestContextService } from '../app-data/request-context.service';
import { IS_PUBLIC_KEY } from './public.decorator';
import { AccessTokenPayload } from './jwt-payload.interface';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(
    private readonly reflector: Reflector,
    private readonly requestContext: RequestContextService,
  ) {
    super();
  }

  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) {
      return true;
    }
    return super.canActivate(context);
  }

  handleRequest<TUser extends AccessTokenPayload>(
    err: unknown,
    user: TUser | false | null,
  ) {
    if (err || !user) {
      throw err instanceof Error ? err : new UnauthorizedException('Unauthorized');
    }
    this.requestContext.setAuth({
      userId: user.sub,
      email: user.email,
      role: user.role,
      vendorId: user.vendorId ?? null,
    });
    return user;
  }
}
