/**
 * Seed Module
 * Module for database seeding operations
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../../users/entities/user.entity';
import { ContractorProfile } from '../../contractor/entities/contractor-profile.entity';
import { Task } from '../../tasks/entities/task.entity';
import { Rating } from '../../tasks/entities/rating.entity';
import { CategoryPricing } from '../../tasks/entities/category-pricing.entity';
import { SeedService } from './seed.service';
import { CategoryPricingService } from '../../tasks/category-pricing.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      ContractorProfile,
      Task,
      Rating,
      CategoryPricing,
    ]),
  ],
  providers: [SeedService, CategoryPricingService],
  exports: [SeedService],
})
export class SeedModule {}
