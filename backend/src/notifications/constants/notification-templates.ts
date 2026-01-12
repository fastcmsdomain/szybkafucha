/**
 * Notification Templates
 * Defines all push notification types and their content
 */

export enum NotificationType {
  // Task events
  NEW_TASK_NEARBY = 'new_task_nearby',
  TASK_ACCEPTED = 'task_accepted',
  TASK_STARTED = 'task_started',
  TASK_COMPLETED = 'task_completed',
  TASK_CONFIRMED = 'task_confirmed',
  TASK_CANCELLED = 'task_cancelled',
  TASK_RATED = 'task_rated',
  TIP_RECEIVED = 'tip_received',

  // Message events
  NEW_MESSAGE = 'new_message',

  // Payment events
  PAYMENT_REQUIRED = 'payment_required',
  PAYMENT_HELD = 'payment_held',
  PAYMENT_RECEIVED = 'payment_received',
  PAYMENT_REFUNDED = 'payment_refunded',
  PAYMENT_FAILED = 'payment_failed',
  PAYOUT_SENT = 'payout_sent',

  // KYC events
  KYC_DOCUMENT_VERIFIED = 'kyc_document_verified',
  KYC_SELFIE_VERIFIED = 'kyc_selfie_verified',
  KYC_BANK_VERIFIED = 'kyc_bank_verified',
  KYC_COMPLETE = 'kyc_complete',
  KYC_FAILED = 'kyc_failed',
}

export interface NotificationTemplate {
  title: string;
  body: string;
}

/**
 * Notification templates with placeholders
 * Placeholders use {variableName} format and will be replaced with actual data
 */
export const NOTIFICATION_TEMPLATES: Record<NotificationType, NotificationTemplate> = {
  // Task events
  [NotificationType.NEW_TASK_NEARBY]: {
    title: 'Nowe zlecenie w pobliżu!',
    body: '{category} - {budget} PLN ({distance}km od Ciebie)',
  },
  [NotificationType.TASK_ACCEPTED]: {
    title: 'Zlecenie zaakceptowane!',
    body: '{contractorName} przyjął Twoje zlecenie "{taskTitle}"',
  },
  [NotificationType.TASK_STARTED]: {
    title: 'Zlecenie rozpoczęte',
    body: '{contractorName} rozpoczął pracę nad "{taskTitle}"',
  },
  [NotificationType.TASK_COMPLETED]: {
    title: 'Zlecenie wykonane!',
    body: '"{taskTitle}" zostało ukończone. Potwierdź wykonanie.',
  },
  [NotificationType.TASK_CONFIRMED]: {
    title: 'Zlecenie potwierdzone!',
    body: 'Klient potwierdził wykonanie "{taskTitle}". Płatność w drodze!',
  },
  [NotificationType.TASK_CANCELLED]: {
    title: 'Zlecenie anulowane',
    body: '"{taskTitle}" zostało anulowane. Powód: {reason}',
  },
  [NotificationType.TASK_RATED]: {
    title: 'Nowa ocena!',
    body: 'Otrzymałeś ocenę {rating}/5 za "{taskTitle}"',
  },
  [NotificationType.TIP_RECEIVED]: {
    title: 'Otrzymałeś napiwek!',
    body: 'Klient dodał {tipAmount} PLN napiwku za "{taskTitle}"',
  },

  // Message events
  [NotificationType.NEW_MESSAGE]: {
    title: 'Nowa wiadomość',
    body: '{senderName}: {messagePreview}',
  },

  // Payment events
  [NotificationType.PAYMENT_REQUIRED]: {
    title: 'Wymagana płatność',
    body: 'Dokonaj płatności {amount} PLN za "{taskTitle}"',
  },
  [NotificationType.PAYMENT_HELD]: {
    title: 'Płatność zabezpieczona',
    body: 'Środki zostały zabezpieczone. Wykonawca może rozpocząć pracę.',
  },
  [NotificationType.PAYMENT_RECEIVED]: {
    title: 'Płatność otrzymana!',
    body: 'Otrzymałeś {amount} PLN za "{taskTitle}"',
  },
  [NotificationType.PAYMENT_REFUNDED]: {
    title: 'Zwrot środków',
    body: 'Otrzymałeś zwrot {amount} PLN za "{taskTitle}"',
  },
  [NotificationType.PAYMENT_FAILED]: {
    title: 'Płatność nieudana',
    body: 'Płatność za "{taskTitle}" nie powiodła się. Spróbuj ponownie.',
  },
  [NotificationType.PAYOUT_SENT]: {
    title: 'Wypłata wysłana',
    body: 'Wypłata {amount} PLN została wysłana na Twoje konto.',
  },

  // KYC events
  [NotificationType.KYC_DOCUMENT_VERIFIED]: {
    title: 'Dokument zweryfikowany',
    body: 'Twój dokument tożsamości został zweryfikowany. Dodaj selfie.',
  },
  [NotificationType.KYC_SELFIE_VERIFIED]: {
    title: 'Selfie zweryfikowane',
    body: 'Twoje selfie zostało zweryfikowane. Dodaj dane bankowe.',
  },
  [NotificationType.KYC_BANK_VERIFIED]: {
    title: 'Konto bankowe zweryfikowane',
    body: 'Twoje konto bankowe zostało zweryfikowane.',
  },
  [NotificationType.KYC_COMPLETE]: {
    title: 'Weryfikacja zakończona!',
    body: 'Gratulacje! Możesz teraz przyjmować zlecenia.',
  },
  [NotificationType.KYC_FAILED]: {
    title: 'Weryfikacja nieudana',
    body: 'Weryfikacja nie powiodła się. Spróbuj ponownie lub skontaktuj się z nami.',
  },
};

/**
 * Helper function to interpolate template placeholders with actual data
 */
export function interpolateTemplate(
  template: NotificationTemplate,
  data: Record<string, string | number>,
): NotificationTemplate {
  let title = template.title;
  let body = template.body;

  for (const [key, value] of Object.entries(data)) {
    const placeholder = `{${key}}`;
    title = title.replace(placeholder, String(value));
    body = body.replace(placeholder, String(value));
  }

  return { title, body };
}
