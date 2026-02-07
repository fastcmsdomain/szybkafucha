/**
 * Purge Service
 * Deletes all tasks and ratings from the database
 */
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task } from '../../tasks/entities/task.entity';
import { Rating } from '../../tasks/entities/rating.entity';

@Injectable()
export class PurgeService {
  private readonly logger = new Logger(PurgeService.name);

  constructor(
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
  ) {}

  /**
   * Purge all tasks and ratings from the database
   * Ratings are deleted first due to foreign key constraints
   */
  async purge(): Promise<void> {
    this.logger.log('🗑️ Starting purge of tasks and ratings...');

    try {
      // Get counts before deletion
      const taskCount = await this.taskRepository.count();
      const ratingCount = await this.ratingRepository.count();

      this.logger.log(`📊 Found ${taskCount} tasks and ${ratingCount} ratings`);

      if (taskCount === 0 && ratingCount === 0) {
        this.logger.warn('⚠️ No tasks or ratings to purge.');
        return;
      }

      // Delete ratings first (due to foreign key constraints)
      if (ratingCount > 0) {
        this.logger.log('🗑️ Deleting ratings...');
        const deleteRatingsResult = await this.ratingRepository
          .createQueryBuilder()
          .delete()
          .execute();
        this.logger.log(
          `   ✅ Deleted ${deleteRatingsResult.affected || 0} ratings`,
        );
      }

      // Delete tasks
      if (taskCount > 0) {
        this.logger.log('🗑️ Deleting tasks...');
        const deleteTasksResult = await this.taskRepository
          .createQueryBuilder()
          .delete()
          .execute();
        this.logger.log(
          `   ✅ Deleted ${deleteTasksResult.affected || 0} tasks`,
        );
      }

      this.logger.log('✅ Purge completed successfully!');
      this.logger.log('');
      this.logger.log('📊 Purge Summary:');
      this.logger.log('================');
      this.logger.log(`🗑️ Tasks deleted: ${taskCount}`);
      this.logger.log(`🗑️ Ratings deleted: ${ratingCount}`);
      this.logger.log('');
    } catch (error) {
      this.logger.error('❌ Purge failed:', error);
      throw error;
    }
  }
}
