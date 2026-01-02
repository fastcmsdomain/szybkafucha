import { User } from '../../users/entities/user.entity';
export declare enum TaskStatus {
    CREATED = "created",
    ACCEPTED = "accepted",
    IN_PROGRESS = "in_progress",
    COMPLETED = "completed",
    CANCELLED = "cancelled",
    DISPUTED = "disputed"
}
export declare class Task {
    id: string;
    clientId: string;
    client: User;
    contractorId: string | null;
    contractor: User | null;
    category: string;
    title: string;
    description: string | null;
    locationLat: number;
    locationLng: number;
    address: string;
    budgetAmount: number;
    finalAmount: number | null;
    commissionAmount: number | null;
    tipAmount: number;
    status: TaskStatus;
    completionPhotos: string[] | null;
    scheduledAt: Date | null;
    acceptedAt: Date | null;
    startedAt: Date | null;
    completedAt: Date | null;
    cancelledAt: Date | null;
    cancellationReason: string | null;
    createdAt: Date;
}
