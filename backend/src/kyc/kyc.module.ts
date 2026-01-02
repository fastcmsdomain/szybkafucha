/**
 * KYC Module
 * Handles contractor identity verification via Onfido
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ConfigModule } from '@nestjs/config';
import { KycController, KycWebhookController } from './kyc.controller';
import { KycService } from './kyc.service';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { User } from '../users/entities/user.entity';
import { KycCheck } from './entities/kyc-check.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([ContractorProfile, User, KycCheck]),
    ConfigModule,
  ],
  controllers: [KycController, KycWebhookController],
  providers: [KycService],
  exports: [KycService],
})
export class KycModule {}
