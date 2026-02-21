/**
 * Users Service
 * Business logic for user operations
 */
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserStatus } from './entities/user.entity';
import { DeletedAccount } from './entities/deleted-account.entity';
import { Rating } from '../tasks/entities/rating.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { ClientProfile } from '../client/entities/client-profile.entity';
import {
  applyRoleRestrictions,
  DEFAULT_NOTIFICATION_PREFERENCES,
  NOTIFICATION_PREFERENCE_KEYS,
  normalizeNotificationPreferences,
  NotificationPreferences,
} from '../notifications/constants/notification-preferences';
import { UpdateNotificationPreferencesDto } from './dto/update-notification-preferences.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
    @InjectRepository(DeletedAccount)
    private readonly deletedAccountRepository: Repository<DeletedAccount>,
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @InjectRepository(ClientProfile)
    private readonly clientProfileRepository: Repository<ClientProfile>,
  ) {}

  /**
   * Find user by ID
   */
  async findById(id: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { id } });
  }

  /**
   * Find user by ID or throw error
   */
  async findByIdOrFail(id: string): Promise<User> {
    const user = await this.findById(id);
    if (!user) {
      throw new NotFoundException(`User with ID ${id} not found`);
    }
    return user;
  }

  /**
   * Find user by phone number
   */
  async findByPhone(phone: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { phone } });
  }

  /**
   * Find user by email
   */
  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { email } });
  }

  /**
   * Find user by Google ID
   */
  async findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { googleId } });
  }

  /**
   * Find user by Apple ID
   */
  async findByAppleId(appleId: string): Promise<User | null> {
    return this.usersRepository.findOne({ where: { appleId } });
  }

  /**
   * Create a new user
   */
  async create(data: Partial<User>): Promise<User> {
    const user = this.usersRepository.create(data);
    return this.usersRepository.save(user);
  }

  /**
   * Update user profile
   */
  async update(id: string, data: Partial<User>): Promise<User> {
    await this.usersRepository.update(id, data);
    return this.findByIdOrFail(id);
  }

  /**
   * Update user status
   */
  async updateStatus(id: string, status: UserStatus): Promise<User> {
    return this.update(id, { status });
  }

  /**
   * Update FCM token for push notifications
   */
  async updateFcmToken(id: string, fcmToken: string): Promise<User> {
    return this.update(id, { fcmToken });
  }

  /**
   * Get notification preferences for current user.
   * Ensures defaults are backfilled for legacy rows.
   */
  async getNotificationPreferences(
    id: string,
    userRoles: string[] = [],
  ): Promise<NotificationPreferences> {
    const user = await this.findByIdOrFail(id);
    const normalized = applyRoleRestrictions(
      normalizeNotificationPreferences(
        user.notificationPreferences as Partial<NotificationPreferences> | null,
      ),
      userRoles.length > 0 ? userRoles : user.types,
    );

    if (!this.arePreferencesEqual(user.notificationPreferences, normalized)) {
      await this.usersRepository.update(id, {
        notificationPreferences: normalized,
      });
    }

    return normalized;
  }

  /**
   * Update notification preferences for current user.
   * Unknown keys are ignored by validation and contractor-only keys
   * are disabled for non-contractor users.
   */
  async updateNotificationPreferences(
    id: string,
    data: UpdateNotificationPreferencesDto,
    userRoles: string[] = [],
  ): Promise<NotificationPreferences> {
    const current = await this.getNotificationPreferences(id, userRoles);
    const roles =
      userRoles.length > 0 ? userRoles : (await this.findByIdOrFail(id)).types;
    const patch = this.toNotificationPreferencesPatch(data);
    const merged = applyRoleRestrictions(
      {
        ...current,
        ...patch,
      },
      roles,
    );

    await this.usersRepository.update(id, {
      notificationPreferences: merged,
    });

    return merged;
  }

  private toNotificationPreferencesPatch(
    data: UpdateNotificationPreferencesDto,
  ): Partial<NotificationPreferences> {
    const patch: Partial<NotificationPreferences> = {};

    for (const key of NOTIFICATION_PREFERENCE_KEYS) {
      const value = data[key];
      if (typeof value === 'boolean') {
        patch[key] = value;
      }
    }

    return patch;
  }

  /**
   * Activate user (set status to active)
   */
  async activate(id: string): Promise<User> {
    return this.updateStatus(id, UserStatus.ACTIVE);
  }

  /**
   * Find user by email with password hash (for authentication)
   * Explicitly selects passwordHash which is excluded by default
   */
  async findByEmailWithPassword(email: string): Promise<User | null> {
    return this.usersRepository
      .createQueryBuilder('user')
      .addSelect('user.passwordHash')
      .where('user.email = :email', { email })
      .getOne();
  }

  /**
   * Increment failed login attempts, lock account after 5 failures
   */
  async incrementFailedLoginAttempts(userId: string): Promise<void> {
    const user = await this.findByIdOrFail(userId);
    user.failedLoginAttempts += 1;

    if (user.failedLoginAttempts >= 5) {
      user.lockedUntil = new Date(Date.now() + 15 * 60 * 1000); // 15 minutes
    }

    await this.usersRepository.save(user);
  }

  /**
   * Reset failed login attempts after successful login
   */
  async resetFailedLoginAttempts(userId: string): Promise<void> {
    await this.usersRepository.update(userId, {
      failedLoginAttempts: 0,
      lockedUntil: null,
    });
  }

  /**
   * Mark email as verified
   */
  async setEmailVerified(userId: string): Promise<User> {
    await this.usersRepository.update(userId, { emailVerified: true });
    return this.findByIdOrFail(userId);
  }

  /**
   * Update password hash and timestamp
   */
  async updatePassword(userId: string, passwordHash: string): Promise<void> {
    await this.usersRepository.update(userId, {
      passwordHash,
      passwordUpdatedAt: new Date(),
      failedLoginAttempts: 0,
      lockedUntil: null,
    });
  }

  /**
   * Archive all user data to deleted_accounts, then anonymise and soft-delete.
   */
  async deleteAccount(userId: string): Promise<void> {
    const user = await this.findByIdOrFail(userId);

    // ── 1. Collect all associated data ──────────────────────────────────────

    const [contractorProfile, clientProfile, reviews] = await Promise.all([
      this.contractorProfileRepository.findOne({ where: { userId } }),
      this.clientProfileRepository.findOne({ where: { userId } }),
      this.ratingRepository.find({ where: { toUserId: userId } }),
    ]);

    // ── 2. Compute per-role rating summaries ─────────────────────────────────

    const contractorReviews = reviews.filter((r) => r.role === 'contractor');
    const clientReviews = reviews.filter((r) => r.role === 'client');

    const avg = (items: Rating[]) =>
      items.length ? items.reduce((s, r) => s + r.rating, 0) / items.length : 0;

    // ── 3. Persist archive record ─────────────────────────────────────────────

    const archive = this.deletedAccountRepository.create({
      originalUserId: userId,
      userTypes: user.types,
      email: user.email,
      phone: user.phone,
      name: user.name,
      address: user.address,
      avatarUrl: user.avatarUrl,
      contractorBio: contractorProfile?.bio ?? null,
      clientBio: clientProfile?.bio ?? null,
      contractorRatingAvg: avg(contractorReviews),
      contractorRatingCount: contractorReviews.length,
      clientRatingAvg: avg(clientReviews),
      clientRatingCount: clientReviews.length,
      reviews: reviews.map((r) => ({
        taskId: r.taskId,
        fromUserId: r.fromUserId,
        rating: r.rating,
        comment: r.comment,
        role: r.role,
        createdAt: r.createdAt,
      })),
    });

    await this.deletedAccountRepository.save(archive);

    // ── 4. Anonymise live record and soft-delete ──────────────────────────────

    user.name = null;
    user.avatarUrl = null;
    user.address = null;
    user.fcmToken = null;
    user.passwordHash = null;
    user.googleId = null;
    user.appleId = null;
    user.email = user.email ? `deleted_${userId}@deleted.invalid` : null;
    user.phone = user.phone ? `del_${userId.slice(0, 8)}` : null; // max 12 chars, fits varchar(15)
    user.status = UserStatus.DELETED;

    await this.usersRepository.save(user);
    await this.usersRepository.softDelete(userId);
  }

  /**
   * Add a role to user (client or contractor)
   * Creates empty profile when role is added
   * Profiles are created lazy - they'll be populated when user edits their profile
   */
  async addRole(userId: string, role: 'client' | 'contractor'): Promise<User> {
    const user = await this.findByIdOrFail(userId);

    // Check if user already has this role
    if (user.types.includes(role)) {
      return user; // Already has role, no change needed
    }

    // Add role to types array
    user.types.push(role);

    // Note: Profiles (ClientProfile/ContractorProfile) are created lazy
    // They'll be created automatically when user first edits their profile for that role

    return this.usersRepository.save(user);
  }

  private arePreferencesEqual(
    current: Record<string, boolean> | null | undefined,
    expected: NotificationPreferences,
  ): boolean {
    if (!current) {
      return false;
    }

    const normalizedCurrent = normalizeNotificationPreferences(
      current as Partial<NotificationPreferences>,
    );

    return Object.entries(DEFAULT_NOTIFICATION_PREFERENCES).every(
      ([key, value]) =>
        normalizedCurrent[key as keyof NotificationPreferences] ===
        (expected[key as keyof NotificationPreferences] ?? value),
    );
  }
}
