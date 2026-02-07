/**
 * Purge Module
 * Module for purging tasks and ratings from the database
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Task } from '../../tasks/entities/task.entity';
import { Rating } from '../../tasks/entities/rating.entity';
import { PurgeService } from './purge.service';

@Module({
  imports: [TypeOrmModule.forFeature([Task, Rating])],
  providers: [PurgeService],
  exports: [PurgeService],
})
export class PurgeModule {}
