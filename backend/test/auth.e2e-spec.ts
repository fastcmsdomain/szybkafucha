/**
 * Auth E2E Tests
 * Tests authentication endpoints end-to-end
 */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { App } from 'supertest/types';
import { AppModule } from '../src/app.module';
import { CACHE_MANAGER } from '@nestjs/cache-manager';

describe('AuthController (e2e)', () => {
  let app: INestApplication<App>;
  let cacheManager: any;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();

    cacheManager = moduleFixture.get(CACHE_MANAGER);
  });

  afterAll(async () => {
    await app.close();
  });

  describe('POST /auth/phone/request-otp', () => {
    it('should return success for valid Polish phone number', () => {
      return request(app.getHttpServer())
        .post('/auth/phone/request-otp')
        .send({ phone: '+48123456789' })
        .expect(200)
        .expect((res) => {
          expect(res.body.message).toBe('OTP sent successfully');
          expect(res.body.expiresIn).toBe(300);
        });
    });

    it('should accept phone number without country code', () => {
      return request(app.getHttpServer())
        .post('/auth/phone/request-otp')
        .send({ phone: '987654321' })
        .expect(200)
        .expect((res) => {
          expect(res.body.message).toBe('OTP sent successfully');
        });
    });

    it('should reject request without phone number', () => {
      return request(app.getHttpServer())
        .post('/auth/phone/request-otp')
        .send({})
        .expect(400);
    });
  });

  describe('POST /auth/phone/verify', () => {
    const testPhone = '+48111222333';

    beforeEach(async () => {
      // Pre-populate cache with valid OTP for testing
      await cacheManager.set(
        `otp:${testPhone}`,
        { code: '123456', expiresAt: new Date(Date.now() + 300000) },
        300000,
      );
    });

    afterEach(async () => {
      await cacheManager.del(`otp:${testPhone}`);
    });

    it('should return JWT token for valid OTP', () => {
      return request(app.getHttpServer())
        .post('/auth/phone/verify')
        .send({ phone: testPhone, code: '123456' })
        .expect(200)
        .expect((res) => {
          expect(res.body.accessToken).toBeDefined();
          expect(res.body.user).toBeDefined();
          expect(res.body.user.phone).toBe(testPhone);
        });
    });

    it('should reject invalid OTP code', async () => {
      // Re-populate cache since previous test consumed the OTP
      await cacheManager.set(
        `otp:${testPhone}`,
        { code: '123456', expiresAt: new Date(Date.now() + 300000) },
        300000,
      );

      return request(app.getHttpServer())
        .post('/auth/phone/verify')
        .send({ phone: testPhone, code: '000000' })
        .expect(400)
        .expect((res) => {
          expect(res.body.message).toContain('Invalid OTP');
        });
    });

    it('should reject expired OTP', async () => {
      await cacheManager.set(
        `otp:${testPhone}`,
        { code: '123456', expiresAt: new Date(Date.now() - 60000) },
        300000,
      );

      return request(app.getHttpServer())
        .post('/auth/phone/verify')
        .send({ phone: testPhone, code: '123456' })
        .expect(400)
        .expect((res) => {
          expect(res.body.message).toContain('expired');
        });
    });

    it('should reject request without required fields', () => {
      return request(app.getHttpServer())
        .post('/auth/phone/verify')
        .send({ phone: testPhone })
        .expect(400);
    });
  });

  describe('POST /auth/google', () => {
    it('should authenticate with valid Google credentials', () => {
      return request(app.getHttpServer())
        .post('/auth/google')
        .send({
          googleId: 'google-test-123',
          email: 'testgoogle@example.com',
          name: 'Google Test User',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.accessToken).toBeDefined();
          expect(res.body.user).toBeDefined();
          expect(res.body.user.email).toBe('testgoogle@example.com');
        });
    });

    it('should reject request without googleId', () => {
      return request(app.getHttpServer())
        .post('/auth/google')
        .send({ email: 'test@example.com' })
        .expect(400);
    });

    it('should reject request without email', () => {
      return request(app.getHttpServer())
        .post('/auth/google')
        .send({ googleId: 'google-123' })
        .expect(400);
    });

    it('should accept optional userType parameter', () => {
      return request(app.getHttpServer())
        .post('/auth/google')
        .send({
          googleId: 'google-contractor-123',
          email: 'contractor@example.com',
          name: 'Contractor User',
          userType: 'contractor',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.user.type).toBe('contractor');
        });
    });
  });

  describe('POST /auth/apple', () => {
    it('should authenticate with valid Apple credentials', () => {
      return request(app.getHttpServer())
        .post('/auth/apple')
        .send({
          appleId: 'apple-test-123',
          email: 'testapple@icloud.com',
          name: 'Apple Test User',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.accessToken).toBeDefined();
          expect(res.body.user).toBeDefined();
        });
    });

    it('should authenticate without email (Apple privacy)', () => {
      return request(app.getHttpServer())
        .post('/auth/apple')
        .send({
          appleId: 'apple-private-123',
        })
        .expect(200)
        .expect((res) => {
          expect(res.body.accessToken).toBeDefined();
        });
    });

    it('should reject request without appleId', () => {
      return request(app.getHttpServer())
        .post('/auth/apple')
        .send({ email: 'test@icloud.com' })
        .expect(400);
    });
  });

  describe('POST /auth/logout', () => {
    let authToken: string;

    beforeAll(async () => {
      // Get a valid token first
      const response = await request(app.getHttpServer())
        .post('/auth/google')
        .send({
          googleId: 'google-logout-test',
          email: 'logout@example.com',
          name: 'Logout Test',
        });
      authToken = response.body.accessToken;
    });

    it('should return success for authenticated user', () => {
      return request(app.getHttpServer())
        .post('/auth/logout')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200)
        .expect((res) => {
          expect(res.body.message).toBe('Logged out successfully');
        });
    });

    it('should reject request without authentication', () => {
      return request(app.getHttpServer())
        .post('/auth/logout')
        .expect(401);
    });

    it('should reject request with invalid token', () => {
      return request(app.getHttpServer())
        .post('/auth/logout')
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });
  });

  describe('Protected routes', () => {
    let authToken: string;

    beforeAll(async () => {
      const response = await request(app.getHttpServer())
        .post('/auth/google')
        .send({
          googleId: 'google-protected-test',
          email: 'protected@example.com',
          name: 'Protected Test',
        });
      authToken = response.body.accessToken;
    });

    it('should allow access to protected route with valid token', () => {
      return request(app.getHttpServer())
        .get('/users/me')
        .set('Authorization', `Bearer ${authToken}`)
        .expect(200);
    });

    it('should deny access to protected route without token', () => {
      return request(app.getHttpServer())
        .get('/users/me')
        .expect(401);
    });

    it('should deny access with malformed Authorization header', () => {
      return request(app.getHttpServer())
        .get('/users/me')
        .set('Authorization', 'NotBearer token')
        .expect(401);
    });
  });
});
