import { Module } from '@nestjs/common';

import { AppDataModule } from '../app-data/app-data.module';
import { OpsController } from './ops.controller';
import { OpsService } from './ops.service';

@Module({
  imports: [AppDataModule],
  controllers: [OpsController],
  providers: [OpsService],
})
export class OpsModule {}
