/**
 * Payments Controller
 * REST endpoints for payment operations
 */
import {
  Controller,
  Get,
  Post,
  Body,
  Param,
  UseGuards,
  Request,
  Headers,
  Req,
  ParseUUIDPipe,
} from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import { PaymentsService } from './payments.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@Controller('payments')
export class PaymentsController {
  constructor(private readonly paymentsService: PaymentsService) {}

  /**
   * POST /payments/connect/onboard
   * Create Stripe Connect account and get onboarding link
   * (Contractor only)
   */
  @UseGuards(JwtAuthGuard)
  @Post('connect/onboard')
  async createConnectAccount(@Request() req: any) {
    return this.paymentsService.createConnectAccount(
      req.user.id,
      req.user.email,
    );
  }

  /**
   * GET /payments/connect/status
   * Get Stripe Connect account status
   * (Contractor only)
   */
  @UseGuards(JwtAuthGuard)
  @Get('connect/status')
  async getConnectStatus(@Request() req: any) {
    return this.paymentsService.getAccountStatus(req.user.id);
  }

  /**
   * POST /payments/create-intent
   * Create PaymentIntent for task payment
   * (Client only)
   */
  @UseGuards(JwtAuthGuard)
  @Post('create-intent')
  async createPaymentIntent(
    @Request() req: any,
    @Body('taskId') taskId: string,
  ) {
    return this.paymentsService.createPaymentIntent(taskId, req.user.id);
  }

  /**
   * POST /payments/:id/confirm
   * Confirm payment hold after client completes payment
   */
  @UseGuards(JwtAuthGuard)
  @Post(':id/confirm')
  async confirmPayment(@Param('id', ParseUUIDPipe) id: string) {
    return this.paymentsService.confirmPaymentHold(id);
  }

  /**
   * POST /payments/:id/capture
   * Capture held payment (after task completion)
   */
  @UseGuards(JwtAuthGuard)
  @Post(':id/capture')
  async capturePayment(@Param('id', ParseUUIDPipe) id: string) {
    const payment = await this.paymentsService.findById(id);
    return this.paymentsService.capturePayment(payment.taskId);
  }

  /**
   * POST /payments/:id/refund
   * Refund payment (full or partial)
   */
  @UseGuards(JwtAuthGuard)
  @Post(':id/refund')
  async refundPayment(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('reason') reason: string,
    @Body('amount') amount?: number,
  ) {
    const payment = await this.paymentsService.findById(id);
    return this.paymentsService.refundPayment(payment.taskId, reason, amount);
  }

  /**
   * GET /payments/:id
   * Get payment details
   */
  @UseGuards(JwtAuthGuard)
  @Get(':id')
  async getPayment(@Param('id', ParseUUIDPipe) id: string) {
    return this.paymentsService.findById(id);
  }

  /**
   * GET /payments/task/:taskId
   * Get payments for a task
   */
  @UseGuards(JwtAuthGuard)
  @Get('task/:taskId')
  async getPaymentsByTask(@Param('taskId', ParseUUIDPipe) taskId: string) {
    return this.paymentsService.findByTaskId(taskId);
  }

  /**
   * GET /earnings
   * Get contractor earnings summary
   * (Contractor only)
   */
  @UseGuards(JwtAuthGuard)
  @Get('/earnings')
  async getEarnings(@Request() req: any) {
    return this.paymentsService.getContractorEarnings(req.user.id);
  }

  /**
   * POST /earnings/withdraw
   * Request payout to bank account
   * (Contractor only)
   */
  @UseGuards(JwtAuthGuard)
  @Post('/earnings/withdraw')
  async requestWithdrawal(
    @Request() req: any,
    @Body('amount') amount: number,
  ) {
    return this.paymentsService.requestPayout(req.user.id, amount);
  }

  /**
   * POST /payments/webhook
   * Handle Stripe webhook events
   * Note: This endpoint should NOT use JwtAuthGuard
   */
  @Post('webhook')
  async handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Headers('stripe-signature') signature: string,
  ) {
    const payload = req.rawBody;
    if (!payload) {
      throw new Error('Raw body is required for webhook');
    }
    await this.paymentsService.handleWebhook(payload, signature);
    return { received: true };
  }
}
