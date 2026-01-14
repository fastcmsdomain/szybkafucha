/**
 * Payments Service Unit Tests
 * Tests for Stripe payment processing and escrow flow
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import {
  BadRequestException,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { Payment, PaymentStatus } from './entities/payment.entity';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
import {
  ContractorProfile,
  KycStatus,
} from '../contractor/entities/contractor-profile.entity';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';

describe('PaymentsService', () => {
  let service: PaymentsService;
  let paymentRepository: jest.Mocked<Repository<Payment>>;
  let taskRepository: jest.Mocked<Repository<Task>>;
  let contractorProfileRepository: jest.Mocked<Repository<ContractorProfile>>;
  let userRepository: jest.Mocked<Repository<User>>;

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
    status: TaskStatus.ACCEPTED,
    completionPhotos: null,
    scheduledAt: null,
    acceptedAt: new Date(),
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
    cancellationReason: null,
    createdAt: new Date(),
    client: null as any,
    contractor: null as any,
  };

  const mockPayment: Payment = {
    id: 'payment-123',
    taskId: 'task-123',
    task: null as any,
    stripePaymentIntentId: 'pi_mock_123',
    stripeTransferId: null,
    amount: 100,
    commissionAmount: 17,
    contractorAmount: 83,
    status: PaymentStatus.PENDING,
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
    stripeAccountId: 'acct_mock_123',
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

  beforeEach(async () => {
    const mockPaymentRepository = {
      create: jest.fn(),
      save: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      createQueryBuilder: jest.fn(() => ({
        innerJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getMany: jest.fn(),
        getRawOne: jest.fn(),
      })),
    };

    const mockTaskRepository = {
      findOne: jest.fn(),
    };

    const mockContractorProfileRepository = {
      findOne: jest.fn(),
      update: jest.fn(),
    };

    const mockUserRepository = {
      findOne: jest.fn(),
    };

    const mockConfigService = {
      get: jest.fn().mockImplementation((key: string, defaultValue?: any) => {
        if (key === 'STRIPE_SECRET_KEY') return null; // Mock mode
        if (key === 'STRIPE_PLATFORM_FEE_PERCENT') return 17;
        return defaultValue;
      }),
    };

    const mockNotificationsService = {
      sendToUser: jest.fn().mockResolvedValue({ success: true }),
      sendToUsers: jest
        .fn()
        .mockResolvedValue({ successCount: 1, failureCount: 0, results: [] }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        PaymentsService,
        {
          provide: getRepositoryToken(Payment),
          useValue: mockPaymentRepository,
        },
        { provide: getRepositoryToken(Task), useValue: mockTaskRepository },
        {
          provide: getRepositoryToken(ContractorProfile),
          useValue: mockContractorProfileRepository,
        },
        { provide: getRepositoryToken(User), useValue: mockUserRepository },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<PaymentsService>(PaymentsService);
    paymentRepository = module.get(getRepositoryToken(Payment));
    taskRepository = module.get(getRepositoryToken(Task));
    contractorProfileRepository = module.get(
      getRepositoryToken(ContractorProfile),
    );
    userRepository = module.get(getRepositoryToken(User));
  });

  describe('createConnectAccount', () => {
    it('should create mock Stripe account in development mode', async () => {
      contractorProfileRepository.findOne.mockResolvedValue({
        ...mockContractorProfile,
        stripeAccountId: null,
      });
      contractorProfileRepository.update.mockResolvedValue(undefined as any);

      const result = await service.createConnectAccount(
        'contractor-123',
        'contractor@test.pl',
      );

      expect(result.accountId).toContain('acct_mock_');
      expect(result.onboardingUrl).toContain('mock-stripe-onboarding');
    });

    it('should return existing onboarding link if account already exists', async () => {
      contractorProfileRepository.findOne.mockResolvedValue(
        mockContractorProfile,
      );

      const result = await service.createConnectAccount(
        'contractor-123',
        'contractor@test.pl',
      );

      expect(result.accountId).toBe('acct_mock_123');
      expect(contractorProfileRepository.update).not.toHaveBeenCalled();
    });

    it('should throw NotFoundException when contractor profile not found', async () => {
      contractorProfileRepository.findOne.mockResolvedValue(null);

      await expect(
        service.createConnectAccount('nonexistent-123', 'test@test.pl'),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('getAccountStatus', () => {
    it('should return hasAccount false when no Stripe account', async () => {
      contractorProfileRepository.findOne.mockResolvedValue({
        ...mockContractorProfile,
        stripeAccountId: null,
      });

      const result = await service.getAccountStatus('contractor-123');

      expect(result.hasAccount).toBe(false);
      expect(result.accountId).toBeNull();
    });

    it('should return full status in mock mode', async () => {
      contractorProfileRepository.findOne.mockResolvedValue(
        mockContractorProfile,
      );

      const result = await service.getAccountStatus('contractor-123');

      expect(result.hasAccount).toBe(true);
      expect(result.accountId).toBe('acct_mock_123');
      expect(result.payoutsEnabled).toBe(true);
      expect(result.chargesEnabled).toBe(true);
      expect(result.detailsSubmitted).toBe(true);
    });
  });

  describe('createPaymentIntent', () => {
    it('should create payment intent for accepted task', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      paymentRepository.findOne.mockResolvedValue(null); // No existing payment
      paymentRepository.create.mockReturnValue(mockPayment);
      paymentRepository.save.mockResolvedValue(mockPayment);

      const result = await service.createPaymentIntent(
        'task-123',
        'client-123',
      );

      expect(result.clientSecret).toContain('mock_secret_');
      expect(result.paymentId).toBe(mockPayment.id);
      expect(paymentRepository.create).toHaveBeenCalled();
    });

    it('should throw NotFoundException when task not found', async () => {
      taskRepository.findOne.mockResolvedValue(null);

      await expect(
        service.createPaymentIntent('nonexistent-task', 'client-123'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should throw BadRequestException when not task owner', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);

      await expect(
        service.createPaymentIntent('task-123', 'wrong-client'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when task not accepted', async () => {
      taskRepository.findOne.mockResolvedValue({
        ...mockTask,
        status: TaskStatus.CREATED,
      });

      await expect(
        service.createPaymentIntent('task-123', 'client-123'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when payment already exists', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      paymentRepository.findOne.mockResolvedValue(mockPayment);

      await expect(
        service.createPaymentIntent('task-123', 'client-123'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should calculate commission correctly (17%)', async () => {
      taskRepository.findOne.mockResolvedValue({
        ...mockTask,
        budgetAmount: 200,
      });
      paymentRepository.findOne.mockResolvedValue(null);
      paymentRepository.create.mockImplementation((data) => ({
        ...mockPayment,
        ...data,
      }));
      paymentRepository.save.mockImplementation((payment) =>
        Promise.resolve(payment as Payment),
      );

      await service.createPaymentIntent('task-123', 'client-123');

      expect(paymentRepository.create).toHaveBeenCalledWith(
        expect.objectContaining({
          amount: 200,
          commissionAmount: 34, // 17% of 200
          contractorAmount: 166, // 83% of 200
        }),
      );
    });
  });

  describe('confirmPaymentHold', () => {
    it('should update payment status to HELD', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.PENDING,
      });
      paymentRepository.save.mockImplementation((payment) =>
        Promise.resolve(payment as Payment),
      );

      const result = await service.confirmPaymentHold('payment-123');

      expect(result.status).toBe(PaymentStatus.HELD);
    });

    it('should throw NotFoundException when payment not found', async () => {
      paymentRepository.findOne.mockResolvedValue(null);

      await expect(service.confirmPaymentHold('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw BadRequestException when payment not pending', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.HELD,
      });

      await expect(service.confirmPaymentHold('payment-123')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('capturePayment', () => {
    it('should capture held payment and mark as captured', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.HELD,
      });
      paymentRepository.save.mockImplementation((payment) =>
        Promise.resolve(payment as Payment),
      );

      const result = await service.capturePayment('task-123');

      expect(result.status).toBe(PaymentStatus.CAPTURED);
      expect(result.stripeTransferId).toContain('tr_mock_');
    });

    it('should throw NotFoundException when no held payment exists', async () => {
      paymentRepository.findOne.mockResolvedValue(null);

      await expect(service.capturePayment('task-123')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('refundPayment', () => {
    it('should refund held payment', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.HELD,
      });
      paymentRepository.save.mockImplementation((payment) =>
        Promise.resolve(payment as Payment),
      );

      const result = await service.refundPayment(
        'task-123',
        'Customer requested',
      );

      expect(result.status).toBe(PaymentStatus.REFUNDED);
      expect(result.refundReason).toBe('Customer requested');
    });

    it('should refund captured payment', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.CAPTURED,
      });
      paymentRepository.save.mockImplementation((payment) =>
        Promise.resolve(payment as Payment),
      );

      const result = await service.refundPayment(
        'task-123',
        'Dispute resolved',
      );

      expect(result.status).toBe(PaymentStatus.REFUNDED);
    });

    it('should throw NotFoundException when no payment exists', async () => {
      paymentRepository.findOne.mockResolvedValue(null);

      await expect(service.refundPayment('task-123', 'reason')).rejects.toThrow(
        NotFoundException,
      );
    });

    it('should throw BadRequestException when payment already refunded', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.REFUNDED,
      });

      await expect(service.refundPayment('task-123', 'reason')).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw BadRequestException for pending payment', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        status: PaymentStatus.PENDING,
      });

      await expect(service.refundPayment('task-123', 'reason')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('getContractorEarnings', () => {
    it('should return earnings summary', async () => {
      const mockQueryBuilder = {
        innerJoin: jest.fn().mockReturnThis(),
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        orderBy: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([
          {
            ...mockPayment,
            contractorAmount: 83,
            status: PaymentStatus.CAPTURED,
          },
          {
            ...mockPayment,
            id: 'payment-2',
            contractorAmount: 166,
            status: PaymentStatus.CAPTURED,
          },
        ]),
      };
      paymentRepository.createQueryBuilder.mockReturnValue(
        mockQueryBuilder as any,
      );

      const result = await service.getContractorEarnings('contractor-123');

      expect(result).toHaveProperty('totalEarnings');
      expect(result).toHaveProperty('pendingEarnings');
      expect(result).toHaveProperty('availableBalance');
      expect(result).toHaveProperty('completedTasks');
      expect(result).toHaveProperty('recentPayments');
    });
  });

  describe('requestPayout', () => {
    it('should create payout request in mock mode', async () => {
      contractorProfileRepository.findOne.mockResolvedValue(
        mockContractorProfile,
      );

      const result = await service.requestPayout('contractor-123', 100);

      expect(result.payoutId).toContain('po_mock_');
      expect(result.status).toBe('pending');
    });

    it('should throw BadRequestException when no Stripe account', async () => {
      contractorProfileRepository.findOne.mockResolvedValue({
        ...mockContractorProfile,
        stripeAccountId: null,
      });

      await expect(
        service.requestPayout('contractor-123', 100),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('findById', () => {
    it('should return payment with task relation', async () => {
      paymentRepository.findOne.mockResolvedValue({
        ...mockPayment,
        task: mockTask,
      });

      const result = await service.findById('payment-123');

      expect(result.id).toBe('payment-123');
      expect(paymentRepository.findOne).toHaveBeenCalledWith({
        where: { id: 'payment-123' },
        relations: ['task'],
      });
    });

    it('should throw NotFoundException when payment not found', async () => {
      paymentRepository.findOne.mockResolvedValue(null);

      await expect(service.findById('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('findByTaskId', () => {
    it('should return payments ordered by creation date', async () => {
      const payments = [mockPayment, { ...mockPayment, id: 'payment-2' }];
      paymentRepository.find.mockResolvedValue(payments);

      const result = await service.findByTaskId('task-123');

      expect(result.length).toBe(2);
      expect(paymentRepository.find).toHaveBeenCalledWith({
        where: { taskId: 'task-123' },
        order: { createdAt: 'DESC' },
      });
    });
  });

  describe('payment flow integration', () => {
    it('should follow correct escrow flow: PENDING -> HELD -> CAPTURED', async () => {
      // Step 1: Create payment intent
      taskRepository.findOne.mockResolvedValue(mockTask);
      paymentRepository.findOne.mockResolvedValueOnce(null); // No existing payment

      const createdPayment = { ...mockPayment, status: PaymentStatus.PENDING };
      paymentRepository.create.mockReturnValue(createdPayment);
      paymentRepository.save.mockResolvedValueOnce(createdPayment);

      await service.createPaymentIntent('task-123', 'client-123');

      // Step 2: Confirm payment hold
      paymentRepository.findOne.mockResolvedValueOnce(createdPayment);
      paymentRepository.save.mockImplementation((p) =>
        Promise.resolve({ ...p, status: PaymentStatus.HELD } as Payment),
      );

      const heldPayment = await service.confirmPaymentHold('payment-123');
      expect(heldPayment.status).toBe(PaymentStatus.HELD);

      // Step 3: Capture payment
      paymentRepository.findOne.mockResolvedValueOnce({
        ...createdPayment,
        status: PaymentStatus.HELD,
      });
      paymentRepository.save.mockImplementation((p) =>
        Promise.resolve({ ...p, status: PaymentStatus.CAPTURED } as Payment),
      );

      const capturedPayment = await service.capturePayment('task-123');
      expect(capturedPayment.status).toBe(PaymentStatus.CAPTURED);
    });
  });
});
