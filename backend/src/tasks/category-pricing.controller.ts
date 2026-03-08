/**
 * Category Pricing Controller
 * Public endpoint for mobile app to fetch category pricing
 */
import { Controller, Get } from '@nestjs/common';
import { CategoryPricingService } from './category-pricing.service';
import { CategoryPricingListResponseDto } from './dto/category-pricing.dto';

@Controller('categories')
export class CategoryPricingController {
  constructor(
    private readonly categoryPricingService: CategoryPricingService,
  ) {}

  /**
   * GET /categories/pricing
   * Public endpoint - no authentication required
   * Returns all active category pricing for mobile app
   */
  @Get('pricing')
  async getAllPricing(): Promise<CategoryPricingListResponseDto> {
    const data = await this.categoryPricingService.getAllActive();
    const updatedAt = await this.categoryPricingService.getLatestUpdateTimestamp();

    return {
      success: true,
      data,
      updatedAt: updatedAt.toISOString(),
    };
  }
}
