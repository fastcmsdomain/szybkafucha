/**
 * Realtime Service
 * Business logic for real-time operations
 */
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
import {
  TaskApplication,
  ApplicationStatus,
} from '../tasks/entities/task-application.entity';
import { Message } from '../messages/entities/message.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { User } from '../users/entities/user.entity';

// Location update payload
export interface LocationUpdate {
  userId: string;
  latitude: number;
  longitude: number;
  timestamp: Date;
}

// Task status update payload
export interface TaskStatusUpdate {
  taskId: string;
  status: TaskStatus;
  updatedAt: Date;
  updatedBy: string;
}

// Chat message payload
export interface ChatMessage {
  id?: string;
  taskId: string;
  senderId: string;
  recipientId: string;
  content: string;
  createdAt: Date;
}

// Active connection tracking
interface ActiveConnection {
  socketId: string;
  userId: string;
  userType: 'client' | 'contractor';
  connectedAt: Date;
}

@Injectable()
export class RealtimeService {
  private readonly logger = new Logger(RealtimeService.name);

  // In-memory storage for active connections and locations
  // In production, use Redis for horizontal scaling
  private activeConnections: Map<string, ActiveConnection> = new Map();
  private userToSocket: Map<string, string> = new Map();
  private contractorLocations: Map<string, LocationUpdate> = new Map();
  private taskRooms: Map<string, Set<string>> = new Map(); // taskId -> Set of socket IDs

  constructor(
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(TaskApplication)
    private readonly taskApplicationRepository: Repository<TaskApplication>,
    @InjectRepository(Message)
    private readonly messageRepository: Repository<Message>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  /**
   * Register a new connection
   */
  registerConnection(
    socketId: string,
    userId: string,
    userType: 'client' | 'contractor',
  ): void {
    const connection: ActiveConnection = {
      socketId,
      userId,
      userType,
      connectedAt: new Date(),
    };

    this.activeConnections.set(socketId, connection);
    this.userToSocket.set(userId, socketId);

    this.logger.log(
      `User ${userId} connected (${userType}) - Socket: ${socketId}`,
    );
  }

  /**
   * Remove a connection
   */
  removeConnection(socketId: string): void {
    const connection = this.activeConnections.get(socketId);

    if (connection) {
      this.userToSocket.delete(connection.userId);
      this.activeConnections.delete(socketId);

      // Remove from all task rooms
      for (const [taskId, sockets] of this.taskRooms.entries()) {
        sockets.delete(socketId);
        if (sockets.size === 0) {
          this.taskRooms.delete(taskId);
        }
      }

      this.logger.log(
        `User ${connection.userId} disconnected - Socket: ${socketId}`,
      );
    }
  }

  /**
   * Join a task room (for real-time updates on a specific task)
   */
  joinTaskRoom(socketId: string, taskId: string): void {
    if (!this.taskRooms.has(taskId)) {
      this.taskRooms.set(taskId, new Set());
    }
    this.taskRooms.get(taskId)!.add(socketId);
    this.logger.debug(`Socket ${socketId} joined task room ${taskId}`);
  }

  /**
   * Leave a task room
   */
  leaveTaskRoom(socketId: string, taskId: string): void {
    const room = this.taskRooms.get(taskId);
    if (room) {
      room.delete(socketId);
      if (room.size === 0) {
        this.taskRooms.delete(taskId);
      }
    }
    this.logger.debug(`Socket ${socketId} left task room ${taskId}`);
  }

  /**
   * Get all sockets in a task room
   */
  getTaskRoomSockets(taskId: string): string[] {
    const room = this.taskRooms.get(taskId);
    return room ? Array.from(room) : [];
  }

  /**
   * Get socket ID for a user
   */
  getSocketForUser(userId: string): string | undefined {
    return this.userToSocket.get(userId);
  }

  /**
   * Update contractor location
   */
  async updateLocation(locationUpdate: LocationUpdate): Promise<void> {
    const { userId, latitude, longitude, timestamp } = locationUpdate;

    // Store in memory for quick access
    this.contractorLocations.set(userId, locationUpdate);

    // Persist to database
    await this.contractorProfileRepository.update(userId, {
      lastLocationLat: latitude,
      lastLocationLng: longitude,
      lastLocationAt: timestamp,
    });

    this.logger.debug(
      `Location updated for contractor ${userId}: ${latitude}, ${longitude}`,
    );
  }

  /**
   * Get contractor's last known location
   */
  getContractorLocation(contractorId: string): LocationUpdate | undefined {
    return this.contractorLocations.get(contractorId);
  }

  /**
   * Get chat room name for a 1-to-1 conversation within a task.
   * Room name is deterministic: sorted user IDs ensure both parties join the same room.
   */
  getChatRoomName(taskId: string, userA: string, userB: string): string {
    const sorted = [userA, userB].sort();
    return `chat:${taskId}:${sorted[0]}:${sorted[1]}`;
  }

  /**
   * Save chat message to database
   */
  async saveMessage(message: ChatMessage): Promise<Message> {
    const savedMessage = await this.messageRepository.save({
      taskId: message.taskId,
      senderId: message.senderId,
      recipientId: message.recipientId,
      content: message.content,
      createdAt: message.createdAt,
    });

    this.logger.debug(
      `Message saved for task ${message.taskId} from ${message.senderId} to ${message.recipientId}`,
    );
    return savedMessage;
  }

  /**
   * Get chat history for a task
   */
  async getTaskMessages(taskId: string, limit = 50): Promise<Message[]> {
    return this.messageRepository.find({
      where: { taskId },
      order: { createdAt: 'DESC' },
      take: limit,
      relations: ['sender'],
    });
  }

  /**
   * Mark messages as read (scoped to 1-to-1 conversation)
   */
  async markMessagesRead(
    taskId: string,
    userId: string,
    otherUserId?: string,
  ): Promise<void> {
    const qb = this.messageRepository
      .createQueryBuilder()
      .update()
      .set({ readAt: new Date() })
      .where('taskId = :taskId', { taskId })
      .andWhere('readAt IS NULL');

    if (otherUserId) {
      // Scope to specific conversation pair
      qb.andWhere('senderId = :otherUserId', { otherUserId }).andWhere(
        'recipientId = :userId',
        { userId },
      );
    } else {
      // Legacy fallback: mark all messages from others
      qb.andWhere('senderId != :userId', { userId });
    }

    await qb.execute();
  }

  /**
   * Check if user is authorized for a task
   */
  async isUserAuthorizedForTask(
    userId: string,
    taskId: string,
  ): Promise<boolean> {
    const task = await this.taskRepository.findOne({
      where: { id: taskId },
      select: ['clientId', 'contractorId'],
    });

    if (!task) {
      return false;
    }

    // Client or assigned contractor always have access
    if (task.clientId === userId || task.contractorId === userId) {
      return true;
    }

    // Applicants with PENDING status also have chat access (room concept)
    const application = await this.taskApplicationRepository.findOne({
      where: {
        taskId,
        contractorId: userId,
        status: ApplicationStatus.PENDING,
      },
    });

    return !!application;
  }

  /**
   * Get IDs of active tasks for a user (as client or contractor)
   * Used to auto-join task rooms on WebSocket connect.
   */
  async getActiveTaskIdsForUser(userId: string): Promise<string[]> {
    // Tasks where user is client or assigned contractor
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

    const taskIds = tasks.map((t) => t.id);

    // Also include tasks where user has a pending application (room concept)
    const applications = await this.taskApplicationRepository.find({
      where: {
        contractorId: userId,
        status: ApplicationStatus.PENDING,
      },
      select: ['taskId'],
    });

    for (const app of applications) {
      if (!taskIds.includes(app.taskId)) {
        taskIds.push(app.taskId);
      }
    }

    return taskIds;
  }

  /**
   * Get active chat room names for a user (for auto-join on connect).
   * Returns deterministic room names for all active 1-to-1 conversations.
   */
  async getActiveChatRoomsForUser(userId: string): Promise<string[]> {
    const roomNames: string[] = [];

    // 1. From existing messages: find distinct conversation pairs in active tasks
    const messageConversations: { taskId: string; otherUserId: string }[] =
      await this.messageRepository
        .createQueryBuilder('msg')
        .select('DISTINCT msg.taskId', 'taskId')
        .addSelect(
          `CASE WHEN msg."senderId" = :userId THEN msg."recipientId" ELSE msg."senderId" END`,
          'otherUserId',
        )
        .innerJoin('msg.task', 'task')
        .where('(msg.senderId = :userId OR msg.recipientId = :userId)', {
          userId,
        })
        .andWhere('msg.recipientId IS NOT NULL')
        .andWhere('task.status NOT IN (:...done)', {
          done: ['completed', 'cancelled'],
        })
        .setParameter('userId', userId)
        .getRawMany();

    for (const conv of messageConversations) {
      if (conv.otherUserId) {
        roomNames.push(
          this.getChatRoomName(conv.taskId, userId, conv.otherUserId),
        );
      }
    }

    // 2. From pending applications: contractor → client
    const contractorApps = await this.taskApplicationRepository
      .createQueryBuilder('app')
      .innerJoinAndSelect('app.task', 'task')
      .where('app.contractorId = :userId', { userId })
      .andWhere('app.status = :status', {
        status: ApplicationStatus.PENDING,
      })
      .getMany();

    for (const app of contractorApps) {
      const room = this.getChatRoomName(app.taskId, userId, app.task.clientId);
      if (!roomNames.includes(room)) {
        roomNames.push(room);
      }
    }

    // 3. For clients: each pending applicant on their tasks
    const clientTasks = await this.taskRepository
      .createQueryBuilder('task')
      .select('task.id')
      .where('task.clientId = :userId', { userId })
      .andWhere('task.status NOT IN (:...done)', {
        done: ['completed', 'cancelled'],
      })
      .getMany();

    if (clientTasks.length > 0) {
      const clientTaskIds = clientTasks.map((t) => t.id);
      const applicantApps = await this.taskApplicationRepository
        .createQueryBuilder('app')
        .where('app.taskId IN (:...taskIds)', { taskIds: clientTaskIds })
        .andWhere('app.status = :status', {
          status: ApplicationStatus.PENDING,
        })
        .getMany();

      for (const app of applicantApps) {
        const room = this.getChatRoomName(app.taskId, userId, app.contractorId);
        if (!roomNames.includes(room)) {
          roomNames.push(room);
        }
      }
    }

    return roomNames;
  }

  /**
   * Get active connections count
   */
  getActiveConnectionsCount(): number {
    return this.activeConnections.size;
  }

  /**
   * Get connection info
   */
  getConnectionInfo(socketId: string): ActiveConnection | undefined {
    return this.activeConnections.get(socketId);
  }

  /**
   * Check if user is online
   */
  isUserOnline(userId: string): boolean {
    return this.userToSocket.has(userId);
  }

  /**
   * Get all online contractors
   */
  getOnlineContractors(): string[] {
    const onlineContractors: string[] = [];
    for (const [, connection] of this.activeConnections.entries()) {
      if (connection.userType === 'contractor') {
        onlineContractors.push(connection.userId);
      }
    }
    return onlineContractors;
  }
}
