import { IsBoolean } from 'class-validator';

export class NotificationPreferencesDto {
  @IsBoolean()
  messages: boolean;

  @IsBoolean()
  taskUpdates: boolean;

  @IsBoolean()
  payments: boolean;

  @IsBoolean()
  ratingsAndTips: boolean;

  @IsBoolean()
  newNearbyTasks: boolean;

  @IsBoolean()
  kycUpdates: boolean;
}
