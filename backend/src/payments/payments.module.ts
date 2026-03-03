/**
 * Payments Module
 * Handles all payment operations: Stripe Connect, credits system
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { PaymentsService } from './payments.service';
import { PaymentsController } from './payments.controller';
import { CreditsService } from './credits.service';
import { CreditsController } from './credits.controller';
import { Payment } from './entities/payment.entity';
import { CreditTransaction } from './entities/credit-transaction.entity';
import { Task } from '../tasks/entities/task.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { User } from '../users/entities/user.entity';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Payment,
      CreditTransaction,
      Task,
      ContractorProfile,
      User,
    ]),
    ConfigModule,
    NotificationsModule,
  ],
  controllers: [PaymentsController, CreditsController],
  providers: [PaymentsService, CreditsService],
  exports: [PaymentsService, CreditsService],
})
export class PaymentsModule {}
