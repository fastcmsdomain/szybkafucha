/**
 * JWT Strategy
 * Validates JWT tokens and extracts user info
 */
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../../users/users.service';
import { UserStatus, UserType } from '../../users/entities/user.entity';
import { AuthenticatedUser } from '../types/auth-user.type';

// JWT payload interface
export interface JwtPayload {
  sub: string; // User ID
  type: UserType; // User type (client/contractor)
  iat?: number;
  exp?: number;
}

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private readonly configService: ConfigService,
    private readonly usersService: UsersService,
  ) {
    const secret = configService.get<string>('JWT_SECRET');
    if (!secret) {
      throw new Error('JWT_SECRET is not configured');
    }

    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: secret,
    });
  }

  /**
   * Validate the JWT payload and return user data
   * This data will be attached to the request object
   */
  async validate(payload: JwtPayload): Promise<AuthenticatedUser> {
    const user = await this.usersService.findById(payload.sub);

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    if (
      user.status === UserStatus.BANNED ||
      user.status === UserStatus.SUSPENDED
    ) {
      throw new UnauthorizedException('Account is suspended or banned');
    }

    return {
      id: user.id,
      types: user.types,
      email: user.email,
      phone: user.phone,
      name: user.name,
      status: user.status,
    };
  }
}
