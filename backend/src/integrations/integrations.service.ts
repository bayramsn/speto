import { Injectable } from '@nestjs/common';

import { AppDataService, IntegrationType } from '../app-data/app-data.service';

@Injectable()
export class IntegrationsService {
  constructor(private readonly appDataService: AppDataService) {}

  list(vendorId?: string): Promise<unknown[]> {
    return this.appDataService.listIntegrations(vendorId);
  }

  create(payload: {
    vendorId: string;
    name: string;
    provider: string;
    type: IntegrationType;
    baseUrl: string;
    locationId: string;
    skuMappings: Record<string, string>;
  }): Promise<unknown> {
    return this.appDataService.createIntegration(payload);
  }

  sync(connectionId: string): Promise<unknown> {
    return this.appDataService.syncIntegration(connectionId);
  }

  webhook(
    connectionId: string,
    payload: { records: Array<{ sku: string; quantity: number }> },
  ): Promise<unknown> {
    return this.appDataService.receiveIntegrationWebhook(connectionId, payload);
  }
}
