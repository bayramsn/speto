import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsEmail, IsOptional, IsString, MinLength } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({ example: 'Bayram Senbay' })
  @IsOptional()
  @IsString()
  @MinLength(3)
  displayName?: string;

  @ApiPropertyOptional({ example: '+90 555 123 45 67' })
  @IsOptional()
  @IsString()
  @MinLength(10)
  phone?: string;

  @ApiPropertyOptional({ example: 'bayram@example.com' })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: 'https://i.pravatar.cc/150?img=1' })
  @IsOptional()
  @IsString()
  avatarUrl?: string;

  @ApiPropertyOptional({ example: true })
  @IsOptional()
  @IsBoolean()
  notificationsEnabled?: boolean;
}
