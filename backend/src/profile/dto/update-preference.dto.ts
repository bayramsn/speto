import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsBoolean, IsString, MinLength } from 'class-validator';

export class UpdatePreferenceDto {
  @ApiProperty({ example: 'MARKET' })
  @IsString()
  @MinLength(3)
  entityType!: string;

  @ApiProperty({ example: 'vendor-migros-jet' })
  @IsString()
  @MinLength(2)
  entityId!: string;

  @ApiProperty({ example: true })
  @Type(() => Boolean)
  @IsBoolean()
  enabled!: boolean;
}
