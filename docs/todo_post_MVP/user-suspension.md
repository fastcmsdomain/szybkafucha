# User suspension – Post MVP

## Status
Auto-suspension **disabled** for MVP Phase 1. Strikes are still recorded; only the status update to `SUSPENDED` is skipped.

## Description
User suspension blocks access for users who cancel tasks after the matching fee was paid (CONFIRMED/IN_PROGRESS). Two mechanisms:

1. **Automatic (3 strikes)**  
   Each such cancellation increments `user.strikes`. After 3 strikes the user is set to `status = SUSPENDED`. Applies to both **client** and **contractor** as canceller.

2. **Manual (admin)**  
   Admin can set a user to `SUSPENDED` via `PUT /admin/users/:id/status` (allowed from PENDING or ACTIVE). This remains available; only the automatic 3-strike suspension is disabled for MVP.

## Where it is disabled
**File:** `backend/src/payments/credits.service.ts`  
**Method:** `processCancellationRefund()`

The block that checks `canceller.strikes >= 3` and updates `status` to `'suspended'` is commented out. Strikes are still incremented above in the same method.

## How to re-enable (post-MVP)
1. In `backend/src/payments/credits.service.ts`, in `processCancellationRefund()`:
   - Remove the “MVP Phase 1: Auto-suspension disabled” comment.
   - Uncomment the block that loads the canceller, checks `canceller.strikes >= 3`, and updates `User` status to `'suspended'` (and the `this.logger.warn` call).
2. No changes needed for:
   - JWT strategy and auth service (they already reject `SUSPENDED` users).
   - Admin status transitions (admin suspend is already allowed).

## Related code
- Strike increment: `credits.service.ts` – `processCancellationRefund()` (strikes +1 for canceller).
- User entity: `backend/src/users/entities/user.entity.ts` – `UserStatus.SUSPENDED`, `strikes` column.
- Enforcement: `backend/src/auth/strategies/jwt.strategy.ts` and `backend/src/auth/auth.service.ts` – reject when `user.status === UserStatus.SUSPENDED`.
- Admin transitions: `backend/src/admin/admin.service.ts` – `allowedTransitions` (ACTIVE → SUSPENDED, etc.).

## Priority
**Medium** – re-enable when ready to enforce cancellation policy (e.g. after MVP feedback).
