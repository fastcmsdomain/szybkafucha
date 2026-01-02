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
} from '@nestjs/common';
import { ContractorService } from './contractor.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateContractorProfileDto } from './dto/update-contractor-profile.dto';
import { UpdateLocationDto } from './dto/update-location.dto';

@Controller('contractor')
@UseGuards(JwtAuthGuard)
export class ContractorController {
  constructor(private readonly contractorService: ContractorService) {}

  /**
   * GET /contractor/profile
   * Get current contractor's profile
   */
  @Get('profile')
  async getProfile(@Request() req: any) {
    // Create profile if doesn't exist
    let profile = await this.contractorService.findByUserId(req.user.id);
    if (!profile) {
      profile = await this.contractorService.create(req.user.id);
    }
    return profile;
  }

  /**
   * PUT /contractor/profile
   * Update contractor profile (bio, categories, radius)
   */
  @Put('profile')
  async updateProfile(
    @Request() req: any,
    @Body() dto: UpdateContractorProfileDto,
  ) {
    // Create profile if doesn't exist
    await this.contractorService.findByUserId(req.user.id) ||
      await this.contractorService.create(req.user.id);
    
    return this.contractorService.update(req.user.id, dto);
  }

  /**
   * PUT /contractor/availability
   * Toggle online/offline status
   */
  @Put('availability')
  async setAvailability(
    @Request() req: any,
    @Body('isOnline') isOnline: boolean,
  ) {
    return this.contractorService.setAvailability(req.user.id, isOnline);
  }

  /**
   * PUT /contractor/location
   * Update GPS coordinates
   */
  @Put('location')
  async updateLocation(@Request() req: any, @Body() dto: UpdateLocationDto) {
    return this.contractorService.updateLocation(req.user.id, dto);
  }

  /**
   * POST /contractor/kyc/id
   * Submit ID document for verification
   */
  @Post('kyc/id')
  async submitKycId(
    @Request() req: any,
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
    @Request() req: any,
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
    @Request() req: any,
    @Body('iban') iban: string,
    @Body('accountHolder') accountHolder: string,
  ) {
    return this.contractorService.submitKycBank(req.user.id, iban, accountHolder);
  }
}
