import { Body, Controller, Get, Param, Patch, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { UpdateOrderStatusDto } from './dto/update-order-status.dto';
import { OpsService } from './ops.service';

@ApiTags('ops')
@Controller('ops')
export class OpsController {
  constructor(private readonly opsService: OpsService) {}

  @Get('orders')
  listOrders(@Query('vendorId') vendorId?: string) {
    return this.opsService.listOrders(vendorId);
  }

  @Patch('orders/:id/status')
  updateStatus(@Param('id') id: string, @Body() payload: UpdateOrderStatusDto) {
    return this.opsService.updateOrderStatus(id, payload.status);
  }
}
