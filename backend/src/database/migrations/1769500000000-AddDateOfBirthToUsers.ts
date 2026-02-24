import { MigrationInterface, QueryRunner } from 'typeorm';

export class AddDateOfBirthToUsers1769500000000 implements MigrationInterface {
  name = 'AddDateOfBirthToUsers1769500000000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      ADD COLUMN IF NOT EXISTS "dateOfBirth" date
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      ALTER TABLE "users"
      DROP COLUMN IF EXISTS "dateOfBirth"
    `);
  }
}
