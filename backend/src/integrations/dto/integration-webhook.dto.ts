import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsArray,
  IsInt,
  IsString,
  Min,
  ValidateNested,
} from 'class-validator';

class IntegrationWebhookRecordDto {
  @ApiProperty({ example: 'EXT-MR-021' })
  @IsString()
  sku!: string;

  @ApiProperty({ example: 18 })
  @Type(() => Number)
  @IsInt()
  @Min(0)
  quantity!: number;
}

export class IntegrationWebhookDto {
  @ApiProperty({ type: [IntegrationWebhookRecordDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => IntegrationWebhookRecordDto)
  records!: IntegrationWebhookRecordDto[];
}
