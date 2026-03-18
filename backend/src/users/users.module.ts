/**
 * Users Module
 * Handles user management and profile operations
 */
import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { DeletedAccount } from './entities/deleted-account.entity';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { FileStorageService } from './file-storage.service';
import { Rating } from '../tasks/entities/rating.entity';
import { ContractorProfile } from '../contractor/entities/contractor-profile.entity';
import { ClientProfile } from '../client/entities/client-profile.entity';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [
    forwardRef(() => AuthModule),
    TypeOrmModule.forFeature([
      User,
      DeletedAccount,
      Rating,
      ContractorProfile,
      ClientProfile,
    ]),
  ],
  controllers: [UsersController],
  providers: [UsersService, FileStorageService],
  exports: [UsersService, FileStorageService],
})
export class UsersModule {}
