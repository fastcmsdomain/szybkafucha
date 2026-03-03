/**
 * Credits Controller
 * REST endpoints for credit balance, top-up, and transaction history
 */
import {
  Controller,
  Get,
  Post,
  Body,
  Query,
  UseGuards,
  Request,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { CreditsService } from './credits.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TopupCreditsDto } from './dto/topup-credits.dto';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';

@Controller('payments/credits')
@UseGuards(JwtAuthGuard)
export class CreditsController {
  constructor(private readonly creditsService: CreditsService) {}

  /**
   * GET /payments/credits/balance
   * Get current credit balance
   */
  @Get('balance')
  async getBalance(@Request() req: AuthenticatedRequest) {
    return this.creditsService.getBalance(req.user.id);
  }

  /**
   * GET /payments/credits/transactions
   * Get credit transaction history (paginated)
   */
  @Get('transactions')
  async getTransactions(
    @Request() req: AuthenticatedRequest,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit: number,
  ) {
    return this.creditsService.getTransactions(req.user.id, page, limit);
  }

  /**
   * POST /payments/credits/topup
   * Initiate credit top-up via Stripe
   * Returns clientSecret for Stripe payment sheet
   */
  @Post('topup')
  async initiateTopup(
    @Request() req: AuthenticatedRequest,
    @Body() dto: TopupCreditsDto,
  ) {
    return this.creditsService.initiateTopup(req.user.id, dto.amount);
  }

  /**
   * POST /payments/credits/topup/confirm
   * Confirm top-up after Stripe payment success
   */
  @Post('topup/confirm')
  async confirmTopup(
    @Request() req: AuthenticatedRequest,
    @Body('paymentIntentId') paymentIntentId: string,
  ) {
    return this.creditsService.confirmTopup(req.user.id, paymentIntentId);
  }
}
