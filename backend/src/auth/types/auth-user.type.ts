/**
 * Authenticated User Type
 * Represents the user object attached to the request by JWT strategy
 */
export interface AuthenticatedUser {
  id: string;
  type: string;
  email: string | null;
  phone: string | null;
  name: string | null;
  status: string;
}
