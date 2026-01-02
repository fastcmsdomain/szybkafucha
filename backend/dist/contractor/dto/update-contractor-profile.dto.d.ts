import { TaskCategory } from '../entities/contractor-profile.entity';
export declare class UpdateContractorProfileDto {
    bio?: string;
    categories?: TaskCategory[];
    serviceRadiusKm?: number;
}
