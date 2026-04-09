import { ApiProperty } from '@nestjs/swagger';
import { IsIn, IsObject, IsString } from 'class-validator';

const integrationTypes = ['POS', 'ERP'] as const;

export class CreateIntegrationDto {
  @ApiProperty({ example: 'vendor-happy-hour-market' })
  @IsString()
  vendorId!: string;

  @ApiProperty({ example: 'Market ERP Feed' })
  @IsString()
  name!: string;

  @ApiProperty({ example: 'Logo ERP' })
  @IsString()
  provider!: string;

  @ApiProperty({ enum: integrationTypes, example: 'ERP' })
  @IsIn(integrationTypes)
  type!: (typeof integrationTypes)[number];

  @ApiProperty({ example: 'https://erp.vendor.local' })
  @IsString()
  baseUrl!: string;

  @ApiProperty({ example: 'loc-market-cold' })
  @IsString()
  locationId!: string;

  @ApiProperty({
    example: { 'EXT-MR-021': 'MR-BND-021' },
    description: 'External system product code -> Speto SKU mapping',
  })
  @IsObject()
  skuMappings!: Record<string, string>;
}
