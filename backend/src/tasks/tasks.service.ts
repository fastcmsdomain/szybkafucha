/**
 * Tasks Service
 * Business logic for task operations and lifecycle management
 */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task, TaskStatus } from './entities/task.entity';
import { Rating } from './entities/rating.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';

// Platform commission percentage
const COMMISSION_RATE = 0.17;

@Injectable()
export class TasksService {
  constructor(
    @InjectRepository(Task)
    private readonly tasksRepository: Repository<Task>,
    @InjectRepository(Rating)
    private readonly ratingsRepository: Repository<Rating>,
  ) {}

  /**
   * Create a new task
   */
  async create(clientId: string, dto: CreateTaskDto): Promise<Task> {
    const task = this.tasksRepository.create({
      ...dto,
      clientId,
      scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : null,
    });

    return this.tasksRepository.save(task);
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
  private calculateDistance(
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
}
