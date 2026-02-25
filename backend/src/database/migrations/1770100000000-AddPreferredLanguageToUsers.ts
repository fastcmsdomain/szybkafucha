import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddPreferredLanguageToUsers1770100000000
  implements MigrationInterface
{
  name = 'AddPreferredLanguageToUsers1770100000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      ADD COLUMN IF NOT EXISTS "preferredLanguage" character varying(5)
      NOT NULL DEFAULT 'pl'
    `);

    await queryRunner.query(`
      UPDATE "users"
      SET "preferredLanguage" = 'pl'
      WHERE "preferredLanguage" IS NULL
    `);

    await queryRunner.query(`
      DO $$
      BEGIN
        IF NOT EXISTS (
          SELECT 1
          FROM pg_constraint
          WHERE conname = 'CHK_users_preferredLanguage'
        ) THEN
          ALTER TABLE "users"
          ADD CONSTRAINT "CHK_users_preferredLanguage"
          CHECK ("preferredLanguage" IN ('pl', 'uk'));
        END IF;
      END
      $$;
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      DROP CONSTRAINT IF EXISTS "CHK_users_preferredLanguage"
    `);

    await queryRunner.query(`
      ALTER TABLE "users"
      DROP COLUMN IF EXISTS "preferredLanguage"
    `);
  }
}
