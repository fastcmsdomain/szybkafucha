import { UserType } from '../../users/entities/user.entity';
export declare class GoogleAuthDto {
    googleId: string;
    email: string;
    name?: string;
    avatarUrl?: string;
    userType?: UserType;
}
