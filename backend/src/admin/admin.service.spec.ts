/**
 * Admin Service Unit Tests
 * Tests for admin dashboard operations and dispute resolution
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { AdminService } from './admin.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import {
  ContractorProfile,
  KycStatus,
} from '../contractor/entities/contractor-profile.entity';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
import { Rating } from '../tasks/entities/rating.entity';
import { Payment, PaymentStatus } from '../payments/entities/payment.entity';

describe('AdminService', () => {
  let service: AdminService;
  let userRepository: jest.Mocked<Repository<User>>;
  let contractorProfileRepository: jest.Mocked<Repository<ContractorProfile>>;
  let taskRepository: jest.Mocked<Repository<Task>>;
  let ratingRepository: jest.Mocked<Repository<Rating>>;
  let paymentRepository: jest.Mocked<Repository<Payment>>;

  const mockUser: User = {
    id: 'user-123',
    types: [UserType.CLIENT],
    phone: '+48111111111',
    email: 'test@example.com',
    name: 'Test User',
    address: null,
    avatarUrl: null,
    googleId: null,
    appleId: null,
    fcmToken: null,
    status: UserStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockContractor: User = {
    ...mockUser,
    id: 'contractor-123',
    types: [UserType.CONTRACTOR],
    name: 'Test Contractor',
  };

  const mockTask: Task = {
    id: 'task-123',
    clientId: 'client-123',
    contractorId: 'contractor-123',
    category: 'sprzatanie',
    title: 'Clean apartment',
    description: 'Deep cleaning needed',
    locationLat: 52.2297,
    locationLng: 21.0122,
    address: 'Warsaw, Poland',
    budgetAmount: 100,
    finalAmount: null,
    commissionAmount: null,
    tipAmount: 0,
    status: TaskStatus.DISPUTED,
    completionPhotos: null,
    scheduledAt: null,
    acceptedAt: new Date(),
    startedAt: new Date(),
    completedAt: null,
    cancelledAt: null,
    cancellationReason: null,
    createdAt: new Date(),
    client: mockUser,
    contractor: mockContractor,
  };

  const mockPayment: Payment = {
    id: 'payment-123',
    taskId: 'task-123',
    task: null as any,
    stripePaymentIntentId: 'pi_123',
    stripeTransferId: null,
    amount: 100,
    commissionAmount: 17,
    contractorAmount: 83,
    status: PaymentStatus.HELD,
    refundReason: null,
    createdAt: new Date(),
  };

  const mockContractorProfile: ContractorProfile = {
    userId: 'contractor-123',
    user: null as any,
    bio: 'Experienced cleaner',
    categories: ['sprzatanie'],
    serviceRadiusKm: 15,
    kycStatus: KycStatus.VERIFIED,
    kycIdVerified: true,
    kycSelfieVerified: true,
    kycBankVerified: true,
    stripeAccountId: 'acct_123',
    ratingAvg: 4.5,
    ratingCount: 50,
    completedTasksCount: 75,
    isOnline: true,
    lastLocationLat: 52.23,
    lastLocationLng: 21.013,
    lastLocationAt: new Date(),
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const createMockQueryBuilder = (
    getRawOneResult?: any,
    getManyResult?: any[],
    getCountResult = 0,
  ) => ({
    select: jest.fn().mockReturnThis(),
    addSelect: jest.fn().mockReturnThis(),
    innerJoin: jest.fn().mockReturnThis(),
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    groupBy: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    take: jest.fn().mockReturnThis(),
    getRawOne: jest.fn().mockResolvedValue(getRawOneResult),
    getRawMany: jest.fn().mockResolvedValue(getManyResult || []),
    getMany: jest.fn().mockResolvedValue(getManyResult || []),
    getCount: jest.fn().mockResolvedValue(getCountResult),
  });

  beforeEach(async () => {
    const mockUserRepository = {
      count: jest.fn(),
      findOne: jest.fn(),
      save: jest.fn(),
      findAndCount: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const mockContractorProfileRepository = {
      findOne: jest.fn(),
    };

    const mockTaskRepository = {
      count: jest.fn(),
      findOne: jest.fn(),
      find: jest.fn(),
      findAndCount: jest.fn(),
      save: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const mockRatingRepository = {
      find: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const mockPaymentRepository = {
      find: jest.fn(),
      findOne: jest.fn(),
      save: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AdminService,
        { provide: getRepositoryToken(User), useValue: mockUserRepository },
        {
          provide: getRepositoryToken(ContractorProfile),
          useValue: mockContractorProfileRepository,
        },
        { provide: getRepositoryToken(Task), useValue: mockTaskRepository },
        { provide: getRepositoryToken(Rating), useValue: mockRatingRepository },
        {
          provide: getRepositoryToken(Payment),
          useValue: mockPaymentRepository,
        },
      ],
    }).compile();

    service = module.get<AdminService>(AdminService);
    userRepository = module.get(getRepositoryToken(User));
    contractorProfileRepository = module.get(
      getRepositoryToken(ContractorProfile),
    );
    taskRepository = module.get(getRepositoryToken(Task));
    ratingRepository = module.get(getRepositoryToken(Rating));
    paymentRepository = module.get(getRepositoryToken(Payment));
  });

  describe('getDashboardMetrics', () => {
    beforeEach(() => {
      // Mock user counts
      userRepository.count
        .mockResolvedValueOnce(100) // total
        .mockResolvedValueOnce(70) // clients
        .mockResolvedValueOnce(30) // contractors
        .mockResolvedValueOnce(5) // new today
        .mockResolvedValueOnce(20); // new this week

      // Mock task counts
      taskRepository.count
        .mockResolvedValueOnce(500) // total
        .mockResolvedValueOnce(10) // today
        .mockResolvedValueOnce(50) // this week
        .mockResolvedValueOnce(150) // this month
        .mockResolvedValueOnce(3) // disputed total
        .mockResolvedValueOnce(3); // disputed pending

      // Mock task status breakdown
      taskRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder({ avgMinutes: '45' }, [
          { status: 'created', count: '100' },
          { status: 'in_progress', count: '50' },
          { status: 'completed', count: '300' },
        ]) as any,
      );

      // Mock payment queries for revenue
      paymentRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder({ total: '10000' }) as any,
      );
    });

    it('should return complete dashboard metrics', async () => {
      const result = await service.getDashboardMetrics();

      expect(result).toHaveProperty('users');
      expect(result).toHaveProperty('tasks');
      expect(result).toHaveProperty('revenue');
      expect(result).toHaveProperty('disputes');
    });

    it('should return correct user metrics', async () => {
      const result = await service.getDashboardMetrics();

      expect(result.users.total).toBe(100);
      expect(result.users.clients).toBe(70);
      expect(result.users.contractors).toBe(30);
      expect(result.users.newToday).toBe(5);
      expect(result.users.newThisWeek).toBe(20);
    });

    it('should return task metrics with status breakdown', async () => {
      const result = await service.getDashboardMetrics();

      expect(result.tasks.total).toBe(500);
      expect(result.tasks.today).toBe(10);
      expect(result.tasks.thisWeek).toBe(50);
      expect(result.tasks.thisMonth).toBe(150);
      expect(result.tasks.byStatus).toBeDefined();
    });

    it('should return dispute counts', async () => {
      const result = await service.getDashboardMetrics();

      expect(result.disputes.total).toBe(3);
      expect(result.disputes.pending).toBe(3);
    });
  });

  describe('getUsers', () => {
    it('should return paginated users list', async () => {
      const qb = createMockQueryBuilder(undefined, [mockUser], 1);
      userRepository.createQueryBuilder.mockReturnValue(qb as any);

      const result = await service.getUsers({ page: 1, limit: 20 });

      expect(result.data.length).toBe(1);
      expect(result.meta.total).toBe(1);
      expect(result.meta.page).toBe(1);
      expect(result.meta.limit).toBe(20);
    });

    it('should filter by user type', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      userRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getUsers({ type: UserType.CONTRACTOR });

      expect(qb.andWhere).toHaveBeenCalledWith('user.type = :type', {
        type: UserType.CONTRACTOR,
      });
    });

    it('should filter by status', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      userRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getUsers({ status: UserStatus.SUSPENDED });

      expect(qb.andWhere).toHaveBeenCalledWith('user.status = :status', {
        status: UserStatus.SUSPENDED,
      });
    });

    it('should search by name, email, or phone', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      userRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getUsers({ search: 'jan' });

      expect(qb.andWhere).toHaveBeenCalledWith(
        '(user.name ILIKE :search OR user.email ILIKE :search OR user.phone ILIKE :search)',
        { search: '%jan%' },
      );
    });

    it('should apply pagination correctly', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      userRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getUsers({ page: 3, limit: 10 });

      expect(qb.skip).toHaveBeenCalledWith(20); // (3-1) * 10
      expect(qb.take).toHaveBeenCalledWith(10);
    });
  });

  describe('getUserById', () => {
    it('should return user by ID', async () => {
      userRepository.findOne.mockResolvedValue(mockUser);

      const result = await service.getUserById('user-123');

      expect(result.id).toBe('user-123');
    });

    it('should include contractor profile for contractors', async () => {
      userRepository.findOne.mockResolvedValue(mockContractor);
      contractorProfileRepository.findOne.mockResolvedValue(
        mockContractorProfile,
      );

      const result = await service.getUserById('contractor-123');

      expect(result.contractorProfile).toBeDefined();
      expect(result.contractorProfile?.kycStatus).toBe(KycStatus.VERIFIED);
    });

    it('should throw NotFoundException when user not found', async () => {
      userRepository.findOne.mockResolvedValue(null);

      await expect(service.getUserById('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('updateUserStatus', () => {
    it('should update user status with valid transition', async () => {
      userRepository.findOne.mockResolvedValue({
        ...mockUser,
        status: UserStatus.ACTIVE,
      });
      userRepository.save.mockImplementation((user) =>
        Promise.resolve(user as User),
      );

      const result = await service.updateUserStatus(
        'user-123',
        UserStatus.SUSPENDED,
      );

      expect(result.status).toBe(UserStatus.SUSPENDED);
    });

    it('should throw NotFoundException when user not found', async () => {
      userRepository.findOne.mockResolvedValue(null);

      await expect(
        service.updateUserStatus('nonexistent', UserStatus.SUSPENDED),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException for invalid transition from ACTIVE to PENDING', async () => {
      userRepository.findOne.mockResolvedValue({
        ...mockUser,
        status: UserStatus.ACTIVE,
      });

      await expect(
        service.updateUserStatus('user-123', UserStatus.PENDING),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when trying to change BANNED status', async () => {
      userRepository.findOne.mockResolvedValue({
        ...mockUser,
        status: UserStatus.BANNED,
      });

      await expect(
        service.updateUserStatus('user-123', UserStatus.ACTIVE),
      ).rejects.toThrow(BadRequestException);
    });

    it('should allow PENDING -> ACTIVE transition', async () => {
      userRepository.findOne.mockResolvedValue({
        ...mockUser,
        status: UserStatus.PENDING,
      });
      userRepository.save.mockImplementation((user) =>
        Promise.resolve(user as User),
      );

      const result = await service.updateUserStatus(
        'user-123',
        UserStatus.ACTIVE,
      );

      expect(result.status).toBe(UserStatus.ACTIVE);
    });

    it('should allow SUSPENDED -> ACTIVE transition', async () => {
      userRepository.findOne.mockResolvedValue({
        ...mockUser,
        status: UserStatus.SUSPENDED,
      });
      userRepository.save.mockImplementation((user) =>
        Promise.resolve(user as User),
      );

      const result = await service.updateUserStatus(
        'user-123',
        UserStatus.ACTIVE,
      );

      expect(result.status).toBe(UserStatus.ACTIVE);
    });
  });

  describe('getDisputes', () => {
    it('should return paginated disputed tasks', async () => {
      taskRepository.findAndCount.mockResolvedValue([[mockTask], 1]);

      const result = await service.getDisputes(1, 20);

      expect(result.data.length).toBe(1);
      expect(result.meta.total).toBe(1);
      expect(taskRepository.findAndCount).toHaveBeenCalledWith({
        where: { status: TaskStatus.DISPUTED },
        relations: ['client', 'contractor'],
        order: { createdAt: 'DESC' },
        skip: 0,
        take: 20,
      });
    });

    it('should handle empty disputes list', async () => {
      taskRepository.findAndCount.mockResolvedValue([[], 0]);

      const result = await service.getDisputes();

      expect(result.data.length).toBe(0);
      expect(result.meta.total).toBe(0);
    });
  });

  describe('getDisputeById', () => {
    it('should return dispute details with payments and ratings', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      paymentRepository.find.mockResolvedValue([mockPayment]);
      ratingRepository.find.mockResolvedValue([]);

      const result = await service.getDisputeById('task-123');

      expect(result.task).toBeDefined();
      expect(result.payments).toBeDefined();
      expect(result.ratings).toBeDefined();
    });

    it('should throw NotFoundException when task not found', async () => {
      taskRepository.findOne.mockResolvedValue(null);

      await expect(service.getDisputeById('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw BadRequestException when task is not disputed', async () => {
      taskRepository.findOne.mockResolvedValue({
        ...mockTask,
        status: TaskStatus.COMPLETED,
      });

      await expect(service.getDisputeById('task-123')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('resolveDispute', () => {
    beforeEach(() => {
      taskRepository.findOne.mockResolvedValue({ ...mockTask });
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.HELD,
      });
      taskRepository.save.mockImplementation((task) =>
        Promise.resolve(task as Task),
      );
      paymentRepository.save.mockImplementation((payment) =>
        Promise.resolve(payment as Payment),
      );
    });

    it('should resolve dispute with refund', async () => {
      const result = await service.resolveDispute(
        'task-123',
        'refund',
        'Customer was right',
      );

      expect(result.status).toBe(TaskStatus.CANCELLED);
      expect(paymentRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: PaymentStatus.REFUNDED }),
      );
    });

    it('should resolve dispute by paying contractor', async () => {
      const result = await service.resolveDispute(
        'task-123',
        'pay_contractor',
        'Work was completed',
      );

      expect(result.status).toBe(TaskStatus.COMPLETED);
      expect(paymentRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ status: PaymentStatus.CAPTURED }),
      );
    });

    it('should resolve dispute with 50/50 split', async () => {
      const result = await service.resolveDispute(
        'task-123',
        'split',
        'Both parties share responsibility',
      );

      expect(result.status).toBe(TaskStatus.COMPLETED);
      expect(result.cancellationReason).toContain('50/50 split');
    });

    it('should throw NotFoundException when task not found', async () => {
      taskRepository.findOne.mockResolvedValue(null);

      await expect(
        service.resolveDispute('nonexistent', 'refund', 'notes'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException when task is not disputed', async () => {
      taskRepository.findOne.mockResolvedValue({
        ...mockTask,
        status: TaskStatus.COMPLETED,
      });

      await expect(
        service.resolveDispute('task-123', 'refund', 'notes'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for invalid resolution type', async () => {
      await expect(
        service.resolveDispute('task-123', 'invalid' as any, 'notes'),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('getTasks', () => {
    it('should return paginated tasks with filters', async () => {
      const qb = createMockQueryBuilder(undefined, [mockTask], 1);
      taskRepository.createQueryBuilder.mockReturnValue(qb as any);

      const result = await service.getTasks({
        status: TaskStatus.IN_PROGRESS,
        page: 1,
        limit: 20,
      });

      expect(result.data.length).toBe(1);
      expect(qb.andWhere).toHaveBeenCalledWith('task.status = :status', {
        status: TaskStatus.IN_PROGRESS,
      });
    });

    it('should filter by category', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      taskRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getTasks({ category: 'sprzatanie' });

      expect(qb.andWhere).toHaveBeenCalledWith('task.category = :category', {
        category: 'sprzatanie',
      });
    });

    it('should filter by clientId', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      taskRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getTasks({ clientId: 'client-123' });

      expect(qb.andWhere).toHaveBeenCalledWith('task.clientId = :clientId', {
        clientId: 'client-123',
      });
    });

    it('should filter by contractorId', async () => {
      const qb = createMockQueryBuilder(undefined, [], 0);
      taskRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getTasks({ contractorId: 'contractor-123' });

      expect(qb.andWhere).toHaveBeenCalledWith(
        'task.contractorId = :contractorId',
        { contractorId: 'contractor-123' },
      );
    });
  });

  describe('getContractorStats', () => {
    it('should return contractor statistics', async () => {
      contractorProfileRepository.findOne.mockResolvedValue(
        mockContractorProfile,
      );
      taskRepository.count.mockResolvedValue(50);
      taskRepository.find.mockResolvedValue([mockTask]);

      const paymentQb = createMockQueryBuilder({ total: '5000' });
      paymentRepository.createQueryBuilder.mockReturnValue(paymentQb as any);

      const ratingQb = createMockQueryBuilder({ avg: '4.5' });
      ratingRepository.createQueryBuilder.mockReturnValue(ratingQb as any);

      const result = await service.getContractorStats('contractor-123');

      expect(result).toHaveProperty('profile');
      expect(result).toHaveProperty('completedTasks');
      expect(result).toHaveProperty('earnings');
      expect(result).toHaveProperty('averageRating');
      expect(result).toHaveProperty('recentTasks');
    });

    it('should handle contractor with no completed tasks', async () => {
      contractorProfileRepository.findOne.mockResolvedValue(
        mockContractorProfile,
      );
      taskRepository.count.mockResolvedValue(0);
      taskRepository.find.mockResolvedValue([]);

      const paymentQb = createMockQueryBuilder({ total: null });
      paymentRepository.createQueryBuilder.mockReturnValue(paymentQb as any);

      const ratingQb = createMockQueryBuilder({ avg: null });
      ratingRepository.createQueryBuilder.mockReturnValue(ratingQb as any);

      const result = await service.getContractorStats('contractor-123');

      expect(result.completedTasks).toBe(0);
      expect(result.earnings).toBe(0);
      expect(result.averageRating).toBe(0);
    });
  });
});
