# AUTHORITATIVE – Database Migrations (Platform vs App)

This is the **source of truth** for database migrations on the Beacon platform: idempotent SQL rules, two-step create-then-deploy, platform vs app migrations (app schema + platform schema), and pre-deploy validation.

**Full doc:** [DATABASE_MIGRATIONS.mdc](DATABASE_MIGRATIONS.mdc) (Cursor-friendly).

**Derived from:** Beacon docs/05_Database_Migrations.md, MIGRATION_SQL_RULES.md, backend/docs/MIGRATE_PERMISSIONS.md, backend/prisma (schema.prisma, platform/schema.prisma, migrations, platform/migrations), scripts (create-migration.sh, validate-migration-sql.sh, migrate.sh, pre-deploy-check.sh), backend/scripts/start.sh (app + platform migrate deploy).
