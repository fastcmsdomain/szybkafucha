/**
 * KYC Controller Unit Tests
 * Tests for KYC REST endpoints
 */
import { Test, TestingModule } from '@nestjs/testing';
import { KycController, KycWebhookController } from './kyc.controller';
import { KycService } from './kyc.service';
import { DocumentType, KycStatusResponse } from './dto/kyc.dto';
import { KycStatus } from '../contractor/entities/contractor-profile.entity';

describe('KycController', () => {
  let controller: KycController;
  let kycService: jest.Mocked<KycService>;

  const mockRequest = {
    user: { id: 'user-123', type: 'contractor', email: 'test@test.pl' },
  };

  const mockKycStatus: KycStatusResponse = {
    userId: 'user-123',
    overallStatus: KycStatus.PENDING,
    idVerified: false,
    selfieVerified: false,
    bankVerified: false,
    checks: [],
    canAcceptTasks: false,
  };

  beforeEach(async () => {
    const mockKycService = {
      getKycStatus: jest.fn(),
      uploadIdDocument: jest.fn(),
      uploadSelfie: jest.fn(),
      verifyBankAccount: jest.fn(),
      getSdkToken: jest.fn(),
      handleWebhook: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [KycController],
      providers: [{ provide: KycService, useValue: mockKycService }],
    }).compile();

    controller = module.get<KycController>(KycController);
    kycService = module.get<KycService>(KycService) as jest.Mocked<KycService>;
  });

  describe('GET /contractor/kyc/status', () => {
    it('should return KYC status for authenticated user', async () => {
      kycService.getKycStatus.mockResolvedValue(mockKycStatus);

      const result = await controller.getStatus(mockRequest as any);

      expect(kycService.getKycStatus).toHaveBeenCalledWith('user-123');
      expect(result).toEqual(mockKycStatus);
    });

    it('should return verified status when all checks pass', async () => {
      const verifiedStatus: KycStatusResponse = {
        ...mockKycStatus,
        overallStatus: KycStatus.VERIFIED,
        idVerified: true,
        selfieVerified: true,
        bankVerified: true,
        canAcceptTasks: true,
      };
      kycService.getKycStatus.mockResolvedValue(verifiedStatus);

      const result = await controller.getStatus(mockRequest as any);

      expect(result.canAcceptTasks).toBe(true);
      expect(result.overallStatus).toBe(KycStatus.VERIFIED);
    });
  });

  describe('POST /contractor/kyc/id', () => {
    const uploadDto = {
      documentType: DocumentType.PASSPORT,
      documentFront: 'base64encodedimage',
      issuingCountry: 'PL',
    };

    it('should accept valid document upload', async () => {
      const expectedResponse = { checkId: 'check-123', status: 'processing' };
      kycService.uploadIdDocument.mockResolvedValue(expectedResponse);

      const result = await controller.uploadIdDocument(
        mockRequest as any,
        uploadDto,
      );

      expect(kycService.uploadIdDocument).toHaveBeenCalledWith(
        'user-123',
        uploadDto,
      );
      expect(result).toEqual(expectedResponse);
    });

    it('should return check ID on success', async () => {
      kycService.uploadIdDocument.mockResolvedValue({
        checkId: 'new-check-id',
        status: 'processing',
      });

      const result = await controller.uploadIdDocument(
        mockRequest as any,
        uploadDto,
      );

      expect(result.checkId).toBe('new-check-id');
      expect(result.status).toBe('processing');
    });
  });

  describe('POST /contractor/kyc/selfie', () => {
    const selfieDto = {
      selfieImage: 'base64encodedselfie',
    };

    it('should accept valid selfie upload', async () => {
      const expectedResponse = { checkId: 'selfie-check-123', status: 'processing' };
      kycService.uploadSelfie.mockResolvedValue(expectedResponse);

      const result = await controller.uploadSelfie(mockRequest as any, selfieDto);

      expect(kycService.uploadSelfie).toHaveBeenCalledWith('user-123', selfieDto);
      expect(result).toEqual(expectedResponse);
    });
  });

  describe('POST /contractor/kyc/bank', () => {
    const bankDto = {
      iban: 'PL61109010140000071219812874',
      accountHolderName: 'Jan Kowalski',
      bankName: 'Santander',
    };

    it('should accept valid IBAN', async () => {
      const expectedResponse = { verified: true, maskedIban: 'PL61****2874' };
      kycService.verifyBankAccount.mockResolvedValue(expectedResponse);

      const result = await controller.verifyBankAccount(mockRequest as any, bankDto);

      expect(kycService.verifyBankAccount).toHaveBeenCalledWith('user-123', bankDto);
      expect(result.verified).toBe(true);
    });

    it('should return masked IBAN on success', async () => {
      kycService.verifyBankAccount.mockResolvedValue({
        verified: true,
        maskedIban: 'PL61****2874',
      });

      const result = await controller.verifyBankAccount(mockRequest as any, bankDto);

      expect(result.maskedIban).toBe('PL61****2874');
    });
  });

  describe('GET /contractor/kyc/sdk-token', () => {
    it('should return SDK token', async () => {
      kycService.getSdkToken.mockResolvedValue({ token: 'mock_sdk_token_123' });

      const result = await controller.getSdkToken(mockRequest as any);

      expect(kycService.getSdkToken).toHaveBeenCalledWith('user-123');
      expect(result.token).toBe('mock_sdk_token_123');
    });
  });
});

describe('KycWebhookController', () => {
  let controller: KycWebhookController;
  let kycService: jest.Mocked<KycService>;

  beforeEach(async () => {
    const mockKycService = {
      handleWebhook: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [KycWebhookController],
      providers: [{ provide: KycService, useValue: mockKycService }],
    }).compile();

    controller = module.get<KycWebhookController>(KycWebhookController);
    kycService = module.get<KycService>(KycService) as jest.Mocked<KycService>;
  });

  describe('POST /webhooks/onfido', () => {
    const webhookPayload = {
      payload: {
        resource_type: 'check',
        action: 'check.completed',
        object: {
          id: 'check-123',
          status: 'complete',
          result: 'clear',
          href: 'https://api.onfido.com/v3/checks/check-123',
        },
      },
    };

    it('should process valid webhook payload', async () => {
      kycService.handleWebhook.mockResolvedValue(undefined);

      const result = await controller.handleOnfidoWebhook(
        webhookPayload,
        'mock-signature',
      );

      expect(kycService.handleWebhook).toHaveBeenCalledWith(
        webhookPayload,
        'mock-signature',
      );
      expect(result).toEqual({ received: true });
    });

    it('should handle check.completed event', async () => {
      kycService.handleWebhook.mockResolvedValue(undefined);

      await controller.handleOnfidoWebhook(webhookPayload, 'signature-123');

      expect(kycService.handleWebhook).toHaveBeenCalledWith(
        expect.objectContaining({
          payload: expect.objectContaining({
            action: 'check.completed',
          }),
        }),
        'signature-123',
      );
    });

    it('should return received: true after processing', async () => {
      kycService.handleWebhook.mockResolvedValue(undefined);

      const result = await controller.handleOnfidoWebhook(
        webhookPayload,
        'any-signature',
      );

      expect(result.received).toBe(true);
    });
  });
});
