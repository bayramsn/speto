import { Injectable } from '@nestjs/common';

import { AppDataService } from '../app-data/app-data.service';
import { LoginDto } from './dto/login.dto';
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

  requestPasswordReset(email: string) {
    return this.appDataService.requestPasswordReset(email);
  }

  updatePassword(email: string, password: string) {
    return this.appDataService.updatePassword(email, password);
  }

  capabilities() {
    return this.appDataService.getCapabilities();
  }
}
