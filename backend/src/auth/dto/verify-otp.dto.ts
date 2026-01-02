/**
 * Verify OTP DTO
 */
import { IsString, IsNotEmpty, IsOptional, IsEnum, Length } from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class VerifyOtpDto {
  @IsString()
  @IsNotEmpty()
  phone: string;

  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  code: string;

  @IsOptional()
  @IsEnum(UserType)
  userType?: UserType;
}
