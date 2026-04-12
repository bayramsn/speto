import { Injectable, NestMiddleware } from '@nestjs/common';

import { RequestContextService } from './request-context.service';
import { JwtTokenService } from '../security/jwt-token.service';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  constructor(
    private readonly requestContext: RequestContextService,
    private readonly jwtTokenService: JwtTokenService,
  ) {}

  use(
    request: { headers?: Record<string, string | string[] | undefined> },
    _: unknown,
    next: () => void,
  ) {
    const authorizationHeader = request.headers?.authorization;
    const headerValue = Array.isArray(authorizationHeader)
      ? authorizationHeader[0]
      : authorizationHeader;
    const accessToken = headerValue?.startsWith('Bearer ')
      ? headerValue.slice('Bearer '.length).trim()
      : undefined;
    const payload =
      accessToken == null ? null : this.jwtTokenService.verifyAccessToken(accessToken);

    this.requestContext.run(
      {
        accessToken,
        userId: payload?.sub,
        email: payload?.email,
        role: payload?.role,
        vendorId: payload?.vendorId ?? null,
      },
      () => next(),
    );
  }
}
