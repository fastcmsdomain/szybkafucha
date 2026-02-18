/**
 * Apply Task DTO
 * Data for a contractor applying to a task with a proposed price
 */
import {
  IsNumber,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { Type } from 'class-transformer';

export class ApplyTaskDto {
  @Type(() => Number)
  @IsNumber()
  @Min(35) // Minimum 35 PLN per job flow requirements
  proposedPrice: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}
