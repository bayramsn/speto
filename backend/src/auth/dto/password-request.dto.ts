import { ApiProperty } from '@nestjs/swagger';
import { IsEmail } from 'class-validator';

export class PasswordRequestDto {
  @ApiProperty({ example: 'ayse@example.com' })
  @IsEmail()
  email!: string;
}
