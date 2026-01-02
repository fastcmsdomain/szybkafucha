/**
 * Create Task DTO
 * Data for creating a new task
 */
import {
  IsString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsEnum,
  MaxLength,
  MinLength,
  Min,
  IsDateString,
} from 'class-validator';
import { TaskCategory } from '../../contractor/entities/contractor-profile.entity';

export class CreateTaskDto {
  @IsEnum(TaskCategory)
  category: TaskCategory;

  @IsString()
  @IsNotEmpty()
  @MinLength(3)
  @MaxLength(200)
  title: string;

  @IsString()
  @IsOptional()
  @MinLength(10)
  @MaxLength(2000)
  description?: string;

  @IsNumber()
  locationLat: number;

  @IsNumber()
  locationLng: number;

  @IsString()
  @IsNotEmpty()
  address: string;

  @IsNumber()
  @Min(30) // Minimum 30 PLN per PRD
  budgetAmount: number;

  @IsOptional()
  @IsDateString()
  scheduledAt?: string;
}
