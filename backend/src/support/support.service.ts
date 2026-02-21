import {
  BadRequestException,
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EmailService } from '../auth/email.service';
import type { AuthenticatedUser } from '../auth/types/auth-user.type';
import { ContactSupportDto } from './dto/contact-support.dto';

export interface ContactSupportResponse {
  success: boolean;
  message: string;
}

@Injectable()
export class SupportService {
  private readonly logger = new Logger(SupportService.name);
  private readonly recipient: string;

  constructor(
    private readonly emailService: EmailService,
    private readonly configService: ConfigService,
  ) {
    this.recipient = this.configService.get<string>(
      'SUPPORT_CONTACT_TO',
      'kontakt@szybkafucha.app',
    );
  }

  async sendContactMessage(
    user: AuthenticatedUser,
    dto: ContactSupportDto,
  ): Promise<ContactSupportResponse> {
    const reporterName = dto.name.trim();
    const message = dto.message.trim();

    if (!reporterName || !message) {
      throw new BadRequestException(
        'Imię i treść wiadomości są wymagane.',
      );
    }

    try {
      await this.emailService.sendSupportContactEmail({
        to: this.recipient,
        reporterId: user.id,
        reporterName,
        reporterEmail: user.email,
        reporterPhone: user.phone,
        reporterRoles: user.types ?? [],
        message,
      });

      return {
        success: true,
        message:
          'Wiadomość wysłana. Odezwiemy się do Ciebie w ciągu 48 godzin.',
      };
    } catch (error) {
      this.logger.error(
        `Contact form email delivery failed for user ${user.id}: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );

      throw new InternalServerErrorException(
        'Nie udało się wysłać wiadomości. Spróbuj ponownie za chwilę.',
      );
    }
  }
}
