/**
 * Users Service Unit Tests
 * Tests for user management logic
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException } from '@nestjs/common';
import { UsersService } from './users.service';
import { User, UserType, UserStatus } from './entities/user.entity';

/* eslint-disable @typescript-eslint/unbound-method */

describe('UsersService', () => {
  let service: UsersService;
  let repository: jest.Mocked<Repository<User>>;

  const mockUser: User = {
    id: 'user-123',
    type: UserType.CLIENT,
    phone: '+48123456789',
    email: 'test@example.com',
    name: 'Test User',
    avatarUrl: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const mockRepository = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
      update: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        { provide: getRepositoryToken(User), useValue: mockRepository },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
    repository = module.get(getRepositoryToken(User));
  });

  describe('findById', () => {
    it('should return user when found', async () => {
      repository.findOne.mockResolvedValue(mockUser);

      const result = await service.findById('user-123');

      expect(repository.findOne).toHaveBeenCalledWith({ where: { id: 'user-123' } });
      expect(result).toEqual(mockUser);
    });

    it('should return null when user not found', async () => {
      repository.findOne.mockResolvedValue(null);

      const result = await service.findById('nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('findByIdOrFail', () => {
    it('should return user when found', async () => {
      repository.findOne.mockResolvedValue(mockUser);

      const result = await service.findByIdOrFail('user-123');

      expect(result).toEqual(mockUser);
    });

    it('should throw NotFoundException when user not found', async () => {
      repository.findOne.mockResolvedValue(null);

      await expect(service.findByIdOrFail('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
      await expect(service.findByIdOrFail('nonexistent')).rejects.toThrow(
        'User with ID nonexistent not found',
      );
    });
  });

  describe('findByPhone', () => {
    it('should return user when found by phone', async () => {
      repository.findOne.mockResolvedValue(mockUser);

      const result = await service.findByPhone('+48123456789');

      expect(repository.findOne).toHaveBeenCalledWith({
        where: { phone: '+48123456789' },
      });
      expect(result).toEqual(mockUser);
    });

    it('should return null when phone not found', async () => {
      repository.findOne.mockResolvedValue(null);

      const result = await service.findByPhone('+48000000000');

      expect(result).toBeNull();
    });
  });

  describe('findByEmail', () => {
    it('should return user when found by email', async () => {
      repository.findOne.mockResolvedValue(mockUser);

      const result = await service.findByEmail('test@example.com');

      expect(repository.findOne).toHaveBeenCalledWith({
        where: { email: 'test@example.com' },
      });
      expect(result).toEqual(mockUser);
    });

    it('should return null when email not found', async () => {
      repository.findOne.mockResolvedValue(null);

      const result = await service.findByEmail('notfound@example.com');

      expect(result).toBeNull();
    });
  });

  describe('findByGoogleId', () => {
    it('should return user when found by Google ID', async () => {
      const googleUser = { ...mockUser, googleId: 'google-123' };
      repository.findOne.mockResolvedValue(googleUser);

      const result = await service.findByGoogleId('google-123');

      expect(repository.findOne).toHaveBeenCalledWith({
        where: { googleId: 'google-123' },
      });
      expect(result).toEqual(googleUser);
    });

    it('should return null when Google ID not found', async () => {
      repository.findOne.mockResolvedValue(null);

      const result = await service.findByGoogleId('nonexistent-google');

      expect(result).toBeNull();
    });
  });

  describe('findByAppleId', () => {
    it('should return user when found by Apple ID', async () => {
      const appleUser = { ...mockUser, appleId: 'apple-123' };
      repository.findOne.mockResolvedValue(appleUser);

      const result = await service.findByAppleId('apple-123');

      expect(repository.findOne).toHaveBeenCalledWith({
        where: { appleId: 'apple-123' },
      });
      expect(result).toEqual(appleUser);
    });

    it('should return null when Apple ID not found', async () => {
      repository.findOne.mockResolvedValue(null);

      const result = await service.findByAppleId('nonexistent-apple');

      expect(result).toBeNull();
    });
  });

  describe('create', () => {
    it('should create and return new user', async () => {
      const userData = {
        phone: '+48111222333',
        type: UserType.CLIENT,
        status: UserStatus.ACTIVE,
      };
      const createdUser = { ...mockUser, ...userData, id: 'new-user-id' };

      repository.create.mockReturnValue(createdUser);
      repository.save.mockResolvedValue(createdUser);

      const result = await service.create(userData);

      expect(repository.create).toHaveBeenCalledWith(userData);
      expect(repository.save).toHaveBeenCalledWith(createdUser);
      expect(result).toEqual(createdUser);
    });

    it('should create contractor user', async () => {
      const contractorData = {
        phone: '+48222333444',
        type: UserType.CONTRACTOR,
        status: UserStatus.ACTIVE,
        name: 'Contractor User',
      };
      const createdContractor = { ...mockUser, ...contractorData };

      repository.create.mockReturnValue(createdContractor);
      repository.save.mockResolvedValue(createdContractor);

      const result = await service.create(contractorData);

      expect(result.type).toBe(UserType.CONTRACTOR);
    });
  });

  describe('update', () => {
    it('should update user profile', async () => {
      const updateData = { name: 'Updated Name' };
      const updatedUser = { ...mockUser, name: 'Updated Name' };

      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(updatedUser);

      const result = await service.update('user-123', updateData);

      expect(repository.update).toHaveBeenCalledWith('user-123', updateData);
      expect(result.name).toBe('Updated Name');
    });

    it('should update avatar URL', async () => {
      const updateData = { avatarUrl: 'https://example.com/avatar.jpg' };
      const updatedUser = { ...mockUser, avatarUrl: 'https://example.com/avatar.jpg' };

      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(updatedUser);

      const result = await service.update('user-123', updateData);

      expect(result.avatarUrl).toBe('https://example.com/avatar.jpg');
    });

    it('should throw NotFoundException when updating non-existent user', async () => {
      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(null);

      await expect(service.update('nonexistent', { name: 'Test' })).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('updateStatus', () => {
    it('should update user status', async () => {
      const suspendedUser = { ...mockUser, status: UserStatus.SUSPENDED };

      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(suspendedUser);

      const result = await service.updateStatus('user-123', UserStatus.SUSPENDED);

      expect(repository.update).toHaveBeenCalledWith('user-123', {
        status: UserStatus.SUSPENDED,
      });
      expect(result.status).toBe(UserStatus.SUSPENDED);
    });

    it('should ban user', async () => {
      const bannedUser = { ...mockUser, status: UserStatus.BANNED };

      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(bannedUser);

      const result = await service.updateStatus('user-123', UserStatus.BANNED);

      expect(result.status).toBe(UserStatus.BANNED);
    });
  });

  describe('updateFcmToken', () => {
    it('should update FCM token for push notifications', async () => {
      const fcmToken = 'new-fcm-token-12345';
      const userWithToken = { ...mockUser, fcmToken };

      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(userWithToken);

      const result = await service.updateFcmToken('user-123', fcmToken);

      expect(repository.update).toHaveBeenCalledWith('user-123', { fcmToken });
      expect(result.fcmToken).toBe(fcmToken);
    });
  });

  describe('activate', () => {
    it('should activate user', async () => {
      const pendingUser = { ...mockUser, status: UserStatus.PENDING };
      const activeUser = { ...mockUser, status: UserStatus.ACTIVE };

      repository.update.mockResolvedValue({ affected: 1, raw: [], generatedMaps: [] });
      repository.findOne.mockResolvedValue(activeUser);

      const result = await service.activate('user-123');

      expect(repository.update).toHaveBeenCalledWith('user-123', {
        status: UserStatus.ACTIVE,
      });
      expect(result.status).toBe(UserStatus.ACTIVE);
    });
  });
});
