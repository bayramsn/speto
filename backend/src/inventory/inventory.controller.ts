import { Body, Controller, Get, Param, Post, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { AdjustInventoryDto } from './dto/adjust-inventory.dto';
import { RestockInventoryDto } from './dto/restock-inventory.dto';
import { InventoryService } from './inventory.service';

@ApiTags('inventory')
@Controller('inventory')
export class InventoryController {
  constructor(private readonly inventoryService: InventoryService) {}

  @Get('dashboard')
  dashboard(
    @Query('vendorId') vendorId?: string,
    @Query('query') query?: string,
  ): Promise<unknown> {
    return this.inventoryService.dashboard(vendorId, query);
  }

  @Get('items')
  listItems(
    @Query('vendorId') vendorId?: string,
    @Query('query') query?: string,
  ): Promise<unknown[]> {
    return this.inventoryService.listItems(vendorId, query);
  }

  @Get('items/:id')
  getItem(@Param('id') id: string): Promise<unknown> {
    return this.inventoryService.getItem(id);
  }

  @Post('items/:id/adjust')
  adjustItem(
    @Param('id') id: string,
    @Body() payload: AdjustInventoryDto,
  ): Promise<unknown> {
    return this.inventoryService.adjustItem(id, payload.quantityDelta, payload.reason);
  }

  @Post('items/:id/restock')
  restockItem(
    @Param('id') id: string,
    @Body() payload: RestockInventoryDto,
  ): Promise<unknown> {
    return this.inventoryService.restockItem(id, payload.quantity, payload.note);
  }

  @Get('movements')
  movements(
    @Query('vendorId') vendorId?: string,
    @Query('productId') productId?: string,
  ): Promise<unknown[]> {
    return this.inventoryService.movements(vendorId, productId);
  }
}
