/**
 * Notifications Service Unit Tests
 * Tests for push notification functionality
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import { NotificationsService } from './notifications.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import {
  NotificationType,
  NOTIFICATION_TEMPLATES,
  interpolateTemplate,
} from './constants/notification-templates';

describe('NotificationsService', () => {
  let service: NotificationsService;
  let userRepository: jest.Mocked<Repository<User>>;

  const mockUser: User = {
    id: 'user-123',
    type: UserType.CONTRACTOR,
    phone: '+48123456789',
    email: 'test@example.com',
    name: 'Test User',
    avatarUrl: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: 'test-fcm-token-12345',
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockUserNoToken: User = {
    ...mockUser,
    id: 'user-no-token',
    fcmToken: null,
  };

  beforeEach(async () => {
    const mockUserRepository = {
      findOne: jest.fn(),
      find: jest.fn(),
    };

    const mockConfigService = {
      get: jest.fn((key: string) => {
        switch (key) {
          case 'FIREBASE_PROJECT_ID':
            return 'placeholder'; // Mock mode
          case 'FIREBASE_CLIENT_EMAIL':
            return 'placeholder';
          case 'FIREBASE_PRIVATE_KEY':
            return 'placeholder';
          default:
            return null;
        }
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        NotificationsService,
        { provide: getRepositoryToken(User), useValue: mockUserRepository },
        { provide: ConfigService, useValue: mockConfigService },
      ],
    }).compile();

    service = module.get<NotificationsService>(NotificationsService);
    userRepository = module.get(getRepositoryToken(User));
  });

  describe('Service Initialization', () => {
    it('should be defined', () => {
      expect(service).toBeDefined();
    });

    it('should be in mock mode when Firebase is not configured', () => {
      expect(service.isMockMode()).toBe(true);
    });
  });

  describe('sendToUser', () => {
    it('should send notification to user with FCM token', async () => {
      userRepository.findOne.mockResolvedValue(mockUser);

      const result = await service.sendToUser(
        mockUser.id,
        NotificationType.TASK_ACCEPTED,
        { taskTitle: 'Test Task', contractorName: 'John' },
      );

      expect(result.success).toBe(true);
      expect(result.messageId).toContain('mock-');
      expect(userRepository.findOne).toHaveBeenCalledWith({
        where: { id: mockUser.id },
      });
    });

    it('should fail when user not found', async () => {
      userRepository.findOne.mockResolvedValue(null);

      const result = await service.sendToUser(
        'nonexistent',
        NotificationType.TASK_ACCEPTED,
        {},
      );

      expect(result.success).toBe(false);
      expect(result.error).toBe('User not found');
    });

    it('should fail when user has no FCM token', async () => {
      userRepository.findOne.mockResolvedValue(mockUserNoToken);

      const result = await service.sendToUser(
        mockUserNoToken.id,
        NotificationType.TASK_ACCEPTED,
        {},
      );

      expect(result.success).toBe(false);
      expect(result.error).toBe('No FCM token');
    });
  });

  describe('sendToToken', () => {
    it('should send notification in mock mode', async () => {
      const result = await service.sendToToken(
        'test-token',
        NotificationType.NEW_TASK_NEARBY,
        { category: 'paczki', budget: 50, distance: 2.5 },
      );

      expect(result.success).toBe(true);
      expect(result.messageId).toContain('mock-');
    });

    it('should fail for unknown notification type', async () => {
      const result = await service.sendToToken(
        'test-token',
        'unknown_type' as NotificationType,
        {},
      );

      expect(result.success).toBe(false);
      expect(result.error).toContain('Unknown notification type');
    });
  });

  describe('sendToUsers', () => {
    it('should send to multiple users', async () => {
      userRepository.find.mockResolvedValue([mockUser, { ...mockUser, id: 'user-456' }]);

      const result = await service.sendToUsers(
        ['user-123', 'user-456'],
        NotificationType.TASK_CANCELLED,
        { taskTitle: 'Test', reason: 'Client request' },
      );

      expect(result.successCount).toBe(2);
      expect(result.failureCount).toBe(0);
      expect(result.results).toHaveLength(2);
    });

    it('should return zero success when no users have FCM tokens', async () => {
      userRepository.find.mockResolvedValue([mockUserNoToken]);

      const result = await service.sendToUsers(
        ['user-no-token'],
        NotificationType.TASK_CANCELLED,
        {},
      );

      expect(result.successCount).toBe(0);
      expect(result.failureCount).toBe(1);
    });
  });

  describe('sendToTokens', () => {
    it('should send to multiple tokens in mock mode', async () => {
      const result = await service.sendToTokens(
        ['token-1', 'token-2', 'token-3'],
        NotificationType.NEW_MESSAGE,
        { senderName: 'John', messagePreview: 'Hello!' },
      );

      expect(result.successCount).toBe(3);
      expect(result.failureCount).toBe(0);
      expect(result.results).toHaveLength(3);
      result.results.forEach((r) => {
        expect(r.success).toBe(true);
      });
    });

    it('should fail all for unknown notification type', async () => {
      const result = await service.sendToTokens(
        ['token-1', 'token-2'],
        'unknown' as NotificationType,
        {},
      );

      expect(result.successCount).toBe(0);
      expect(result.failureCount).toBe(2);
    });
  });
});

describe('Notification Templates', () => {
  describe('interpolateTemplate', () => {
    it('should interpolate single placeholder', () => {
      const template = { title: 'Hello {name}!', body: 'Welcome!' };
      const result = interpolateTemplate(template, { name: 'John' });

      expect(result.title).toBe('Hello John!');
      expect(result.body).toBe('Welcome!');
    });

    it('should interpolate multiple placeholders', () => {
      const template = {
        title: '{category} - {budget} PLN',
        body: 'Distance: {distance}km',
      };
      const result = interpolateTemplate(template, {
        category: 'Paczki',
        budget: 50,
        distance: 2.5,
      });

      expect(result.title).toBe('Paczki - 50 PLN');
      expect(result.body).toBe('Distance: 2.5km');
    });

    it('should leave unmatched placeholders unchanged', () => {
      const template = { title: 'Hello {name}!', body: '{unknown}' };
      const result = interpolateTemplate(template, { name: 'John' });

      expect(result.title).toBe('Hello John!');
      expect(result.body).toBe('{unknown}');
    });
  });

  describe('NOTIFICATION_TEMPLATES', () => {
    it('should have all notification types defined', () => {
      const types = Object.values(NotificationType);

      types.forEach((type) => {
        expect(NOTIFICATION_TEMPLATES[type]).toBeDefined();
        expect(NOTIFICATION_TEMPLATES[type].title).toBeTruthy();
        expect(NOTIFICATION_TEMPLATES[type].body).toBeTruthy();
      });
    });

    it('should have NEW_TASK_NEARBY template with placeholders', () => {
      const template = NOTIFICATION_TEMPLATES[NotificationType.NEW_TASK_NEARBY];

      expect(template.body).toContain('{category}');
      expect(template.body).toContain('{budget}');
      expect(template.body).toContain('{distance}');
    });

    it('should have TASK_ACCEPTED template with placeholders', () => {
      const template = NOTIFICATION_TEMPLATES[NotificationType.TASK_ACCEPTED];

      expect(template.body).toContain('{taskTitle}');
      expect(template.body).toContain('{contractorName}');
    });

    it('should have NEW_MESSAGE template with placeholders', () => {
      const template = NOTIFICATION_TEMPLATES[NotificationType.NEW_MESSAGE];

      expect(template.body).toContain('{senderName}');
      expect(template.body).toContain('{messagePreview}');
    });

    it('should have PAYMENT_RECEIVED template with placeholders', () => {
      const template = NOTIFICATION_TEMPLATES[NotificationType.PAYMENT_RECEIVED];

      expect(template.body).toContain('{amount}');
      expect(template.body).toContain('{taskTitle}');
    });
  });
});
