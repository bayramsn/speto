import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, Length } from 'class-validator';

export class PasswordVerifyOtpDto {
  @ApiProperty({ example: 'user@speto.app' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: '12345' })
  @IsString()
  @Length(5, 5)
  code!: string;
}
