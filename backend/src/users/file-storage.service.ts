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

  constructor(private readonly configService: ConfigService) {
    // Default to local uploads directory
    this.uploadDir = this.configService.get<string>('UPLOAD_DIR', './uploads/avatars');
    this.baseUrl = this.configService.get<string>('UPLOAD_BASE_URL', '/uploads/avatars');

    // Ensure upload directory exists
    this.ensureUploadDir();
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
      throw new BadRequestException('Invalid file type. Allowed: JPEG, PNG, WebP');
    }

    // Generate unique filename
    const filename = `${userId}-${crypto.randomUUID()}${extension}`;
    const filepath = path.join(this.uploadDir, filename);

    try {
      // Write file to disk
      await fs.promises.writeFile(filepath, file.buffer);
      this.logger.log(`Avatar uploaded: ${filename} for user ${userId}`);

      // Return public URL
      return `${this.baseUrl}/${filename}`;
    } catch (error) {
      this.logger.error(`Failed to upload avatar: ${error}`);
      throw new BadRequestException('Failed to upload file');
    }
  }

  /**
   * Delete avatar file
   */
  async deleteAvatar(avatarUrl: string): Promise<void> {
    if (!avatarUrl || !avatarUrl.startsWith(this.baseUrl)) {
      return; // Not a local file or no avatar
    }

    const filename = avatarUrl.replace(`${this.baseUrl}/`, '');
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
