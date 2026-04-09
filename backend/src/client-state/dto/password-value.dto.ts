import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class PasswordValueDto {
  @ApiProperty({ example: 'StrongPass123' })
  @IsString()
  @MinLength(1)
  password!: string;
}
