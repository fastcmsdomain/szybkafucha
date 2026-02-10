/**
 * Client Service
 * Business logic for client operations, including ratings aggregation
 */
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Rating } from '../tasks/entities/rating.entity';
import { ClientProfile } from './entities/client-profile.entity';
import { UsersService } from '../users/users.service';
import { UpdateClientProfileDto } from './dto/update-client-profile.dto';

export interface ClientProfileDto {
  userId: string;
  bio: string | null;
  ratingAvg: number;
  ratingCount: number;
}

type RatingAggregateRow = {
  avg: string | null;
  count: string | null;
};

@Injectable()
export class ClientService {
  constructor(
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
    private readonly usersService: UsersService,
  ) {}

  /**
   * Find client profile by user ID
   */
  async findByUserId(userId: string): Promise<ClientProfile | null> {
    return this.clientProfileRepository.findOne({
      where: { userId },
      relations: ['user'],
    });
  }

  /**
   * Find client profile by user ID or throw error
   */
  async findByUserIdOrFail(userId: string): Promise<ClientProfile> {
    const profile = await this.findByUserId(userId);
    if (!profile) {
      throw new NotFoundException('Client profile not found');
    }
    return profile;
  }

  /**
   * Create empty client profile
   * Called when user adds 'client' role or first edits their client profile
   */
  async createProfile(userId: string): Promise<ClientProfile> {
    const existing = await this.findByUserId(userId);
    if (existing) {
      return existing; // Profile already exists, return it
    }

    const profile = this.clientProfileRepository.create({
      userId,
      bio: null,
      ratingAvg: 0,
      ratingCount: 0,
    });

    return this.clientProfileRepository.save(profile);
  }

  /**
   * Update client profile (bio)
   * Automatically creates profile if it doesn't exist (lazy creation)
   */
  async updateProfile(
    userId: string,
    dto: UpdateClientProfileDto,
  ): Promise<ClientProfile> {
    let profile = await this.findByUserId(userId);

    // Lazy creation: create profile if it doesn't exist
    if (!profile) {
      profile = await this.createProfile(userId);
    }

    // Update fields
    if (dto.bio !== undefined) {
      profile.bio = dto.bio;
    }

    return this.clientProfileRepository.save(profile);
  }

  /**
   * Get client profile with aggregated ratings
   * Calculates average rating and count from ratings table where toUserId = clientId AND role = 'client'
   * Also returns bio from client_profiles table
   */
  async getClientProfile(userId: string): Promise<ClientProfileDto> {
    // Get or create client profile (lazy creation)
    let profile = await this.findByUserId(userId);
    if (!profile) {
      profile = await this.createProfile(userId);
    }

    // Get aggregated ratings for client role
    const result = await this.ratingRepository
      .createQueryBuilder('rating')
      .select('AVG(rating.rating)', 'avg')
      .addSelect('COUNT(rating.id)', 'count')
      .where('rating.toUserId = :userId', { userId })
      .andWhere('rating.role = :role', { role: 'client' }) // NEW: Filter by client role
      .getRawOne<RatingAggregateRow>();

    // Handle case when client has no ratings
    const ratingAvg = result?.avg ? parseFloat(result.avg) : 0.0;
    const ratingCount = result?.count ? parseInt(result.count, 10) : 0;

    return {
      userId: profile.userId,
      bio: profile.bio,
      ratingAvg,
      ratingCount,
    };
  }

  /**
   * Get client reviews with aggregated rating data
   */
  async getClientReviews(userId: string): Promise<{
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
      .andWhere('rating.role = :role', { role: 'client' })
      .getRawOne<RatingAggregateRow>();

    const reviews = await this.ratingRepository.find({
      where: {
        toUserId: userId,
        role: 'client',
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
   * Get public client reviews with aggregated rating data
   * Returns latest 5 reviews for contractor-facing views
   */
  async getPublicClientReviews(userId: string): Promise<{
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
      .andWhere('rating.role = :role', { role: 'client' })
      .getRawOne<RatingAggregateRow>();

    const reviews = await this.ratingRepository.find({
      where: {
        toUserId: userId,
        role: 'client',
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
   * Get public client profile for contractors viewing client
   * Returns safe public fields: name, avatar, bio, ratings
   */
  async getPublicProfile(userId: string): Promise<{
    id: string;
    name: string;
    avatarUrl: string | null;
    bio: string | null;
    ratingAvg: number;
    ratingCount: number;
    memberSince: Date;
  }> {
    // Get user data
    const user = await this.usersService.findById(userId);
    if (!user) {
      throw new NotFoundException('Client not found');
    }

    // Get or create client profile (lazy creation)
    let profile = await this.findByUserId(userId);
    if (!profile) {
      profile = await this.createProfile(userId);
    }

    // Get aggregated ratings for client role
    const ratingsData = await this.getClientProfile(userId);

    // Return public profile
    return {
      id: user.id,
      name: user.name || 'Klient',
      avatarUrl: user.avatarUrl || null,
      bio: profile.bio || null, // Use profile.bio instead of user.bio
      ratingAvg: ratingsData.ratingAvg,
      ratingCount: ratingsData.ratingCount,
      memberSince: user.createdAt,
    };
  }
}
