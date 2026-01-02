import { UserType } from '../../users/entities/user.entity';
export declare class VerifyOtpDto {
    phone: string;
    code: string;
    userType?: UserType;
}
