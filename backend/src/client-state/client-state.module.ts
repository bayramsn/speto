import { Module } from '@nestjs/common';

import { ClientStateController } from './client-state.controller';
import { ClientStateService } from './client-state.service';

@Module({
  controllers: [ClientStateController],
  providers: [ClientStateService],
})
export class ClientStateModule {}
