/**
 * Messages Module
 * REST endpoints for chat functionality
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import {
  MessagesController,
  UnreadMessagesController,
} from './messages.controller';
import { MessagesService } from './messages.service';
import { Message } from './entities/message.entity';
import { Task } from '../tasks/entities/task.entity';
import { User } from '../users/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Message, Task, User])],
  controllers: [MessagesController, UnreadMessagesController],
  providers: [MessagesService],
  exports: [MessagesService],
})
export class MessagesModule {}
