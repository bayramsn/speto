import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class RedeemTicketDto {
  @ApiPropertyOptional({ example: 'VIP' })
  @IsOptional()
  @IsString()
  zone?: string;

  @ApiPropertyOptional({ example: 'A12' })
  @IsOptional()
  @IsString()
  seat?: string;

  @ApiPropertyOptional({ example: 'G3' })
  @IsOptional()
  @IsString()
  gate?: string;
}
