import { Injectable } from '@nestjs/common';
import { ContentBlockType as PrismaContentBlockType } from '@prisma/client';

import { AppDataService } from '../app-data/app-data.service';

@Injectable()
export class CatalogService {
  constructor(private readonly appDataService: AppDataService) {}

  bootstrap(): Promise<unknown> {
    return this.appDataService.getBootstrap();
  }

  restaurants(): Promise<unknown[]> {
    return this.appDataService.listRestaurants();
  }

  events(): Promise<unknown[]> {
    return this.appDataService.listEvents();
  }

  markets(): Promise<unknown[]> {
    return this.appDataService.listMarkets();
  }

  vendor(vendorId: string): Promise<unknown> {
    return this.appDataService.getVendorCatalog(vendorId);
  }

  vendorSections(vendorId: string): Promise<unknown[]> {
    return this.appDataService.listVendorSections(vendorId);
  }

  vendorProducts(vendorId: string): Promise<unknown[]> {
    return this.appDataService.listVendorProducts(vendorId);
  }

  event(eventId: string): Promise<unknown> {
    return this.appDataService.getEventDetail(eventId);
  }

  adminVendors(vendorId?: string): Promise<unknown[]> {
    return this.appDataService.listCatalogAdminVendors(vendorId);
  }

  createVendor(payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.createCatalogVendor(payload);
  }

  updateVendor(vendorId: string, payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.updateCatalogVendor(vendorId, payload);
  }

  adminSections(vendorId?: string): Promise<unknown[]> {
    return this.appDataService.listCatalogAdminSections(vendorId);
  }

  createSection(payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.createCatalogSection(payload);
  }

  updateSection(sectionId: string, payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.updateCatalogSection(sectionId, payload);
  }

  adminProducts(vendorId?: string): Promise<unknown[]> {
    return this.appDataService.listCatalogAdminProducts(vendorId);
  }

  createProduct(payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.createCatalogProduct(payload);
  }

  updateProduct(productId: string, payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.updateCatalogProduct(productId, payload);
  }

  adminEvents(): Promise<unknown[]> {
    return this.appDataService.listCatalogAdminEvents();
  }

  updateEvent(eventId: string, payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.updateCatalogEvent(eventId, payload);
  }

  adminContentBlocks(type?: PrismaContentBlockType): Promise<unknown[]> {
    return this.appDataService.listCatalogContentBlocks(type);
  }

  updateContentBlock(blockId: string, payload: Record<string, unknown>): Promise<unknown> {
    return this.appDataService.updateCatalogContentBlock(blockId, payload);
  }
}
