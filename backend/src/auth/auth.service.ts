/**
 * Auth Service
 * Handles authentication logic for all methods
 */
import { Injectable, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';

// OTP storage (in production, use Redis)
const otpStore: Map<string, { code: string; expiresAt: Date }> = new Map();

// Configuration constants
const OTP_CONFIG = {
  LENGTH: 6,
  EXPIRES_IN_MINUTES: 5,
  DEV_CODE: '123456', // Fixed code for development/testing
};

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
  ) {}

  /**
   * Generate JWT token for a user
   */
  generateToken(user: User): { accessToken: string; user: Partial<User> } {
    const payload = {
      sub: user.id,
      type: user.type,
    };

    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        type: user.type,
        name: user.name,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatarUrl,
        status: user.status,
      },
    };
  }

  /**
   * Request OTP for phone authentication
   * In production, integrate with Twilio
   */
  async requestPhoneOtp(phone: string): Promise<{ message: string; expiresIn: number }> {
    // Normalize phone number
    const normalizedPhone = this.normalizePhone(phone);

    // Use fixed code in development, random in production
    const isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    const code = isDev ? OTP_CONFIG.DEV_CODE : this.generateOtp();
    const expiresAt = new Date(Date.now() + OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000);

    // Store OTP (in production, use Redis with TTL)
    otpStore.set(normalizedPhone, { code, expiresAt });

    // TODO: Send SMS via Twilio
    // For development, log the OTP
    if (isDev) {
      console.log(`[DEV] OTP for ${normalizedPhone}: ${code}`);
    }

    return {
      message: 'OTP sent successfully',
      expiresIn: OTP_CONFIG.EXPIRES_IN_MINUTES * 60,
    };
  }

  /**
   * Verify phone OTP and authenticate user
   */
  async verifyPhoneOtp(
    phone: string,
    code: string,
    userType?: UserType,
  ): Promise<{ accessToken: string; user: Partial<User>; isNewUser: boolean }> {
    const normalizedPhone = this.normalizePhone(phone);

    // Get stored OTP
    const storedOtp = otpStore.get(normalizedPhone);

    if (!storedOtp) {
      throw new BadRequestException('OTP not found. Please request a new one.');
    }

    if (new Date() > storedOtp.expiresAt) {
      otpStore.delete(normalizedPhone);
      throw new BadRequestException('OTP expired. Please request a new one.');
    }

    if (storedOtp.code !== code) {
      throw new BadRequestException('Invalid OTP code.');
    }

    // OTP is valid, remove from store
    otpStore.delete(normalizedPhone);

    // Find or create user
    let user = await this.usersService.findByPhone(normalizedPhone);
    let isNewUser = false;

    if (!user) {
      isNewUser = true;
      user = await this.usersService.create({
        phone: normalizedPhone,
        type: userType || UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
    }

    const token = this.generateToken(user);
    return { ...token, isNewUser };
  }

  /**
   * Authenticate with Google
   * Expects Google ID token from mobile app
   */
  async authenticateWithGoogle(
    googleId: string,
    email: string,
    name?: string,
    avatarUrl?: string,
    userType?: UserType,
  ): Promise<{ accessToken: string; user: Partial<User>; isNewUser: boolean }> {
    // Check if user exists with this Google ID
    let user = await this.usersService.findByGoogleId(googleId);
    let isNewUser = false;

    if (!user) {
      // Check if user exists with this email
      user = await this.usersService.findByEmail(email);

      if (user) {
        // Link Google account to existing user
        user = await this.usersService.update(user.id, { googleId });
      } else {
        // Create new user
        isNewUser = true;
        user = await this.usersService.create({
          googleId,
          email,
          name,
          avatarUrl,
          type: userType || UserType.CLIENT,
          status: UserStatus.ACTIVE,
        });
      }
    }

    const token = this.generateToken(user);
    return { ...token, isNewUser };
  }

  /**
   * Authenticate with Apple
   * Expects Apple ID token from mobile app
   */
  async authenticateWithApple(
    appleId: string,
    email?: string,
    name?: string,
    userType?: UserType,
  ): Promise<{ accessToken: string; user: Partial<User>; isNewUser: boolean }> {
    // Check if user exists with this Apple ID
    let user = await this.usersService.findByAppleId(appleId);
    let isNewUser = false;

    if (!user) {
      if (email) {
        // Check if user exists with this email
        user = await this.usersService.findByEmail(email);

        if (user) {
          // Link Apple account to existing user
          user = await this.usersService.update(user.id, { appleId });
        }
      }

      if (!user) {
        // Create new user
        isNewUser = true;
        user = await this.usersService.create({
          appleId,
          email,
          name,
          type: userType || UserType.CLIENT,
          status: UserStatus.ACTIVE,
        });
      }
    }

    const token = this.generateToken(user);
    return { ...token, isNewUser };
  }

  /**
   * Generate random OTP code
   */
  private generateOtp(): string {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  /**
   * Normalize phone number format
   */
  private normalizePhone(phone: string): string {
    // Remove all non-digit characters except +
    let normalized = phone.replace(/[^\d+]/g, '');

    // Ensure it starts with + for international format
    if (!normalized.startsWith('+')) {
      // Assume Polish number if no country code
      if (normalized.length === 9) {
        normalized = `+48${normalized}`;
      }
    }

    return normalized;
  }
}
