import { IsEnum } from 'class-validator';
import { UserType } from '../entities/user.entity';

/**
 * DTO for updating user type (client/contractor)
 */
export class UpdateUserTypeDto {
  @IsEnum(UserType, {
    message: 'type must be either "client" or "contractor"',
  })
  type: UserType;
}
