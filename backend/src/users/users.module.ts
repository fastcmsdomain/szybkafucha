/**
 * Users Module
 * Handles user management and profile operations
 */
import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from './entities/user.entity';
import { UsersService } from './users.service';
import { UsersController } from './users.controller';
import { FileStorageService } from './file-storage.service';

@Module({
  imports: [TypeOrmModule.forFeature([User])],
  controllers: [UsersController],
  providers: [UsersService, FileStorageService],
  exports: [UsersService, FileStorageService],
})
export class UsersModule {}
