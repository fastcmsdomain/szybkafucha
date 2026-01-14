/**
 * Users Controller Unit Tests
 * Tests for user REST endpoints
 */
import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';
import { FileStorageService } from './file-storage.service';
import { User, UserType, UserStatus } from './entities/user.entity';

describe('UsersController', () => {
  let controller: UsersController;
  let usersService: jest.Mocked<UsersService>;
  let fileStorageService: jest.Mocked<FileStorageService>;

  const mockUser: User = {
    id: 'user-123',
    type: UserType.CLIENT,
    phone: '+48123456789',
    email: 'test@example.com',
    name: 'Test User',
    avatarUrl: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockRequest = {
    user: { id: 'user-123', type: 'client', email: 'test@example.com' },
  };

  beforeEach(async () => {
    const mockUsersService = {
      findByIdOrFail: jest.fn(),
      update: jest.fn(),
    };

    const mockFileStorageService = {
      uploadAvatar: jest.fn(),
      deleteAvatar: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [UsersController],
      providers: [
        { provide: UsersService, useValue: mockUsersService },
        { provide: FileStorageService, useValue: mockFileStorageService },
      ],
    }).compile();

    controller = module.get<UsersController>(UsersController);
    usersService = module.get<UsersService>(
      UsersService,
    ) as jest.Mocked<UsersService>;
    fileStorageService = module.get<FileStorageService>(
      FileStorageService,
    ) as jest.Mocked<FileStorageService>;
  });

  describe('GET /users/me', () => {
    it('should return current user profile', async () => {
      usersService.findByIdOrFail.mockResolvedValue(mockUser);

      const result = await controller.getProfile(mockRequest as any);

      expect(usersService.findByIdOrFail).toHaveBeenCalledWith('user-123');
      expect(result).toEqual(mockUser);
    });

    it('should throw NotFoundException for non-existent user', async () => {
      usersService.findByIdOrFail.mockRejectedValue(
        new NotFoundException('User not found'),
      );

      await expect(controller.getProfile(mockRequest as any)).rejects.toThrow(
        NotFoundException,
      );
    });
  });

  describe('PUT /users/me', () => {
    it('should update user name', async () => {
      const updateDto = { name: 'New Name' };
      const updatedUser = { ...mockUser, name: 'New Name' };
      usersService.update.mockResolvedValue(updatedUser);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(usersService.update).toHaveBeenCalledWith('user-123', updateDto);
      expect(result.name).toBe('New Name');
    });

    it('should update avatar URL', async () => {
      const updateDto = { avatarUrl: 'https://example.com/new-avatar.jpg' };
      const updatedUser = { ...mockUser, avatarUrl: updateDto.avatarUrl };
      usersService.update.mockResolvedValue(updatedUser);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(result.avatarUrl).toBe('https://example.com/new-avatar.jpg');
    });

    it('should update FCM token', async () => {
      const updateDto = { fcmToken: 'new-fcm-token' };
      const updatedUser = { ...mockUser, fcmToken: 'new-fcm-token' };
      usersService.update.mockResolvedValue(updatedUser);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(result.fcmToken).toBe('new-fcm-token');
    });

    it('should handle partial updates', async () => {
      const updateDto = { name: 'Only Name' };
      const updatedUser = { ...mockUser, name: 'Only Name' };
      usersService.update.mockResolvedValue(updatedUser);

      const result = await controller.updateProfile(
        mockRequest as any,
        updateDto,
      );

      expect(usersService.update).toHaveBeenCalledWith('user-123', {
        name: 'Only Name',
      });
      expect(result.avatarUrl).toBeNull(); // unchanged
    });
  });

  describe('POST /users/me/avatar', () => {
    const mockFile = {
      fieldname: 'file',
      originalname: 'avatar.jpg',
      encoding: '7bit',
      mimetype: 'image/jpeg',
      buffer: Buffer.from('fake-image-data'),
      size: 1024,
    };

    it('should upload avatar and return URL', async () => {
      const avatarUrl = '/uploads/avatars/user-123-uuid.jpg';
      usersService.findByIdOrFail.mockResolvedValue(mockUser);
      fileStorageService.uploadAvatar.mockResolvedValue(avatarUrl);
      usersService.update.mockResolvedValue({ ...mockUser, avatarUrl });

      const result = await controller.uploadAvatar(
        mockRequest as any,
        mockFile,
      );

      expect(fileStorageService.uploadAvatar).toHaveBeenCalledWith(
        mockFile,
        'user-123',
      );
      expect(usersService.update).toHaveBeenCalledWith('user-123', {
        avatarUrl,
      });
      expect(result.avatarUrl).toBe(avatarUrl);
      expect(result.message).toBe('Avatar uploaded successfully');
    });

    it('should delete old avatar before uploading new one', async () => {
      const oldAvatarUrl = '/uploads/avatars/old-avatar.jpg';
      const newAvatarUrl = '/uploads/avatars/new-avatar.jpg';
      const userWithAvatar = { ...mockUser, avatarUrl: oldAvatarUrl };

      usersService.findByIdOrFail.mockResolvedValue(userWithAvatar);
      fileStorageService.uploadAvatar.mockResolvedValue(newAvatarUrl);
      usersService.update.mockResolvedValue({
        ...mockUser,
        avatarUrl: newAvatarUrl,
      });

      await controller.uploadAvatar(mockRequest as any, mockFile);

      expect(fileStorageService.deleteAvatar).toHaveBeenCalledWith(
        oldAvatarUrl,
      );
    });

    it('should not delete avatar if user has none', async () => {
      usersService.findByIdOrFail.mockResolvedValue(mockUser); // avatarUrl is null
      fileStorageService.uploadAvatar.mockResolvedValue(
        '/uploads/avatars/new.jpg',
      );
      usersService.update.mockResolvedValue(mockUser);

      await controller.uploadAvatar(mockRequest as any, mockFile);

      expect(fileStorageService.deleteAvatar).not.toHaveBeenCalled();
    });

    it('should throw BadRequestException for missing file', async () => {
      await expect(
        controller.uploadAvatar(mockRequest as any, undefined as any),
      ).rejects.toThrow(BadRequestException);
      await expect(
        controller.uploadAvatar(mockRequest as any, undefined as any),
      ).rejects.toThrow('No file provided');
    });

    it('should throw BadRequestException for invalid file type', async () => {
      const invalidFile = { ...mockFile, mimetype: 'application/pdf' };

      await expect(
        controller.uploadAvatar(mockRequest as any, invalidFile),
      ).rejects.toThrow(BadRequestException);
      await expect(
        controller.uploadAvatar(mockRequest as any, invalidFile),
      ).rejects.toThrow('Invalid file type');
    });

    it('should accept PNG files', async () => {
      const pngFile = { ...mockFile, mimetype: 'image/png' };
      usersService.findByIdOrFail.mockResolvedValue(mockUser);
      fileStorageService.uploadAvatar.mockResolvedValue(
        '/uploads/avatars/avatar.png',
      );
      usersService.update.mockResolvedValue(mockUser);

      const result = await controller.uploadAvatar(mockRequest as any, pngFile);

      expect(result.avatarUrl).toBe('/uploads/avatars/avatar.png');
    });

    it('should accept WebP files', async () => {
      const webpFile = { ...mockFile, mimetype: 'image/webp' };
      usersService.findByIdOrFail.mockResolvedValue(mockUser);
      fileStorageService.uploadAvatar.mockResolvedValue(
        '/uploads/avatars/avatar.webp',
      );
      usersService.update.mockResolvedValue(mockUser);

      const result = await controller.uploadAvatar(
        mockRequest as any,
        webpFile,
      );

      expect(result.avatarUrl).toBe('/uploads/avatars/avatar.webp');
    });

    it('should throw BadRequestException for file too large', async () => {
      const largeFile = { ...mockFile, size: 10 * 1024 * 1024 }; // 10MB

      await expect(
        controller.uploadAvatar(mockRequest as any, largeFile),
      ).rejects.toThrow(BadRequestException);
      await expect(
        controller.uploadAvatar(mockRequest as any, largeFile),
      ).rejects.toThrow('File too large');
    });
  });
});
