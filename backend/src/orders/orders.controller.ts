import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CreateCheckoutSessionDto } from './dto/create-checkout-session.dto';
import { RateOrderDto } from './dto/rate-order.dto';
import { OrdersService } from './orders.service';

@ApiTags('orders')
@Controller('orders')
export class OrdersController {
  constructor(private readonly ordersService: OrdersService) {}

  @Get()
  listOrders() {
    return this.ordersService.listOrders();
  }

  @Get(':orderId')
  getOrder(@Param('orderId') orderId: string) {
    return this.ordersService.getOrder(orderId);
  }

  @Post('checkout-sessions')
  createCheckoutSession(@Body() payload: CreateCheckoutSessionDto) {
    return this.ordersService.createCheckoutSession(payload);
  }

  @Post('checkout')
  checkout(@Body() payload: CreateCheckoutSessionDto) {
    return this.ordersService.checkout(payload);
  }

  @Post(':orderId/complete')
  complete(@Param('orderId') orderId: string) {
    return this.ordersService.complete(orderId);
  }

  @Post(':orderId/rating')
  rate(@Param('orderId') orderId: string, @Body() payload: RateOrderDto) {
    return this.ordersService.rate(orderId, payload.stars);
  }
}
