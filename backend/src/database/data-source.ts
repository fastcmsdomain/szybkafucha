/**
 * TypeORM DataSource Configuration
 * Used by TypeORM CLI for migrations
 */
import { DataSource } from 'typeorm';
import * as dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Import all entities
import { User } from '../users/entities/user.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { Task } from '../tasks/entities/task.entity';
import { TaskApplication } from '../tasks/entities/task-application.entity';
import { Rating } from '../tasks/entities/rating.entity';
import { Message } from '../messages/entities/message.entity';
import { Payment } from '../payments/entities/payment.entity';
import { KycCheck } from '../kyc/entities/kyc-check.entity';
import { NewsletterSubscriber } from '../newsletter/entities/newsletter-subscriber.entity';

export const AppDataSource = new DataSource({
  type: 'postgres',
  host: process.env.DATABASE_HOST || 'localhost',
  port: parseInt(process.env.DATABASE_PORT || '5432'),
  username: process.env.DATABASE_USERNAME || 'szybkafucha',
  password: process.env.DATABASE_PASSWORD || 'szybkafucha_dev_password',
  database: process.env.DATABASE_NAME || 'szybkafucha',
  entities: [
    User,
    ContractorProfile,
    Task,
    TaskApplication,
    Rating,
    Message,
    Payment,
    KycCheck,
    NewsletterSubscriber,
  ],
  migrations: ['src/database/migrations/*.ts'],
  synchronize: false, // Never use synchronize with migrations
  logging: process.env.NODE_ENV === 'development',
});
