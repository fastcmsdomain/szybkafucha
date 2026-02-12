/**
 * Auth Service Unit Tests
 * Tests for authentication logic including OTP, social login, and email+password
 */
import { Test, TestingModule } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import {
  BadRequestException,
  ConflictException,
  UnauthorizedException,
  HttpException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { EmailService } from './email.service';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import * as bcrypt from 'bcrypt';

jest.mock('bcrypt');

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
  let emailService: jest.Mocked<EmailService>;

  const mockUser: User = {
    id: 'user-123',
    types: [UserType.CLIENT],
    phone: '+48123456789',
    email: 'test@example.com',
    name: 'Test User',
    address: null,
    avatarUrl: null,
    status: UserStatus.ACTIVE,
    googleId: null,
    appleId: null,
    fcmToken: null,
    passwordHash: null,
    passwordUpdatedAt: null,
    emailVerified: false,
    failedLoginAttempts: 0,
    lockedUntil: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockUserWithPassword: User = {
    ...mockUser,
    id: 'user-pw-123',
    email: 'pw@example.com',
    passwordHash: '$2b$12$hashedpassword',
    passwordUpdatedAt: new Date(),
    emailVerified: true,
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
      findByEmailWithPassword: jest.fn(),
      findByGoogleId: jest.fn(),
      findByAppleId: jest.fn(),
      create: jest.fn(),
      update: jest.fn(),
      addRole: jest.fn(),
      incrementFailedLoginAttempts: jest.fn(),
      resetFailedLoginAttempts: jest.fn(),
      setEmailVerified: jest.fn(),
      updatePassword: jest.fn(),
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

    const mockEmailService = {
      sendVerificationOtp: jest.fn(),
      sendPasswordResetOtp: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
        { provide: ConfigService, useValue: mockConfigService },
        { provide: CACHE_MANAGER, useValue: mockCacheManager },
        { provide: EmailService, useValue: mockEmailService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(
      UsersService,
    ) as jest.Mocked<UsersService>;
    jwtService = module.get<JwtService>(JwtService) as jest.Mocked<JwtService>;
    cacheManager = module.get<MockCacheManager>(CACHE_MANAGER);
    emailService = module.get<EmailService>(
      EmailService,
    ) as jest.Mocked<EmailService>;
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

      await expect(
        service.verifyPhoneOtp(phone, 'wrong-code'),
      ).rejects.toThrow(BadRequestException);
      await expect(
        service.verifyPhoneOtp(phone, 'wrong-code'),
      ).rejects.toThrow('Invalid OTP code');
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

  // ──────────────────────────────────────────────────────
  // Email + Password Authentication Tests
  // ──────────────────────────────────────────────────────

  describe('registerWithEmail', () => {
    const email = 'new@example.com';
    const password = 'Test123!@#';

    beforeEach(() => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('$2b$12$hashed');
    });

    it('should register a new user with hashed password', async () => {
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockUser,
        email,
        passwordHash: '$2b$12$hashed',
      });

      const result = await service.registerWithEmail(email, password);

      expect(bcrypt.hash).toHaveBeenCalledWith(password, 12);
      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({
          email,
          passwordHash: '$2b$12$hashed',
          emailVerified: false,
        }),
      );
      expect(result.isNewUser).toBe(true);
      expect(result.accessToken).toBe('mock-jwt-token');
    });

    it('should throw ConflictException if email already exists', async () => {
      usersService.findByEmail.mockResolvedValue(mockUser);

      await expect(
        service.registerWithEmail(email, password),
      ).rejects.toThrow(ConflictException);
    });

    it('should send email verification OTP after registration', async () => {
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockUser,
        email,
      });

      await service.registerWithEmail(email, password);

      expect(cacheManager.set).toHaveBeenCalled();
      expect(emailService.sendVerificationOtp).toHaveBeenCalledWith(
        email,
        expect.any(String),
      );
    });

    it('should create contractor when userType specified', async () => {
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue({
        ...mockContractor,
        email,
      });

      await service.registerWithEmail(
        email,
        password,
        'Test',
        UserType.CONTRACTOR,
      );

      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({ types: [UserType.CONTRACTOR] }),
      );
    });
  });

  describe('loginWithEmail', () => {
    const email = 'pw@example.com';
    const password = 'Test123!@#';

    it('should return token for valid credentials', async () => {
      usersService.findByEmailWithPassword.mockResolvedValue(
        mockUserWithPassword,
      );
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      const result = await service.loginWithEmail(email, password);

      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.isNewUser).toBe(false);
      expect(usersService.resetFailedLoginAttempts).toHaveBeenCalledWith(
        mockUserWithPassword.id,
      );
    });

    it('should throw UnauthorizedException for wrong password', async () => {
      usersService.findByEmailWithPassword.mockResolvedValue(
        mockUserWithPassword,
      );
      (bcrypt.compare as jest.Mock).mockResolvedValue(false);

      await expect(
        service.loginWithEmail(email, 'wrong-password'),
      ).rejects.toThrow(UnauthorizedException);
      expect(usersService.incrementFailedLoginAttempts).toHaveBeenCalledWith(
        mockUserWithPassword.id,
      );
    });

    it('should throw UnauthorizedException for non-existent user', async () => {
      usersService.findByEmailWithPassword.mockResolvedValue(null);

      await expect(
        service.loginWithEmail(email, password),
      ).rejects.toThrow(UnauthorizedException);
    });

    it('should throw HttpException (423) for locked account', async () => {
      const lockedUser = {
        ...mockUserWithPassword,
        lockedUntil: new Date(Date.now() + 10 * 60 * 1000), // 10 min from now
      };
      usersService.findByEmailWithPassword.mockResolvedValue(lockedUser);

      await expect(
        service.loginWithEmail(email, password),
      ).rejects.toThrow(HttpException);
    });

    it('should throw UnauthorizedException for suspended/banned user', async () => {
      const bannedUser = {
        ...mockUserWithPassword,
        status: UserStatus.BANNED,
      };
      usersService.findByEmailWithPassword.mockResolvedValue(bannedUser);
      (bcrypt.compare as jest.Mock).mockResolvedValue(true);

      await expect(
        service.loginWithEmail(email, password),
      ).rejects.toThrow(UnauthorizedException);
    });
  });

  describe('verifyEmailOtp', () => {
    const email = 'test@example.com';
    const code = '123456';
    const cacheKey = `email-verify:${email}`;
    const validOtp = { code, expiresAt: new Date(Date.now() + 60000) };

    it('should verify email successfully with valid code', async () => {
      cacheManager.get.mockResolvedValue(validOtp);
      usersService.findByEmail.mockResolvedValue(mockUser);
      usersService.setEmailVerified.mockResolvedValue({
        ...mockUser,
        emailVerified: true,
      });

      const result = await service.verifyEmailOtp(email, code);

      expect(result.message).toContain('zweryfikowany');
      expect(cacheManager.del).toHaveBeenCalledWith(cacheKey);
      expect(usersService.setEmailVerified).toHaveBeenCalledWith(mockUser.id);
    });

    it('should throw BadRequestException for expired code', async () => {
      const expiredOtp = { code, expiresAt: new Date(Date.now() - 60000) };
      cacheManager.get.mockResolvedValue(expiredOtp);

      await expect(service.verifyEmailOtp(email, code)).rejects.toThrow(
        BadRequestException,
      );
    });

    it('should throw BadRequestException for wrong code', async () => {
      cacheManager.get.mockResolvedValue(validOtp);

      await expect(service.verifyEmailOtp(email, '000000')).rejects.toThrow(
        BadRequestException,
      );
    });
  });

  describe('requestPasswordReset', () => {
    it('should send reset OTP when user exists', async () => {
      usersService.findByEmailWithPassword.mockResolvedValue(mockUserWithPassword);

      const result = await service.requestPasswordReset('pw@example.com');

      expect(cacheManager.set).toHaveBeenCalled();
      expect(emailService.sendPasswordResetOtp).toHaveBeenCalled();
      expect(result.message).toBeDefined();
    });

    it('should return same response when user does not exist (anti-enumeration)', async () => {
      usersService.findByEmailWithPassword.mockResolvedValue(null);

      const result = await service.requestPasswordReset(
        'nonexistent@example.com',
      );

      expect(emailService.sendPasswordResetOtp).not.toHaveBeenCalled();
      expect(result.message).toBeDefined();
    });
  });

  describe('resetPassword', () => {
    const email = 'pw@example.com';
    const code = '123456';
    const newPassword = 'NewPass123!@#';
    const cacheKey = `password-reset:${email}`;
    const validOtp = { code, expiresAt: new Date(Date.now() + 60000) };

    beforeEach(() => {
      (bcrypt.hash as jest.Mock).mockResolvedValue('$2b$12$newhash');
    });

    it('should reset password with valid OTP', async () => {
      cacheManager.get.mockResolvedValue(validOtp);
      usersService.findByEmail.mockResolvedValue(mockUserWithPassword);

      const result = await service.resetPassword(email, code, newPassword);

      expect(bcrypt.hash).toHaveBeenCalledWith(newPassword, 12);
      expect(usersService.updatePassword).toHaveBeenCalledWith(
        mockUserWithPassword.id,
        '$2b$12$newhash',
      );
      expect(cacheManager.del).toHaveBeenCalledWith(cacheKey);
      expect(result.message).toContain('zmienione');
    });

    it('should throw BadRequestException for invalid OTP', async () => {
      cacheManager.get.mockResolvedValue(validOtp);

      await expect(
        service.resetPassword(email, 'wrong', newPassword),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException for expired OTP', async () => {
      const expiredOtp = { code, expiresAt: new Date(Date.now() - 60000) };
      cacheManager.get.mockResolvedValue(expiredOtp);

      await expect(
        service.resetPassword(email, code, newPassword),
      ).rejects.toThrow(BadRequestException);
    });
  });
});
