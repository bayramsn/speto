import { Controller, Get, Module, Post, UseGuards } from '@nestjs/common';
import { FastifyAdapter, NestFastifyApplication } from '@nestjs/platform-fastify';
import { Test } from '@nestjs/testing';
import { Role as PrismaRole } from '@prisma/client';

import { AccessTokenPayload } from '../src/security/jwt-payload.interface';
import { JwtTokenService } from '../src/security/jwt-token.service';
import { Public } from '../src/security/public.decorator';
import { Roles } from '../src/security/roles.decorator';
import { SecurityModule } from '../src/security/security.module';
import { WebhookSecretGuard } from '../src/security/webhook-secret.guard';

@Controller()
class SecurityTestController {
  @Get('me')
  me() {
    return { ok: true };
  }

  @Get('ops/orders')
  @Roles(PrismaRole.ADMIN, PrismaRole.VENDOR)
  opsOrders() {
    return { ok: true };
  }

  @Post('integrations/example/webhook')
  @Public()
  @Roles()
  @UseGuards(WebhookSecretGuard)
  webhook() {
    return { ok: true };
  }
}

@Module({
  imports: [SecurityModule],
  controllers: [SecurityTestController],
})
class SecurityTestModule {}

describe('Security guards', () => {
  let app: NestFastifyApplication;
  let jwtTokenService: JwtTokenService;

  beforeAll(async () => {
    process.env.JWT_ACCESS_SECRET = 'test-access-secret';
    process.env.JWT_ACCESS_TTL_SECONDS = '900';
    process.env.INTEGRATION_WEBHOOK_SECRET = 'test-webhook-secret';

    const moduleRef = await Test.createTestingModule({
      imports: [SecurityTestModule],
    }).compile();

    app = moduleRef.createNestApplication<NestFastifyApplication>(
      new FastifyAdapter(),
    );
    await app.init();
    await app.getHttpAdapter().getInstance().ready();
    jwtTokenService = moduleRef.get(JwtTokenService);
  });

  afterAll(async () => {
    await app.close();
  });

  async function signToken(
    payload: Omit<AccessTokenPayload, 'sub'> & { userId: string },
  ) {
    const signed = await jwtTokenService.issueAccessToken({
      userId: payload.userId,
      email: payload.email,
      role: payload.role,
      vendorId: payload.vendorId,
    });
    return signed.token;
  }

  it('rejects forged access-* tokens', async () => {
    const response = await app.inject({
      method: 'GET',
      url: '/me',
      headers: {
        authorization: 'Bearer access-usr_customer_123',
      },
    });

    expect(response.statusCode).toBe(401);
  });

  it('blocks customer tokens from ops routes', async () => {
    const token = await signToken({
      userId: 'usr_customer_123',
      email: 'customer@example.com',
      role: PrismaRole.CUSTOMER,
      vendorId: null,
    });

    const response = await app.inject({
      method: 'GET',
      url: '/ops/orders',
      headers: {
        authorization: `Bearer ${token}`,
      },
    });

    expect(response.statusCode).toBe(403);
  });

  it('rejects webhook calls without the shared secret', async () => {
    const response = await app.inject({
      method: 'POST',
      url: '/integrations/example/webhook',
      payload: { ok: true },
    });

    expect(response.statusCode).toBe(403);
  });
});
