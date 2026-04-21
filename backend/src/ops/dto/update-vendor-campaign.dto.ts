import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsIn, IsInt, IsNumber, IsOptional, IsString } from 'class-validator';

const campaignKinds = ['HAPPY_HOUR', 'DISCOUNT', 'CLEARANCE', 'BUNDLE'] as const;
const campaignStatuses = ['DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED'] as const;

export class UpdateVendorCampaignDto {
  @ApiPropertyOptional({ enum: campaignKinds, example: 'DISCOUNT' })
  @IsOptional()
  @IsIn(campaignKinds)
  kind?: (typeof campaignKinds)[number];

  @ApiPropertyOptional({ example: 'Yeni kampanya basligi' })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiPropertyOptional({ example: 'Aciklama' })
  @IsOptional()
  @IsString()
  description?: string;

  @ApiPropertyOptional({ enum: campaignStatuses, example: 'PAUSED' })
  @IsOptional()
  @IsIn(campaignStatuses)
  status?: (typeof campaignStatuses)[number];

  @ApiPropertyOptional({ example: '2026-04-12T15:00:00.000Z' })
  @IsOptional()
  @IsString()
  startsAt?: string;

  @ApiPropertyOptional({ example: '2026-04-12T18:00:00.000Z' })
  @IsOptional()
  @IsString()
  endsAt?: string;

  @ApiPropertyOptional({ example: '18:00 - 20:00' })
  @IsOptional()
  @IsString()
  scheduleLabel?: string;

  @ApiPropertyOptional({ example: '%20' })
  @IsOptional()
  @IsString()
  badgeLabel?: string;

  @ApiPropertyOptional({ example: 20 })
  @IsOptional()
  @IsInt()
  discountPercent?: number;

  @ApiPropertyOptional({ example: 60 })
  @IsOptional()
  @IsNumber()
  discountedPrice?: number;

  @ApiPropertyOptional({ example: 100 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  stockLimit?: number;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/campaigns/fit-menu.jpg' })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ example: 3 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  buyQuantity?: number;

  @ApiPropertyOptional({ example: 2 })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  payQuantity?: number;

  @ApiPropertyOptional({ type: [String], example: ['product-1', 'product-2'] })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  productIds?: string[];
}
