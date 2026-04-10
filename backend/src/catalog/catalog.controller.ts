import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ContentBlockType as PrismaContentBlockType } from '@prisma/client';
import { ApiTags } from '@nestjs/swagger';

import { CatalogService } from './catalog.service';

@ApiTags('catalog')
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('bootstrap')
  bootstrap(): Promise<unknown> {
    return this.catalogService.bootstrap();
  }

  @Get('restaurants')
  restaurants(): Promise<unknown[]> {
    return this.catalogService.restaurants();
  }

  @Get('events')
  events(): Promise<unknown[]> {
    return this.catalogService.events();
  }

  @Get('markets')
  markets(): Promise<unknown[]> {
    return this.catalogService.markets();
  }

  @Get('vendors/:vendorId')
  vendor(@Param('vendorId') vendorId: string): Promise<unknown> {
    return this.catalogService.vendor(vendorId);
  }

  @Get('vendors/:vendorId/sections')
  vendorSections(@Param('vendorId') vendorId: string): Promise<unknown[]> {
    return this.catalogService.vendorSections(vendorId);
  }

  @Get('vendors/:vendorId/products')
  vendorProducts(@Param('vendorId') vendorId: string): Promise<unknown[]> {
    return this.catalogService.vendorProducts(vendorId);
  }

  @Get('events/:eventId')
  event(@Param('eventId') eventId: string): Promise<unknown> {
    return this.catalogService.event(eventId);
  }

  @Get('admin/vendors')
  adminVendors(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.catalogService.adminVendors(vendorId);
  }

  @Post('admin/vendors')
  createVendor(@Body() payload: Record<string, unknown>): Promise<unknown> {
    return this.catalogService.createVendor(payload);
  }

  @Patch('admin/vendors/:vendorId')
  updateVendor(
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateVendor(vendorId, payload);
  }

  @Get('admin/sections')
  adminSections(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.catalogService.adminSections(vendorId);
  }

  @Post('admin/sections')
  createSection(@Body() payload: Record<string, unknown>): Promise<unknown> {
    return this.catalogService.createSection(payload);
  }

  @Patch('admin/sections/:sectionId')
  updateSection(
    @Param('sectionId') sectionId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateSection(sectionId, payload);
  }

  @Get('admin/products')
  adminProducts(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.catalogService.adminProducts(vendorId);
  }

  @Post('admin/products')
  createProduct(@Body() payload: Record<string, unknown>): Promise<unknown> {
    return this.catalogService.createProduct(payload);
  }

  @Patch('admin/products/:productId')
  updateProduct(
    @Param('productId') productId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateProduct(productId, payload);
  }

  @Get('admin/events')
  adminEvents(): Promise<unknown[]> {
    return this.catalogService.adminEvents();
  }

  @Patch('admin/events/:eventId')
  updateEvent(
    @Param('eventId') eventId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateEvent(eventId, payload);
  }

  @Get('admin/content-blocks')
  adminContentBlocks(
    @Query('type') type?: PrismaContentBlockType,
  ): Promise<unknown[]> {
    return this.catalogService.adminContentBlocks(type);
  }

  @Patch('admin/content-blocks/:blockId')
  updateContentBlock(
    @Param('blockId') blockId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateContentBlock(blockId, payload);
  }
}
