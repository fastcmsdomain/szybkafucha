import { NotificationType } from './notification-templates';
import {
  applyRoleRestrictions,
  DEFAULT_NOTIFICATION_PREFERENCES,
  getPreferenceKeyForNotificationType,
  normalizeNotificationPreferences,
} from './notification-preferences';

describe('notification-preferences constants', () => {
  it('maps notification types to preference categories', () => {
    expect(getPreferenceKeyForNotificationType(NotificationType.NEW_MESSAGE)).toBe(
      'messages',
    );
    expect(
      getPreferenceKeyForNotificationType(NotificationType.PAYMENT_FAILED),
    ).toBe('payments');
    expect(
      getPreferenceKeyForNotificationType(NotificationType.KYC_COMPLETE),
    ).toBe('kycUpdates');
  });

  it('normalizes partial preferences with defaults', () => {
    const normalized = normalizeNotificationPreferences({
      messages: false,
      payments: false,
    });

    expect(normalized).toEqual({
      ...DEFAULT_NOTIFICATION_PREFERENCES,
      messages: false,
      payments: false,
    });
  });

  it('disables contractor-only categories for non-contractor roles', () => {
    const clientResult = applyRoleRestrictions(
      { ...DEFAULT_NOTIFICATION_PREFERENCES },
      ['client'],
    );
    expect(clientResult.newNearbyTasks).toBe(false);
    expect(clientResult.kycUpdates).toBe(false);

    const contractorResult = applyRoleRestrictions(
      { ...DEFAULT_NOTIFICATION_PREFERENCES },
      ['contractor'],
    );
    expect(contractorResult.newNearbyTasks).toBe(true);
    expect(contractorResult.kycUpdates).toBe(true);
  });
});
