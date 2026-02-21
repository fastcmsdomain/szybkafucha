/**
 * DeletedAccount Entity
 * Immutable archive of all user data captured at the moment of account deletion.
 * Kept for legal / audit purposes. Never updated after creation.
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity('deleted_accounts')
export class DeletedAccount {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  /** Original user UUID — kept for cross-reference with other tables */
  @Column({ type: 'uuid' })
  originalUserId: string;

  /** Roles the user had: ['client'], ['contractor'], or both */
  @Column({ type: 'simple-array', nullable: true })
  userTypes: string[] | null;

  // ── Personal data ──────────────────────────────────────────────────────────

  @Column({ type: 'varchar', length: 255, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 15, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  name: string | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  address: string | null;

  @Column({ type: 'text', nullable: true })
  avatarUrl: string | null;

  /** Bio from contractor_profiles */
  @Column({ type: 'text', nullable: true })
  contractorBio: string | null;

  /** Bio from client_profiles */
  @Column({ type: 'text', nullable: true })
  clientBio: string | null;

  // ── Rating summary ─────────────────────────────────────────────────────────

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0 })
  contractorRatingAvg: number;

  @Column({ type: 'int', default: 0 })
  contractorRatingCount: number;

  @Column({ type: 'decimal', precision: 3, scale: 2, default: 0 })
  clientRatingAvg: number;

  @Column({ type: 'int', default: 0 })
  clientRatingCount: number;

  // ── Full review archive ────────────────────────────────────────────────────

  /**
   * All reviews received by this user, stored as JSONB snapshot.
   * Shape: { taskId, fromUserId, rating, comment, role, createdAt }[]
   */
  @Column({ type: 'jsonb', nullable: true })
  reviews: Array<{
    taskId: string;
    fromUserId: string;
    rating: number;
    comment: string | null;
    role: string;
    createdAt: Date;
  }> | null;

  /** Timestamp when the deletion was processed */
  @CreateDateColumn()
  deletedAt: Date;
}
