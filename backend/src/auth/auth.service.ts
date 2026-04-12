import { Injectable } from '@nestjs/common';

import { AppDataService } from '../app-data/app-data.service';
import { LoginDto } from './dto/login.dto';
import { OperatorRegisterDto } from './dto/operator-register.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(private readonly appDataService: AppDataService) {}

  register(payload: RegisterDto) {
    return this.appDataService.register(payload);
  }

  login(payload: LoginDto) {
    return this.appDataService.login(payload.email, payload.password);
  }

  operatorRegister(payload: OperatorRegisterDto) {
    return this.appDataService.registerOperator(payload);
  }

  requestPasswordReset(email: string) {
    return this.appDataService.requestPasswordReset(email);
  }

  accountExists(email: string) {
    return this.appDataService.accountExists(email);
  }

  updatePassword(email: string, password: string) {
    return this.appDataService.updatePassword(email, password);
  }

  verifyPasswordResetOtp(email: string, code: string) {
    return this.appDataService.verifyPasswordResetOtp(email, code);
  }

  refresh(refreshToken: string) {
    return this.appDataService.refreshSession(refreshToken);
  }

  logout(refreshToken?: string) {
    return this.appDataService.logout(refreshToken);
  }

  capabilities() {
    return this.appDataService.getCapabilities();
  }
}
