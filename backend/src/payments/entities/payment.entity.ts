/**
 * Payment Entity
 * Tracks payment status for tasks using Stripe
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Task } from '../../tasks/entities/task.entity';

// Payment status enum
export enum PaymentStatus {
  PENDING = 'pending',
  HELD = 'held',
  CAPTURED = 'captured',
  REFUNDED = 'refunded',
  FAILED = 'failed',
}

@Entity('payments')
export class Payment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  taskId: string;

  @ManyToOne(() => Task)
  @JoinColumn({ name: 'taskId' })
  task: Task;

  // Stripe PaymentIntent ID
  @Column({ length: 255, nullable: true })
  stripePaymentIntentId: string | null;

  // Stripe Transfer ID (for contractor payout)
  @Column({ length: 255, nullable: true })
  stripeTransferId: string | null;

  // Total amount charged to client
  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  // Platform commission
  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  commissionAmount: number | null;

  // Amount transferred to contractor
  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  contractorAmount: number | null;

  // Payment status
  @Column({
    type: 'enum',
    enum: PaymentStatus,
    default: PaymentStatus.PENDING,
  })
  status: PaymentStatus;

  // Refund reason if refunded
  @Column({ type: 'text', nullable: true })
  refundReason: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
