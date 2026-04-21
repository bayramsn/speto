import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean,
  IsArray,
  IsEmail,
  IsIn,
  IsObject,
  IsOptional,
  IsString,
  MinLength,
  ValidateNested,
} from 'class-validator';

const storefrontTypes = ['RESTAURANT', 'MARKET', 'OTHER_BUSINESS'] as const;

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

  @ApiPropertyOptional({ example: 'Istanbul' })
  @IsOptional()
  @IsString()
  city?: string;

  @ApiPropertyOptional({ example: 'Kadikoy' })
  @IsOptional()
  @IsString()
  district?: string;

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

  @ApiPropertyOptional({
    example: [
      {
        label: 'Pazartesi',
        shortLabel: 'Pzt',
        isOpen: true,
        openTime: '09:00',
        closeTime: '22:00',
      },
    ],
  })
  @IsOptional()
  @IsArray()
  @IsObject({ each: true })
  workingDays?: Record<string, unknown>[];

  @ApiPropertyOptional({ example: '1234567890' })
  @IsOptional()
  @IsString()
  taxNumber?: string;

  @ApiPropertyOptional({ example: 'Kadikoy' })
  @IsOptional()
  @IsString()
  taxOffice?: string;
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

  @ApiPropertyOptional({ example: 'Ziraat Bankasi' })
  @IsOptional()
  @IsString()
  @MinLength(2)
  bankName?: string;

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

  @ApiPropertyOptional({ example: false })
  @IsOptional()
  @IsBoolean()
  sms?: boolean;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  push?: boolean;
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
