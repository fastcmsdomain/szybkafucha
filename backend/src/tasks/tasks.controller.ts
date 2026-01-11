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
import { AuthenticatedUser } from '../auth/types/auth-user.type';

interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
}

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

    // For contractors, require location
    if (!lat || !lng) {
      return [];
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
   * PUT /tasks/:id/confirm
   * Client confirms task completion
   */
  @Put(':id/confirm')
  async confirm(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.confirmTask(id, req.user.id);
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
