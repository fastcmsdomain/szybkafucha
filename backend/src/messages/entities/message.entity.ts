/**
 * Message Entity
 * Stores chat messages between client and contractor during a task
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

@Entity('messages')
@Index(['taskId', 'senderId', 'recipientId'])
export class Message {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  taskId: string;

  @ManyToOne(() => Task)
  @JoinColumn({ name: 'taskId' })
  task: Task;

  @Column('uuid')
  senderId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'senderId' })
  sender: User;

  // Recipient of the message (1-to-1 private chat)
  @Column('uuid', { nullable: true })
  recipientId: string | null;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'recipientId' })
  recipient: User;

  // Message content
  @Column({ type: 'text' })
  content: string;

  // Flagged by moderation (company/social media mentions)
  @Column({ type: 'boolean', default: false })
  flagged: boolean;

  // When the message was read by recipient
  @Column({ type: 'timestamp', nullable: true })
  readAt: Date | null;

  @CreateDateColumn()
  createdAt: Date;
}
