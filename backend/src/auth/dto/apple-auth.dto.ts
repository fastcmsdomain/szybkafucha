/**
 * Apple Auth DTO
 */
import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEmail,
  IsEnum,
} from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class AppleAuthDto {
  @IsString()
  @IsNotEmpty()
  appleId: string;

  @IsOptional()
  @IsEmail()
  email?: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(UserType)
  userType?: UserType;
}
