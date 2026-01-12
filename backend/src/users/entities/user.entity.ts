/**
 * User Entity
 * Represents both clients and contractors in the Szybka Fucha platform
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

// User type enum
export enum UserType {
  CLIENT = 'client',
  CONTRACTOR = 'contractor',
}

// User status enum
export enum UserStatus {
  PENDING = 'pending',
  ACTIVE = 'active',
  SUSPENDED = 'suspended',
  BANNED = 'banned',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({
    type: 'enum',
    enum: UserType,
    default: UserType.CLIENT,
  })
  type: UserType;

  @Column({ type: 'varchar', length: 15, unique: true, nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', length: 255, unique: true, nullable: true })
  email: string | null;

  @Column({ type: 'varchar', length: 100, nullable: true })
  name: string | null;

  @Column({ type: 'text', nullable: true })
  avatarUrl: string | null;

  @Column({
    type: 'enum',
    enum: UserStatus,
    default: UserStatus.PENDING,
  })
  status: UserStatus;

  // Social login identifiers
  @Column({ type: 'varchar', length: 255, unique: true, nullable: true })
  googleId: string | null;

  @Column({ type: 'varchar', length: 255, unique: true, nullable: true })
  appleId: string | null;

  // Push notification token
  @Column({ type: 'text', nullable: true })
  fcmToken: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
