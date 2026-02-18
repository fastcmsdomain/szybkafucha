/**
 * Task Entity
 * Represents a task/job posted by a client and potentially accepted by a contractor
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

// Task status enum following the state machine from PRD
export enum TaskStatus {
  CREATED = 'created',
  ACCEPTED = 'accepted',
  CONFIRMED = 'confirmed', // Client confirmed the contractor
  IN_PROGRESS = 'in_progress',
  PENDING_COMPLETE = 'pending_complete', // Client confirmed completion, waiting for contractor to finalize
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  DISPUTED = 'disputed',
}

@Entity('tasks')
export class Task {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  // Client who posted the task
  @Column('uuid')
  clientId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'clientId' })
  client: User;

  // Contractor who accepted the task (null until accepted)
  @Column('uuid', { nullable: true })
  contractorId: string | null;

  @ManyToOne(() => User, { nullable: true })
  @JoinColumn({ name: 'contractorId' })
  contractor: User | null;

  // Task category (stored as TaskCategory string key, e.g. paczki, hydraulik)
  @Column({ type: 'varchar', length: 50 })
  category: string;

  // Short title for the task
  @Column({ type: 'varchar', length: 200 })
  title: string;

  // Detailed description
  @Column({ type: 'text', nullable: true })
  description: string | null;

  // Location coordinates
  @Column({ type: 'decimal', precision: 10, scale: 7 })
  locationLat: number;

  @Column({ type: 'decimal', precision: 10, scale: 7 })
  locationLng: number;

  // Human-readable address
  @Column({ type: 'text' })
  address: string;

  // Budget and payment amounts
  @Column({ type: 'decimal', precision: 10, scale: 2 })
  budgetAmount: number;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  finalAmount: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, nullable: true })
  commissionAmount: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 2, default: 0 })
  tipAmount: number;

  // Estimated duration in hours (e.g., 1.5 = 1h 30min)
  @Column({ type: 'decimal', precision: 4, scale: 1, nullable: true })
  estimatedDurationHours: number | null;

  // Maximum number of contractor applications allowed (bidding system)
  @Column({ type: 'int', default: 5 })
  maxApplications: number;

  // Task status
  @Column({
    type: 'enum',
    enum: TaskStatus,
    default: TaskStatus.CREATED,
  })
  status: TaskStatus;

  // Photo proof of completion
  @Column({ type: 'simple-array', nullable: true })
  completionPhotos: string[] | null;

  // Task images (added by client during creation)
  @Column({ type: 'simple-array', nullable: true })
  imageUrls: string[] | null;

  // Timestamps for task lifecycle
  @Column({ type: 'timestamp', nullable: true })
  scheduledAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  acceptedAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  confirmedAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  startedAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date | null;

  // Dual-rating tracking - status changes to COMPLETED only when both have rated
  @Column({ type: 'boolean', default: false })
  clientRated: boolean;

  @Column({ type: 'boolean', default: false })
  contractorRated: boolean;

  @Column({ type: 'timestamp', nullable: true })
  cancelledAt: Date | null;

  // Cancellation reason if cancelled
  @Column({ type: 'text', nullable: true })
  cancellationReason: string | null;

  @CreateDateColumn()
  createdAt: Date;
}
