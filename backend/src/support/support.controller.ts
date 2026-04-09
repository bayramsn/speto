import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { AppDataService } from '../app-data/app-data.service';
import { CreateSupportTicketDto } from './dto/create-support-ticket.dto';

@ApiTags('support')
@Controller('support')
export class SupportController {
  constructor(private readonly appDataService: AppDataService) {}

  @Get('tickets')
  listTickets() {
    return this.appDataService.listSupportTickets();
  }

  @Post('tickets')
  createTicket(@Body() payload: CreateSupportTicketDto) {
    return this.appDataService.createSupportTicket(payload);
  }
}
