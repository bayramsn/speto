import { Controller, Get, Param } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { OffersService } from './offers.service';

@ApiTags('offers')
@Controller('offers')
export class OffersController {
  constructor(private readonly offersService: OffersService) {}

  @Get('happy-hour')
  happyHourList(): Promise<unknown[]> {
    return this.offersService.happyHourList();
  }

  @Get('happy-hour/:offerId')
  happyHourDetail(@Param('offerId') offerId: string): Promise<unknown> {
    return this.offersService.happyHourDetail(offerId);
  }
}
