/**
 * Purge Script
 * Standalone script to purge tasks and ratings from the database
 * Usage: npm run purge
 */
import { NestFactory } from '@nestjs/core';
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Task } from '../../tasks/entities/task.entity';
import { Rating } from '../../tasks/entities/rating.entity';
import { PurgeModule } from './purge.module';
import { PurgeService } from './purge.service';

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
        password: configService.get<string>(
          'DATABASE_PASSWORD',
          'szybkafucha_dev_password',
        ),
        database: configService.get<string>('DATABASE_NAME', 'szybkafucha'),
        entities: [Task, Rating],
        synchronize: false, // Never use synchronize in production
      }),
      inject: [ConfigService],
    }),
    PurgeModule,
  ],
})
class PurgeAppModule {}

async function bootstrap() {
  const app = await NestFactory.createApplicationContext(PurgeAppModule);
  const purgeService = app.get(PurgeService);

  try {
    await purgeService.purge();
  } catch (error) {
    console.error('Purge failed:', error);
    process.exit(1);
  } finally {
    await app.close();
  }
}

void bootstrap();
