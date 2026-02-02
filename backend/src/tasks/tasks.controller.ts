/**
 * Tasks Controller
 * REST endpoints for task management
 */
import {
  Controller,
  Get,
  Post,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
} from '@nestjs/common';
import { TasksService } from './tasks.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateTaskDto } from './dto/create-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
import { UserType } from '../users/entities/user.entity';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(private readonly tasksService: TasksService) {}

  /**
   * POST /tasks
   * Create a new task (client only)
   */
  @Post()
  async create(
    @Request() req: AuthenticatedRequest,
    @Body() createTaskDto: CreateTaskDto,
  ) {
    return this.tasksService.create(req.user.id, createTaskDto);
  }

  /**
   * GET /tasks
   * List tasks filtered by user role
   * - Clients see their own tasks
   * - Contractors see available nearby tasks
   */
  @Get()
  async findAll(
    @Request() req: AuthenticatedRequest,
    @Query('lat') lat?: number,
    @Query('lng') lng?: number,
    @Query('categories') categories?: string,
    @Query('radiusKm') radiusKm?: number,
  ) {
    if (req.user.type === UserType.CLIENT) {
      return this.tasksService.findByClient(req.user.id);
    }

    // For MVP: If no location provided, return all available tasks (no geo filter)
    // In production: require location for contractors
    if (!lat || !lng) {
      return this.tasksService.findAllAvailable();
    }

    const categoryList = categories ? categories.split(',') : [];
    return this.tasksService.findAvailableForContractor(
      req.user.id,
      categoryList,
      lat,
      lng,
      radiusKm || 10,
    );
  }

  /**
   * GET /tasks/:id
   * Get task details
   */
  @Get(':id')
  async findOne(@Param('id', ParseUUIDPipe) id: string) {
    return this.tasksService.findByIdOrFail(id);
  }

  /**
   * PUT /tasks/:id/accept
   * Contractor accepts a task
   */
  @Put(':id/accept')
  async accept(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.acceptTask(id, req.user.id);
  }

  /**
   * PUT /tasks/:id/start
   * Contractor starts the task
   */
  @Put(':id/start')
  async start(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.startTask(id, req.user.id);
  }

  /**
   * PUT /tasks/:id/complete
   * Contractor marks task as complete
   */
  @Put(':id/complete')
  async complete(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('completionPhotos') completionPhotos?: string[],
  ) {
    return this.tasksService.completeTask(id, req.user.id, completionPhotos);
  }

  /**
   * PUT /tasks/:id/confirm-contractor
   * Client confirms the contractor after they accept (before work starts)
   * This triggers payment and allows contractor to start
   */
  @Put(':id/confirm-contractor')
  async confirmContractor(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.confirmContractor(id, req.user.id);
  }

  /**
   * PUT /tasks/:id/reject-contractor
   * Client rejects the contractor - task goes back to searching
   */
  @Put(':id/reject-contractor')
  async rejectContractor(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('reason') reason?: string,
  ) {
    return this.tasksService.rejectContractor(id, req.user.id, reason);
  }

  /**
   * PUT /tasks/:id/confirm-completion
   * Client confirms the job is complete (moves to pending_complete)
   * Contractor must then finalize to complete the task
   */
  @Put(':id/confirm-completion')
  async confirmCompletion(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.confirmCompletion(id, req.user.id);
  }

  /**
   * PUT /tasks/:id/confirm
   * Client confirms task completion (triggers payment release)
   * @deprecated Use confirm-completion instead
   */
  @Put(':id/confirm')
  async confirm(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    // For backward compatibility, redirect to confirmCompletion
    return this.tasksService.confirmCompletion(id, req.user.id);
  }

  /**
   * PUT /tasks/:id/cancel
   * Cancel a task
   */
  @Put(':id/cancel')
  async cancel(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('reason') reason?: string,
  ) {
    return this.tasksService.cancelTask(id, req.user.id, reason);
  }

  /**
   * POST /tasks/:id/rate
   * Rate a completed task
   */
  @Post(':id/rate')
  async rate(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() rateTaskDto: RateTaskDto,
  ) {
    const task = await this.tasksService.findByIdOrFail(id);

    // Determine who is being rated
    const toUserId =
      req.user.id === task.clientId ? task.contractorId : task.clientId;

    if (!toUserId) {
      throw new Error('Cannot determine rating recipient');
    }

    return this.tasksService.rateTask(id, req.user.id, toUserId, rateTaskDto);
  }

  /**
   * POST /tasks/:id/tip
   * Add tip to a completed task
   */
  @Post(':id/tip')
  async addTip(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body('amount') amount: number,
  ) {
    return this.tasksService.addTip(id, req.user.id, amount);
  }
}
