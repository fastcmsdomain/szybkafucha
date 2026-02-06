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
import { Rating } from './entities/rating.entity';
import {
  ContractorProfile,
  KycStatus,
} from '../contractor/entities/contractor-profile.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/constants/notification-templates';
import { ServerEvent } from '../realtime/realtime.gateway';
import { ContractorService } from '../contractor/contractor.service';

// Platform commission percentage
const COMMISSION_RATE = 0.17;

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
    @InjectRepository(Rating)
    private readonly ratingsRepository: Repository<Rating>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @Inject(forwardRef(() => RealtimeGateway))
    private readonly realtimeGateway: RealtimeGateway,
    private readonly notificationsService: NotificationsService,
    @Inject(forwardRef(() => ContractorService))
    private readonly contractorService: ContractorService,
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
   */
  async findAllAvailable(): Promise<Task[]> {
    return this.tasksRepository.find({
      where: { status: TaskStatus.CREATED },
      relations: ['client'],
      order: { createdAt: 'DESC' },
    });
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
  ): Promise<Task[]> {
    // For MVP, use simple distance calculation
    // In production, use PostGIS for accurate geospatial queries
    const tasks = await this.tasksRepository.find({
      where: { status: TaskStatus.CREATED },
      relations: ['client'],
      order: { createdAt: 'DESC' },
    });

    // Filter by category and distance
    return tasks.filter((task) => {
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
  }

  /**
   * Contractor accepts a task
   * Validates that contractor profile is complete before allowing acceptance
   */
  async acceptTask(taskId: string, contractorId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.status !== TaskStatus.CREATED) {
      throw new BadRequestException('Task is no longer available');
    }

    // NEW: Check if contractor profile is complete
    const isComplete =
      await this.contractorService.isProfileComplete(contractorId);
    if (!isComplete) {
      throw new BadRequestException(
        'Complete your contractor profile before accepting tasks',
      );
    }

    task.contractorId = contractorId;
    task.status = TaskStatus.ACCEPTED;
    task.acceptedAt = new Date();

    const savedTask = await this.tasksRepository.save(task);

    // Get contractor profile for name
    const contractorProfile = await this.contractorProfileRepository.findOne({
      where: { userId: contractorId },
      relations: ['user'],
    });

    // Broadcast via WebSocket to client with contractor details
    this.realtimeGateway.broadcastTaskStatusWithContractor(
      taskId,
      TaskStatus.ACCEPTED,
      contractorId,
      task.clientId,
      {
        id: contractorId,
        name: contractorProfile?.user?.name || 'Wykonawca',
        avatarUrl: contractorProfile?.user?.avatarUrl || null,
        rating: contractorProfile?.ratingAvg || 0,
        completedTasks: contractorProfile?.completedTasksCount || 0,
        bio: contractorProfile?.bio || null,
      },
    );

    // Notify client that task was accepted (push notification as backup)
    this.notificationsService
      .sendToUser(task.clientId, NotificationType.TASK_ACCEPTED, {
        taskTitle: task.title,
        contractorName: contractorProfile?.user?.name || 'Wykonawca',
      })
      .catch((err) =>
        this.logger.error(`Failed to send TASK_ACCEPTED notification: ${err}`),
      );

    return savedTask;
  }

  /**
   * Client confirms the contractor after they accept
   * Changes status from ACCEPTED to CONFIRMED, triggers payment
   */
  async confirmContractor(taskId: string, clientId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.ACCEPTED) {
      throw new BadRequestException(
        'Task must be in accepted state to confirm contractor',
      );
    }

    task.status = TaskStatus.CONFIRMED;
    task.confirmedAt = new Date();

    const savedTask = await this.tasksRepository.save(task);

    // Broadcast via WebSocket to contractor
    this.realtimeGateway.broadcastTaskStatus(
      taskId,
      TaskStatus.CONFIRMED,
      clientId,
      task.contractorId!,
    );

    // Notify contractor that client confirmed them
    if (task.contractorId) {
      this.notificationsService
        .sendToUser(task.contractorId, NotificationType.TASK_CONFIRMED, {
          taskTitle: task.title,
        })
        .catch((err) =>
          this.logger.error(
            `Failed to send contractor confirmation notification: ${err}`,
          ),
        );
    }

    return savedTask;
  }

  /**
   * Client rejects the contractor - task goes back to searching
   */
  async rejectContractor(
    taskId: string,
    clientId: string,
    reason?: string,
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.ACCEPTED) {
      throw new BadRequestException(
        'Task must be in accepted state to reject contractor',
      );
    }

    // Reset task to created state
    const rejectedContractorId = task.contractorId;
    task.contractorId = null;
    task.status = TaskStatus.CREATED;
    task.acceptedAt = null;

    const savedTask = await this.tasksRepository.save(task);

    // Notify rejected contractor
    if (rejectedContractorId) {
      this.notificationsService
        .sendToUser(rejectedContractorId, NotificationType.TASK_CANCELLED, {
          taskTitle: task.title,
          reason: reason || 'Klient odrzucił zlecenie',
        })
        .catch((err) =>
          this.logger.error(`Failed to send rejection notification: ${err}`),
        );
    }

    // Re-notify available contractors
    this.notifyAvailableContractors(savedTask).catch((error) => {
      this.logger.error(
        `Failed to re-notify contractors for task ${savedTask.id}`,
        error,
      );
    });

    return savedTask;
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

    // Calculate final amounts (for earnings display)
    const finalAmount = task.budgetAmount;
    const commissionAmount = Number(
      (Number(finalAmount) * COMMISSION_RATE).toFixed(2),
    );

    // Status stays PENDING_COMPLETE - will change to COMPLETED when both rate
    task.finalAmount = finalAmount;
    task.commissionAmount = commissionAmount;
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
      throw new BadRequestException('Cannot cancel completed or already cancelled task');
    }

    const isContractorCancelling = task.contractorId === userId;
    const isClientCancelling = task.clientId === userId;

    if (!isClientCancelling && !isContractorCancelling) {
      throw new ForbiddenException('You cannot cancel this task');
    }

    // Store contractor ID before clearing (for notifications)
    const previousContractorId = task.contractorId;

    if (isContractorCancelling) {
      // CONTRACTOR is cancelling - return task to 'posted' status so other contractors can accept it
      this.logger.log(`Contractor ${userId} releasing task ${taskId} - returning to posted status`);

      task.status = TaskStatus.CREATED;
      task.contractorId = null;
      task.acceptedAt = null;
      task.confirmedAt = null; // Clear confirmation when contractor releases
      task.startedAt = null;
      // Don't set cancelledAt - task is not cancelled, just released

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
          reason: reason || 'Wykonawca zrezygnował ze zlecenia. Zlecenie jest ponownie dostępne.',
        })
        .catch((err) =>
          this.logger.error(
            `Failed to send task released notification: ${err}`,
          ),
        );

      return savedTask;
    } else {
      // CLIENT is cancelling - truly cancel the task
      this.logger.log(`Client ${userId} cancelling task ${taskId} in status ${task.status}`);

      task.status = TaskStatus.CANCELLED;
      task.cancelledAt = new Date();
      task.cancellationReason = reason || null;

      const savedTask = await this.tasksRepository.save(task);

      // Broadcast via WebSocket to both parties
      this.realtimeGateway.broadcastTaskStatus(
        taskId,
        TaskStatus.CANCELLED,
        userId,
        task.clientId,
      );

      // Also notify contractor directly (they might not be in the task room)
      if (previousContractorId) {
        this.realtimeGateway.sendToUser(previousContractorId, ServerEvent.TASK_STATUS, {
          taskId,
          status: TaskStatus.CANCELLED,
          updatedAt: new Date(),
          updatedBy: userId,
        });
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
}
