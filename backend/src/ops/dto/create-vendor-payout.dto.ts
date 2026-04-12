import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsNumber, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateVendorPayoutDto {
  @ApiProperty({ example: 'vendor-burger-yiyelim' })
  @IsString()
  @MinLength(3)
  vendorId!: string;

  @ApiProperty({ example: 'bank_account_01' })
  @IsString()
  @MinLength(3)
  bankAccountId!: string;

  @ApiProperty({ example: 1850.5 })
  @IsNumber()
  amount!: number;

  @ApiPropertyOptional({ example: 'Haftalik aktarim' })
  @IsOptional()
  @IsString()
  note?: string;
}
