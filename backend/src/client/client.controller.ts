/**
 * Client Controller
 * REST endpoints for client-specific operations
 */
import {
  Controller,
  Get,
  Put,
  UseGuards,
  Request,
  Param,
  Body,
} from '@nestjs/common';
import { ClientService } from './client.service';
import { UpdateClientProfileDto } from './dto/update-client-profile.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import type { AuthenticatedRequest } from '../auth/types/authenticated-request.type';

@Controller('client')
@UseGuards(JwtAuthGuard)
export class ClientController {
  constructor(private readonly clientService: ClientService) {}

  /**
   * GET /client/:userId/public
   * Get public client profile for contractors viewing client
   * Returns safe public fields: name, avatar, bio, ratings
   */
  @Get(':userId/public')
  async getPublicProfile(@Param('userId') userId: string) {
    return this.clientService.getPublicProfile(userId);
  }

  /**
   * GET /client/profile
   * Get current client's profile with aggregated ratings
   * Returns: { ratingAvg: number, ratingCount: number }
   */
  @Get('profile')
  async getProfile(@Request() req: AuthenticatedRequest) {
    return this.clientService.getClientProfile(req.user.id);
  }

  /**
   * PUT /client/profile
   * Update current client's profile (bio only)
   * Automatically creates profile if it doesn't exist (lazy creation)
   */
  @Put('profile')
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @Body() dto: UpdateClientProfileDto,
  ) {
    return this.clientService.updateProfile(req.user.id, dto);
  }
}
