import { Injectable, NestMiddleware } from '@nestjs/common';

import { RequestContextService } from './request-context.service';

@Injectable()
export class RequestContextMiddleware implements NestMiddleware {
  constructor(private readonly requestContext: RequestContextService) {}

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

    this.requestContext.run({ accessToken }, () => next());
  }
}
