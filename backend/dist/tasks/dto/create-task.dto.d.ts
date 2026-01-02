import { TaskCategory } from '../../contractor/entities/contractor-profile.entity';
export declare class CreateTaskDto {
    category: TaskCategory;
    title: string;
    description?: string;
    locationLat: number;
    locationLng: number;
    address: string;
    budgetAmount: number;
    scheduledAt?: string;
}
