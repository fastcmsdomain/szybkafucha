/**
 * Newsletter Controller
 * REST endpoints for newsletter subscriptions
 */
import {
  Controller,
  Post,
  Get,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
  Query,
} from '@nestjs/common';
import { NewsletterService, type SubscribeResponse } from './newsletter.service';
import { SubscribeNewsletterDto } from './dto/subscribe-newsletter.dto';
import { UserType } from './entities/newsletter-subscriber.entity';
import { AdminGuard } from '../admin/guards/admin.guard';

@Controller('newsletter')
export class NewsletterController {
  constructor(private readonly newsletterService: NewsletterService) {}

  /**
   * POST /newsletter/subscribe
   * Subscribe to newsletter (public endpoint)
   */
  @Post('subscribe')
  @HttpCode(HttpStatus.OK)
  async subscribe(@Body() dto: SubscribeNewsletterDto): Promise<SubscribeResponse> {
    return this.newsletterService.subscribe(dto);
  }

  /**
   * GET /newsletter/subscribers
   * Get all subscribers (admin only)
   */
  @Get('subscribers')
  @UseGuards(AdminGuard)
  async getAllSubscribers() {
    return this.newsletterService.getAllSubscribers();
  }

  /**
   * GET /newsletter/stats
   * Get subscription statistics (admin only)
   */
  @Get('stats')
  @UseGuards(AdminGuard)
  async getStats() {
    return this.newsletterService.getStats();
  }

  /**
   * POST /newsletter/unsubscribe
   * Unsubscribe from newsletter (public endpoint)
   */
  @Post('unsubscribe')
  @HttpCode(HttpStatus.OK)
  async unsubscribe(@Query('email') email: string): Promise<SubscribeResponse> {
    return this.newsletterService.unsubscribe(email);
  }
}
