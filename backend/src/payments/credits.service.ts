/**
 * Credits Service
 * Manages user credit balance: top-ups via Stripe, deductions, refunds
 */
import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  InternalServerErrorException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { ConfigService } from '@nestjs/config';
import Stripe from 'stripe';
import { User } from '../users/entities/user.entity';
import {
  CreditTransaction,
  CreditTransactionType,
} from './entities/credit-transaction.entity';

@Injectable()
export class CreditsService {
  private readonly logger = new Logger(CreditsService.name);
  private readonly stripe: Stripe | null;

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(CreditTransaction)
    private readonly creditTransactionRepository: Repository<CreditTransaction>,
    private readonly dataSource: DataSource,
    private readonly configService: ConfigService,
  ) {
    const stripeSecretKey = this.configService.get<string>('STRIPE_SECRET_KEY');

    if (!stripeSecretKey || stripeSecretKey === 'sk_test_placeholder') {
      this.logger.warn('Stripe not configured for credits. Using mock mode.');
      this.stripe = null;
    } else {
      this.stripe = new Stripe(stripeSecretKey);
    }
  }

  /**
   * Get user's current credit balance
   */
  async getBalance(userId: string): Promise<{ credits: number }> {
    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }
    return { credits: Number(user.credits) };
  }

  /**
   * Get credit transaction history (paginated)
   */
  async getTransactions(
    userId: string,
    page = 1,
    limit = 20,
  ): Promise<{
    transactions: CreditTransaction[];
    total: number;
    page: number;
    limit: number;
  }> {
    const [transactions, total] =
      await this.creditTransactionRepository.findAndCount({
        where: { userId },
        order: { createdAt: 'DESC' },
        skip: (page - 1) * limit,
        take: limit,
      });

    return { transactions, total, page, limit };
  }

  /**
   * Initiate credit top-up via Stripe PaymentIntent
   * Returns clientSecret for Stripe payment sheet
   */
  async initiateTopup(
    userId: string,
    amount: number,
  ): Promise<{ clientSecret: string; paymentIntentId: string }> {
    if (amount < 20) {
      throw new BadRequestException('Minimalna kwota doładowania to 20 zł');
    }

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) {
      throw new NotFoundException('User not found');
    }

    const amountInGrosz = Math.round(amount * 100);

    // Mock mode
    if (!this.stripe) {
      const mockPaymentIntentId = `pi_credits_mock_${Date.now()}`;

      // In mock mode, immediately add credits
      await this.addCredits(
        userId,
        amount,
        CreditTransactionType.TOPUP,
        `Doładowanie konta: ${amount} zł`,
        null,
        mockPaymentIntentId,
      );

      return {
        clientSecret: `mock_secret_credits_${mockPaymentIntentId}`,
        paymentIntentId: mockPaymentIntentId,
      };
    }

    try {
      const paymentIntent = await this.stripe.paymentIntents.create({
        amount: amountInGrosz,
        currency: 'pln',
        metadata: {
          purpose: 'credits_topup',
          userId,
          creditsAmount: amount.toString(),
        },
      });

      return {
        clientSecret: paymentIntent.client_secret!,
        paymentIntentId: paymentIntent.id,
      };
    } catch (error) {
      this.logger.error('Failed to create topup PaymentIntent:', error);
      throw new InternalServerErrorException('Failed to initiate top-up');
    }
  }

  /**
   * Confirm top-up after Stripe payment success
   */
  async confirmTopup(
    userId: string,
    paymentIntentId: string,
  ): Promise<{ credits: number }> {
    // Check if already processed (idempotency)
    const existing = await this.creditTransactionRepository.findOne({
      where: { stripePaymentIntentId: paymentIntentId, userId },
    });
    if (existing) {
      const user = await this.userRepository.findOne({
        where: { id: userId },
      });
      return { credits: Number(user!.credits) };
    }

    // Verify with Stripe
    if (this.stripe) {
      try {
        const paymentIntent =
          await this.stripe.paymentIntents.retrieve(paymentIntentId);

        if (paymentIntent.status !== 'succeeded') {
          throw new BadRequestException(
            `Płatność nie powiodła się. Status: ${paymentIntent.status}`,
          );
        }

        if (paymentIntent.metadata.purpose !== 'credits_topup') {
          throw new BadRequestException('Invalid payment intent');
        }

        if (paymentIntent.metadata.userId !== userId) {
          throw new BadRequestException('Payment intent does not belong to you');
        }

        const amount = Number(paymentIntent.metadata.creditsAmount);

        await this.addCredits(
          userId,
          amount,
          CreditTransactionType.TOPUP,
          `Doładowanie konta: ${amount} zł`,
          null,
          paymentIntentId,
        );
      } catch (error) {
        if (
          error instanceof BadRequestException ||
          error instanceof NotFoundException
        ) {
          throw error;
        }
        this.logger.error('Failed to confirm topup:', error);
        throw new InternalServerErrorException('Failed to confirm top-up');
      }
    }

    const user = await this.userRepository.findOne({ where: { id: userId } });
    return { credits: Number(user!.credits) };
  }

  /**
   * Handle Stripe webhook for credits top-up
   */
  async handleTopupWebhook(paymentIntent: Stripe.PaymentIntent): Promise<void> {
    if (paymentIntent.metadata.purpose !== 'credits_topup') {
      return;
    }

    const userId = paymentIntent.metadata.userId;
    const amount = Number(paymentIntent.metadata.creditsAmount);

    // Check if already processed (idempotency)
    const existing = await this.creditTransactionRepository.findOne({
      where: { stripePaymentIntentId: paymentIntent.id, userId },
    });
    if (existing) {
      this.logger.log(
        `Credits topup already processed for PI ${paymentIntent.id}`,
      );
      return;
    }

    await this.addCredits(
      userId,
      amount,
      CreditTransactionType.TOPUP,
      `Doładowanie konta: ${amount} zł`,
      null,
      paymentIntent.id,
    );

    this.logger.log(
      `Credits topup: ${amount} zł added to user ${userId} via webhook`,
    );
  }

  /**
   * Add credits to a user (used by top-up, refund, bonus)
   */
  async addCredits(
    userId: string,
    amount: number,
    type: CreditTransactionType,
    description: string,
    taskId: string | null = null,
    stripePaymentIntentId: string | null = null,
  ): Promise<void> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      await queryRunner.manager
        .createQueryBuilder()
        .update(User)
        .set({ credits: () => `credits + ${amount}` })
        .where('id = :userId', { userId })
        .execute();

      const transaction = queryRunner.manager.create(CreditTransaction, {
        userId,
        amount,
        type,
        taskId,
        stripePaymentIntentId,
        description,
      });
      await queryRunner.manager.save(transaction);

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      this.logger.error(`Failed to add credits for user ${userId}:`, error);
      throw new InternalServerErrorException('Failed to add credits');
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Deduct credits atomically from two users (client + contractor matching fee)
   * Returns true if successful, throws if insufficient balance
   */
  async deductMatchingFee(
    clientId: string,
    contractorId: string,
    taskId: string,
    feePerSide: number = 10,
  ): Promise<void> {
    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Lock both users for update (prevent race conditions)
      const client = await queryRunner.manager
        .createQueryBuilder(User, 'user')
        .setLock('pessimistic_write')
        .where('user.id = :id', { id: clientId })
        .getOne();

      const contractor = await queryRunner.manager
        .createQueryBuilder(User, 'user')
        .setLock('pessimistic_write')
        .where('user.id = :id', { id: contractorId })
        .getOne();

      if (!client || !contractor) {
        throw new NotFoundException('User not found');
      }

      if (Number(client.credits) < feePerSide) {
        throw new BadRequestException(
          `Niewystarczające środki klienta. Potrzebujesz ${feePerSide} zł, masz ${client.credits} zł`,
        );
      }

      if (Number(contractor.credits) < feePerSide) {
        throw new BadRequestException(
          `Wykonawca ma niewystarczające środki (${contractor.credits} zł). Wymagane: ${feePerSide} zł`,
        );
      }

      // Deduct from both
      await queryRunner.manager
        .createQueryBuilder()
        .update(User)
        .set({ credits: () => `credits - ${feePerSide}` })
        .where('id = :id', { id: clientId })
        .execute();

      await queryRunner.manager
        .createQueryBuilder()
        .update(User)
        .set({ credits: () => `credits - ${feePerSide}` })
        .where('id = :id', { id: contractorId })
        .execute();

      // Log both transactions
      const clientTx = queryRunner.manager.create(CreditTransaction, {
        userId: clientId,
        amount: -feePerSide,
        type: CreditTransactionType.DEDUCTION,
        taskId,
        description: 'Opłata za dopasowanie (szef)',
      });

      const contractorTx = queryRunner.manager.create(CreditTransaction, {
        userId: contractorId,
        amount: -feePerSide,
        type: CreditTransactionType.DEDUCTION,
        taskId,
        description: 'Opłata za dopasowanie (pracownik)',
      });

      await queryRunner.manager.save([clientTx, contractorTx]);

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      if (
        error instanceof BadRequestException ||
        error instanceof NotFoundException
      ) {
        throw error;
      }
      this.logger.error('Failed to deduct matching fee:', error);
      throw new InternalServerErrorException(
        'Failed to process matching fee payment',
      );
    } finally {
      await queryRunner.release();
    }
  }

  /**
   * Refund credits on cancellation (20% to canceller, 140% to injured party)
   */
  async processCancellationRefund(
    cancellerId: string,
    injuredPartyId: string,
    taskId: string,
    matchingFee: number = 10,
  ): Promise<void> {
    const cancellerRefund = matchingFee * 0.2; // 2 zł
    const injuredRefund = matchingFee * 1.4; // 14 zł

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Refund canceller (20%)
      await queryRunner.manager
        .createQueryBuilder()
        .update(User)
        .set({ credits: () => `credits + ${cancellerRefund}` })
        .where('id = :id', { id: cancellerId })
        .execute();

      // Refund injured party (140%)
      await queryRunner.manager
        .createQueryBuilder()
        .update(User)
        .set({ credits: () => `credits + ${injuredRefund}` })
        .where('id = :id', { id: injuredPartyId })
        .execute();

      // Increment strikes for canceller
      await queryRunner.manager
        .createQueryBuilder()
        .update(User)
        .set({ strikes: () => 'strikes + 1' })
        .where('id = :id', { id: cancellerId })
        .execute();

      // Log transactions
      const cancellerTx = queryRunner.manager.create(CreditTransaction, {
        userId: cancellerId,
        amount: cancellerRefund,
        type: CreditTransactionType.REFUND,
        taskId,
        description: `Częściowy zwrot za anulowanie: ${cancellerRefund} zł (20%)`,
      });

      const injuredTx = queryRunner.manager.create(CreditTransaction, {
        userId: injuredPartyId,
        amount: injuredRefund,
        type: CreditTransactionType.REFUND,
        taskId,
        description: `Zwrot za anulowanie przez drugą stronę: ${injuredRefund} zł (140%)`,
      });

      await queryRunner.manager.save([cancellerTx, injuredTx]);

      // Check if canceller reached 3 strikes
      const canceller = await queryRunner.manager.findOne(User, {
        where: { id: cancellerId },
      });
      if (canceller && canceller.strikes >= 3) {
        await queryRunner.manager.update(User, cancellerId, {
          status: 'suspended' as any,
        });
        this.logger.warn(
          `User ${cancellerId} suspended after ${canceller.strikes} strikes`,
        );
      }

      await queryRunner.commitTransaction();
    } catch (error) {
      await queryRunner.rollbackTransaction();
      this.logger.error('Failed to process cancellation refund:', error);
      throw new InternalServerErrorException(
        'Failed to process cancellation refund',
      );
    } finally {
      await queryRunner.release();
    }
  }
}
