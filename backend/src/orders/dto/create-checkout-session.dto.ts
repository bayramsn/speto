import { ApiProperty } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsArray, IsEnum, IsInt, IsNumber, IsOptional, IsString, Min, MinLength, ValidateNested } from 'class-validator';

import { FulfillmentMode } from '../../common/enums/fulfillment-mode.enum';

class CheckoutLineItemDto {
  @ApiProperty({ example: 'mega-burger-menu' })
  @IsString()
  productId!: string;

  @ApiProperty({ example: 2 })
  @Type(() => Number)
  @IsInt()
  @Min(1)
  quantity!: number;

  @ApiProperty({ example: 'Burger King Kadıköy', required: false })
  @IsOptional()
  @IsString()
  vendor?: string;

  @ApiProperty({ example: 'Mega Burger Menü', required: false })
  @IsOptional()
  @IsString()
  title?: string;

  @ApiProperty({
    example: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd',
    required: false,
  })
  @IsOptional()
  @IsString()
  image?: string;

  @ApiProperty({ example: 185, required: false })
  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(0)
  unitPrice?: number;
}

export class CreateCheckoutSessionDto {
  @ApiProperty({ enum: FulfillmentMode, example: FulfillmentMode.PICKUP })
  @IsEnum(FulfillmentMode)
  fulfillmentMode!: FulfillmentMode;

  @ApiProperty({ example: 'pickup-kadikoy-center' })
  @IsString()
  @MinLength(3)
  pickupPointId!: string;

  @ApiProperty({ example: 'pm_demo_001', required: false })
  @IsOptional()
  @IsString()
  paymentMethodToken?: string;

  @ApiProperty({ example: 'Apple Pay', required: false })
  @IsOptional()
  @IsString()
  paymentMethodLabel?: string;

  @ApiProperty({ type: [CheckoutLineItemDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => CheckoutLineItemDto)
  items!: CheckoutLineItemDto[];

  @ApiProperty({ example: 'KAMPUS25', required: false })
  @IsOptional()
  @IsString()
  promoCode?: string;
}
