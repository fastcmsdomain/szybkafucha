/**
 * Tasks Module
 * Handles task creation, management, and lifecycle
 */
import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Task } from './entities/task.entity';
import { TaskApplication } from './entities/task-application.entity';
import { Rating } from './entities/rating.entity';
import { CategoryPricing } from './entities/category-pricing.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { TasksService } from './tasks.service';
import { TasksScheduler } from './tasks.scheduler';
import { CategoryPricingService } from './category-pricing.service';
import { TasksController } from './tasks.controller';
import { PublicTasksController } from './public-tasks.controller';
import { CategoryPricingController } from './category-pricing.controller';
import { UsersModule } from '../users/users.module';
import { ContractorModule } from '../contractor/contractor.module';
import { RealtimeModule } from '../realtime/realtime.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { PaymentsModule } from '../payments/payments.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Task,
      TaskApplication,
      Rating,
      ContractorProfile,
      CategoryPricing,
    ]),
    UsersModule,
    ContractorModule,
    forwardRef(() => RealtimeModule),
    NotificationsModule,
    PaymentsModule,
  ],
  controllers: [
    TasksController,
    PublicTasksController,
    CategoryPricingController,
  ],
  providers: [TasksService, TasksScheduler, CategoryPricingService],
  exports: [TasksService, CategoryPricingService],
})
export class TasksModule {}
