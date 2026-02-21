import { NotificationType } from './notification-templates';

export type NotificationPreferenceKey =
  | 'messages'
  | 'taskUpdates'
  | 'payments'
  | 'ratingsAndTips'
  | 'newNearbyTasks'
  | 'kycUpdates';

export type NotificationPreferences = Record<NotificationPreferenceKey, boolean>;

export const NOTIFICATION_PREFERENCE_KEYS: NotificationPreferenceKey[] = [
  'messages',
  'taskUpdates',
  'payments',
  'ratingsAndTips',
  'newNearbyTasks',
  'kycUpdates',
];

export const CONTRACTOR_ONLY_NOTIFICATION_PREFERENCE_KEYS: NotificationPreferenceKey[] =
  ['newNearbyTasks', 'kycUpdates'];

export const DEFAULT_NOTIFICATION_PREFERENCES: NotificationPreferences = {
  messages: true,
  taskUpdates: true,
  payments: true,
  ratingsAndTips: true,
  newNearbyTasks: true,
  kycUpdates: true,
};

export const NOTIFICATION_TYPE_TO_PREFERENCE_KEY: Record<
  NotificationType,
  NotificationPreferenceKey
> = {
  [NotificationType.NEW_TASK_NEARBY]: 'newNearbyTasks',
  [NotificationType.TASK_ACCEPTED]: 'taskUpdates',
  [NotificationType.TASK_STARTED]: 'taskUpdates',
  [NotificationType.TASK_COMPLETED]: 'taskUpdates',
  [NotificationType.TASK_CONFIRMED]: 'taskUpdates',
  [NotificationType.TASK_CANCELLED]: 'taskUpdates',
  [NotificationType.TASK_RATED]: 'ratingsAndTips',
  [NotificationType.TIP_RECEIVED]: 'ratingsAndTips',
  [NotificationType.NEW_MESSAGE]: 'messages',
  [NotificationType.PAYMENT_REQUIRED]: 'payments',
  [NotificationType.PAYMENT_HELD]: 'payments',
  [NotificationType.PAYMENT_RECEIVED]: 'payments',
  [NotificationType.PAYMENT_REFUNDED]: 'payments',
  [NotificationType.PAYMENT_FAILED]: 'payments',
  [NotificationType.PAYOUT_SENT]: 'payments',
  [NotificationType.KYC_DOCUMENT_VERIFIED]: 'kycUpdates',
  [NotificationType.KYC_SELFIE_VERIFIED]: 'kycUpdates',
  [NotificationType.KYC_BANK_VERIFIED]: 'kycUpdates',
  [NotificationType.KYC_COMPLETE]: 'kycUpdates',
  [NotificationType.KYC_FAILED]: 'kycUpdates',
};

export function normalizeNotificationPreferences(
  value?: Partial<NotificationPreferences> | null,
): NotificationPreferences {
  const normalized: NotificationPreferences = { ...DEFAULT_NOTIFICATION_PREFERENCES };
  if (!value) {
    return normalized;
  }

  for (const key of NOTIFICATION_PREFERENCE_KEYS) {
    const incoming = value[key];
    if (typeof incoming === 'boolean') {
      normalized[key] = incoming;
    }
  }

  return normalized;
}

export function applyRoleRestrictions(
  preferences: NotificationPreferences,
  roles: string[] = [],
): NotificationPreferences {
  const result: NotificationPreferences = { ...preferences };
  const hasContractorRole = roles.includes('contractor');

  if (!hasContractorRole) {
    for (const key of CONTRACTOR_ONLY_NOTIFICATION_PREFERENCE_KEYS) {
      result[key] = false;
    }
  }

  return result;
}

export function getPreferenceKeyForNotificationType(
  type: NotificationType,
): NotificationPreferenceKey {
  return NOTIFICATION_TYPE_TO_PREFERENCE_KEY[type];
}
