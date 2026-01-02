import { AuthService } from './auth.service';
import { RequestOtpDto } from './dto/request-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { GoogleAuthDto } from './dto/google-auth.dto';
import { AppleAuthDto } from './dto/apple-auth.dto';
export declare class AuthController {
    private readonly authService;
    constructor(authService: AuthService);
    requestOtp(dto: RequestOtpDto): Promise<{
        message: string;
        expiresIn: number;
    }>;
    verifyOtp(dto: VerifyOtpDto): Promise<{
        accessToken: string;
        user: Partial<import("../users/entities/user.entity").User>;
        isNewUser: boolean;
    }>;
    googleAuth(dto: GoogleAuthDto): Promise<{
        accessToken: string;
        user: Partial<import("../users/entities/user.entity").User>;
        isNewUser: boolean;
    }>;
    appleAuth(dto: AppleAuthDto): Promise<{
        accessToken: string;
        user: Partial<import("../users/entities/user.entity").User>;
        isNewUser: boolean;
    }>;
}
