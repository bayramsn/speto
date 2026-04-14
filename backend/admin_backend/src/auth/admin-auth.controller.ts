import { Body, Controller, Get, Post, Req } from '@nestjs/common';
import { User as PrismaUser } from '@prisma/client';

import { Public } from './public.decorator';
import { AdminAuthService } from './admin-auth.service';

type AdminRequest = {
  adminUser?: PrismaUser;
};

@Controller('admin/auth')
export class AdminAuthController {
  constructor(private readonly adminAuthService: AdminAuthService) {}

  @Post('login')
  @Public()
  login(@Body() payload: Record<string, unknown>) {
    return this.adminAuthService.login(
      typeof payload.email === 'string' ? payload.email : '',
      typeof payload.password === 'string' ? payload.password : '',
    );
  }

  @Post('refresh')
  @Public()
  refresh(@Body() payload: Record<string, unknown>) {
    return this.adminAuthService.refresh(
      typeof payload.refreshToken === 'string' ? payload.refreshToken : '',
    );
  }

  @Post('logout')
  @Public()
  logout(@Body() payload: Record<string, unknown>) {
    return this.adminAuthService.logout(
      typeof payload.refreshToken === 'string' ? payload.refreshToken : '',
    );
  }

  @Get('me')
  me(@Req() req: AdminRequest) {
    return this.adminAuthService.me(req.adminUser);
  }
}
