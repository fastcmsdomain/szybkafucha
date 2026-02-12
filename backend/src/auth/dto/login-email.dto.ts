import { IsEmail, IsString, IsNotEmpty } from 'class-validator';

export class LoginEmailDto {
  @IsEmail({}, { message: 'Podaj prawidłowy adres email' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Hasło jest wymagane' })
  password: string;
}
