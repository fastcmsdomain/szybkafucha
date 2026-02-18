/**
 * Tasks Controller
 * REST endpoints for task management
 */
import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
  ParseEnumPipe,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  GoneException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { TasksService } from './tasks.service';
import { FileStorageService } from '../users/file-storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CreateTaskDto } from './dto/create-task.dto';
import { ApplyTaskDto } from './dto/apply-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
import { UserType } from '../users/entities/user.entity';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';
import type { UploadedFile as FileType } from '../users/file-storage.service';

// Max 5MB per image
const MAX_TASK_IMAGE_SIZE = 5 * 1024 * 1024;
const ALLOWED_IMAGE_MIMETYPES = ['image/jpeg', 'image/png', 'image/webp'];

@Controller('tasks')
@UseGuards(JwtAuthGuard)
export class TasksController {
  constructor(
    private readonly tasksService: TasksService,
    private readonly fileStorageService: FileStorageService,
  ) {}

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
   * Use ?role=client or ?role=contractor for dual-role users
   */
  @Get()
  async findAll(
    @Request() req: AuthenticatedRequest,
    @Query('role', new ParseEnumPipe(UserType, { optional: true }))
    role?: UserType,
    @Query('lat') lat?: number,
    @Query('lng') lng?: number,
    @Query('categories') categories?: string,
    @Query('radiusKm') radiusKm?: number,
  ) {
    // Use explicit role param, or infer from user types
    const activeRole: UserType =
      role === UserType.CLIENT || role === UserType.CONTRACTOR
        ? role
        : req.user.types.includes(UserType.CONTRACTOR)
          ? UserType.CONTRACTOR
          : UserType.CLIENT;

    if (activeRole === UserType.CLIENT) {
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
   * GET /tasks/contractor/applications
   * Get all applications for the current contractor
   * NOTE: Must be before :id route to avoid "contractor" being parsed as UUID
   */
  @Get('contractor/applications')
  async getMyApplications(@Request() req: AuthenticatedRequest) {
    return this.tasksService.getMyApplications(req.user.id);
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
   * @deprecated Use POST /tasks/:id/apply instead (bidding system)
   */
  @Put(':id/accept')
  accept(): never {
    throw new GoneException(
      'Direct accept is no longer supported. Use POST /tasks/:id/apply to apply for tasks.',
    );
  }

  /**
   * PUT /tasks/:id/confirm-contractor
   * @deprecated Use PUT /tasks/:id/applications/:appId/accept instead
   */
  @Put(':id/confirm-contractor')
  confirmContractor(): never {
    throw new GoneException(
      'Use PUT /tasks/:id/applications/:appId/accept instead.',
    );
  }

  /**
   * PUT /tasks/:id/reject-contractor
   * @deprecated Use PUT /tasks/:id/applications/:appId/reject instead
   */
  @Put(':id/reject-contractor')
  rejectContractor(): never {
    throw new GoneException(
      'Use PUT /tasks/:id/applications/:appId/reject instead.',
    );
  }

  // ─── Bidding System Endpoints ──────────────────────────────────────

  /**
   * POST /tasks/:id/apply
   * Contractor applies for a task with proposed price and optional message
   */
  @Post(':id/apply')
  async applyForTask(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() applyTaskDto: ApplyTaskDto,
  ) {
    return this.tasksService.applyForTask(id, req.user.id, applyTaskDto);
  }

  /**
   * GET /tasks/:id/applications
   * Get all applications for a task (client only)
   */
  @Get(':id/applications')
  async getApplications(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.getApplications(id, req.user.id);
  }

  /**
   * PUT /tasks/:id/applications/:appId/accept
   * Client accepts a specific application
   */
  @Put(':id/applications/:appId/accept')
  async acceptApplication(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('appId', ParseUUIDPipe) appId: string,
  ) {
    return this.tasksService.acceptApplication(id, appId, req.user.id);
  }

  /**
   * PUT /tasks/:id/applications/:appId/reject
   * Client rejects a specific application
   */
  @Put(':id/applications/:appId/reject')
  async rejectApplication(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
    @Param('appId', ParseUUIDPipe) appId: string,
  ) {
    return this.tasksService.rejectApplication(id, appId, req.user.id);
  }

  /**
   * DELETE /tasks/:id/apply
   * Contractor withdraws their application
   */
  @Delete(':id/apply')
  async withdrawApplication(
    @Request() req: AuthenticatedRequest,
    @Param('id', ParseUUIDPipe) id: string,
  ) {
    return this.tasksService.withdrawApplication(id, req.user.id);
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

  /**
   * POST /tasks/upload-image
   * Upload a task image before creating the task
   * Returns the URL of the uploaded image
   */
  @Post('upload-image')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: MAX_TASK_IMAGE_SIZE,
      },
    }),
  )
  async uploadTaskImage(
    @Request() req: AuthenticatedRequest,
    @UploadedFile() file: FileType,
  ): Promise<{ imageUrl: string; message: string }> {
    // Validate file exists
    if (!file) {
      throw new BadRequestException('No file provided. Use form field "file".');
    }

    // Validate file type
    if (!ALLOWED_IMAGE_MIMETYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid file type: ${file.mimetype}. Allowed: JPEG, PNG, WebP`,
      );
    }

    // Validate file size
    if (file.size > MAX_TASK_IMAGE_SIZE) {
      throw new BadRequestException(
        `File too large: ${Math.round(file.size / 1024 / 1024)}MB. Max: 5MB`,
      );
    }

    // Upload image
    const imageUrl = await this.fileStorageService.uploadTaskImage(
      file,
      req.user.id,
    );

    return {
      imageUrl,
      message: 'Image uploaded successfully',
    };
  }
}
