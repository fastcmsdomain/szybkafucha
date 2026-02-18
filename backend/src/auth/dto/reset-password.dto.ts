import { IsEmail, IsString, Length, MinLength, Matches } from 'class-validator';

export class ResetPasswordDto {
  @IsEmail({}, { message: 'Podaj prawidłowy adres email' })
  email: string;

  @IsString()
  @Length(6, 6, { message: 'Kod weryfikacyjny musi mieć 6 znaków' })
  code: string;

  @IsString()
  @MinLength(8, { message: 'Hasło musi mieć minimum 8 znaków' })
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])/, {
    message:
      'Hasło musi zawierać dużą literę, małą literę, cyfrę i znak specjalny',
  })
  newPassword: string;
}
