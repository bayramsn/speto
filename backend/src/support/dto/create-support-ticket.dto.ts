import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CreateSupportTicketDto {
  @ApiProperty({ example: 'Gel-al hazırlık süresi hakkında bilgi' })
  @IsString()
  @MinLength(3)
  subject!: string;

  @ApiProperty({ example: 'Siparişim için güncel hazırlık durumunu görmek istiyorum.' })
  @IsString()
  @MinLength(10)
  message!: string;

  @ApiProperty({ example: 'Canlı Destek' })
  @IsString()
  @MinLength(3)
  channel!: string;
}
