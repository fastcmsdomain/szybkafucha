/**
 * Realtime Gateway
 * WebSocket gateway for real-time communication
 */
import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  OnGatewayConnection,
  OnGatewayDisconnect,
  OnGatewayInit,
  ConnectedSocket,
  MessageBody,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { DefaultEventsMap, Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import {
  RealtimeService,
  LocationUpdate,
  ChatMessage,
  TaskStatusUpdate,
} from './realtime.service';
import { TaskStatus } from '../tasks/entities/task.entity';
import { UserType } from '../users/entities/user.entity';

/** Detects phone number patterns: +48 123 456 789, 0048123456789, 123-456-789, etc. */
const PHONE_NUMBER_REGEX = /(\+?(?:\d[\s\-.()]?){8,}\d)/;

/**
 * Detects digits spread across the message (e.g. "5 1 2 3 4 5 6 7 8").
 * Strips all non-digit characters and checks if 7+ digits remain.
 */
function containsHiddenPhoneNumber(text: string): boolean {
  const digitsOnly = text.replace(/\D/g, '');
  return digitsOnly.length >= 7;
}

/** Detects email addresses */
const EMAIL_REGEX = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/gi;

/** Detects URLs */
const URL_REGEX = /(https?:\/\/|www\.)[^\s]+/gi;

/** Detects @username handles (social media style, min 3 chars after @) */
const AT_HANDLE_REGEX = /(?<!\w)@[a-zA-Z0-9._]{3,}/gi;

/** Blocks social media / messaging platform mentions */
const SOCIAL_MEDIA_REGEX =
  /\b(instagram|facebook|tiktok|linkedin|whatsapp|telegram|signal|snapchat|viber|discord|twitter|youtube|skype|messenger|gg|x\.com)\b/gi;

/** Detects Polish contact-sharing phrases */
const CONTACT_PHRASE_REGEX =
  /\b(napisz (do mnie |)na|mój profil|znajdź mnie|dodaj mnie|zadzwoń (do mnie |)na|mój numer|mój mail|mój email|kontakt do mnie|prywatna wiadomość)\b/gi;

// Events emitted by server
export enum ServerEvent {
  LOCATION_UPDATE = 'location:update',
  TASK_STATUS = 'task:status',
  MESSAGE_NEW = 'message:new',
  MESSAGE_READ = 'message:read',
  USER_ONLINE = 'user:online',
  USER_OFFLINE = 'user:offline',
  ERROR = 'error',
  // Bidding system events
  APPLICATION_NEW = 'application:new',
  APPLICATION_ACCEPTED = 'application:accepted',
  APPLICATION_REJECTED = 'application:rejected',
  APPLICATION_WITHDRAWN = 'application:withdrawn',
  APPLICATION_COUNT = 'application:count',
}

// Events received from client
export enum ClientEvent {
  LOCATION_UPDATE = 'location:update',
  TASK_JOIN = 'task:join',
  TASK_LEAVE = 'task:leave',
  CHAT_JOIN = 'chat:join',
  MESSAGE_SEND = 'message:send',
  MESSAGE_READ = 'message:read',
}

// JWT payload interface
interface JwtPayload {
  sub: string;
  email?: string;
  type?: UserType;
}

type SocketData = {
  userId?: string;
  userType?: UserType;
};

type AuthedSocket = Socket<
  DefaultEventsMap,
  DefaultEventsMap,
  DefaultEventsMap,
  SocketData
>;

type AuthedServer = Server<
  DefaultEventsMap,
  DefaultEventsMap,
  DefaultEventsMap,
  SocketData
>;

@WebSocketGateway({
  cors: {
    origin: '*', // Configure properly in production
    credentials: true,
  },
  namespace: '/realtime',
})
export class RealtimeGateway
  implements OnGatewayInit, OnGatewayConnection, OnGatewayDisconnect
{
  @WebSocketServer()
  server: AuthedServer;

  private readonly logger = new Logger(RealtimeGateway.name);

  constructor(
    private readonly realtimeService: RealtimeService,
    private readonly jwtService: JwtService,
  ) {}

  afterInit(): void {
    this.logger.log('WebSocket Gateway initialized');
  }

  /**
   * Handle new connection
   * Authenticate via JWT token in query or auth header
   */
  handleConnection(client: AuthedSocket): void {
    const token = this.extractToken(client);

    if (!token) {
      this.logger.warn(`Connection rejected: No token provided - ${client.id}`);
      client.emit(ServerEvent.ERROR, { message: 'Authentication required' });
      client.disconnect();
      return;
    }

    try {
      const payload = this.jwtService.verify<JwtPayload>(token);
      const userId = payload.sub;
      const userType = payload.type || UserType.CLIENT;

      // Store user info on socket for later use
      client.data.userId = userId;
      client.data.userType = userType;

      // Register connection
      this.realtimeService.registerConnection(client.id, userId, userType);

      // Auto-join task rooms (for status/application events)
      this.realtimeService
        .getActiveTaskIdsForUser(userId)
        .then(async (taskIds) => {
          for (const taskId of taskIds) {
            await client.join(`task:${taskId}`);
            this.realtimeService.joinTaskRoom(client.id, taskId);
          }
          if (taskIds.length > 0) {
            this.logger.debug(
              `User ${userId} auto-joined ${taskIds.length} task room(s)`,
            );
          }
        })
        .catch((err) => {
          this.logger.error(
            `Failed to auto-join task rooms for ${userId}: ${err}`,
          );
        });

      // Auto-join chat rooms (for 1-to-1 message delivery)
      this.realtimeService
        .getActiveChatRoomsForUser(userId)
        .then(async (chatRooms) => {
          for (const roomName of chatRooms) {
            await client.join(roomName);
          }
          if (chatRooms.length > 0) {
            this.logger.debug(
              `User ${userId} auto-joined ${chatRooms.length} chat room(s)`,
            );
          }
        })
        .catch((err) => {
          this.logger.error(
            `Failed to auto-join chat rooms for ${userId}: ${err}`,
          );
        });

      // Notify others that user is online
      this.server.emit(ServerEvent.USER_ONLINE, { userId, userType });

      this.logger.log(
        `Client connected: ${client.id} (User: ${userId}, Type: ${userType})`,
      );
    } catch {
      this.logger.warn(`Connection rejected: Invalid token - ${client.id}`);
      client.emit(ServerEvent.ERROR, {
        message: 'Invalid authentication token',
      });
      client.disconnect();
    }
  }

  /**
   * Handle disconnection
   */
  handleDisconnect(client: AuthedSocket): void {
    const userId = client.data.userId;
    const userType = client.data.userType;

    if (userId) {
      this.realtimeService.removeConnection(client.id);
      this.server.emit(ServerEvent.USER_OFFLINE, { userId, userType });
    }

    this.logger.log(`Client disconnected: ${client.id}`);
  }

  /**
   * Handle location updates from contractors
   */
  @SubscribeMessage(ClientEvent.LOCATION_UPDATE)
  async handleLocationUpdate(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() data: { latitude: number; longitude: number },
  ): Promise<void> {
    const { userId, userType } = client.data;

    if (!userId || !userType) {
      client.emit(ServerEvent.ERROR, { message: 'Authentication required' });
      client.disconnect();
      return;
    }

    if (userType !== UserType.CONTRACTOR) {
      client.emit(ServerEvent.ERROR, {
        message: 'Only contractors can update location',
      });
      return;
    }

    const locationUpdate: LocationUpdate = {
      userId,
      latitude: data.latitude,
      longitude: data.longitude,
      timestamp: new Date(),
    };

    // Save location
    await this.realtimeService.updateLocation(locationUpdate);

    // Broadcast to task rooms this contractor is in
    this.server.emit(ServerEvent.LOCATION_UPDATE, locationUpdate);

    this.logger.debug(
      `Location update from ${userId}: ${data.latitude}, ${data.longitude}`,
    );
  }

  /**
   * Join a task room to receive task-level updates (status, applications)
   */
  @SubscribeMessage(ClientEvent.TASK_JOIN)
  async handleTaskJoin(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() data: { taskId: string },
  ): Promise<{ success: boolean; error?: string }> {
    const userId = client.data.userId;

    if (!userId) {
      return { success: false, error: 'Authentication required' };
    }

    // Check authorization
    const isAuthorized = await this.realtimeService.isUserAuthorizedForTask(
      userId,
      data.taskId,
    );

    if (!isAuthorized) {
      return { success: false, error: 'Not authorized for this task' };
    }

    // Join task room (for status/application events)
    await client.join(`task:${data.taskId}`);
    this.realtimeService.joinTaskRoom(client.id, data.taskId);

    this.logger.debug(`User ${userId} joined task room ${data.taskId}`);
    return { success: true };
  }

  /**
   * Join a 1-to-1 chat room within a task
   */
  @SubscribeMessage(ClientEvent.CHAT_JOIN)
  async handleChatJoin(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() data: { taskId: string; otherUserId: string },
  ): Promise<{ success: boolean; error?: string }> {
    const userId = client.data.userId;

    if (!userId) {
      return { success: false, error: 'Authentication required' };
    }

    // Check authorization
    const isAuthorized = await this.realtimeService.isUserAuthorizedForTask(
      userId,
      data.taskId,
    );

    if (!isAuthorized) {
      return { success: false, error: 'Not authorized for this task' };
    }

    // Compute deterministic chat room name and join
    const chatRoom = this.realtimeService.getChatRoomName(
      data.taskId,
      userId,
      data.otherUserId,
    );
    await client.join(chatRoom);

    this.logger.debug(
      `User ${userId} joined chat room ${chatRoom} (task: ${data.taskId}, other: ${data.otherUserId})`,
    );
    return { success: true };
  }

  /**
   * Leave a task room
   */
  @SubscribeMessage(ClientEvent.TASK_LEAVE)
  async handleTaskLeave(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() data: { taskId: string },
  ): Promise<{ success: boolean }> {
    const userId = client.data.userId;

    if (!userId) {
      return { success: false };
    }

    await client.leave(`task:${data.taskId}`);
    this.realtimeService.leaveTaskRoom(client.id, data.taskId);

    this.logger.debug(`User ${userId} left task room ${data.taskId}`);
    return { success: true };
  }

  /**
   * Handle sending chat messages (1-to-1)
   */
  @SubscribeMessage(ClientEvent.MESSAGE_SEND)
  async handleMessageSend(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody()
    data: { taskId: string; recipientId: string; content: string },
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    const userId = client.data.userId;

    if (!userId) {
      return { success: false, error: 'Authentication required' };
    }

    if (!data.recipientId) {
      return { success: false, error: 'recipientId is required' };
    }

    // Check authorization
    const isAuthorized = await this.realtimeService.isUserAuthorizedForTask(
      userId,
      data.taskId,
    );

    if (!isAuthorized) {
      return { success: false, error: 'Not authorized for this task' };
    }

    // Block phone numbers in chat (direct pattern + hidden digits)
    if (PHONE_NUMBER_REGEX.test(data.content) || containsHiddenPhoneNumber(data.content)) {
      return {
        success: false,
        error: 'Udostępnianie numerów telefonu w czacie jest niedozwolone.',
      };
    }

    // Block email addresses in chat
    if (EMAIL_REGEX.test(data.content)) {
      return {
        success: false,
        error: 'Udostępnianie adresów email w czacie jest niedozwolone.',
      };
    }

    // Block URLs in chat
    if (URL_REGEX.test(data.content)) {
      return {
        success: false,
        error: 'Udostępnianie linków w czacie jest niedozwolone.',
      };
    }

    // Block @username handles
    if (AT_HANDLE_REGEX.test(data.content)) {
      return {
        success: false,
        error: 'Udostępnianie nazw użytkowników (@handle) w czacie jest niedozwolone.',
      };
    }

    // Block social media / messaging platform mentions
    if (SOCIAL_MEDIA_REGEX.test(data.content)) {
      return {
        success: false,
        error: 'Wspominanie platform społecznościowych w czacie jest niedozwolone.',
      };
    }

    // Block Polish contact-sharing phrases
    if (CONTACT_PHRASE_REGEX.test(data.content)) {
      return {
        success: false,
        error: 'Udostępnianie danych kontaktowych w czacie jest niedozwolone.',
      };
    }

    // Create and save message with recipientId
    const chatMessage: ChatMessage = {
      taskId: data.taskId,
      senderId: userId,
      recipientId: data.recipientId,
      content: data.content,
      createdAt: new Date(),
    };

    const savedMessage = await this.realtimeService.saveMessage(chatMessage);

    // Broadcast to 1-to-1 chat room (only sender + recipient see this)
    const chatRoom = this.realtimeService.getChatRoomName(
      data.taskId,
      userId,
      data.recipientId,
    );
    this.server.to(chatRoom).emit(ServerEvent.MESSAGE_NEW, {
      id: savedMessage.id,
      taskId: data.taskId,
      senderId: userId,
      recipientId: data.recipientId,
      content: data.content,
      createdAt: savedMessage.createdAt,
    });

    this.logger.debug(
      `Message sent in task ${data.taskId} from ${userId} to ${data.recipientId}`,
    );
    return { success: true, messageId: savedMessage.id };
  }

  /**
   * Handle marking messages as read (1-to-1)
   */
  @SubscribeMessage(ClientEvent.MESSAGE_READ)
  async handleMessageRead(
    @ConnectedSocket() client: AuthedSocket,
    @MessageBody() data: { taskId: string; otherUserId: string },
  ): Promise<{ success: boolean }> {
    const userId = client.data.userId;

    if (!userId) {
      return { success: false };
    }

    await this.realtimeService.markMessagesRead(
      data.taskId,
      userId,
      data.otherUserId,
    );

    // Notify the other user via their chat room
    const chatRoom = this.realtimeService.getChatRoomName(
      data.taskId,
      userId,
      data.otherUserId,
    );
    this.server.to(chatRoom).emit(ServerEvent.MESSAGE_READ, {
      taskId: data.taskId,
      readBy: userId,
      readAt: new Date(),
    });

    return { success: true };
  }

  /**
   * Broadcast task status update to task room
   * Called from TasksService when status changes
   */
  broadcastTaskStatus(
    taskId: string,
    status: TaskStatus,
    updatedBy: string,
    clientId?: string,
  ): void {
    const update: TaskStatusUpdate = {
      taskId,
      status,
      updatedAt: new Date(),
      updatedBy,
    };

    // Broadcast to task room
    this.server.to(`task:${taskId}`).emit(ServerEvent.TASK_STATUS, update);

    // Also send directly to client (in case they're not in the task room yet)
    if (clientId) {
      this.sendToUser(clientId, ServerEvent.TASK_STATUS, update);
    }

    this.logger.debug(`Task ${taskId} status broadcast: ${status}`);
  }

  /**
   * Broadcast task status with contractor details
   * Called from TasksService when contractor accepts a task
   */
  broadcastTaskStatusWithContractor(
    taskId: string,
    status: TaskStatus,
    updatedBy: string,
    clientId: string,
    contractor: {
      id: string;
      name: string;
      avatarUrl: string | null;
      rating: number;
      completedTasks: number;
      bio?: string | null;
    },
  ): void {
    const update = {
      taskId,
      status,
      updatedAt: new Date(),
      updatedBy,
      contractor,
    };

    // Broadcast to task room
    this.server.to(`task:${taskId}`).emit(ServerEvent.TASK_STATUS, update);

    // Also send directly to client (critical: client may not be in room yet)
    this.sendToUser(clientId, ServerEvent.TASK_STATUS, update);

    this.logger.debug(
      `Task ${taskId} status broadcast with contractor: ${status} -> ${contractor.name}`,
    );
  }

  /**
   * Send notification to specific user
   */
  sendToUser(userId: string, event: string, data: any): boolean {
    const socketId = this.realtimeService.getSocketForUser(userId);

    if (socketId) {
      this.server.to(socketId).emit(event, data);
      return true;
    }

    return false;
  }

  /**
   * Extract JWT token from socket connection
   */
  private extractToken(client: AuthedSocket): string | null {
    // Try query parameter first
    const queryToken = client.handshake.query?.token;
    if (typeof queryToken === 'string' && queryToken) {
      return queryToken;
    }
    if (
      Array.isArray(queryToken) &&
      typeof queryToken[0] === 'string' &&
      queryToken[0]
    ) {
      return queryToken[0];
    }

    // Try auth header
    const authHeader = client.handshake.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }

    // Try auth object
    const authPayload = client.handshake.auth;
    if (
      authPayload &&
      typeof authPayload === 'object' &&
      'token' in authPayload
    ) {
      const tokenValue = (authPayload as { token?: unknown }).token;
      if (typeof tokenValue === 'string' && tokenValue) {
        return tokenValue;
      }
    }

    return null;
  }

  /**
   * Get server statistics
   */
  getStats(): { connections: number; rooms: number } {
    return {
      connections: this.realtimeService.getActiveConnectionsCount(),
      rooms: this.server.sockets.adapter.rooms.size,
    };
  }
}
