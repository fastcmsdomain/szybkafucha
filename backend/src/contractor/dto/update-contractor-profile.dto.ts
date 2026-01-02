/**
 * Update Contractor Profile DTO
 */
import {
  IsString,
  IsOptional,
  IsArray,
  IsEnum,
  IsInt,
  Min,
  Max,
  MaxLength,
} from 'class-validator';
import { TaskCategory } from '../entities/contractor-profile.entity';

export class UpdateContractorProfileDto {
  @IsOptional()
  @IsString()
  @MaxLength(500)
  bio?: string;

  @IsOptional()
  @IsArray()
  @IsEnum(TaskCategory, { each: true })
  categories?: TaskCategory[];

  @IsOptional()
  @IsInt()
  @Min(1)
  @Max(50)
  serviceRadiusKm?: number;
}
