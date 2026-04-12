import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { Role as PrismaRole } from '@prisma/client';
import { ApiTags } from '@nestjs/swagger';

import { Public } from '../security/public.decorator';
import { Roles } from '../security/roles.decorator';
import { WebhookSecretGuard } from '../security/webhook-secret.guard';
import { CreateIntegrationDto } from './dto/create-integration.dto';
import { IntegrationWebhookDto } from './dto/integration-webhook.dto';
import { IntegrationsService } from './integrations.service';

@ApiTags('integrations')
@Controller('integrations')
export class IntegrationsController {
  constructor(private readonly integrationsService: IntegrationsService) {}

  @Get()
  @Roles(PrismaRole.ADMIN, PrismaRole.VENDOR)
  list(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.integrationsService.list(vendorId);
  }

  @Post()
  @Roles(PrismaRole.ADMIN, PrismaRole.VENDOR)
  create(@Body() payload: CreateIntegrationDto): Promise<unknown> {
    return this.integrationsService.create(payload);
  }

  @Post(':id/sync')
  @Roles(PrismaRole.ADMIN, PrismaRole.VENDOR)
  sync(@Param('id') id: string): Promise<unknown> {
    return this.integrationsService.sync(id);
  }

  @Post(':id/webhook')
  @Public()
  @Roles()
  @UseGuards(WebhookSecretGuard)
  webhook(
    @Param('id') id: string,
    @Body() payload: IntegrationWebhookDto,
  ): Promise<unknown> {
    return this.integrationsService.webhook(id, payload);
  }
}
