/**
 * DTO for updating client profile
 */
import { IsOptional, IsString, MaxLength } from 'class-validator';

export class UpdateClientProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;
}
