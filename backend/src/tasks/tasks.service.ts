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
import { ContractorProfile, KycStatus } from '../contractor/entities/contractor-profile.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
import { RealtimeGateway } from '../realtime/realtime.gateway';

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
      this.logger.error(`Failed to notify contractors for task ${savedTask.id}`, error);
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
   */
  async acceptTask(taskId: string, contractorId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.status !== TaskStatus.CREATED) {
      throw new BadRequestException('Task is no longer available');
    }

    task.contractorId = contractorId;
    task.status = TaskStatus.ACCEPTED;
    task.acceptedAt = new Date();

    return this.tasksRepository.save(task);
  }

  /**
   * Contractor starts the task
   */
  async startTask(taskId: string, contractorId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.contractorId !== contractorId) {
      throw new ForbiddenException('You are not assigned to this task');
    }

    if (task.status !== TaskStatus.ACCEPTED) {
      throw new BadRequestException('Task must be accepted before starting');
    }

    task.status = TaskStatus.IN_PROGRESS;
    task.startedAt = new Date();

    return this.tasksRepository.save(task);
  }

  /**
   * Contractor marks task as complete
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

    if (task.status !== TaskStatus.IN_PROGRESS) {
      throw new BadRequestException('Task must be in progress to complete');
    }

    // Calculate final amounts
    const finalAmount = task.budgetAmount;
    const commissionAmount = Number((Number(finalAmount) * COMMISSION_RATE).toFixed(2));

    task.status = TaskStatus.COMPLETED;
    task.completedAt = new Date();
    task.finalAmount = finalAmount;
    task.commissionAmount = commissionAmount;
    task.completionPhotos = completionPhotos || null;

    return this.tasksRepository.save(task);
  }

  /**
   * Client confirms task completion (triggers payment)
   */
  async confirmTask(taskId: string, clientId: string): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.COMPLETED) {
      throw new BadRequestException('Task must be completed first');
    }

    // Task is confirmed - payment will be released
    // Payment logic handled by PaymentsService
    return task;
  }

  /**
   * Cancel a task
   */
  async cancelTask(
    taskId: string,
    userId: string,
    reason?: string,
  ): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    // Only client can cancel before acceptance
    if (task.clientId === userId) {
      if (task.status !== TaskStatus.CREATED) {
        throw new BadRequestException(
          'Cannot cancel task after contractor accepted. Contact support.',
        );
      }
    } else if (task.contractorId === userId) {
      // Contractor can cancel accepted task
      if (task.status === TaskStatus.COMPLETED) {
        throw new BadRequestException('Cannot cancel completed task');
      }
    } else {
      throw new ForbiddenException('You cannot cancel this task');
    }

    task.status = TaskStatus.CANCELLED;
    task.cancelledAt = new Date();
    task.cancellationReason = reason || null;

    return this.tasksRepository.save(task);
  }

  /**
   * Rate a completed task
   */
  async rateTask(
    taskId: string,
    fromUserId: string,
    toUserId: string,
    dto: RateTaskDto,
  ): Promise<Rating> {
    const task = await this.findByIdOrFail(taskId);

    if (task.status !== TaskStatus.COMPLETED) {
      throw new BadRequestException('Can only rate completed tasks');
    }

    // Check if already rated
    const existingRating = await this.ratingsRepository.findOne({
      where: { taskId, fromUserId },
    });

    if (existingRating) {
      throw new BadRequestException('You have already rated this task');
    }

    const rating = this.ratingsRepository.create({
      taskId,
      fromUserId,
      toUserId,
      rating: dto.rating,
      comment: dto.comment,
    });

    return this.ratingsRepository.save(rating);
  }

  /**
   * Add tip to a task
   */
  async addTip(taskId: string, clientId: string, tipAmount: number): Promise<Task> {
    const task = await this.findByIdOrFail(taskId);

    if (task.clientId !== clientId) {
      throw new ForbiddenException('You are not the owner of this task');
    }

    if (task.status !== TaskStatus.COMPLETED) {
      throw new BadRequestException('Can only tip completed tasks');
    }

    task.tipAmount = tipAmount;
    return this.tasksRepository.save(task);
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
    // Find all verified, online contractors with matching category
    const contractors = await this.contractorProfileRepository.find({
      where: {
        isOnline: true,
        kycStatus: KycStatus.VERIFIED,
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

    // Send to each contractor via WebSocket
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

      if (sent) {
        this.logger.debug(
          `Notified contractor ${ranked.contractorId} (score: ${ranked.score}, distance: ${ranked.distance}km)`,
        );
      }
    }
  }
}
