# Security rules (RCO Developer Documents)

Canonical list of security rules for multi-tenant web application development. The security-compliance subagent evaluates code changes against these rules. Edit this file to add or change rules; then re-copy this repo’s `cursor/` config into projects that use it.

---

## Authentication & Authorization

- **Always fail secure, never fail open.** If there's any doubt about permissions or an error occurs during authorization checks, deny access completely rather than defaulting to allowing access.
- **Every data access must verify tenant isolation.** Before retrieving, modifying, or deleting any record, explicitly verify that the record belongs to the authenticated user's tenant. Never rely on implicit filtering.
- **Authorization checks are never optional.** Even if a function is "only called from authorized contexts," it must independently verify permissions. Calling context can change during refactoring.
- **Never remove security checks to fix bugs.** If an authorization check causes an error, fix the underlying issue—don't remove the check. Security is not negotiable for functionality.
- **Session data is advisory, not authoritative.** Always verify permissions against the database. Never trust client-provided data (cookies, tokens, headers) without server-side validation.

## Data Handling

- **Explicitly scope all database queries by tenant ID.** Every SELECT, UPDATE, and DELETE query must include a WHERE clause filtering by the authenticated user's tenant. Make this a mandatory part of query construction.
- **Validate tenant ownership before any JOIN operations.** When joining tables, ensure all tables in the query are filtered by tenant ID, not just the primary table.
- **Sanitize and validate all user inputs.** Use parameterized queries exclusively. Never concatenate user input directly into SQL statements, even if it seems safe.
- **Limit data exposure in API responses.** Only return fields the user is authorized to see. Don't fetch sensitive data and then filter it out—exclude it from queries entirely.

## Error Handling

- **Never expose internal system details in error messages.** Use generic error messages to users ("Access denied," "Resource not found") while logging detailed errors server-side for debugging.
- **Distinguish between "doesn't exist" and "no permission" carefully.** For security-sensitive resources, return the same error for both cases to prevent information disclosure through error messages.
- **Log security-relevant events comprehensively.** Failed authorization attempts, suspicious access patterns, and permission changes should all be logged with sufficient context for investigation.

## API Design

- **Default to deny.** New endpoints and features should require explicit permission grants rather than being accessible by default.
- **Use principle of least privilege.** Grant users and service accounts only the minimum permissions necessary to perform their function.
- **API endpoints must independently verify authorization.** Don't assume frontend restrictions prevent unauthorized API calls. Validate permissions server-side for every request.

## Code Patterns

- **Create reusable authorization middleware/decorators.** Centralize tenant filtering and permission checks rather than implementing them inconsistently across endpoints.
- **Use database-level constraints where possible.** Foreign keys, unique constraints, and row-level security provide defense in depth beyond application logic.
- **Separate authentication from authorization.** Knowing who the user is (authentication) is distinct from what they can do (authorization). Both must be verified.
- **Never disable security features in production.** Development shortcuts (disabled auth, mock users, debug modes) must never reach production environments.

## Testing & Validation

- **Test cross-tenant data isolation explicitly.** Automated tests should verify that User A from Tenant 1 cannot access User B's data from Tenant 2 under any circumstance.
- **Include negative test cases.** Test that unauthorized actions fail appropriately, not just that authorized actions succeed.
- **Review all data access patterns during code review.** Every pull request touching data access should have explicit verification that tenant isolation is maintained.

---

## Core Principle

When in doubt between functionality and security, choose security. A feature that doesn't work is a bug; a feature that leaks data across tenants is a catastrophic failure.
