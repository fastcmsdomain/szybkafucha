/**
 * Update User DTO
 * Data transfer object for updating user profile
 */
import {
  IsString,
  IsOptional,
  MaxLength,
  IsUrl,
  IsEmail,
} from 'class-validator';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(100)
  name?: string;

  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  @IsOptional()
  @IsString()
  fcmToken?: string;

   @IsOptional()
   @IsString()
   @MaxLength(20)
   phone?: string;

   @IsOptional()
   @IsEmail()
   email?: string;

   @IsOptional()
   @IsString()
   @MaxLength(255)
   address?: string;
}
