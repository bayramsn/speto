import { Global, Module } from '@nestjs/common';

import { PrismaModule } from '../prisma/prisma.module';
import { AppDataService } from './app-data.service';
import { RequestContextModule } from './request-context.module';

@Global()
@Module({
  imports: [PrismaModule, RequestContextModule],
  providers: [AppDataService],
  exports: [AppDataService, RequestContextModule],
})
export class AppDataModule {}
