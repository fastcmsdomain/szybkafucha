/**
 * Authenticated User Type
 * Represents the user object attached to the request by JWT strategy
 */
import { UserStatus, UserType } from '../../users/entities/user.entity';

export interface AuthenticatedUser {
  id: string;
  type: UserType;
  email: string | null;
  phone: string | null;
  name: string | null;
  status: UserStatus;
}
