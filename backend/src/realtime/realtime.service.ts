/**
 * Realtime Service
 * Business logic for real-time operations
 */
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
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
   * Save chat message to database
   */
  async saveMessage(message: ChatMessage): Promise<Message> {
    const savedMessage = await this.messageRepository.save({
      taskId: message.taskId,
      senderId: message.senderId,
      content: message.content,
      createdAt: message.createdAt,
    });

    this.logger.debug(
      `Message saved for task ${message.taskId} from ${message.senderId}`,
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
   * Mark messages as read
   */
  async markMessagesRead(taskId: string, userId: string): Promise<void> {
    await this.messageRepository
      .createQueryBuilder()
      .update()
      .set({ readAt: new Date() })
      .where('taskId = :taskId', { taskId })
      .andWhere('senderId != :userId', { userId })
      .andWhere('readAt IS NULL')
      .execute();
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

    return task.clientId === userId || task.contractorId === userId;
  }

  /**
   * Get IDs of active tasks for a user (as client or contractor)
   * Used to auto-join task rooms on WebSocket connect.
   */
  async getActiveTaskIdsForUser(userId: string): Promise<string[]> {
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

    return tasks.map((t) => t.id);
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
