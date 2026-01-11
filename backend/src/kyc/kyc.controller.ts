/**
 * KYC Controller
 * REST endpoints for contractor identity verification
 */
import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  Request,
  Headers,
} from '@nestjs/common';
import { KycService } from './kyc.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import {
  UploadIdDocumentDto,
  UploadSelfieDto,
  VerifyBankDto,
  KycStatusResponse,
} from './dto/kyc.dto';
import type { OnfidoWebhookPayload } from './dto/kyc.dto';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';

@Controller('contractor/kyc')
@UseGuards(JwtAuthGuard)
export class KycController {
  constructor(private readonly kycService: KycService) {}

  /**
   * GET /contractor/kyc/status
   * Get current KYC verification status
   */
  @Get('status')
  async getStatus(
    @Request() req: AuthenticatedRequest,
  ): Promise<KycStatusResponse> {
    return this.kycService.getKycStatus(req.user.id);
  }

  /**
   * POST /contractor/kyc/id
   * Upload ID document for verification
   */
  @Post('id')
  async uploadIdDocument(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UploadIdDocumentDto,
  ): Promise<{ checkId: string; status: string }> {
    return this.kycService.uploadIdDocument(req.user.id, dto);
  }

  /**
   * POST /contractor/kyc/selfie
   * Upload selfie for facial verification
   */
  @Post('selfie')
  async uploadSelfie(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UploadSelfieDto,
  ): Promise<{ checkId: string; status: string }> {
    return this.kycService.uploadSelfie(req.user.id, dto);
  }

  /**
   * POST /contractor/kyc/bank
   * Verify bank account (IBAN)
   */
  @Post('bank')
  async verifyBankAccount(
    @Request() req: AuthenticatedRequest,
    @Body() dto: VerifyBankDto,
  ): Promise<{ verified: boolean; maskedIban: string }> {
    return this.kycService.verifyBankAccount(req.user.id, dto);
  }

  /**
   * GET /contractor/kyc/sdk-token
   * Get Onfido SDK token for mobile integration
   */
  @Get('sdk-token')
  async getSdkToken(
    @Request() req: AuthenticatedRequest,
  ): Promise<{ token: string }> {
    return this.kycService.getSdkToken(req.user.id);
  }
}

/**
 * Webhook Controller (no auth - verified by signature)
 */
@Controller('webhooks')
export class KycWebhookController {
  constructor(private readonly kycService: KycService) {}

  /**
   * POST /webhooks/onfido
   * Handle Onfido verification webhooks
   */
  @Post('onfido')
  async handleOnfidoWebhook(
    @Body() payload: OnfidoWebhookPayload,
    @Headers('x-sha2-signature') signature: string,
  ): Promise<{ received: boolean }> {
    await this.kycService.handleWebhook(payload, signature);
    return { received: true };
  }
}
