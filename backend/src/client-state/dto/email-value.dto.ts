import { ApiProperty } from '@nestjs/swagger';
import { IsEmail } from 'class-validator';

export class EmailValueDto {
  @ApiProperty({ example: 'bayram@example.com' })
  @IsEmail()
  email!: string;
}
