import { IsBoolean, IsOptional } from 'class-validator';

export class UpdateNotificationPreferencesDto {
  @IsOptional()
  @IsBoolean()
  messages?: boolean;

  @IsOptional()
  @IsBoolean()
  taskUpdates?: boolean;

  @IsOptional()
  @IsBoolean()
  payments?: boolean;

  @IsOptional()
  @IsBoolean()
  ratingsAndTips?: boolean;

  @IsOptional()
  @IsBoolean()
  newNearbyTasks?: boolean;

  @IsOptional()
  @IsBoolean()
  kycUpdates?: boolean;
}
