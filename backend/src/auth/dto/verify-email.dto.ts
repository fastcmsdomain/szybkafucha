import { IsEmail, IsString, Length } from 'class-validator';

export class VerifyEmailDto {
  @IsEmail({}, { message: 'Podaj prawidłowy adres email' })
  email: string;

  @IsString()
  @Length(6, 6, { message: 'Kod weryfikacyjny musi mieć 6 znaków' })
  code: string;
}
