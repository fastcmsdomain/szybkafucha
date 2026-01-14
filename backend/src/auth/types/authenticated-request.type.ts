import type { Request } from 'express';
import type { AuthenticatedUser } from './auth-user.type';

export interface AuthenticatedRequest extends Request {
  user: AuthenticatedUser;
}
