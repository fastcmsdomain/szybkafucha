/**
 * Credit Transaction Entity
 * Tracks all credit movements: top-ups, matching fee deductions, refunds, bonuses
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Task } from '../../tasks/entities/task.entity';

export enum CreditTransactionType {
  TOPUP = 'topup',
  DEDUCTION = 'deduction',
  REFUND = 'refund',
  BONUS = 'bonus',
}

@Entity('credit_transactions')
@Index(['userId', 'createdAt'])
export class CreditTransaction {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  userId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'userId' })
  user: User;

  // Positive = credit added, negative = credit deducted
  @Column({ type: 'decimal', precision: 10, scale: 2 })
  amount: number;

  @Column({
    type: 'enum',
    enum: CreditTransactionType,
  })
  type: CreditTransactionType;

  // Related task (for deduction/refund)
  @Column('uuid', { nullable: true })
  taskId: string | null;

  @ManyToOne(() => Task, { nullable: true })
  @JoinColumn({ name: 'taskId' })
  task: Task | null;

  // Stripe PaymentIntent ID (for top-ups)
  @Column({ type: 'varchar', length: 255, nullable: true })
  stripePaymentIntentId: string | null;

  @Column({ type: 'varchar', length: 500 })
  description: string;

  @CreateDateColumn()
  createdAt: Date;
}
