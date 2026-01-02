import { User } from '../../users/entities/user.entity';
export declare enum KycStatus {
    PENDING = "pending",
    VERIFIED = "verified",
    REJECTED = "rejected"
}
export declare enum TaskCategory {
    PACZKI = "paczki",
    ZAKUPY = "zakupy",
    KOLEJKI = "kolejki",
    MONTAZ = "montaz",
    PRZEPROWADZKI = "przeprowadzki",
    SPRZATANIE = "sprzatanie"
}
export declare class ContractorProfile {
    userId: string;
    user: User;
    bio: string | null;
    categories: string[];
    serviceRadiusKm: number;
    kycStatus: KycStatus;
    kycIdVerified: boolean;
    kycSelfieVerified: boolean;
    kycBankVerified: boolean;
    stripeAccountId: string | null;
    ratingAvg: number;
    ratingCount: number;
    completedTasksCount: number;
    isOnline: boolean;
    lastLocationLat: number | null;
    lastLocationLng: number | null;
    lastLocationAt: Date | null;
    createdAt: Date;
    updatedAt: Date;
}
