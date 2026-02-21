import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import request from 'supertest';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { AppModule } from '../src/app.module';
import { User, UserStatus, UserType } from '../src/users/entities/user.entity';

describe('Users notification preferences (e2e)', () => {
  let app: INestApplication;
  let userRepository: Repository<User>;
  let jwtService: JwtService;

  const testUserId = 'd37bdf1d-5b6b-4a62-8ab8-290f98adf6bd';
  const testUserEmail = 'notif-pref-client-e2e@szybkafucha.test';
  const testUserPhone = '+48701010203';
  let authToken: string;
  jest.setTimeout(30000);

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(
      new ValidationPipe({ whitelist: true, transform: true }),
    );
    await app.init();

    userRepository = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
    jwtService = moduleFixture.get(JwtService);

    await userRepository.delete({ id: testUserId });
    await userRepository.delete({ email: testUserEmail });
    await userRepository.delete({ phone: testUserPhone });

    await userRepository.save({
      id: testUserId,
      types: [UserType.CLIENT],
      email: testUserEmail,
      phone: testUserPhone,
      name: 'Notification Pref Client',
      status: UserStatus.ACTIVE,
      notificationPreferences: {
        messages: false,
      },
    });

    authToken = jwtService.sign({
      sub: testUserId,
      types: [UserType.CLIENT],
    });
  });

  afterAll(async () => {
    if (userRepository) {
      await userRepository.delete({ id: testUserId });
    }
    if (app) {
      await app.close();
    }
  });

  it('returns normalized preferences on GET', async () => {
    const response = await request(app.getHttpServer())
      .get('/users/me/notification-preferences')
      .set('Authorization', `Bearer ${authToken}`)
      .expect(200);

    expect(response.body).toMatchObject({
      messages: false,
      taskUpdates: true,
      payments: true,
      ratingsAndTips: true,
      newNearbyTasks: false,
      kycUpdates: false,
    });
  });

  it('applies partial updates and enforces client role restrictions on PUT', async () => {
    const response = await request(app.getHttpServer())
      .put('/users/me/notification-preferences')
      .set('Authorization', `Bearer ${authToken}`)
      .send({
        payments: false,
        newNearbyTasks: true,
        kycUpdates: true,
      })
      .expect(200);

    expect(response.body).toMatchObject({
      messages: false,
      payments: false,
      newNearbyTasks: false,
      kycUpdates: false,
    });

    const user = await userRepository.findOne({ where: { id: testUserId } });
    expect(user?.notificationPreferences).toMatchObject({
      payments: false,
      newNearbyTasks: false,
      kycUpdates: false,
    });
  });

  it('rejects unauthenticated requests', async () => {
    await request(app.getHttpServer())
      .get('/users/me/notification-preferences')
      .expect(401);
  });
});
