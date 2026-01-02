/**
 * KYC Service
 * Handles identity verification via Onfido
 */
import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import { DefaultApi, Configuration, Region } from '@onfido/api';
import * as IBAN from 'iban';
import { ContractorProfile, KycStatus } from '../contractor/entities/contractor-profile.entity';
import { User } from '../users/entities/user.entity';
import { KycCheck, KycCheckType, KycCheckStatus, KycCheckResult } from './entities/kyc-check.entity';
import {
  UploadIdDocumentDto,
  UploadSelfieDto,
  VerifyBankDto,
  KycStatusResponse,
  OnfidoWebhookPayload,
  DocumentType,
} from './dto/kyc.dto';

@Injectable()
export class KycService {
  private readonly logger = new Logger(KycService.name);
  private readonly onfido: DefaultApi | null;
  private readonly webhookSecret: string;

  constructor(
    @InjectRepository(ContractorProfile)
    private readonly profileRepository: Repository<ContractorProfile>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(KycCheck)
    private readonly kycCheckRepository: Repository<KycCheck>,
    private readonly configService: ConfigService,
  ) {
    const apiToken = this.configService.get<string>('ONFIDO_API_TOKEN');
    const region = this.configService.get<string>('ONFIDO_REGION', 'EU');

    if (!apiToken || apiToken.includes('placeholder')) {
      this.logger.warn('⚠️ Onfido not configured. Using mock mode.');
      this.onfido = null;
    } else {
      const config = new Configuration({
        apiToken,
        region: region === 'US' ? Region.US : Region.EU,
      });
      this.onfido = new DefaultApi(config);
    }

    this.webhookSecret = this.configService.get<string>('ONFIDO_WEBHOOK_SECRET', '');
  }

  /**
   * Get or create Onfido applicant for user
   */
  private async getOrCreateApplicant(userId: string): Promise<string> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    
    if (!user) {
      throw new NotFoundException('User not found');
    }

    // Check if we already have an applicant ID stored
    const existingCheck = await this.getKycChecksForUser(userId);
    const applicantId = existingCheck.find(c => c.onfidoApplicantId)?.onfidoApplicantId;

    if (applicantId) {
      return applicantId;
    }

    // Mock mode
    if (!this.onfido) {
      return `mock_applicant_${userId.slice(0, 8)}`;
    }

    try {
      // Create new Onfido applicant
      const applicant = await this.onfido.createApplicant({
        first_name: user.name?.split(' ')[0] || 'Unknown',
        last_name: user.name?.split(' ').slice(1).join(' ') || 'User',
        email: user.email || undefined,
      });

      return applicant.data.id;
    } catch (error) {
      this.logger.error('Failed to create Onfido applicant:', error);
      throw new InternalServerErrorException('Failed to initialize verification');
    }
  }

  /**
   * Upload ID document for verification
   */
  async uploadIdDocument(
    userId: string,
    dto: UploadIdDocumentDto,
  ): Promise<{ checkId: string; status: string }> {
    const profile = await this.getContractorProfile(userId);

    if (profile.kycIdVerified) {
      throw new BadRequestException('ID already verified');
    }

    const applicantId = await this.getOrCreateApplicant(userId);

    // Create KYC check record
    const kycCheck = new KycCheck();
    kycCheck.userId = userId;
    kycCheck.type = KycCheckType.DOCUMENT;
    kycCheck.onfidoApplicantId = applicantId;
    kycCheck.status = KycCheckStatus.PENDING;

    // Mock mode
    if (!this.onfido) {
      kycCheck.onfidoCheckId = `mock_check_doc_${Date.now()}`;
      kycCheck.onfidoDocumentId = `mock_doc_${Date.now()}`;
      kycCheck.status = KycCheckStatus.IN_PROGRESS;
      
      // Simulate async verification (would be webhook in production)
      setTimeout(() => this.mockVerificationComplete(kycCheck.id, 'document'), 5000);

      await this.saveKycCheck(kycCheck);

      return {
        checkId: kycCheck.id,
        status: 'processing',
      };
    }

    try {
      // Upload document to Onfido
      // Note: In production, use FileTransfer for proper file handling
      const document = await this.onfido.uploadDocument(
        dto.documentType as any, // Cast to DocumentTypes
        applicantId,
        // For simplicity, using base64 directly - in production use proper file upload
        Buffer.from(dto.documentFront, 'base64') as any,
      );

      kycCheck.onfidoDocumentId = document.data.id;

      // Create check
      const check = await this.onfido.createCheck({
        applicant_id: applicantId,
        report_names: ['document'],
      });

      kycCheck.onfidoCheckId = check.data.id;
      kycCheck.status = KycCheckStatus.IN_PROGRESS;

      await this.saveKycCheck(kycCheck);

      return {
        checkId: kycCheck.id,
        status: 'processing',
      };
    } catch (error: any) {
      this.logger.error('Failed to upload document:', error);
      
      if (error.response?.data?.error) {
        throw new BadRequestException(`Document verification failed: ${error.response.data.error.message}`);
      }
      
      throw new InternalServerErrorException('Failed to process document');
    }
  }

  /**
   * Upload selfie for face verification
   */
  async uploadSelfie(
    userId: string,
    dto: UploadSelfieDto,
  ): Promise<{ checkId: string; status: string }> {
    const profile = await this.getContractorProfile(userId);

    if (profile.kycSelfieVerified) {
      throw new BadRequestException('Selfie already verified');
    }

    // Check that document was verified first
    if (!profile.kycIdVerified) {
      throw new BadRequestException('ID verification must be completed first');
    }

    const applicantId = await this.getOrCreateApplicant(userId);

    // Create KYC check record
    const kycCheck = new KycCheck();
    kycCheck.userId = userId;
    kycCheck.type = KycCheckType.FACIAL_SIMILARITY;
    kycCheck.onfidoApplicantId = applicantId;
    kycCheck.status = KycCheckStatus.PENDING;

    // Mock mode
    if (!this.onfido) {
      kycCheck.onfidoCheckId = `mock_check_selfie_${Date.now()}`;
      kycCheck.status = KycCheckStatus.IN_PROGRESS;
      
      // Simulate async verification
      setTimeout(() => this.mockVerificationComplete(kycCheck.id, 'selfie'), 5000);

      await this.saveKycCheck(kycCheck);

      return {
        checkId: kycCheck.id,
        status: 'processing',
      };
    }

    try {
      // Upload live photo to Onfido
      await this.onfido.uploadLivePhoto(
        applicantId,
        Buffer.from(dto.selfieImage, 'base64') as any,
      );

      // Create facial similarity check
      const check = await this.onfido.createCheck({
        applicant_id: applicantId,
        report_names: ['facial_similarity_photo'],
      });

      kycCheck.onfidoCheckId = check.data.id;
      kycCheck.status = KycCheckStatus.IN_PROGRESS;

      await this.saveKycCheck(kycCheck);

      return {
        checkId: kycCheck.id,
        status: 'processing',
      };
    } catch (error: any) {
      this.logger.error('Failed to upload selfie:', error);
      
      if (error.response?.data?.error) {
        throw new BadRequestException(`Selfie verification failed: ${error.response.data.error.message}`);
      }
      
      throw new InternalServerErrorException('Failed to process selfie');
    }
  }

  /**
   * Verify bank account (IBAN validation + store for payouts)
   */
  async verifyBankAccount(
    userId: string,
    dto: VerifyBankDto,
  ): Promise<{ verified: boolean; maskedIban: string }> {
    const profile = await this.getContractorProfile(userId);

    if (profile.kycBankVerified) {
      throw new BadRequestException('Bank account already verified');
    }

    // Validate IBAN format
    if (!IBAN.isValid(dto.iban)) {
      throw new BadRequestException('Invalid IBAN format');
    }

    // Extract bank info from IBAN
    const electronicIban = IBAN.electronicFormat(dto.iban);
    const countryCode = electronicIban.substring(0, 2);

    // For Poland, validate it starts with PL
    if (countryCode !== 'PL') {
      throw new BadRequestException('Only Polish bank accounts (IBAN starting with PL) are supported');
    }

    // Create KYC check record
    const kycCheck = new KycCheck();
    kycCheck.userId = userId;
    kycCheck.type = KycCheckType.BANK_ACCOUNT;
    kycCheck.status = KycCheckStatus.COMPLETE;
    kycCheck.result = KycCheckResult.CLEAR;
    kycCheck.completedAt = new Date();
    kycCheck.resultDetails = {
      iban: electronicIban,
      accountHolderName: dto.accountHolderName,
      bankName: dto.bankName,
      countryCode,
      maskedIban: this.maskIban(electronicIban),
    };

    await this.saveKycCheck(kycCheck);

    // Update contractor profile
    profile.kycBankVerified = true;
    await this.profileRepository.save(profile);

    // Update overall KYC status
    await this.updateOverallKycStatus(userId);

    return {
      verified: true,
      maskedIban: this.maskIban(electronicIban),
    };
  }

  /**
   * Get KYC status for a user
   */
  async getKycStatus(userId: string): Promise<KycStatusResponse> {
    const profile = await this.getContractorProfile(userId);
    const checks = await this.getKycChecksForUser(userId);

    return {
      userId,
      overallStatus: profile.kycStatus,
      idVerified: profile.kycIdVerified,
      selfieVerified: profile.kycSelfieVerified,
      bankVerified: profile.kycBankVerified,
      checks: checks.map(c => ({
        id: c.id,
        type: c.type,
        status: c.status,
        result: c.result,
        createdAt: c.createdAt,
      })),
      canAcceptTasks: profile.kycStatus === KycStatus.VERIFIED,
    };
  }

  /**
   * Handle Onfido webhook
   */
  async handleWebhook(payload: OnfidoWebhookPayload, signature: string): Promise<void> {
    // In production, verify webhook signature
    // const isValid = this.verifyWebhookSignature(payload, signature);
    // if (!isValid) throw new BadRequestException('Invalid webhook signature');

    this.logger.log(`Onfido webhook received: ${payload.payload.action}`);

    if (payload.payload.resource_type !== 'check') {
      this.logger.log(`Ignoring webhook for resource type: ${payload.payload.resource_type}`);
      return;
    }

    const checkId = payload.payload.object.id;
    const status = payload.payload.object.status;
    const result = payload.payload.object.result;

    // Find our KYC check record
    const kycCheck = await this.findKycCheckByOnfidoId(checkId);
    
    if (!kycCheck) {
      this.logger.warn(`KYC check not found for Onfido check ID: ${checkId}`);
      return;
    }

    // Update check status
    if (status === 'complete') {
      kycCheck.status = KycCheckStatus.COMPLETE;
      kycCheck.completedAt = new Date();

      if (result === 'clear') {
        kycCheck.result = KycCheckResult.CLEAR;
        await this.markVerificationComplete(kycCheck);
      } else if (result === 'consider') {
        kycCheck.result = KycCheckResult.CONSIDER;
        // May need manual review
      } else {
        kycCheck.result = KycCheckResult.UNIDENTIFIED;
      }
    }

    await this.saveKycCheck(kycCheck);
    await this.updateOverallKycStatus(kycCheck.userId);
  }

  /**
   * Get SDK token for mobile SDK (if using Onfido SDK in app)
   */
  async getSdkToken(userId: string): Promise<{ token: string }> {
    const applicantId = await this.getOrCreateApplicant(userId);

    // Mock mode
    if (!this.onfido) {
      return { token: `mock_sdk_token_${applicantId}` };
    }

    try {
      const sdkToken = await this.onfido.generateSdkToken({
        applicant_id: applicantId,
      });

      return { token: sdkToken.data.token };
    } catch (error) {
      this.logger.error('Failed to generate SDK token:', error);
      throw new InternalServerErrorException('Failed to generate verification token');
    }
  }

  // Helper methods

  private async getContractorProfile(userId: string): Promise<ContractorProfile> {
    const profile = await this.profileRepository.findOne({ where: { userId } });
    
    if (!profile) {
      throw new NotFoundException('Contractor profile not found. Please complete contractor registration first.');
    }

    return profile;
  }

  private async getKycChecksForUser(userId: string): Promise<KycCheck[]> {
    return this.kycCheckRepository.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  private async saveKycCheck(kycCheck: KycCheck): Promise<KycCheck> {
    const saved = await this.kycCheckRepository.save(kycCheck);
    this.logger.debug(`KYC check saved: ${saved.id}`);
    return saved;
  }

  private async findKycCheckByOnfidoId(onfidoCheckId: string): Promise<KycCheck | null> {
    return this.kycCheckRepository.findOne({
      where: { onfidoCheckId },
    });
  }

  private async markVerificationComplete(kycCheck: KycCheck): Promise<void> {
    const profile = await this.getContractorProfile(kycCheck.userId);

    if (kycCheck.type === KycCheckType.DOCUMENT) {
      profile.kycIdVerified = true;
    } else if (kycCheck.type === KycCheckType.FACIAL_SIMILARITY) {
      profile.kycSelfieVerified = true;
    }

    await this.profileRepository.save(profile);
    this.logger.log(`${kycCheck.type} verification complete for user ${kycCheck.userId}`);
  }

  private async updateOverallKycStatus(userId: string): Promise<void> {
    const profile = await this.getContractorProfile(userId);

    if (profile.kycIdVerified && profile.kycSelfieVerified && profile.kycBankVerified) {
      profile.kycStatus = KycStatus.VERIFIED;
      await this.profileRepository.save(profile);
      this.logger.log(`User ${userId} fully KYC verified`);
    }
  }

  private maskIban(iban: string): string {
    // Show first 4 and last 4 characters
    if (iban.length <= 8) return iban;
    return `${iban.substring(0, 4)}****${iban.substring(iban.length - 4)}`;
  }

  private async mockVerificationComplete(checkId: string, type: string): Promise<void> {
    // Simulate webhook callback for mock mode
    this.logger.log(`Mock ${type} verification complete for check ${checkId}`);
    // In real implementation, this would be triggered by Onfido webhook
  }
}
