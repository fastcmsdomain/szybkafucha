/**
 * Auth Service Unit Tests
 * Tests for authentication logic including OTP and social login
 */
import { Test, TestingModule } from '@nestjs/testing';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';

describe('AuthService', () => {
  let service: AuthService;
  let usersService: jest.Mocked<UsersService>;
  let jwtService: jest.Mocked<JwtService>;
  let configService: jest.Mocked<ConfigService>;

  const mockUser: User = {
    id: 'user-123',
    type: UserType.CLIENT,
    phone: '+48111111111',
    email: 'test@example.com',
    name: 'Test User',
    avatarUrl: null,
    googleId: null,
    appleId: null,
    status: UserStatus.ACTIVE,
    createdAt: new Date(),
    updatedAt: new Date(),
  };

  const mockContractor: User = {
    ...mockUser,
    id: 'contractor-123',
    type: UserType.CONTRACTOR,
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
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get(UsersService);
    jwtService = module.get(JwtService);
    configService = module.get(ConfigService);
  });

  describe('generateToken', () => {
    it('should generate JWT token with correct payload', () => {
      const result = service.generateToken(mockUser);

      expect(jwtService.sign).toHaveBeenCalledWith({
        sub: mockUser.id,
        type: mockUser.type,
      });
      expect(result.accessToken).toBe('mock-jwt-token');
    });

    it('should return partial user data without sensitive fields', () => {
      const result = service.generateToken(mockUser);

      expect(result.user).toEqual({
        id: mockUser.id,
        type: mockUser.type,
        name: mockUser.name,
        email: mockUser.email,
        phone: mockUser.phone,
        avatarUrl: mockUser.avatarUrl,
        status: mockUser.status,
      });
      expect(result.user).not.toHaveProperty('googleId');
      expect(result.user).not.toHaveProperty('appleId');
    });
  });

  describe('requestPhoneOtp', () => {
    it('should return success message with expiration time', async () => {
      const result = await service.requestPhoneOtp('+48111111111');

      expect(result.message).toBe('OTP sent successfully');
      expect(result.expiresIn).toBe(300); // 5 minutes in seconds
    });

    it('should normalize phone number without country code', async () => {
      const result = await service.requestPhoneOtp('111111111');

      expect(result.message).toBe('OTP sent successfully');
    });

    it('should handle phone with spaces and dashes', async () => {
      const result = await service.requestPhoneOtp('+48 111-111-111');

      expect(result.message).toBe('OTP sent successfully');
    });
  });

  describe('verifyPhoneOtp', () => {
    beforeEach(async () => {
      // Request OTP first to populate store
      await service.requestPhoneOtp('+48111111111');
    });

    it('should verify valid OTP and return token for existing user', async () => {
      usersService.findByPhone.mockResolvedValue(mockUser);

      const result = await service.verifyPhoneOtp('+48111111111', '123456');

      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.isNewUser).toBe(false);
      expect(result.user.id).toBe(mockUser.id);
    });

    it('should create new user when phone not found', async () => {
      usersService.findByPhone.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.verifyPhoneOtp('+48111111111', '123456');

      expect(usersService.create).toHaveBeenCalledWith({
        phone: '+48111111111',
        type: UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should create contractor when userType is specified', async () => {
      usersService.findByPhone.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockContractor);

      await service.verifyPhoneOtp('+48111111111', '123456', UserType.CONTRACTOR);

      expect(usersService.create).toHaveBeenCalledWith({
        phone: '+48111111111',
        type: UserType.CONTRACTOR,
        status: UserStatus.ACTIVE,
      });
    });

    it('should throw BadRequestException for invalid OTP', async () => {
      await expect(
        service.verifyPhoneOtp('+48111111111', '000000'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should throw BadRequestException when OTP not requested', async () => {
      await expect(
        service.verifyPhoneOtp('+48999999999', '123456'),
      ).rejects.toThrow(BadRequestException);
    });

    it('should invalidate OTP after successful verification', async () => {
      usersService.findByPhone.mockResolvedValue(mockUser);

      await service.verifyPhoneOtp('+48111111111', '123456');

      // Second attempt should fail
      await expect(
        service.verifyPhoneOtp('+48111111111', '123456'),
      ).rejects.toThrow(BadRequestException);
    });
  });

  describe('authenticateWithGoogle', () => {
    const googleId = 'google-123';
    const email = 'user@gmail.com';
    const name = 'Google User';
    const avatarUrl = 'https://google.com/avatar.jpg';

    it('should return token for existing user with Google ID', async () => {
      usersService.findByGoogleId.mockResolvedValue(mockUser);

      const result = await service.authenticateWithGoogle(googleId, email, name, avatarUrl);

      expect(result.accessToken).toBe('mock-jwt-token');
      expect(result.isNewUser).toBe(false);
    });

    it('should link Google account to existing user with same email', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(mockUser);
      usersService.update.mockResolvedValue({ ...mockUser, googleId });

      const result = await service.authenticateWithGoogle(googleId, email, name, avatarUrl);

      expect(usersService.update).toHaveBeenCalledWith(mockUser.id, { googleId });
      expect(result.isNewUser).toBe(false);
    });

    it('should create new user when no existing account found', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.authenticateWithGoogle(googleId, email, name, avatarUrl);

      expect(usersService.create).toHaveBeenCalledWith({
        googleId,
        email,
        name,
        avatarUrl,
        type: UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should create contractor when userType specified', async () => {
      usersService.findByGoogleId.mockResolvedValue(null);
      usersService.findByEmail.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockContractor);

      await service.authenticateWithGoogle(googleId, email, name, avatarUrl, UserType.CONTRACTOR);

      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({ type: UserType.CONTRACTOR }),
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

      expect(usersService.update).toHaveBeenCalledWith(mockUser.id, { appleId });
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
        type: UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
      expect(result.isNewUser).toBe(true);
    });

    it('should handle Apple Sign In without email (subsequent logins)', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockUser);

      const result = await service.authenticateWithApple(appleId, undefined, undefined);

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

    it('should create contractor when userType specified', async () => {
      usersService.findByAppleId.mockResolvedValue(null);
      usersService.create.mockResolvedValue(mockContractor);

      await service.authenticateWithApple(appleId, email, name, UserType.CONTRACTOR);

      expect(usersService.create).toHaveBeenCalledWith(
        expect.objectContaining({ type: UserType.CONTRACTOR }),
      );
    });
  });

  describe('phone normalization', () => {
    beforeEach(async () => {
      usersService.findByPhone.mockResolvedValue(mockUser);
    });

    it('should normalize phone without country code to Polish format', async () => {
      await service.requestPhoneOtp('111111111');
      await service.verifyPhoneOtp('111111111', '123456');

      expect(usersService.findByPhone).toHaveBeenCalledWith('+48111111111');
    });

    it('should preserve existing country code', async () => {
      await service.requestPhoneOtp('+48111111111');
      await service.verifyPhoneOtp('+48111111111', '123456');

      expect(usersService.findByPhone).toHaveBeenCalledWith('+48111111111');
    });

    it('should handle different international formats', async () => {
      await service.requestPhoneOtp('+1234567890');
      await service.verifyPhoneOtp('+1234567890', '123456');

      expect(usersService.findByPhone).toHaveBeenCalledWith('+1234567890');
    });
  });
});
