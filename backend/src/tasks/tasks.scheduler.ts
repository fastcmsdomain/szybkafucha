/**
 * Tasks Scheduler
 * Cron jobs for automated task lifecycle management
 */
import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThan } from 'typeorm';
import { Task, TaskStatus } from './entities/task.entity';
import { Rating } from './entities/rating.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';

@Injectable()
export class TasksScheduler {
  private readonly logger = new Logger(TasksScheduler.name);

  constructor(
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
  ) {}

  /**
   * Auto-complete tasks in PENDING_COMPLETE after 7 days
   * Creates automatic 5-star ratings for both parties
   * Runs daily at 2:00 AM
   */
  @Cron('0 2 * * *')
  async autoCompleteStaleRatings(): Promise<void> {
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

    const staleTasks = await this.taskRepository.find({
      where: {
        status: TaskStatus.PENDING_COMPLETE,
        completedAt: LessThan(sevenDaysAgo),
      },
    });

    if (staleTasks.length === 0) {
      return;
    }

    this.logger.log(
      `Found ${staleTasks.length} stale PENDING_COMPLETE tasks (>7 days)`,
    );

    for (const task of staleTasks) {
      try {
        await this.autoCompleteTask(task);
      } catch (error) {
        this.logger.error(
          `Failed to auto-complete task ${task.id}: ${error}`,
        );
      }
    }
  }

  private async autoCompleteTask(task: Task): Promise<void> {
    const autoComment = 'Automatyczna ocena po 7 dniach';
    const autoRating = 5;

    // Create auto-ratings for parties that haven't rated yet
    if (!task.clientRated && task.contractorId) {
      const clientRating = this.ratingRepository.create({
        taskId: task.id,
        fromUserId: task.clientId,
        toUserId: task.contractorId,
        rating: autoRating,
        comment: autoComment,
        role: 'contractor',
      });
      await this.ratingRepository.save(clientRating);
      task.clientRated = true;
    }

    if (!task.contractorRated && task.contractorId) {
      const contractorRating = this.ratingRepository.create({
        taskId: task.id,
        fromUserId: task.contractorId,
        toUserId: task.clientId,
        rating: autoRating,
        comment: autoComment,
        role: 'client',
      });
      await this.ratingRepository.save(contractorRating);
      task.contractorRated = true;
    }

    task.status = TaskStatus.COMPLETED;
    await this.taskRepository.save(task);

    // Update contractor profile rating stats
    if (task.contractorId) {
      await this.updateContractorRatingStats(task.contractorId);
    }

    this.logger.log(`Auto-completed task ${task.id} after 7 days`);
  }

  private async updateContractorRatingStats(
    contractorId: string,
  ): Promise<void> {
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'avg')
      .addSelect('COUNT(*)', 'count')
      .where('rating.toUserId = :contractorId', { contractorId })
      .andWhere('rating.role = :role', { role: 'contractor' })
      .getRawOne();

    if (result) {
      await this.contractorProfileRepository.update(contractorId, {
        ratingAvg: parseFloat(result.avg) || 0,
        ratingCount: parseInt(result.count) || 0,
      });
    }
  }
}
