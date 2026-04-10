import { Injectable } from '@nestjs/common';

import { AppDataService } from '../app-data/app-data.service';

@Injectable()
export class OffersService {
  constructor(private readonly appDataService: AppDataService) {}

  happyHourList(): Promise<unknown[]> {
    return this.appDataService.listHappyHourOffers();
  }

  happyHourDetail(offerId: string): Promise<unknown> {
    return this.appDataService.getHappyHourOfferDetail(offerId);
  }
}
