/**
 * Admin Controller
 * REST endpoints for admin dashboard
 */
import {
  Controller,
  Get,
  Put,
  Body,
  Param,
  Query,
  UseGuards,
  ParseUUIDPipe,
  ParseIntPipe,
  DefaultValuePipe,
} from '@nestjs/common';
import { AdminService } from './admin.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { AdminGuard } from './guards/admin.guard';
import { UserStatus, UserType, User } from '../users/entities/user.entity';
import { TaskStatus, Task } from '../tasks/entities/task.entity';
import {
  DashboardMetrics,
  PaginatedResponse,
  UserWithProfile,
  DisputeDetails,
  ContractorStats,
} from './dto/admin.dto';
import type { DisputeResolution } from './dto/admin.dto';

@Controller('admin')
@UseGuards(JwtAuthGuard, AdminGuard)
export class AdminController {
  constructor(private readonly adminService: AdminService) {}

  /**
   * GET /admin/dashboard
   * Returns key metrics for the admin dashboard
   */
  @Get('dashboard')
  async getDashboard(): Promise<DashboardMetrics> {
    return this.adminService.getDashboardMetrics();
  }

  /**
   * GET /admin/users
   * Returns paginated list of users with filters
   */
  @Get('users')
  async getUsers(
    @Query('type') type?: UserType,
    @Query('status') status?: UserStatus,
    @Query('search') search?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ): Promise<PaginatedResponse<User>> {
    return this.adminService.getUsers({ type, status, search, page, limit });
  }

  /**
   * GET /admin/users/:id
   * Returns single user details
   */
  @Get('users/:id')
  async getUser(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<UserWithProfile> {
    return this.adminService.getUserById(id);
  }

  /**
   * PUT /admin/users/:id/status
   * Change user status
   */
  @Put('users/:id/status')
  async updateUserStatus(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('status') status: UserStatus,
  ): Promise<User> {
    return this.adminService.updateUserStatus(id, status);
  }

  /**
   * GET /admin/users/:id/contractor-stats
   * Get contractor statistics
   */
  @Get('users/:id/contractor-stats')
  async getContractorStats(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<ContractorStats> {
    return this.adminService.getContractorStats(id);
  }

  /**
   * GET /admin/tasks
   * Returns paginated list of tasks with filters
   */
  @Get('tasks')
  async getTasks(
    @Query('status') status?: TaskStatus,
    @Query('category') category?: string,
    @Query('clientId') clientId?: string,
    @Query('contractorId') contractorId?: string,
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ): Promise<PaginatedResponse<Task>> {
    return this.adminService.getTasks({
      status,
      category,
      clientId,
      contractorId,
      page,
      limit,
    });
  }

  /**
   * GET /admin/disputes
   * Returns list of disputed tasks
   */
  @Get('disputes')
  async getDisputes(
    @Query('page', new DefaultValuePipe(1), ParseIntPipe) page?: number,
    @Query('limit', new DefaultValuePipe(20), ParseIntPipe) limit?: number,
  ): Promise<PaginatedResponse<Task>> {
    return this.adminService.getDisputes(page, limit);
  }

  /**
   * GET /admin/disputes/:id
   * Returns single dispute details
   */
  @Get('disputes/:id')
  async getDispute(
    @Param('id', ParseUUIDPipe) id: string,
  ): Promise<DisputeDetails> {
    return this.adminService.getDisputeById(id);
  }

  /**
   * PUT /admin/disputes/:id/resolve
   * Resolve a dispute
   */
  @Put('disputes/:id/resolve')
  async resolveDispute(
    @Param('id', ParseUUIDPipe) id: string,
    @Body('resolution') resolution: DisputeResolution,
    @Body('notes') notes: string,
  ): Promise<Task> {
    return this.adminService.resolveDispute(id, resolution, notes);
  }
}
