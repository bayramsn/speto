import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({ example: 'ayse@example.com' })
  @IsEmail()
  email!: string;

  @ApiProperty({ example: 'Ayse Yilmaz' })
  @IsString()
  @MinLength(3)
  displayName!: string;

  @ApiProperty({ example: '+905551112233' })
  @IsString()
  @MinLength(10)
  phone!: string;

  @ApiProperty({ example: 'StrongPass123' })
  @IsString()
  @MinLength(8)
  password!: string;

  @ApiProperty({
    example: 'ayse@universite.edu.tr',
    required: false,
    description: 'Optional student verification email',
  })
  @IsOptional()
  @IsEmail()
  studentEmail?: string;
}
