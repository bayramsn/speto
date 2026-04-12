import { Body, Controller, Delete, Get, NotFoundException, Param, Put, Query } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { EmailValueDto } from './dto/email-value.dto';
import { PasswordValueDto } from './dto/password-value.dto';
import { ClientStateService } from './client-state.service';
import { Public } from '../security/public.decorator';

@ApiTags('client-state')
@Public()
@Controller('client-state')
export class ClientStateController {
  constructor(private readonly clientStateService: ClientStateService) {}

  private assertEnabled() {
    const enabled =
      (process.env.ENABLE_DEV_CLIENT_STATE ?? 'false').trim().toLowerCase() ===
      'true';
    if (!enabled) {
      throw new NotFoundException();
    }
  }

  @Get('session')
  readSession() {
    this.assertEnabled();
    return this.clientStateService.readSession();
  }

  @Put('session')
  writeSession(@Body() payload: unknown) {
    this.assertEnabled();
    return this.clientStateService.writeSession(payload);
  }

  @Delete('session')
  clearSession() {
    this.assertEnabled();
    return this.clientStateService.clearSession();
  }

  @Get('registration-draft')
  readRegistrationDraft() {
    this.assertEnabled();
    return this.clientStateService.readRegistrationDraft();
  }

  @Put('registration-draft')
  writeRegistrationDraft(@Body() payload: unknown) {
    this.assertEnabled();
    return this.clientStateService.writeRegistrationDraft(payload);
  }

  @Delete('registration-draft')
  clearRegistrationDraft() {
    this.assertEnabled();
    return this.clientStateService.clearRegistrationDraft();
  }

  @Get('password-reset-email')
  readPasswordResetEmail() {
    this.assertEnabled();
    return this.clientStateService.readPasswordResetEmail();
  }

  @Put('password-reset-email')
  writePasswordResetEmail(@Body() payload: EmailValueDto) {
    this.assertEnabled();
    return this.clientStateService.writePasswordResetEmail(payload.email);
  }

  @Delete('password-reset-email')
  clearPasswordResetEmail() {
    this.assertEnabled();
    return this.clientStateService.clearPasswordResetEmail();
  }

  @Get('account-passwords/:email')
  readAccountPassword(@Param('email') email: string) {
    this.assertEnabled();
    return this.clientStateService.readAccountPassword(email);
  }

  @Put('account-passwords/:email')
  writeAccountPassword(
    @Param('email') email: string,
    @Body() payload: PasswordValueDto,
  ) {
    this.assertEnabled();
    return this.clientStateService.writeAccountPassword(email, payload.password);
  }

  @Delete('account-passwords/:email')
  deleteAccountPassword(@Param('email') email: string) {
    this.assertEnabled();
    return this.clientStateService.deleteAccountPassword(email);
  }

  @Get('commerce-snapshot')
  readCommerceSnapshot(@Query('scopeKey') scopeKey?: string) {
    this.assertEnabled();
    return this.clientStateService.readCommerceSnapshot(scopeKey);
  }

  @Put('commerce-snapshot')
  writeCommerceSnapshot(
    @Query('scopeKey') scopeKey: string | undefined,
    @Body() payload: unknown,
  ) {
    this.assertEnabled();
    return this.clientStateService.writeCommerceSnapshot(payload, scopeKey);
  }
}
