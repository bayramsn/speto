import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Throttle } from '@nestjs/throttler';

import { Public } from '../security/public.decorator';
import { AuthService } from './auth.service';
import { AccountExistsDto } from './dto/account-exists.dto';
import { LoginDto } from './dto/login.dto';
import { LogoutDto } from './dto/logout.dto';
import { OperatorRegisterDto } from './dto/operator-register.dto';
import { PasswordRequestDto } from './dto/password-request.dto';
import { PasswordUpdateDto } from './dto/password-update.dto';
import { PasswordVerifyOtpDto } from './dto/password-verify-otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { RegisterDto } from './dto/register.dto';

@ApiTags('auth')
@Public()
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  register(@Body() payload: RegisterDto) {
    return this.authService.register(payload);
  }

  @Post('login')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  login(@Body() payload: LoginDto) {
    return this.authService.login(payload);
  }

  @Post('operator-register')
  @Throttle({ default: { limit: 3, ttl: 60_000 } })
  operatorRegister(@Body() payload: OperatorRegisterDto) {
    return this.authService.operatorRegister(payload);
  }

  @Post('password/request')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  requestPasswordReset(@Body() payload: PasswordRequestDto) {
    return this.authService.requestPasswordReset(payload.email);
  }

  @Post('account-exists')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  accountExists(@Body() payload: AccountExistsDto) {
    return this.authService.accountExists(payload.email);
  }

  @Post('password/update')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  updatePassword(@Body() payload: PasswordUpdateDto) {
    return this.authService.updatePassword(payload.email, payload.password);
  }

  @Post('password/verify-otp')
  @Throttle({ default: { limit: 5, ttl: 60_000 } })
  verifyPasswordResetOtp(@Body() payload: PasswordVerifyOtpDto) {
    return this.authService.verifyPasswordResetOtp(payload.email, payload.code);
  }

  @Post('refresh')
  @Throttle({ default: { limit: 10, ttl: 60_000 } })
  refresh(@Body() payload: RefreshTokenDto) {
    return this.authService.refresh(payload.refreshToken);
  }

  @Post('logout')
  logout(@Body() payload: LogoutDto) {
    return this.authService.logout(payload.refreshToken);
  }

  @Get('capabilities')
  capabilities() {
    return this.authService.capabilities();
  }
}
