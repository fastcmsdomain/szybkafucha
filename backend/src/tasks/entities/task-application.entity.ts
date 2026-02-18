/**
 * Task Application Entity
 * Represents a contractor's application/bid for a task
 */
import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  Unique,
  Index,
} from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { Task } from './task.entity';

export enum ApplicationStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
  WITHDRAWN = 'withdrawn',
}

@Entity('task_applications')
@Unique(['taskId', 'contractorId'])
@Index(['taskId', 'status'])
@Index(['contractorId', 'status'])
export class TaskApplication {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  taskId: string;

  @ManyToOne(() => Task)
  @JoinColumn({ name: 'taskId' })
  task: Task;

  @Column('uuid')
  contractorId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'contractorId' })
  contractor: User;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  proposedPrice: number;

  @Column({ type: 'text', nullable: true })
  message: string | null;

  @Column({
    type: 'enum',
    enum: ApplicationStatus,
    default: ApplicationStatus.PENDING,
  })
  status: ApplicationStatus;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  respondedAt: Date | null;
}
