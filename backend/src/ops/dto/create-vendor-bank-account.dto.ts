import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateVendorBankAccountDto {
  @ApiProperty({ example: 'vendor-burger-yiyelim' })
  @IsString()
  @MinLength(3)
  vendorId!: string;

  @ApiProperty({ example: 'Burger Yiyelim Ltd.' })
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

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;
}
