export declare enum UserType {
    CLIENT = "client",
    CONTRACTOR = "contractor"
}
export declare enum UserStatus {
    PENDING = "pending",
    ACTIVE = "active",
    SUSPENDED = "suspended",
    BANNED = "banned"
}
export declare class User {
    id: string;
    type: UserType;
    phone: string | null;
    email: string | null;
    name: string | null;
    avatarUrl: string | null;
    status: UserStatus;
    googleId: string | null;
    appleId: string | null;
    fcmToken: string | null;
    createdAt: Date;
    updatedAt: Date;
}
