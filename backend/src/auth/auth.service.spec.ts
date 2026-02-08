/**
 * Auth Service Unit Tests
 * Tests for authentication logic including OTP and social login
 */
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { BadRequestException } from '@nestjs/common';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';

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
    types: [UserType.CLIENT],
    phone: '+48123456789',
    email: 'test@example.com',
    name: 'Test User',
    avatarUrl: null,
    address: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockContractor: User = {
    ...mockUser,
    id: 'contractor-123',
    types: [UserType.CONTRACTOR],
    phone: '+48222222221',
    email: 'contractor@example.com',
    name: 'Test Contractor',
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
      get: jest.fn().mockImplementation((key: string) => {
        if (key === 'NODE_ENV') return 'development';
        return null;
      }),
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
    usersService = module.get<UsersService>(
      UsersService,
    ) as jest.Mocked<UsersService>;
    jwtService = module.get<JwtService>(JwtService) as jest.Mocked<JwtService>;
    cacheManager = module.get<MockCacheManager>(CACHE_MANAGER);
  });

  describe('generateToken', () => {
    it('should generate JWT token with correct payload', () => {
      const result = service.generateToken(mockUser);

      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: mockUser.id,
        types: mockUser.types,
      });
      expect(result.accessToken).toBe('mock-jwt-token');
    });

    it('should return partial user data without sensitive fields', () => {
      const result = service.generateToken(mockUser);

      expect(result.user.id).toBe(mockUser.id);
      expect(result.user.types).toEqual(mockUser.types);
      expect(result.user.name).toBe(mockUser.name);
      expect(result.user.email).toBe(mockUser.email);
      expect(result.user.phone).toBe(mockUser.phone);
      expect(result.user).not.toHaveProperty('googleId');
      expect(result.user).not.toHaveProperty('appleId');
      expect(result.user).not.toHaveProperty('fcmToken');
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

    it('should handle phone with spaces and dashes', async () => {
      const result = await service.requestPhoneOtp('+48 123-456-789');

      expect(result.message).toBe('OTP sent successfully');
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

      const result = await service.verifyPhoneOtp(phone, code);

      expect(usersService.create).toHaveBeenCalledWith({
        phone,
        types: [UserType.CLIENT],
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should create contractor when userType is specified', async () => {
      cacheManager.get.mockResolvedValue(validOtp);
      usersService.findByPhone.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockContractor);

      const result = await service.verifyPhoneOtp(
        phone,
        code,
        UserType.CONTRACTOR,
      );

      expect(usersService.create).toHaveBeenCalledWith({
        phone,
        types: [UserType.CONTRACTOR],
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
    const email = 'user@gmail.com';
    const name = 'Google User';
    const avatarUrl = 'https://google.com/avatar.jpg';

    it('should return token for existing user with Google ID', async () => {
      usersService.findByGoogleId.mockResolvedValue(mockUser);

      const result = await service.authenticateWithGoogle(
        googleId,
        email,
        name,
        avatarUrl,
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
        avatarUrl,
      );

      expect(usersService.update).toHaveBeenCalledWith(mockUser.id, {
        googleId,
      });
      expect(result.isNewUser).toBe(false);
    });

    it('should create new user when no existing account found', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.authenticateWithGoogle(
        googleId,
        email,
        name,
        avatarUrl,
      );

      expect(usersService.create).toHaveBeenCalledWith({
        googleId,
        email,
        name,
        avatarUrl,
        types: [UserType.CLIENT],
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should create contractor when userType specified', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockContractor);

      await service.authenticateWithGoogle(
        googleId,
        email,
        name,
        avatarUrl,
        UserType.CONTRACTOR,
      );

      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({ types: [UserType.CONTRACTOR] }),
      );
    });
  });

  describe('authenticateWithApple', () => {
    const appleId = 'apple-123';
    const email = 'user@icloud.com';
    const name = 'Apple User';

    it('should return token for existing user with Apple ID', async () => {
      usersService.findByAppleId.mockResolvedValue(mockUser);

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

    it('should create new user when no existing account found', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.authenticateWithApple(appleId, email, name);

      expect(usersService.create).toHaveBeenCalledWith({
        appleId,
        email,
        name,
        types: [UserType.CLIENT],
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should handle Apple Sign In without email (subsequent logins)', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.authenticateWithApple(appleId);

      expect(usersService.findByEmail).not.toHaveBeenCalled();
      expect(usersService.create).toHaveBeenCalledWith({
        appleId,
        email: undefined,
        name: undefined,
        types: [UserType.CLIENT],
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should create contractor when userType specified', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockContractor);

      await service.authenticateWithApple(
        appleId,
        email,
        name,
        UserType.CONTRACTOR,
      );

      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({ types: [UserType.CONTRACTOR] }),
      );
    });
  });
});
