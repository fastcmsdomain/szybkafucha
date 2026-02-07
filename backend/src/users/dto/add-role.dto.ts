/**
 * DTO for adding a role to user
 */
import { IsEnum } from 'class-validator';

export enum UserRole {
  CLIENT = 'client',
  CONTRACTOR = 'contractor',
}

export class AddRoleDto {
  @IsEnum(UserRole)
  role: UserRole;
}
