import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CreateIntegrationDto } from './dto/create-integration.dto';
import { IntegrationWebhookDto } from './dto/integration-webhook.dto';
import { IntegrationsService } from './integrations.service';

@ApiTags('integrations')
@Controller('integrations')
export class IntegrationsController {
  constructor(private readonly integrationsService: IntegrationsService) {}

  @Get()
  list(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.integrationsService.list(vendorId);
  }

  @Post()
  create(@Body() payload: CreateIntegrationDto): Promise<unknown> {
    return this.integrationsService.create(payload);
  }

  @Post(':id/sync')
  sync(@Param('id') id: string): Promise<unknown> {
    return this.integrationsService.sync(id);
  }

  @Post(':id/webhook')
  webhook(
    @Param('id') id: string,
    @Body() payload: IntegrationWebhookDto,
  ): Promise<unknown> {
    return this.integrationsService.webhook(id, payload);
  }
}
