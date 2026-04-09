import { Body, Controller, Delete, Get, Param, Put, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { EmailValueDto } from './dto/email-value.dto';
import { PasswordValueDto } from './dto/password-value.dto';
import { ClientStateService } from './client-state.service';

@ApiTags('client-state')
@Controller('client-state')
export class ClientStateController {
  constructor(private readonly clientStateService: ClientStateService) {}

  @Get('session')
  readSession() {
    return this.clientStateService.readSession();
  }

  @Put('session')
  writeSession(@Body() payload: unknown) {
    return this.clientStateService.writeSession(payload);
  }

  @Delete('session')
  clearSession() {
    return this.clientStateService.clearSession();
  }

  @Get('registration-draft')
  readRegistrationDraft() {
    return this.clientStateService.readRegistrationDraft();
  }

  @Put('registration-draft')
  writeRegistrationDraft(@Body() payload: unknown) {
    return this.clientStateService.writeRegistrationDraft(payload);
  }

  @Delete('registration-draft')
  clearRegistrationDraft() {
    return this.clientStateService.clearRegistrationDraft();
  }

  @Get('password-reset-email')
  readPasswordResetEmail() {
    return this.clientStateService.readPasswordResetEmail();
  }

  @Put('password-reset-email')
  writePasswordResetEmail(@Body() payload: EmailValueDto) {
    return this.clientStateService.writePasswordResetEmail(payload.email);
  }

  @Delete('password-reset-email')
  clearPasswordResetEmail() {
    return this.clientStateService.clearPasswordResetEmail();
  }

  @Get('account-passwords/:email')
  readAccountPassword(@Param('email') email: string) {
    return this.clientStateService.readAccountPassword(email);
  }

  @Put('account-passwords/:email')
  writeAccountPassword(
    @Param('email') email: string,
    @Body() payload: PasswordValueDto,
  ) {
    return this.clientStateService.writeAccountPassword(email, payload.password);
  }

  @Delete('account-passwords/:email')
  deleteAccountPassword(@Param('email') email: string) {
    return this.clientStateService.deleteAccountPassword(email);
  }

  @Get('commerce-snapshot')
  readCommerceSnapshot(@Query('scopeKey') scopeKey?: string) {
    return this.clientStateService.readCommerceSnapshot(scopeKey);
  }

  @Put('commerce-snapshot')
  writeCommerceSnapshot(
    @Query('scopeKey') scopeKey: string | undefined,
    @Body() payload: unknown,
  ) {
    return this.clientStateService.writeCommerceSnapshot(payload, scopeKey);
  }
}
