/**
 * Contractor Service Unit Tests
 * Tests for contractor operations
 */
import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { NotFoundException, BadRequestException } from '@nestjs/common';
import { ContractorService } from './contractor.service';
import {
  ContractorProfile,
  KycStatus,
} from './entities/contractor-profile.entity';
import { User, UserType, UserStatus } from '../users/entities/user.entity';

/* eslint-disable @typescript-eslint/unbound-method */

describe('ContractorService', () => {
  let service: ContractorService;
  let repository: jest.Mocked<Repository<ContractorProfile>>;

  const mockUser: User = {
    id: 'user-123',
    type: UserType.CONTRACTOR,
    phone: '+48123456789',
    email: 'contractor@example.com',
    name: 'Test Contractor',
    avatarUrl: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockProfile: ContractorProfile = {
    userId: 'user-123',
    user: mockUser,
    bio: 'Test bio',
    categories: ['paczki', 'zakupy'],
    serviceRadiusKm: 10,
    kycStatus: KycStatus.PENDING,
    kycIdVerified: false,
    kycSelfieVerified: false,
    kycBankVerified: false,
    stripeAccountId: null,
    ratingAvg: 0,
    ratingCount: 0,
    completedTasksCount: 0,
    isOnline: false,
    lastLocationLat: null,
    lastLocationLng: null,
    lastLocationAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  beforeEach(async () => {
    const mockRepository = {
      findOne: jest.fn(),
      create: jest.fn(),
      save: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ContractorService,
        { provide: getRepositoryToken(ContractorProfile), useValue: mockRepository },
      ],
    }).compile();

    service = module.get<ContractorService>(ContractorService);
    repository = module.get(getRepositoryToken(ContractorProfile));
  });

  describe('findByUserId', () => {
    it('should return contractor profile when found', async () => {
      repository.findOne.mockResolvedValue(mockProfile);

      const result = await service.findByUserId('user-123');

      expect(repository.findOne).toHaveBeenCalledWith({
        where: { userId: 'user-123' },
        relations: ['user'],
      });
      expect(result).toEqual(mockProfile);
    });

    it('should return null when profile not found', async () => {
      repository.findOne.mockResolvedValue(null);

      const result = await service.findByUserId('nonexistent');

      expect(result).toBeNull();
    });
  });

  describe('findByUserIdOrFail', () => {
    it('should return profile when found', async () => {
      repository.findOne.mockResolvedValue(mockProfile);

      const result = await service.findByUserIdOrFail('user-123');

      expect(result).toEqual(mockProfile);
    });

    it('should throw NotFoundException when profile not found', async () => {
      repository.findOne.mockResolvedValue(null);

      await expect(service.findByUserIdOrFail('nonexistent')).rejects.toThrow(
        NotFoundException,
      );
      await expect(service.findByUserIdOrFail('nonexistent')).rejects.toThrow(
        'Contractor profile not found',
      );
    });
  });

  describe('create', () => {
    it('should create new contractor profile', async () => {
      repository.findOne.mockResolvedValue(null);
      repository.create.mockReturnValue(mockProfile);
      repository.save.mockResolvedValue(mockProfile);

      const result = await service.create('user-123');

      expect(repository.create).toHaveBeenCalledWith({
        userId: 'user-123',
        categories: [],
      });
      expect(repository.save).toHaveBeenCalled();
      expect(result).toEqual(mockProfile);
    });

    it('should return existing profile if already exists', async () => {
      repository.findOne.mockResolvedValue(mockProfile);

      const result = await service.create('user-123');

      expect(repository.create).not.toHaveBeenCalled();
      expect(result).toEqual(mockProfile);
    });
  });

  describe('update', () => {
    it('should update bio', async () => {
      const updatedProfile = { ...mockProfile, bio: 'Updated bio' };
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockResolvedValue(updatedProfile);

      const result = await service.update('user-123', { bio: 'Updated bio' });

      expect(result.bio).toBe('Updated bio');
    });

    it('should update categories', async () => {
      const newCategories = ['montaz', 'sprzatanie'];
      const updatedProfile = { ...mockProfile, categories: newCategories };
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockResolvedValue(updatedProfile);

      const result = await service.update('user-123', { categories: newCategories });

      expect(result.categories).toEqual(newCategories);
    });

    it('should update service radius', async () => {
      const updatedProfile = { ...mockProfile, serviceRadiusKm: 20 };
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockResolvedValue(updatedProfile);

      const result = await service.update('user-123', { serviceRadiusKm: 20 });

      expect(result.serviceRadiusKm).toBe(20);
    });

    it('should throw NotFoundException when profile not found', async () => {
      repository.findOne.mockResolvedValue(null);

      await expect(service.update('nonexistent', { bio: 'Test' })).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('setAvailability', () => {
    it('should allow going offline without KYC', async () => {
      const offlineProfile = { ...mockProfile, isOnline: false };
      repository.findOne.mockResolvedValue({ ...mockProfile, isOnline: true });
      repository.save.mockResolvedValue(offlineProfile);

      const result = await service.setAvailability('user-123', false);

      expect(result.isOnline).toBe(false);
    });

    it('should allow going online when KYC verified', async () => {
      const verifiedProfile = {
        ...mockProfile,
        kycStatus: KycStatus.VERIFIED,
        isOnline: false,
      };
      const onlineProfile = { ...verifiedProfile, isOnline: true };
      repository.findOne.mockResolvedValue(verifiedProfile);
      repository.save.mockResolvedValue(onlineProfile);

      const result = await service.setAvailability('user-123', true);

      expect(result.isOnline).toBe(true);
    });

    it('should throw BadRequestException when going online without KYC', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile, kycStatus: KycStatus.PENDING });

      await expect(service.setAvailability('user-123', true)).rejects.toThrow(
        BadRequestException,
      );
      await expect(service.setAvailability('user-123', true)).rejects.toThrow(
        'Complete KYC verification before going online',
      );
    });
  });

  describe('updateLocation', () => {
    it('should update GPS coordinates', async () => {
      const location = { lat: 52.2297, lng: 21.0122 };
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.updateLocation('user-123', location);

      expect(result.lastLocationLat).toBe(52.2297);
      expect(result.lastLocationLng).toBe(21.0122);
      expect(result.lastLocationAt).toBeDefined();
    });

    it('should throw NotFoundException when profile not found', async () => {
      repository.findOne.mockResolvedValue(null);

      await expect(
        service.updateLocation('nonexistent', { lat: 52.0, lng: 21.0 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('submitKycId', () => {
    it('should mark ID as verified', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.submitKycId('user-123', 'document-url');

      expect(result.kycIdVerified).toBe(true);
    });
  });

  describe('submitKycSelfie', () => {
    it('should mark selfie as verified', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.submitKycSelfie('user-123', 'selfie-url');

      expect(result.kycSelfieVerified).toBe(true);
    });
  });

  describe('submitKycBank', () => {
    it('should mark bank as verified for valid IBAN', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.submitKycBank(
        'user-123',
        'PL61109010140000071219812874',
        'Test User',
      );

      expect(result.kycBankVerified).toBe(true);
    });

    it('should throw BadRequestException for invalid IBAN', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile });

      await expect(
        service.submitKycBank('user-123', 'INVALID', 'Test User'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.submitKycBank('user-123', 'INVALID', 'Test User'),
      ).rejects.toThrow('Invalid IBAN format');
    });

    it('should set overall KYC status to VERIFIED when all verified', async () => {
      const partiallyVerified = {
        ...mockProfile,
        kycIdVerified: true,
        kycSelfieVerified: true,
        kycBankVerified: false,
      };
      repository.findOne.mockResolvedValue(partiallyVerified);
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.submitKycBank(
        'user-123',
        'PL61109010140000071219812874',
        'Test User',
      );

      expect(result.kycBankVerified).toBe(true);
      expect(result.kycStatus).toBe(KycStatus.VERIFIED);
    });
  });

  describe('updateRating', () => {
    it('should calculate new average rating', async () => {
      const profileWithRatings = {
        ...mockProfile,
        ratingAvg: 4.0,
        ratingCount: 4,
      };
      repository.findOne.mockResolvedValue(profileWithRatings);
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      // Adding a 5-star rating to (4 * 4.0 = 16) gives (16 + 5) / 5 = 4.2
      const result = await service.updateRating('user-123', 5);

      expect(result.ratingCount).toBe(5);
      expect(result.ratingAvg).toBe(4.2);
    });

    it('should handle first rating', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile, ratingAvg: 0, ratingCount: 0 });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.updateRating('user-123', 5);

      expect(result.ratingCount).toBe(1);
      expect(result.ratingAvg).toBe(5);
    });
  });

  describe('incrementCompletedTasks', () => {
    it('should increment completed tasks count', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile, completedTasksCount: 5 });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.incrementCompletedTasks('user-123');

      expect(result.completedTasksCount).toBe(6);
    });

    it('should handle first completed task', async () => {
      repository.findOne.mockResolvedValue({ ...mockProfile, completedTasksCount: 0 });
      repository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      const result = await service.incrementCompletedTasks('user-123');

      expect(result.completedTasksCount).toBe(1);
    });
  });
});
