import { Body, Controller, Get, Param, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { AppDataService } from '../app-data/app-data.service';
import { RedeemTicketDto } from './dto/redeem-ticket.dto';

@ApiTags('wallet')
@Controller()
export class WalletController {
  constructor(private readonly appDataService: AppDataService) {}

  @Get('wallet')
  getWallet() {
    return this.appDataService.getWallet();
  }

  @Get('tickets')
  listTickets() {
    return this.appDataService.listTickets();
  }

  @Post('wallet/redeem/:eventId')
  redeem(@Param('eventId') eventId: string, @Body() payload: RedeemTicketDto) {
    return this.appDataService.redeemEventTicket(eventId, payload);
  }
}
