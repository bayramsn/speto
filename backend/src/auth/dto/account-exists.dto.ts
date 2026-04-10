import { ApiProperty } from '@nestjs/swagger';
import { IsEmail } from 'class-validator';

export class AccountExistsDto {
  @ApiProperty({ example: 'bayram@example.com' })
  @IsEmail()
  email!: string;
}
