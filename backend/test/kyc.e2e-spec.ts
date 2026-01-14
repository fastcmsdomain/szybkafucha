/**
 * KYC E2E Tests
 * Tests KYC verification flow end-to-end
 */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserType, UserStatus } from '../src/users/entities/user.entity';
import {
  ContractorProfile,
  KycStatus,
} from '../src/contractor/entities/contractor-profile.entity';
import { KycCheck } from '../src/kyc/entities/kyc-check.entity';
import { DocumentType } from '../src/kyc/dto/kyc.dto';

interface AuthResponse {
  accessToken?: string;
  user?: { id?: string };
}

interface KycStatusResponse {
  userId: string;
  overallStatus: string;
  idVerified: boolean;
  selfieVerified: boolean;
  bankVerified: boolean;
  canAcceptTasks: boolean;
}

interface CheckResponse {
  checkId: string;
  status: string;
}

interface BankResponse {
  verified: boolean;
  maskedIban: string;
}

describe('KYC Flow (e2e)', () => {
  let app: INestApplication<App>;
  let userRepository: Repository<User>;
  let profileRepository: Repository<ContractorProfile>;
  let kycCheckRepository: Repository<KycCheck>;
  let authToken: string;
  let testUserId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    userRepository = moduleFixture.get(getRepositoryToken(User));
    profileRepository = moduleFixture.get(
      getRepositoryToken(ContractorProfile),
    );
    kycCheckRepository = moduleFixture.get(getRepositoryToken(KycCheck));

    // Create test contractor user via Google auth
    const authResponse = await request(app.getHttpServer())
      .post('/auth/google')
      .send({
        googleId: 'google-kyc-test-user',
        email: 'kyctest@example.com',
        name: 'KYC Test User',
        userType: 'contractor',
      });

    const authBody = authResponse.body as AuthResponse;
    authToken = authBody.accessToken || '';
    testUserId = authBody.user?.id || '';

    // Create contractor profile if not exists
    const existingProfile = await profileRepository.findOne({
      where: { userId: testUserId },
    });
    if (!existingProfile) {
      const profile = profileRepository.create({
        userId: testUserId,
        bio: 'Test contractor for KYC testing',
        categories: ['paczki', 'zakupy'],
        serviceRadiusKm: 10,
        kycStatus: KycStatus.PENDING,
        kycIdVerified: false,
        kycSelfieVerified: false,
        kycBankVerified: false,
      });
      await profileRepository.save(profile);
    }
  });

  afterAll(async () => {
    // Clean up test data
    if (testUserId) {
      await kycCheckRepository.delete({ userId: testUserId });
      await profileRepository.delete({ userId: testUserId });
      await userRepository.delete({ id: testUserId });
    }
    await app.close();
  });

  describe('GET /contractor/kyc/status', () => {
    it('should return initial KYC status (all unverified)', async () => {
      const response = await request(app.getHttpServer())
        .get('/contractor/kyc/status')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      const body = response.body as KycStatusResponse;
      expect(body.userId).toBe(testUserId);
      expect(body.idVerified).toBe(false);
      expect(body.selfieVerified).toBe(false);
      expect(body.bankVerified).toBe(false);
      expect(body.canAcceptTasks).toBe(false);
    });

    it('should require authentication', () => {
      return request(app.getHttpServer())
        .get('/contractor/kyc/status')
        .expect(401);
    });
  });

  describe('POST /contractor/kyc/id', () => {
    it('should upload ID document and return processing status', async () => {
      const response = await request(app.getHttpServer())
        .post('/contractor/kyc/id')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          documentType: DocumentType.PASSPORT,
          documentFront: 'SGVsbG8gV29ybGQ=', // "Hello World" in base64
          issuingCountry: 'PL',
        })
        .expect(201);

      const body = response.body as CheckResponse;
      expect(body.checkId).toBeDefined();
      expect(body.status).toBe('processing');
    });

    it('should reject invalid document type', () => {
      return request(app.getHttpServer())
        .post('/contractor/kyc/id')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          documentType: 'invalid_type',
          documentFront: 'base64data',
        })
        .expect(400);
    });

    it('should require document front image', () => {
      return request(app.getHttpServer())
        .post('/contractor/kyc/id')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          documentType: DocumentType.PASSPORT,
        })
        .expect(400);
    });
  });

  describe('POST /contractor/kyc/selfie', () => {
    it('should require ID verification first', async () => {
      // Reset profile to unverified state for this test
      await profileRepository.update(
        { userId: testUserId },
        { kycIdVerified: false },
      );

      return request(app.getHttpServer())
        .post('/contractor/kyc/selfie')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          selfieImage: 'base64encodedselfie',
        })
        .expect(400)
        .expect((res) => {
          expect(res.body.message).toContain(
            'ID verification must be completed first',
          );
        });
    });

    it('should accept selfie when ID is verified', async () => {
      // Mark ID as verified for this test
      await profileRepository.update(
        { userId: testUserId },
        { kycIdVerified: true },
      );

      const response = await request(app.getHttpServer())
        .post('/contractor/kyc/selfie')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          selfieImage: 'SGVsbG8gV29ybGQ=', // "Hello World" in base64
        })
        .expect(201);

      const body = response.body as CheckResponse;
      expect(body.checkId).toBeDefined();
      expect(body.status).toBe('processing');
    });
  });

  describe('POST /contractor/kyc/bank', () => {
    it('should verify valid Polish IBAN', async () => {
      // Reset bank verification for this test
      await profileRepository.update(
        { userId: testUserId },
        { kycBankVerified: false },
      );

      const response = await request(app.getHttpServer())
        .post('/contractor/kyc/bank')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          iban: 'PL61109010140000071219812874',
          accountHolderName: 'Test User',
          bankName: 'Test Bank',
        })
        .expect(201);

      const body = response.body as BankResponse;
      expect(body.verified).toBe(true);
      expect(body.maskedIban).toBe('PL61****2874');
    });

    it('should reject invalid IBAN format', () => {
      return request(app.getHttpServer())
        .post('/contractor/kyc/bank')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          iban: 'INVALID',
          accountHolderName: 'Test User',
        })
        .expect(400);
    });

    it('should reject non-Polish IBAN', async () => {
      // Reset bank verification for this test
      await profileRepository.update(
        { userId: testUserId },
        { kycBankVerified: false },
      );

      return request(app.getHttpServer())
        .post('/contractor/kyc/bank')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          iban: 'DE89370400440532013000',
          accountHolderName: 'Test User',
        })
        .expect(400)
        .expect((res) => {
          expect(res.body.message).toContain('Only Polish bank accounts');
        });
    });
  });

  describe('GET /contractor/kyc/sdk-token', () => {
    it('should return SDK token', async () => {
      const response = await request(app.getHttpServer())
        .get('/contractor/kyc/sdk-token')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);

      expect(response.body).toHaveProperty('token');
      expect(response.body.token).toMatch(/^mock_sdk_token_/);
    });

    it('should require authentication', () => {
      return request(app.getHttpServer())
        .get('/contractor/kyc/sdk-token')
        .expect(401);
    });
  });

  describe('POST /webhooks/onfido', () => {
    it('should accept valid webhook payload', async () => {
      const response = await request(app.getHttpServer())
        .post('/webhooks/onfido')
        .set('x-sha2-signature', 'mock-signature')
        .send({
          payload: {
            resource_type: 'check',
            action: 'check.completed',
            object: {
              id: 'nonexistent-check',
              status: 'complete',
              result: 'clear',
              href: 'https://api.onfido.com/v3/checks/123',
            },
          },
        })
        .expect(201);

      expect(response.body).toEqual({ received: true });
    });

    it('should handle missing signature gracefully', async () => {
      // Currently signature verification is disabled in mock mode
      const response = await request(app.getHttpServer())
        .post('/webhooks/onfido')
        .send({
          payload: {
            resource_type: 'check',
            action: 'check.completed',
            object: {
              id: 'test-check',
              status: 'complete',
              result: 'clear',
              href: 'https://api.onfido.com/v3/checks/123',
            },
          },
        })
        .expect(201);

      expect(response.body.received).toBe(true);
    });
  });

  describe('Complete KYC Flow', () => {
    let flowUserId: string;
    let flowAuthToken: string;

    beforeAll(async () => {
      // Create a fresh user for the complete flow test
      const authResponse = await request(app.getHttpServer())
        .post('/auth/google')
        .send({
          googleId: 'google-kyc-flow-test',
          email: 'kycflow@example.com',
          name: 'KYC Flow Test User',
          userType: 'contractor',
        });

      const authBody = authResponse.body as AuthResponse;
      flowAuthToken = authBody.accessToken || '';
      flowUserId = authBody.user?.id || '';

      // Create contractor profile
      const existingProfile = await profileRepository.findOne({
        where: { userId: flowUserId },
      });
      if (!existingProfile) {
        const profile = profileRepository.create({
          userId: flowUserId,
          bio: 'Complete flow test',
          categories: ['paczki'],
          serviceRadiusKm: 5,
          kycStatus: KycStatus.PENDING,
        });
        await profileRepository.save(profile);
      }
    });

    afterAll(async () => {
      if (flowUserId) {
        await kycCheckRepository.delete({ userId: flowUserId });
        await profileRepository.delete({ userId: flowUserId });
        await userRepository.delete({ id: flowUserId });
      }
    });

    it('should complete full KYC flow: ID → Selfie → Bank', async () => {
      // Step 1: Check initial status
      let statusResponse = await request(app.getHttpServer())
        .get('/contractor/kyc/status')
        .set('Authorization', `Bearer ${flowAuthToken}`)
        .expect(200);

      let status = statusResponse.body as KycStatusResponse;
      expect(status.canAcceptTasks).toBe(false);

      // Step 2: Upload ID document
      await request(app.getHttpServer())
        .post('/contractor/kyc/id')
        .set('Authorization', `Bearer ${flowAuthToken}`)
        .send({
          documentType: DocumentType.NATIONAL_ID,
          documentFront: 'SGVsbG8gV29ybGQ=',
          issuingCountry: 'PL',
        })
        .expect(201);

      // Simulate ID verification completion (normally via webhook)
      await profileRepository.update(
        { userId: flowUserId },
        { kycIdVerified: true },
      );

      // Step 3: Upload selfie
      await request(app.getHttpServer())
        .post('/contractor/kyc/selfie')
        .set('Authorization', `Bearer ${flowAuthToken}`)
        .send({
          selfieImage: 'SGVsbG8gV29ybGQ=',
        })
        .expect(201);

      // Simulate selfie verification completion
      await profileRepository.update(
        { userId: flowUserId },
        { kycSelfieVerified: true },
      );

      // Step 4: Verify bank account
      await request(app.getHttpServer())
        .post('/contractor/kyc/bank')
        .set('Authorization', `Bearer ${flowAuthToken}`)
        .send({
          iban: 'PL61109010140000071219812874',
          accountHolderName: 'Flow Test User',
        })
        .expect(201);

      // Step 5: Check final status
      statusResponse = await request(app.getHttpServer())
        .get('/contractor/kyc/status')
        .set('Authorization', `Bearer ${flowAuthToken}`)
        .expect(200);

      status = statusResponse.body as KycStatusResponse;
      expect(status.idVerified).toBe(true);
      expect(status.selfieVerified).toBe(true);
      expect(status.bankVerified).toBe(true);
      expect(status.overallStatus).toBe(KycStatus.VERIFIED);
      expect(status.canAcceptTasks).toBe(true);
    });
  });
});
