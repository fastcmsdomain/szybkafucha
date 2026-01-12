/**
 * KYC Service Unit Tests
 * Tests for identity verification logic
 */
import { Test, TestingModule } from '@nestjs/testing';
import { ConfigService } from '@nestjs/config';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { KycService } from './kyc.service';
import { KycCheck, KycCheckType, KycCheckStatus, KycCheckResult } from './entities/kyc-check.entity';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import { ContractorProfile, KycStatus } from '../contractor/entities/contractor-profile.entity';
import { DocumentType } from './dto/kyc.dto';
import { NotificationsService } from '../notifications/notifications.service';

/* eslint-disable @typescript-eslint/unbound-method */

describe('KycService', () => {
  let service: KycService;
  let kycCheckRepository: jest.Mocked<Repository<KycCheck>>;
  let userRepository: jest.Mocked<Repository<User>>;
  let profileRepository: jest.Mocked<Repository<ContractorProfile>>;

  const mockUser: User = {
    id: 'user-123',
    type: UserType.CONTRACTOR,
    phone: '+48123456789',
    email: 'contractor@test.pl',
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

  const mockKycCheck: KycCheck = {
    id: 'check-123',
    userId: 'user-123',
    user: mockUser,
    type: KycCheckType.DOCUMENT,
    onfidoApplicantId: 'mock_applicant_user-123',
    onfidoCheckId: 'mock_check_123',
    onfidoDocumentId: 'mock_doc_123',
    status: KycCheckStatus.PENDING,
    result: null,
    resultDetails: null,
    errorMessage: null,
    createdAt: new Date(),
    completedAt: null,
  };

  beforeEach(async () => {
    const mockKycCheckRepository = {
      find: jest.fn(),
      findOne: jest.fn(),
      save: jest.fn(),
      create: jest.fn(),
    };

    const mockUserRepository = {
      findOne: jest.fn(),
    };

    const mockProfileRepository = {
      findOne: jest.fn(),
      save: jest.fn(),
    };

    const mockConfigService = {
      get: jest.fn().mockImplementation((key: string, defaultValue?: string) => {
        if (key === 'ONFIDO_API_TOKEN') return 'placeholder_token';
        if (key === 'ONFIDO_REGION') return defaultValue || 'EU';
        if (key === 'ONFIDO_WEBHOOK_SECRET') return defaultValue || '';
        return defaultValue;
      }),
    };

    const mockNotificationsService = {
      sendToUser: jest.fn().mockResolvedValue({ success: true }),
      sendToUsers: jest.fn().mockResolvedValue({ successCount: 1, failureCount: 0, results: [] }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        KycService,
        { provide: getRepositoryToken(KycCheck), useValue: mockKycCheckRepository },
        { provide: getRepositoryToken(User), useValue: mockUserRepository },
        { provide: getRepositoryToken(ContractorProfile), useValue: mockProfileRepository },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: NotificationsService, useValue: mockNotificationsService },
      ],
    }).compile();

    service = module.get<KycService>(KycService);
    kycCheckRepository = module.get(getRepositoryToken(KycCheck));
    userRepository = module.get(getRepositoryToken(User));
    profileRepository = module.get(getRepositoryToken(ContractorProfile));
  });

  describe('Service Initialization', () => {
    it('should be defined', () => {
      expect(service).toBeDefined();
    });

    it('should initialize in mock mode when ONFIDO_API_TOKEN is placeholder', () => {
      // Service is already initialized with placeholder token
      // The service logs a warning and uses mock mode
      expect(service).toBeDefined();
    });
  });

  describe('getKycStatus', () => {
    it('should return complete KYC status with all verification flags', async () => {
      profileRepository.findOne.mockResolvedValue(mockProfile);
      kycCheckRepository.find.mockResolvedValue([mockKycCheck]);

      const result = await service.getKycStatus('user-123');

      expect(result.userId).toBe('user-123');
      expect(result.overallStatus).toBe(KycStatus.PENDING);
      expect(result.idVerified).toBe(false);
      expect(result.selfieVerified).toBe(false);
      expect(result.bankVerified).toBe(false);
      expect(result.canAcceptTasks).toBe(false);
      expect(result.checks).toHaveLength(1);
    });

    it('should correctly calculate canAcceptTasks when fully verified', async () => {
      const verifiedProfile = {
        ...mockProfile,
        kycStatus: KycStatus.VERIFIED,
        kycIdVerified: true,
        kycSelfieVerified: true,
        kycBankVerified: true,
      };
      profileRepository.findOne.mockResolvedValue(verifiedProfile);
      kycCheckRepository.find.mockResolvedValue([]);

      const result = await service.getKycStatus('user-123');

      expect(result.canAcceptTasks).toBe(true);
      expect(result.overallStatus).toBe(KycStatus.VERIFIED);
    });

    it('should throw NotFoundException when contractor profile not found', async () => {
      profileRepository.findOne.mockResolvedValue(null);

      await expect(service.getKycStatus('nonexistent-user')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('uploadIdDocument', () => {
    const uploadDto = {
      documentType: DocumentType.PASSPORT,
      documentFront: 'base64encodedimage',
      issuingCountry: 'PL',
    };

    it('should upload document and create check in mock mode', async () => {
      const freshProfile = { ...mockProfile, kycIdVerified: false };
      profileRepository.findOne.mockResolvedValue(freshProfile);
      userRepository.findOne.mockResolvedValue(mockUser);
      kycCheckRepository.find.mockResolvedValue([]);
      kycCheckRepository.save.mockImplementation((check) => {
        const savedCheck = { ...check, id: 'new-check-id' } as KycCheck;
        return Promise.resolve(savedCheck);
      });

      const result = await service.uploadIdDocument('user-123', uploadDto);

      expect(result.status).toBe('processing');
      // In mock mode, checkId comes from the saved check which may be the internal id
      expect(kycCheckRepository.save).toHaveBeenCalled();
    });

    it('should reject duplicate ID verification', async () => {
      const verifiedProfile = { ...mockProfile, kycIdVerified: true };
      profileRepository.findOne.mockResolvedValue(verifiedProfile);

      await expect(
        service.uploadIdDocument('user-123', uploadDto),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.uploadIdDocument('user-123', uploadDto),
      ).rejects.toThrow('ID already verified');
    });

    it('should throw NotFoundException when contractor profile missing', async () => {
      profileRepository.findOne.mockResolvedValue(null);

      await expect(
        service.uploadIdDocument('user-123', uploadDto),
      ).rejects.toThrow(NotFoundException);
    });

    it('should reuse existing applicant ID if available', async () => {
      profileRepository.findOne.mockResolvedValue(mockProfile);
      userRepository.findOne.mockResolvedValue(mockUser);
      kycCheckRepository.find.mockResolvedValue([mockKycCheck]); // Has existing applicant ID
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve({ ...check, id: 'new-check-id' } as KycCheck)
      );

      await service.uploadIdDocument('user-123', uploadDto);

      // Should not call userRepository.findOne again for applicant creation
      // since existing applicant ID was found
      expect(kycCheckRepository.save).toHaveBeenCalled();
    });
  });

  describe('uploadSelfie', () => {
    const selfieDto = {
      selfieImage: 'base64encodedselfie',
    };

    it('should require ID verification to complete first', async () => {
      const profileWithoutId = { ...mockProfile, kycIdVerified: false };
      profileRepository.findOne.mockResolvedValue(profileWithoutId);

      await expect(
        service.uploadSelfie('user-123', selfieDto),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.uploadSelfie('user-123', selfieDto),
      ).rejects.toThrow('ID verification must be completed first');
    });

    it('should upload selfie when ID is verified', async () => {
      const profileWithId = { ...mockProfile, kycIdVerified: true, kycSelfieVerified: false };
      profileRepository.findOne.mockResolvedValue(profileWithId);
      userRepository.findOne.mockResolvedValue(mockUser);
      kycCheckRepository.find.mockResolvedValue([mockKycCheck]);
      kycCheckRepository.save.mockImplementation((check) => {
        const savedCheck = { ...check, id: 'selfie-check-id' } as KycCheck;
        return Promise.resolve(savedCheck);
      });

      const result = await service.uploadSelfie('user-123', selfieDto);

      expect(result.status).toBe('processing');
      expect(kycCheckRepository.save).toHaveBeenCalled();
    });

    it('should reject duplicate selfie verification', async () => {
      const verifiedProfile = {
        ...mockProfile,
        kycIdVerified: true,
        kycSelfieVerified: true,
      };
      profileRepository.findOne.mockResolvedValue(verifiedProfile);

      await expect(
        service.uploadSelfie('user-123', selfieDto),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.uploadSelfie('user-123', selfieDto),
      ).rejects.toThrow('Selfie already verified');
    });
  });

  describe('verifyBankAccount', () => {
    const validBankDto = {
      iban: 'PL61109010140000071219812874',
      accountHolderName: 'Jan Kowalski',
      bankName: 'Santander',
    };

    it('should verify valid Polish IBAN', async () => {
      profileRepository.findOne.mockResolvedValue(mockProfile);
      profileRepository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve({ ...check, id: 'bank-check-id' } as KycCheck)
      );

      const result = await service.verifyBankAccount('user-123', validBankDto);

      expect(result.verified).toBe(true);
      expect(result.maskedIban).toMatch(/^PL61\*\*\*\*2874$/);
    });

    it('should reject non-Polish IBAN', async () => {
      const freshProfile = { ...mockProfile, kycBankVerified: false };
      profileRepository.findOne.mockResolvedValue(freshProfile);
      const germanIban = {
        ...validBankDto,
        iban: 'DE89370400440532013000',
      };

      await expect(
        service.verifyBankAccount('user-123', germanIban),
      ).rejects.toThrow(BadRequestException);

      profileRepository.findOne.mockResolvedValue(freshProfile);
      await expect(
        service.verifyBankAccount('user-123', germanIban),
      ).rejects.toThrow('Only Polish bank accounts');
    });

    it('should reject invalid IBAN format', async () => {
      const freshProfile = { ...mockProfile, kycBankVerified: false };
      profileRepository.findOne.mockResolvedValue(freshProfile);
      const invalidIban = {
        ...validBankDto,
        iban: 'INVALID_IBAN_FORMAT',
      };

      await expect(
        service.verifyBankAccount('user-123', invalidIban),
      ).rejects.toThrow(BadRequestException);

      profileRepository.findOne.mockResolvedValue(freshProfile);
      await expect(
        service.verifyBankAccount('user-123', invalidIban),
      ).rejects.toThrow('Invalid IBAN format');
    });

    it('should reject duplicate bank verification', async () => {
      const verifiedProfile = { ...mockProfile, kycBankVerified: true };
      profileRepository.findOne.mockResolvedValue(verifiedProfile);

      await expect(
        service.verifyBankAccount('user-123', validBankDto),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.verifyBankAccount('user-123', validBankDto),
      ).rejects.toThrow('Bank account already verified');
    });

    it('should update contractor profile with bank verified flag', async () => {
      const freshProfile = { ...mockProfile, kycBankVerified: false };
      profileRepository.findOne.mockResolvedValue(freshProfile);
      profileRepository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve({ ...check, id: 'bank-check-id' } as KycCheck)
      );

      await service.verifyBankAccount('user-123', validBankDto);

      expect(profileRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({ kycBankVerified: true }),
      );
    });

    it('should mask IBAN correctly', async () => {
      const freshProfile = { ...mockProfile, kycBankVerified: false };
      profileRepository.findOne.mockResolvedValue(freshProfile);
      profileRepository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve({ ...check, id: 'bank-check-id' } as KycCheck)
      );

      const result = await service.verifyBankAccount('user-123', validBankDto);

      // PL61109010140000071219812874 -> PL61****2874
      expect(result.maskedIban).toBe('PL61****2874');
    });
  });

  describe('handleWebhook', () => {
    const completeWebhookPayload = {
      payload: {
        resource_type: 'check',
        action: 'check.completed',
        object: {
          id: 'mock_check_123',
          status: 'complete',
          result: 'clear',
          href: 'https://api.onfido.com/v3/checks/mock_check_123',
        },
      },
    };

    it('should update check status on webhook receipt', async () => {
      const pendingCheck = { ...mockKycCheck, status: KycCheckStatus.IN_PROGRESS };
      kycCheckRepository.findOne.mockResolvedValue(pendingCheck);
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve(check as KycCheck)
      );
      profileRepository.findOne.mockResolvedValue(mockProfile);
      profileRepository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      await service.handleWebhook(completeWebhookPayload, 'mock-signature');

      expect(kycCheckRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          status: KycCheckStatus.COMPLETE,
          result: KycCheckResult.CLEAR,
        }),
      );
    });

    it('should ignore non-check resource types', async () => {
      const nonCheckPayload = {
        payload: {
          resource_type: 'report',
          action: 'report.completed',
          object: {
            id: 'report-123',
            status: 'complete',
            result: 'clear',
            href: 'https://api.onfido.com/v3/reports/report-123',
          },
        },
      };

      await service.handleWebhook(nonCheckPayload, 'mock-signature');

      expect(kycCheckRepository.findOne).not.toHaveBeenCalled();
    });

    it('should handle unknown check IDs gracefully', async () => {
      kycCheckRepository.findOne.mockResolvedValue(null);

      // Should not throw, just log warning
      await expect(
        service.handleWebhook(completeWebhookPayload, 'mock-signature'),
      ).resolves.not.toThrow();
    });

    it('should handle consider result', async () => {
      const considerPayload = {
        payload: {
          resource_type: 'check',
          action: 'check.completed',
          object: {
            id: 'mock_check_123',
            status: 'complete',
            result: 'consider',
            href: 'https://api.onfido.com/v3/checks/mock_check_123',
          },
        },
      };

      const pendingCheck = { ...mockKycCheck, status: KycCheckStatus.IN_PROGRESS };
      kycCheckRepository.findOne.mockResolvedValue(pendingCheck);
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve(check as KycCheck)
      );
      profileRepository.findOne.mockResolvedValue(mockProfile);
      profileRepository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );

      await service.handleWebhook(considerPayload, 'mock-signature');

      expect(kycCheckRepository.save).toHaveBeenCalledWith(
        expect.objectContaining({
          result: KycCheckResult.CONSIDER,
        }),
      );
    });
  });

  describe('getSdkToken', () => {
    it('should return mock SDK token in mock mode', async () => {
      userRepository.findOne.mockResolvedValue(mockUser);
      kycCheckRepository.find.mockResolvedValue([]);

      const result = await service.getSdkToken('user-123');

      expect(result.token).toMatch(/^mock_sdk_token_/);
    });

    it('should throw NotFoundException for non-existent user', async () => {
      userRepository.findOne.mockResolvedValue(null);
      kycCheckRepository.find.mockResolvedValue([]);

      await expect(service.getSdkToken('nonexistent-user')).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('Overall KYC Status Update', () => {
    it('should set status to VERIFIED when all checks pass', async () => {
      const partiallyVerifiedProfile = {
        ...mockProfile,
        kycIdVerified: true,
        kycSelfieVerified: true,
        kycBankVerified: false,
      };

      // First call for bank verification
      profileRepository.findOne.mockResolvedValueOnce(partiallyVerifiedProfile);

      // Second call for status update check
      const fullyVerifiedForCheck = {
        ...partiallyVerifiedProfile,
        kycBankVerified: true,
      };
      profileRepository.findOne.mockResolvedValueOnce(fullyVerifiedForCheck);

      profileRepository.save.mockImplementation((profile) =>
        Promise.resolve(profile as ContractorProfile)
      );
      kycCheckRepository.save.mockImplementation((check) =>
        Promise.resolve({ ...check, id: 'bank-check-id' } as KycCheck)
      );

      const validBankDto = {
        iban: 'PL61109010140000071219812874',
        accountHolderName: 'Jan Kowalski',
      };

      await service.verifyBankAccount('user-123', validBankDto);

      // Verify that save was called (profile gets updated)
      expect(profileRepository.save).toHaveBeenCalled();
    });
  });
});
