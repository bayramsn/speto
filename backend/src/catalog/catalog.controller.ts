import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { CatalogService } from './catalog.service';

@ApiTags('catalog')
@Controller('catalog')
export class CatalogController {
  constructor(private readonly catalogService: CatalogService) {}

  @Get('bootstrap')
  bootstrap(): Promise<unknown> {
    return this.catalogService.bootstrap();
  }

  @Get('restaurants')
  restaurants(): Promise<unknown[]> {
    return this.catalogService.restaurants();
  }

  @Get('events')
  events(): Promise<unknown[]> {
    return this.catalogService.events();
  }
}
