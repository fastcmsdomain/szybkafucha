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
import { UsersService } from '../users/users.service';
import { Rating } from '../tasks/entities/rating.entity';

type RatingAggregateRow = {
  avg: string | null;
  count: string | null;
};

@Injectable()
export class ContractorService {
  constructor(
    @InjectRepository(ContractorProfile)
    private readonly contractorRepository: Repository<ContractorProfile>,
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    private readonly usersService: UsersService,
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
   * Automatically creates profile if it doesn't exist (lazy creation)
   */
  async update(
    userId: string,
    dto: UpdateContractorProfileDto,
  ): Promise<ContractorProfile> {
    let profile = await this.findByUserId(userId);

    // Lazy creation: create profile if it doesn't exist
    if (!profile) {
      profile = await this.create(userId);
    }

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
   * Check if contractor profile is complete
   * Required fields: name, address, bio, categories (min 1), service radius, KYC verified
   */
  async isProfileComplete(userId: string): Promise<boolean> {
    const user = await this.usersService.findById(userId);
    const profile = await this.findByUserId(userId);

    if (!user || !profile) {
      return false;
    }

    return !!(
      user.name &&
      user.address &&
      profile.bio &&
      profile.categories.length > 0 &&
      profile.serviceRadiusKm &&
      profile.kycStatus === KycStatus.VERIFIED
    );
  }

  /**
   * Get contractor profile with aggregated ratings
   * Calculates average rating and count from ratings table where toUserId = contractorId AND role = 'contractor'
   */
  async getContractorProfile(userId: string): Promise<{
    ratingAvg: number;
    ratingCount: number;
    completedTasksCount: number;
    categories: string[];
    serviceRadiusKm: number | null;
  }> {
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'avg')
      .addSelect('COUNT(rating.id)', 'count')
      .where('rating.toUserId = :userId', { userId })
      .andWhere('rating.role = :role', { role: 'contractor' }) // NEW: Filter by contractor role
      .getRawOne<RatingAggregateRow>();

    // Handle case when contractor has no ratings
    const ratingAvg = result?.avg ? parseFloat(result.avg) : 0.0;
    const ratingCount = result?.count ? parseInt(result.count, 10) : 0;

    // Get contractor profile for other data
    const profile = await this.findByUserId(userId);

    return {
      ratingAvg,
      ratingCount,
      completedTasksCount: profile?.completedTasksCount || 0,
      categories: profile?.categories || [],
      serviceRadiusKm: profile?.serviceRadiusKm || null,
    };
  }

  /**
   * Get contractor reviews with aggregated rating data
   */
  async getContractorReviews(userId: string): Promise<{
    ratingAvg: number;
    ratingCount: number;
    reviews: Array<{
      id: string;
      rating: number;
      comment: string | null;
      createdAt: Date;
    }>;
  }> {
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'avg')
      .addSelect('COUNT(rating.id)', 'count')
      .where('rating.toUserId = :userId', { userId })
      .andWhere('rating.role = :role', { role: 'contractor' })
      .getRawOne<RatingAggregateRow>();

    const reviews = await this.ratingRepository.find({
      where: {
        toUserId: userId,
        role: 'contractor',
      },
      select: {
        id: true,
        rating: true,
        comment: true,
        createdAt: true,
      },
      order: {
        createdAt: 'DESC',
      },
    });

    return {
      ratingAvg: result?.avg ? parseFloat(result.avg) : 0.0,
      ratingCount: result?.count ? parseInt(result.count, 10) : 0,
      reviews,
    };
  }

  /**
   * Get public contractor reviews with aggregated rating data
   * Returns latest 5 reviews for client-facing views
   */
  async getPublicContractorReviews(userId: string): Promise<{
    ratingAvg: number;
    ratingCount: number;
    reviews: Array<{
      id: string;
      rating: number;
      comment: string | null;
      createdAt: Date;
    }>;
  }> {
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'avg')
      .addSelect('COUNT(rating.id)', 'count')
      .where('rating.toUserId = :userId', { userId })
      .andWhere('rating.role = :role', { role: 'contractor' })
      .getRawOne<RatingAggregateRow>();

    const reviews = await this.ratingRepository.find({
      where: {
        toUserId: userId,
        role: 'contractor',
      },
      select: {
        id: true,
        rating: true,
        comment: true,
        createdAt: true,
      },
      order: {
        createdAt: 'DESC',
      },
      take: 5,
    });

    return {
      ratingAvg: result?.avg ? parseFloat(result.avg) : 0.0,
      ratingCount: result?.count ? parseInt(result.count, 10) : 0,
      reviews,
    };
  }

  /**
   * Toggle contractor availability
   */
  async setAvailability(
    userId: string,
    isOnline: boolean,
  ): Promise<ContractorProfile> {
    const profile = await this.findByUserIdOrFail(userId);

    // TODO: Re-enable KYC check before production (see docs/todo_post_MVP/KYC_VERIFICATION.md)
    // Cannot go online if not verified
    // if (isOnline && profile.kycStatus !== KycStatus.VERIFIED) {
    //   throw new BadRequestException(
    //     'Complete KYC verification before going online',
    //   );
    // }

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
   * Get public contractor profile (for clients viewing contractor)
   * Combines User + ContractorProfile data, excluding sensitive fields
   * Falls back to User data if no contractor profile exists
   */
  async getPublicProfile(userId: string): Promise<{
    id: string;
    name: string;
    avatarUrl: string | null;
    bio: string | null;
    ratingAvg: number;
    ratingCount: number;
    completedTasksCount: number;
    categories: string[];
    isVerified: boolean;
    memberSince: Date;
  }> {
    // Try to find contractor profile with user relation
    const profile = await this.contractorRepository.findOne({
      where: { userId },
      relations: ['user'],
    });

    // If contractor profile exists, return full data with real computed ratings
    if (profile && profile.user) {
      // Compute real ratings from ratings table instead of stale cached values
      const ratingResult = await this.ratingRepository
        .createQueryBuilder('rating')
        .select('AVG(rating.rating)', 'avg')
        .addSelect('COUNT(rating.id)', 'count')
        .where('rating.toUserId = :userId', { userId })
        .andWhere('rating.role = :role', { role: 'contractor' })
        .getRawOne<RatingAggregateRow>();

      const computedRatingAvg = ratingResult?.avg ? parseFloat(ratingResult.avg) : 0.0;
      const computedRatingCount = ratingResult?.count ? parseInt(ratingResult.count, 10) : 0;

      return {
        id: profile.userId,
        name: profile.user.name || 'Wykonawca',
        avatarUrl: profile.user.avatarUrl || null,
        bio: profile.bio || null,
        ratingAvg: computedRatingAvg,
        ratingCount: computedRatingCount,
        completedTasksCount: profile.completedTasksCount || 0,
        categories: profile.categories || [],
        isVerified: profile.kycStatus === KycStatus.VERIFIED,
        memberSince: profile.createdAt,
      };
    }

    // Fall back to User data if no contractor profile exists
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('Contractor not found');
    }

    // Return basic profile from User data (no bio since it's role-specific)
    return {
      id: user.id,
      name: user.name || 'Wykonawca',
      avatarUrl: user.avatarUrl || null,
      bio: null, // Bio is role-specific, stored in contractor_profiles
      ratingAvg: 0,
      ratingCount: 0,
      completedTasksCount: 0,
      categories: [],
      isVerified: false,
      memberSince: user.createdAt,
    };
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
