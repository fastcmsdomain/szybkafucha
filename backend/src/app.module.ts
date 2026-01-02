/**
 * App Module
 * Root module for Szybka Fucha backend
 */
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from './app.controller';
import { AppService } from './app.service';

// Feature modules
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { TasksModule } from './tasks/tasks.module';
import { ContractorModule } from './contractor/contractor.module';

// Entities
import { User } from './users/entities/user.entity';
import { ContractorProfile } from './contractor/entities/contractor-profile.entity';
import { Task } from './tasks/entities/task.entity';
import { Rating } from './tasks/entities/rating.entity';
import { Message } from './messages/entities/message.entity';
import { Payment } from './payments/entities/payment.entity';

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
        password: configService.get<string>('DATABASE_PASSWORD', 'szybkafucha_dev_password'),
        database: configService.get<string>('DATABASE_NAME', 'szybkafucha'),
        entities: [User, ContractorProfile, Task, Rating, Message, Payment],
        synchronize: configService.get<string>('NODE_ENV') === 'development', // Auto-sync in dev only
        logging: configService.get<string>('NODE_ENV') === 'development',
      }),
      inject: [ConfigService],
    }),

    // Feature modules
    AuthModule,
    UsersModule,
    TasksModule,
    ContractorModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
