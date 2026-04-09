import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsString } from 'class-validator';

export class AdjustInventoryDto {
  @ApiProperty({ example: -2 })
  @Type(() => Number)
  @IsInt()
  quantityDelta!: number;

  @ApiProperty({ example: 'Broken package count corrected after cycle count' })
  @IsString()
  reason!: string;
}
