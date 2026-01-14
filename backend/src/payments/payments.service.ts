/**
 * Payments Service
 * Handles Stripe Connect integration for payments and payouts
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
import Stripe from 'stripe';
import { Payment, PaymentStatus } from './entities/payment.entity';
import { Task, TaskStatus } from '../tasks/entities/task.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { User } from '../users/entities/user.entity';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType } from '../notifications/constants/notification-templates';

@Injectable()
export class PaymentsService {
  private readonly logger = new Logger(PaymentsService.name);
  private readonly stripe: Stripe | null;
  private readonly platformFeePercent: number;

  constructor(
    @InjectRepository(Payment)
    private readonly paymentRepository: Repository<Payment>,
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly configService: ConfigService,
    private readonly notificationsService: NotificationsService,
  ) {
    const stripeSecretKey = this.configService.get<string>('STRIPE_SECRET_KEY');

    if (!stripeSecretKey || stripeSecretKey === 'sk_test_placeholder') {
      this.logger.warn('⚠️ Stripe not configured. Using mock mode.');
      this.stripe = null;
    } else {
      this.stripe = new Stripe(stripeSecretKey);
    }

    this.platformFeePercent = this.configService.get<number>(
      'STRIPE_PLATFORM_FEE_PERCENT',
      17,
    );
  }

  /**
   * Create Stripe Connect Express account for contractor onboarding
   */
  async createConnectAccount(
    userId: string,
    email: string,
  ): Promise<{ accountId: string; onboardingUrl: string }> {
    const profile = await this.contractorProfileRepository.findOne({
      where: { userId },
    });

    if (!profile) {
      throw new NotFoundException('Contractor profile not found');
    }

    if (profile.stripeAccountId) {
      // Already has account, generate new onboarding link
      return this.generateOnboardingLink(profile.stripeAccountId);
    }

    // Mock mode for development
    if (!this.stripe) {
      const mockAccountId = `acct_mock_${userId.slice(0, 8)}`;
      await this.contractorProfileRepository.update(userId, {
        stripeAccountId: mockAccountId,
      });

      return {
        accountId: mockAccountId,
        onboardingUrl: `http://localhost:3002/mock-stripe-onboarding?account=${mockAccountId}`,
      };
    }

    try {
      // Create Stripe Connect Express account
      const account = await this.stripe.accounts.create({
        type: 'express',
        country: 'PL',
        email,
        capabilities: {
          card_payments: { requested: true },
          transfers: { requested: true },
        },
        business_type: 'individual',
        metadata: {
          userId,
        },
      });

      // Save account ID to contractor profile
      await this.contractorProfileRepository.update(userId, {
        stripeAccountId: account.id,
      });

      // Generate onboarding link
      return this.generateOnboardingLink(account.id);
    } catch (error) {
      this.logger.error('Failed to create Stripe Connect account:', error);
      throw new InternalServerErrorException(
        'Failed to create payment account',
      );
    }
  }

  /**
   * Generate Stripe Connect onboarding link
   */
  private async generateOnboardingLink(
    accountId: string,
  ): Promise<{ accountId: string; onboardingUrl: string }> {
    if (!this.stripe) {
      return {
        accountId,
        onboardingUrl: `http://localhost:3002/mock-stripe-onboarding?account=${accountId}`,
      };
    }

    try {
      const accountLink = await this.stripe.accountLinks.create({
        account: accountId,
        refresh_url: `${this.configService.get('FRONTEND_URL')}/contractor/stripe-refresh`,
        return_url: `${this.configService.get('FRONTEND_URL')}/contractor/stripe-complete`,
        type: 'account_onboarding',
      });

      return {
        accountId,
        onboardingUrl: accountLink.url,
      };
    } catch (error) {
      this.logger.error('Failed to generate onboarding link:', error);
      throw new InternalServerErrorException(
        'Failed to generate onboarding link',
      );
    }
  }

  /**
   * Check contractor's Stripe account status
   */
  async getAccountStatus(userId: string): Promise<{
    hasAccount: boolean;
    accountId: string | null;
    payoutsEnabled: boolean;
    chargesEnabled: boolean;
    detailsSubmitted: boolean;
  }> {
    const profile = await this.contractorProfileRepository.findOne({
      where: { userId },
    });

    if (!profile?.stripeAccountId) {
      return {
        hasAccount: false,
        accountId: null,
        payoutsEnabled: false,
        chargesEnabled: false,
        detailsSubmitted: false,
      };
    }

    // Mock mode
    if (!this.stripe) {
      return {
        hasAccount: true,
        accountId: profile.stripeAccountId,
        payoutsEnabled: true,
        chargesEnabled: true,
        detailsSubmitted: true,
      };
    }

    try {
      const account = await this.stripe.accounts.retrieve(
        profile.stripeAccountId,
      );

      return {
        hasAccount: true,
        accountId: profile.stripeAccountId,
        payoutsEnabled: account.payouts_enabled || false,
        chargesEnabled: account.charges_enabled || false,
        detailsSubmitted: account.details_submitted || false,
      };
    } catch (error) {
      this.logger.error('Failed to retrieve Stripe account:', error);
      throw new InternalServerErrorException(
        'Failed to check payment account status',
      );
    }
  }

  /**
   * Create PaymentIntent for task payment (hold/authorize)
   */
  async createPaymentIntent(
    taskId: string,
    clientId: string,
  ): Promise<{ clientSecret: string; paymentId: string }> {
    const task = await this.taskRepository.findOne({ where: { id: taskId } });

    if (!task) {
      throw new NotFoundException('Task not found');
    }

    if (task.clientId !== clientId) {
      throw new BadRequestException('You can only pay for your own tasks');
    }

    if (task.status !== TaskStatus.ACCEPTED) {
      throw new BadRequestException('Task must be accepted before payment');
    }

    // Check for existing pending payment
    const existingPayment = await this.paymentRepository.findOne({
      where: { taskId, status: PaymentStatus.PENDING },
    });

    if (existingPayment) {
      throw new BadRequestException('Payment already initiated for this task');
    }

    // Calculate amounts (in grosz - Polish cents)
    const amountInGrosz = Math.round(task.budgetAmount * 100);
    const commissionInGrosz = Math.round(
      amountInGrosz * (this.platformFeePercent / 100),
    );
    const contractorAmountInGrosz = amountInGrosz - commissionInGrosz;

    // Create payment record
    const payment = this.paymentRepository.create({
      taskId,
      amount: task.budgetAmount,
      commissionAmount: commissionInGrosz / 100,
      contractorAmount: contractorAmountInGrosz / 100,
      status: PaymentStatus.PENDING,
    });

    // Mock mode
    if (!this.stripe) {
      payment.stripePaymentIntentId = `pi_mock_${Date.now()}`;
      await this.paymentRepository.save(payment);

      return {
        clientSecret: `mock_secret_${payment.id}`,
        paymentId: payment.id,
      };
    }

    try {
      // Get contractor's Stripe account for transfer
      const contractorProfile = await this.contractorProfileRepository.findOne({
        where: { userId: task.contractorId! },
      });

      // Create PaymentIntent with manual capture (hold funds)
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: amountInGrosz,
        currency: 'pln',
        capture_method: 'manual', // Hold, don't capture immediately
        metadata: {
          taskId,
          clientId,
          contractorId: task.contractorId || '',
        },
        // If contractor has Stripe account, set up transfer
        ...(contractorProfile?.stripeAccountId && {
          transfer_data: {
            destination: contractorProfile.stripeAccountId,
            amount: contractorAmountInGrosz,
          },
        }),
      });

      payment.stripePaymentIntentId = paymentIntent.id;
      await this.paymentRepository.save(payment);

      return {
        clientSecret: paymentIntent.client_secret!,
        paymentId: payment.id,
      };
    } catch (error) {
      this.logger.error('Failed to create PaymentIntent:', error);
      throw new InternalServerErrorException('Failed to initiate payment');
    }
  }

  /**
   * Confirm payment hold (after client confirms payment in app)
   */
  async confirmPaymentHold(paymentId: string): Promise<Payment> {
    const payment = await this.paymentRepository.findOne({
      where: { id: paymentId },
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    if (payment.status !== PaymentStatus.PENDING) {
      throw new BadRequestException('Payment is not in pending status');
    }

    // Mock mode
    if (!this.stripe) {
      payment.status = PaymentStatus.HELD;
      return this.paymentRepository.save(payment);
    }

    try {
      // Verify PaymentIntent status
      const paymentIntent = await this.stripe.paymentIntents.retrieve(
        payment.stripePaymentIntentId!,
      );

      if (paymentIntent.status === 'requires_capture') {
        payment.status = PaymentStatus.HELD;
        return this.paymentRepository.save(payment);
      }

      throw new BadRequestException(`Payment status: ${paymentIntent.status}`);
    } catch (error) {
      if (error instanceof BadRequestException) throw error;
      this.logger.error('Failed to confirm payment hold:', error);
      throw new InternalServerErrorException('Failed to confirm payment');
    }
  }

  /**
   * Capture held payment (after task completion confirmed)
   */
  async capturePayment(taskId: string): Promise<Payment> {
    const payment = await this.paymentRepository.findOne({
      where: { taskId, status: PaymentStatus.HELD },
    });

    if (!payment) {
      throw new NotFoundException('No held payment found for this task');
    }

    // Mock mode
    if (!this.stripe) {
      payment.status = PaymentStatus.CAPTURED;
      payment.stripeTransferId = `tr_mock_${Date.now()}`;
      const savedPayment = await this.paymentRepository.save(payment);

      // Notify contractor about payment received
      const task = await this.taskRepository.findOne({ where: { id: taskId } });
      if (task?.contractorId) {
        this.notificationsService
          .sendToUser(task.contractorId, NotificationType.PAYMENT_RECEIVED, {
            amount: payment.contractorAmount || 0,
            taskTitle: task.title,
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send PAYMENT_RECEIVED notification: ${err}`,
            ),
          );
      }

      return savedPayment;
    }

    try {
      // Capture the PaymentIntent
      const paymentIntent = await this.stripe.paymentIntents.capture(
        payment.stripePaymentIntentId!,
      );

      payment.status = PaymentStatus.CAPTURED;

      // Transfer ID is created automatically if transfer_data was set
      if (paymentIntent.transfer_data?.destination) {
        payment.stripeTransferId = paymentIntent.latest_charge as string;
      }

      const savedPayment = await this.paymentRepository.save(payment);

      // Notify contractor about payment received
      const task = await this.taskRepository.findOne({ where: { id: taskId } });
      if (task?.contractorId) {
        this.notificationsService
          .sendToUser(task.contractorId, NotificationType.PAYMENT_RECEIVED, {
            amount: payment.contractorAmount || 0,
            taskTitle: task.title,
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send PAYMENT_RECEIVED notification: ${err}`,
            ),
          );
      }

      return savedPayment;
    } catch (error) {
      this.logger.error('Failed to capture payment:', error);
      throw new InternalServerErrorException('Failed to capture payment');
    }
  }

  /**
   * Refund payment (full or partial)
   */
  async refundPayment(
    taskId: string,
    reason: string,
    amount?: number,
  ): Promise<Payment> {
    const payment = await this.paymentRepository.findOne({
      where: { taskId },
      order: { createdAt: 'DESC' },
    });

    if (!payment) {
      throw new NotFoundException('No payment found for this task');
    }

    if (payment.status === PaymentStatus.REFUNDED) {
      throw new BadRequestException('Payment already refunded');
    }

    if (
      payment.status !== PaymentStatus.HELD &&
      payment.status !== PaymentStatus.CAPTURED
    ) {
      throw new BadRequestException(
        'Payment cannot be refunded in current status',
      );
    }

    // Mock mode
    if (!this.stripe) {
      payment.status = PaymentStatus.REFUNDED;
      payment.refundReason = reason;
      const savedPayment = await this.paymentRepository.save(payment);

      // Notify client about refund
      const task = await this.taskRepository.findOne({ where: { id: taskId } });
      if (task) {
        this.notificationsService
          .sendToUser(task.clientId, NotificationType.PAYMENT_REFUNDED, {
            amount: payment.amount,
            taskTitle: task.title,
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send PAYMENT_REFUNDED notification: ${err}`,
            ),
          );
      }

      return savedPayment;
    }

    try {
      const refundAmount = amount ? Math.round(amount * 100) : undefined;

      if (payment.status === PaymentStatus.HELD) {
        // Cancel the PaymentIntent (release hold)
        await this.stripe.paymentIntents.cancel(payment.stripePaymentIntentId!);
      } else {
        // Create refund for captured payment
        await this.stripe.refunds.create({
          payment_intent: payment.stripePaymentIntentId!,
          amount: refundAmount,
          reason: 'requested_by_customer',
        });
      }

      payment.status = PaymentStatus.REFUNDED;
      payment.refundReason = reason;
      const savedPayment = await this.paymentRepository.save(payment);

      // Notify client about refund
      const task = await this.taskRepository.findOne({ where: { id: taskId } });
      if (task) {
        this.notificationsService
          .sendToUser(task.clientId, NotificationType.PAYMENT_REFUNDED, {
            amount: payment.amount,
            taskTitle: task.title,
          })
          .catch((err) =>
            this.logger.error(
              `Failed to send PAYMENT_REFUNDED notification: ${err}`,
            ),
          );
      }

      return savedPayment;
    } catch (error) {
      this.logger.error('Failed to refund payment:', error);
      throw new InternalServerErrorException('Failed to process refund');
    }
  }

  /**
   * Get contractor earnings summary
   */
  async getContractorEarnings(contractorId: string): Promise<{
    totalEarnings: number;
    pendingEarnings: number;
    availableBalance: number;
    completedTasks: number;
    recentPayments: Payment[];
  }> {
    // Get all captured payments for this contractor's tasks
    const payments = await this.paymentRepository
      .createQueryBuilder('payment')
      .innerJoin('payment.task', 'task')
      .where('task.contractorId = :contractorId', { contractorId })
      .andWhere('payment.status = :status', { status: PaymentStatus.CAPTURED })
      .orderBy('payment.createdAt', 'DESC')
      .getMany();

    const totalEarnings = payments.reduce(
      (sum, p) => sum + Number(p.contractorAmount || 0),
      0,
    );

    // Get pending (held) payments
    const pendingPayments = await this.paymentRepository
      .createQueryBuilder('payment')
      .innerJoin('payment.task', 'task')
      .where('task.contractorId = :contractorId', { contractorId })
      .andWhere('payment.status = :status', { status: PaymentStatus.HELD })
      .getMany();

    const pendingEarnings = pendingPayments.reduce(
      (sum, p) => sum + Number(p.contractorAmount || 0),
      0,
    );

    // Get available balance from Stripe (mock if not configured)
    let availableBalance = totalEarnings;

    if (this.stripe) {
      try {
        const profile = await this.contractorProfileRepository.findOne({
          where: { userId: contractorId },
        });

        if (profile?.stripeAccountId) {
          const balance = await this.stripe.balance.retrieve({
            stripeAccount: profile.stripeAccountId,
          });

          availableBalance = balance.available.reduce(
            (sum, b) => sum + (b.currency === 'pln' ? b.amount / 100 : 0),
            0,
          );
        }
      } catch (error) {
        this.logger.warn('Failed to fetch Stripe balance:', error);
      }
    }

    return {
      totalEarnings,
      pendingEarnings,
      availableBalance,
      completedTasks: payments.length,
      recentPayments: payments.slice(0, 10),
    };
  }

  /**
   * Request payout to contractor's bank account
   */
  async requestPayout(
    contractorId: string,
    amount: number,
  ): Promise<{ payoutId: string; status: string }> {
    const profile = await this.contractorProfileRepository.findOne({
      where: { userId: contractorId },
    });

    if (!profile?.stripeAccountId) {
      throw new BadRequestException('Stripe account not set up');
    }

    // Mock mode
    if (!this.stripe) {
      return {
        payoutId: `po_mock_${Date.now()}`,
        status: 'pending',
      };
    }

    try {
      const payout = await this.stripe.payouts.create(
        {
          amount: Math.round(amount * 100),
          currency: 'pln',
        },
        {
          stripeAccount: profile.stripeAccountId,
        },
      );

      return {
        payoutId: payout.id,
        status: payout.status,
      };
    } catch (error) {
      this.logger.error('Failed to create payout:', error);
      throw new InternalServerErrorException('Failed to process payout');
    }
  }

  /**
   * Handle Stripe webhook events
   */
  async handleWebhook(payload: Buffer, signature: string): Promise<void> {
    if (!this.stripe) {
      this.logger.warn('Stripe webhook received but Stripe not configured');
      return;
    }

    const webhookSecret = this.configService.get<string>(
      'STRIPE_WEBHOOK_SECRET',
    );

    if (!webhookSecret) {
      this.logger.warn('Stripe webhook secret not configured');
      return;
    }

    let event: Stripe.Event;

    try {
      event = this.stripe.webhooks.constructEvent(
        payload,
        signature,
        webhookSecret,
      );
    } catch (error) {
      this.logger.error('Webhook signature verification failed:', error);
      throw new BadRequestException('Webhook signature verification failed');
    }

    this.logger.log(`Received Stripe webhook: ${event.type}`);

    switch (event.type) {
      case 'payment_intent.succeeded':
        await this.handlePaymentSucceeded(event.data.object);
        break;
      case 'payment_intent.payment_failed':
        await this.handlePaymentFailed(event.data.object);
        break;
      case 'account.updated':
        await this.handleAccountUpdated(event.data.object);
        break;
      default:
        this.logger.log(`Unhandled webhook event: ${event.type}`);
    }
  }

  private async handlePaymentSucceeded(
    paymentIntent: Stripe.PaymentIntent,
  ): Promise<void> {
    const payment = await this.paymentRepository.findOne({
      where: { stripePaymentIntentId: paymentIntent.id },
    });

    if (payment && payment.status === PaymentStatus.PENDING) {
      payment.status = PaymentStatus.HELD;
      await this.paymentRepository.save(payment);
      this.logger.log(`Payment ${payment.id} marked as held`);
    }
  }

  private async handlePaymentFailed(
    paymentIntent: Stripe.PaymentIntent,
  ): Promise<void> {
    const payment = await this.paymentRepository.findOne({
      where: { stripePaymentIntentId: paymentIntent.id },
    });

    if (payment) {
      payment.status = PaymentStatus.FAILED;
      await this.paymentRepository.save(payment);
      this.logger.log(`Payment ${payment.id} marked as failed`);
    }
  }

  private async handleAccountUpdated(account: Stripe.Account): Promise<void> {
    const profile = await this.contractorProfileRepository.findOne({
      where: { stripeAccountId: account.id },
    });

    if (profile && account.details_submitted && account.payouts_enabled) {
      // Could update KYC status or send notification
      this.logger.log(
        `Contractor ${profile.userId} Stripe account is now fully set up`,
      );
    }
  }

  /**
   * Get payment by ID
   */
  async findById(paymentId: string): Promise<Payment> {
    const payment = await this.paymentRepository.findOne({
      where: { id: paymentId },
      relations: ['task'],
    });

    if (!payment) {
      throw new NotFoundException('Payment not found');
    }

    return payment;
  }

  /**
   * Get payments for a task
   */
  async findByTaskId(taskId: string): Promise<Payment[]> {
    return this.paymentRepository.find({
      where: { taskId },
      order: { createdAt: 'DESC' },
    });
  }
}
