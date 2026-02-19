import { Test, TestingModule } from '@nestjs/testing';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { UserType } from '../users/entities/user.entity';

describe('AuthController', () => {
  let controller: AuthController;
  let authService: jest.Mocked<AuthService>;

  beforeEach(async () => {
    const mockAuthService = {
      requestPhoneOtp: jest.fn(),
      verifyPhoneOtp: jest.fn(),
      authenticateWithGoogle: jest.fn(),
      authenticateWithApple: jest.fn(),
      registerWithEmail: jest.fn(),
      loginWithEmail: jest.fn(),
      verifyEmailOtp: jest.fn(),
      resendEmailVerificationOtp: jest.fn(),
      requestPasswordReset: jest.fn(),
      resetPassword: jest.fn(),
      selectRole: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      controllers: [AuthController],
      providers: [{ provide: AuthService, useValue: mockAuthService }],
    }).compile();

    controller = module.get<AuthController>(AuthController);
    authService = module.get<AuthService>(AuthService) as jest.Mocked<AuthService>;
  });

  describe('POST /auth/role/select', () => {
    it('should call authService.selectRole with authenticated user id and role', async () => {
      const req = {
        user: {
          id: 'user-123',
          types: [],
          email: 'user@example.com',
          phone: null,
          name: 'User',
          status: 'active',
        },
      } as any;

      authService.selectRole.mockResolvedValue({
        accessToken: 'new-jwt-token',
        user: { id: 'user-123', types: [UserType.CLIENT] },
        requiresRoleSelection: false,
      });

      const result = await controller.selectRole(req, { role: UserType.CLIENT });

      expect(authService.selectRole).toHaveBeenCalledWith(
        'user-123',
        UserType.CLIENT,
      );
      expect(result.requiresRoleSelection).toBe(false);
    });
  });
});
