import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { UsersService } from '../users/users.service';
import { User, UserType } from '../users/entities/user.entity';
export declare class AuthService {
    private readonly usersService;
    private readonly jwtService;
    private readonly configService;
    constructor(usersService: UsersService, jwtService: JwtService, configService: ConfigService);
    generateToken(user: User): {
        accessToken: string;
        user: Partial<User>;
    };
    requestPhoneOtp(phone: string): Promise<{
        message: string;
        expiresIn: number;
    }>;
    verifyPhoneOtp(phone: string, code: string, userType?: UserType): Promise<{
        accessToken: string;
        user: Partial<User>;
        isNewUser: boolean;
    }>;
    authenticateWithGoogle(googleId: string, email: string, name?: string, avatarUrl?: string, userType?: UserType): Promise<{
        accessToken: string;
        user: Partial<User>;
        isNewUser: boolean;
    }>;
    authenticateWithApple(appleId: string, email?: string, name?: string, userType?: UserType): Promise<{
        accessToken: string;
        user: Partial<User>;
        isNewUser: boolean;
    }>;
    private generateOtp;
    private normalizePhone;
}
