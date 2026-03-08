/**
 * Category Pricing Service
 * Business logic for managing category pricing
 */
import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { CategoryPricing } from './entities/category-pricing.entity';
import {
  UpdateCategoryPricingDto,
  CategoryPricingResponseDto,
  AdminCategoryPricingResponseDto,
} from './dto/category-pricing.dto';

/**
 * Default pricing data for all categories
 * Used for initial seeding and fallback
 */
export const DEFAULT_CATEGORY_PRICING: Partial<CategoryPricing>[] = [
  {
    category: 'paczki',
    minPrice: 30,
    maxPrice: 60,
    priceUnit: 'PLN',
    estimatedMinutes: 30,
  },
  {
    category: 'zakupy',
    minPrice: 40,
    maxPrice: 80,
    priceUnit: 'PLN',
    estimatedMinutes: 45,
  },
  {
    category: 'kolejki',
    minPrice: 50,
    maxPrice: 100,
    priceUnit: 'PLN/h',
    estimatedMinutes: 60,
  },
  {
    category: 'montaz',
    minPrice: 60,
    maxPrice: 120,
    priceUnit: 'PLN',
    estimatedMinutes: 90,
  },
  {
    category: 'przeprowadzki',
    minPrice: 80,
    maxPrice: 150,
    priceUnit: 'PLN/h',
    estimatedMinutes: 120,
  },
  {
    category: 'sprzatanie',
    minPrice: 100,
    maxPrice: 180,
    priceUnit: 'PLN',
    estimatedMinutes: 120,
  },
  {
    category: 'naprawy',
    minPrice: 60,
    maxPrice: 150,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
  {
    category: 'ogrod',
    minPrice: 80,
    maxPrice: 200,
    priceUnit: 'PLN/h',
    estimatedMinutes: 120,
  },
  {
    category: 'transport',
    minPrice: 50,
    maxPrice: 120,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
  {
    category: 'zwierzeta',
    minPrice: 40,
    maxPrice: 80,
    priceUnit: 'PLN/h',
    estimatedMinutes: 60,
  },
  {
    category: 'elektryk',
    minPrice: 80,
    maxPrice: 200,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
  {
    category: 'hydraulik',
    minPrice: 80,
    maxPrice: 200,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
  {
    category: 'malowanie',
    minPrice: 100,
    maxPrice: 250,
    priceUnit: 'PLN',
    estimatedMinutes: 180,
  },
  {
    category: 'zlota_raczka',
    minPrice: 50,
    maxPrice: 150,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
  {
    category: 'komputery',
    minPrice: 60,
    maxPrice: 150,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
  {
    category: 'sport',
    minPrice: 60,
    maxPrice: 120,
    priceUnit: 'PLN/h',
    estimatedMinutes: 60,
  },
  {
    category: 'inne',
    minPrice: 35,
    maxPrice: 200,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
  },
];

@Injectable()
export class CategoryPricingService {
  private readonly logger = new Logger(CategoryPricingService.name);

  constructor(
    @InjectRepository(CategoryPricing)
    private readonly categoryPricingRepository: Repository<CategoryPricing>,
  ) {}

  /**
   * Get all active category pricing (public API)
   * Returns calculated suggestedPrice if not set
   */
  async getAllActive(): Promise<CategoryPricingResponseDto[]> {
    const pricings = await this.categoryPricingRepository.find({
      where: { isActive: true },
      order: { category: 'ASC' },
    });

    return pricings.map((p) => ({
      category: p.category,
      minPrice: p.minPrice,
      maxPrice: p.maxPrice,
      suggestedPrice: p.getEffectiveSuggestedPrice(),
      priceUnit: p.priceUnit,
      estimatedMinutes: p.estimatedMinutes,
    }));
  }

  /**
   * Get all category pricing for admin (includes inactive)
   */
  async getAllForAdmin(): Promise<AdminCategoryPricingResponseDto[]> {
    const pricings = await this.categoryPricingRepository.find({
      order: { category: 'ASC' },
    });

    return pricings.map((p) => ({
      id: p.id,
      category: p.category,
      minPrice: p.minPrice,
      maxPrice: p.maxPrice,
      suggestedPrice: p.getEffectiveSuggestedPrice(),
      priceUnit: p.priceUnit,
      estimatedMinutes: p.estimatedMinutes,
      isActive: p.isActive,
      updatedAt: p.updatedAt,
    }));
  }

  /**
   * Get pricing for a specific category
   */
  async getByCategory(category: string): Promise<CategoryPricing> {
    const pricing = await this.categoryPricingRepository.findOne({
      where: { category },
    });

    if (!pricing) {
      throw new NotFoundException(
        `Pricing for category '${category}' not found`,
      );
    }

    return pricing;
  }

  /**
   * Update pricing for a category
   */
  async update(
    category: string,
    dto: UpdateCategoryPricingDto,
  ): Promise<AdminCategoryPricingResponseDto> {
    const pricing = await this.getByCategory(category);

    // Validate minPrice < maxPrice
    if (dto.maxPrice <= dto.minPrice) {
      throw new BadRequestException(
        'Maksymalna cena musi być większa od minimalnej',
      );
    }

    // Validate suggestedPrice within range (if provided)
    if (
      dto.suggestedPrice !== undefined &&
      dto.suggestedPrice !== null &&
      (dto.suggestedPrice < dto.minPrice || dto.suggestedPrice > dto.maxPrice)
    ) {
      throw new BadRequestException(
        'Sugerowana cena musi być w zakresie [min, max]',
      );
    }

    // Update fields
    pricing.minPrice = dto.minPrice;
    pricing.maxPrice = dto.maxPrice;
    pricing.suggestedPrice =
      dto.suggestedPrice !== undefined ? dto.suggestedPrice : null;
    pricing.priceUnit = dto.priceUnit;
    pricing.estimatedMinutes = dto.estimatedMinutes;

    if (dto.isActive !== undefined) {
      pricing.isActive = dto.isActive;
    }

    const saved = await this.categoryPricingRepository.save(pricing);

    this.logger.log(`Updated pricing for category: ${category}`);

    return {
      id: saved.id,
      category: saved.category,
      minPrice: saved.minPrice,
      maxPrice: saved.maxPrice,
      suggestedPrice: saved.getEffectiveSuggestedPrice(),
      priceUnit: saved.priceUnit,
      estimatedMinutes: saved.estimatedMinutes,
      isActive: saved.isActive,
      updatedAt: saved.updatedAt,
    };
  }

  /**
   * Seed database with default pricing
   * Creates missing categories, does not overwrite existing
   */
  async seedDefaults(): Promise<{ created: number; skipped: number }> {
    let created = 0;
    let skipped = 0;

    for (const defaultPricing of DEFAULT_CATEGORY_PRICING) {
      const existing = await this.categoryPricingRepository.findOne({
        where: { category: defaultPricing.category },
      });

      if (existing) {
        skipped++;
        continue;
      }

      const pricing = this.categoryPricingRepository.create({
        ...defaultPricing,
        isActive: true,
      });

      await this.categoryPricingRepository.save(pricing);
      created++;
    }

    this.logger.log(
      `Seeded category pricing: ${created} created, ${skipped} skipped`,
    );

    return { created, skipped };
  }

  /**
   * Reset all pricing to defaults
   * Updates existing categories to default values
   */
  async resetToDefaults(): Promise<{ updated: number; created: number }> {
    let updated = 0;
    let created = 0;

    for (const defaultPricing of DEFAULT_CATEGORY_PRICING) {
      const existing = await this.categoryPricingRepository.findOne({
        where: { category: defaultPricing.category },
      });

      if (existing) {
        existing.minPrice = defaultPricing.minPrice!;
        existing.maxPrice = defaultPricing.maxPrice!;
        existing.suggestedPrice = null;
        existing.priceUnit = defaultPricing.priceUnit!;
        existing.estimatedMinutes = defaultPricing.estimatedMinutes!;
        existing.isActive = true;
        await this.categoryPricingRepository.save(existing);
        updated++;
      } else {
        const pricing = this.categoryPricingRepository.create({
          ...defaultPricing,
          isActive: true,
        });
        await this.categoryPricingRepository.save(pricing);
        created++;
      }
    }

    this.logger.log(
      `Reset category pricing: ${updated} updated, ${created} created`,
    );

    return { updated, created };
  }

  /**
   * Get the latest update timestamp
   * Used for cache invalidation in mobile app
   */
  async getLatestUpdateTimestamp(): Promise<Date> {
    const result = await this.categoryPricingRepository
      .createQueryBuilder('pricing')
      .select('MAX(pricing.updatedAt)', 'maxUpdatedAt')
      .getRawOne<{ maxUpdatedAt: Date | null }>();

    return result?.maxUpdatedAt || new Date();
  }
}
