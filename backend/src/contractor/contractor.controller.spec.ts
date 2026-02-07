/**
 * Contractor Controller Unit Tests
 * Tests for contractor REST endpoints
 */
import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { ContractorController } from './contractor.controller';
import { ContractorService } from './contractor.service';
import {
  ContractorProfile,
  KycStatus,
} from './entities/contractor-profile.entity';
import { User, UserType, UserStatus } from '../users/entities/user.entity';

describe('ContractorController', () => {
  let controller: ContractorController;
  let service: jest.Mocked<ContractorService>;

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

  const mockRequest = {
    user: {
      id: 'user-123',
      type: 'contractor',
      email: 'contractor@example.com',
    },
  };

  beforeEach(async () => {
    const mockService = {
      findByUserId: jest.fn(),
      findByUserIdOrFail: jest.fn(),
      getRatingsByUserId: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      setAvailability: jest.fn(),
      updateLocation: jest.fn(),
      submitKycId: jest.fn(),
      submitKycSelfie: jest.fn(),
      submitKycBank: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [ContractorController],
      providers: [{ provide: ContractorService, useValue: mockService }],
    }).compile();

    controller = module.get<ContractorController>(ContractorController);
    service = module.get<ContractorService>(
      ContractorService,
    ) as jest.Mocked<ContractorService>;
  });

  describe('GET /contractor/profile', () => {
    it('should return existing contractor profile', async () => {
      service.findByUserId.mockResolvedValue(mockProfile);

      const result = await controller.getProfile(mockRequest as any);

      expect(service.findByUserId).toHaveBeenCalledWith('user-123');
      expect(result).toEqual(mockProfile);
    });

    it('should create profile if not exists', async () => {
      service.findByUserId.mockResolvedValue(null);
      service.create.mockResolvedValue(mockProfile);

      const result = await controller.getProfile(mockRequest as any);

      expect(service.findByUserId).toHaveBeenCalledWith('user-123');
      expect(service.create).toHaveBeenCalledWith('user-123');
      expect(result).toEqual(mockProfile);
    });
  });

  describe('GET /contractor/profile/ratings', () => {
    it('should return contractor ratings and comments', async () => {
      const ratings = [
        {
          id: 'rating-1',
          rating: 5,
          comment: 'Świetna współpraca',
          createdAt: new Date(),
          fromUserId: 'client-1',
          fromUserName: 'Anna',
          fromUserAvatarUrl: null,
        },
      ];
      service.getRatingsByUserId.mockResolvedValue(ratings as any);

      const result = await controller.getMyRatings(mockRequest as any);

      expect(service.getRatingsByUserId).toHaveBeenCalledWith('user-123');
      expect(result).toEqual(ratings);
    });
  });

  describe('GET /contractor/:userId/ratings', () => {
    it('should return ratings for selected contractor', async () => {
      const ratings = [{ id: 'rating-1', rating: 4, comment: 'Super' }];
      service.getRatingsByUserId.mockResolvedValue(ratings as any);

      const result = await controller.getPublicRatings('user-999');

      expect(service.getRatingsByUserId).toHaveBeenCalledWith('user-999');
      expect(result).toEqual(ratings);
    });
  });

  describe('PUT /contractor/profile', () => {
    it('should update profile bio', async () => {
      const updateDto = { bio: 'Updated bio' };
      const updatedProfile = { ...mockProfile, bio: 'Updated bio' };

      service.findByUserId.mockResolvedValue(mockProfile);
      service.update.mockResolvedValue(updatedProfile);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(service.update).toHaveBeenCalledWith('user-123', updateDto);
      expect(result.bio).toBe('Updated bio');
    });

    it('should update profile categories', async () => {
      const updateDto = { categories: ['montaz', 'sprzatanie'] };
      const updatedProfile = {
        ...mockProfile,
        categories: ['montaz', 'sprzatanie'],
      };

      service.findByUserId.mockResolvedValue(mockProfile);
      service.update.mockResolvedValue(updatedProfile);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(result.categories).toEqual(['montaz', 'sprzatanie']);
    });

    it('should update service radius', async () => {
      const updateDto = { serviceRadiusKm: 25 };
      const updatedProfile = { ...mockProfile, serviceRadiusKm: 25 };

      service.findByUserId.mockResolvedValue(mockProfile);
      service.update.mockResolvedValue(updatedProfile);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(result.serviceRadiusKm).toBe(25);
    });

    it('should create profile before update if not exists', async () => {
      const updateDto = { bio: 'New bio' };

      service.findByUserId.mockResolvedValue(null);
      service.create.mockResolvedValue(mockProfile);
      service.update.mockResolvedValue({ ...mockProfile, bio: 'New bio' });

      await controller.updateProfile(mockRequest as any, updateDto);

      expect(service.create).toHaveBeenCalledWith('user-123');
      expect(service.update).toHaveBeenCalledWith('user-123', updateDto);
    });
  });

  describe('PUT /contractor/availability', () => {
    it('should set contractor online', async () => {
      const verifiedProfile = {
        ...mockProfile,
        kycStatus: KycStatus.VERIFIED,
        isOnline: true,
      };
      service.setAvailability.mockResolvedValue(verifiedProfile);

      const result = await controller.setAvailability(mockRequest as any, true);

      expect(service.setAvailability).toHaveBeenCalledWith('user-123', true);
      expect(result.isOnline).toBe(true);
    });

    it('should set contractor offline', async () => {
      const offlineProfile = { ...mockProfile, isOnline: false };
      service.setAvailability.mockResolvedValue(offlineProfile);

      const result = await controller.setAvailability(
        mockRequest as any,
        false,
      );

      expect(result.isOnline).toBe(false);
    });

    it('should throw BadRequestException when going online without KYC', async () => {
      service.setAvailability.mockRejectedValue(
        new BadRequestException(
          'Complete KYC verification before going online',
        ),
      );

      await expect(
        controller.setAvailability(mockRequest as any, true),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('PUT /contractor/location', () => {
    it('should update GPS coordinates', async () => {
      const locationDto = { lat: 52.2297, lng: 21.0122 };
      const updatedProfile = {
        ...mockProfile,
        lastLocationLat: 52.2297,
        lastLocationLng: 21.0122,
        lastLocationAt: new Date(),
      };

      service.updateLocation.mockResolvedValue(updatedProfile);

      const result = await controller.updateLocation(
        mockRequest as any,
        locationDto,
      );

      expect(service.updateLocation).toHaveBeenCalledWith(
        'user-123',
        locationDto,
      );
      expect(result.lastLocationLat).toBe(52.2297);
      expect(result.lastLocationLng).toBe(21.0122);
    });

    it('should throw NotFoundException when profile not found', async () => {
      service.updateLocation.mockRejectedValue(
        new NotFoundException('Contractor profile not found'),
      );

      await expect(
        controller.updateLocation(mockRequest as any, { lat: 52.0, lng: 21.0 }),
      ).rejects.toThrow(NotFoundException);
    });
  });

  describe('POST /contractor/kyc/id', () => {
    it('should submit ID document for verification', async () => {
      const verifiedProfile = { ...mockProfile, kycIdVerified: true };
      service.submitKycId.mockResolvedValue(verifiedProfile);

      const result = await controller.submitKycId(
        mockRequest as any,
        'document-url',
      );

      expect(service.submitKycId).toHaveBeenCalledWith(
        'user-123',
        'document-url',
      );
      expect(result.kycIdVerified).toBe(true);
    });
  });

  describe('POST /contractor/kyc/selfie', () => {
    it('should submit selfie for verification', async () => {
      const verifiedProfile = { ...mockProfile, kycSelfieVerified: true };
      service.submitKycSelfie.mockResolvedValue(verifiedProfile);

      const result = await controller.submitKycSelfie(
        mockRequest as any,
        'selfie-url',
      );

      expect(service.submitKycSelfie).toHaveBeenCalledWith(
        'user-123',
        'selfie-url',
      );
      expect(result.kycSelfieVerified).toBe(true);
    });
  });

  describe('POST /contractor/kyc/bank', () => {
    it('should submit bank account for verification', async () => {
      const verifiedProfile = { ...mockProfile, kycBankVerified: true };
      service.submitKycBank.mockResolvedValue(verifiedProfile);

      const result = await controller.submitKycBank(
        mockRequest as any,
        'PL61109010140000071219812874',
        'Test User',
      );

      expect(service.submitKycBank).toHaveBeenCalledWith(
        'user-123',
        'PL61109010140000071219812874',
        'Test User',
      );
      expect(result.kycBankVerified).toBe(true);
    });

    it('should throw BadRequestException for invalid IBAN', async () => {
      service.submitKycBank.mockRejectedValue(
        new BadRequestException('Invalid IBAN format'),
      );

      await expect(
        controller.submitKycBank(mockRequest as any, 'INVALID', 'Test User'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should set overall KYC status to VERIFIED when all checks pass', async () => {
      const fullyVerifiedProfile = {
        ...mockProfile,
        kycIdVerified: true,
        kycSelfieVerified: true,
        kycBankVerified: true,
        kycStatus: KycStatus.VERIFIED,
      };
      service.submitKycBank.mockResolvedValue(fullyVerifiedProfile);

      const result = await controller.submitKycBank(
        mockRequest as any,
        'PL61109010140000071219812874',
        'Test User',
      );

      expect(result.kycStatus).toBe(KycStatus.VERIFIED);
    });
  });
});
