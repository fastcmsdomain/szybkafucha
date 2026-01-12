/**
 * Newsletter Service
 * Handles newsletter subscription logic
 */
import { Injectable, Logger, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import {
  NewsletterSubscriber,
  UserType,
} from './entities/newsletter-subscriber.entity';
import { SubscribeNewsletterDto } from './dto/subscribe-newsletter.dto';

// Response interface for subscribe method
export interface SubscribeResponse {
  success: boolean;
  message: string;
}

@Injectable()
export class NewsletterService {
  private readonly logger = new Logger(NewsletterService.name);

  constructor(
    @InjectRepository(NewsletterSubscriber)
    private newsletterRepository: Repository<NewsletterSubscriber>,
  ) {}

  /**
   * Subscribe to newsletter
   * Handles new subscriptions and reactivations
   */
  async subscribe(dto: SubscribeNewsletterDto): Promise<SubscribeResponse> {
    // Check if email already exists
    const existing = await this.newsletterRepository.findOne({
      where: { email: dto.email.toLowerCase() },
    });

    if (existing) {
      // If already subscribed and active, return success (idempotent)
      if (existing.isActive) {
        this.logger.log(`Email ${dto.email} already subscribed`);
        return {
          success: true,
          message: 'Już jesteś zapisany do newslettera!',
        };
      }

      // If unsubscribed, reactivate
      existing.isActive = true;
      existing.name = dto.name;
      existing.city = dto.city || null;
      existing.userType = dto.userType as UserType;
      existing.consent = dto.consent;
      existing.services = dto.services ? JSON.stringify(dto.services) : null;
      existing.comments = dto.comments || null;
      existing.source = dto.source || null;
      existing.subscribedAt = new Date();
      existing.unsubscribedAt = null;

      await this.newsletterRepository.save(existing);
      this.logger.log(`Reactivated subscription for ${dto.email}`);

      return {
        success: true,
        message: 'Dziękujemy za ponowne zapisanie się!',
      };
    }

    // Create new subscription
    const subscriber = this.newsletterRepository.create({
      name: dto.name,
      email: dto.email.toLowerCase(),
      city: dto.city || null,
      userType: dto.userType as UserType,
      consent: dto.consent,
      services: dto.services ? JSON.stringify(dto.services) : null,
      comments: dto.comments || null,
      source: dto.source || 'landing_page',
      isActive: true,
      subscribedAt: new Date(),
    });

    await this.newsletterRepository.save(subscriber);
    this.logger.log(`New subscription: ${dto.email} (${dto.userType})`);

    return {
      success: true,
      message: 'Dziękujemy za zapisanie się do newslettera!',
    };
  }

  /**
   * Get all subscribers (for admin)
   */
  async getAllSubscribers(): Promise<NewsletterSubscriber[]> {
    return this.newsletterRepository.find({
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get active subscribers count
   */
  async getActiveCount(): Promise<number> {
    return this.newsletterRepository.count({
      where: { isActive: true },
    });
  }

  /**
   * Get subscribers by user type
   */
  async getByUserType(userType: UserType): Promise<NewsletterSubscriber[]> {
    return this.newsletterRepository.find({
      where: { userType, isActive: true },
      order: { createdAt: 'DESC' },
    });
  }

  /**
   * Get subscription statistics
   */
  async getStats(): Promise<{
    total: number;
    clients: number;
    contractors: number;
  }> {
    const total = await this.getActiveCount();
    const clients = await this.newsletterRepository.count({
      where: { userType: UserType.CLIENT, isActive: true },
    });
    const contractors = await this.newsletterRepository.count({
      where: { userType: UserType.CONTRACTOR, isActive: true },
    });

    return { total, clients, contractors };
  }

  /**
   * Unsubscribe (soft delete)
   */
  async unsubscribe(email: string): Promise<SubscribeResponse> {
    const subscriber = await this.newsletterRepository.findOne({
      where: { email: email.toLowerCase() },
    });

    if (!subscriber) {
      throw new BadRequestException('Email nie został znaleziony w bazie.');
    }

    subscriber.isActive = false;
    subscriber.unsubscribedAt = new Date();
    await this.newsletterRepository.save(subscriber);

    this.logger.log(`Unsubscribed: ${email}`);

    return {
      success: true,
      message: 'Wypisano z newslettera.',
    };
  }
}
