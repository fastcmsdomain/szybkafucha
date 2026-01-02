/**
 * Contractor Profile Entity
 * Extended profile data for users who are contractors
 */
import {
  Entity,
  PrimaryColumn,
  Column,
  OneToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';

// KYC status enum
export enum KycStatus {
  PENDING = 'pending',
  VERIFIED = 'verified',
  REJECTED = 'rejected',
}

// Available task categories
export enum TaskCategory {
  PACZKI = 'paczki',
  ZAKUPY = 'zakupy',
  KOLEJKI = 'kolejki',
  MONTAZ = 'montaz',
  PRZEPROWADZKI = 'przeprowadzki',
  SPRZATANIE = 'sprzatanie',
}

@Entity('contractor_profiles')
export class ContractorProfile {
  @PrimaryColumn('uuid')
  userId: string;

  @OneToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  @Column({ type: 'text', nullable: true })
  bio: string | null;

  // Categories the contractor can handle
  @Column('simple-array', { default: '' })
  categories: string[];

  // Maximum service radius in kilometers
  @Column({ type: 'int', default: 10 })
  serviceRadiusKm: number;

  // KYC verification status
  @Column({
    type: 'enum',
    enum: KycStatus,
    default: KycStatus.PENDING,
  })
  kycStatus: KycStatus;

  @Column({ type: 'boolean', default: false })
  kycIdVerified: boolean;

  @Column({ type: 'boolean', default: false })
  kycSelfieVerified: boolean;

  @Column({ type: 'boolean', default: false })
  kycBankVerified: boolean;

  // Stripe Connect account for payouts
  @Column({ length: 255, nullable: true })
  stripeAccountId: string | null;

  // Rating statistics
  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0 })
  ratingAvg: number;

  @Column({ type: 'int', default: 0 })
  ratingCount: number;

  @Column({ type: 'int', default: 0 })
  completedTasksCount: number;

  // Availability status
  @Column({ type: 'boolean', default: false })
  isOnline: boolean;

  // Last known location (stored as lat,lng string for simplicity)
  // In production, use PostGIS GEOGRAPHY type
  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  lastLocationLat: number | null;

  @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
  lastLocationLng: number | null;

  @Column({ type: 'timestamp', nullable: true })
  lastLocationAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
