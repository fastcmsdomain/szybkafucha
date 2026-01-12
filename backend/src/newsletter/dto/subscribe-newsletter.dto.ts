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
  IsArray,
} from 'class-validator';
import { Transform } from 'class-transformer';

export class SubscribeNewsletterDto {
  @IsString()
  @IsNotEmpty({ message: 'Imię jest wymagane' })
  @MinLength(2, { message: 'Imię musi mieć co najmniej 2 znaki' })
  @MaxLength(255, { message: 'Imię może mieć maksymalnie 255 znaków' })
  @Transform(({ value }) =>
    typeof value === 'string' ? value.trim() : undefined,
  )
  name: string;

  @IsEmail({}, { message: 'Proszę podać poprawny adres e-mail' })
  @IsNotEmpty({ message: 'Adres e-mail jest wymagany' })
  @MaxLength(255, { message: 'Email może mieć maksymalnie 255 znaków' })
  @Transform(({ value }) =>
    typeof value === 'string' ? value.toLowerCase().trim() : undefined,
  )
  email: string;

  @IsOptional()
  @IsString()
  @MaxLength(100, { message: 'Miasto może mieć maksymalnie 100 znaków' })
  city?: string;

  @IsString()
  @IsNotEmpty({ message: 'Proszę wybrać typ użytkownika' })
  @IsIn(['client', 'contractor'], {
    message: 'Typ użytkownika musi być "client" lub "contractor"',
  })
  userType: 'client' | 'contractor';

  @IsBoolean()
  @IsNotEmpty({ message: 'Zgoda jest wymagana' })
  consent: boolean;

  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  services?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(500, { message: 'Komentarz może mieć maksymalnie 500 znaków' })
  comments?: string;

  @IsOptional()
  @IsString()
  @MaxLength(50)
  source?: string;
}
