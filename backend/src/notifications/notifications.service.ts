/**
 * Notifications Service
 * Handles push notifications via Firebase Cloud Messaging
 * Operates in mock mode when Firebase credentials are not configured
 */
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import * as admin from 'firebase-admin';
import { User } from '../users/entities/user.entity';
import {
  NotificationType,
  NOTIFICATION_TEMPLATES,
  interpolateTemplate,
} from './constants/notification-templates';
import {
  NotificationResult,
  BatchNotificationResult,
} from './dto/send-notification.dto';

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);
  private readonly mockMode: boolean;
  private firebaseApp: admin.app.App | null = null;

  constructor(
    private readonly configService: ConfigService,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {
    const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');

    // Enable mock mode if Firebase is not configured
    this.mockMode = !projectId || projectId === 'placeholder';

    if (this.mockMode) {
      this.logger.warn(
        'Firebase not configured - running in MOCK MODE. Notifications will be logged but not sent.',
      );
    } else {
      this.initializeFirebase();
    }
  }

  /**
   * Initialize Firebase Admin SDK
   */
  private initializeFirebase(): void {
    try {
      const projectId = this.configService.get<string>('FIREBASE_PROJECT_ID');
      const clientEmail = this.configService.get<string>('FIREBASE_CLIENT_EMAIL');
      const privateKey = this.configService.get<string>('FIREBASE_PRIVATE_KEY');

      if (!projectId || !clientEmail || !privateKey) {
        this.logger.error('Missing Firebase credentials');
        return;
      }

      this.firebaseApp = admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          // Replace escaped newlines in private key
          privateKey: privateKey.replace(/\\n/g, '\n'),
        }),
      });

      this.logger.log('Firebase Admin SDK initialized successfully');
    } catch (error) {
      this.logger.error(`Failed to initialize Firebase: ${error}`);
    }
  }

  /**
   * Send notification to a single user by user ID
   */
  async sendToUser(
    userId: string,
    type: NotificationType,
    data: Record<string, string | number> = {},
  ): Promise<NotificationResult> {
    const user = await this.userRepository.findOne({ where: { id: userId } });

    if (!user) {
      return { success: false, error: 'User not found' };
    }

    if (!user.fcmToken) {
      this.logger.debug(`User ${userId} has no FCM token - skipping notification`);
      return { success: false, error: 'No FCM token' };
    }

    return this.sendToToken(user.fcmToken, type, data);
  }

  /**
   * Send notification directly to FCM token
   */
  async sendToToken(
    fcmToken: string,
    type: NotificationType,
    data: Record<string, string | number> = {},
  ): Promise<NotificationResult> {
    const template = NOTIFICATION_TEMPLATES[type];
    if (!template) {
      return { success: false, error: `Unknown notification type: ${type}` };
    }

    const { title, body } = interpolateTemplate(template, data);

    // Mock mode - just log the notification
    if (this.mockMode) {
      this.logger.log(
        `[MOCK] Push notification: ${type}\n` +
        `  Token: ${fcmToken.substring(0, 20)}...\n` +
        `  Title: ${title}\n` +
        `  Body: ${body}`,
      );
      return { success: true, messageId: `mock-${Date.now()}` };
    }

    // Real Firebase send
    if (!this.firebaseApp) {
      return { success: false, error: 'Firebase not initialized' };
    }

    try {
      const message: admin.messaging.Message = {
        token: fcmToken,
        notification: {
          title,
          body,
        },
        data: {
          type,
          ...Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          ),
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'szybkafucha_notifications',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().send(message);
      this.logger.log(`Notification sent: ${response}`);
      return { success: true, messageId: response };
    } catch (error) {
      this.logger.error(`Failed to send notification: ${error}`);
      return { success: false, error: String(error) };
    }
  }

  /**
   * Send notification to multiple users
   */
  async sendToUsers(
    userIds: string[],
    type: NotificationType,
    data: Record<string, string | number> = {},
  ): Promise<BatchNotificationResult> {
    const users = await this.userRepository.find({
      where: { id: In(userIds) },
    });

    const tokens = users
      .filter((u) => u.fcmToken)
      .map((u) => u.fcmToken as string);

    if (tokens.length === 0) {
      return { successCount: 0, failureCount: userIds.length, results: [] };
    }

    return this.sendToTokens(tokens, type, data);
  }

  /**
   * Send notification to multiple FCM tokens
   */
  async sendToTokens(
    fcmTokens: string[],
    type: NotificationType,
    data: Record<string, string | number> = {},
  ): Promise<BatchNotificationResult> {
    const template = NOTIFICATION_TEMPLATES[type];
    if (!template) {
      return {
        successCount: 0,
        failureCount: fcmTokens.length,
        results: fcmTokens.map(() => ({
          success: false,
          error: `Unknown notification type: ${type}`,
        })),
      };
    }

    const { title, body } = interpolateTemplate(template, data);

    // Mock mode - log all notifications
    if (this.mockMode) {
      this.logger.log(
        `[MOCK] Batch push notification: ${type}\n` +
        `  Recipients: ${fcmTokens.length} tokens\n` +
        `  Title: ${title}\n` +
        `  Body: ${body}`,
      );
      return {
        successCount: fcmTokens.length,
        failureCount: 0,
        results: fcmTokens.map(() => ({
          success: true,
          messageId: `mock-${Date.now()}`,
        })),
      };
    }

    // Real Firebase multicast
    if (!this.firebaseApp) {
      return {
        successCount: 0,
        failureCount: fcmTokens.length,
        results: fcmTokens.map(() => ({
          success: false,
          error: 'Firebase not initialized',
        })),
      };
    }

    try {
      const message: admin.messaging.MulticastMessage = {
        tokens: fcmTokens,
        notification: {
          title,
          body,
        },
        data: {
          type,
          ...Object.fromEntries(
            Object.entries(data).map(([k, v]) => [k, String(v)]),
          ),
        },
        android: {
          priority: 'high',
          notification: {
            sound: 'default',
            channelId: 'szybkafucha_notifications',
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      const response = await admin.messaging().sendEachForMulticast(message);

      const results: NotificationResult[] = response.responses.map((r, i) => ({
        success: r.success,
        messageId: r.messageId,
        error: r.error?.message,
      }));

      this.logger.log(
        `Batch notification sent: ${response.successCount}/${fcmTokens.length} succeeded`,
      );

      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
        results,
      };
    } catch (error) {
      this.logger.error(`Failed to send batch notification: ${error}`);
      return {
        successCount: 0,
        failureCount: fcmTokens.length,
        results: fcmTokens.map(() => ({
          success: false,
          error: String(error),
        })),
      };
    }
  }

  /**
   * Check if service is in mock mode
   */
  isMockMode(): boolean {
    return this.mockMode;
  }
}
