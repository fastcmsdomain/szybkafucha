/**
 * Seed Service
 * Populates database with test data for development
 */
import { Injectable, Logger } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from '../../users/entities/user.entity';
import { ContractorProfile } from '../../contractor/entities/contractor-profile.entity';
import { Task } from '../../tasks/entities/task.entity';
import { Rating } from '../../tasks/entities/rating.entity';
import {
  seedClients,
  seedContractors,
  seedTasks,
  seedRatings,
  seedAdmin,
} from './seed.data';

@Injectable()
export class SeedService {
  private readonly logger = new Logger(SeedService.name);

  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(ContractorProfile)
    private readonly contractorProfileRepository: Repository<ContractorProfile>,
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(Rating)
    private readonly ratingRepository: Repository<Rating>,
  ) {}

  async seed(): Promise<void> {
    this.logger.log('🌱 Starting database seeding...');

    try {
      // Check if already seeded
      const existingUsers = await this.userRepository.count();
      if (existingUsers > 0) {
        this.logger.warn('⚠️ Database already has data. Skipping seed.');
        this.logger.log('💡 To reseed, run: npm run seed:fresh');
        return;
      }

      // Seed in order (respecting foreign key constraints)
      await this.seedUsers();
      await this.seedContractorProfiles();
      await this.seedTasks();
      await this.seedRatings();

      this.logger.log('✅ Database seeding completed successfully!');
      this.logSummary();
    } catch (error) {
      this.logger.error('❌ Seeding failed:', error);
      throw error;
    }
  }

  async fresh(): Promise<void> {
    this.logger.log('🗑️ Clearing existing data...');

    try {
      // Clear tables in reverse order (respecting foreign key constraints)
      await this.ratingRepository.createQueryBuilder().delete().execute();
      await this.taskRepository.createQueryBuilder().delete().execute();
      await this.contractorProfileRepository.createQueryBuilder().delete().execute();
      await this.userRepository.createQueryBuilder().delete().execute();

      this.logger.log('✅ Data cleared. Running seed...');
      await this.seed();
    } catch (error) {
      this.logger.error('❌ Fresh seed failed:', error);
      throw error;
    }
  }

  private async seedUsers(): Promise<void> {
    this.logger.log('👤 Seeding users...');

    // Seed admin
    await this.userRepository.save(seedAdmin);

    // Seed clients
    for (const client of seedClients) {
      await this.userRepository.save(client);
    }

    // Seed contractor users
    for (const contractor of seedContractors) {
      await this.userRepository.save(contractor.user);
    }

    this.logger.log(
      `   Created ${1 + seedClients.length + seedContractors.length} users`,
    );
  }

  private async seedContractorProfiles(): Promise<void> {
    this.logger.log('🔧 Seeding contractor profiles...');

    for (const contractor of seedContractors) {
      await this.contractorProfileRepository.save({
        userId: contractor.user.id,
        ...contractor.profile,
      });
    }

    this.logger.log(`   Created ${seedContractors.length} contractor profiles`);
  }

  private async seedTasks(): Promise<void> {
    this.logger.log('📋 Seeding tasks...');

    for (const task of seedTasks) {
      await this.taskRepository.save(task);
    }

    this.logger.log(`   Created ${seedTasks.length} tasks`);
  }

  private async seedRatings(): Promise<void> {
    this.logger.log('⭐ Seeding ratings...');

    for (const rating of seedRatings) {
      await this.ratingRepository.save(rating);
    }

    this.logger.log(`   Created ${seedRatings.length} ratings`);
  }

  private logSummary(): void {
    this.logger.log('');
    this.logger.log('📊 Seed Summary:');
    this.logger.log('================');
    this.logger.log(
      `👤 Users: ${1 + seedClients.length + seedContractors.length}`,
    );
    this.logger.log(`   - Admin: 1`);
    this.logger.log(`   - Clients: ${seedClients.length}`);
    this.logger.log(`   - Contractors: ${seedContractors.length}`);
    this.logger.log(`📋 Tasks: ${seedTasks.length}`);
    this.logger.log(`⭐ Ratings: ${seedRatings.length}`);
    this.logger.log('');
    this.logger.log('🔑 Test Credentials:');
    this.logger.log('================');
    this.logger.log('Admin:      admin@szybkafucha.pl / +48000000001');
    this.logger.log('Client 1:   jan.kowalski@test.pl / +48111111111');
    this.logger.log('Client 2:   anna.nowak@test.pl / +48111111112');
    this.logger.log('Contractor: marek.kurier@test.pl / +48222222221');
    this.logger.log('');
    this.logger.log('💡 Use OTP code "123456" for all test accounts');
    this.logger.log('');
  }
}
