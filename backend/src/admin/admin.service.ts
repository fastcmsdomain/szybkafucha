/**
 * Admin Service
 * Business logic for admin dashboard operations
 */
import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan, Raw } from 'typeorm';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
import { Rating } from '../tasks/entities/rating.entity';
import { Payment, PaymentStatus } from '../payments/entities/payment.entity';
import {
  DashboardMetrics,
  PaginatedResponse,
  UserWithProfile,
  DisputeDetails,
  ContractorStats,
  DisputeResolution,
} from './dto/admin.dto';

// User filters interface
export interface UserFilters {
  type?: UserType;
  status?: UserStatus;
  search?: string;
  page?: number;
  limit?: number;
}

@Injectable()
export class AdminService {
  private readonly logger = new Logger(AdminService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
  ) {}

  /**
   * Get dashboard metrics
   */
  async getDashboardMetrics(): Promise<DashboardMetrics> {
    const now = new Date();
    const startOfDay = new Date(now.setHours(0, 0, 0, 0));
    const startOfWeek = new Date(now);
    startOfWeek.setDate(startOfWeek.getDate() - 7);
    const startOfMonth = new Date(now);
    startOfMonth.setDate(1);

    // User metrics
    const [totalUsers, clients, contractors, newToday, newThisWeek] =
      await Promise.all([
        this.userRepository.count(),
        this.userRepository.count({
          where: { types: Raw((alias) => `${alias} LIKE '%client%'`) },
        }),
        this.userRepository.count({
          where: { types: Raw((alias) => `${alias} LIKE '%contractor%'`) },
        }),
        this.userRepository.count({
          where: { createdAt: MoreThan(startOfDay) },
        }),
        this.userRepository.count({
          where: { createdAt: MoreThan(startOfWeek) },
        }),
      ]);

    // Task metrics
    const [totalTasks, tasksToday, tasksThisWeek, tasksThisMonth] =
      await Promise.all([
        this.taskRepository.count(),
        this.taskRepository.count({
          where: { createdAt: MoreThan(startOfDay) },
        }),
        this.taskRepository.count({
          where: { createdAt: MoreThan(startOfWeek) },
        }),
        this.taskRepository.count({
          where: { createdAt: MoreThan(startOfMonth) },
        }),
      ]);

    // Tasks by status
    const tasksByStatus = await this.taskRepository
      .createQueryBuilder('task')
      .select('task.status', 'status')
      .addSelect('COUNT(*)', 'count')
      .groupBy('task.status')
      .getRawMany<{ status: TaskStatus; count: string }>();

    const byStatus: Partial<Record<TaskStatus, number>> = {};
    for (const { status, count } of tasksByStatus) {
      byStatus[status] = parseInt(count, 10);
    }

    // Average completion time
    const completedTasks = await this.taskRepository
      .createQueryBuilder('task')
      .select(
        'AVG(EXTRACT(EPOCH FROM (task.completedAt - task.startedAt)) / 60)',
        'avgMinutes',
      )
      .where('task.status = :status', { status: TaskStatus.COMPLETED })
      .andWhere('task.completedAt IS NOT NULL')
      .andWhere('task.startedAt IS NOT NULL')
      .getRawOne<{ avgMinutes: string | null }>();

    const avgMinutes = completedTasks?.avgMinutes ?? null;
    const averageCompletionTimeMinutes = avgMinutes
      ? Math.round(parseFloat(avgMinutes))
      : null;

    // Revenue metrics (from captured payments)
    const [gmvTotal, gmvToday, gmvThisWeek, gmvThisMonth] = await Promise.all([
      this.calculateGmv(),
      this.calculateGmv(startOfDay),
      this.calculateGmv(startOfWeek),
      this.calculateGmv(startOfMonth),
    ]);

    const [revenueTotal, revenueToday, revenueThisWeek, revenueThisMonth] =
      await Promise.all([
        this.calculateRevenue(),
        this.calculateRevenue(startOfDay),
        this.calculateRevenue(startOfWeek),
        this.calculateRevenue(startOfMonth),
      ]);

    // Disputes
    const [totalDisputes, pendingDisputes] = await Promise.all([
      this.taskRepository.count({ where: { status: TaskStatus.DISPUTED } }),
      this.taskRepository.count({ where: { status: TaskStatus.DISPUTED } }),
    ]);

    return {
      users: {
        total: totalUsers,
        clients,
        contractors,
        newToday,
        newThisWeek,
      },
      tasks: {
        total: totalTasks,
        today: tasksToday,
        thisWeek: tasksThisWeek,
        thisMonth: tasksThisMonth,
        byStatus,
        averageCompletionTimeMinutes,
      },
      revenue: {
        totalGmv: gmvTotal,
        totalRevenue: revenueTotal,
        gmvToday,
        revenueToday,
        gmvThisWeek,
        revenueThisWeek,
        gmvThisMonth,
        revenueThisMonth,
      },
      disputes: {
        total: totalDisputes,
        pending: pendingDisputes,
      },
    };
  }

  /**
   * Calculate total GMV (Gross Merchandise Value)
   */
  private async calculateGmv(since?: Date): Promise<number> {
    const query = this.paymentRepository
      .createQueryBuilder('payment')
      .select('SUM(payment.amount)', 'total')
      .where('payment.status = :status', { status: PaymentStatus.CAPTURED });

    if (since) {
      query.andWhere('payment.createdAt >= :since', { since });
    }

    const result = await query.getRawOne<{ total: string | null }>();
    const total = result?.total ?? '0';
    return parseFloat(total);
  }

  /**
   * Calculate platform revenue (commissions)
   */
  private async calculateRevenue(since?: Date): Promise<number> {
    const query = this.paymentRepository
      .createQueryBuilder('payment')
      .select('SUM(payment.commissionAmount)', 'total')
      .where('payment.status = :status', { status: PaymentStatus.CAPTURED });

    if (since) {
      query.andWhere('payment.createdAt >= :since', { since });
    }

    const result = await query.getRawOne<{ total: string | null }>();
    const total = result?.total ?? '0';
    return parseFloat(total);
  }

  /**
   * Get paginated users list with filters
   */
  async getUsers(filters: UserFilters): Promise<PaginatedResponse<User>> {
    const { type, status, search, page = 1, limit = 20 } = filters;

    const queryBuilder = this.userRepository.createQueryBuilder('user');

    // Apply filters
    if (type) {
      queryBuilder.andWhere('user.type = :type', { type });
    }

    if (status) {
      queryBuilder.andWhere('user.status = :status', { status });
    }

    if (search) {
      queryBuilder.andWhere(
        '(user.name ILIKE :search OR user.email ILIKE :search OR user.phone ILIKE :search)',
        { search: `%${search}%` },
      );
    }

    // Get total count
    const total = await queryBuilder.getCount();

    // Apply pagination
    const offset = (page - 1) * limit;
    queryBuilder.skip(offset).take(limit);

    // Order by newest first
    queryBuilder.orderBy('user.createdAt', 'DESC');

    const data = await queryBuilder.getMany();

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get user by ID with contractor profile if applicable
   */
  async getUserById(userId: string): Promise<UserWithProfile> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // If contractor, include profile
    if (user.types.includes(UserType.CONTRACTOR)) {
      const profile = await this.contractorProfileRepository.findOne({
        where: { userId },
      });
      return { ...user, contractorProfile: profile || undefined };
    }

    return user;
  }

  /**
   * Update user status
   */
  async updateUserStatus(userId: string, newStatus: UserStatus): Promise<User> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Validate status transition
    const allowedTransitions: Record<UserStatus, UserStatus[]> = {
      [UserStatus.PENDING]: [UserStatus.ACTIVE, UserStatus.SUSPENDED],
      [UserStatus.ACTIVE]: [UserStatus.SUSPENDED, UserStatus.BANNED],
      [UserStatus.SUSPENDED]: [UserStatus.ACTIVE, UserStatus.BANNED],
      [UserStatus.BANNED]: [], // No transitions allowed
    };

    if (!allowedTransitions[user.status].includes(newStatus)) {
      throw new BadRequestException(
        `Cannot transition from ${user.status} to ${newStatus}`,
      );
    }

    user.status = newStatus;
    return this.userRepository.save(user);
  }

  /**
   * Get disputed tasks
   */
  async getDisputes(page = 1, limit = 20): Promise<PaginatedResponse<Task>> {
    const [data, total] = await this.taskRepository.findAndCount({
      where: { status: TaskStatus.DISPUTED },
      relations: ['client', 'contractor'],
      order: { createdAt: 'DESC' },
      skip: (page - 1) * limit,
      take: limit,
    });

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get single dispute details
   */
  async getDisputeById(taskId: string): Promise<DisputeDetails> {
    const task = await this.taskRepository.findOne({
      where: { id: taskId },
      relations: ['client', 'contractor'],
    });

    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (task.status !== TaskStatus.DISPUTED) {
      throw new BadRequestException('Task is not in disputed status');
    }

    const [payments, ratings] = await Promise.all([
      this.paymentRepository.find({ where: { taskId } }),
      this.ratingRepository.find({ where: { taskId } }),
    ]);

    return { task, payments, ratings };
  }

  /**
   * Resolve dispute
   */
  async resolveDispute(
    taskId: string,
    resolution: DisputeResolution,
    adminNotes: string,
  ): Promise<Task> {
    const task = await this.taskRepository.findOne({
      where: { id: taskId },
      relations: ['client', 'contractor'],
    });

    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (task.status !== TaskStatus.DISPUTED) {
      throw new BadRequestException('Task is not in disputed status');
    }

    // Get associated payment
    const payment = await this.paymentRepository.findOne({
      where: { taskId },
      order: { createdAt: 'DESC' },
    });

    // Handle resolution based on type
    switch (resolution) {
      case 'refund':
        // Full refund to client
        task.status = TaskStatus.CANCELLED;
        task.cancellationReason = `Dispute resolved: Full refund to client. Admin notes: ${adminNotes}`;
        if (payment && payment.status === PaymentStatus.HELD) {
          payment.status = PaymentStatus.REFUNDED;
          payment.refundReason = 'Dispute resolved in favor of client';
          await this.paymentRepository.save(payment);
        }
        break;

      case 'pay_contractor':
        // Pay contractor as normal
        task.status = TaskStatus.COMPLETED;
        if (payment && payment.status === PaymentStatus.HELD) {
          payment.status = PaymentStatus.CAPTURED;
          await this.paymentRepository.save(payment);
        }
        break;

      case 'split':
        // 50/50 split - partial refund
        task.status = TaskStatus.COMPLETED;
        task.cancellationReason = `Dispute resolved: 50/50 split. Admin notes: ${adminNotes}`;
        // In production, would create partial refund here
        break;

      default:
        throw new BadRequestException('Invalid resolution type');
    }

    this.logger.log(`Dispute ${taskId} resolved: ${resolution} by admin`);
    return this.taskRepository.save(task);
  }

  /**
   * Get paginated tasks with filters
   */
  async getTasks(filters: {
    status?: TaskStatus;
    category?: string;
    clientId?: string;
    contractorId?: string;
    page?: number;
    limit?: number;
  }): Promise<PaginatedResponse<Task>> {
    const {
      status,
      category,
      clientId,
      contractorId,
      page = 1,
      limit = 20,
    } = filters;

    const queryBuilder = this.taskRepository
      .createQueryBuilder('task')
      .leftJoinAndSelect('task.client', 'client')
      .leftJoinAndSelect('task.contractor', 'contractor');

    if (status) {
      queryBuilder.andWhere('task.status = :status', { status });
    }

    if (category) {
      queryBuilder.andWhere('task.category = :category', { category });
    }

    if (clientId) {
      queryBuilder.andWhere('task.clientId = :clientId', { clientId });
    }

    if (contractorId) {
      queryBuilder.andWhere('task.contractorId = :contractorId', {
        contractorId,
      });
    }

    const total = await queryBuilder.getCount();

    queryBuilder
      .skip((page - 1) * limit)
      .take(limit)
      .orderBy('task.createdAt', 'DESC');

    const data = await queryBuilder.getMany();

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Get contractor stats
   */
  async getContractorStats(contractorId: string): Promise<ContractorStats> {
    const profile = await this.contractorProfileRepository.findOne({
      where: { userId: contractorId },
    });

    const [completedTasks, earnings, avgRating, recentTasks] =
      await Promise.all([
        this.taskRepository.count({
          where: { contractorId, status: TaskStatus.COMPLETED },
        }),
        this.calculateContractorEarnings(contractorId),
        this.calculateAverageRating(contractorId),
        this.taskRepository.find({
          where: { contractorId },
          order: { createdAt: 'DESC' },
          take: 5,
        }),
      ]);

    return {
      profile,
      completedTasks,
      earnings,
      averageRating: avgRating,
      recentTasks,
    };
  }

  private async calculateContractorEarnings(
    contractorId: string,
  ): Promise<number> {
    const result = await this.paymentRepository
      .createQueryBuilder('payment')
      .innerJoin('payment.task', 'task')
      .select('SUM(payment.contractorAmount)', 'total')
      .where('task.contractorId = :contractorId', { contractorId })
      .andWhere('payment.status = :status', { status: PaymentStatus.CAPTURED })
      .getRawOne<{ total: string | null }>();

    const total = result?.total ?? '0';
    return parseFloat(total);
  }

  private async calculateAverageRating(contractorId: string): Promise<number> {
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'avg')
      .where('rating.toUserId = :contractorId', { contractorId })
      .getRawOne<{ avg: string | null }>();

    const avg = result?.avg ?? '0';
    return parseFloat(avg);
  }
}
