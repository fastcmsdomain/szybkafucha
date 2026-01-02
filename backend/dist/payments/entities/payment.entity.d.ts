import { Task } from '../../tasks/entities/task.entity';
export declare enum PaymentStatus {
    PENDING = "pending",
    HELD = "held",
    CAPTURED = "captured",
    REFUNDED = "refunded",
    FAILED = "failed"
}
export declare class Payment {
    id: string;
    taskId: string;
    task: Task;
    stripePaymentIntentId: string | null;
    stripeTransferId: string | null;
    amount: number;
    commissionAmount: number | null;
    contractorAmount: number | null;
    status: PaymentStatus;
    refundReason: string | null;
    createdAt: Date;
}
