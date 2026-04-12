import { Module } from '@nestjs/common';

import { AppDataModule } from '../app-data/app-data.module';
import { OpsCampaignsController } from './ops-campaigns.controller';
import { OpsFinanceController } from './ops-finance.controller';
import { OpsController } from './ops.controller';
import { OpsService } from './ops.service';

@Module({
  imports: [AppDataModule],
  controllers: [OpsController, OpsFinanceController, OpsCampaignsController],
  providers: [OpsService],
})
export class OpsModule {}
