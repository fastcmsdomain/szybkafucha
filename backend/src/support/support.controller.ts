import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Post,
  Request,
  UseGuards,
} from '@nestjs/common';
import { Throttle } from '@nestjs/throttler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';
import { ContactSupportDto } from './dto/contact-support.dto';
import {
  ContactSupportResponse,
  SupportService,
} from './support.service';

@Controller('support')
export class SupportController {
  constructor(private readonly supportService: SupportService) {}

  /**
   * POST /support/contact
   * Sends contact message from Profile -> Pomoc form to support inbox.
   */
  @Post('contact')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard)
  @Throttle({ default: { limit: 3, ttl: 60000 } })
  async contact(
    @Request() req: AuthenticatedRequest,
    @Body() dto: ContactSupportDto,
  ): Promise<ContactSupportResponse> {
    return this.supportService.sendContactMessage(req.user, dto);
  }
}
