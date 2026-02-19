/**
 * Auth Controller
 * REST endpoints for authentication
 */
import {
  Controller,
  Post,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  Request,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { AppleAuthDto } from './dto/apple-auth.dto';
import { RegisterEmailDto } from './dto/register-email.dto';
import { LoginEmailDto } from './dto/login-email.dto';
import { VerifyEmailDto } from './dto/verify-email.dto';
import { RequestPasswordResetDto } from './dto/request-password-reset.dto';
import { ResetPasswordDto } from './dto/reset-password.dto';
import { SelectRoleDto } from './dto/select-role.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';
import type { AuthenticatedRequest } from './types/authenticated-request.type';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * POST /auth/phone/request-otp
   * Send OTP code to phone number
   * Rate limit: 3 requests per 60 seconds (SMS cost protection)
   */
  @Post('phone/request-otp')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  async requestOtp(@Body() dto: RequestOtpDto) {
    return this.authService.requestPhoneOtp(dto.phone);
  }

  /**
   * POST /auth/phone/verify
   * Verify OTP and return JWT token
   * Rate limit: 5 verification attempts per 60 seconds
   */
  @Post('phone/verify')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async verifyOtp(@Body() dto: VerifyOtpDto) {
    return this.authService.verifyPhoneOtp(dto.phone, dto.code, dto.userType);
  }

  /**
   * POST /auth/google
   * Authenticate with Google ID token
   */
  @Post('google')
  @HttpCode(HttpStatus.OK)
  async googleAuth(@Body() dto: GoogleAuthDto) {
    return this.authService.authenticateWithGoogle(dto);
  }

  /**
   * POST /auth/apple
   * Authenticate with Apple ID token
   */
  @Post('apple')
  @HttpCode(HttpStatus.OK)
  async appleAuth(@Body() dto: AppleAuthDto) {
    return this.authService.authenticateWithApple(
      dto.appleId,
      dto.email,
      dto.name,
      dto.userType,
    );
  }

  // ──────────────────────────────────────────────────────
  // Email + Password Authentication
  // ──────────────────────────────────────────────────────

  /**
   * POST /auth/email/register
   * Register with email and password
   * Rate limit: 3 requests per 60 seconds
   */
  @Post('email/register')
  @HttpCode(HttpStatus.CREATED)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  async registerWithEmail(@Body() dto: RegisterEmailDto) {
    return this.authService.registerWithEmail(
      dto.email,
      dto.password,
      dto.name,
      dto.userType,
    );
  }

  /**
   * POST /auth/email/login
   * Login with email and password
   * Rate limit: 5 attempts per 60 seconds
   */
  @Post('email/login')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async loginWithEmail(@Body() dto: LoginEmailDto) {
    return this.authService.loginWithEmail(dto.email, dto.password);
  }

  /**
   * POST /auth/email/verify
   * Verify email with OTP code
   * Rate limit: 5 attempts per 60 seconds
   */
  @Post('email/verify')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 5, ttl: 60000 } })
  async verifyEmail(@Body() dto: VerifyEmailDto) {
    return this.authService.verifyEmailOtp(dto.email, dto.code);
  }

  /**
   * POST /auth/email/resend-verification
   * Resend email verification OTP
   * Rate limit: 3 requests per 60 seconds
   */
  @Post('email/resend-verification')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  async resendVerification(@Body() dto: RequestPasswordResetDto) {
    return this.authService.resendEmailVerificationOtp(dto.email);
  }

  /**
   * POST /auth/email/request-password-reset
   * Request password reset OTP via email
   * Rate limit: 3 requests per 60 seconds
   */
  @Post('email/request-password-reset')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  async requestPasswordReset(@Body() dto: RequestPasswordResetDto) {
    return this.authService.requestPasswordReset(dto.email);
  }

  /**
   * POST /auth/email/reset-password
   * Reset password with OTP code and new password
   * Rate limit: 3 requests per 60 seconds
   */
  @Post('email/reset-password')
  @HttpCode(HttpStatus.OK)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  async resetPassword(@Body() dto: ResetPasswordDto) {
    return this.authService.resetPassword(dto.email, dto.code, dto.newPassword);
  }

  // ──────────────────────────────────────────────────────
  // Session Management
  // ──────────────────────────────────────────────────────

  /**
   * POST /auth/logout
   * Logout the current user
   * Client should clear stored tokens after this call
   */
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  logout() {
    return { message: 'Logged out successfully' };
  }

  /**
   * POST /auth/role/select
   * Finalize first-login role selection for social users.
   */
  @Post('role/select')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async selectRole(
    @Request() req: AuthenticatedRequest,
    @Body() dto: SelectRoleDto,
  ) {
    return this.authService.selectRole(req.user.id, dto.role);
  }
}
