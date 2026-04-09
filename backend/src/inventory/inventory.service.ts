import { Injectable } from '@nestjs/common';

import { AppDataService } from '../app-data/app-data.service';

@Injectable()
export class InventoryService {
  constructor(private readonly appDataService: AppDataService) {}

  dashboard(vendorId?: string, query?: string): Promise<unknown> {
    return this.appDataService.getInventoryDashboard(vendorId, query);
  }

  listItems(vendorId?: string, query?: string): Promise<unknown[]> {
    return this.appDataService.listInventoryItems(vendorId, query);
  }

  getItem(itemId: string): Promise<unknown> {
    return this.appDataService.getInventoryItem(itemId);
  }

  adjustItem(
    itemId: string,
    quantityDelta: number,
    reason: string,
  ): Promise<unknown> {
    return this.appDataService.adjustInventory(itemId, quantityDelta, reason);
  }

  restockItem(
    itemId: string,
    quantity: number,
    note: string,
  ): Promise<unknown> {
    return this.appDataService.restockInventory(itemId, quantity, note);
  }

  movements(vendorId?: string, productId?: string): Promise<unknown[]> {
    return this.appDataService.listInventoryMovements(vendorId, productId);
  }
}
