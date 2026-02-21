import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class ContactSupportDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(2)
  @MaxLength(120)
  name: string;

  @IsString()
  @IsNotEmpty()
  @MinLength(10)
  @MaxLength(5000)
  message: string;
}
