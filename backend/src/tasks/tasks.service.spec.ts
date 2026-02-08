/**
 * Tasks Service Unit Tests
 * Tests for task operations and contractor matching algorithm
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { TasksService } from './tasks.service';
import { Task, TaskStatus } from './entities/task.entity';
import { Rating } from './entities/rating.entity';
import {
  ContractorProfile,
  KycStatus,
} from '../contractor/entities/contractor-profile.entity';
import { ContractorService } from '../contractor/contractor.service';
import { RealtimeGateway } from '../realtime/realtime.gateway';
import { NotificationsService } from '../notifications/notifications.service';

describe('TasksService', () => {
  let service: TasksService;
  let taskRepository: jest.Mocked<Repository<Task>>;
  let contractorProfileRepository: jest.Mocked<Repository<ContractorProfile>>;
  let realtimeGateway: jest.Mocked<RealtimeGateway>;

  const mockTask: Task = {
    id: 'task-123',
    clientId: 'client-123',
    contractorId: null,
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
    status: TaskStatus.CREATED,
    completionPhotos: null,
    scheduledAt: null,
    acceptedAt: null,
    startedAt: null,
    completedAt: null,
    cancelledAt: null,
    cancellationReason: null,
    createdAt: new Date(),
    client: null as any,
    contractor: null as any,
  };

  const createMockContractorProfile = (overrides = {}): ContractorProfile => ({
    userId: 'contractor-123',
    user: null as any,
    bio: 'Experienced cleaner',
    categories: ['sprzatanie', 'zakupy'],
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
    ...overrides,
  });

  beforeEach(async () => {
    const mockTaskRepository = {
      create: jest.fn(),
      save: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
    };

    const mockRatingRepository = {
      create: jest.fn(),
      save: jest.fn(),
      findOne: jest.fn(),
    };

    const mockContractorProfileRepository = {
      find: jest.fn(),
    };

    const mockRealtimeGateway = {
      sendToUser: jest.fn().mockReturnValue(true),
      broadcastTaskStatusWithContractor: jest.fn(),
      broadcastTaskStatus: jest.fn(),
    };

    const mockContractorService = {
      isProfileComplete: jest.fn().mockResolvedValue(true),
    };

    const mockNotificationsService = {
      sendToUser: jest.fn().mockResolvedValue({ success: true }),
      sendToUsers: jest
        .fn()
        .mockResolvedValue({ successCount: 1, failureCount: 0, results: [] }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        TasksService,
        { provide: getRepositoryToken(Task), useValue: mockTaskRepository },
        { provide: getRepositoryToken(Rating), useValue: mockRatingRepository },
        {
          provide: getRepositoryToken(ContractorProfile),
          useValue: mockContractorProfileRepository,
        },
        { provide: RealtimeGateway, useValue: mockRealtimeGateway },
        { provide: NotificationsService, useValue: mockNotificationsService },
        { provide: ContractorService, useValue: mockContractorService },
      ],
    }).compile();

    service = module.get<TasksService>(TasksService);
    taskRepository = module.get(getRepositoryToken(Task));
    contractorProfileRepository = module.get(
      getRepositoryToken(ContractorProfile),
    );
    realtimeGateway = module.get(RealtimeGateway);
  });

  describe('calculateDistance', () => {
    it('should return 0 for same coordinates', () => {
      const distance = service.calculateDistance(
        52.2297,
        21.0122,
        52.2297,
        21.0122,
      );
      expect(distance).toBe(0);
    });

    it('should calculate distance between Warsaw and Krakow correctly (~250-300km)', () => {
      // Warsaw coordinates
      const warsawLat = 52.2297;
      const warsawLng = 21.0122;
      // Krakow coordinates
      const krakowLat = 50.0647;
      const krakowLng = 19.945;

      const distance = service.calculateDistance(
        warsawLat,
        warsawLng,
        krakowLat,
        krakowLng,
      );

      // Distance should be approximately 252km (allow 10% margin)
      expect(distance).toBeGreaterThan(240);
      expect(distance).toBeLessThan(270);
    });

    it('should handle coordinates across the equator', () => {
      // New York
      const nyLat = 40.7128;
      const nyLng = -74.006;
      // Buenos Aires
      const baLat = -34.6037;
      const baLng = -58.3816;

      const distance = service.calculateDistance(nyLat, nyLng, baLat, baLng);

      // Distance should be approximately 8500km
      expect(distance).toBeGreaterThan(8000);
      expect(distance).toBeLessThan(9000);
    });

    it('should be symmetric (A to B = B to A)', () => {
      const lat1 = 52.2297;
      const lng1 = 21.0122;
      const lat2 = 50.0647;
      const lng2 = 19.945;

      const distance1 = service.calculateDistance(lat1, lng1, lat2, lng2);
      const distance2 = service.calculateDistance(lat2, lng2, lat1, lng1);

      expect(distance1).toBeCloseTo(distance2, 6);
    });

    it('should calculate short distances accurately', () => {
      // Two points ~1km apart in Warsaw
      const lat1 = 52.2297;
      const lng1 = 21.0122;
      const lat2 = 52.2387; // ~1km north
      const lng2 = 21.0122;

      const distance = service.calculateDistance(lat1, lng1, lat2, lng2);

      // Should be approximately 1km (allow 100m margin)
      expect(distance).toBeGreaterThan(0.9);
      expect(distance).toBeLessThan(1.1);
    });
  });

  describe('calculateContractorScore', () => {
    it('should return ~1.0 for perfect contractor at same location', () => {
      // Perfect rating (5.0), max completions (100), same location (0 distance)
      const score = service.calculateContractorScore(5.0, 100, 0, 20);

      // Score = (1.0 * 0.4) + (1.0 * 0.3) + (1.0 * 0.3) = 1.0
      expect(score).toBeCloseTo(1.0, 2);
    });

    it('should return low score for new contractor far away', () => {
      // No rating (0), no completions (0), at max radius (20km)
      const score = service.calculateContractorScore(0, 0, 20, 20);

      // Score = (0 * 0.4) + (0 * 0.3) + (0 * 0.3) = 0
      expect(score).toBeCloseTo(0, 2);
    });

    it('should apply weights correctly', () => {
      // Rating 5 (normalized: 1.0), 50 completions (normalized: 0.5), 10km (proximity: 0.5)
      const score = service.calculateContractorScore(5, 50, 10, 20);

      // Score = (1.0 * 0.4) + (0.5 * 0.3) + (0.5 * 0.3) = 0.4 + 0.15 + 0.15 = 0.7
      expect(score).toBeCloseTo(0.7, 2);
    });

    it('should cap completions normalization at 100', () => {
      // 200 completions should be normalized to 1.0, not 2.0
      const score = service.calculateContractorScore(0, 200, 20, 20);

      // Only completions component: (1.0 * 0.3) = 0.3
      expect(score).toBeCloseTo(0.3, 2);
    });

    it('should handle rating above 5 gracefully', () => {
      // Edge case: rating somehow above 5
      const score = service.calculateContractorScore(6, 0, 0, 20);

      // Rating should be capped at 1.0, so (1.0 * 0.4) + (0 * 0.3) + (1.0 * 0.3) = 0.7
      expect(score).toBeLessThanOrEqual(1.0);
    });

    it('should return higher score for closer contractors with same rating', () => {
      const closeScore = service.calculateContractorScore(4.0, 50, 2, 20);
      const farScore = service.calculateContractorScore(4.0, 50, 15, 20);

      expect(closeScore).toBeGreaterThan(farScore);
    });
  });

  describe('findAndRankContractors', () => {
    it('should return contractors sorted by score (highest first)', async () => {
      const contractors = [
        createMockContractorProfile({
          userId: 'contractor-1',
          ratingAvg: 3.0,
          completedTasksCount: 20,
          lastLocationLat: 52.24,
          lastLocationLng: 21.02,
        }),
        createMockContractorProfile({
          userId: 'contractor-2',
          ratingAvg: 5.0,
          completedTasksCount: 100,
          lastLocationLat: 52.23,
          lastLocationLng: 21.013,
        }),
        createMockContractorProfile({
          userId: 'contractor-3',
          ratingAvg: 4.0,
          completedTasksCount: 50,
          lastLocationLat: 52.235,
          lastLocationLng: 21.015,
        }),
      ];

      contractorProfileRepository.find.mockResolvedValue(contractors);

      const ranked = await service.findAndRankContractors(mockTask, 20, 10);

      expect(ranked.length).toBe(3);
      expect(ranked[0].contractorId).toBe('contractor-2'); // Highest score
      expect(ranked[0].score).toBeGreaterThan(ranked[1].score);
      expect(ranked[1].score).toBeGreaterThan(ranked[2].score);
    });

    it('should filter out offline contractors', async () => {
      const contractors = [
        createMockContractorProfile({
          userId: 'online-contractor',
          isOnline: true,
        }),
        createMockContractorProfile({
          userId: 'offline-contractor',
          isOnline: false,
        }),
      ];

      contractorProfileRepository.find.mockResolvedValue(
        contractors.filter((c) => c.isOnline),
      );

      const ranked = await service.findAndRankContractors(mockTask);

      expect(ranked.length).toBe(1);
      expect(ranked[0].contractorId).toBe('online-contractor');
    });

    it('should filter by category match', async () => {
      const contractors = [
        createMockContractorProfile({
          userId: 'matching-contractor',
          categories: ['sprzatanie'],
        }),
        createMockContractorProfile({
          userId: 'non-matching-contractor',
          categories: ['zakupy', 'paczki'],
        }),
      ];

      contractorProfileRepository.find.mockResolvedValue(contractors);

      const ranked = await service.findAndRankContractors(mockTask);

      expect(ranked.length).toBe(1);
      expect(ranked[0].contractorId).toBe('matching-contractor');
    });

    it('should filter by distance radius', async () => {
      const contractors = [
        createMockContractorProfile({
          userId: 'nearby-contractor',
          lastLocationLat: 52.23, // ~0.5km from task
          lastLocationLng: 21.013,
        }),
        createMockContractorProfile({
          userId: 'far-contractor',
          lastLocationLat: 52.5, // ~30km from task
          lastLocationLng: 21.0,
        }),
      ];

      contractorProfileRepository.find.mockResolvedValue(contractors);

      const ranked = await service.findAndRankContractors(mockTask, 5); // 5km radius

      expect(ranked.length).toBe(1);
      expect(ranked[0].contractorId).toBe('nearby-contractor');
    });

    it('should return empty array when no contractors match', async () => {
      contractorProfileRepository.find.mockResolvedValue([]);

      const ranked = await service.findAndRankContractors(mockTask);

      expect(ranked).toEqual([]);
    });

    it('should skip contractors without location', async () => {
      const contractors = [
        createMockContractorProfile({
          userId: 'with-location',
          lastLocationLat: 52.23,
          lastLocationLng: 21.013,
        }),
        createMockContractorProfile({
          userId: 'no-location',
          lastLocationLat: null,
          lastLocationLng: null,
        }),
      ];

      contractorProfileRepository.find.mockResolvedValue(contractors);

      const ranked = await service.findAndRankContractors(mockTask);

      expect(ranked.length).toBe(1);
      expect(ranked[0].contractorId).toBe('with-location');
    });

    it('should limit results to specified number', async () => {
      const contractors = Array.from({ length: 10 }, (_, i) =>
        createMockContractorProfile({
          userId: `contractor-${i}`,
          ratingAvg: 4.0 + i * 0.1,
          lastLocationLat: 52.23,
          lastLocationLng: 21.013,
        }),
      );

      contractorProfileRepository.find.mockResolvedValue(contractors);

      const ranked = await service.findAndRankContractors(mockTask, 20, 5);

      expect(ranked.length).toBe(5);
    });

    it('should include distance in results', async () => {
      const contractors = [
        createMockContractorProfile({
          userId: 'contractor-1',
          lastLocationLat: 52.23,
          lastLocationLng: 21.013,
        }),
      ];

      contractorProfileRepository.find.mockResolvedValue(contractors);

      const ranked = await service.findAndRankContractors(mockTask);

      expect(ranked[0]).toHaveProperty('distance');
      expect(typeof ranked[0].distance).toBe('number');
      expect(ranked[0].distance).toBeGreaterThan(0);
    });
  });

  describe('notifyAvailableContractors', () => {
    it('should notify ranked contractors via WebSocket', async () => {
      const contractors = [
        createMockContractorProfile({ userId: 'contractor-1' }),
        createMockContractorProfile({ userId: 'contractor-2' }),
      ];

      contractorProfileRepository.find.mockResolvedValue(contractors);

      await service.notifyAvailableContractors(mockTask);

      expect(realtimeGateway.sendToUser).toHaveBeenCalledTimes(2);
      expect(realtimeGateway.sendToUser).toHaveBeenCalledWith(
        'contractor-1',
        'task:new_available',
        expect.objectContaining({
          task: expect.objectContaining({
            id: mockTask.id,
            category: mockTask.category,
          }),
          score: expect.any(Number),
          distance: expect.any(Number),
        }),
      );
    });

    it('should not send notifications when no contractors available', async () => {
      contractorProfileRepository.find.mockResolvedValue([]);

      await service.notifyAvailableContractors(mockTask);

      expect(realtimeGateway.sendToUser).not.toHaveBeenCalled();
    });
  });

  describe('findAvailableForContractor', () => {
    it('should return tasks within radius matching categories', async () => {
      const tasks = [
        { ...mockTask, id: 'task-1', category: 'sprzatanie' },
        { ...mockTask, id: 'task-2', category: 'zakupy' },
        { ...mockTask, id: 'task-3', category: 'paczki' }, // Different category
      ];

      taskRepository.find.mockResolvedValue(tasks);

      const result = await service.findAvailableForContractor(
        'contractor-123',
        ['sprzatanie', 'zakupy'],
        52.2297,
        21.0122,
        10,
      );

      expect(result.length).toBe(2);
      expect(result.map((t) => t.id)).toContain('task-1');
      expect(result.map((t) => t.id)).toContain('task-2');
    });

    it('should filter out tasks beyond radius', async () => {
      const tasks = [
        {
          ...mockTask,
          id: 'nearby-task',
          locationLat: 52.23,
          locationLng: 21.013,
        },
        { ...mockTask, id: 'far-task', locationLat: 52.5, locationLng: 21.0 },
      ];

      taskRepository.find.mockResolvedValue(tasks);

      const result = await service.findAvailableForContractor(
        'contractor-123',
        ['sprzatanie'],
        52.2297,
        21.0122,
        5, // 5km radius
      );

      expect(result.length).toBe(1);
      expect(result[0].id).toBe('nearby-task');
    });
  });
});
