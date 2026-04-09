import { Global, Module } from '@nestjs/common';

import { PrismaModule } from '../prisma/prisma.module';
import { AppDataService } from './app-data.service';
import { RequestContextService } from './request-context.service';

@Global()
@Module({
  imports: [PrismaModule],
  providers: [AppDataService, RequestContextService],
  exports: [AppDataService, RequestContextService],
})
export class AppDataModule {}
