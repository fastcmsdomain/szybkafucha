# Szybka Fucha MVP action plan

Context: Backend/admin/landing are largely built, but MVP is blocked by missing production readiness, test coverage, notifications, and a usable mobile client. Below is a minimal path to an end-to-end usable app.

## Immediate (this week)
- Lock hygiene: enable branch protection + GitHub Actions for lint/test on backend and admin (tasks 1.7, 1.8). Fail the build if migrations are missing or tests fail.
- Database & config: stop relying on TypeORM sync in non-dev; finish migrations (task 2.9) and load .env with real Stripe/Onfido keys for staging. Add secrets management instructions.
- Auth/User gaps: implement refresh/invalidate logout (3.9), add avatar upload to S3/CloudStorage (4.4). Ship auth unit + e2e tests (3.11, 3.12) and user tests (4.10).
- Matching & payments: implement scoring algorithm + notification queue (6.3, 6.4) and add payment-flow tests (7.12). Verify escrow → capture → refund paths in Stripe test mode.
- Realtime & chat: add reconnection/message queue handling (8.7) and write realtime/chat tests (8.8, 9.5).
- KYC: obtain Onfido keys (10.1), add end-to-end KYC tests (10.9).

## Near term (next 1-2 weeks)
- Push notifications: stand up Firebase project; implement device token registration and templates (11.1–11.5) with coverage (11.6). Wire notifications into task, chat, and payment events.
- Admin robustness: add tests for admin endpoints (12.7); ensure dispute resolution paths are covered.
- Integration tests: cover full task lifecycle with payments, chat, realtime (19.1–19.4). Add load test for 100 concurrent users (19.6).

## Mobile (start now, parallel)
- Unblock Flutter: install SDK and create the project (1.2, 13.0). Set design system per PRD (13.2), API client + auth interceptor (13.3), storage, navigation, localization (13.4–13.7).
- Ship core flows only: auth (14.x), task post/accept, tracking map, chat, payment sheet, rating (15.x, 16.x, 17.x). Defer non-essential screens until after MVP.
- Push + realtime: integrate Socket.io client (17.1–17.4) and FCM handling (17.5) aligned with backend events.

## Launch readiness
- Environments: create staging/prod stacks (21.1–21.4) with HTTPS, monitoring (Sentry/CloudWatch), and auto-scaling. Add smoke tests (21.7).
- Store prep: icons/splash, Polish store copy, screenshots (20.1–20.4); TestFlight/Play beta submissions (20.5–20.6).
- Soft launch: onboard initial contractors, invite waitlist (22.x); instrument feedback and triage critical bugs quickly.
