/**
 * Users Controller
 * REST endpoints for user operations
 */
import {
  Controller,
  Get,
  Put,
  Post,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { FileStorageService } from './file-storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateUserDto } from './dto/update-user.dto';
import {
  UploadAvatarResponseDto,
  ALLOWED_AVATAR_MIMETYPES,
  MAX_AVATAR_SIZE,
} from './dto/upload-avatar.dto';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';
import type { UploadedFile as FileType } from './file-storage.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly fileStorageService: FileStorageService,
  ) {}

  /**
   * GET /users/me
   * Returns the current authenticated user's profile
   */
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req: AuthenticatedRequest) {
    return this.usersService.findByIdOrFail(req.user.id);
  }

  /**
   * PUT /users/me
   * Updates the current user's profile (name, avatar)
   */
  @UseGuards(JwtAuthGuard)
  @Put('me')
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.update(req.user.id, updateUserDto);
  }

  /**
   * PUT /users/me/fcm-token
   * Updates FCM token for push notifications
   */
  @UseGuards(JwtAuthGuard)
  @Put('me/fcm-token')
  async updateFcmToken(
    @Request() req: AuthenticatedRequest,
    @Body('fcmToken') fcmToken: string,
  ) {
    if (!fcmToken || typeof fcmToken !== 'string') {
      throw new BadRequestException('FCM token is required');
    }
    return this.usersService.updateFcmToken(req.user.id, fcmToken);
  }

  /**
   * POST /users/me/avatar
   * Uploads avatar image to storage
   * Accepts multipart/form-data with 'file' field
   */
  @UseGuards(JwtAuthGuard)
  @Post('me/avatar')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: {
        fileSize: MAX_AVATAR_SIZE,
      },
    }),
  )
  async uploadAvatar(
    @Request() req: AuthenticatedRequest,
    @UploadedFile() file: FileType,
  ): Promise<UploadAvatarResponseDto> {
    // Validate file exists
    if (!file) {
      throw new BadRequestException('No file provided. Use form field "file".');
    }

    // Validate file type
    if (!ALLOWED_AVATAR_MIMETYPES.includes(file.mimetype)) {
      throw new BadRequestException(
        `Invalid file type: ${file.mimetype}. Allowed: JPEG, PNG, WebP`,
      );
    }

    // Validate file size (double check - multer should handle this)
    if (file.size > MAX_AVATAR_SIZE) {
      throw new BadRequestException(
        `File too large: ${Math.round(file.size / 1024 / 1024)}MB. Max: 5MB`,
      );
    }

    // Get current user to check for existing avatar
    const user = await this.usersService.findByIdOrFail(req.user.id);

    // Delete old avatar if exists
    if (user.avatarUrl) {
      await this.fileStorageService.deleteAvatar(user.avatarUrl);
    }

    // Upload new avatar
    const avatarUrl = await this.fileStorageService.uploadAvatar(file, req.user.id);

    // Update user profile with new avatar URL
    await this.usersService.update(req.user.id, { avatarUrl });

    return {
      avatarUrl,
      message: 'Avatar uploaded successfully',
    };
  }
}
