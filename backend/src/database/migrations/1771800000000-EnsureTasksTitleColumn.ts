import { MigrationInterface, QueryRunner } from 'typeorm';

export class EnsureTasksTitleColumn1771800000000 implements MigrationInterface {
  name = 'EnsureTasksTitleColumn1771800000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "tasks"
      ADD COLUMN IF NOT EXISTS "title" character varying(200)
    `);

    await queryRunner.query(`
      UPDATE "tasks"
      SET "title" = LEFT(COALESCE(NULLIF("description", ''), 'Zlecenie'), 200)
      WHERE "title" IS NULL OR TRIM("title") = ''
    `);

    await queryRunner.query(`
      ALTER TABLE "tasks"
      ALTER COLUMN "title" SET NOT NULL
    `);
  }

  public async down(_queryRunner: QueryRunner): Promise<void> {
    // no-op: do not drop canonical column to avoid data loss
  }
}
