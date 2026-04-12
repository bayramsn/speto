import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { Role as PrismaRole } from '@prisma/client';
import { ApiTags } from '@nestjs/swagger';

import { Roles } from '../security/roles.decorator';
import { CreateVendorBankAccountDto } from './dto/create-vendor-bank-account.dto';
import { CreateVendorPayoutDto } from './dto/create-vendor-payout.dto';
import { OpsService } from './ops.service';

@ApiTags('ops-finance')
@Roles(PrismaRole.ADMIN, PrismaRole.VENDOR)
@Controller('ops/finance')
export class OpsFinanceController {
  constructor(private readonly opsService: OpsService) {}

  @Get('summary')
  summary(@Query('vendorId') vendorId?: string) {
    return this.opsService.financeSummary(vendorId);
  }

  @Get('accounts')
  accounts(@Query('vendorId') vendorId?: string) {
    return this.opsService.financeAccounts(vendorId);
  }

  @Post('accounts')
  createAccount(@Body() payload: CreateVendorBankAccountDto) {
    return this.opsService.createFinanceAccount(payload);
  }

  @Post('payouts')
  createPayout(@Body() payload: CreateVendorPayoutDto) {
    return this.opsService.createPayout(payload);
  }
}
