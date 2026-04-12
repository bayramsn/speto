import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsEmail,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  MinLength,
  ValidateNested,
} from 'class-validator';

const storefrontTypes = ['RESTAURANT', 'MARKET'] as const;

class OperatorRegisterBusinessDto {
  @ApiProperty({ example: 'Lezzet Duragi' })
  @IsString()
  @MinLength(3)
  name!: string;

  @ApiProperty({ example: 'Restoran' })
  @IsString()
  @MinLength(2)
  category!: string;

  @ApiPropertyOptional({ example: 'Burger ve pizza gel-al' })
  @IsOptional()
  @IsString()
  subtitle?: string;

  @ApiPropertyOptional({ example: 'https://images.example.com/vendor.jpg' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiProperty({ example: 'Ana teslim noktasi' })
  @IsString()
  @MinLength(3)
  pickupPointLabel!: string;

  @ApiProperty({ example: 'Kadikoy, Istanbul' })
  @IsString()
  @MinLength(5)
  pickupPointAddress!: string;

  @ApiProperty({ example: '09:00-23:00' })
  @IsString()
  @MinLength(3)
  workingHoursLabel!: string;
}

class OperatorRegisterProfileDto {
  @ApiProperty({ example: 'ops@lezzetduragi.app' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'StrongPass123' })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({ example: 'Lezzet Duragi Operasyon' })
  @IsString()
  @MinLength(3)
  displayName!: string;

  @ApiProperty({ example: '+905551112233' })
  @IsString()
  @MinLength(10)
  phone!: string;
}

class OperatorRegisterBankAccountDto {
  @ApiProperty({ example: 'Lezzet Duragi Ltd.' })
  @IsString()
  @MinLength(3)
  holderName!: string;

  @ApiProperty({ example: 'Ziraat Bankasi' })
  @IsString()
  @MinLength(2)
  bankName!: string;

  @ApiProperty({ example: 'TR120006200001000000000001' })
  @IsString()
  @MinLength(10)
  iban!: string;
}

class OperatorRegisterConsentsDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  termsAccepted!: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  privacyAccepted!: boolean;

  @ApiProperty({ example: false })
  @IsBoolean()
  marketingOptIn!: boolean;
}

class OperatorRegisterNotificationsDto {
  @ApiProperty({ example: true })
  @IsBoolean()
  newOrders!: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  cancellations!: boolean;

  @ApiProperty({ example: true })
  @IsBoolean()
  lowStock!: boolean;

  @ApiProperty({ example: false })
  @IsBoolean()
  campaignTips!: boolean;
}

export class OperatorRegisterDto {
  @ApiProperty({ enum: storefrontTypes, example: 'RESTAURANT' })
  @IsIn(storefrontTypes)
  storefrontType!: (typeof storefrontTypes)[number];

  @ApiProperty({ type: OperatorRegisterBusinessDto })
  @ValidateNested()
  @Type(() => OperatorRegisterBusinessDto)
  business!: OperatorRegisterBusinessDto;

  @ApiProperty({ type: OperatorRegisterProfileDto })
  @ValidateNested()
  @Type(() => OperatorRegisterProfileDto)
  operator!: OperatorRegisterProfileDto;

  @ApiProperty({ type: OperatorRegisterBankAccountDto })
  @ValidateNested()
  @Type(() => OperatorRegisterBankAccountDto)
  bankAccount!: OperatorRegisterBankAccountDto;

  @ApiProperty({ type: OperatorRegisterConsentsDto })
  @ValidateNested()
  @Type(() => OperatorRegisterConsentsDto)
  consents!: OperatorRegisterConsentsDto;

  @ApiProperty({ type: OperatorRegisterNotificationsDto })
  @ValidateNested()
  @Type(() => OperatorRegisterNotificationsDto)
  notifications!: OperatorRegisterNotificationsDto;
}
