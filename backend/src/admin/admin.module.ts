/**
 * Admin Module
 * Backend API for admin dashboard
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminController } from './admin.controller';
import { AdminService } from './admin.service';
import { User } from '../users/entities/user.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { Task } from '../tasks/entities/task.entity';
import { Rating } from '../tasks/entities/rating.entity';
import { Payment } from '../payments/entities/payment.entity';
import { CategoryPricing } from '../tasks/entities/category-pricing.entity';
import { CategoryPricingService } from '../tasks/category-pricing.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      ContractorProfile,
      Task,
      Rating,
      Payment,
      CategoryPricing,
    ]),
  ],
  controllers: [AdminController],
  providers: [AdminService, CategoryPricingService],
  exports: [AdminService],
})
export class AdminModule {}
