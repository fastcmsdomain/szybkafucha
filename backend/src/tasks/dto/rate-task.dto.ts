/**
 * Rate Task DTO
 * Data for rating a completed task
 */
import {
  IsInt,
  IsString,
  IsOptional,
  Min,
  Max,
  MaxLength,
} from 'class-validator';

export class RateTaskDto {
  @IsInt()
  @Min(1)
  @Max(5)
  rating: number;

  @IsString()
  @IsOptional()
  @MaxLength(500)
  comment?: string;
}
