/**
 * DTOs for Notification Service
 */
import { IsOptional, IsEnum, IsObject } from 'class-validator';
import { NotificationType } from '../constants/notification-templates';

export class SendNotificationDto {
  @IsEnum(NotificationType)
  type: NotificationType;

  @IsObject()
  @IsOptional()
  data?: Record<string, string | number>;
}

export interface NotificationResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

export interface BatchNotificationResult {
  successCount: number;
  failureCount: number;
  results: NotificationResult[];
}
