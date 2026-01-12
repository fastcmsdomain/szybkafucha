/**
 * Tasks Module
 * Handles task creation, management, and lifecycle
 */
import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Task } from './entities/task.entity';
import { Rating } from './entities/rating.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { TasksService } from './tasks.service';
import { TasksController } from './tasks.controller';
import { UsersModule } from '../users/users.module';
import { ContractorModule } from '../contractor/contractor.module';
import { RealtimeModule } from '../realtime/realtime.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([Task, Rating, ContractorProfile]),
    UsersModule,
    ContractorModule,
    forwardRef(() => RealtimeModule),
  ],
  controllers: [TasksController],
  providers: [TasksService],
  exports: [TasksService],
})
export class TasksModule {}
