/**
 * Users Service
 * Business logic for user operations
 */
import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserStatus } from './entities/user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepository: Repository<User>,
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
   * Add a role to user (client or contractor)
   * Creates empty profile when role is added
   * Profiles are created lazy - they'll be populated when user edits their profile
   */
  async addRole(userId: string, role: 'client' | 'contractor'): Promise<User> {
    const user = await this.findByIdOrFail(userId);
    const validRoles = user.types.filter(
      (type): type is 'client' | 'contractor' =>
        type === 'client' || type === 'contractor',
    );

    user.types = validRoles;

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
}
