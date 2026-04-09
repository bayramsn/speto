import { Body, Controller, Delete, Get, Param, Patch, Post } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';

import { AppDataService } from '../app-data/app-data.service';
import { CreateAddressDto } from './dto/create-address.dto';
import { CreatePaymentMethodDto } from './dto/create-payment-method.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@ApiTags('profile')
@Controller('me')
export class ProfileController {
  constructor(private readonly appDataService: AppDataService) {}

  @Get()
  getProfile() {
    return this.appDataService.getProfile();
  }

  @Get('snapshot')
  getSnapshot() {
    return this.appDataService.getSnapshot();
  }

  @Patch()
  updateProfile(@Body() payload: UpdateProfileDto) {
    return this.appDataService.updateProfile(payload);
  }

  @Delete()
  deleteProfile() {
    return this.appDataService.deleteAccount();
  }

  @Get('addresses')
  listAddresses() {
    return this.appDataService.listAddresses();
  }

  @Post('addresses')
  saveAddress(@Body() payload: CreateAddressDto) {
    return this.appDataService.saveAddress(payload);
  }

  @Delete('addresses/:id')
  deleteAddress(@Param('id') id: string) {
    return this.appDataService.deleteAddress(id);
  }

  @Get('payment-methods')
  listPaymentMethods() {
    return this.appDataService.listPaymentMethods();
  }

  @Post('payment-methods')
  savePaymentMethod(@Body() payload: CreatePaymentMethodDto) {
    return this.appDataService.savePaymentMethod(payload);
  }

  @Delete('payment-methods/:id')
  deletePaymentMethod(@Param('id') id: string) {
    return this.appDataService.deletePaymentMethod(id);
  }
}
