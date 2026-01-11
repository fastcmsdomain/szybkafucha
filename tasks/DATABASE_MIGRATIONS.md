# Database Migrations Guide

> **Task Reference:** 2.9 from `tasks-prd-szybka-fucha.md`
> **Status:** Completed
> **Date:** January 2026

---

## Overview

This document describes the database migration infrastructure for Szybka Fucha backend. Migrations provide version control for the database schema, enabling safe and reproducible deployments across environments.

---

## Quick Reference

### Available Commands

Run these commands from the `backend/` directory:

```bash
# Run all pending migrations
npm run migration:run

# Revert the last migration
npm run migration:revert

# Show migration status
npm run migration:show

# Generate migration from entity changes (auto-detect)
npm run migration:generate --name=AddNewField

# Create empty migration (manual SQL)
npm run migration:create --name=CustomMigration
```

---

## Development vs Production

### Development Mode (Current)

The backend uses `synchronize: true` in development, which automatically syncs entity changes to the database. This is convenient but:
- Does not track schema history
- Can cause data loss on destructive changes
- Not suitable for production

### Production Mode

For production, you must:
1. Set `NODE_ENV=production` (disables synchronize)
2. Run `npm run migration:run` on deployment
3. Never use `synchronize: true`

---

## Migration Files

### Location

```
backend/src/database/migrations/
```

### Current Migrations

| Timestamp | Name | Description |
|-----------|------|-------------|
| 1768161108457 | InitialSchema | Creates all 8 tables and enum types |

### Schema Covered by InitialSchema

**Enum Types:**
- `users_type_enum`: client, contractor
- `users_status_enum`: pending, active, suspended, banned
- `tasks_status_enum`: created, accepted, in_progress, completed, cancelled, disputed
- `contractor_profiles_kycstatus_enum`: pending, verified, rejected
- `payments_status_enum`: pending, held, captured, refunded, failed
- `kyc_checks_type_enum`: document, facial_similarity, bank_account
- `kyc_checks_status_enum`: pending, in_progress, complete, failed
- `kyc_checks_result_enum`: clear, consider, unidentified

**Tables:**
1. `users` - User accounts (clients and contractors)
2. `contractor_profiles` - Extended profile for contractors
3. `tasks` - Task/job listings
4. `ratings` - User ratings and reviews
5. `messages` - In-app chat messages
6. `payments` - Stripe payment records
7. `kyc_checks` - Onfido KYC verification records
8. `newsletter_subscribers` - Newsletter signups

---

## Common Workflows

### Adding a New Column

1. Update the entity file (e.g., `user.entity.ts`)
2. Generate migration:
   ```bash
   npm run migration:generate --name=AddUserBio
   ```
3. Review the generated migration file
4. Run migration:
   ```bash
   npm run migration:run
   ```

### Creating a Custom Migration

For complex changes (data migrations, custom SQL):

```bash
npm run migration:create --name=MigrateUserData
```

Then edit the generated file in `src/database/migrations/`.

### Reverting a Bad Migration

```bash
npm run migration:revert
```

This runs the `down()` method of the last executed migration.

### Checking Migration Status

```bash
npm run migration:show
```

Output:
```
[X] 1768161108457-InitialSchema  # X = executed
[ ] 1768200000000-NewMigration   # empty = pending
```

---

## Configuration Files

### DataSource Configuration

File: `backend/src/database/data-source.ts`

This file is used by TypeORM CLI for migration commands. It:
- Loads environment variables from `.env`
- Imports all entity files
- Points to the migrations directory
- Has `synchronize: false` (required for migrations)

### App Module Configuration

File: `backend/src/app.module.ts`

The main app uses the same database config but with:
- `synchronize: true` in development (auto-sync)
- `synchronize: false` in production (migrations only)

---

## Deployment Checklist

Before deploying to production:

1. [ ] Set `NODE_ENV=production`
2. [ ] Ensure database credentials are configured
3. [ ] Run `npm run migration:show` to verify pending migrations
4. [ ] Run `npm run migration:run`
5. [ ] Verify migration success in logs
6. [ ] Test application functionality

### CI/CD Integration

Add to your deployment pipeline:

```yaml
# Example GitHub Actions step
- name: Run database migrations
  run: |
    cd backend
    npm run migration:run
  env:
    DATABASE_HOST: ${{ secrets.DB_HOST }}
    DATABASE_PASSWORD: ${{ secrets.DB_PASSWORD }}
    # ... other env vars
```

---

## Troubleshooting

### "No changes in database schema"

This means your entities match the database. Either:
- The change was already applied via `synchronize`
- You need to drop tables first (dev only)

### Permission denied on ts-node

```bash
chmod +x node_modules/.bin/ts-node
```

### Migration fails with "relation already exists"

The InitialSchema migration uses `IF NOT EXISTS` clauses, so it's safe to run on existing databases. If you have custom migrations that fail:

```sql
-- Check if table exists before creating
CREATE TABLE IF NOT EXISTS "my_table" (...);
```

### Rolling back all migrations (dev only)

```bash
# Revert one by one
npm run migration:revert
npm run migration:revert
# ... repeat as needed

# Or drop everything and start fresh
npm run seed:fresh
```

---

## Best Practices

1. **Never edit executed migrations** - Create a new migration instead
2. **Test migrations locally** before deploying to production
3. **Backup database** before running migrations in production
4. **Keep migrations small** - One logical change per migration
5. **Use transactions** - TypeORM wraps migrations in transactions by default
6. **Write reversible migrations** - Always implement the `down()` method

---

## Related Documentation

- [CLAUDE.md](../CLAUDE.md) - Project overview and development commands
- [PRODUCTION_SETUP.md](PRODUCTION_SETUP.md) - Production deployment guide
- [PRODUCTION_CHECKLIST.md](PRODUCTION_CHECKLIST.md) - Pre-launch checklist
- [TypeORM Migrations Docs](https://typeorm.io/migrations)
