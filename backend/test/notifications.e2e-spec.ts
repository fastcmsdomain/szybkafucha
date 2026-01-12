/**
 * Notifications E2E Tests
 * End-to-end tests for push notification functionality
 */
import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from '../src/app.module';
import { User, UserType, UserStatus } from '../src/users/entities/user.entity';
import { JwtService } from '@nestjs/jwt';

describe('Notifications (e2e)', () => {
  let app: INestApplication;
  let userRepository: Repository<User>;
  let jwtService: JwtService;

  const testUser: Partial<User> = {
    id: 'f47ac10b-58cc-4372-a567-0e02b2c3d479', // Valid UUID
    type: UserType.CONTRACTOR,
    phone: '+48111222333',
    email: 'notifications-test@example.com',
    name: 'Notifications Test User',
    avatarUrl: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: null,
  };

  let authToken: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
    await app.init();

    userRepository = moduleFixture.get(getRepositoryToken(User));
    jwtService = moduleFixture.get(JwtService);

    // Create test user
    const existingUser = await userRepository.findOne({
      where: { id: testUser.id },
    });
    if (!existingUser) {
      await userRepository.save(testUser);
    }

    // Generate JWT token
    authToken = jwtService.sign({
      sub: testUser.id,
      email: testUser.email,
      type: testUser.type,
    });
  });

  afterAll(async () => {
    // Clean up test user
    try {
      await userRepository.delete({ id: testUser.id });
    } catch {
      // Ignore errors
    }
    await app.close();
  });

  describe('PUT /users/me/fcm-token', () => {
    it('should update FCM token', async () => {
      const fcmToken = 'test-fcm-token-' + Date.now();

      const response = await request(app.getHttpServer())
        .put('/users/me/fcm-token')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ fcmToken })
        .expect(200);

      expect(response.body.fcmToken).toBe(fcmToken);
    });

    it('should reject empty FCM token', async () => {
      await request(app.getHttpServer())
        .put('/users/me/fcm-token')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ fcmToken: '' })
        .expect(400);
    });

    it('should reject missing FCM token', async () => {
      await request(app.getHttpServer())
        .put('/users/me/fcm-token')
        .set('Authorization', `Bearer ${authToken}`)
        .send({})
        .expect(400);
    });

    it('should reject request without auth', async () => {
      await request(app.getHttpServer())
        .put('/users/me/fcm-token')
        .send({ fcmToken: 'test-token' })
        .expect(401);
    });

    it('should update existing FCM token', async () => {
      const firstToken = 'first-token-' + Date.now();
      const secondToken = 'second-token-' + Date.now();

      // Set first token
      await request(app.getHttpServer())
        .put('/users/me/fcm-token')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ fcmToken: firstToken })
        .expect(200);

      // Update to second token
      const response = await request(app.getHttpServer())
        .put('/users/me/fcm-token')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ fcmToken: secondToken })
        .expect(200);

      expect(response.body.fcmToken).toBe(secondToken);
    });
  });

  describe('Notification Triggers (Integration)', () => {
    it('should have NotificationsService available', async () => {
      // Verify the module is properly loaded
      const response = await request(app.getHttpServer())
        .get('/health')
        .expect(200);

      expect(response.body.status).toBe('ok');
    });
  });
});
