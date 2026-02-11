/**
 * Contractor Module
 * Handles contractor-specific operations: profile, availability, location, earnings
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ContractorProfile } from './entities/contractor-profile.entity';
import { ContractorService } from './contractor.service';
import { ContractorController } from './contractor.controller';
import { UsersModule } from '../users/users.module';
import { Rating } from '../tasks/entities/rating.entity';

@Module({
  imports: [TypeOrmModule.forFeature([ContractorProfile, Rating]), UsersModule],
  controllers: [ContractorController],
  providers: [ContractorService],
  exports: [ContractorService],
})
export class ContractorModule {}
