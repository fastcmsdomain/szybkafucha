/**
 * Authenticated User Type
 * Represents the user object attached to the request by JWT strategy
 */
import { UserStatus } from '../../users/entities/user.entity';

export interface AuthenticatedUser {
  id: string;
  types: string[]; // Array of roles: ['client'] or ['contractor'] or ['client', 'contractor']
  email: string | null;
  phone: string | null;
  name: string | null;
  status: UserStatus;
}
