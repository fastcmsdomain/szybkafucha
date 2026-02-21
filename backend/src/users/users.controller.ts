/**
 * Users Controller
 * REST endpoints for user operations
 */
import {
  Controller,
  Get,
  Put,
  Patch,
  Post,
  Delete,
  Body,
  UseGuards,
  Request,
  UseInterceptors,
  UploadedFile,
  BadRequestException,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { UsersService } from './users.service';
import { FileStorageService } from './file-storage.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateUserDto } from './dto/update-user.dto';
import { UpdateUserTypeDto } from './dto/update-user-type.dto';
import { AddRoleDto } from './dto/add-role.dto';
import {
  UploadAvatarResponseDto,
  ALLOWED_AVATAR_MIMETYPES,
  MAX_AVATAR_SIZE,
} from './dto/upload-avatar.dto';
import { NotificationPreferencesDto } from './dto/notification-preferences.dto';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';
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
   * PATCH /users/me/type
   * Updates user type (client to contractor or vice versa)
   * MVP: Disabled for users who already have roles
   */
  @UseGuards(JwtAuthGuard)
  @Patch('me/type')
  async updateUserType(
    @Request() req: AuthenticatedRequest,
    @Body() updateUserTypeDto: UpdateUserTypeDto,
  ) {
    // MVP: Prevent role changes for users who already have roles
    if (req.user.types && req.user.types.length > 0) {
      throw new BadRequestException(
        'Role changes are not allowed in MVP. Please contact support if you need to change your role.',
      );
    }

    // In dual-role architecture, this adds a role rather than replacing it
    return this.usersService.addRole(req.user.id, updateUserTypeDto.type);
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
   * GET /users/me/notification-preferences
   * Returns current push notification preferences.
   */
  @UseGuards(JwtAuthGuard)
  @Get('me/notification-preferences')
  async getNotificationPreferences(
    @Request() req: AuthenticatedRequest,
  ): Promise<NotificationPreferencesDto> {
    return this.usersService.getNotificationPreferences(
      req.user.id,
      req.user.types,
    );
  }

  /**
   * PUT /users/me/notification-preferences
   * Updates push notification preferences.
   */
  @UseGuards(JwtAuthGuard)
  @Put('me/notification-preferences')
  async updateNotificationPreferences(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateNotificationPreferencesDto,
  ): Promise<NotificationPreferencesDto> {
    return this.usersService.updateNotificationPreferences(
      req.user.id,
      dto,
      req.user.types,
    );
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
    const avatarUrl = await this.fileStorageService.uploadAvatar(
      file,
      req.user.id,
    );

    // Update user profile with new avatar URL
    await this.usersService.update(req.user.id, { avatarUrl });

    return {
      avatarUrl,
      message: 'Avatar uploaded successfully',
    };
  }

  /**
   * DELETE /users/me
   * Soft-deletes the authenticated user's account and anonymises PII.
   */
  @UseGuards(JwtAuthGuard)
  @Delete('me')
  @HttpCode(HttpStatus.NO_CONTENT)
  async deleteAccount(@Request() req: AuthenticatedRequest): Promise<void> {
    await this.usersService.deleteAccount(req.user.id);
  }

  /**
   * POST /users/me/add-role
   * Add a role (client or contractor) to the current user
   * MVP: Disabled for users who already have roles
   */
  @UseGuards(JwtAuthGuard)
  @Post('me/add-role')
  async addRole(
    @Request() req: AuthenticatedRequest,
    @Body() addRoleDto: AddRoleDto,
  ) {
    // MVP: Prevent adding roles for users who already have roles
    if (req.user.types && req.user.types.length > 0) {
      throw new BadRequestException(
        'Adding roles is not allowed in MVP. Please contact support if you need to add a role.',
      );
    }

    return this.usersService.addRole(req.user.id, addRoleDto.role);
  }
}
