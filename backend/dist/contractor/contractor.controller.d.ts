import { ContractorService } from './contractor.service';
import { UpdateContractorProfileDto } from './dto/update-contractor-profile.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
export declare class ContractorController {
    private readonly contractorService;
    constructor(contractorService: ContractorService);
    getProfile(req: any): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
    updateProfile(req: any, dto: UpdateContractorProfileDto): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
    setAvailability(req: any, isOnline: boolean): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
    updateLocation(req: any, dto: UpdateLocationDto): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
    submitKycId(req: any, documentUrl: string): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
    submitKycSelfie(req: any, selfieUrl: string): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
    submitKycBank(req: any, iban: string, accountHolder: string): Promise<import("./entities/contractor-profile.entity").ContractorProfile>;
}
