import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { ContentBlockType as PrismaContentBlockType, Role as PrismaRole } from '@prisma/client';
import { ApiTags } from '@nestjs/swagger';

import { Public } from '../security/public.decorator';
import { Roles } from '../security/roles.decorator';
import { CatalogService } from './catalog.service';

@ApiTags('catalog')
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('bootstrap')
  @Public()
  bootstrap(): Promise<unknown> {
    return this.catalogService.bootstrap();
  }

  @Get('restaurants')
  @Public()
  restaurants(): Promise<unknown[]> {
    return this.catalogService.restaurants();
  }

  @Get('events')
  @Public()
  events(): Promise<unknown[]> {
    return this.catalogService.events();
  }

  @Get('markets')
  @Public()
  markets(): Promise<unknown[]> {
    return this.catalogService.markets();
  }

  @Get('vendors/:vendorId')
  @Public()
  vendor(@Param('vendorId') vendorId: string): Promise<unknown> {
    return this.catalogService.vendor(vendorId);
  }

  @Get('vendors/:vendorId/sections')
  @Public()
  vendorSections(@Param('vendorId') vendorId: string): Promise<unknown[]> {
    return this.catalogService.vendorSections(vendorId);
  }

  @Get('vendors/:vendorId/products')
  @Public()
  vendorProducts(@Param('vendorId') vendorId: string): Promise<unknown[]> {
    return this.catalogService.vendorProducts(vendorId);
  }

  @Get('events/:eventId')
  @Public()
  event(@Param('eventId') eventId: string): Promise<unknown> {
    return this.catalogService.event(eventId);
  }

  @Get('admin/vendors')
  @Roles(PrismaRole.ADMIN)
  adminVendors(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.catalogService.adminVendors(vendorId);
  }

  @Post('admin/vendors')
  @Roles(PrismaRole.ADMIN)
  createVendor(@Body() payload: Record<string, unknown>): Promise<unknown> {
    return this.catalogService.createVendor(payload);
  }

  @Patch('admin/vendors/:vendorId')
  @Roles(PrismaRole.ADMIN)
  updateVendor(
    @Param('vendorId') vendorId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateVendor(vendorId, payload);
  }

  @Get('admin/sections')
  @Roles(PrismaRole.ADMIN)
  adminSections(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.catalogService.adminSections(vendorId);
  }

  @Post('admin/sections')
  @Roles(PrismaRole.ADMIN)
  createSection(@Body() payload: Record<string, unknown>): Promise<unknown> {
    return this.catalogService.createSection(payload);
  }

  @Patch('admin/sections/:sectionId')
  @Roles(PrismaRole.ADMIN)
  updateSection(
    @Param('sectionId') sectionId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateSection(sectionId, payload);
  }

  @Get('admin/products')
  @Roles(PrismaRole.ADMIN)
  adminProducts(@Query('vendorId') vendorId?: string): Promise<unknown[]> {
    return this.catalogService.adminProducts(vendorId);
  }

  @Post('admin/products')
  @Roles(PrismaRole.ADMIN)
  createProduct(@Body() payload: Record<string, unknown>): Promise<unknown> {
    return this.catalogService.createProduct(payload);
  }

  @Patch('admin/products/:productId')
  @Roles(PrismaRole.ADMIN)
  updateProduct(
    @Param('productId') productId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateProduct(productId, payload);
  }

  @Get('admin/events')
  @Roles(PrismaRole.ADMIN)
  adminEvents(): Promise<unknown[]> {
    return this.catalogService.adminEvents();
  }

  @Patch('admin/events/:eventId')
  @Roles(PrismaRole.ADMIN)
  updateEvent(
    @Param('eventId') eventId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateEvent(eventId, payload);
  }

  @Get('admin/content-blocks')
  @Roles(PrismaRole.ADMIN)
  adminContentBlocks(
    @Query('type') type?: PrismaContentBlockType,
  ): Promise<unknown[]> {
    return this.catalogService.adminContentBlocks(type);
  }

  @Patch('admin/content-blocks/:blockId')
  @Roles(PrismaRole.ADMIN)
  updateContentBlock(
    @Param('blockId') blockId: string,
    @Body() payload: Record<string, unknown>,
  ): Promise<unknown> {
    return this.catalogService.updateContentBlock(blockId, payload);
  }
}
