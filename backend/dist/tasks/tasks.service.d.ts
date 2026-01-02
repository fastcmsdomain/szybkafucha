import { Repository } from 'typeorm';
import { Task } from './entities/task.entity';
import { Rating } from './entities/rating.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
export declare class TasksService {
    private readonly tasksRepository;
    private readonly ratingsRepository;
    constructor(tasksRepository: Repository<Task>, ratingsRepository: Repository<Rating>);
    create(clientId: string, dto: CreateTaskDto): Promise<Task>;
    findById(id: string): Promise<Task | null>;
    findByIdOrFail(id: string): Promise<Task>;
    findByClient(clientId: string): Promise<Task[]>;
    findAvailableForContractor(contractorId: string, categories: string[], lat: number, lng: number, radiusKm?: number): Promise<Task[]>;
    acceptTask(taskId: string, contractorId: string): Promise<Task>;
    startTask(taskId: string, contractorId: string): Promise<Task>;
    completeTask(taskId: string, contractorId: string, completionPhotos?: string[]): Promise<Task>;
    confirmTask(taskId: string, clientId: string): Promise<Task>;
    cancelTask(taskId: string, userId: string, reason?: string): Promise<Task>;
    rateTask(taskId: string, fromUserId: string, toUserId: string, dto: RateTaskDto): Promise<Rating>;
    addTip(taskId: string, clientId: string, tipAmount: number): Promise<Task>;
    private calculateDistance;
    private deg2rad;
}
