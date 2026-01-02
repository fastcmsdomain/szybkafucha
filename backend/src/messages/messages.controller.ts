/**
 * Messages Controller
 * REST endpoints for chat functionality
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

@Controller('tasks/:taskId/messages')
@UseGuards(JwtAuthGuard)
export class MessagesController {
  constructor(private readonly messagesService: MessagesService) {}

  /**
   * GET /tasks/:taskId/messages
   * Get chat messages for a task
   */
  @Get()
  async getMessages(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Request() req: any,
    @Query('limit', new DefaultValuePipe(50), ParseIntPipe) limit?: number,
    @Query('before') before?: string,
  ): Promise<MessageResponse[]> {
    return this.messagesService.getTaskMessages(taskId, req.user.id, limit, before);
  }

  /**
   * POST /tasks/:taskId/messages
   * Send a message in task chat
   */
  @Post()
  async sendMessage(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Request() req: any,
    @Body() dto: CreateMessageDto,
  ): Promise<MessageResponse> {
    return this.messagesService.sendMessage(taskId, req.user.id, dto);
  }

  /**
   * POST /tasks/:taskId/messages/read
   * Mark all messages as read
   */
  @Post('read')
  async markAsRead(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Request() req: any,
  ): Promise<{ updated: number }> {
    return this.messagesService.markAsRead(taskId, req.user.id);
  }

  /**
   * GET /tasks/:taskId/messages/unread-count
   * Get unread message count
   */
  @Get('unread-count')
  async getUnreadCount(
    @Param('taskId', ParseUUIDPipe) taskId: string,
    @Request() req: any,
  ): Promise<{ count: number }> {
    const count = await this.messagesService.getUnreadCount(taskId, req.user.id);
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
   * Get unread message counts for all user's active tasks
   */
  @Get('unread')
  async getAllUnreadCounts(@Request() req: any): Promise<{ taskId: string; count: number }[]> {
    return this.messagesService.getAllUnreadCounts(req.user.id);
  }
}
