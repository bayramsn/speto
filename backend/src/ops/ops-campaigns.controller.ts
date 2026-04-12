import { Body, Controller, Get, Param, Patch, Post, Query } from '@nestjs/common';
import { Role as PrismaRole } from '@prisma/client';
import { ApiTags } from '@nestjs/swagger';

import { Roles } from '../security/roles.decorator';
import { CreateVendorCampaignDto } from './dto/create-vendor-campaign.dto';
import { UpdateVendorCampaignDto } from './dto/update-vendor-campaign.dto';
import { OpsService } from './ops.service';

@ApiTags('ops-campaigns')
@Roles(PrismaRole.ADMIN, PrismaRole.VENDOR)
@Controller('ops/campaigns')
export class OpsCampaignsController {
  constructor(private readonly opsService: OpsService) {}

  @Get('summary')
  summary(@Query('vendorId') vendorId?: string) {
    return this.opsService.campaignSummary(vendorId);
  }

  @Get()
  list(@Query('vendorId') vendorId?: string) {
    return this.opsService.listCampaigns(vendorId);
  }

  @Post()
  create(@Body() payload: CreateVendorCampaignDto) {
    return this.opsService.createCampaign(payload);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() payload: UpdateVendorCampaignDto) {
    return this.opsService.updateCampaign(id, payload);
  }

  @Post(':id/toggle')
  toggle(@Param('id') id: string) {
    return this.opsService.toggleCampaign(id);
  }
}
