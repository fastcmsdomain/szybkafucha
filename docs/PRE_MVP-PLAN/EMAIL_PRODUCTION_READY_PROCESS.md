# Email Production Ready Process

This document describes a practical process for taking Szybka Fucha email from development to production.

## Goal

The goal is to make transactional email:

- authenticated
- reliable
- brand-consistent
- observable
- safe to launch

## 1. Choose The Sending Setup

Pick one production email path:

### Option A. Transactional email provider

Examples:

- Resend
- SendGrid
- Mailgun
- Postmark
- Amazon SES

Recommended when:

- inbox placement matters
- you want dashboards and delivery logs
- you want easier SPF/DKIM setup

### Option B. Traditional SMTP mailbox hosting

Examples:

- your hosting provider mailbox
- cPanel mail
- custom VPS mail relay

Recommended only when:

- email volume is low
- you already manage the domain mailbox well
- you understand DNS and mail reputation risks

## 2. Verify The Sending Domain

For `szybkafucha.app`, production email should be authenticated with:

- SPF
- DKIM
- DMARC

Minimum process:

1. Add the provider’s SPF record
2. Add the provider’s DKIM records
3. Add a DMARC TXT record
4. Wait for DNS propagation
5. Verify records in the provider dashboard

Suggested starting DMARC policy:

```txt
v=DMARC1; p=none; rua=mailto:postmaster@szybkafucha.app
```

Later, after monitoring:

- move to `p=quarantine`
- eventually `p=reject`

## 3. Configure Backend Secrets

Set in production:

- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_SECURE`
- `SMTP_USER`
- `SMTP_PASSWORD`
- `SMTP_FROM`
- `SUPPORT_CONTACT_TO`

Recommended sender:

```txt
Szybka Fucha <noreply@szybkafucha.app>
```

Recommended support inbox:

```txt
kontakt@szybkafucha.app
```

## 4. Keep Transactional Emails Focused

To reduce spam risk:

- keep transactional emails short and clear
- avoid sales-heavy wording
- avoid too many links
- avoid large remote images
- use a consistent sender name
- send emails only after real user actions

For MVP, transactional email should cover:

- verification
- welcome
- password reset
- password changed
- phone changed
- KYC updates
- important task lifecycle updates
- support confirmation
- account deletion confirmation

## 5. Improve Deliverability

Before launch:

- test Gmail inbox placement
- test Outlook inbox placement
- test Apple Mail / iCloud inbox placement
- confirm DKIM passes
- confirm SPF passes
- confirm DMARC alignment passes

If emails still go to spam:

- switch to a transactional provider with better reputation
- reduce unnecessary links and HTML complexity
- add plain-text body versions
- warm up the domain slowly

## 6. Operational Rules

Use these rules in production:

- never hardcode real production credentials in code
- store SMTP secrets only in environment variables
- rotate passwords if exposed
- log send failures
- do not block critical flows if a non-essential email fails
- keep support emails monitored by a real human inbox

## 7. Recommended Release Order

Use this release order:

1. Enable SPF, DKIM, DMARC
2. Configure production SMTP secrets
3. Deploy backend
4. Run end-to-end smoke tests
5. Check inbox placement
6. Monitor failures for 24 to 72 hours
7. Only then announce public launch

## 8. Production Smoke Test

Run these tests after deploy:

1. Register with email and receive verification email
2. Verify email and receive welcome email
3. Trigger password reset and receive reset email
4. Change password and receive security email
5. Change phone and receive security email
6. Complete KYC milestones and receive KYC emails
7. Create and progress a task to verify task lifecycle emails
8. Send support message and verify:
   user confirmation email
   support inbox email
9. Delete account and verify goodbye email

## 9. Recommended Hosting Direction

For Szybka Fucha, the safest practical production approach is:

- use a dedicated transactional provider
- keep the branded sender on `szybkafucha.app`
- route support replies to `kontakt@szybkafucha.app`

This gives you:

- better inbox placement
- easier DNS setup
- delivery dashboards
- bounce monitoring
- lower risk than basic shared-hosting SMTP

## 10. Nice Next Steps

After MVP, consider:

- plain-text email bodies for all templates
- bounce and complaint handling
- unsubscribe handling for non-transactional emails
- email analytics dashboard
- localization support for EN / UA versions
