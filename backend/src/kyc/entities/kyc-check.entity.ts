/**
 * KYC Check Entity
 * Tracks individual verification checks from Onfido
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

// KYC check types
export enum KycCheckType {
  DOCUMENT = 'document',
  FACIAL_SIMILARITY = 'facial_similarity',
  BANK_ACCOUNT = 'bank_account',
}

// Check status
export enum KycCheckStatus {
  PENDING = 'pending',
  IN_PROGRESS = 'in_progress',
  COMPLETE = 'complete',
  FAILED = 'failed',
}

// Check result
export enum KycCheckResult {
  CLEAR = 'clear',
  CONSIDER = 'consider',
  UNIDENTIFIED = 'unidentified',
}

@Entity('kyc_checks')
export class KycCheck {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({
    type: 'enum',
    enum: KycCheckType,
  })
  type: KycCheckType;

  // Onfido applicant ID
  @Column({ type: 'varchar', length: 255, nullable: true })
  onfidoApplicantId: string | null;

  // Onfido check/report ID
  @Column({ type: 'varchar', length: 255, nullable: true })
  onfidoCheckId: string | null;

  // Onfido document ID (for document checks)
  @Column({ type: 'varchar', length: 255, nullable: true })
  onfidoDocumentId: string | null;

  @Column({
    type: 'enum',
    enum: KycCheckStatus,
    default: KycCheckStatus.PENDING,
  })
  status: KycCheckStatus;

  @Column({
    type: 'enum',
    enum: KycCheckResult,
    nullable: true,
  })
  result: KycCheckResult | null;

  // Detailed result data from Onfido
  @Column({ type: 'jsonb', nullable: true })
  resultDetails: Record<string, any> | null;

  // Error message if failed
  @Column({ type: 'text', nullable: true })
  errorMessage: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  completedAt: Date | null;
}
