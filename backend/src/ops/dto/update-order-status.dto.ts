import { ApiProperty } from '@nestjs/swagger';
import { IsIn } from 'class-validator';

const orderStatuses = [
  'CREATED',
  'ACCEPTED',
  'PREPARING',
  'READY',
  'COMPLETED',
  'CANCELLED',
] as const;

export class UpdateOrderStatusDto {
  @ApiProperty({ enum: orderStatuses, example: 'READY' })
  @IsIn(orderStatuses)
  status!: (typeof orderStatuses)[number];
}
