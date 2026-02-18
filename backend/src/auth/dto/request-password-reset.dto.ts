import { IsEmail } from 'class-validator';

export class RequestPasswordResetDto {
  @IsEmail({}, { message: 'Podaj prawidłowy adres email' })
  email: string;
}
