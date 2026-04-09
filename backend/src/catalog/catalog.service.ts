import { Injectable } from '@nestjs/common';

import { AppDataService } from '../app-data/app-data.service';

@Injectable()
export class CatalogService {
  constructor(private readonly appDataService: AppDataService) {}

  bootstrap(): Promise<unknown> {
    return this.appDataService.getBootstrap();
  }

  restaurants(): Promise<unknown[]> {
    return this.appDataService.listRestaurants();
  }

  events(): Promise<unknown[]> {
    return this.appDataService.listEvents();
  }
}
