/**
 * Public Tasks Controller
 * Provides public access to task listings without authentication
 * Used for showcasing platform value to unauthenticated users
 */
import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { ThrottlerGuard } from '@nestjs/throttler';
import { TasksService } from './tasks.service';

@Controller('public/tasks')
export class PublicTasksController {
  constructor(private readonly tasksService: TasksService) {}

  /**
   * Browse available tasks publicly (no authentication required)
   *
   * Security measures:
   * - Rate limited to 100 requests per 15 minutes
   * - Returns sanitized data (no sensitive client information)
   * - Addresses generalized to city/district level
   * - Coordinates rounded for privacy
   * - Limited to 100 tasks per request
   *
   * @param categories - Comma-separated list of task categories to filter
   * @param limit - Maximum number of tasks to return (capped at 100)
   * @returns Array of sanitized public task objects
   */
  @Get()
  @UseGuards(ThrottlerGuard)
  async browsePublic(
    @Query('categories') categories?: string,
    @Query('limit') limit: number = 50,
  ) {
    const categoryList = categories ? categories.split(',') : [];
    const maxLimit = Math.min(limit, 100); // Cap at 100 tasks

    return this.tasksService.findAllAvailablePublic({
      categories: categoryList,
      limit: maxLimit,
    });
  }
}
