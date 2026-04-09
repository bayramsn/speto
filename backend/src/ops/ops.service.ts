import { Injectable } from '@nestjs/common';

import { AppDataService, OpsOrderStatus } from '../app-data/app-data.service';

@Injectable()
export class OpsService {
  constructor(private readonly appDataService: AppDataService) {}

  listOrders(vendorId?: string) {
    return this.appDataService.listOpsOrders(vendorId);
  }

  updateOrderStatus(orderId: string, status: OpsOrderStatus) {
    return this.appDataService.updateOrderStatus(orderId, status);
  }
}
