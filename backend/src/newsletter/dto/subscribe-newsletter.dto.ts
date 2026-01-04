/**
 * Subscribe Newsletter DTO
 * Validates incoming newsletter subscription requests
 */
import {
  IsString,
  IsEmail,
  IsNotEmpty,
  IsBoolean,
  IsIn,
  IsOptional,
  MaxLength,
  MinLength,
} from 'class-validator';
import { Transform } from 'class-transformer';

export class SubscribeNewsletterDto {
  @IsString()
  @IsNotEmpty({ message: 'Imię jest wymagane' })
  @MinLength(2, { message: 'Imię musi mieć co najmniej 2 znaki' })
  @MaxLength(255, { message: 'Imię może mieć maksymalnie 255 znaków' })
  @Transform(({ value }) => (typeof value === 'string' ? value.trim() : value))
  name: string;

  @IsEmail({}, { message: 'Proszę podać poprawny adres e-mail' })
  @IsNotEmpty({ message: 'Adres e-mail jest wymagany' })
  @MaxLength(255, { message: 'Email może mieć maksymalnie 255 znaków' })
  @Transform(({ value }) => (typeof value === 'string' ? value.toLowerCase().trim() : value))
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Proszę wybrać typ użytkownika' })
  @IsIn(['client', 'contractor'], { message: 'Typ użytkownika musi być "client" lub "contractor"' })
  userType: 'client' | 'contractor';

  @IsBoolean()
  @IsNotEmpty({ message: 'Zgoda jest wymagana' })
  consent: boolean;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  source?: string;
}
