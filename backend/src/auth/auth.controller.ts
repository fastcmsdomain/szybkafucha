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
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { AuthService } from './auth.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { AppleAuthDto } from './dto/apple-auth.dto';
import { JwtAuthGuard } from './guards/jwt-auth.guard';

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
    return this.authService.authenticateWithGoogle(
      dto.googleId,
      dto.email,
      dto.name,
      dto.avatarUrl,
      dto.userType,
    );
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

  /**
   * POST /auth/logout
   * Logout the current user
   * Client should clear stored tokens after this call
   */
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  async logout() {
    return { message: 'Logged out successfully' };
  }
}
