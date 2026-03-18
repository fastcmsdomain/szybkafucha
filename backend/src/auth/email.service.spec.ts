import { Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';
import { EmailService } from './email.service';

jest.mock('nodemailer', () => ({
  createTransport: jest.fn(),
}));

describe('EmailService', () => {
  const sendMail = jest.fn();
  const createTransport = nodemailer.createTransport as jest.Mock;

  beforeEach(() => {
    jest.clearAllMocks();
    sendMail.mockResolvedValue(undefined);
    createTransport.mockReturnValue({ sendMail });
  });

  it('renders branded verification email content and sends it when SMTP is configured', async () => {
    const configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          NODE_ENV: 'production',
          SMTP_HOST: 'smtp.example.com',
          SMTP_PORT: '587',
          SMTP_USER: 'mailer',
          SMTP_PASSWORD: 'secret',
          SMTP_FROM: 'Szybka Fucha <noreply@example.com>',
        };
        return values[key];
      }),
    } as unknown as ConfigService;

    const service = new EmailService(configService);

    await service.sendVerificationOtp('jan@example.com', '654321');

    expect(createTransport).toHaveBeenCalledWith(
      expect.objectContaining({
        host: 'smtp.example.com',
        port: 587,
        secure: false,
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'jan@example.com',
        subject: 'Szybka Fucha - Zweryfikuj swoj adres email',
        html: expect.stringContaining('Potwierdz swoj adres email'),
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        html: expect.stringContaining('654321'),
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        html: expect.stringContaining('Kod jest wazny przez 5 minut.'),
      }),
    );
  });

  it('logs OTP in development when SMTP is not configured', async () => {
    const configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          NODE_ENV: 'development',
        };
        return values[key];
      }),
    } as unknown as ConfigService;

    const logSpy = jest
      .spyOn(Logger.prototype, 'log')
      .mockImplementation(() => undefined);

    const service = new EmailService(configService);
    await service.sendVerificationOtp('dev@example.com', '123456');

    expect(createTransport).not.toHaveBeenCalled();
    expect(sendMail).not.toHaveBeenCalled();
    expect(logSpy).toHaveBeenCalledWith(
      '[DEV] Email OTP for dev@example.com: 123456',
    );

    logSpy.mockRestore();
  });

  it('sends verification email in development when SMTP is configured', async () => {
    const configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          NODE_ENV: 'development',
          SMTP_HOST: 'smtp.example.com',
          SMTP_PORT: '465',
          SMTP_SECURE: 'true',
          SMTP_USER: 'mailer',
          SMTP_PASSWORD: 'secret',
          SMTP_FROM: 'Szybka Fucha <noreply@example.com>',
        };
        return values[key];
      }),
    } as unknown as ConfigService;

    const logSpy = jest
      .spyOn(Logger.prototype, 'log')
      .mockImplementation(() => undefined);

    const service = new EmailService(configService);
    await service.sendVerificationOtp('dev-mail@example.com', '123456');

    expect(createTransport).toHaveBeenCalledWith(
      expect.objectContaining({
        host: 'smtp.example.com',
        port: 465,
        secure: true,
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'dev-mail@example.com',
        subject: 'Szybka Fucha - Zweryfikuj swoj adres email',
      }),
    );
    expect(logSpy).not.toHaveBeenCalledWith(
      '[DEV] Email OTP for dev-mail@example.com: 123456',
    );

    logSpy.mockRestore();
  });

  it('renders and sends account deletion goodbye email', async () => {
    const configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          NODE_ENV: 'production',
          SMTP_HOST: 'smtp.example.com',
          SMTP_PORT: '587',
          SMTP_USER: 'mailer',
          SMTP_PASSWORD: 'secret',
          SMTP_FROM: 'Szybka Fucha <noreply@example.com>',
        };
        return values[key];
      }),
    } as unknown as ConfigService;

    const service = new EmailService(configService);
    await service.sendAccountDeletionGoodbye('jan@example.com', 'Jan');

    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'jan@example.com',
        subject: 'Szybka Fucha - Potwierdzenie usuniecia konta',
        html: expect.stringContaining('Twoje konto zostalo usuniete'),
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        html: expect.stringContaining('Dziekujemy Ci za czas spedzony z nami, Jan.'),
      }),
    );
  });

  it('renders and sends welcome email', async () => {
    const configService = {
      get: jest.fn((key: string) => {
        const values: Record<string, string> = {
          NODE_ENV: 'production',
          SMTP_HOST: 'smtp.example.com',
          SMTP_PORT: '587',
          SMTP_USER: 'mailer',
          SMTP_PASSWORD: 'secret',
          SMTP_FROM: 'Szybka Fucha <noreply@example.com>',
        };
        return values[key];
      }),
    } as unknown as ConfigService;

    const service = new EmailService(configService);
    await service.sendWelcomeEmail('jan@example.com', 'Jan');

    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        to: 'jan@example.com',
        subject: 'Szybka Fucha - Witamy na pokladzie',
        html: expect.stringContaining('Milo Cie widziec w SzybkaFucha'),
      }),
    );
    expect(sendMail).toHaveBeenCalledWith(
      expect.objectContaining({
        html: expect.stringContaining('Czesc Jan!'),
      }),
    );
  });
});
