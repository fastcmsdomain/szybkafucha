/**
 * Auth Service Unit Tests
 */
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';

/* eslint-disable @typescript-eslint/unbound-method */

interface MockCacheManager {
  get: jest.Mock;
  set: jest.Mock;
  del: jest.Mock;
}

describe('AuthService', () => {
  let service: AuthService;
  let usersService: jest.Mocked<UsersService>;
  let jwtService: jest.Mocked<JwtService>;
  let cacheManager: MockCacheManager;

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

  beforeEach(async () => {
    const mockUsersService = {
      findByPhone: jest.fn(),
      findByEmail: jest.fn(),
      findByGoogleId: jest.fn(),
      findByAppleId: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
    };

    const mockJwtService = {
      sign: jest.fn().mockReturnValue('mock-jwt-token'),
    };

    const mockCacheManager = {
      get: jest.fn(),
      set: jest.fn(),
      del: jest.fn(),
    };

    const mockConfigService = {
      get: jest.fn().mockReturnValue(null), // No Twilio credentials for tests
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: CACHE_MANAGER, useValue: mockCacheManager },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
    jwtService = module.get<JwtService>(JwtService);
    cacheManager = module.get<MockCacheManager>(CACHE_MANAGER);
  });

  describe('generateToken', () => {
    it('should generate a valid JWT token', () => {
      const result = service.generateToken(mockUser);

      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: mockUser.id,
        type: mockUser.type,
      });
      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.user.id).toBe(mockUser.id);
      expect(result.user.type).toBe(mockUser.type);
      expect(result.user.name).toBe(mockUser.name);
    });

    it('should not include sensitive fields in user response', () => {
      const result = service.generateToken(mockUser);

      expect(result.user).not.toHaveProperty('googleId');
      expect(result.user).not.toHaveProperty('appleId');
      expect(result.user).not.toHaveProperty('fcmToken');
      expect(result.user).not.toHaveProperty('createdAt');
      expect(result.user).not.toHaveProperty('updatedAt');
    });
  });

  describe('requestPhoneOtp', () => {
    it('should generate and store OTP in cache', async () => {
      const phone = '+48123456789';

      const result = await service.requestPhoneOtp(phone);

      expect(cacheManager.set).toHaveBeenCalled();
      const [cacheKey, otpData] = cacheManager.set.mock.calls[0] as [
        string,
        { code: string; expiresAt: Date },
      ];
      expect(cacheKey).toBe(`otp:${phone}`);
      expect(otpData).toHaveProperty('code');
      expect(otpData.code).toHaveLength(6);
      expect(result.message).toBe('OTP sent successfully');
      expect(result.expiresIn).toBe(300); // 5 minutes
    });

    it('should normalize phone number without country code', async () => {
      const phone = '123456789';

      await service.requestPhoneOtp(phone);

      expect(cacheManager.set).toHaveBeenCalled();
      const [cacheKey] = cacheManager.set.mock.calls[0] as [
        string,
        { code: string; expiresAt: Date },
      ];
      expect(cacheKey).toBe('otp:+48123456789');
    });
  });

  describe('verifyPhoneOtp', () => {
    const phone = '+48123456789';
    const code = '123456';
    const validOtp = { code, expiresAt: new Date(Date.now() + 60000) };

    it('should return JWT token for valid OTP', async () => {
      cacheManager.get.mockResolvedValue(validOtp);
      usersService.findByPhone.mockResolvedValue(mockUser);

      const result = await service.verifyPhoneOtp(phone, code);

      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.user.id).toBe(mockUser.id);
      expect(result.isNewUser).toBe(false);
      expect(cacheManager.del).toHaveBeenCalledWith(`otp:${phone}`);
    });

    it('should create new user if phone not found', async () => {
      cacheManager.get.mockResolvedValue(validOtp);
      usersService.findByPhone.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.verifyPhoneOtp(
        phone,
        code,
        UserType.CONTRACTOR,
      );

      expect(usersService.create).toHaveBeenCalledWith({
        phone,
        type: UserType.CONTRACTOR,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should throw BadRequestException for missing OTP', async () => {
      cacheManager.get.mockResolvedValue(null);

      await expect(service.verifyPhoneOtp(phone, code)).rejects.toThrow(
        BadRequestException,
      );
      await expect(service.verifyPhoneOtp(phone, code)).rejects.toThrow(
        'OTP not found or expired',
      );
    });

    it('should throw BadRequestException for expired OTP', async () => {
      const expiredOtp = { code, expiresAt: new Date(Date.now() - 60000) };
      cacheManager.get.mockResolvedValue(expiredOtp);

      await expect(service.verifyPhoneOtp(phone, code)).rejects.toThrow(
        BadRequestException,
      );
      expect(cacheManager.del).toHaveBeenCalledWith(`otp:${phone}`);
    });

    it('should throw BadRequestException for invalid OTP code', async () => {
      cacheManager.get.mockResolvedValue(validOtp);

      await expect(service.verifyPhoneOtp(phone, 'wrong-code')).rejects.toThrow(
        BadRequestException,
      );
      await expect(service.verifyPhoneOtp(phone, 'wrong-code')).rejects.toThrow(
        'Invalid OTP code',
      );
    });
  });

  describe('authenticateWithGoogle', () => {
    const googleId = 'google-123';
    const email = 'test@gmail.com';
    const name = 'Google User';

    it('should return existing user if Google ID found', async () => {
      const googleUser = { ...mockUser, googleId };
      usersService.findByGoogleId.mockResolvedValue(googleUser);

      const result = await service.authenticateWithGoogle(
        googleId,
        email,
        name,
      );

      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.isNewUser).toBe(false);
      expect(usersService.create).not.toHaveBeenCalled();
    });

    it('should link Google account to existing user with same email', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(mockUser);
      usersService.update.mockResolvedValue({ ...mockUser, googleId });

      const result = await service.authenticateWithGoogle(
        googleId,
        email,
        name,
      );

      expect(usersService.update).toHaveBeenCalledWith(mockUser.id, {
        googleId,
      });
      expect(result.isNewUser).toBe(false);
    });

    it('should create new user if no existing account found', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockUser,
        googleId,
        email,
        name,
      });

      const result = await service.authenticateWithGoogle(
        googleId,
        email,
        name,
        'avatar.jpg',
        UserType.CONTRACTOR,
      );

      expect(usersService.create).toHaveBeenCalledWith({
        googleId,
        email,
        name,
        avatarUrl: 'avatar.jpg',
        type: UserType.CONTRACTOR,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });
  });

  describe('authenticateWithApple', () => {
    const appleId = 'apple-123';
    const email = 'test@icloud.com';
    const name = 'Apple User';

    it('should return existing user if Apple ID found', async () => {
      const appleUser = { ...mockUser, appleId };
      usersService.findByAppleId.mockResolvedValue(appleUser);

      const result = await service.authenticateWithApple(appleId, email, name);

      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.isNewUser).toBe(false);
    });

    it('should link Apple account to existing user with same email', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(mockUser);
      usersService.update.mockResolvedValue({ ...mockUser, appleId });

      const result = await service.authenticateWithApple(appleId, email, name);

      expect(usersService.update).toHaveBeenCalledWith(mockUser.id, {
        appleId,
      });
      expect(result.isNewUser).toBe(false);
    });

    it('should create new user if no existing account found', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockUser,
        appleId,
        email,
        name,
      });

      const result = await service.authenticateWithApple(
        appleId,
        email,
        name,
        UserType.CLIENT,
      );

      expect(usersService.create).toHaveBeenCalledWith({
        appleId,
        email,
        name,
        type: UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should create user without email if not provided', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.create.mockResolvedValue({ ...mockUser, appleId });

      const result = await service.authenticateWithApple(appleId);

      expect(usersService.findByEmail).not.toHaveBeenCalled();
      expect(usersService.create).toHaveBeenCalledWith({
        appleId,
        email: undefined,
        name: undefined,
        type: UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });
  });
});
