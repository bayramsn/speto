import { Injectable } from '@nestjs/common';

import { AppDataService, OpsOrderStatus } from '../app-data/app-data.service';
import { CreateVendorBankAccountDto } from './dto/create-vendor-bank-account.dto';
import { CreateVendorCampaignDto } from './dto/create-vendor-campaign.dto';
import { CreateVendorPayoutDto } from './dto/create-vendor-payout.dto';
import { UpdateVendorCampaignDto } from './dto/update-vendor-campaign.dto';

@Injectable()
export class OpsService {
  constructor(private readonly appDataService: AppDataService) {}

  listOrders(vendorId?: string) {
    return this.appDataService.listOpsOrders(vendorId);
  }

  updateOrderStatus(orderId: string, status: OpsOrderStatus) {
    return this.appDataService.updateOrderStatus(orderId, status);
  }

  financeSummary(vendorId?: string) {
    return this.appDataService.getVendorFinanceSummary(vendorId);
  }

  financeAccounts(vendorId?: string) {
    return this.appDataService.listVendorBankAccounts(vendorId);
  }

  createFinanceAccount(payload: CreateVendorBankAccountDto) {
    return this.appDataService.createVendorBankAccount(payload);
  }

  createPayout(payload: CreateVendorPayoutDto) {
    return this.appDataService.createVendorPayout(payload);
  }

  campaignSummary(vendorId?: string) {
    return this.appDataService.getVendorCampaignSummary(vendorId);
  }

  listCampaigns(vendorId?: string) {
    return this.appDataService.listVendorCampaigns(vendorId);
  }

  createCampaign(payload: CreateVendorCampaignDto) {
    return this.appDataService.createVendorCampaign(payload);
  }

  updateCampaign(campaignId: string, payload: UpdateVendorCampaignDto) {
    return this.appDataService.updateVendorCampaign(campaignId, payload);
  }

  toggleCampaign(campaignId: string) {
    return this.appDataService.toggleVendorCampaign(campaignId);
  }
}
