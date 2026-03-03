/**
 * Messages Controller
 * REST endpoints for 1-to-1 chat functionality
 */
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ParseUUIDPipe,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { MessagesService, MessageResponse } from './messages.service';
import { CreateMessageDto } from './dto/create-message.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';

@Controller('tasks/:taskId/messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  /**
   * GET /tasks/:taskId/messages/:otherUserId
   * Get 1-to-1 conversation messages within a task
   */
  @Get(':otherUserId')
  async getMessages(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Param('otherUserId', ParseUUIDPipe) otherUserId: string,
    @Request() req: AuthenticatedRequest,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit?: number,
    @Query('before') before?: string,
  ): Promise<MessageResponse[]> {
    return this.messagesService.getTaskMessages(
      taskId,
      req.user.id,
      otherUserId,
      limit,
      before,
    );
  }

  /**
   * POST /tasks/:taskId/messages/:otherUserId
   * Send a message to a specific user in task chat
   */
  @Post(':otherUserId')
  async sendMessage(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Param('otherUserId', ParseUUIDPipe) otherUserId: string,
    @Request() req: AuthenticatedRequest,
    @Body() dto: CreateMessageDto,
  ): Promise<MessageResponse> {
    return this.messagesService.sendMessage(
      taskId,
      req.user.id,
      otherUserId,
      dto,
    );
  }

  /**
   * POST /tasks/:taskId/messages/:otherUserId/read
   * Mark conversation messages as read
   */
  @Post(':otherUserId/read')
  async markAsRead(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Param('otherUserId', ParseUUIDPipe) otherUserId: string,
    @Request() req: AuthenticatedRequest,
  ): Promise<{ updated: number }> {
    return this.messagesService.markAsRead(taskId, req.user.id, otherUserId);
  }

  /**
   * GET /tasks/:taskId/messages/:otherUserId/unread-count
   * Get unread message count for a conversation
   */
  @Get(':otherUserId/unread-count')
  async getUnreadCount(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Param('otherUserId', ParseUUIDPipe) otherUserId: string,
    @Request() req: AuthenticatedRequest,
  ): Promise<{ count: number }> {
    const count = await this.messagesService.getUnreadCount(
      taskId,
      req.user.id,
      otherUserId,
    );
    return { count };
  }
}

/**
 * Additional endpoint for getting all unread counts
 */
@Controller('messages')
@UseGuards(JwtAuthGuard)
export class UnreadMessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  /**
   * GET /messages/unread
   * Get unread message counts for all user's active conversations
   */
  @Get('unread')
  async getAllUnreadCounts(
    @Request() req: AuthenticatedRequest,
  ): Promise<{ taskId: string; otherUserId: string; count: number }[]> {
    return this.messagesService.getAllUnreadCounts(req.user.id);
  }
}
