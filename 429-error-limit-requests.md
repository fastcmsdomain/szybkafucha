# 429 Too Many Requests – What Happened and How We Fixed It

## Issue
Users sometimes hit `ApiException: ThrottlerException: Too Many Requests (status: 429)`. Our NestJS backend was rate‑limiting all clients to **10 requests per 60 seconds** (global ThrottlerGuard defaults).

## Root cause
`ThrottlerModule.forRoot` in `backend/src/app.module.ts` used static limits:
- `limit: 10`
- `ttl: 60000` ms (60 s)

During bursts (e.g., rapid UI retries or background polling) the global cap was exceeded, producing 429s.

## Change made
- Switched throttling config to `ThrottlerModule.forRootAsync` with env-driven values.
- New environment variables:
  - `THROTTLE_LIMIT` – max requests per window (default `10` if unset).
  - `THROTTLE_TTL_MS` – window length in milliseconds (default `60000` if unset).

This lets us raise/lower limits per environment without code changes.

## How to adjust limits
1) Edit `.env` (or your deployment env vars) and set desired values, e.g.:
   ```
   THROTTLE_LIMIT=60
   THROTTLE_TTL_MS=60000
   ```
2) Restart the backend service so the new limits load.

## Recommendations
- Pick limits that balance user experience and abuse protection; start with `60 req / 60s` for mobile clients.
- Monitor 429 rates and CPU/db load after change; tune down if you observe stress or abuse.
- For finer control later, consider route‑specific throttling or per‑user keys instead of a single global bucket.
