/**
 * Tasks Service
 * Business logic for task operations and lifecycle management
 */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Inject,
  forwardRef,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task, TaskStatus } from './entities/task.entity';
import {
  TaskApplication,
  ApplicationStatus,
} from './entities/task-application.entity';
import { Rating } from './entities/rating.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';
import { ApplyTaskDto } from './dto/apply-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/constants/notification-templates';
import { ServerEvent } from '../realtime/realtime.gateway';
import { ContractorService } from '../contractor/contractor.service';
import { CreditsService } from '../payments/credits.service';

// MVP Phase 1: Flat fee per side (client pays 10 zł, contractor pays 10 zł)
const MATCHING_FEE_PER_SIDE = 10;

// Scoring weights for contractor matching
const SCORING_WEIGHTS = {
  RATING: 0.4,
  COMPLETIONS: 0.3,
  PROXIMITY: 0.3,
};

// Maximum completions for normalization (contractors with 100+ tasks get max score)
const MAX_COMPLETIONS_FOR_NORMALIZATION = 100;

// Maximum contractors to notify for a new task
const MAX_CONTRACTORS_TO_NOTIFY = 5;

/**
 * Ranked contractor result with score and distance
 */
export interface RankedContractor {
  contractorId: string;
  profile: ContractorProfile;
  score: number;
  distance: number;
}

@Injectable()
export class TasksService {
  private readonly logger = new Logger(TasksService.name);

  constructor(
    @InjectRepository(Task)
    private readonly tasksRepository: Repository<Task>,
    @InjectRepository(TaskApplication)
    private readonly taskApplicationRepository: Repository<TaskApplication>,
    @InjectRepository(Rating)
    private readonly ratingsRepository: Repository<Rating>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @Inject(forwardRef(() => RealtimeGateway))
    private readonly realtimeGateway: RealtimeGateway,
    private readonly notificationsService: NotificationsService,
    @Inject(forwardRef(() => ContractorService))
    private readonly contractorService: ContractorService,
    private readonly creditsService: CreditsService,
  ) {}

  /**
   * Create a new task
   * After creation, notifies nearby available contractors
   */
  async create(clientId: string, dto: CreateTaskDto): Promise<Task> {
    const task = this.tasksRepository.create({
      ...dto,
      clientId,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
    });

    const savedTask = await this.tasksRepository.save(task);

    // Notify available contractors asynchronously (don't block response)
    this.notifyAvailableContractors(savedTask).catch((error) => {
      this.logger.error(
        `Failed to notify contractors for task ${savedTask.id}`,
        error,
      );
    });

    return savedTask;
  }

  /**
   * Update an existing task.
   * Client can edit task details while task is still active.
   */
  async updateTask(
    taskId: string,
    clientId: string,
    dto: UpdateTaskDto,
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (
      task.status === TaskStatus.CANCELLED ||
      task.status === TaskStatus.COMPLETED
    ) {
      throw new BadRequestException('Cannot edit cancelled or completed task');
    }

    if (dto.category !== undefined) task.category = dto.category;
    if (dto.title !== undefined) task.title = dto.title;
    if (dto.description !== undefined) task.description = dto.description;
    if (dto.locationLat !== undefined) task.locationLat = dto.locationLat;
    if (dto.locationLng !== undefined) task.locationLng = dto.locationLng;
    if (dto.address !== undefined) task.address = dto.address;
    if (dto.budgetAmount !== undefined) task.budgetAmount = dto.budgetAmount;
    if (dto.estimatedDurationHours !== undefined) {
      task.estimatedDurationHours = dto.estimatedDurationHours;
    }
    if (dto.maxApplications !== undefined) {
      task.maxApplications = dto.maxApplications;
    }
    if (dto.imageUrls !== undefined) {
      task.imageUrls = dto.imageUrls;
    }
    if (Object.prototype.hasOwnProperty.call(dto, 'scheduledAt')) {
      task.scheduledAt = dto.scheduledAt ? new Date(dto.scheduledAt) : null;
    }

    await this.tasksRepository.save(task);

    // Broadcast update so connected users refresh task data instantly.
    this.realtimeGateway.broadcastTaskStatus(
      task.id,
      task.status,
      clientId,
      task.clientId,
    );
    if (task.contractorId) {
      this.realtimeGateway.sendToUser(
        task.contractorId,
        ServerEvent.TASK_STATUS,
        {
          taskId: task.id,
          status: task.status,
          updatedAt: new Date(),
          updatedBy: clientId,
        },
      );
    }

    // If task is still open for applications, refresh contractor lists in real time.
    if (task.status === TaskStatus.CREATED) {
      const rankedContractors = await this.findAndRankContractors(task);
      for (const ranked of rankedContractors) {
        this.realtimeGateway.sendToUser(
          ranked.contractorId,
          'task:new_available',
          {
            type: 'task:new_available',
            task: {
              id: task.id,
              category: task.category,
              title: task.title,
              budgetAmount: task.budgetAmount,
              address: task.address,
              locationLat: task.locationLat,
              locationLng: task.locationLng,
              createdAt: task.createdAt,
            },
            score: ranked.score,
            distance: ranked.distance,
          },
        );
      }
    }

    return this.findByIdOrFail(taskId);
  }

  /**
   * Find task by ID
   */
  async findById(id: string): Promise<Task | null> {
    return this.tasksRepository.findOne({
      where: { id },
      relations: ['client', 'contractor'],
    });
  }

  /**
   * Find task by ID or throw error
   */
  async findByIdOrFail(id: string): Promise<Task> {
    const task = await this.findById(id);
    if (!task) {
      throw new NotFoundException(`Task with ID ${id} not found`);
    }
    return task;
  }

  /**
   * List tasks for a client
   */
  async findByClient(clientId: string): Promise<Task[]> {
    return this.tasksRepository.find({
      where: { clientId },
      relations: ['contractor'],
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Find all available tasks (MVP - no location filtering)
   * Used when contractor doesn't provide location
   * Includes applicationsCount for room slots display
   */
  async findAllAvailable(): Promise<any[]> {
    const tasks = await this.tasksRepository.find({
      where: { status: TaskStatus.CREATED },
      relations: ['client'],
      order: { createdAt: 'DESC' },
    });

    // Attach application counts for each task
    const tasksWithCounts = await Promise.all(
      tasks.map(async (task) => {
        const applicationsCount = await this.taskApplicationRepository.count({
          where: {
            taskId: task.id,
            status: ApplicationStatus.PENDING,
          },
        });
        return {
          ...task,
          applicationsCount,
        };
      }),
    );

    return tasksWithCounts;
  }

  /**
   * Find all available tasks for public browsing (no authentication)
   * Returns sanitized task data without sensitive client information
   *
   * Security measures:
   * - No client personal information (name, email, phone)
   * - Address sanitized to city/district level only
   * - Coordinates rounded to ~1km precision for privacy
   * - Description truncated to 200 characters
   * - No task images included
   *
   * @param options - Query options (categories, limit)
   * @returns Array of sanitized public task objects
   */
  async findAllAvailablePublic(options: {
    categories?: string[];
    limit: number;
  }): Promise<any[]> {
    const queryBuilder = this.tasksRepository
      .createQueryBuilder('task')
      .where('task.status = :status', { status: TaskStatus.CREATED })
      .orderBy('task.createdAt', 'DESC')
      .limit(options.limit);

    if (options.categories && options.categories.length > 0) {
      queryBuilder.andWhere('task.category IN (:...categories)', {
        categories: options.categories,
      });
    }

    const tasks = await queryBuilder.getMany();

    // Attach application counts and sanitize data
    const results = await Promise.all(
      tasks.map(async (task) => {
        const applicationsCount = await this.taskApplicationRepository.count({
          where: {
            taskId: task.id,
            status: ApplicationStatus.PENDING,
          },
        });
        return {
          id: task.id,
          category: task.category,
          title: task.title,
          description: task.description?.substring(0, 200),
          address: this.sanitizeAddress(task.address),
          budgetAmount: task.budgetAmount,
          locationLat: Math.round(Number(task.locationLat) * 100) / 100,
          locationLng: Math.round(Number(task.locationLng) * 100) / 100,
          createdAt: task.createdAt,
          estimatedDurationHours: task.estimatedDurationHours,
          scheduledAt: task.scheduledAt,
          applicationsCount,
          maxApplications: task.maxApplications,
        };
      }),
    );

    return results;
  }

  /**
   * Find available tasks for contractors
   * Filters by category and location (within radius)
   */
  async findAvailableForContractor(
    contractorId: string,
    categories: string[],
    lat: number,
    lng: number,
    radiusKm: number = 10,
  ): Promise<any[]> {
    // For MVP, use simple distance calculation
    // In production, use PostGIS for accurate geospatial queries
    const tasks = await this.tasksRepository.find({
      where: { status: TaskStatus.CREATED },
      relations: ['client'],
      order: { createdAt: 'DESC' },
    });

    // Filter by category and distance
    const filtered = tasks.filter((task) => {
      // Check category
      if (!categories.includes(task.category)) {
        return false;
      }

      // Calculate distance (simplified Haversine)
      const distance = this.calculateDistance(
        lat,
        lng,
        Number(task.locationLat),
        Number(task.locationLng),
      );

      return distance <= radiusKm;
    });

    // Attach application counts for room slots display
    const tasksWithCounts = await Promise.all(
      filtered.map(async (task) => {
        const applicationsCount = await this.taskApplicationRepository.count({
          where: {
            taskId: task.id,
            status: ApplicationStatus.PENDING,
          },
        });
        return {
          ...task,
          applicationsCount,
        };
      }),
    );

    return tasksWithCounts;
  }

  /**
   * @deprecated Use applyForTask instead. Old direct-accept flow replaced by bidding system.
   */
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  acceptTask(taskId: string, contractorId: string): never {
    throw new BadRequestException(
      'Direct accept is no longer supported. Use POST /tasks/:id/apply to apply for tasks.',
    );
  }

  /**
   * @deprecated Use acceptApplication instead. Old confirm flow replaced by bidding system.
   */
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  confirmContractor(taskId: string, clientId: string): never {
    throw new BadRequestException(
      'Direct confirm is no longer supported. Use PUT /tasks/:id/applications/:appId/accept instead.',
    );
  }

  /**
   * @deprecated Use rejectApplication instead. Old reject flow replaced by bidding system.
   */
  // eslint-disable-next-line @typescript-eslint/no-unused-vars
  rejectContractor(taskId: string, clientId: string, reason?: string): never {
    throw new BadRequestException(
      'Direct reject is no longer supported. Use PUT /tasks/:id/applications/:appId/reject instead.',
    );
  }

  // ─── Bidding System Methods ────────────────────────────────────────

  /**
   * Contractor applies for a task with a proposed price and optional message
   */
  async applyForTask(
    taskId: string,
    contractorId: string,
    dto: ApplyTaskDto,
  ): Promise<TaskApplication> {
    const task = await this.findByIdOrFail(taskId);

    if (task.status !== TaskStatus.CREATED) {
      throw new BadRequestException('Task is no longer accepting applications');
    }

    // Check if contractor profile is complete
    const isComplete =
      await this.contractorService.isProfileComplete(contractorId);
    if (!isComplete) {
      throw new BadRequestException(
        'Complete your contractor profile before applying for tasks',
      );
    }

    // Check if contractor already applied
    const existing = await this.taskApplicationRepository.findOne({
      where: { taskId, contractorId },
    });
    if (existing) {
      // Kicked contractors cannot re-apply
      if (existing.status === ApplicationStatus.KICKED) {
        throw new ForbiddenException(
          'You have been removed from this task and cannot re-apply',
        );
      }
      // Withdrawn contractors can re-apply — reactivate the existing application
      if (existing.status === ApplicationStatus.WITHDRAWN) {
        existing.status = ApplicationStatus.PENDING;
        existing.proposedPrice = dto.proposedPrice;
        existing.message = dto.message || null;
        existing.joinedRoomAt = new Date();
        existing.respondedAt = null;
        await this.taskApplicationRepository.save(existing);

        // Continue below to send notifications (reuse savedApplication reference)
        // Skip creating a new record — jump to notification logic
        return this._notifyClientAboutApplication(
          existing,
          task,
          contractorId,
          dto,
        );
      }
      throw new BadRequestException('You have already applied for this task');
    }

    // Check application limit
    const currentCount = await this.taskApplicationRepository.count({
      where: { taskId, status: ApplicationStatus.PENDING },
    });
    if (currentCount >= task.maxApplications) {
      throw new BadRequestException(
        `Application limit reached (${task.maxApplications}/${task.maxApplications})`,
      );
    }

    const application = this.taskApplicationRepository.create({
      taskId,
      contractorId,
      proposedPrice: dto.proposedPrice,
      message: dto.message || null,
      joinedRoomAt: new Date(),
    });

    const savedApplication =
      await this.taskApplicationRepository.save(application);

    return this._notifyClientAboutApplication(
      savedApplication,
      task,
      contractorId,
      dto,
    );
  }

  /**
   * Send WebSocket + push notifications to client about a new/re-activated application
   */
  private async _notifyClientAboutApplication(
    application: TaskApplication,
    task: Task,
    contractorId: string,
    dto: ApplyTaskDto,
  ): Promise<TaskApplication> {
    const currentCount = await this.taskApplicationRepository.count({
      where: { taskId: task.id, status: ApplicationStatus.PENDING },
    });

    // Get contractor profile for notification details
    const contractorProfile = await this.contractorProfileRepository.findOne({
      where: { userId: contractorId },
      relations: ['user'],
    });

    // Notify client via WebSocket about new application
    const applicationSummary = {
      applicationId: application.id,
      taskId: task.id,
      contractor: {
        id: contractorId,
        name: contractorProfile?.user?.name || 'Wykonawca',
        avatarUrl: contractorProfile?.user?.avatarUrl || null,
        rating: contractorProfile?.ratingAvg || 0,
        completedTasks: contractorProfile?.completedTasksCount || 0,
        bio: contractorProfile?.bio || null,
      },
      proposedPrice: dto.proposedPrice,
      message: dto.message || null,
      createdAt: application.createdAt,
      applicationCount: currentCount,
      maxApplications: task.maxApplications,
    };

    this.realtimeGateway.sendToUser(
      task.clientId,
      ServerEvent.APPLICATION_NEW,
      applicationSummary,
    );

    // Also send application count update
    this.realtimeGateway.sendToUser(
      task.clientId,
      ServerEvent.APPLICATION_COUNT,
      {
        taskId: task.id,
        count: currentCount,
        max: task.maxApplications,
      },
    );

    // Push notification to client
    this.notificationsService
      .sendToUser(task.clientId, NotificationType.TASK_ACCEPTED, {
        taskTitle: task.title,
        contractorName: contractorProfile?.user?.name || 'Wykonawca',
      })
      .catch((err) =>
        this.logger.error(
          `Failed to send new application notification: ${err}`,
        ),
      );

    this.logger.log(
      `Contractor ${contractorId} applied for task ${task.id} with price ${dto.proposedPrice} PLN`,
    );

    return application;
  }

  /**
   * Get all applications for a task (client only)
   * Returns applications with contractor profile details
   */
  async getApplications(taskId: string, clientId: string): Promise<any[]> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    const applications = await this.taskApplicationRepository.find({
      where: { taskId },
      relations: ['contractor'],
      order: { createdAt: 'ASC' },
    });

    // Enrich with contractor profile details
    const enriched = await Promise.all(
      applications.map(async (app) => {
        const profile = await this.contractorProfileRepository.findOne({
          where: { userId: app.contractorId },
          relations: ['user'],
        });

        // Calculate distance from task
        let distanceKm: number | null = null;
        if (profile?.lastLocationLat && profile?.lastLocationLng) {
          distanceKm = Number(
            this.calculateDistance(
              Number(task.locationLat),
              Number(task.locationLng),
              Number(profile.lastLocationLat),
              Number(profile.lastLocationLng),
            ).toFixed(1),
          );
        }

        return {
          id: app.id,
          taskId: app.taskId,
          contractorId: app.contractorId,
          contractorName: profile?.user?.name || 'Wykonawca',
          contractorAvatarUrl: profile?.user?.avatarUrl || null,
          contractorRating: profile?.ratingAvg || 0,
          contractorReviewCount: profile?.ratingCount || 0,
          contractorCompletedTasks: profile?.completedTasksCount || 0,
          contractorBio: profile?.bio || null,
          distanceKm,
          proposedPrice: app.proposedPrice,
          message: app.message,
          status: app.status,
          createdAt: app.createdAt,
        };
      }),
    );

    return enriched;
  }

  /**
   * Client accepts an application - assigns contractor to task
   * Auto-rejects all other pending applications
   */
  async acceptApplication(
    taskId: string,
    applicationId: string,
    clientId: string,
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.CREATED) {
      throw new BadRequestException(
        'Task must be in created state to accept applications',
      );
    }

    const application = await this.taskApplicationRepository.findOne({
      where: { id: applicationId, taskId },
    });

    if (!application) {
      throw new NotFoundException('Application not found');
    }

    if (application.status !== ApplicationStatus.PENDING) {
      throw new BadRequestException('Application is no longer pending');
    }

    // MVP Phase 1: Atomic credit deduction (10 zł from client + 10 zł from contractor)
    await this.creditsService.deductMatchingFee(
      clientId,
      application.contractorId,
      taskId,
      MATCHING_FEE_PER_SIDE,
    );

    // Accept this application
    application.status = ApplicationStatus.ACCEPTED;
    application.respondedAt = new Date();
    await this.taskApplicationRepository.save(application);

    // Assign contractor to task and move to CONFIRMED
    task.contractorId = application.contractorId;
    task.status = TaskStatus.CONFIRMED;
    task.confirmedAt = new Date();
    task.finalAmount = application.proposedPrice;
    task.flatFee = MATCHING_FEE_PER_SIDE;
    task.matchingFee = MATCHING_FEE_PER_SIDE;

    const savedTask = await this.tasksRepository.save(task);

    // Auto-reject all other pending applications
    const otherApplications = await this.taskApplicationRepository.find({
      where: { taskId, status: ApplicationStatus.PENDING },
    });

    for (const otherApp of otherApplications) {
      otherApp.status = ApplicationStatus.REJECTED;
      otherApp.respondedAt = new Date();
      await this.taskApplicationRepository.save(otherApp);

      // Notify rejected contractor
      this.realtimeGateway.sendToUser(
        otherApp.contractorId,
        ServerEvent.APPLICATION_REJECTED,
        {
          taskId,
          applicationId: otherApp.id,
          status: 'rejected',
          reason: 'Klient wybrał innego wykonawcę',
        },
      );

      this.notificationsService
        .sendToUser(otherApp.contractorId, NotificationType.TASK_CANCELLED, {
          taskTitle: task.title,
          reason: 'Klient wybrał innego wykonawcę',
        })
        .catch((err) =>
          this.logger.error(`Failed to send rejection notification: ${err}`),
        );
    }

    // Get contractor profile for WebSocket broadcast
    const contractorProfile = await this.contractorProfileRepository.findOne({
      where: { userId: application.contractorId },
      relations: ['user'],
    });

    // Notify accepted contractor via WebSocket
    this.realtimeGateway.sendToUser(
      application.contractorId,
      ServerEvent.APPLICATION_ACCEPTED,
      {
        taskId,
        applicationId: application.id,
        status: 'accepted',
        task: {
          id: task.id,
          title: task.title,
          category: task.category,
          address: task.address,
          finalAmount: application.proposedPrice,
        },
      },
    );

    // Broadcast task status update to client
    this.realtimeGateway.broadcastTaskStatusWithContractor(
      taskId,
      TaskStatus.CONFIRMED,
      clientId,
      task.clientId,
      {
        id: application.contractorId,
        name: contractorProfile?.user?.name || 'Wykonawca',
        avatarUrl: contractorProfile?.user?.avatarUrl || null,
        rating: contractorProfile?.ratingAvg || 0,
        completedTasks: contractorProfile?.completedTasksCount || 0,
        bio: contractorProfile?.bio || null,
      },
    );

    // Push notification to accepted contractor
    this.notificationsService
      .sendToUser(application.contractorId, NotificationType.TASK_CONFIRMED, {
        taskTitle: task.title,
      })
      .catch((err) =>
        this.logger.error(`Failed to send acceptance notification: ${err}`),
      );

    this.logger.log(
      `Client ${clientId} accepted application ${applicationId} for task ${taskId}. Contractor: ${application.contractorId}`,
    );

    return savedTask;
  }

  /**
   * Client rejects a specific application
   */
  async rejectApplication(
    taskId: string,
    applicationId: string,
    clientId: string,
  ): Promise<TaskApplication> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    const application = await this.taskApplicationRepository.findOne({
      where: { id: applicationId, taskId },
    });

    if (!application) {
      throw new NotFoundException('Application not found');
    }

    if (application.status !== ApplicationStatus.PENDING) {
      throw new BadRequestException('Application is no longer pending');
    }

    application.status = ApplicationStatus.REJECTED;
    application.respondedAt = new Date();
    const savedApplication =
      await this.taskApplicationRepository.save(application);

    // Notify contractor
    this.realtimeGateway.sendToUser(
      application.contractorId,
      ServerEvent.APPLICATION_REJECTED,
      {
        taskId,
        applicationId: application.id,
        status: 'rejected',
      },
    );

    // Update application count for client
    const pendingCount = await this.taskApplicationRepository.count({
      where: { taskId, status: ApplicationStatus.PENDING },
    });
    this.realtimeGateway.sendToUser(
      task.clientId,
      ServerEvent.APPLICATION_COUNT,
      {
        taskId,
        count: pendingCount,
        max: task.maxApplications,
      },
    );

    // Push notification
    this.notificationsService
      .sendToUser(application.contractorId, NotificationType.TASK_CANCELLED, {
        taskTitle: task.title,
        reason: 'Twoje zgłoszenie zostało odrzucone',
      })
      .catch((err) =>
        this.logger.error(`Failed to send rejection notification: ${err}`),
      );

    this.logger.log(
      `Client ${clientId} rejected application ${applicationId} for task ${taskId}`,
    );

    return savedApplication;
  }

  /**
   * Contractor withdraws their application
   */
  async withdrawApplication(
    taskId: string,
    contractorId: string,
  ): Promise<TaskApplication> {
    const application = await this.taskApplicationRepository.findOne({
      where: { taskId, contractorId, status: ApplicationStatus.PENDING },
    });

    if (!application) {
      throw new NotFoundException('No pending application found for this task');
    }

    application.status = ApplicationStatus.WITHDRAWN;
    application.respondedAt = new Date();
    const savedApplication =
      await this.taskApplicationRepository.save(application);

    const task = await this.findByIdOrFail(taskId);

    // Notify client that contractor withdrew
    this.realtimeGateway.sendToUser(
      task.clientId,
      ServerEvent.APPLICATION_WITHDRAWN,
      {
        taskId,
        applicationId: application.id,
        contractorId,
      },
    );

    // Update application count
    const pendingCount = await this.taskApplicationRepository.count({
      where: { taskId, status: ApplicationStatus.PENDING },
    });
    this.realtimeGateway.sendToUser(
      task.clientId,
      ServerEvent.APPLICATION_COUNT,
      {
        taskId,
        count: pendingCount,
        max: task.maxApplications,
      },
    );

    this.logger.log(
      `Contractor ${contractorId} withdrew application for task ${taskId}`,
    );

    return savedApplication;
  }

  /**
   * Client kicks a contractor from the room
   * Rate limits: max 3 kicks per 5 minutes per task
   * Soft cap: warn after 10 kicks per task, hard cap at 20
   */
  async kickFromRoom(
    taskId: string,
    applicationId: string,
    clientId: string,
  ): Promise<{ message: string; kickCount: number }> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.CREATED) {
      throw new BadRequestException(
        'Can only kick contractors before accepting one',
      );
    }

    const application = await this.taskApplicationRepository.findOne({
      where: { id: applicationId, taskId, status: ApplicationStatus.PENDING },
    });

    if (!application) {
      throw new NotFoundException('Application not found or not pending');
    }

    // Count total kicks for this task
    const totalKicks = await this.taskApplicationRepository.count({
      where: { taskId, status: ApplicationStatus.KICKED },
    });

    // Hard cap: 20 kicks per task
    if (totalKicks >= 20) {
      throw new BadRequestException(
        'Osiągnięto limit usunięć z pokoju (20). Skontaktuj się z pomocą techniczną.',
      );
    }

    // Kick the contractor
    application.status = ApplicationStatus.KICKED;
    application.respondedAt = new Date();
    await this.taskApplicationRepository.save(application);

    // Update application count for client
    const pendingCount = await this.taskApplicationRepository.count({
      where: { taskId, status: ApplicationStatus.PENDING },
    });

    // Notify kicked contractor via WebSocket
    this.realtimeGateway.sendToUser(
      application.contractorId,
      ServerEvent.APPLICATION_REJECTED,
      {
        taskId,
        applicationId: application.id,
        status: 'kicked',
        reason: 'Klient usunął Cię z pokoju',
      },
    );

    // Update count for client
    this.realtimeGateway.sendToUser(
      task.clientId,
      ServerEvent.APPLICATION_COUNT,
      {
        taskId,
        count: pendingCount,
        max: task.maxApplications,
      },
    );

    const newKickCount = totalKicks + 1;
    let message = 'Wykonawca usunięty z pokoju';
    if (newKickCount >= 10) {
      message += ` (uwaga: ${newKickCount}/20 usunięć)`;
    }

    this.logger.log(
      `Client ${clientId} kicked contractor ${application.contractorId} from task ${taskId} (kick ${newKickCount})`,
    );

    return { message, kickCount: newKickCount };
  }

  /**
   * Get all applications for a contractor (their application history)
   */
  async getMyApplications(contractorId: string): Promise<any[]> {
    const applications = await this.taskApplicationRepository.find({
      where: { contractorId },
      relations: ['task'],
      order: { createdAt: 'DESC' },
    });

    return applications.map((app) => ({
      id: app.id,
      taskId: app.taskId,
      clientId: app.task?.clientId || '',
      taskTitle: app.task?.title || '',
      taskCategory: app.task?.category || '',
      taskAddress: app.task?.address || '',
      taskBudgetAmount: app.task?.budgetAmount || 0,
      proposedPrice: app.proposedPrice,
      message: app.message,
      status: app.status,
      createdAt: app.createdAt,
      respondedAt: app.respondedAt,
    }));
  }

  /**
   * Contractor starts the task
   */
  async startTask(taskId: string, contractorId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.contractorId !== contractorId) {
      throw new ForbiddenException('You are not assigned to this task');
    }

    // Allow starting from ACCEPTED (backward compat) or CONFIRMED (new flow)
    if (
      task.status !== TaskStatus.ACCEPTED &&
      task.status !== TaskStatus.CONFIRMED
    ) {
      throw new BadRequestException(
        'Task must be accepted or confirmed before starting',
      );
    }

    task.status = TaskStatus.IN_PROGRESS;
    task.startedAt = new Date();

    const savedTask = await this.tasksRepository.save(task);

    // Get contractor profile for name
    const contractorProfile = await this.contractorProfileRepository.findOne({
      where: { userId: contractorId },
      relations: ['user'],
    });

    // Broadcast via WebSocket to client
    this.realtimeGateway.broadcastTaskStatus(
      taskId,
      TaskStatus.IN_PROGRESS,
      contractorId,
      task.clientId,
    );

    // Notify client that task was started (push notification as backup)
    this.notificationsService
      .sendToUser(task.clientId, NotificationType.TASK_STARTED, {
        taskTitle: task.title,
        contractorName: contractorProfile?.user?.name || 'Wykonawca',
      })
      .catch((err) =>
        this.logger.error(`Failed to send TASK_STARTED notification: ${err}`),
      );

    return savedTask;
  }

  /**
   * Contractor acknowledges task completion
   * Task must be in PENDING_COMPLETE status (client already confirmed)
   * Status stays PENDING_COMPLETE until both parties rate - then changes to COMPLETED
   */
  async completeTask(
    taskId: string,
    contractorId: string,
    completionPhotos?: string[],
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.contractorId !== contractorId) {
      throw new ForbiddenException('You are not assigned to this task');
    }

    // Task must be in PENDING_COMPLETE (client confirmed) to complete
    if (task.status !== TaskStatus.PENDING_COMPLETE) {
      throw new BadRequestException(
        'Client must confirm completion first before contractor can finalize',
      );
    }

    // MVP Phase 1: Payment already settled at acceptance (flat fee credits model)
    // Set finalAmount for records, no commission calculation needed
    task.finalAmount = task.budgetAmount;
    task.completionPhotos = completionPhotos || null;

    const savedTask = await this.tasksRepository.save(task);

    this.logger.log(
      `Contractor ${contractorId} acknowledged completion of task ${taskId}. Awaiting ratings from both parties.`,
    );

    return savedTask;
  }

  /**
   * Client confirms task completion
   * Changes status from IN_PROGRESS to PENDING_COMPLETE
   * Contractor must then call completeTask to finalize
   */
  async confirmCompletion(taskId: string, clientId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.IN_PROGRESS) {
      throw new BadRequestException(
        'Task must be in progress for client to confirm completion',
      );
    }

    task.status = TaskStatus.PENDING_COMPLETE;

    const savedTask = await this.tasksRepository.save(task);

    // Broadcast via WebSocket to contractor
    this.realtimeGateway.broadcastTaskStatus(
      taskId,
      TaskStatus.PENDING_COMPLETE,
      clientId,
      task.contractorId!,
    );

    // Notify contractor that client confirmed - they can now complete the task
    if (task.contractorId) {
      this.notificationsService
        .sendToUser(task.contractorId, NotificationType.TASK_CONFIRMED, {
          taskTitle: task.title,
        })
        .catch((err) =>
          this.logger.error(
            `Failed to send completion confirmation notification: ${err}`,
          ),
        );
    }

    return savedTask;
  }

  /**
   * Client confirms task completion (triggers payment)
   * @deprecated Use confirmCompletion instead
   */
  async confirmTask(taskId: string, clientId: string): Promise<Task> {
    // Redirect to new confirmCompletion method for backward compatibility
    return this.confirmCompletion(taskId, clientId);
  }

  /**
   * Cancel a task
   * - When CONTRACTOR cancels: task returns to 'posted' status (available for other contractors)
   * - When CLIENT cancels: task is truly cancelled
   */
  async cancelTask(
    taskId: string,
    userId: string,
    reason?: string,
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    // Check if task can be cancelled
    if (
      task.status === TaskStatus.COMPLETED ||
      task.status === TaskStatus.CANCELLED
    ) {
      throw new BadRequestException(
        'Cannot cancel completed or already cancelled task',
      );
    }

    const isContractorCancelling = task.contractorId === userId;
    const isClientCancelling = task.clientId === userId;

    if (!isClientCancelling && !isContractorCancelling) {
      throw new ForbiddenException('You cannot cancel this task');
    }

    // Store contractor ID before clearing (for notifications)
    const previousContractorId = task.contractorId;

    // MVP Phase 1: Process credit refunds if matching fee was already paid
    const wasMatchingFeePaid =
      (task.status === TaskStatus.CONFIRMED ||
        task.status === TaskStatus.IN_PROGRESS) &&
      task.contractorId &&
      Number(task.flatFee) > 0;

    if (wasMatchingFeePaid) {
      const cancellerId = userId;
      const injuredPartyId = isClientCancelling
        ? task.contractorId!
        : task.clientId;

      await this.creditsService.processCancellationRefund(
        cancellerId,
        injuredPartyId,
        taskId,
        MATCHING_FEE_PER_SIDE,
      );

      this.logger.log(
        `Cancellation refund processed for task ${taskId}. Canceller: ${cancellerId}, injured: ${injuredPartyId}`,
      );
    }

    if (isContractorCancelling) {
      // CONTRACTOR is cancelling - return task to 'posted' status so other contractors can accept it
      this.logger.log(
        `Contractor ${userId} releasing task ${taskId} - returning to posted status`,
      );

      task.status = TaskStatus.CREATED;
      task.contractorId = null;
      task.acceptedAt = null;
      task.confirmedAt = null;
      task.startedAt = null;
      task.flatFee = 0;
      task.matchingFee = 0;

      const savedTask = await this.tasksRepository.save(task);

      // Broadcast status change - task is now available again
      this.realtimeGateway.broadcastTaskStatus(
        taskId,
        TaskStatus.CREATED,
        userId,
        task.clientId,
      );

      // Notify client that contractor released the task
      this.notificationsService
        .sendToUser(task.clientId, NotificationType.TASK_CANCELLED, {
          taskTitle: task.title,
          reason:
            reason ||
            'Wykonawca zrezygnował ze zlecenia. Zlecenie jest ponownie dostępne.',
        })
        .catch((err) =>
          this.logger.error(
            `Failed to send task released notification: ${err}`,
          ),
        );

      return savedTask;
    } else {
      // CLIENT is cancelling - truly cancel the task
      this.logger.log(
        `Client ${userId} cancelling task ${taskId} in status ${task.status}`,
      );

      task.status = TaskStatus.CANCELLED;
      task.cancelledAt = new Date();
      task.cancellationReason = reason || null;

      const savedTask = await this.tasksRepository.save(task);

      // Auto-reject all pending applications
      const pendingApplications = await this.taskApplicationRepository.find({
        where: { taskId, status: ApplicationStatus.PENDING },
      });

      for (const app of pendingApplications) {
        app.status = ApplicationStatus.REJECTED;
        app.respondedAt = new Date();
        await this.taskApplicationRepository.save(app);

        this.realtimeGateway.sendToUser(
          app.contractorId,
          ServerEvent.APPLICATION_REJECTED,
          {
            taskId,
            applicationId: app.id,
            status: 'rejected',
            reason: 'Zlecenie zostało anulowane',
          },
        );

        this.notificationsService
          .sendToUser(app.contractorId, NotificationType.TASK_CANCELLED, {
            taskTitle: task.title,
            reason: 'Zlecenie zostało anulowane',
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send cancellation notification to applicant: ${err}`,
            ),
          );
      }

      // Broadcast via WebSocket to both parties
      this.realtimeGateway.broadcastTaskStatus(
        taskId,
        TaskStatus.CANCELLED,
        userId,
        task.clientId,
      );

      // Also notify contractor directly (they might not be in the task room)
      if (previousContractorId) {
        this.realtimeGateway.sendToUser(
          previousContractorId,
          ServerEvent.TASK_STATUS,
          {
            taskId,
            status: TaskStatus.CANCELLED,
            updatedAt: new Date(),
            updatedBy: userId,
          },
        );
      }

      // Notify contractor if there was one assigned
      if (previousContractorId) {
        this.notificationsService
          .sendToUser(previousContractorId, NotificationType.TASK_CANCELLED, {
            taskTitle: task.title,
            reason: reason || 'Anulowałeś zlecenie',
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send TASK_CANCELLED notification: ${err}`,
            ),
          );
      }

      return savedTask;
    }
  }

  /**
   * Rate a completed or pending_complete task
   * Client can rate when confirming completion (PENDING_COMPLETE)
   * Contractor can rate after completing (COMPLETED)
   */
  async rateTask(
    taskId: string,
    fromUserId: string,
    toUserId: string,
    dto: RateTaskDto,
  ): Promise<Rating> {
    const task = await this.findByIdOrFail(taskId);

    if (
      task.status !== TaskStatus.COMPLETED &&
      task.status !== TaskStatus.PENDING_COMPLETE
    ) {
      throw new BadRequestException(
        'Can only rate tasks that are completed or pending completion',
      );
    }

    // Check if already rated
    const existingRating = await this.ratingsRepository.findOne({
      where: { taskId, fromUserId },
    });

    if (existingRating) {
      throw new BadRequestException('You have already rated this task');
    }

    // Determine the role of the person being rated
    // If toUserId is the client, they're being rated as a client
    // If toUserId is the contractor, they're being rated as a contractor
    const role = toUserId === task.clientId ? 'client' : 'contractor';

    const rating = this.ratingsRepository.create({
      taskId,
      fromUserId,
      toUserId,
      rating: dto.rating,
      comment: dto.comment,
      role, // NEW: Add role field
    });

    const savedRating = await this.ratingsRepository.save(rating);

    // Track who has rated
    if (fromUserId === task.clientId) {
      task.clientRated = true;
      this.logger.log(`Client ${fromUserId} rated task ${taskId}`);
    } else if (fromUserId === task.contractorId) {
      task.contractorRated = true;
      this.logger.log(`Contractor ${fromUserId} rated task ${taskId}`);
    }

    // Check if both parties have now rated - if so, mark as COMPLETED
    if (task.clientRated && task.contractorRated && task.contractorId) {
      task.status = TaskStatus.COMPLETED;
      task.completedAt = new Date();
      this.logger.log(
        `Both parties rated task ${taskId}. Status changed to COMPLETED.`,
      );

      // Broadcast COMPLETED status via WebSocket
      this.realtimeGateway.broadcastTaskStatus(
        taskId,
        TaskStatus.COMPLETED,
        task.contractorId,
        task.clientId,
      );

      // Notify both parties that task is fully completed
      this.notificationsService
        .sendToUser(task.clientId, NotificationType.TASK_COMPLETED, {
          taskTitle: task.title,
        })
        .catch((err) =>
          this.logger.error(
            `Failed to send TASK_COMPLETED notification to client: ${err}`,
          ),
        );
      this.notificationsService
        .sendToUser(task.contractorId, NotificationType.TASK_COMPLETED, {
          taskTitle: task.title,
        })
        .catch((err) =>
          this.logger.error(
            `Failed to send TASK_COMPLETED notification to contractor: ${err}`,
          ),
        );
    }

    await this.tasksRepository.save(task);

    // Notify the rated user
    this.notificationsService
      .sendToUser(toUserId, NotificationType.TASK_RATED, {
        taskTitle: task.title,
        rating: dto.rating,
      })
      .catch((err) =>
        this.logger.error(`Failed to send TASK_RATED notification: ${err}`),
      );

    return savedRating;
  }

  /**
   * Add tip to a task
   * Client can tip when confirming completion (PENDING_COMPLETE) or after (COMPLETED)
   */
  async addTip(
    taskId: string,
    clientId: string,
    tipAmount: number,
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (
      task.status !== TaskStatus.COMPLETED &&
      task.status !== TaskStatus.PENDING_COMPLETE
    ) {
      throw new BadRequestException(
        'Can only tip tasks that are completed or pending completion',
      );
    }

    task.tipAmount = tipAmount;
    const savedTask = await this.tasksRepository.save(task);

    // Notify contractor about tip
    if (task.contractorId) {
      this.notificationsService
        .sendToUser(task.contractorId, NotificationType.TIP_RECEIVED, {
          taskTitle: task.title,
          tipAmount,
        })
        .catch((err) =>
          this.logger.error(`Failed to send TIP_RECEIVED notification: ${err}`),
        );
    }

    return savedTask;
  }

  /**
   * Calculate distance between two coordinates (Haversine formula)
   */
  calculateDistance(
    lat1: number,
    lng1: number,
    lat2: number,
    lng2: number,
  ): number {
    const R = 6371; // Earth's radius in km
    const dLat = this.deg2rad(lat2 - lat1);
    const dLng = this.deg2rad(lng2 - lng1);
    const a =
      Math.sin(dLat / 2) * Math.sin(dLat / 2) +
      Math.cos(this.deg2rad(lat1)) *
        Math.cos(this.deg2rad(lat2)) *
        Math.sin(dLng / 2) *
        Math.sin(dLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c;
  }

  private deg2rad(deg: number): number {
    return deg * (Math.PI / 180);
  }

  /**
   * Calculate contractor score for matching algorithm
   * Score = (rating * 0.4) + (completions * 0.3) + (proximity * 0.3)
   *
   * @param rating - Contractor's average rating (0-5)
   * @param completedTasks - Number of completed tasks
   * @param distance - Distance from task location in km
   * @param maxRadius - Maximum radius for proximity calculation in km
   * @returns Score between 0 and 1
   */
  calculateContractorScore(
    rating: number,
    completedTasks: number,
    distance: number,
    maxRadius: number,
  ): number {
    // Normalize rating (0-5) to (0-1)
    const normalizedRating = Math.min(Number(rating) / 5, 1);

    // Normalize completions (0-100+) to (0-1), cap at 100
    const normalizedCompletions = Math.min(
      completedTasks / MAX_COMPLETIONS_FOR_NORMALIZATION,
      1,
    );

    // Calculate proximity (0-1), where 1 = same location, 0 = at max radius
    // Contractors beyond maxRadius are filtered out before scoring
    const proximity = Math.max(0, 1 - distance / maxRadius);

    // Apply weights
    const score =
      normalizedRating * SCORING_WEIGHTS.RATING +
      normalizedCompletions * SCORING_WEIGHTS.COMPLETIONS +
      proximity * SCORING_WEIGHTS.PROXIMITY;

    return Number(score.toFixed(4));
  }

  /**
   * Find and rank contractors for a task based on scoring algorithm
   * Returns contractors sorted by score (highest first)
   *
   * @param task - Task to find contractors for
   * @param maxRadius - Maximum search radius in km (default 20km)
   * @param limit - Maximum number of contractors to return
   */
  async findAndRankContractors(
    task: Task,
    maxRadius: number = 20,
    limit: number = MAX_CONTRACTORS_TO_NOTIFY,
  ): Promise<RankedContractor[]> {
    // Find all online contractors with matching category
    // TODO: Re-enable KYC check before production: kycStatus: KycStatus.VERIFIED
    const contractors = await this.contractorProfileRepository.find({
      where: {
        isOnline: true,
        // MVP: Allow non-verified contractors for testing
        // kycStatus: KycStatus.VERIFIED,
      },
      relations: ['user'],
    });

    const rankedContractors: RankedContractor[] = [];

    for (const profile of contractors) {
      // Skip if contractor doesn't have location set
      if (!profile.lastLocationLat || !profile.lastLocationLng) {
        continue;
      }

      // Skip if contractor doesn't handle this category
      if (!profile.categories.includes(task.category)) {
        continue;
      }

      // Calculate distance
      const distance = this.calculateDistance(
        Number(task.locationLat),
        Number(task.locationLng),
        Number(profile.lastLocationLat),
        Number(profile.lastLocationLng),
      );

      // Skip if beyond max radius
      if (distance > maxRadius) {
        continue;
      }

      // Calculate score
      const score = this.calculateContractorScore(
        profile.ratingAvg,
        profile.completedTasksCount,
        distance,
        maxRadius,
      );

      rankedContractors.push({
        contractorId: profile.userId,
        profile,
        score,
        distance: Number(distance.toFixed(2)),
      });
    }

    // Sort by score (highest first)
    rankedContractors.sort((a, b) => b.score - a.score);

    // Return top N contractors
    return rankedContractors.slice(0, limit);
  }

  /**
   * Notify available contractors about a new task via WebSocket
   * Sends notification to top-ranked contractors
   */
  async notifyAvailableContractors(task: Task): Promise<void> {
    // Find top contractors for this task
    const rankedContractors = await this.findAndRankContractors(task);

    if (rankedContractors.length === 0) {
      this.logger.debug(`No available contractors found for task ${task.id}`);
      return;
    }

    this.logger.log(
      `Notifying ${rankedContractors.length} contractors for task ${task.id}`,
    );

    // Prepare notification payload
    const notification = {
      type: 'task:new_available',
      task: {
        id: task.id,
        category: task.category,
        title: task.title,
        budgetAmount: task.budgetAmount,
        address: task.address,
        locationLat: task.locationLat,
        locationLng: task.locationLng,
        createdAt: task.createdAt,
      },
    };

    // Send to each contractor via WebSocket and Push Notification
    for (const ranked of rankedContractors) {
      const sent = this.realtimeGateway.sendToUser(
        ranked.contractorId,
        'task:new_available',
        {
          ...notification,
          score: ranked.score,
          distance: ranked.distance,
        },
      );

      // Also send push notification for offline contractors
      this.notificationsService
        .sendToUser(ranked.contractorId, NotificationType.NEW_TASK_NEARBY, {
          category: task.category,
          budget: task.budgetAmount,
          distance: ranked.distance,
        })
        .catch((err) =>
          this.logger.error(`Failed to send NEW_TASK_NEARBY push: ${err}`),
        );

      if (sent) {
        this.logger.debug(
          `Notified contractor ${ranked.contractorId} (score: ${ranked.score}, distance: ${ranked.distance}km)`,
        );
      }
    }
  }

  /**
   * Sanitize address to show only city/district (privacy protection)
   * Returns first 2 parts of comma-separated address
   *
   * Example: "ul. Marszałkowska 1, Warszawa, Śródmieście, 00-001"
   *          -> "Warszawa, Śródmieście"
   *
   * @param fullAddress - Full address string
   * @returns Sanitized address with only city/district
   */
  private sanitizeAddress(fullAddress: string): string {
    if (!fullAddress) return '';

    const parts = fullAddress.split(',').map((p) => p.trim());
    // Return only first 2 parts (e.g., "Warszawa, Śródmieście")
    return parts.slice(0, 2).join(', ');
  }
}
