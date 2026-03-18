# Email Pre-Prod Checklist

Use this checklist before enabling production email sending for Szybka Fucha.

## DNS And Domain

- [ ] Production sending domain is decided
- [ ] `SMTP_FROM` uses the same verified domain
- [ ] SPF record is added and validated
- [ ] DKIM record is added and validated
- [ ] DMARC record is added
- [ ] Reverse DNS / PTR is configured if required by the provider
- [ ] `noreply@...` mailbox or sender identity exists
- [ ] `SUPPORT_CONTACT_TO` points to a monitored inbox

## Infrastructure

- [ ] Production SMTP credentials are stored in the backend environment
- [ ] `SMTP_HOST` is correct
- [ ] `SMTP_PORT` is correct
- [ ] `SMTP_SECURE` is correct
- [ ] `SMTP_USER` is correct
- [ ] `SMTP_PASSWORD` is correct
- [ ] `SMTP_FROM` is correct
- [ ] Backend can connect to the SMTP server from production

## Product Flows

- [ ] Email verification sends successfully
- [ ] Welcome email sends after verified email signup
- [ ] Welcome email sends for first Google signup
- [ ] Welcome email sends for first Apple signup
- [ ] Password reset email sends successfully
- [ ] Password changed security email sends successfully
- [ ] Phone changed security email sends successfully
- [ ] Account deletion goodbye email sends successfully
- [ ] KYC emails send for document verified, selfie verified, complete, and failed
- [ ] Task lifecycle emails send for:
- [ ] application received
- [ ] application accepted
- [ ] task started
- [ ] completion confirmed
- [ ] task completed
- [ ] task cancelled
- [ ] Support form sends email to support inbox
- [ ] Support form sends confirmation email to the user

## Content And UX

- [ ] Subjects are readable and consistent
- [ ] Footer links work
- [ ] Facebook text link works
- [ ] All emails render correctly on mobile width
- [ ] OTP digits are readable in Gmail, Outlook, Apple Mail
- [ ] Welcome/goodbye/support emails look on-brand
- [ ] Plain-text bodies are planned or implemented

## Deliverability

- [ ] Test inbox placement with Gmail
- [ ] Test inbox placement with Outlook
- [ ] Test inbox placement with iCloud or another mailbox
- [ ] Verify emails are not failing DMARC/SPF/DKIM checks
- [ ] Check sender reputation with your provider dashboard
- [ ] Avoid bulk test sends from a fresh domain

## Monitoring

- [ ] SMTP/server logs are accessible
- [ ] Failed email sends are visible in logs
- [ ] Support inbox is monitored
- [ ] Bounce / reject handling is planned
- [ ] A process exists for rotating SMTP credentials

## Final Go-Live Gate

- [ ] Backend restarted with production email config
- [ ] Smoke test completed on production-like environment
- [ ] One real end-to-end test completed per critical flow
- [ ] Team knows which inbox receives support messages
- [ ] Team knows how to verify SPF/DKIM/DMARC after deployment
