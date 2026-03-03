/**
 * Messages Service
 * Business logic for chat functionality (1-to-1 private conversations)
 */
import {
  Injectable,
  Logger,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message } from './entities/message.entity';
import { Task } from '../tasks/entities/task.entity';
import {
  TaskApplication,
  ApplicationStatus,
} from '../tasks/entities/task-application.entity';
import { User } from '../users/entities/user.entity';
import { CreateMessageDto } from './dto/create-message.dto';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/constants/notification-templates';

// MVP Phase 1: Chat moderation regex patterns
/** Detects phone number patterns: +48 123 456 789, 0048123456789, 123-456-789, etc. */
const PHONE_NUMBER_REGEX = /(\+?(?:\d[\s\-.()]?){8,}\d)/;

/** Detects email addresses */
const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/gi;

/** Detects URLs and links */
const URL_REGEX = /(https?:\/\/|www\.)[^\s]+/gi;

/** Flags company/social media mentions (not blocked, just flagged for admin review) */
const COMPANY_FLAG_REGEX =
  /\b(sp\.?\s*z\.?\s*o\.?\s*o|s\.?\s*a\.|firma|spółka|instagram|facebook|tiktok|linkedin|whatsapp|telegram|signal)\b/gi;

/** 5 minutes in milliseconds */
const FIRST_MESSAGE_TIMEOUT_MS = 5 * 60 * 1000;

// DTO for message response
export interface MessageResponse {
  id: string;
  taskId: string;
  senderId: string;
  recipientId: string | null;
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
    @InjectRepository(TaskApplication)
    private readonly taskApplicationRepository: Repository<TaskApplication>,
    private readonly notificationsService: NotificationsService,
  ) {}

  /**
   * Get messages for a 1-to-1 conversation within a task
   */
  async getTaskMessages(
    taskId: string,
    userId: string,
    otherUserId: string,
    limit = 50,
    before?: string,
  ): Promise<MessageResponse[]> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, userId);

    const queryBuilder = this.messageRepository
      .createQueryBuilder('message')
      .leftJoinAndSelect('message.sender', 'sender')
      .where('message.taskId = :taskId', { taskId })
      .andWhere(
        '((message.senderId = :userId AND message.recipientId = :otherUserId) ' +
          'OR (message.senderId = :otherUserId AND message.recipientId = :userId))',
        { userId, otherUserId },
      );

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
      recipientId: msg.recipientId,
      senderName: msg.sender?.name || null,
      senderAvatar: msg.sender?.avatarUrl || null,
      content: msg.content,
      readAt: msg.readAt,
      createdAt: msg.createdAt,
    }));
  }

  /**
   * Send a message in a 1-to-1 task chat
   */
  async sendMessage(
    taskId: string,
    senderId: string,
    recipientId: string,
    dto: CreateMessageDto,
  ): Promise<MessageResponse> {
    // Verify sender is authorized for this task
    await this.verifyTaskAccess(taskId, senderId);

    // MVP Phase 1: Enhanced chat moderation
    if (PHONE_NUMBER_REGEX.test(dto.content)) {
      throw new BadRequestException(
        'Udostępnianie numerów telefonu w czacie jest niedozwolone.',
      );
    }

    if (EMAIL_REGEX.test(dto.content)) {
      throw new BadRequestException(
        'Udostępnianie adresów email w czacie jest niedozwolone.',
      );
    }

    if (URL_REGEX.test(dto.content)) {
      throw new BadRequestException(
        'Udostępnianie linków w czacie jest niedozwolone.',
      );
    }

    // Check for company/social media mentions (flag, don't block)
    const isFlagged = COMPANY_FLAG_REGEX.test(dto.content);

    // Fetch task for timeout check
    const task = await this.taskRepository.findOne({ where: { id: taskId } });

    // MVP Phase 1: 5-minute first message timeout for contractors
    if (task && senderId !== task.clientId) {
      const application = await this.taskApplicationRepository.findOne({
        where: {
          taskId,
          contractorId: senderId,
          status: ApplicationStatus.PENDING,
        },
      });

      if (application && !application.firstMessageSentAt) {
        const timeSinceJoin =
          Date.now() - new Date(application.joinedRoomAt!).getTime();

        if (timeSinceJoin > FIRST_MESSAGE_TIMEOUT_MS) {
          throw new BadRequestException(
            'Minął czas na pierwszą wiadomość (5 min). Twoja aplikacja wygasła.',
          );
        }

        // Record first message timestamp
        application.firstMessageSentAt = new Date();
        await this.taskApplicationRepository.save(application);
      }
    }

    // Create message with recipientId
    const message = await this.messageRepository.save({
      taskId,
      senderId,
      recipientId,
      content: dto.content,
      flagged: isFlagged,
    });

    // Get sender info
    const sender = await this.userRepository.findOne({
      where: { id: senderId },
    });

    this.logger.debug(
      `Message sent in task ${taskId} from ${senderId} to ${recipientId}`,
    );

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

    return {
      id: message.id,
      taskId: message.taskId,
      senderId: message.senderId,
      recipientId: message.recipientId,
      senderName: sender?.name || null,
      senderAvatar: sender?.avatarUrl || null,
      content: message.content,
      readAt: message.readAt,
      createdAt: message.createdAt,
    };
  }

  /**
   * Mark messages as read in a 1-to-1 conversation
   */
  async markAsRead(
    taskId: string,
    userId: string,
    otherUserId: string,
  ): Promise<{ updated: number }> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, userId);

    // Mark messages sent by otherUser to current user as read
    const result = await this.messageRepository
      .createQueryBuilder()
      .update()
      .set({ readAt: new Date() })
      .where('taskId = :taskId', { taskId })
      .andWhere('senderId = :otherUserId', { otherUserId })
      .andWhere('recipientId = :userId', { userId })
      .andWhere('readAt IS NULL')
      .execute();

    this.logger.debug(
      `Marked ${result.affected} messages as read in task ${taskId} (conversation with ${otherUserId})`,
    );

    return { updated: result.affected || 0 };
  }

  /**
   * Get unread message count for a specific conversation
   */
  async getUnreadCount(
    taskId: string,
    userId: string,
    otherUserId: string,
  ): Promise<number> {
    // Verify user is authorized for this task
    await this.verifyTaskAccess(taskId, userId);

    return this.messageRepository
      .createQueryBuilder('message')
      .where('message.taskId = :taskId', { taskId })
      .andWhere('message.senderId = :otherUserId', { otherUserId })
      .andWhere('message.recipientId = :userId', { userId })
      .andWhere('message.readAt IS NULL')
      .getCount();
  }

  /**
   * Get all unread counts for a user's active conversations
   * Returns per-conversation counts: { taskId, otherUserId, count }
   */
  async getAllUnreadCounts(
    userId: string,
  ): Promise<{ taskId: string; otherUserId: string; count: number }[]> {
    const results: { taskId: string; otherUserId: string; count: string }[] =
      await this.messageRepository
        .createQueryBuilder('message')
        .select('message.taskId', 'taskId')
        .addSelect('message.senderId', 'otherUserId')
        .addSelect('COUNT(*)', 'count')
        .innerJoin('message.task', 'task')
        .where('message.recipientId = :userId', { userId })
        .andWhere('message.readAt IS NULL')
        .andWhere('task.status NOT IN (:...done)', {
          done: ['completed', 'cancelled'],
        })
        .groupBy('message.taskId')
        .addGroupBy('message.senderId')
        .getRawMany();

    return results.map((r) => ({
      taskId: r.taskId,
      otherUserId: r.otherUserId,
      count: parseInt(r.count, 10),
    }));
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

    // Client or assigned contractor always have access
    if (task.clientId === userId || task.contractorId === userId) {
      return task;
    }

    // Applicants with PENDING status also have chat access (room concept)
    const application = await this.taskApplicationRepository.findOne({
      where: {
        taskId,
        contractorId: userId,
        status: ApplicationStatus.PENDING,
      },
    });

    if (application) {
      return task;
    }

    throw new ForbiddenException(
      'You are not authorized to access this chat',
    );
  }
}
