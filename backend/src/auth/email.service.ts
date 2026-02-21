import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

@Injectable()
export class EmailService {
  private readonly logger = new Logger(EmailService.name);
  private transporter: nodemailer.Transporter | null = null;
  private readonly isDev: boolean;
  private readonly fromAddress: string;

  constructor(private readonly configService: ConfigService) {
    this.isDev = this.configService.get<string>('NODE_ENV') !== 'production';
    this.fromAddress =
      this.configService.get<string>('SMTP_FROM') ||
      'Szybka Fucha <noreply@szybkafucha.app>';

    if (!this.isDev) {
      this.initializeTransporter();
    }
  }

  private initializeTransporter(): void {
    const host = this.configService.get<string>('SMTP_HOST');
    const portRaw = this.configService.get<string>('SMTP_PORT') || '587';
    const port = Number.parseInt(portRaw, 10);
    const user = this.configService.get<string>('SMTP_USER');
    const pass = this.configService.get<string>('SMTP_PASSWORD');
    const secureRaw = this.configService.get<string>('SMTP_SECURE');
    const secure =
      secureRaw != null
        ? ['1', 'true', 'yes', 'on'].includes(secureRaw.toLowerCase())
        : port === 465;

    if (!host || !user || !pass || Number.isNaN(port)) {
      this.logger.warn(
        `SMTP not configured - missing host/user/pass or invalid port (host=${
          host ? 'set' : 'missing'
        }, user=${user ? 'set' : 'missing'}, pass=${pass ? 'set' : 'missing'}, port=${portRaw})`,
      );
      return;
    }

    this.transporter = nodemailer.createTransport({
      host,
      port,
      secure,
      auth: { user, pass },
    });
    this.logger.log(
      `SMTP transporter initialized (host=${host}, port=${port}, secure=${secure})`,
    );
  }

  /**
   * Send email verification OTP
   */
  async sendVerificationOtp(email: string, code: string): Promise<void> {
    const subject = 'Szybka Fucha - Kod weryfikacyjny';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
        <h2 style="color: #1a1a2e; margin-bottom: 16px;">Weryfikacja adresu email</h2>
        <p style="color: #444; font-size: 16px;">Twój kod weryfikacyjny:</p>
        <div style="background: #f0f4ff; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a1a2e;">${code}</span>
        </div>
        <p style="color: #888; font-size: 14px;">Kod jest ważny przez 5 minut. Nie udostępniaj go nikomu.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #aaa; font-size: 12px;">Szybka Fucha - Twoje zlecenia, szybko i bezpiecznie.</p>
      </div>
    `;

    await this.sendEmail(email, subject, html, code);
  }

  /**
   * Send password reset OTP
   */
  async sendPasswordResetOtp(email: string, code: string): Promise<void> {
    const subject = 'Szybka Fucha - Reset hasła';
    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 480px; margin: 0 auto; padding: 32px;">
        <h2 style="color: #1a1a2e; margin-bottom: 16px;">Reset hasła</h2>
        <p style="color: #444; font-size: 16px;">Otrzymaliśmy prośbę o zmianę hasła. Twój kod:</p>
        <div style="background: #fff4f0; border-radius: 12px; padding: 24px; text-align: center; margin: 24px 0;">
          <span style="font-size: 32px; font-weight: bold; letter-spacing: 8px; color: #1a1a2e;">${code}</span>
        </div>
        <p style="color: #888; font-size: 14px;">Kod jest ważny przez 5 minut. Jeśli nie prosiłeś o zmianę hasła, zignoruj tę wiadomość.</p>
        <hr style="border: none; border-top: 1px solid #eee; margin: 24px 0;" />
        <p style="color: #aaa; font-size: 12px;">Szybka Fucha - Twoje zlecenia, szybko i bezpiecznie.</p>
      </div>
    `;

    await this.sendEmail(email, subject, html, code);
  }

  private async sendEmail(
    to: string,
    subject: string,
    html: string,
    otpCode: string,
  ): Promise<void> {
    if (this.isDev) {
      this.logger.log(`[DEV] Email OTP for ${to}: ${otpCode}`);
      return;
    }

    if (!this.transporter) {
      this.logger.warn(`SMTP not configured - Email OTP for ${to}: ${otpCode}`);
      return;
    }

    try {
      await this.transporter.sendMail({
        from: this.fromAddress,
        to,
        subject,
        html,
      });
      this.logger.log(`Email sent to ${to}: ${subject}`);
    } catch (error) {
      this.logger.error(
        `Failed to send email to ${to}: ${error instanceof Error ? error.message : String(error)}`,
      );
      // Don't throw - email delivery failure shouldn't block the auth flow
      // OTP code is still stored in Redis and logged in dev mode
    }
  }
}
