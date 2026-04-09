import { Module } from '@nestjs/common';

import { AppDataModule } from '../app-data/app-data.module';
import { InventoryController } from './inventory.controller';
import { InventoryService } from './inventory.service';

@Module({
  imports: [AppDataModule],
  controllers: [InventoryController],
  providers: [InventoryService],
})
export class InventoryModule {}
