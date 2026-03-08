/**
 * Admin Authentication Configuration
 *
 * Authentication is handled via backend API (/auth/email/login)
 *
 * Default development credentials:
 * - Email: admin@szybkafucha.pl
 * - Password: AdminPass123!
 *
 * Run `npm run seed` in backend to create the admin user
 */

export const authConfig = {
  // Admin email (for development fallback)
  adminEmail: 'admin@szybkafucha.pl',

  // Admin password (for development fallback)
  adminPassword: 'AdminPass123!',

  // Token name stored in localStorage
  tokenKey: 'adminToken',

  // Token value (for development fallback only - when backend is not running)
  tokenValue: 'mock-admin-token',
};
