/**
 * App Module
 * Root module for Szybka Fucha backend
 */
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { CacheModule } from '@nestjs/cache-manager';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { ServeStaticModule } from '@nestjs/serve-static';
import { APP_GUARD } from '@nestjs/core';
import { join } from 'path';
import * as redisStore from 'cache-manager-redis-store';
import { AppController } from './app.controller';
import { AppService } from './app.service';

// Feature modules
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { TasksModule } from './tasks/tasks.module';
import { ContractorModule } from './contractor/contractor.module';
import { PaymentsModule } from './payments/payments.module';
import { AdminModule } from './admin/admin.module';
import { RealtimeModule } from './realtime/realtime.module';
import { MessagesModule } from './messages/messages.module';
import { KycModule } from './kyc/kyc.module';
import { NewsletterModule } from './newsletter/newsletter.module';
import { HealthModule } from './health/health.module';
import { NotificationsModule } from './notifications/notifications.module';

// Entities
import { User } from './users/entities/user.entity';
import { ContractorProfile } from './contractor/entities/contractor-profile.entity';
import { Task } from './tasks/entities/task.entity';
import { Rating } from './tasks/entities/rating.entity';
import { Message } from './messages/entities/message.entity';
import { Payment } from './payments/entities/payment.entity';
import { KycCheck } from './kyc/entities/kyc-check.entity';
import { NewsletterSubscriber } from './newsletter/entities/newsletter-subscriber.entity';

@Module({
  imports: [
    // Configuration module - loads .env files
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),

    // TypeORM database connection
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DATABASE_HOST', 'localhost'),
        port: configService.get<number>('DATABASE_PORT', 5432),
        username: configService.get<string>('DATABASE_USERNAME', 'szybkafucha'),
        password: configService.get<string>(
          'DATABASE_PASSWORD',
          'szybkafucha_dev_password',
        ),
        database: configService.get<string>('DATABASE_NAME', 'szybkafucha'),
        entities: [
          User,
          ContractorProfile,
          Task,
          Rating,
          Message,
          Payment,
          KycCheck,
          NewsletterSubscriber,
        ],
        synchronize: configService.get<string>('NODE_ENV') === 'development', // Auto-sync in dev only
        logging: configService.get<string>('NODE_ENV') === 'development',
        // Connection pool configuration to prevent "too many clients" errors
        extra: {
          max: 10, // Maximum number of clients in the pool
          min: 2, // Minimum number of clients in the pool
          idleTimeoutMillis: 30000, // Close idle clients after 30 seconds
          connectionTimeoutMillis: 10000, // Wait 10 seconds for connection
        },
        // Additional connection settings
        retryAttempts: 3,
        retryDelay: 3000,
        autoLoadEntities: false, // Explicit entity loading for better control
        keepConnectionAlive: true, // Prevent connection drops
      }),
      inject: [ConfigService],
    }),

    // Redis cache for OTP storage and session management
    CacheModule.register({
      isGlobal: true, // Make cache available globally
      store: redisStore as any,
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT || '6379'),
      password: process.env.REDIS_PASSWORD || undefined,
      ttl: 300, // Default TTL: 5 minutes (in seconds)
    }),

    // Rate limiting - protect against spam and DoS (configurable via env)
    ThrottlerModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => [
        {
          ttl: parseInt(
            configService.get<string>('THROTTLE_TTL_MS', '60000'),
          ), // default: 60s
          limit: parseInt(
            configService.get<string>('THROTTLE_LIMIT', '50'),
          ), // default: 10 reqs/window
        },
      ],
      inject: [ConfigService],
    }),

    // Serve static files (uploads)
    ServeStaticModule.forRoot({
      rootPath: join(__dirname, '..', 'uploads'),
      serveRoot: '/uploads',
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    TasksModule,
    ContractorModule,
    PaymentsModule,
    AdminModule,
    RealtimeModule,
    MessagesModule,
    KycModule,
    NewsletterModule,
    HealthModule,
    NotificationsModule,
  ],
  controllers: [AppController],
  providers: [
    AppService,
    // Global rate limiting guard
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
