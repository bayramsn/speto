import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, MinLength } from 'class-validator';

export class CreateAddressDto {
  @ApiPropertyOptional({ example: 'address-home' })
  @IsOptional()
  @IsString()
  id?: string;

  @ApiProperty({ example: 'Ev' })
  @IsString()
  @MinLength(2)
  label!: string;

  @ApiProperty({ example: 'Kadıköy / İstanbul' })
  @IsString()
  @MinLength(5)
  address!: string;

  @ApiPropertyOptional({ example: 'home' })
  @IsOptional()
  @IsString()
  iconKey?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  isPrimary?: boolean;
}
