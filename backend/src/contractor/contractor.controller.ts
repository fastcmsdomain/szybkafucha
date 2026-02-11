/**
 * Contractor Controller
 * REST endpoints for contractor-specific operations
 */
import {
  Controller,
  Get,
  Put,
  Post,
  Body,
  UseGuards,
  Request,
  Param,
} from '@nestjs/common';
import { ContractorService } from './contractor.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateContractorProfileDto } from './dto/update-contractor-profile.dto';
import { UpdateLocationDto } from './dto/update-location.dto';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';

@Controller('contractor')
@UseGuards(JwtAuthGuard)
export class ContractorController {
  constructor(private readonly contractorService: ContractorService) {}

  /**
   * GET /contractor/:userId/public
   * Get public contractor profile for clients viewing contractor
   * Returns safe public fields: name, avatar, bio, ratings, categories
   */
  @Get(':userId/public')
  async getPublicProfile(@Param('userId') userId: string) {
    return this.contractorService.getPublicProfile(userId);
  }

  /**
   * GET /contractor/:userId/reviews
   * Get public contractor reviews for client-facing views
   */
  @Get(':userId/reviews')
  async getPublicReviews(@Param('userId') userId: string) {
    return this.contractorService.getPublicContractorReviews(userId);
  }

  /**
   * GET /contractor/profile
   * Get current contractor's profile
   */
  @Get('profile')
  async getProfile(@Request() req: AuthenticatedRequest) {
    // Create profile if doesn't exist
    let profile = await this.contractorService.findByUserId(req.user.id);
    if (!profile) {
      profile = await this.contractorService.create(req.user.id);
    }
    return profile;
  }

  /**
   * GET /contractor/reviews
   * Get current contractor's reviews list with rating summary
   */
  @Get('reviews')
  async getReviews(@Request() req: AuthenticatedRequest) {
    return this.contractorService.getContractorReviews(req.user.id);
  }

  /**
   * PUT /contractor/profile
   * Update contractor profile (bio, categories, radius)
   * Automatically creates profile if it doesn't exist (lazy creation)
   */
  @Put('profile')
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateContractorProfileDto,
  ) {
    return this.contractorService.update(req.user.id, dto);
  }

  /**
   * GET /contractor/profile/complete
   * Check if contractor profile is complete
   * Returns: { complete: boolean }
   */
  @Get('profile/complete')
  async checkProfileComplete(@Request() req: AuthenticatedRequest) {
    return {
      complete: await this.contractorService.isProfileComplete(req.user.id),
    };
  }

  /**
   * PUT /contractor/availability
   * Toggle online/offline status
   */
  @Put('availability')
  async setAvailability(
    @Request() req: AuthenticatedRequest,
    @Body('isOnline') isOnline: boolean,
  ) {
    return this.contractorService.setAvailability(req.user.id, isOnline);
  }

  /**
   * PUT /contractor/location
   * Update GPS coordinates
   */
  @Put('location')
  async updateLocation(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateLocationDto,
  ) {
    return this.contractorService.updateLocation(req.user.id, dto);
  }

  /**
   * POST /contractor/kyc/id
   * Submit ID document for verification
   */
  @Post('kyc/id')
  async submitKycId(
    @Request() req: AuthenticatedRequest,
    @Body('documentUrl') documentUrl: string,
  ) {
    return this.contractorService.submitKycId(req.user.id, documentUrl);
  }

  /**
   * POST /contractor/kyc/selfie
   * Submit selfie for verification
   */
  @Post('kyc/selfie')
  async submitKycSelfie(
    @Request() req: AuthenticatedRequest,
    @Body('selfieUrl') selfieUrl: string,
  ) {
    return this.contractorService.submitKycSelfie(req.user.id, selfieUrl);
  }

  /**
   * POST /contractor/kyc/bank
   * Submit bank account for payouts
   */
  @Post('kyc/bank')
  async submitKycBank(
    @Request() req: AuthenticatedRequest,
    @Body('iban') iban: string,
    @Body('accountHolder') accountHolder: string,
  ) {
    return this.contractorService.submitKycBank(
      req.user.id,
      iban,
      accountHolder,
    );
  }
}
