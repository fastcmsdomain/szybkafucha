import { User } from '../../users/entities/user.entity';
import { Task } from './task.entity';
export declare class Rating {
    id: string;
    taskId: string;
    task: Task;
    fromUserId: string;
    fromUser: User;
    toUserId: string;
    toUser: User;
    rating: number;
    comment: string | null;
    createdAt: Date;
}
