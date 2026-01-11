/**
 * Auth Service
 * Handles authentication logic for all methods
 */
import { Injectable, BadRequestException, UnauthorizedException, Inject, Logger } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import twilio from 'twilio';

// Configuration constants
const OTP_CONFIG = {
  LENGTH: 6,
  EXPIRES_IN_MINUTES: 5,
};

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private twilioClient: twilio.Twilio | null = null;

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
  ) {
    // Initialize Twilio client if credentials are provided
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN');

    if (accountSid && authToken) {
      this.twilioClient = twilio(accountSid, authToken);
      this.logger.log('Twilio client initialized successfully');
    } else {
      this.logger.warn('Twilio credentials not configured - OTP will only be logged to console');
    }
  }

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
   * Stores OTP in Redis with automatic TTL expiration
   */
  async requestPhoneOtp(phone: string): Promise<{ message: string; expiresIn: number }> {
    // Normalize phone number
    const normalizedPhone = this.normalizePhone(phone);

    // Generate 6-digit OTP
    const code = this.generateOtp();
    const expiresAt = new Date(Date.now() + OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000);

    // Store OTP in Redis with TTL (milliseconds)
    await this.cacheManager.set(
      `otp:${normalizedPhone}`,
      { code, expiresAt },
      OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    // Send SMS (in production) or log (in development)
    if (process.env.NODE_ENV === 'production') {
      await this.sendOtpSms(normalizedPhone, code);
    } else {
      this.logger.debug(`[DEV] OTP for ${normalizedPhone}: ${code}`);
    }

    return {
      message: 'OTP sent successfully',
      expiresIn: OTP_CONFIG.EXPIRES_IN_MINUTES * 60,
    };
  }

  /**
   * Verify phone OTP and authenticate user
   * Retrieves OTP from Redis and validates it
   */
  async verifyPhoneOtp(
    phone: string,
    code: string,
    userType?: UserType,
  ): Promise<{ accessToken: string; user: Partial<User>; isNewUser: boolean }> {
    const normalizedPhone = this.normalizePhone(phone);

    // Get stored OTP from Redis
    const storedOtp = await this.cacheManager.get<{ code: string; expiresAt: Date }>(
      `otp:${normalizedPhone}`,
    );

    if (!storedOtp) {
      throw new BadRequestException('OTP not found or expired. Please request a new one.');
    }

    if (new Date() > new Date(storedOtp.expiresAt)) {
      await this.cacheManager.del(`otp:${normalizedPhone}`);
      throw new BadRequestException('OTP expired. Please request a new one.');
    }

    if (storedOtp.code !== code) {
      throw new BadRequestException('Invalid OTP code.');
    }

    // OTP is valid, remove from Redis (one-time use)
    await this.cacheManager.del(`otp:${normalizedPhone}`);

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
   * Send OTP via Twilio SMS
   */
  private async sendOtpSms(phone: string, code: string): Promise<void> {
    if (!this.twilioClient) {
      this.logger.warn('Twilio not configured - OTP will only be logged');
      return;
    }

    try {
      await this.twilioClient.messages.create({
        body: `Twój kod weryfikacyjny Szybka Fucha: ${code}. Ważny przez ${OTP_CONFIG.EXPIRES_IN_MINUTES} minut.`,
        from: this.configService.get<string>('TWILIO_PHONE_NUMBER'),
        to: phone,
      });
      this.logger.log(`SMS OTP sent successfully to ${phone}`);
    } catch (error) {
      this.logger.error(`Failed to send SMS to ${phone}`, error);
      throw new BadRequestException('Nie udało się wysłać SMS z kodem weryfikacyjnym');
    }
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
