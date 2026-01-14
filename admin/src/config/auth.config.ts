/**
 * Admin Authentication Configuration
 * 
 * IMPORTANT: Change these credentials before deploying to production!
 * 
 * For better security, consider:
 * - Using environment variables
 * - Implementing proper backend authentication
 * - Using JWT tokens with expiration
 */

export const authConfig = {
  // Admin email
  adminEmail: 'admin@szybkafucha.pl',
  
  // Admin password
  adminPassword: 'Redjansz280307!!',
  
  // Token name stored in localStorage
  tokenKey: 'adminToken',
  
  // Token value (in production, this should come from backend)
  tokenValue: 'mock-admin-token',
};
