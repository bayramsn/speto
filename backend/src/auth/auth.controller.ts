import { Body, Controller, Get, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { PasswordRequestDto } from './dto/password-request.dto';
import { PasswordUpdateDto } from './dto/password-update.dto';
import { RegisterDto } from './dto/register.dto';

@ApiTags('auth')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('register')
  register(@Body() payload: RegisterDto) {
    return this.authService.register(payload);
  }

  @Post('login')
  login(@Body() payload: LoginDto) {
    return this.authService.login(payload);
  }

  @Post('password/request')
  requestPasswordReset(@Body() payload: PasswordRequestDto) {
    return this.authService.requestPasswordReset(payload.email);
  }

  @Post('password/update')
  updatePassword(@Body() payload: PasswordUpdateDto) {
    return this.authService.updatePassword(payload.email, payload.password);
  }

  @Get('capabilities')
  capabilities() {
    return this.authService.capabilities();
  }
}
