import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddNotificationPreferencesToUsers1769068800000
  implements MigrationInterface
{
  name = 'AddNotificationPreferencesToUsers1769068800000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      ADD COLUMN IF NOT EXISTS "notificationPreferences" jsonb
      NOT NULL DEFAULT '{"messages":true,"taskUpdates":true,"payments":true,"ratingsAndTips":true,"newNearbyTasks":true,"kycUpdates":true}'::jsonb
    `);

    await queryRunner.query(`
      UPDATE "users"
      SET "notificationPreferences" = '{"messages":true,"taskUpdates":true,"payments":true,"ratingsAndTips":true,"newNearbyTasks":true,"kycUpdates":true}'::jsonb
      WHERE "notificationPreferences" IS NULL
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      DROP COLUMN IF EXISTS "notificationPreferences"
    `);
  }
}
