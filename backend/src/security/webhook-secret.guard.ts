import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';

@Injectable()
export class WebhookSecretGuard implements CanActivate {
  canActivate(context: ExecutionContext) {
    const expectedSecret = (process.env.INTEGRATION_WEBHOOK_SECRET ?? '').trim();
    if (expectedSecret.length === 0) {
      throw new ForbiddenException('Webhook secret is not configured');
    }
    const request = context.switchToHttp().getRequest<{
      headers?: Record<string, string | string[] | undefined>;
    }>();
    const headerValue = request.headers?.['x-speto-webhook-secret'];
    const providedSecret = Array.isArray(headerValue)
      ? (headerValue[0] ?? '').trim()
      : (headerValue ?? '').trim();
    if (providedSecret == expectedSecret) {
      return true;
    }
    throw new ForbiddenException('Invalid webhook secret');
  }
}
