import { IsNotEmpty, IsString, Length } from 'class-validator';

export class VerifyLinkedPhoneDto {
  @IsString()
  @IsNotEmpty()
  phone: string;

  @IsString()
  @IsNotEmpty()
  @Length(6, 6)
  code: string;
}
