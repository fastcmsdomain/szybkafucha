/**
 * Messages Service Unit Tests
 * Tests for chat functionality between client and contractor
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, ForbiddenException } from '@nestjs/common';
import { MessagesService } from './messages.service';
import { Message } from './entities/message.entity';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';

describe('MessagesService', () => {
  let service: MessagesService;
  let messageRepository: jest.Mocked<Repository<Message>>;
  let taskRepository: jest.Mocked<Repository<Task>>;
  let userRepository: jest.Mocked<Repository<User>>;

  const mockClient: User = {
    id: 'client-123',
    type: UserType.CLIENT,
    phone: '+48111111111',
    email: 'client@test.pl',
    name: 'Jan Kowalski',
    avatarUrl: 'https://example.com/client.jpg',
    googleId: null,
    appleId: null,
    status: UserStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockContractor: User = {
    id: 'contractor-123',
    type: UserType.CONTRACTOR,
    phone: '+48222222221',
    email: 'contractor@test.pl',
    name: 'Marek Szybki',
    avatarUrl: 'https://example.com/contractor.jpg',
    googleId: null,
    appleId: null,
    status: UserStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
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
    status: TaskStatus.IN_PROGRESS,
    completionPhotos: null,
    scheduledAt: null,
    acceptedAt: new Date(),
    startedAt: new Date(),
    completedAt: null,
    cancelledAt: null,
    cancellationReason: null,
    createdAt: new Date(),
    client: null as any,
    contractor: null as any,
  };

  const mockMessage: Message = {
    id: 'message-123',
    taskId: 'task-123',
    task: null as any,
    senderId: 'client-123',
    sender: mockClient,
    content: 'Hello, when can you start?',
    readAt: null,
    createdAt: new Date(),
  };

  const createMockQueryBuilder = (getMany: any[] = [], getCount = 0) => ({
    leftJoinAndSelect: jest.fn().mockReturnThis(),
    where: jest.fn().mockReturnThis(),
    andWhere: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    take: jest.fn().mockReturnThis(),
    skip: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    update: jest.fn().mockReturnThis(),
    set: jest.fn().mockReturnThis(),
    execute: jest.fn().mockResolvedValue({ affected: 1 }),
    getMany: jest.fn().mockResolvedValue(getMany),
    getCount: jest.fn().mockResolvedValue(getCount),
  });

  beforeEach(async () => {
    const mockMessageRepository = {
      save: jest.fn(),
      find: jest.fn(),
      findOne: jest.fn(),
      count: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const mockTaskRepository = {
      findOne: jest.fn(),
      createQueryBuilder: jest.fn(),
    };

    const mockUserRepository = {
      findOne: jest.fn(),
    };

    const mockNotificationsService = {
      sendToUser: jest.fn().mockResolvedValue({ success: true }),
      sendToUsers: jest
        .fn()
        .mockResolvedValue({ successCount: 1, failureCount: 0, results: [] }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        MessagesService,
        {
          provide: getRepositoryToken(Message),
          useValue: mockMessageRepository,
        },
        { provide: getRepositoryToken(Task), useValue: mockTaskRepository },
        { provide: getRepositoryToken(User), useValue: mockUserRepository },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<MessagesService>(MessagesService);
    messageRepository = module.get(getRepositoryToken(Message));
    taskRepository = module.get(getRepositoryToken(Task));
    userRepository = module.get(getRepositoryToken(User));
  });

  describe('getTaskMessages', () => {
    it('should return messages for authorized user (client)', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder([mockMessage]) as any,
      );

      const result = await service.getTaskMessages('task-123', 'client-123');

      expect(result.length).toBe(1);
      expect(result[0].id).toBe('message-123');
      expect(result[0].content).toBe('Hello, when can you start?');
    });

    it('should return messages for authorized user (contractor)', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder([mockMessage]) as any,
      );

      const result = await service.getTaskMessages(
        'task-123',
        'contractor-123',
      );

      expect(result.length).toBe(1);
    });

    it('should throw ForbiddenException for unauthorized user', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);

      await expect(
        service.getTaskMessages('task-123', 'other-user'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException when task not found', async () => {
      taskRepository.findOne.mockResolvedValue(null);

      await expect(
        service.getTaskMessages('nonexistent', 'client-123'),
      ).rejects.toThrow(NotFoundException);
    });

    it('should return message response with sender info', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder([{ ...mockMessage, sender: mockClient }]) as any,
      );

      const result = await service.getTaskMessages('task-123', 'client-123');

      expect(result[0]).toHaveProperty('senderName', 'Jan Kowalski');
      expect(result[0]).toHaveProperty(
        'senderAvatar',
        'https://example.com/client.jpg',
      );
    });

    it('should apply pagination with before parameter', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.findOne.mockResolvedValue({
        ...mockMessage,
        id: 'before-message',
        createdAt: new Date('2024-01-01'),
      });
      const qb = createMockQueryBuilder([]);
      messageRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getTaskMessages(
        'task-123',
        'client-123',
        50,
        'before-message',
      );

      expect(qb.andWhere).toHaveBeenCalledWith(
        'message.createdAt < :createdAt',
        expect.any(Object),
      );
    });

    it('should limit results', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      const qb = createMockQueryBuilder([]);
      messageRepository.createQueryBuilder.mockReturnValue(qb as any);

      await service.getTaskMessages('task-123', 'client-123', 25);

      expect(qb.take).toHaveBeenCalledWith(25);
    });
  });

  describe('sendMessage', () => {
    it('should create and return message', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.save.mockResolvedValue(mockMessage);
      userRepository.findOne.mockResolvedValue(mockClient);

      const result = await service.sendMessage('task-123', 'client-123', {
        content: 'Hello, when can you start?',
      });

      expect(result.id).toBe('message-123');
      expect(result.content).toBe('Hello, when can you start?');
      expect(result.senderName).toBe('Jan Kowalski');
    });

    it('should throw ForbiddenException when sender not part of task', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);

      await expect(
        service.sendMessage('task-123', 'other-user', { content: 'Hi' }),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should throw NotFoundException when task not found', async () => {
      taskRepository.findOne.mockResolvedValue(null);

      await expect(
        service.sendMessage('nonexistent', 'client-123', { content: 'Hi' }),
      ).rejects.toThrow(NotFoundException);
    });

    it('should allow contractor to send message', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.save.mockResolvedValue({
        ...mockMessage,
        senderId: 'contractor-123',
        sender: mockContractor,
      });
      userRepository.findOne.mockResolvedValue(mockContractor);

      const result = await service.sendMessage('task-123', 'contractor-123', {
        content: 'I will start in 10 minutes',
      });

      expect(result.senderId).toBe('contractor-123');
      expect(result.senderName).toBe('Marek Szybki');
    });
  });

  describe('markAsRead', () => {
    it('should mark unread messages from other users as read', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      const qb = createMockQueryBuilder();
      qb.execute.mockResolvedValue({ affected: 5 });
      messageRepository.createQueryBuilder.mockReturnValue(qb as any);

      const result = await service.markAsRead('task-123', 'client-123');

      expect(result.updated).toBe(5);
      expect(qb.set).toHaveBeenCalledWith({ readAt: expect.any(Date) });
    });

    it('should throw ForbiddenException for unauthorized user', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);

      await expect(
        service.markAsRead('task-123', 'other-user'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should return 0 when no unread messages', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      const qb = createMockQueryBuilder();
      qb.execute.mockResolvedValue({ affected: 0 });
      messageRepository.createQueryBuilder.mockReturnValue(qb as any);

      const result = await service.markAsRead('task-123', 'client-123');

      expect(result.updated).toBe(0);
    });
  });

  describe('getUnreadCount', () => {
    it('should return count of unread messages', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.count.mockResolvedValue(3);

      const result = await service.getUnreadCount('task-123', 'client-123');

      expect(result).toBe(3);
    });

    it('should throw ForbiddenException for unauthorized user', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);

      await expect(
        service.getUnreadCount('task-123', 'other-user'),
      ).rejects.toThrow(ForbiddenException);
    });
  });

  describe('getAllUnreadCounts', () => {
    it('should return unread counts for all active tasks', async () => {
      const tasks = [{ id: 'task-1' }, { id: 'task-2' }, { id: 'task-3' }];

      const taskQb = {
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue(tasks),
      };
      taskRepository.createQueryBuilder.mockReturnValue(taskQb as any);

      const messageQb = createMockQueryBuilder();
      messageQb.getCount
        .mockResolvedValueOnce(5) // task-1: 5 unread
        .mockResolvedValueOnce(0) // task-2: 0 unread
        .mockResolvedValueOnce(2); // task-3: 2 unread
      messageRepository.createQueryBuilder.mockReturnValue(messageQb as any);

      const result = await service.getAllUnreadCounts('client-123');

      // Should only return tasks with unread > 0
      expect(result.length).toBe(2);
      expect(result).toContainEqual({ taskId: 'task-1', count: 5 });
      expect(result).toContainEqual({ taskId: 'task-3', count: 2 });
    });

    it('should return empty array when no active tasks', async () => {
      const taskQb = {
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      };
      taskRepository.createQueryBuilder.mockReturnValue(taskQb as any);

      const result = await service.getAllUnreadCounts('client-123');

      expect(result).toEqual([]);
    });

    it('should exclude completed and cancelled tasks', async () => {
      const taskQb = {
        select: jest.fn().mockReturnThis(),
        where: jest.fn().mockReturnThis(),
        andWhere: jest.fn().mockReturnThis(),
        getMany: jest.fn().mockResolvedValue([]),
      };
      taskRepository.createQueryBuilder.mockReturnValue(taskQb as any);

      await service.getAllUnreadCounts('client-123');

      expect(taskQb.andWhere).toHaveBeenCalledWith(
        'task.status NOT IN (:...completedStatuses)',
        { completedStatuses: ['completed', 'cancelled'] },
      );
    });
  });

  describe('task access verification', () => {
    it('should allow client to access their task', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder([]) as any,
      );

      await expect(
        service.getTaskMessages('task-123', 'client-123'),
      ).resolves.toBeDefined();
    });

    it('should allow contractor to access assigned task', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);
      messageRepository.createQueryBuilder.mockReturnValue(
        createMockQueryBuilder([]) as any,
      );

      await expect(
        service.getTaskMessages('task-123', 'contractor-123'),
      ).resolves.toBeDefined();
    });

    it('should deny access to task without contractor', async () => {
      taskRepository.findOne.mockResolvedValue({
        ...mockTask,
        contractorId: null,
      });

      await expect(
        service.getTaskMessages('task-123', 'contractor-123'),
      ).rejects.toThrow(ForbiddenException);
    });

    it('should deny access to random user', async () => {
      taskRepository.findOne.mockResolvedValue(mockTask);

      await expect(
        service.getTaskMessages('task-123', 'random-user'),
      ).rejects.toThrow(ForbiddenException);
    });
  });
});
