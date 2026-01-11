import { MigrationInterface, QueryRunner } from 'typeorm';

/**
 * Initial database schema migration for Szybka Fucha
 * This migration creates all tables from scratch for fresh deployments.
 *
 * Note: If the database already has tables (from synchronize: true),
 * this migration will be skipped as tables already exist.
 */
export class InitialSchema1768161108457 implements MigrationInterface {
  name = 'InitialSchema1768161108457';

  public async up(queryRunner: QueryRunner): Promise<void> {
    // Enable UUID extension
    await queryRunner.query(`CREATE EXTENSION IF NOT EXISTS "uuid-ossp"`);

    // Create enum types
    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."users_type_enum" AS ENUM ('client', 'contractor');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."users_status_enum" AS ENUM ('pending', 'active', 'suspended', 'banned');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."tasks_status_enum" AS ENUM ('created', 'accepted', 'in_progress', 'completed', 'cancelled', 'disputed');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."contractor_profiles_kycstatus_enum" AS ENUM ('pending', 'verified', 'rejected');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."payments_status_enum" AS ENUM ('pending', 'held', 'captured', 'refunded', 'failed');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."kyc_checks_type_enum" AS ENUM ('document', 'facial_similarity', 'bank_account');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."kyc_checks_status_enum" AS ENUM ('pending', 'in_progress', 'complete', 'failed');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    await queryRunner.query(`
      DO $$ BEGIN
        CREATE TYPE "public"."kyc_checks_result_enum" AS ENUM ('clear', 'consider', 'unidentified');
      EXCEPTION
        WHEN duplicate_object THEN null;
      END $$;
    `);

    // Create users table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "users" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "type" "public"."users_type_enum" NOT NULL DEFAULT 'client',
        "phone" character varying(15),
        "email" character varying(255),
        "name" character varying(100),
        "avatarUrl" text,
        "status" "public"."users_status_enum" NOT NULL DEFAULT 'pending',
        "googleId" character varying(255),
        "appleId" character varying(255),
        "fcmToken" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_users" PRIMARY KEY ("id")
      )
    `);

    // Create indexes on users
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_email" ON "users" ("email") WHERE "email" IS NOT NULL`);
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_phone" ON "users" ("phone") WHERE "phone" IS NOT NULL`);
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_googleId" ON "users" ("googleId") WHERE "googleId" IS NOT NULL`);
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS "IDX_users_appleId" ON "users" ("appleId") WHERE "appleId" IS NOT NULL`);

    // Create contractor_profiles table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "contractor_profiles" (
        "userId" uuid NOT NULL,
        "bio" text,
        "categories" text NOT NULL DEFAULT '',
        "serviceRadiusKm" integer NOT NULL DEFAULT 10,
        "kycStatus" "public"."contractor_profiles_kycstatus_enum" NOT NULL DEFAULT 'pending',
        "kycIdVerified" boolean NOT NULL DEFAULT false,
        "kycSelfieVerified" boolean NOT NULL DEFAULT false,
        "kycBankVerified" boolean NOT NULL DEFAULT false,
        "stripeAccountId" character varying(255),
        "ratingAvg" numeric(3,2) NOT NULL DEFAULT 0,
        "ratingCount" integer NOT NULL DEFAULT 0,
        "completedTasksCount" integer NOT NULL DEFAULT 0,
        "isOnline" boolean NOT NULL DEFAULT false,
        "lastLocationLat" numeric(10,7),
        "lastLocationLng" numeric(10,7),
        "lastLocationAt" TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_contractor_profiles" PRIMARY KEY ("userId"),
        CONSTRAINT "FK_contractor_profiles_user" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    // Create tasks table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "tasks" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "clientId" uuid NOT NULL,
        "contractorId" uuid,
        "category" character varying(50) NOT NULL,
        "title" character varying(200) NOT NULL,
        "description" text,
        "locationLat" numeric(10,7) NOT NULL,
        "locationLng" numeric(10,7) NOT NULL,
        "address" text NOT NULL,
        "budgetAmount" numeric(10,2) NOT NULL,
        "finalAmount" numeric(10,2),
        "commissionAmount" numeric(10,2),
        "tipAmount" numeric(10,2) NOT NULL DEFAULT 0,
        "status" "public"."tasks_status_enum" NOT NULL DEFAULT 'created',
        "completionPhotos" text,
        "scheduledAt" TIMESTAMP,
        "acceptedAt" TIMESTAMP,
        "startedAt" TIMESTAMP,
        "completedAt" TIMESTAMP,
        "cancelledAt" TIMESTAMP,
        "cancellationReason" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_tasks" PRIMARY KEY ("id"),
        CONSTRAINT "FK_tasks_client" FOREIGN KEY ("clientId") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_tasks_contractor" FOREIGN KEY ("contractorId") REFERENCES "users"("id") ON DELETE SET NULL
      )
    `);

    // Create indexes on tasks
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_tasks_status" ON "tasks" ("status")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_tasks_clientId" ON "tasks" ("clientId")`);
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_tasks_contractorId" ON "tasks" ("contractorId")`);

    // Create ratings table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "ratings" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "taskId" uuid NOT NULL,
        "fromUserId" uuid NOT NULL,
        "toUserId" uuid NOT NULL,
        "rating" integer NOT NULL,
        "comment" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_ratings" PRIMARY KEY ("id"),
        CONSTRAINT "FK_ratings_task" FOREIGN KEY ("taskId") REFERENCES "tasks"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_ratings_fromUser" FOREIGN KEY ("fromUserId") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_ratings_toUser" FOREIGN KEY ("toUserId") REFERENCES "users"("id") ON DELETE CASCADE,
        CONSTRAINT "CHK_ratings_value" CHECK (rating >= 1 AND rating <= 5)
      )
    `);

    // Create messages table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "messages" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "taskId" uuid NOT NULL,
        "senderId" uuid NOT NULL,
        "content" text NOT NULL,
        "readAt" TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_messages" PRIMARY KEY ("id"),
        CONSTRAINT "FK_messages_task" FOREIGN KEY ("taskId") REFERENCES "tasks"("id") ON DELETE CASCADE,
        CONSTRAINT "FK_messages_sender" FOREIGN KEY ("senderId") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    // Create index on messages
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_messages_taskId" ON "messages" ("taskId")`);

    // Create payments table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "payments" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "taskId" uuid NOT NULL,
        "stripePaymentIntentId" character varying(255),
        "stripeTransferId" character varying(255),
        "amount" numeric(10,2) NOT NULL,
        "commissionAmount" numeric(10,2),
        "contractorAmount" numeric(10,2),
        "status" "public"."payments_status_enum" NOT NULL DEFAULT 'pending',
        "refundReason" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_payments" PRIMARY KEY ("id"),
        CONSTRAINT "FK_payments_task" FOREIGN KEY ("taskId") REFERENCES "tasks"("id") ON DELETE CASCADE
      )
    `);

    // Create kyc_checks table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "kyc_checks" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "userId" uuid NOT NULL,
        "type" "public"."kyc_checks_type_enum" NOT NULL,
        "onfidoApplicantId" character varying(255),
        "onfidoCheckId" character varying(255),
        "onfidoDocumentId" character varying(255),
        "status" "public"."kyc_checks_status_enum" NOT NULL DEFAULT 'pending',
        "result" "public"."kyc_checks_result_enum",
        "resultDetails" jsonb,
        "errorMessage" text,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "completedAt" TIMESTAMP,
        CONSTRAINT "PK_kyc_checks" PRIMARY KEY ("id"),
        CONSTRAINT "FK_kyc_checks_user" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE
      )
    `);

    // Create index on kyc_checks
    await queryRunner.query(`CREATE INDEX IF NOT EXISTS "IDX_kyc_checks_userId" ON "kyc_checks" ("userId")`);

    // Create newsletter_subscribers table
    await queryRunner.query(`
      CREATE TABLE IF NOT EXISTS "newsletter_subscribers" (
        "id" uuid NOT NULL DEFAULT uuid_generate_v4(),
        "name" character varying(255) NOT NULL,
        "email" character varying(255) NOT NULL,
        "city" character varying(100),
        "userType" character varying(20) NOT NULL,
        "consent" boolean NOT NULL DEFAULT true,
        "services" text,
        "comments" text,
        "source" character varying(50),
        "isActive" boolean NOT NULL DEFAULT true,
        "subscribedAt" TIMESTAMP,
        "unsubscribedAt" TIMESTAMP,
        "createdAt" TIMESTAMP NOT NULL DEFAULT now(),
        "updatedAt" TIMESTAMP NOT NULL DEFAULT now(),
        CONSTRAINT "PK_newsletter_subscribers" PRIMARY KEY ("id")
      )
    `);

    // Create unique index on newsletter_subscribers email
    await queryRunner.query(`CREATE UNIQUE INDEX IF NOT EXISTS "IDX_newsletter_subscribers_email" ON "newsletter_subscribers" ("email")`);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    // Drop tables in reverse order of dependencies
    await queryRunner.query(`DROP TABLE IF EXISTS "newsletter_subscribers" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "kyc_checks" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "payments" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "messages" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "ratings" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "tasks" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "contractor_profiles" CASCADE`);
    await queryRunner.query(`DROP TABLE IF EXISTS "users" CASCADE`);

    // Drop enum types
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."kyc_checks_result_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."kyc_checks_status_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."kyc_checks_type_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."payments_status_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."contractor_profiles_kycstatus_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."tasks_status_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."users_status_enum"`);
    await queryRunner.query(`DROP TYPE IF EXISTS "public"."users_type_enum"`);
  }
}
