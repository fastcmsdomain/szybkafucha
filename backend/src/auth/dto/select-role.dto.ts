import { IsEnum } from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class SelectRoleDto {
  @IsEnum(UserType, {
    message: 'role must be either "client" or "contractor"',
  })
  role: UserType;
}
