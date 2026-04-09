import { Injectable } from '@nestjs/common';

import { AppDataService } from '../app-data/app-data.service';
import { FulfillmentMode } from '../common/enums/fulfillment-mode.enum';
import { CreateCheckoutSessionDto } from './dto/create-checkout-session.dto';

@Injectable()
export class OrdersService {
  constructor(private readonly appDataService: AppDataService) {}

  async listOrders() {
    const orders = await this.appDataService.listOrders();
    return orders.map((order) => ({
      ...order,
      fulfillmentMode: FulfillmentMode.PICKUP,
      pickupPointLabel: order.deliveryAddress,
    }));
  }

  getOrder(orderId: string) {
    return this.appDataService.getOrder(orderId);
  }

  createCheckoutSession(payload: CreateCheckoutSessionDto) {
    return this.appDataService.createCheckoutSession(payload);
  }

  checkout(payload: CreateCheckoutSessionDto) {
    return this.appDataService.checkout(payload);
  }

  complete(orderId: string) {
    return this.appDataService.completeOrder(orderId);
  }
}
