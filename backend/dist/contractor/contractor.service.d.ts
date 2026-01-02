import { Repository } from 'typeorm';
import { ContractorProfile } from './entities/contractor-profile.entity';
import { UpdateContractorProfileDto } from './dto/update-contractor-profile.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
export declare class ContractorService {
    private readonly contractorRepository;
    constructor(contractorRepository: Repository<ContractorProfile>);
    findByUserId(userId: string): Promise<ContractorProfile | null>;
    findByUserIdOrFail(userId: string): Promise<ContractorProfile>;
    create(userId: string): Promise<ContractorProfile>;
    update(userId: string, dto: UpdateContractorProfileDto): Promise<ContractorProfile>;
    setAvailability(userId: string, isOnline: boolean): Promise<ContractorProfile>;
    updateLocation(userId: string, location: UpdateLocationDto): Promise<ContractorProfile>;
    submitKycId(userId: string, documentUrl: string): Promise<ContractorProfile>;
    submitKycSelfie(userId: string, selfieUrl: string): Promise<ContractorProfile>;
    submitKycBank(userId: string, iban: string, accountHolder: string): Promise<ContractorProfile>;
    updateRating(userId: string, newRating: number): Promise<ContractorProfile>;
    incrementCompletedTasks(userId: string): Promise<ContractorProfile>;
    private updateKycStatus;
    private validateIban;
}
