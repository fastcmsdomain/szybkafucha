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
import { SeedService } from './seed.service';

@Module({
  imports: [TypeOrmModule.forFeature([User, ContractorProfile, Task, Rating])],
  providers: [SeedService],
  exports: [SeedService],
})
export class SeedModule {}
