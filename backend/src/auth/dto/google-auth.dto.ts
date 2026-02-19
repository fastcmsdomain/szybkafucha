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
  ValidateIf,
} from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class GoogleAuthDto {
  // New flow: Google ID token from mobile SDK (preferred)
  @ValidateIf((o: GoogleAuthDto) => !o.googleId)
  @IsString()
  @IsNotEmpty()
  idToken?: string;

  // Legacy fallback: kept temporarily for backward compatibility
  @ValidateIf((o: GoogleAuthDto) => !o.idToken)
  @IsString()
  @IsNotEmpty()
  googleId?: string;

  @ValidateIf((o: GoogleAuthDto) => !o.idToken)
  @IsEmail()
  email?: string;

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
