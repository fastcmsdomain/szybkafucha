/**
 * Auth Service
 * Handles authentication logic for all methods
 */
import {
  Injectable,
  BadRequestException,
  ConflictException,
  UnauthorizedException,
  Inject,
  Logger,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import type { Cache } from 'cache-manager';
import * as bcrypt from 'bcrypt';
import { OAuth2Client, type TokenPayload } from 'google-auth-library';
import { UsersService } from '../users/users.service';
import { User, UserType, UserStatus } from '../users/entities/user.entity';
import { EmailService } from './email.service';
import { GoogleAuthDto } from './dto/google-auth.dto';
import twilio from 'twilio';

// Configuration constants
const OTP_CONFIG = {
  LENGTH: 6,
  EXPIRES_IN_MINUTES: 5,
  DEV_CODE: '123456', // Fixed code for development/testing
};

const BCRYPT_SALT_ROUNDS = 12;
const LOCKOUT_THRESHOLD = 5;
const LOCKOUT_DURATION_MINUTES = 15;

type AuthResponse = {
  accessToken: string;
  user: Partial<User>;
  isNewUser: boolean;
  requiresRoleSelection: boolean;
};

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private twilioClient: twilio.Twilio | null = null;
  private readonly googleOAuthClient = new OAuth2Client();

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
    private readonly configService: ConfigService,
    @Inject(CACHE_MANAGER) private readonly cacheManager: Cache,
    private readonly emailService: EmailService,
  ) {
    // Initialize Twilio client if credentials are provided
    const accountSid = this.configService.get<string>('TWILIO_ACCOUNT_SID');
    const authToken = this.configService.get<string>('TWILIO_AUTH_TOKEN');

    if (accountSid && authToken) {
      this.twilioClient = twilio(accountSid, authToken);
      this.logger.log('Twilio client initialized successfully');
    } else {
      this.logger.warn(
        'Twilio credentials not configured - OTP will only be logged to console',
      );
    }
  }

  /**
   * Generate JWT token for a user
   */
  generateToken(user: User): { accessToken: string; user: Partial<User> } {
    const normalizedTypes = this.normalizeTypes(user.types);
    const type = this.resolvePrimaryType(normalizedTypes);
    const payload = {
      sub: user.id,
      types: normalizedTypes,
      ...(type ? { type } : {}),
    };

    return {
      accessToken: this.jwtService.sign(payload),
      user: {
        id: user.id,
        types: normalizedTypes,
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
  async requestPhoneOtp(
    phone: string,
  ): Promise<{ message: string; expiresIn: number }> {
    // Normalize phone number
    const normalizedPhone = this.normalizePhone(phone);

    // Use fixed code in development, random in production
    const isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    const code = isDev ? OTP_CONFIG.DEV_CODE : this.generateOtp();
    const expiresAt = new Date(
      Date.now() + OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    // Store OTP in Redis with TTL (milliseconds)
    await this.cacheManager.set(
      `otp:${normalizedPhone}`,
      { code, expiresAt },
      OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    // Send SMS (in production) or log (in development)
    if (!isDev) {
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
  ): Promise<AuthResponse> {
    const normalizedPhone = this.normalizePhone(phone);

    // Get stored OTP from Redis
    const storedOtp = await this.cacheManager.get<{
      code: string;
      expiresAt: Date;
    }>(`otp:${normalizedPhone}`);

    if (!storedOtp) {
      throw new BadRequestException('OTP not found or expired');
    }

    if (new Date() > new Date(storedOtp.expiresAt)) {
      await this.cacheManager.del(`otp:${normalizedPhone}`);
      throw new BadRequestException('OTP expired. Please request a new one.');
    }

    if (storedOtp.code !== code) {
      throw new BadRequestException('Invalid OTP code');
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
        types: [userType || UserType.CLIENT],
        status: UserStatus.ACTIVE,
      });
    } else if (userType && !this.hasAssignedRole(user.types)) {
      // MVP: Only add role if user has no roles yet (prevents role switching)
      user = await this.usersService.addRole(user.id, userType);
    }

    return this.buildAuthResponse(user, isNewUser);
  }

  /**
   * Authenticate with Google
   * Expects Google ID token from mobile app (new flow).
   * Supports legacy googleId + email payload for backward compatibility.
   */
  async authenticateWithGoogle(
    dto: GoogleAuthDto,
  ): Promise<AuthResponse> {
    let googleId: string;
    let email: string | undefined;
    let name: string | undefined = dto.name;
    let avatarUrl: string | undefined = dto.avatarUrl;

    if (dto.idToken) {
      const payload = await this.verifyGoogleIdToken(dto.idToken);
      googleId = payload.sub;
      email = payload.email || undefined;
      name = payload.name || name;
      avatarUrl = payload.picture || avatarUrl;
    } else {
      // Legacy path: keep for one release window
      googleId = dto.googleId!;
      email = dto.email;
      this.logger.warn(
        `Deprecated Google auth payload used (googleId/email) for googleId=${googleId}`,
      );
    }

    if (!email) {
      throw new BadRequestException(
        'Google account does not include an email address',
      );
    }

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
          types: dto.userType ? [dto.userType] : [],
          status: UserStatus.ACTIVE,
        });
        // Defensive fix: ensure truly roleless account for first-login selection.
        if (!dto.userType && this.hasAssignedRole(user.types)) {
          this.logger.warn(
            `Expected roleless social user but got roles=${user.types.join(',')} for userId=${user.id}. Clearing roles.`,
          );
          user = await this.usersService.update(user.id, { types: [] });
        }
      }
    } else if (dto.userType && !this.hasAssignedRole(user.types)) {
      // MVP: Only add role if user has no roles yet (prevents role switching)
      user = await this.usersService.addRole(user.id, dto.userType);
    }

    return this.buildAuthResponse(user, isNewUser);
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
  ): Promise<AuthResponse> {
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
          types: userType ? [userType] : [],
          status: UserStatus.ACTIVE,
        });
        // Defensive fix: ensure truly roleless account for first-login selection.
        if (!userType && this.hasAssignedRole(user.types)) {
          this.logger.warn(
            `Expected roleless Apple user but got roles=${user.types.join(',')} for userId=${user.id}. Clearing roles.`,
          );
          user = await this.usersService.update(user.id, { types: [] });
        }
      }
    } else if (userType && !this.hasAssignedRole(user.types)) {
      // MVP: Only add role if user has no roles yet (prevents role switching)
      user = await this.usersService.addRole(user.id, userType);
    }

    return this.buildAuthResponse(user, isNewUser);
  }

  /**
   * Finalize role for first-login social users.
   * Allowed only when user does not have any role yet.
   */
  async selectRole(
    userId: string,
    role: UserType,
  ): Promise<{
    accessToken: string;
    user: Partial<User>;
    requiresRoleSelection: false;
  }> {
    const user = await this.usersService.findByIdOrFail(userId);

    if (this.hasAssignedRole(user.types)) {
      throw new BadRequestException(
        'Role changes are not allowed in MVP. Please contact support if you need to change your role.',
      );
    }

    const updatedUser = await this.usersService.addRole(user.id, role);
    const token = this.generateToken(updatedUser);

    this.logger.log(`role_selected userId=${user.id} role=${role}`);

    return {
      ...token,
      requiresRoleSelection: false,
    };
  }

  // ──────────────────────────────────────────────────────
  // Email + Password Authentication
  // ──────────────────────────────────────────────────────

  /**
   * Register with email and password
   */
  async registerWithEmail(
    email: string,
    password: string,
    name?: string,
    userType?: UserType,
  ): Promise<AuthResponse> {
    // Check if email is already taken
    const existingUser = await this.usersService.findByEmail(email);
    if (existingUser) {
      throw new ConflictException('Konto z tym adresem email już istnieje');
    }

    // Hash password with bcrypt
    const passwordHash = await bcrypt.hash(password, BCRYPT_SALT_ROUNDS);

    // Create user
    const user = await this.usersService.create({
      email,
      passwordHash,
      passwordUpdatedAt: new Date(),
      name: name || null,
      types: [userType || UserType.CLIENT],
      status: UserStatus.ACTIVE,
      emailVerified: false,
    });

    // Send email verification OTP
    await this.sendEmailVerificationOtp(email);

    return this.buildAuthResponse(user, true);
  }

  /**
   * Login with email and password
   */
  async loginWithEmail(
    email: string,
    password: string,
  ): Promise<AuthResponse> {
    // Find user with password hash
    const user = await this.usersService.findByEmailWithPassword(email);

    if (!user || !user.passwordHash) {
      throw new UnauthorizedException('Nieprawidłowy email lub hasło');
    }

    // Check account lockout
    if (user.lockedUntil && new Date() < new Date(user.lockedUntil)) {
      const minutesLeft = Math.ceil(
        (new Date(user.lockedUntil).getTime() - Date.now()) / 60000,
      );
      throw new HttpException(
        `Konto tymczasowo zablokowane. Spróbuj ponownie za ${minutesLeft} min.`,
        HttpStatus.LOCKED,
      );
    }

    // Compare password
    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);

    if (!isPasswordValid) {
      await this.usersService.incrementFailedLoginAttempts(user.id);

      const attemptsLeft = LOCKOUT_THRESHOLD - (user.failedLoginAttempts + 1);
      if (attemptsLeft <= 0) {
        throw new HttpException(
          `Konto zablokowane na ${LOCKOUT_DURATION_MINUTES} minut z powodu zbyt wielu nieudanych prób logowania.`,
          HttpStatus.LOCKED,
        );
      }

      throw new UnauthorizedException('Nieprawidłowy email lub hasło');
    }

    // Check user status
    if (
      user.status === UserStatus.BANNED ||
      user.status === UserStatus.SUSPENDED
    ) {
      throw new UnauthorizedException('Konto zostało zawieszone');
    }

    // Reset failed login attempts on success
    await this.usersService.resetFailedLoginAttempts(user.id);

    return this.buildAuthResponse(user, false);
  }

  /**
   * Verify email address with OTP code
   */
  async verifyEmailOtp(
    email: string,
    code: string,
  ): Promise<{ message: string }> {
    const cacheKey = `email-verify:${email.toLowerCase()}`;
    const storedOtp = await this.cacheManager.get<{
      code: string;
      expiresAt: Date;
    }>(cacheKey);

    if (!storedOtp) {
      throw new BadRequestException(
        'Kod weryfikacyjny nie został znaleziony lub wygasł',
      );
    }

    if (new Date() > new Date(storedOtp.expiresAt)) {
      await this.cacheManager.del(cacheKey);
      throw new BadRequestException('Kod weryfikacyjny wygasł. Wyślij nowy.');
    }

    if (storedOtp.code !== code) {
      throw new BadRequestException('Nieprawidłowy kod weryfikacyjny');
    }

    // OTP valid - mark email as verified
    await this.cacheManager.del(cacheKey);

    const user = await this.usersService.findByEmail(email);
    if (user) {
      await this.usersService.setEmailVerified(user.id);
    }

    return { message: 'Email zweryfikowany pomyślnie' };
  }

  /**
   * Resend email verification OTP
   */
  async resendEmailVerificationOtp(
    email: string,
  ): Promise<{ message: string; expiresIn: number }> {
    const user = await this.usersService.findByEmail(email);
    if (!user) {
      // Don't reveal if user exists
      return {
        message: 'Jeśli konto istnieje, wysłaliśmy kod weryfikacyjny',
        expiresIn: OTP_CONFIG.EXPIRES_IN_MINUTES * 60,
      };
    }

    if (user.emailVerified) {
      throw new BadRequestException('Email jest już zweryfikowany');
    }

    await this.sendEmailVerificationOtp(email);

    return {
      message: 'Kod weryfikacyjny został wysłany',
      expiresIn: OTP_CONFIG.EXPIRES_IN_MINUTES * 60,
    };
  }

  /**
   * Request password reset - send OTP to email
   */
  async requestPasswordReset(
    email: string,
  ): Promise<{ message: string; expiresIn: number }> {
    const user = await this.usersService.findByEmailWithPassword(email);

    // Always return same response to prevent email enumeration
    const response = {
      message:
        'Jeśli konto istnieje, wysłaliśmy kod do resetowania hasła na podany adres email',
      expiresIn: OTP_CONFIG.EXPIRES_IN_MINUTES * 60,
    };

    if (!user || !user.passwordHash) {
      // User doesn't exist or doesn't use password auth - don't reveal this
      return response;
    }

    const isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    const code = isDev ? OTP_CONFIG.DEV_CODE : this.generateOtp();
    const expiresAt = new Date(
      Date.now() + OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    const cacheKey = `password-reset:${email.toLowerCase()}`;
    await this.cacheManager.set(
      cacheKey,
      { code, expiresAt },
      OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    await this.emailService.sendPasswordResetOtp(email, code);

    return response;
  }

  /**
   * Reset password with OTP code
   */
  async resetPassword(
    email: string,
    code: string,
    newPassword: string,
  ): Promise<{ message: string }> {
    const cacheKey = `password-reset:${email.toLowerCase()}`;
    const storedOtp = await this.cacheManager.get<{
      code: string;
      expiresAt: Date;
    }>(cacheKey);

    if (!storedOtp) {
      throw new BadRequestException(
        'Kod resetowania nie został znaleziony lub wygasł',
      );
    }

    if (new Date() > new Date(storedOtp.expiresAt)) {
      await this.cacheManager.del(cacheKey);
      throw new BadRequestException('Kod resetowania wygasł. Wyślij nowy.');
    }

    if (storedOtp.code !== code) {
      throw new BadRequestException('Nieprawidłowy kod resetowania');
    }

    // OTP valid - update password
    await this.cacheManager.del(cacheKey);

    const user = await this.usersService.findByEmail(email);
    if (!user) {
      throw new BadRequestException('Nie znaleziono użytkownika');
    }

    const passwordHash = await bcrypt.hash(newPassword, BCRYPT_SALT_ROUNDS);
    await this.usersService.updatePassword(user.id, passwordHash);

    return { message: 'Hasło zostało zmienione pomyślnie' };
  }

  /**
   * Send email verification OTP (internal helper)
   */
  private async sendEmailVerificationOtp(email: string): Promise<void> {
    const isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    const code = isDev ? OTP_CONFIG.DEV_CODE : this.generateOtp();
    const expiresAt = new Date(
      Date.now() + OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    const cacheKey = `email-verify:${email.toLowerCase()}`;
    await this.cacheManager.set(
      cacheKey,
      { code, expiresAt },
      OTP_CONFIG.EXPIRES_IN_MINUTES * 60 * 1000,
    );

    await this.emailService.sendVerificationOtp(email, code);
  }

  // ──────────────────────────────────────────────────────
  // Private Helpers
  // ──────────────────────────────────────────────────────

  private buildAuthResponse(user: User, isNewUser: boolean): AuthResponse {
    const requiresRoleSelection = !this.hasAssignedRole(user.types);
    const token = this.generateToken(user);

    if (requiresRoleSelection) {
      this.logger.log(`requires_role_selection userId=${user.id}`);
    }

    return {
      ...token,
      isNewUser,
      requiresRoleSelection,
    };
  }

  private normalizeTypes(types: string[] | undefined | null): UserType[] {
    return (types ?? []).filter(
      (type): type is UserType =>
        type === UserType.CLIENT || type === UserType.CONTRACTOR,
    );
  }

  private hasAssignedRole(types: string[] | undefined | null): boolean {
    return this.normalizeTypes(types).length > 0;
  }

  private resolvePrimaryType(types: string[]): UserType | undefined {
    const normalizedTypes = this.normalizeTypes(types);

    if (normalizedTypes.includes(UserType.CLIENT)) {
      return UserType.CLIENT;
    }

    if (normalizedTypes.includes(UserType.CONTRACTOR)) {
      return UserType.CONTRACTOR;
    }

    return undefined;
  }

  private async verifyGoogleIdToken(idToken: string): Promise<TokenPayload> {
    try {
      const audience = this.getGoogleClientIds();
      const payload =
        audience.length > 0
          ? (
              await this.googleOAuthClient.verifyIdToken({
                idToken,
                audience,
              })
            ).getPayload()
          : this.decodeGoogleIdTokenPayloadForDev(idToken);

      if (!payload?.sub) {
        throw new UnauthorizedException('Invalid Google ID token payload');
      }

      return payload;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      throw new UnauthorizedException('Invalid Google ID token');
    }
  }

  private getGoogleClientIds(): string[] {
    const clientIdsRaw =
      this.configService.get<string>('GOOGLE_CLIENT_IDS') ||
      this.configService.get<string>('GOOGLE_CLIENT_ID');

    if (!clientIdsRaw) {
      const nodeEnv = this.configService.get<string>('NODE_ENV');
      if (nodeEnv === 'production') {
        throw new UnauthorizedException('Google Sign-In is not configured');
      }
      return [];
    }

    return clientIdsRaw
      .split(',')
      .map((value) => value.trim())
      .filter((value) => value.length > 0);
  }

  /**
   * Development-only fallback when Google client IDs are missing.
   * Decodes payload without signature verification.
   */
  private decodeGoogleIdTokenPayloadForDev(idToken: string): TokenPayload {
    const nodeEnv = this.configService.get<string>('NODE_ENV');
    if (nodeEnv === 'production') {
      throw new UnauthorizedException('Google Sign-In is not configured');
    }

    this.logger.warn(
      'GOOGLE_CLIENT_ID(S) not configured. Using unverified Google token payload in non-production.',
    );

    const parts = idToken.split('.');
    if (parts.length !== 3) {
      throw new UnauthorizedException('Invalid Google ID token');
    }

    try {
      const payloadJson = Buffer.from(parts[1], 'base64url').toString('utf8');
      return JSON.parse(payloadJson) as TokenPayload;
    } catch {
      throw new UnauthorizedException('Invalid Google ID token');
    }
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
      throw new BadRequestException(
        'Nie udało się wysłać SMS z kodem weryfikacyjnym',
      );
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
