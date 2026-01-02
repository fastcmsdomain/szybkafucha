/**
 * Seed Script
 * Standalone script to run database seeding
 * Usage: npm run seed or npm run seed:fresh
 */
import { NestFactory } from '@nestjs/core';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../../users/entities/user.entity';
import { ContractorProfile } from '../../contractor/entities/contractor-profile.entity';
import { Task } from '../../tasks/entities/task.entity';
import { Rating } from '../../tasks/entities/rating.entity';
import { Message } from '../../messages/entities/message.entity';
import { Payment } from '../../payments/entities/payment.entity';
import { SeedModule } from './seed.module';
import { SeedService } from './seed.service';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      envFilePath: '.env',
    }),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => ({
        type: 'postgres',
        host: configService.get<string>('DATABASE_HOST', 'localhost'),
        port: configService.get<number>('DATABASE_PORT', 5432),
        username: configService.get<string>('DATABASE_USERNAME', 'szybkafucha'),
        password: configService.get<string>('DATABASE_PASSWORD', 'szybkafucha_dev_password'),
        database: configService.get<string>('DATABASE_NAME', 'szybkafucha'),
        entities: [User, ContractorProfile, Task, Rating, Message, Payment],
        synchronize: true,
      }),
      inject: [ConfigService],
    }),
    SeedModule,
  ],
})
class SeedAppModule {}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(SeedAppModule);
  const seedService = app.get(SeedService);

  const args = process.argv.slice(2);
  const isFresh = args.includes('--fresh') || args.includes('-f');

  try {
    if (isFresh) {
      await seedService.fresh();
    } else {
      await seedService.seed();
    }
  } catch (error) {
    console.error('Seeding failed:', error);
    process.exit(1);
  } finally {
    await app.close();
  }
}

bootstrap();
