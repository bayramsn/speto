import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, Length, MinLength } from 'class-validator';

export class CreatePaymentMethodDto {
  @ApiPropertyOptional({ example: 'pm_demo_001' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ example: 'VISA' })
  @IsString()
  @MinLength(2)
  brand!: string;

  @ApiProperty({ example: '4242' })
  @IsString()
  @Length(4, 4)
  last4!: string;

  @ApiProperty({ example: '12/27' })
  @IsString()
  @MinLength(4)
  expiry!: string;

  @ApiProperty({ example: 'Bayram Senbay' })
  @IsString()
  @MinLength(3)
  holderName!: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isDefault?: boolean;

  @ApiPropertyOptional({ example: 'pm_demo_001' })
  @IsOptional()
  @IsString()
  token?: string;
}
