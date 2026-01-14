/**
 * Messages Service
 * Business logic for chat functionality
 */
import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './entities/message.entity';
import { Task } from '../tasks/entities/task.entity';
import { User } from '../users/entities/user.entity';
import { CreateMessageDto } from './dto/create-message.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/constants/notification-templates';

// DTO for message response
export interface MessageResponse {
  id: string;
  taskId: string;
  senderId: string;
  senderName: string | null;
  senderAvatar: string | null;
  content: string;
  readAt: Date | null;
  createdAt: Date;
}

@Injectable()
export class MessagesService {
  private readonly logger = new Logger(MessagesService.name);

  constructor(
    @InjectRepository(Message)
    private readonly messageRepository: Repository<Message>,
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Get messages for a task
   */
  async getTaskMessages(
    taskId: string,
    userId: string,
    limit = 50,
    before?: string,
  ): Promise<MessageResponse[]> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, userId);

    const queryBuilder = this.messageRepository
      .createQueryBuilder('message')
      .leftJoinAndSelect('message.sender', 'sender')
      .where('message.taskId = :taskId', { taskId });

    // Pagination - get messages before a specific message ID
    if (before) {
      const beforeMessage = await this.messageRepository.findOne({
        where: { id: before },
      });
      if (beforeMessage) {
        queryBuilder.andWhere('message.createdAt < :createdAt', {
          createdAt: beforeMessage.createdAt,
        });
      }
    }

    queryBuilder.orderBy('message.createdAt', 'DESC').take(limit);

    const messages = await queryBuilder.getMany();

    // Transform to response format
    return messages.map((msg) => ({
      id: msg.id,
      taskId: msg.taskId,
      senderId: msg.senderId,
      senderName: msg.sender?.name || null,
      senderAvatar: msg.sender?.avatarUrl || null,
      content: msg.content,
      readAt: msg.readAt,
      createdAt: msg.createdAt,
    }));
  }

  /**
   * Send a message in a task chat
   */
  async sendMessage(
    taskId: string,
    senderId: string,
    dto: CreateMessageDto,
  ): Promise<MessageResponse> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, senderId);

    // Create message
    const message = await this.messageRepository.save({
      taskId,
      senderId,
      content: dto.content,
    });

    // Get sender info
    const sender = await this.userRepository.findOne({
      where: { id: senderId },
    });

    this.logger.debug(`Message sent in task ${taskId} by ${senderId}`);

    // Get the task to find the recipient
    const task = await this.taskRepository.findOne({ where: { id: taskId } });
    if (task) {
      // Determine the recipient (the other party in the chat)
      const recipientId =
        task.clientId === senderId ? task.contractorId : task.clientId;
      if (recipientId) {
        // Send push notification to recipient
        const messagePreview =
          dto.content.length > 50
            ? dto.content.substring(0, 50) + '...'
            : dto.content;

        this.notificationsService
          .sendToUser(recipientId, NotificationType.NEW_MESSAGE, {
            senderName: sender?.name || 'Użytkownik',
            messagePreview,
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send NEW_MESSAGE notification: ${err}`,
            ),
          );
      }
    }

    return {
      id: message.id,
      taskId: message.taskId,
      senderId: message.senderId,
      senderName: sender?.name || null,
      senderAvatar: sender?.avatarUrl || null,
      content: message.content,
      readAt: message.readAt,
      createdAt: message.createdAt,
    };
  }

  /**
   * Mark messages as read
   */
  async markAsRead(
    taskId: string,
    userId: string,
  ): Promise<{ updated: number }> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, userId);

    // Mark all unread messages from other users as read
    const result = await this.messageRepository
      .createQueryBuilder()
      .update()
      .set({ readAt: new Date() })
      .where('taskId = :taskId', { taskId })
      .andWhere('senderId != :userId', { userId })
      .andWhere('readAt IS NULL')
      .execute();

    this.logger.debug(
      `Marked ${result.affected} messages as read in task ${taskId}`,
    );

    return { updated: result.affected || 0 };
  }

  /**
   * Get unread message count for a task
   */
  async getUnreadCount(taskId: string, userId: string): Promise<number> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, userId);

    return this.messageRepository.count({
      where: {
        taskId,
        readAt: undefined,
      },
    });
  }

  /**
   * Get all unread counts for a user's active tasks
   */
  async getAllUnreadCounts(
    userId: string,
  ): Promise<{ taskId: string; count: number }[]> {
    // Get tasks where user is client or contractor
    const tasks = await this.taskRepository
      .createQueryBuilder('task')
      .select('task.id')
      .where('task.clientId = :userId OR task.contractorId = :userId', {
        userId,
      })
      .andWhere('task.status NOT IN (:...completedStatuses)', {
        completedStatuses: ['completed', 'cancelled'],
      })
      .getMany();

    const unreadCounts: { taskId: string; count: number }[] = [];

    for (const task of tasks) {
      const count = await this.messageRepository
        .createQueryBuilder('message')
        .where('message.taskId = :taskId', { taskId: task.id })
        .andWhere('message.senderId != :userId', { userId })
        .andWhere('message.readAt IS NULL')
        .getCount();

      if (count > 0) {
        unreadCounts.push({ taskId: task.id, count });
      }
    }

    return unreadCounts;
  }

  /**
   * Verify user has access to task chat
   */
  private async verifyTaskAccess(
    taskId: string,
    userId: string,
  ): Promise<Task> {
    const task = await this.taskRepository.findOne({
      where: { id: taskId },
    });

    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (task.clientId !== userId && task.contractorId !== userId) {
      throw new ForbiddenException(
        'You are not authorized to access this chat',
      );
    }

    return task;
  }
}
