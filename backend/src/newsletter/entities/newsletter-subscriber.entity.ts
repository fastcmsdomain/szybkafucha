/**
 * Newsletter Subscriber Entity
 * Stores newsletter signups from landing page
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  Index,
} from 'typeorm';

// User type enum for newsletter subscribers
export enum UserType {
  CLIENT = 'client',
  CONTRACTOR = 'contractor',
}

@Entity('newsletter_subscribers')
@Index(['email'], { unique: true })
export class NewsletterSubscriber {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'varchar', length: 255 })
  name: string;

  @Column({ type: 'varchar', length: 255 })
  email: string;

  @Column({
    type: 'varchar',
    length: 20,
  })
  userType: UserType;

  @Column({ type: 'boolean', default: true })
  consent: boolean;

  @Column({ type: 'varchar', length: 50, nullable: true })
  source: string | null; // e.g., 'landing_page', 'landing_page_hero'

  @Column({ type: 'boolean', default: true })
  isActive: boolean;

  @Column({ type: 'timestamp', nullable: true })
  subscribedAt: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  unsubscribedAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
