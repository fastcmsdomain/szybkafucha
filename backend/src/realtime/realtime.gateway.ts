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
  WsException,
} from '@nestjs/websockets';
import { Logger, UseGuards } from '@nestjs/common';
import { Server, Socket } from 'socket.io';
import { JwtService } from '@nestjs/jwt';
import { RealtimeService, LocationUpdate, ChatMessage, TaskStatusUpdate } from './realtime.service';
import { TaskStatus } from '../tasks/entities/task.entity';

// Events emitted by server
export enum ServerEvent {
  LOCATION_UPDATE = 'location:update',
  TASK_STATUS = 'task:status',
  MESSAGE_NEW = 'message:new',
  MESSAGE_READ = 'message:read',
  USER_ONLINE = 'user:online',
  USER_OFFLINE = 'user:offline',
  ERROR = 'error',
}

// Events received from client
export enum ClientEvent {
  LOCATION_UPDATE = 'location:update',
  TASK_JOIN = 'task:join',
  TASK_LEAVE = 'task:leave',
  MESSAGE_SEND = 'message:send',
  MESSAGE_READ = 'message:read',
}

// JWT payload interface
interface JwtPayload {
  sub: string;
  email?: string;
  type?: 'client' | 'contractor';
}

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
  server: Server;

  private readonly logger = new Logger(RealtimeGateway.name);

  constructor(
    private readonly realtimeService: RealtimeService,
    private readonly jwtService: JwtService,
  ) {}

  afterInit(server: Server): void {
    this.logger.log('WebSocket Gateway initialized');
  }

  /**
   * Handle new connection
   * Authenticate via JWT token in query or auth header
   */
  async handleConnection(client: Socket): Promise<void> {
    try {
      const token = this.extractToken(client);
      
      if (!token) {
        this.logger.warn(`Connection rejected: No token provided - ${client.id}`);
        client.emit(ServerEvent.ERROR, { message: 'Authentication required' });
        client.disconnect();
        return;
      }

      const payload = this.jwtService.verify<JwtPayload>(token);
      const userId = payload.sub;
      const userType = payload.type || 'client';

      // Store user info on socket for later use
      client.data.userId = userId;
      client.data.userType = userType;

      // Register connection
      this.realtimeService.registerConnection(client.id, userId, userType as 'client' | 'contractor');

      // Notify others that user is online
      this.server.emit(ServerEvent.USER_ONLINE, { userId, userType });

      this.logger.log(`Client connected: ${client.id} (User: ${userId}, Type: ${userType})`);
    } catch (error) {
      this.logger.warn(`Connection rejected: Invalid token - ${client.id}`);
      client.emit(ServerEvent.ERROR, { message: 'Invalid authentication token' });
      client.disconnect();
    }
  }

  /**
   * Handle disconnection
   */
  handleDisconnect(client: Socket): void {
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
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { latitude: number; longitude: number },
  ): Promise<void> {
    const userId = client.data.userId;
    const userType = client.data.userType;

    if (userType !== 'contractor') {
      client.emit(ServerEvent.ERROR, { message: 'Only contractors can update location' });
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
    // Get all task rooms and broadcast to those where this contractor is involved
    this.server.emit(ServerEvent.LOCATION_UPDATE, locationUpdate);

    this.logger.debug(`Location update from ${userId}: ${data.latitude}, ${data.longitude}`);
  }

  /**
   * Join a task room to receive updates
   */
  @SubscribeMessage(ClientEvent.TASK_JOIN)
  async handleTaskJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { taskId: string },
  ): Promise<{ success: boolean; error?: string }> {
    const userId = client.data.userId;

    // Check authorization
    const isAuthorized = await this.realtimeService.isUserAuthorizedForTask(userId, data.taskId);
    
    if (!isAuthorized) {
      return { success: false, error: 'Not authorized for this task' };
    }

    // Join room
    client.join(`task:${data.taskId}`);
    this.realtimeService.joinTaskRoom(client.id, data.taskId);

    this.logger.debug(`User ${userId} joined task room ${data.taskId}`);
    return { success: true };
  }

  /**
   * Leave a task room
   */
  @SubscribeMessage(ClientEvent.TASK_LEAVE)
  handleTaskLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { taskId: string },
  ): { success: boolean } {
    client.leave(`task:${data.taskId}`);
    this.realtimeService.leaveTaskRoom(client.id, data.taskId);

    this.logger.debug(`User ${client.data.userId} left task room ${data.taskId}`);
    return { success: true };
  }

  /**
   * Handle sending chat messages
   */
  @SubscribeMessage(ClientEvent.MESSAGE_SEND)
  async handleMessageSend(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { taskId: string; content: string },
  ): Promise<{ success: boolean; messageId?: string; error?: string }> {
    const userId = client.data.userId;

    // Check authorization
    const isAuthorized = await this.realtimeService.isUserAuthorizedForTask(userId, data.taskId);
    
    if (!isAuthorized) {
      return { success: false, error: 'Not authorized for this task' };
    }

    // Create and save message
    const chatMessage: ChatMessage = {
      taskId: data.taskId,
      senderId: userId,
      content: data.content,
      createdAt: new Date(),
    };

    const savedMessage = await this.realtimeService.saveMessage(chatMessage);

    // Broadcast to task room
    this.server.to(`task:${data.taskId}`).emit(ServerEvent.MESSAGE_NEW, {
      id: savedMessage.id,
      taskId: data.taskId,
      senderId: userId,
      content: data.content,
      createdAt: savedMessage.createdAt,
    });

    this.logger.debug(`Message sent in task ${data.taskId} by ${userId}`);
    return { success: true, messageId: savedMessage.id };
  }

  /**
   * Handle marking messages as read
   */
  @SubscribeMessage(ClientEvent.MESSAGE_READ)
  async handleMessageRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { taskId: string },
  ): Promise<{ success: boolean }> {
    const userId = client.data.userId;

    await this.realtimeService.markMessagesRead(data.taskId, userId);

    // Notify other users in the task room
    this.server.to(`task:${data.taskId}`).emit(ServerEvent.MESSAGE_READ, {
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
  broadcastTaskStatus(taskId: string, status: TaskStatus, updatedBy: string): void {
    const update: TaskStatusUpdate = {
      taskId,
      status,
      updatedAt: new Date(),
      updatedBy,
    };

    this.server.to(`task:${taskId}`).emit(ServerEvent.TASK_STATUS, update);
    this.logger.debug(`Task ${taskId} status broadcast: ${status}`);
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
  private extractToken(client: Socket): string | null {
    // Try query parameter first
    const queryToken = client.handshake.query.token as string;
    if (queryToken) {
      return queryToken;
    }

    // Try auth header
    const authHeader = client.handshake.headers.authorization;
    if (authHeader?.startsWith('Bearer ')) {
      return authHeader.slice(7);
    }

    // Try auth object
    const authToken = client.handshake.auth?.token;
    if (authToken) {
      return authToken;
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
