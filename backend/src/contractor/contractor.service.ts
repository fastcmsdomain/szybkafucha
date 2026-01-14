/**
 * Contractor Service
 * Business logic for contractor operations
 */
import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  ContractorProfile,
  KycStatus,
} from './entities/contractor-profile.entity';
import { UpdateContractorProfileDto } from './dto/update-contractor-profile.dto';
import { UpdateLocationDto } from './dto/update-location.dto';

@Injectable()
export class ContractorService {
  constructor(
    @InjectRepository(ContractorProfile)
    private readonly contractorRepository: Repository<ContractorProfile>,
  ) {}

  /**
   * Get contractor profile
   */
  async findByUserId(userId: string): Promise<ContractorProfile | null> {
    return this.contractorRepository.findOne({
      where: { userId },
      relations: ['user'],
    });
  }

  /**
   * Get contractor profile or throw error
   */
  async findByUserIdOrFail(userId: string): Promise<ContractorProfile> {
    const profile = await this.findByUserId(userId);
    if (!profile) {
      throw new NotFoundException('Contractor profile not found');
    }
    return profile;
  }

  /**
   * Create contractor profile for a user
   */
  async create(userId: string): Promise<ContractorProfile> {
    const existing = await this.findByUserId(userId);
    if (existing) {
      return existing;
    }

    const profile = this.contractorRepository.create({
      userId,
      categories: [],
    });

    return this.contractorRepository.save(profile);
  }

  /**
   * Update contractor profile
   */
  async update(
    userId: string,
    dto: UpdateContractorProfileDto,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);

    if (dto.bio !== undefined) {
      profile.bio = dto.bio;
    }

    if (dto.categories !== undefined) {
      profile.categories = dto.categories;
    }

    if (dto.serviceRadiusKm !== undefined) {
      profile.serviceRadiusKm = dto.serviceRadiusKm;
    }

    return this.contractorRepository.save(profile);
  }

  /**
   * Toggle contractor availability
   */
  async setAvailability(
    userId: string,
    isOnline: boolean,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);

    // Cannot go online if not verified
    if (isOnline && profile.kycStatus !== KycStatus.VERIFIED) {
      throw new BadRequestException(
        'Complete KYC verification before going online',
      );
    }

    profile.isOnline = isOnline;
    return this.contractorRepository.save(profile);
  }

  /**
   * Update contractor location
   */
  async updateLocation(
    userId: string,
    location: UpdateLocationDto,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);

    profile.lastLocationLat = location.lat;
    profile.lastLocationLng = location.lng;
    profile.lastLocationAt = new Date();

    return this.contractorRepository.save(profile);
  }

  /**
   * Submit ID document for KYC verification
   * In production, integrate with Onfido API
   */
  async submitKycId(
    userId: string,
    _documentUrl: string,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);
    void _documentUrl;

    // TODO: Send to Onfido for verification
    // For MVP, mark as verified immediately (development only)
    profile.kycIdVerified = true;
    this.updateKycStatus(profile);

    return this.contractorRepository.save(profile);
  }

  /**
   * Submit selfie for KYC verification
   */
  async submitKycSelfie(
    userId: string,
    _selfieUrl: string,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);
    void _selfieUrl;

    // TODO: Send to Onfido for face match
    // For MVP, mark as verified immediately (development only)
    profile.kycSelfieVerified = true;
    this.updateKycStatus(profile);

    return this.contractorRepository.save(profile);
  }

  /**
   * Submit bank account for payouts
   */
  async submitKycBank(
    userId: string,
    iban: string,
    _accountHolder: string,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);
    void _accountHolder;

    // Validate IBAN format (basic validation)
    if (!this.validateIban(iban)) {
      throw new BadRequestException('Invalid IBAN format');
    }

    // TODO: Create Stripe Connect account
    profile.kycBankVerified = true;
    this.updateKycStatus(profile);

    return this.contractorRepository.save(profile);
  }

  /**
   * Update contractor rating after a new rating is submitted
   */
  async updateRating(
    userId: string,
    newRating: number,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);

    // Calculate new average
    const totalRatings =
      profile.ratingCount * Number(profile.ratingAvg) + newRating;
    profile.ratingCount += 1;
    profile.ratingAvg = Number((totalRatings / profile.ratingCount).toFixed(2));

    return this.contractorRepository.save(profile);
  }

  /**
   * Increment completed tasks count
   */
  async incrementCompletedTasks(userId: string): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);
    profile.completedTasksCount += 1;
    return this.contractorRepository.save(profile);
  }

  /**
   * Update overall KYC status based on individual verifications
   */
  private updateKycStatus(profile: ContractorProfile): void {
    if (
      profile.kycIdVerified &&
      profile.kycSelfieVerified &&
      profile.kycBankVerified
    ) {
      profile.kycStatus = KycStatus.VERIFIED;
    }
  }

  /**
   * Basic IBAN validation
   */
  private validateIban(iban: string): boolean {
    // Remove spaces and convert to uppercase
    const cleanIban = iban.replace(/\s/g, '').toUpperCase();

    // Check minimum length and format
    if (cleanIban.length < 15 || cleanIban.length > 34) {
      return false;
    }

    // Check if starts with country code (2 letters) followed by 2 digits
    const ibanRegex = /^[A-Z]{2}[0-9]{2}[A-Z0-9]+$/;
    return ibanRegex.test(cleanIban);
  }
}
