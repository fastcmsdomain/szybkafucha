import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as nodemailer from 'nodemailer';

const OTP_EXPIRY_MINUTES = 5;
const BRAND_PRIMARY = '#E94560';
const BRAND_PRIMARY_DARK = '#D13A54';
const BRAND_SECONDARY = '#1A1A2E';
const FACEBOOK_URL = 'https://www.facebook.com/61585993722753';
const PRIVACY_URL = 'https://szybkafucha.app/privacy.html';
const TERMS_URL = 'https://szybkafucha.app/terms.html';
const COOKIES_URL = 'https://szybkafucha.app/cookies.html';

interface SendSupportContactEmailInput {
  to: string;
  reporterId: string;
  reporterName: string;
  reporterEmail?: string | null;
  reporterPhone?: string | null;
  reporterRoles: string[];
  message: string;
}

interface OtpEmailTemplateInput {
  eyebrow: string;
  title: string;
  intro: string;
  code: string;
  accentColor: string;
  panelBackground: string;
  note: string;
  footer: string;
}

interface BrandedEmailShellInput {
  preheader: string;
  eyebrow: string;
  title: string;
  intro: string;
  bodyHtml: string;
  footer: string;
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
    this.initializeTransporter();
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
    const subject = 'Szybka Fucha - Zweryfikuj swoj adres email';
    const html = this.buildOtpEmailTemplate({
      eyebrow: 'Weryfikacja konta',
      title: 'Potwierdz swoj adres email',
      intro:
        'Dziekujemy za rejestracje w Szybkiej Fusze. Wpisz ponizszy kod w aplikacji, aby dokonczyc weryfikacje adresu email.',
      code,
      accentColor: BRAND_PRIMARY,
      panelBackground: '#fff1f4',
      note: `Kod jest wazny przez ${OTP_EXPIRY_MINUTES} minut. Nie udostepniaj go nikomu.`,
      footer:
        'Jesli to nie Ty zakladales konto, mozesz bezpiecznie zignorowac te wiadomosc.',
    });

    await this.sendEmail(email, subject, html, code);
  }

  /**
   * Send password reset OTP
   */
  async sendPasswordResetOtp(email: string, code: string): Promise<void> {
    const subject = 'Szybka Fucha - Reset hasla';
    const html = this.buildOtpEmailTemplate({
      eyebrow: 'Bezpieczenstwo konta',
      title: 'Reset hasla',
      intro:
        'Otrzymalismy prosbe o zmiane hasla do Twojego konta. Wpisz ten kod w aplikacji, aby ustawic nowe haslo.',
      code,
      accentColor: '#c2410c',
      panelBackground: '#fff7ed',
      note: `Kod jest wazny przez ${OTP_EXPIRY_MINUTES} minut. Jesli nie prosiles o zmiane hasla, zignoruj te wiadomosc.`,
      footer:
        'Dla bezpieczenstwa nie przekazuj kodu innym osobom i nie wysylaj go poza aplikacje.',
    });

    await this.sendEmail(email, subject, html, code);
  }

  async sendWelcomeEmail(
    email: string,
    firstName?: string | null,
  ): Promise<void> {
    const safeName = this.escapeHtml(firstName?.trim() || 'Tam');
    const subject = 'Szybka Fucha - Witamy na pokladzie';
    const html = this.buildBrandedEmailShell({
      preheader:
        'Witamy w SzybkaFucha. Twoje konto jest gotowe do korzystania z aplikacji.',
      eyebrow: 'Witamy',
      title: 'Milo Cie widziec w SzybkaFucha',
      intro: `Czesc ${safeName}! Dziekujemy, ze dolaczyles do Szybka Fucha. Twoje konto jest gotowe i mozesz zaczac korzystac z aplikacji.`,
      bodyHtml: `
        <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:linear-gradient(180deg, #fff7f8 0%, #ffffff 100%); border:1px solid #f3d4db;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            W Szybka Fucha mozesz szybko zlecac codzienne zadania albo zarabiac pomagajac innym lokalnie. Wszystko w prosty i bezpieczny sposob.
          </p>
        </div>
        <div style="padding:18px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <p style="margin:0 0 10px; font-size:14px; line-height:1.7; color:${BRAND_SECONDARY}; font-weight:700;">
            Co dalej?
          </p>
          <p style="margin:0 0 10px; font-size:14px; line-height:1.7; color:#4b5563;">
            Uzupelnij profil, dodaj najwazniejsze informacje i zacznij korzystac z mozliwosci aplikacji.
          </p>
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            Jesli bedziesz potrzebowac pomocy, jestesmy blisko.
          </p>
        </div>
      `,
      footer:
        'Dziekujemy za zaufanie. Cieszymy sie, ze jestes z nami od poczatku.',
    });

    await this.sendEmail(email, subject, html);
  }

  async sendAccountDeletionGoodbye(
    email: string,
    firstName?: string | null,
  ): Promise<void> {
    const safeName = this.escapeHtml(firstName?.trim() || 'Tam');
    const subject = 'Szybka Fucha - Potwierdzenie usuniecia konta';
    const html = this.buildBrandedEmailShell({
      preheader:
        'Potwierdzenie usuniecia konta i krotkie pozegnanie od SzybkaFucha.',
      eyebrow: 'Pozegnanie',
      title: 'Twoje konto zostalo usuniete',
      intro: `Dziekujemy Ci za czas spedzony z nami, ${safeName}. Potwierdzamy, ze Twoje konto w Szybka Fucha zostalo usuniete zgodnie z prosba.`,
      bodyHtml: `
        <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:linear-gradient(180deg, #fff7f8 0%, #ffffff 100%); border:1px solid #f3d4db;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            Twoje dane w aktywnym koncie zostaly usuniete lub zanonimizowane zgodnie z naszym procesem bezpieczenstwa. Jesli kiedykolwiek zechcesz wrocic, bedzie nam bardzo milo powitac Cie ponownie.
          </p>
        </div>
        <div style="padding:18px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <p style="margin:0 0 10px; font-size:14px; line-height:1.7; color:${BRAND_SECONDARY}; font-weight:700;">
            Dziekujemy, ze byles z nami.
          </p>
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            Doceniamy kazde zaufanie okazane Szybka Fucha. Zyczymy Ci wszystkiego dobrego i mamy nadzieje, ze nasze drogi jeszcze sie przetna.
          </p>
        </div>
      `,
      footer:
        'Jesli usuniecie konta nie bylo wykonane przez Ciebie, skontaktuj sie z nami jak najszybciej przez formularz pomocy lub Facebook.',
    });

    await this.sendEmail(email, subject, html);
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

    const html = this.buildBrandedEmailShell({
      preheader: 'Nowa wiadomosc z formularza pomocy w aplikacji SzybkaFucha.',
      eyebrow: 'Pomoc',
      title: 'Nowa wiadomosc od uzytkownika',
      intro:
        'Do skrzynki pomocy trafila nowa wiadomosc z formularza Profil -> Pomoc.',
      bodyHtml: `
        <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="font-size:14px; line-height:1.7; color:#4b5563;">
            <tr><td style="padding:6px 0; width:140px; color:#6b7280;">Uzytkownik ID:</td><td style="padding:6px 0;">${this.escapeHtml(
              input.reporterId,
            )}</td></tr>
            <tr><td style="padding:6px 0; color:#6b7280;">Imie:</td><td style="padding:6px 0;">${reporterName}</td></tr>
            <tr><td style="padding:6px 0; color:#6b7280;">Email:</td><td style="padding:6px 0;">${reporterEmail}</td></tr>
            <tr><td style="padding:6px 0; color:#6b7280;">Telefon:</td><td style="padding:6px 0;">${reporterPhone}</td></tr>
            <tr><td style="padding:6px 0; color:#6b7280;">Role:</td><td style="padding:6px 0;">${reporterRoles}</td></tr>
          </table>
        </div>
        <div style="padding:18px; border-radius:20px; background:#f9fafb; border:1px solid #eceff3;">
          <p style="margin:0 0 8px; color:#374151; font-weight:700; font-size:14px;">Tresc wiadomosci</p>
          <p style="margin:0; color:#111827; line-height:1.7; font-size:14px;">${messageHtml}</p>
        </div>
      `,
      footer: 'Ta wiadomosc zostala wyslana z formularza pomocy w aplikacji.',
    });

    try {
      await transporter.sendMail({
        from: this.fromAddress,
        to: input.to,
        subject,
        html,
        text,
        replyTo: input.reporterEmail ?? undefined,
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

  async sendSupportContactConfirmation(
    email: string,
    firstName?: string | null,
    referenceId?: string,
  ): Promise<void> {
    const safeName = this.escapeHtml(firstName?.trim() || 'Tam');
    const reference = referenceId ? this.escapeHtml(referenceId) : null;
    const subject = 'Szybka Fucha - Potwierdzenie otrzymania wiadomosci';
    const html = this.buildBrandedEmailShell({
      preheader:
        'Potwierdzamy otrzymanie Twojej wiadomosci do zespolu pomocy SzybkaFucha.',
      eyebrow: 'Pomoc',
      title: 'Otrzymalismy Twoja wiadomosc',
      intro: `Dziekujemy ${safeName}. Twoja wiadomosc trafiła do naszego zespolu i wrocimy z odpowiedzia tak szybko, jak to mozliwe.`,
      bodyHtml: `
        <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:linear-gradient(180deg, #fff7f8 0%, #ffffff 100%); border:1px solid #f3d4db;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            Standardowo odpowiadamy w ciagu 48 godzin. Jesli sprawa jest pilna, prosimy o doprecyzowanie szczegolow przy kolejnej wiadomosci.
          </p>
        </div>
        ${
          reference
            ? `<div style="padding:16px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
                <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
                  Numer referencyjny: <strong style="color:${BRAND_SECONDARY};">${reference}</strong>
                </p>
              </div>`
            : ''
        }
      `,
      footer: 'Dziekujemy za kontakt. Jestesmy do dyspozycji.',
    });

    await this.sendEmail(email, subject, html);
  }

  async sendSecurityPasswordChangedEmail(
    email: string,
    firstName?: string | null,
  ): Promise<void> {
    const safeName = this.escapeHtml(firstName?.trim() || 'Tam');
    const subject = 'Szybka Fucha - Haslo zostalo zmienione';
    const html = this.buildBrandedEmailShell({
      preheader:
        'Potwierdzenie zmiany hasla w koncie SzybkaFucha.',
      eyebrow: 'Bezpieczenstwo',
      title: 'Twoje haslo zostalo zmienione',
      intro: `Czesc ${safeName}. Potwierdzamy, ze haslo do Twojego konta w Szybka Fucha zostalo wlasnie zmienione.`,
      bodyHtml: `
        <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            Jesli to byla Twoja zmiana, nie musisz robic nic wiecej.
          </p>
        </div>
      `,
      footer:
        'Jesli to nie Ty zmieniles haslo, natychmiast zresetuj dostep do konta i skontaktuj sie z pomoca.',
    });

    await this.sendEmail(email, subject, html);
  }

  async sendSecurityPhoneChangedEmail(
    email: string,
    newPhone: string,
    firstName?: string | null,
  ): Promise<void> {
    const safeName = this.escapeHtml(firstName?.trim() || 'Tam');
    const subject = 'Szybka Fucha - Numer telefonu zostal zmieniony';
    const html = this.buildBrandedEmailShell({
      preheader:
        'Potwierdzenie zmiany numeru telefonu w koncie SzybkaFucha.',
      eyebrow: 'Bezpieczenstwo',
      title: 'Numer telefonu zostal zaktualizowany',
      intro: `Czesc ${safeName}. Potwierdzamy zmiane numeru telefonu przypisanego do Twojego konta.`,
      bodyHtml: `
        <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            Nowy numer: <strong style="color:${BRAND_SECONDARY};">${this.escapeHtml(newPhone)}</strong>
          </p>
        </div>
      `,
      footer:
        'Jesli to nie Ty zmieniles numer telefonu, skontaktuj sie z pomoca tak szybko, jak to mozliwe.',
    });

    await this.sendEmail(email, subject, html);
  }

  async sendKycUpdateEmail(
    email: string,
    kind:
      | 'document_verified'
      | 'selfie_verified'
      | 'kyc_complete'
      | 'kyc_failed',
    firstName?: string | null,
  ): Promise<void> {
    const safeName = this.escapeHtml(firstName?.trim() || 'Tam');
    const config = {
      document_verified: {
        subject: 'Szybka Fucha - Dokument zweryfikowany',
        eyebrow: 'Weryfikacja',
        title: 'Dokument zostal zweryfikowany',
        intro: `Czesc ${safeName}. Twoj dokument tozsamosci zostal pozytywnie zweryfikowany.`,
        body: 'Kolejny krok to selfie, aby dokonczyc weryfikacje tozsamosci.',
        footer: 'Dziekujemy za cierpliwosc. Jestes juz bardzo blisko pelnej aktywacji.',
      },
      selfie_verified: {
        subject: 'Szybka Fucha - Selfie zweryfikowane',
        eyebrow: 'Weryfikacja',
        title: 'Selfie zostalo zweryfikowane',
        intro: `Czesc ${safeName}. Twoje selfie zostalo pozytywnie zweryfikowane.`,
        body: 'Jesli wszystkie wymagane etapy sa zakonczone, konto zostanie wkrotce w pelni aktywowane.',
        footer: 'Dziekujemy. Dbamy o bezpieczenstwo calej spolecznosci.',
      },
      kyc_complete: {
        subject: 'Szybka Fucha - Weryfikacja zakonczona',
        eyebrow: 'Weryfikacja',
        title: 'Mozesz przyjmowac zlecenia',
        intro: `Gratulacje ${safeName}! Twoja weryfikacja zostala zakonczona pomyslnie.`,
        body: 'Twoje konto jest gotowe do korzystania z funkcji wykonawcy i przyjmowania zlecen.',
        footer: 'Powodzenia i dziekujemy, ze tworzysz z nami SzybkaFucha.',
      },
      kyc_failed: {
        subject: 'Szybka Fucha - Weryfikacja wymaga uwagi',
        eyebrow: 'Weryfikacja',
        title: 'Nie udalo sie zakonczyc weryfikacji',
        intro: `Czesc ${safeName}. Twoja weryfikacja nie zostala zakonczona pomyslnie.`,
        body: 'Sprawdz dane i sprobuj ponownie. Jesli problem bedzie sie powtarzal, skontaktuj sie z pomoca.',
        footer: 'Jestesmy do dyspozycji, jesli bedziesz potrzebowac wsparcia.',
      },
    }[kind];

    const html = this.buildBrandedEmailShell({
      preheader: config.title,
      eyebrow: config.eyebrow,
      title: config.title,
      intro: config.intro,
      bodyHtml: `
        <div style="padding:18px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            ${this.escapeHtml(config.body)}
          </p>
        </div>
      `,
      footer: config.footer,
    });

    await this.sendEmail(email, config.subject, html);
  }

  async sendTaskLifecycleEmail(
    email: string,
    event:
      | 'application_received'
      | 'application_accepted'
      | 'task_started'
      | 'task_completion_confirmed'
      | 'task_completed'
      | 'task_cancelled',
    params: {
      firstName?: string | null;
      taskTitle: string;
      counterpartName?: string | null;
      reason?: string | null;
    },
  ): Promise<void> {
    const safeName = this.escapeHtml(params.firstName?.trim() || 'Tam');
    const safeTaskTitle = this.escapeHtml(params.taskTitle);
    const safeCounterpart = this.escapeHtml(params.counterpartName?.trim() || '');
    const safeReason = this.escapeHtml(params.reason?.trim() || '');

    const config = {
      application_received: {
        subject: 'Szybka Fucha - Nowe zgloszenie do zlecenia',
        title: 'Masz nowe zgloszenie',
        intro: `Czesc ${safeName}. Do Twojego zlecenia "${safeTaskTitle}" zglosil sie nowy wykonawca.`,
        body: safeCounterpart
          ? `Wykonawca: ${safeCounterpart}. Sprawdz szczegoly zgloszenia w aplikacji.`
          : 'Sprawdz szczegoly zgloszenia w aplikacji.',
      },
      application_accepted: {
        subject: 'Szybka Fucha - Twoje zgloszenie zostalo zaakceptowane',
        title: 'Twoje zgloszenie zostalo zaakceptowane',
        intro: `Czesc ${safeName}. Twoje zgloszenie do "${safeTaskTitle}" zostalo zaakceptowane.`,
        body: 'Wejdz do aplikacji, aby sprawdzic szczegoly i przygotowac sie do realizacji.',
      },
      task_started: {
        subject: 'Szybka Fucha - Zlecenie zostalo rozpoczęte',
        title: 'Zlecenie zostalo rozpoczęte',
        intro: `Czesc ${safeName}. Prace nad "${safeTaskTitle}" wlasnie sie rozpoczęly.`,
        body: safeCounterpart
          ? `${safeCounterpart} rozpoczal realizacje zlecenia.`
          : 'Sprawdz postep w aplikacji.',
      },
      task_completion_confirmed: {
        subject: 'Szybka Fucha - Klient potwierdzil wykonanie',
        title: 'Klient potwierdzil wykonanie',
        intro: `Czesc ${safeName}. Klient potwierdzil wykonanie "${safeTaskTitle}".`,
        body: 'Mozesz teraz domknac proces i przejsc do ostatnich krokow w aplikacji.',
      },
      task_completed: {
        subject: 'Szybka Fucha - Zlecenie zostalo zakonczone',
        title: 'Zlecenie zostalo zakonczone',
        intro: `Czesc ${safeName}. Zlecenie "${safeTaskTitle}" zostalo zakonczone.`,
        body: 'Dziekujemy za skorzystanie z Szybka Fucha.',
      },
      task_cancelled: {
        subject: 'Szybka Fucha - Zlecenie zostalo anulowane',
        title: 'Zlecenie zostalo anulowane',
        intro: `Czesc ${safeName}. Zlecenie "${safeTaskTitle}" zostalo anulowane.`,
        body: safeReason ? `Powod: ${safeReason}` : 'Sprawdz szczegoly w aplikacji.',
      },
    }[event];

    const html = this.buildBrandedEmailShell({
      preheader: config.title,
      eyebrow: 'Zlecenie',
      title: config.title,
      intro: config.intro,
      bodyHtml: `
        <div style="padding:18px 18px; border-radius:20px; background:#ffffff; border:1px solid #eceff3;">
          <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
            ${config.body}
          </p>
        </div>
      `,
      footer: 'Najswiezsze szczegoly zawsze znajdziesz w aplikacji Szybka Fucha.',
    });

    await this.sendEmail(email, config.subject, html);
  }

  private getTransporter(): nodemailer.Transporter | null {
    if (!this.transporter) {
      this.initializeTransporter();
    }
    return this.transporter;
  }

  private buildOtpEmailTemplate(input: OtpEmailTemplateInput): string {
    return this.buildBrandedEmailShell({
      preheader:
        'SzybkaFucha - kod weryfikacyjny do bezpiecznego potwierdzenia adresu email.',
      eyebrow: input.eyebrow,
      title: input.title,
      intro: input.intro,
      bodyHtml: `
              <div style="margin-bottom:20px; padding:16px 18px; border-radius:20px; background:linear-gradient(180deg, #fff7f8 0%, #ffffff 100%); border:1px solid #f3d4db;">
                <p style="margin:0; font-size:14px; line-height:1.7; color:#4b5563;">
                  Zweryfikuj adres email, aby bezpiecznie korzystac z konta Szybka Fucha i potwierdzic, ze ten adres nalezy do Ciebie.
                </p>
              </div>

              <div style="border-radius:24px; background:${input.panelBackground}; border:1px solid #f5c6cf; padding:22px 12px; text-align:center;">
                <p style="margin:0 0 12px; font-size:13px; font-weight:700; letter-spacing:1px; text-transform:uppercase; color:#6b7280;">
                  Kod jednorazowy
                </p>
                <div style="display:inline-block; max-width:100%; margin:0 auto; padding:6px 4px; border-radius:0; background:transparent; border:none; font-size:26px; line-height:1.15; font-weight:800; letter-spacing:3px; color:${input.accentColor}; word-break:break-word;">
                  ${this.escapeHtml(input.code)}
                </div>
              </div>

              <p style="margin:22px 0 0; font-size:14px; line-height:1.7; color:#4b5563;">
                ${this.escapeHtml(input.note)}
              </p>
      `,
      footer: input.footer,
    });
  }

  private buildBrandedEmailShell(input: BrandedEmailShellInput): string {
    return `
      <div style="margin:0; padding:24px 12px; background:#f9fafb; font-family:'Plus Jakarta Sans', Arial, sans-serif; color:#1f2937;">
        <div style="display:none; max-height:0; overflow:hidden; opacity:0; mso-hide:all;">
          ${this.escapeHtml(input.preheader)}
        </div>
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0" border="0" style="max-width:600px; margin:0 auto; background:#ffffff; border:1px solid #e5e7eb; border-radius:28px; overflow:hidden;">
          <tr>
            <td style="padding:28px 24px 8px; background:#ffffff;">
              <table role="presentation" cellspacing="0" cellpadding="0" border="0">
                <tr>
                  <td style="vertical-align:middle;">
                    <div aria-hidden="true" style="width:48px; height:48px; border-radius:12px; background:${BRAND_PRIMARY}; color:#ffffff; font-size:26px; font-weight:700; line-height:48px; text-align:center;">
                      ⚡
                    </div>
                  </td>
                  <td style="padding-left:12px; vertical-align:middle;">
                    <div style="font-family:Nunito, Arial, sans-serif; font-size:26px; font-weight:800; line-height:1.1; color:${BRAND_SECONDARY};">
                      <span style="color:${BRAND_SECONDARY};">Szybka</span><span style="color:${BRAND_PRIMARY};">Fucha</span>
                    </div>
                    <div style="margin-top:4px; font-size:12px; line-height:1.4; color:#6b7280;">
                      Zlecaj lub zarabiaj lokalnie. Szybko. Bezpiecznie.
                    </div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          <tr>
            <td style="padding:8px 24px 0; background:#ffffff;">
              <p style="margin:0 0 12px; font-size:12px; font-weight:800; letter-spacing:1.8px; text-transform:uppercase; color:${BRAND_PRIMARY};">${this.escapeHtml(
      input.eyebrow,
    )}</p>
              <h1 style="margin:0; font-family:Nunito, Arial, sans-serif; font-size:30px; line-height:1.2; color:${BRAND_SECONDARY};">${this.escapeHtml(
      input.title,
    )}</h1>
              <p style="margin:14px 0 0; font-size:15px; line-height:1.7; color:#4b5563;">
              ${this.escapeHtml(input.intro)}
              </p>
            </td>
          </tr>

          <tr>
            <td style="padding:32px 24px;">
              ${input.bodyHtml}

              <div style="margin-top:24px; padding:20px 22px; border-radius:20px; background:#f9fafb; border:1px solid #eceff3;">
                <p style="margin:0; font-size:13px; line-height:1.7; color:#6b7280;">
                  ${this.escapeHtml(input.footer)}
                </p>
                <p style="margin:18px 0 0; font-size:13px; line-height:1.6; color:#6b7280;">
                  <a href="${FACEBOOK_URL}" target="_blank" rel="noopener noreferrer" style="color:${BRAND_PRIMARY}; text-decoration:underline;">Obserwuj nas na Facebooku</a>
                </p>
                <p style="margin:18px 0 0; font-size:12px; line-height:1.8; color:#9ca3af;">
                  <a href="${PRIVACY_URL}" target="_blank" rel="noopener noreferrer" style="color:${BRAND_PRIMARY}; text-decoration:underline;">Polityka prywatnosci</a>
                  &nbsp;&middot;&nbsp;
                  <a href="${TERMS_URL}" target="_blank" rel="noopener noreferrer" style="color:${BRAND_PRIMARY}; text-decoration:underline;">Regulamin</a>
                  &nbsp;&middot;&nbsp;
                  <a href="${COOKIES_URL}" target="_blank" rel="noopener noreferrer" style="color:${BRAND_PRIMARY}; text-decoration:underline;">Cookies</a>
                </p>
                <p style="margin:16px 0 0; font-size:12px; line-height:1.7; color:#9ca3af;">
                  SzybkaFucha<br />
                  Zlecaj lub zarabiaj lokalnie. Szybko. Bezpiecznie.
                </p>
              </div>
            </td>
          </tr>
        </table>
      </div>
    `;
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
    otpCode?: string,
  ): Promise<void> {
    const transporter = this.getTransporter();

    if (this.isDev && !transporter && otpCode) {
      this.logger.log(`[DEV] Email OTP for ${to}: ${otpCode}`);
      return;
    }

    if (!transporter) {
      this.logger.warn(
        `SMTP not configured - Email not sent to ${to}${otpCode ? ` (OTP: ${otpCode})` : ''}`,
      );
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
