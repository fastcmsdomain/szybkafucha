/**
 * Admin Guard
 * Restricts access to admin users only
 * 
 * For MVP, admin users are identified by email ending with @szybkafucha.pl
 * In production, implement proper role-based access control
 */
import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
} from '@nestjs/common';
import { AuthenticatedUser } from '../../auth/types/auth-user.type';

@Injectable()
export class AdminGuard implements CanActivate {
  // Admin email domains/addresses (can be moved to config)
  private readonly adminEmails = [
    'admin@szybkafucha.pl',
  ];

  private readonly adminDomain = '@szybkafucha.pl';

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const user = request.user as AuthenticatedUser | undefined;

    if (!user) {
      throw new ForbiddenException('User not authenticated');
    }

    // Check if user email is in admin list or has admin domain
    const isAdmin = this.isAdminUser(user.email);

    if (!isAdmin) {
      throw new ForbiddenException('Admin access required');
    }

    return true;
  }

  private isAdminUser(email: string | null): boolean {
    if (!email) {
      return false;
    }

    // Check if email is in explicit admin list
    if (this.adminEmails.includes(email.toLowerCase())) {
      return true;
    }

    // Check if email ends with admin domain
    if (email.toLowerCase().endsWith(this.adminDomain)) {
      return true;
    }

    return false;
  }
}
