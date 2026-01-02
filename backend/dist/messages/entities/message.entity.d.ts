import { User } from '../../users/entities/user.entity';
import { Task } from '../../tasks/entities/task.entity';
export declare class Message {
    id: string;
    taskId: string;
    task: Task;
    senderId: string;
    sender: User;
    content: string;
    readAt: Date | null;
    createdAt: Date;
}
