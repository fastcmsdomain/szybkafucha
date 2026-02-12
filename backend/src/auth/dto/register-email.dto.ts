import {
  IsEmail,
  IsString,
  IsOptional,
  IsEnum,
  MinLength,
  Matches,
} from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class RegisterEmailDto {
  @IsEmail({}, { message: 'Podaj prawidłowy adres email' })
  email: string;

  @IsString()
  @MinLength(8, { message: 'Hasło musi mieć minimum 8 znaków' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])/, {
    message:
      'Hasło musi zawierać dużą literę, małą literę, cyfrę i znak specjalny',
  })
  password: string;

  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @IsEnum(UserType)
  userType?: UserType;
}
