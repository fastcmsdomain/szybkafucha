/**
 * File Storage Service
 * Handles file uploads - currently uses local storage
 * Can be easily swapped for S3/CloudStorage in production
 */
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as fs from 'fs';
import * as path from 'path';
import * as crypto from 'crypto';

export interface UploadedFile {
  fieldname: string;
  originalname: string;
  encoding: string;
  mimetype: string;
  buffer: Buffer;
  size: number;
}

@Injectable()
export class FileStorageService {
  private readonly logger = new Logger(FileStorageService.name);
  private readonly uploadDir: string;
  private readonly baseUrl: string;
  private readonly taskImagesDir: string;
  private readonly taskImagesBaseUrl: string;
  private readonly serverUrl: string;

  constructor(private readonly configService: ConfigService) {
    // Server base URL for constructing full URLs
    this.serverUrl = this.configService.get<string>(
      'SERVER_URL',
      'http://localhost:3000',
    );

    // Default to local uploads directory
    this.uploadDir = this.configService.get<string>(
      'UPLOAD_DIR',
      './uploads/avatars',
    );
    this.baseUrl = this.configService.get<string>(
      'UPLOAD_BASE_URL',
      '/uploads/avatars',
    );

    // Task images directory
    this.taskImagesDir = this.configService.get<string>(
      'TASK_IMAGES_DIR',
      './uploads/tasks',
    );
    this.taskImagesBaseUrl = this.configService.get<string>(
      'TASK_IMAGES_BASE_URL',
      '/uploads/tasks',
    );

    // Ensure upload directories exist
    this.ensureUploadDir();
    this.ensureTaskImagesDir();
  }

  /**
   * Ensure upload directory exists
   */
  private ensureUploadDir(): void {
    if (!fs.existsSync(this.uploadDir)) {
      fs.mkdirSync(this.uploadDir, { recursive: true });
      this.logger.log(`Created upload directory: ${this.uploadDir}`);
    }
  }

  /**
   * Ensure task images directory exists
   */
  private ensureTaskImagesDir(): void {
    if (!fs.existsSync(this.taskImagesDir)) {
      fs.mkdirSync(this.taskImagesDir, { recursive: true });
      this.logger.log(`Created task images directory: ${this.taskImagesDir}`);
    }
  }

  /**
   * Upload avatar file
   * Returns the public URL of the uploaded file
   */
  async uploadAvatar(file: UploadedFile, userId: string): Promise<string> {
    // Validate file
    if (!file || !file.buffer) {
      throw new BadRequestException('No file provided');
    }

    // Get file extension from mimetype
    const extension = this.getExtensionFromMimetype(file.mimetype);
    if (!extension) {
      throw new BadRequestException(
        'Invalid file type. Allowed: JPEG, PNG, WebP',
      );
    }

    // Generate unique filename
    const filename = `${userId}-${crypto.randomUUID()}${extension}`;
    const filepath = path.join(this.uploadDir, filename);

    try {
      // Write file to disk
      await fs.promises.writeFile(filepath, file.buffer);
      this.logger.log(`Avatar uploaded: ${filename} for user ${userId}`);

      // Return full public URL (not relative)
      return `${this.serverUrl}${this.baseUrl}/${filename}`;
    } catch (error) {
      this.logger.error(`Failed to upload avatar: ${error}`);
      throw new BadRequestException('Failed to upload file');
    }
  }

  /**
   * Upload task image file
   * Returns the public URL of the uploaded file
   */
  async uploadTaskImage(file: UploadedFile, userId: string): Promise<string> {
    // Validate file
    if (!file || !file.buffer) {
      throw new BadRequestException('No file provided');
    }

    // Get file extension from mimetype
    const extension = this.getExtensionFromMimetype(file.mimetype);
    if (!extension) {
      throw new BadRequestException(
        'Invalid file type. Allowed: JPEG, PNG, WebP',
      );
    }

    // Generate unique filename
    const filename = `task-${userId}-${crypto.randomUUID()}${extension}`;
    const filepath = path.join(this.taskImagesDir, filename);

    try {
      // Write file to disk
      await fs.promises.writeFile(filepath, file.buffer);
      this.logger.log(`Task image uploaded: ${filename} by user ${userId}`);

      // Return full public URL (not relative) for DTO validation
      return `${this.serverUrl}${this.taskImagesBaseUrl}/${filename}`;
    } catch (error) {
      this.logger.error(`Failed to upload task image: ${error}`);
      throw new BadRequestException('Failed to upload file');
    }
  }

  /**
   * Delete avatar file
   */
  async deleteAvatar(avatarUrl: string): Promise<void> {
    if (!avatarUrl) {
      return; // No avatar
    }

    // Handle both full URLs and relative paths
    let filename: string;
    if (avatarUrl.startsWith(this.serverUrl)) {
      // Full URL: extract filename from full URL
      filename = avatarUrl.replace(`${this.serverUrl}${this.baseUrl}/`, '');
    } else if (avatarUrl.startsWith(this.baseUrl)) {
      // Relative path: extract filename
      filename = avatarUrl.replace(`${this.baseUrl}/`, '');
    } else {
      // Not a local file
      return;
    }

    const filepath = path.join(this.uploadDir, filename);

    try {
      if (fs.existsSync(filepath)) {
        await fs.promises.unlink(filepath);
        this.logger.log(`Avatar deleted: ${filename}`);
      }
    } catch (error) {
      this.logger.warn(`Failed to delete avatar: ${error}`);
      // Don't throw - deletion failure is not critical
    }
  }

  /**
   * Get file extension from MIME type
   */
  private getExtensionFromMimetype(mimetype: string): string | null {
    const mimeToExt: Record<string, string> = {
      'image/jpeg': '.jpg',
      'image/png': '.png',
      'image/webp': '.webp',
    };
    return mimeToExt[mimetype] || null;
  }
}
