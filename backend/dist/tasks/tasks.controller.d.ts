import { TasksService } from './tasks.service';
import { CreateTaskDto } from './dto/create-task.dto';
import { RateTaskDto } from './dto/rate-task.dto';
export declare class TasksController {
    private readonly tasksService;
    constructor(tasksService: TasksService);
    create(req: any, createTaskDto: CreateTaskDto): Promise<import("./entities/task.entity").Task>;
    findAll(req: any, lat?: number, lng?: number, categories?: string, radiusKm?: number): Promise<import("./entities/task.entity").Task[]>;
    findOne(id: string): Promise<import("./entities/task.entity").Task>;
    accept(req: any, id: string): Promise<import("./entities/task.entity").Task>;
    start(req: any, id: string): Promise<import("./entities/task.entity").Task>;
    complete(req: any, id: string, completionPhotos?: string[]): Promise<import("./entities/task.entity").Task>;
    confirm(req: any, id: string): Promise<import("./entities/task.entity").Task>;
    cancel(req: any, id: string, reason?: string): Promise<import("./entities/task.entity").Task>;
    rate(req: any, id: string, rateTaskDto: RateTaskDto): Promise<import("./entities/rating.entity").Rating>;
    addTip(req: any, id: string, amount: number): Promise<import("./entities/task.entity").Task>;
}
