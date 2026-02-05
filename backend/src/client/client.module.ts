/**
 * Client Module
 * Handles client-specific operations: profile, ratings aggregation
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Rating } from '../tasks/entities/rating.entity';
import { ClientProfile } from './entities/client-profile.entity';
import { ClientService } from './client.service';
import { ClientController } from './client.controller';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [TypeOrmModule.forFeature([Rating, ClientProfile]), UsersModule],
  controllers: [ClientController],
  providers: [ClientService],
  exports: [ClientService],
})
export class ClientModule {}
