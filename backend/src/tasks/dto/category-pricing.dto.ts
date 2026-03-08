/**
 * Category Pricing DTOs
 * Used for admin CRUD operations on category pricing
 */
import {
  IsInt,
  IsString,
  IsBoolean,
  IsOptional,
  Min,
  IsIn,
  ValidateIf,
} from 'class-validator';
import { Type } from 'class-transformer';

/**
 * DTO for updating category pricing
 */
export class UpdateCategoryPricingDto {
  @Type(() => Number)
  @IsInt()
  @Min(35, { message: 'Minimalna cena musi wynosić co najmniej 35 PLN' })
  minPrice: number;

  @Type(() => Number)
  @IsInt()
  @Min(36, { message: 'Maksymalna cena musi być większa od minimalnej' })
  maxPrice: number;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(35, { message: 'Sugerowana cena musi wynosić co najmniej 35 PLN' })
  suggestedPrice?: number | null;

  @IsString()
  @IsIn(['PLN', 'PLN/h'], {
    message: 'Jednostka ceny musi być "PLN" lub "PLN/h"',
  })
  priceUnit: string;

  @Type(() => Number)
  @IsInt()
  @Min(1, { message: 'Szacowany czas musi wynosić co najmniej 1 minutę' })
  estimatedMinutes: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

/**
 * DTO for category pricing response (public API)
 */
export class CategoryPricingResponseDto {
  category: string;
  minPrice: number;
  maxPrice: number;
  suggestedPrice: number;
  priceUnit: string;
  estimatedMinutes: number;
}

/**
 * DTO for admin category pricing response (includes id, isActive)
 */
export class AdminCategoryPricingResponseDto extends CategoryPricingResponseDto {
  id: string;
  isActive: boolean;
  updatedAt: Date;
}

/**
 * Response wrapper for category pricing list
 */
export class CategoryPricingListResponseDto {
  success: boolean;
  data: CategoryPricingResponseDto[];
  updatedAt: string;
}
