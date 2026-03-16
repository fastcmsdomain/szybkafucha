/**
 * Category Pricing Service Unit Tests
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import {
  CategoryPricingService,
  DEFAULT_CATEGORY_PRICING,
} from './category-pricing.service';
import { CategoryPricing } from './entities/category-pricing.entity';
import { UpdateCategoryPricingDto } from './dto/category-pricing.dto';

describe('CategoryPricingService', () => {
  let service: CategoryPricingService;
  let repository: jest.Mocked<Repository<CategoryPricing>>;

  const mockCategoryPricing: CategoryPricing = {
    id: 'pricing-123',
    category: 'hydraulik',
    minPrice: 80,
    maxPrice: 200,
    suggestedPrice: null,
    priceUnit: 'PLN',
    estimatedMinutes: 60,
    isActive: true,
    createdAt: new Date(),
    updatedAt: new Date(),
    getEffectiveSuggestedPrice: function () {
      return (
        this.suggestedPrice ?? Math.round((this.minPrice + this.maxPrice) / 2)
      );
    },
  };

  beforeEach(async () => {
    const mockRepository = {
      find: jest.fn(),
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        CategoryPricingService,
        {
          provide: getRepositoryToken(CategoryPricing),
          useValue: mockRepository,
        },
      ],
    }).compile();

    service = module.get<CategoryPricingService>(CategoryPricingService);
    repository = module.get(getRepositoryToken(CategoryPricing));
  });

  describe('getAllActive', () => {
    it('should return all active category pricing', async () => {
      const mockPricings = [
        { ...mockCategoryPricing, getEffectiveSuggestedPrice: () => 140 },
        {
          ...mockCategoryPricing,
          id: 'pricing-456',
          category: 'sprzatanie',
          minPrice: 100,
          maxPrice: 180,
          getEffectiveSuggestedPrice: () => 140,
        },
      ];

      repository.find.mockResolvedValue(mockPricings);

      const result = await service.getAllActive();

      expect(repository.find).toHaveBeenCalledWith({
        where: { isActive: true },
        order: { category: 'ASC' },
      });
      expect(result).toHaveLength(2);
      expect(result[0].category).toBe('hydraulik');
      expect(result[0].suggestedPrice).toBe(140);
    });

    it('should return empty array when no active pricing', async () => {
      repository.find.mockResolvedValue([]);

      const result = await service.getAllActive();

      expect(result).toEqual([]);
    });
  });

  describe('getAllForAdmin', () => {
    it('should return all pricing including inactive', async () => {
      const mockPricings = [
        { ...mockCategoryPricing, getEffectiveSuggestedPrice: () => 140 },
        {
          ...mockCategoryPricing,
          id: 'pricing-789',
          category: 'inne',
          isActive: false,
          getEffectiveSuggestedPrice: () => 100,
        },
      ];

      repository.find.mockResolvedValue(mockPricings);

      const result = await service.getAllForAdmin();

      expect(repository.find).toHaveBeenCalledWith({
        order: { category: 'ASC' },
      });
      expect(result).toHaveLength(2);
      expect(result[0]).toHaveProperty('id');
      expect(result[0]).toHaveProperty('isActive');
      expect(result[0]).toHaveProperty('updatedAt');
    });
  });

  describe('getByCategory', () => {
    it('should return pricing for existing category', async () => {
      repository.findOne.mockResolvedValue(mockCategoryPricing);

      const result = await service.getByCategory('hydraulik');

      expect(repository.findOne).toHaveBeenCalledWith({
        where: { category: 'hydraulik' },
      });
      expect(result).toEqual(mockCategoryPricing);
    });

    it('should throw NotFoundException for non-existing category', async () => {
      repository.findOne.mockResolvedValue(null);

      await expect(service.getByCategory('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('update', () => {
    const validDto: UpdateCategoryPricingDto = {
      minPrice: 100,
      maxPrice: 250,
      suggestedPrice: 150,
      priceUnit: 'PLN',
      estimatedMinutes: 90,
      isActive: true,
    };

    it('should update pricing successfully', async () => {
      const existingPricing = {
        ...mockCategoryPricing,
        getEffectiveSuggestedPrice: () => 150,
      };
      repository.findOne.mockResolvedValue(existingPricing);
      repository.save.mockResolvedValue({
        ...existingPricing,
        ...validDto,
        getEffectiveSuggestedPrice: () => 150,
      });

      const result = await service.update('hydraulik', validDto);

      expect(result.minPrice).toBe(100);
      expect(result.maxPrice).toBe(250);
      expect(result.suggestedPrice).toBe(150);
    });

    it('should throw BadRequestException when maxPrice <= minPrice', async () => {
      repository.findOne.mockResolvedValue(mockCategoryPricing);

      const invalidDto: UpdateCategoryPricingDto = {
        ...validDto,
        minPrice: 200,
        maxPrice: 100,
      };

      await expect(service.update('hydraulik', invalidDto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw BadRequestException when suggestedPrice out of range', async () => {
      repository.findOne.mockResolvedValue(mockCategoryPricing);

      const invalidDto: UpdateCategoryPricingDto = {
        ...validDto,
        minPrice: 100,
        maxPrice: 200,
        suggestedPrice: 300, // Out of range
      };

      await expect(service.update('hydraulik', invalidDto)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should allow null suggestedPrice (auto-calculate)', async () => {
      const existingPricing = {
        ...mockCategoryPricing,
        getEffectiveSuggestedPrice: () => 175,
      };
      repository.findOne.mockResolvedValue(existingPricing);
      repository.save.mockResolvedValue({
        ...existingPricing,
        minPrice: 100,
        maxPrice: 250,
        suggestedPrice: null,
        getEffectiveSuggestedPrice: () => 175,
      });

      const dtoWithNullSuggested: UpdateCategoryPricingDto = {
        ...validDto,
        suggestedPrice: undefined,
      };

      const result = await service.update('hydraulik', dtoWithNullSuggested);

      expect(result.suggestedPrice).toBe(175); // Auto-calculated
    });
  });

  describe('seedDefaults', () => {
    it('should seed missing categories', async () => {
      repository.findOne.mockResolvedValue(null); // No existing categories
      repository.create.mockImplementation((data) => data as CategoryPricing);
      repository.save.mockResolvedValue({} as CategoryPricing);

      const result = await service.seedDefaults();

      expect(result.created).toBe(DEFAULT_CATEGORY_PRICING.length);
      expect(result.skipped).toBe(0);
      expect(repository.create).toHaveBeenCalledTimes(
        DEFAULT_CATEGORY_PRICING.length,
      );
    });

    it('should skip existing categories', async () => {
      // First category exists, rest don't
      repository.findOne
        .mockResolvedValueOnce(mockCategoryPricing)
        .mockResolvedValue(null);
      repository.create.mockImplementation((data) => data as CategoryPricing);
      repository.save.mockResolvedValue({} as CategoryPricing);

      const result = await service.seedDefaults();

      expect(result.skipped).toBe(1);
      expect(result.created).toBe(DEFAULT_CATEGORY_PRICING.length - 1);
    });
  });

  describe('resetToDefaults', () => {
    it('should update existing and create missing', async () => {
      // First category exists
      repository.findOne
        .mockResolvedValueOnce(mockCategoryPricing)
        .mockResolvedValue(null);
      repository.create.mockImplementation((data) => data as CategoryPricing);
      repository.save.mockResolvedValue({} as CategoryPricing);

      const result = await service.resetToDefaults();

      expect(result.updated).toBe(1);
      expect(result.created).toBe(DEFAULT_CATEGORY_PRICING.length - 1);
    });
  });

  describe('getLatestUpdateTimestamp', () => {
    it('should return latest update timestamp', async () => {
      const mockDate = new Date('2026-03-08T12:00:00Z');
      const mockQueryBuilder = {
        select: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ maxUpdatedAt: mockDate }),
      };
      repository.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

      const result = await service.getLatestUpdateTimestamp();

      expect(result).toEqual(mockDate);
    });

    it('should return current date when no data', async () => {
      const mockQueryBuilder = {
        select: jest.fn().mockReturnThis(),
        getRawOne: jest.fn().mockResolvedValue({ maxUpdatedAt: null }),
      };
      repository.createQueryBuilder.mockReturnValue(mockQueryBuilder as any);

      const result = await service.getLatestUpdateTimestamp();

      expect(result).toBeInstanceOf(Date);
    });
  });

  describe('DEFAULT_CATEGORY_PRICING', () => {
    it('should have all 17 categories', () => {
      expect(DEFAULT_CATEGORY_PRICING).toHaveLength(17);
    });

    it('should have valid pricing for each category', () => {
      for (const pricing of DEFAULT_CATEGORY_PRICING) {
        expect(pricing.category).toBeDefined();
        expect(pricing.minPrice).toBeGreaterThanOrEqual(35);
        expect(pricing.maxPrice).toBeGreaterThan(pricing.minPrice!);
        expect(['PLN', 'PLN/h']).toContain(pricing.priceUnit);
        expect(pricing.estimatedMinutes).toBeGreaterThan(0);
      }
    });
  });
});
