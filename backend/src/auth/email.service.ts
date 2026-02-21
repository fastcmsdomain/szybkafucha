import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

interface SendSupportContactEmailInput {
  to: string;
  reporterId: string;
  reporterName: string;
  reporterEmail?: string | null;
  reporterPhone?: string | null;
  reporterRoles: string[];
  message: string;
}

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

  /**
   * Send contact form message to support inbox.
   * Throws on delivery errors because user explicitly expects support submission.
   */
  async sendSupportContactEmail(
    input: SendSupportContactEmailInput,
  ): Promise<void> {
    const transporter = this.getTransporter();

    if (!transporter) {
      throw new Error('SMTP transporter is not configured');
    }

    const reporterName = this.escapeHtml(input.reporterName);
    const reporterEmail = this.escapeHtml(input.reporterEmail ?? '-');
    const reporterPhone = this.escapeHtml(input.reporterPhone ?? '-');
    const reporterRoles = this.escapeHtml(
      input.reporterRoles.length > 0 ? input.reporterRoles.join(', ') : '-',
    );
    const messageHtml = this.escapeHtml(input.message).replace(/\n/g, '<br>');

    const subject = 'Szybka Fucha - Formularz kontaktowy';
    const text = [
      'Nowa wiadomość z formularza Pomoc (Profil):',
      '',
      `Użytkownik ID: ${input.reporterId}`,
      `Imię: ${input.reporterName}`,
      `Email: ${input.reporterEmail ?? '-'}`,
      `Telefon: ${input.reporterPhone ?? '-'}`,
      `Role: ${input.reporterRoles.join(', ') || '-'}`,
      '',
      'Treść wiadomości:',
      input.message,
    ].join('\n');

    const html = `
      <div style="font-family: Arial, sans-serif; max-width: 620px; margin: 0 auto; padding: 24px;">
        <h2 style="color: #1a1a2e; margin-bottom: 16px;">Nowa wiadomość z formularza kontaktowego</h2>
        <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
          <tr><td style="padding: 6px 0; color: #555; width: 150px;">Użytkownik ID:</td><td style="padding: 6px 0;">${this.escapeHtml(
            input.reporterId,
          )}</td></tr>
          <tr><td style="padding: 6px 0; color: #555;">Imię:</td><td style="padding: 6px 0;">${reporterName}</td></tr>
          <tr><td style="padding: 6px 0; color: #555;">Email:</td><td style="padding: 6px 0;">${reporterEmail}</td></tr>
          <tr><td style="padding: 6px 0; color: #555;">Telefon:</td><td style="padding: 6px 0;">${reporterPhone}</td></tr>
          <tr><td style="padding: 6px 0; color: #555;">Role:</td><td style="padding: 6px 0;">${reporterRoles}</td></tr>
        </table>
        <div style="background: #f9fafb; border-radius: 12px; padding: 16px; border: 1px solid #e5e7eb;">
          <p style="margin: 0 0 8px; color: #374151; font-weight: 600;">Treść wiadomości:</p>
          <p style="margin: 0; color: #111827; line-height: 1.5;">${messageHtml}</p>
        </div>
      </div>
    `;

    try {
      await transporter.sendMail({
        from: this.fromAddress,
        to: input.to,
        subject,
        html,
        text,
      });
      this.logger.log(`Support contact email sent to ${input.to}`);
    } catch (error) {
      this.logger.error(
        `Failed to send support contact email to ${input.to}: ${this.getErrorMessage(error)}`,
      );
      throw error instanceof Error
        ? error
        : new Error('Unknown SMTP delivery error');
    }
  }

  private getTransporter(): nodemailer.Transporter | null {
    if (!this.transporter) {
      this.initializeTransporter();
    }
    return this.transporter;
  }

  private escapeHtml(value: string): string {
    return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
  }

  private getErrorMessage(error: unknown): string {
    if (error instanceof Error) {
      return error.message;
    }
    if (typeof error === 'string') {
      return error;
    }
    return JSON.stringify(error);
  }

  private async sendEmail(
    to: string,
    subject: string,
    html: string,
    otpCode: string,
  ): Promise<void> {
    const transporter = this.getTransporter();

    if (this.isDev && !transporter) {
      this.logger.log(`[DEV] Email OTP for ${to}: ${otpCode}`);
      return;
    }

    if (!transporter) {
      this.logger.warn(`SMTP not configured - Email OTP for ${to}: ${otpCode}`);
      return;
    }

    try {
      await transporter.sendMail({
        from: this.fromAddress,
        to,
        subject,
        html,
      });
      this.logger.log(`Email sent to ${to}: ${subject}`);
    } catch (error) {
      this.logger.error(
        `Failed to send email to ${to}: ${this.getErrorMessage(error)}`,
      );
      // Don't throw - email delivery failure shouldn't block the auth flow
      // OTP code is still stored in Redis and logged in dev mode
    }
  }
}
