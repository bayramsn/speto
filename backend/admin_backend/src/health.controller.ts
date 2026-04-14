import { Controller, Get } from '@nestjs/common';

import { Public } from './auth/public.decorator';

@Controller('health')
export class HealthController {
  @Get()
  @Public()
  health() {
    return {
      ok: true,
      service: 'speto-admin-backend',
      timestamp: new Date().toISOString(),
    };
  }
}
