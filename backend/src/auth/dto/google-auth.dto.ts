/**
 * Google Auth DTO
 */
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEmail,
  IsEnum,
  IsUrl,
} from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class GoogleAuthDto {
  @IsString()
  @IsNotEmpty()
  googleId: string;

  @IsEmail()
  email: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  @IsOptional()
  @IsEnum(UserType)
  userType?: UserType;
}
