/**
 * Users Controller
 * REST endpoints for user operations
 */
import {
  Controller,
  Get,
  Put,
  Body,
  UseGuards,
  Request,
} from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { UpdateUserDto } from './dto/update-user.dto';
import { AuthenticatedUser } from '../auth/types/auth-user.type';

interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
}

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * GET /users/me
   * Returns the current authenticated user's profile
   */
  @UseGuards(JwtAuthGuard)
  @Get('me')
  async getProfile(@Request() req: AuthenticatedRequest) {
    return this.usersService.findByIdOrFail(req.user.id);
  }

  /**
   * PUT /users/me
   * Updates the current user's profile (name, avatar)
   */
  @UseGuards(JwtAuthGuard)
  @Put('me')
  async updateProfile(
    @Request() req: AuthenticatedRequest,
    @Body() updateUserDto: UpdateUserDto,
  ) {
    return this.usersService.update(req.user.id, updateUserDto);
  }
}
