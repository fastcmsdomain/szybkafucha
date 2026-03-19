# Email Communication MVP

## Purpose

This document lists the recommended email communication use cases for Szybka Fucha, split into:

- must-have for MVP
- strong next-priority emails
- optional later emails
- current implementation status

## Must-Have For MVP

These are the minimum email flows that are worth having in production from day one.

### 1. Email verification

Why it matters:

- confirms that the email belongs to the user
- reduces fake accounts and typo-based signups
- supports secure password reset later

Status:

- implemented

### 2. Password reset

Why it matters:

- required for account recovery
- reduces support burden
- core part of email/password authentication

Status:

- implemented

### 3. Account deletion confirmation

Why it matters:

- confirms a sensitive action
- gives the user closure and trust
- helps if deletion was not expected and support is needed

Status:

- implemented

### 4. Support / contact email handling

Why it matters:

- gives users a reliable path to ask for help
- routes support messages to the team
- important for early-stage trust and operations

Status:

- implemented

### 5. Security change notifications

Recommended MVP minimum:

- password changed
- email changed

Why it matters:

- alerts users about high-risk account changes
- helps detect account takeover

Status:

- not implemented yet

## Strong Next-Priority Emails

These are not mandatory for launch, but they bring a lot of value quickly.

### Welcome email

Examples:

- first registration completed
- short onboarding message
- links to support and key next steps

Why it matters:

- improves trust
- confirms signup success
- helps onboarding

Status:

- not implemented yet

### KYC status updates

Examples:

- ID verified
- selfie verified
- verification rejected
- overall KYC completed

Why it matters:

- important for contractor trust
- reduces confusion during onboarding

Status:

- not implemented as email
- currently better represented through in-app status / notifications

### Important task lifecycle emails

Examples:

- offer accepted
- task assigned
- dispute opened or resolved

Why it matters:

- useful when push notifications are missed
- helps with reliability of critical marketplace events

Status:

- not implemented yet

## Optional Later Emails

These can wait until after MVP.

### Reminder emails

Examples:

- finish profile
- verify email
- complete KYC
- return to unfinished registration

### Ratings / review request

Examples:

- rate contractor after completed job
- rate client after completed job

### Reactivation / retention emails

Examples:

- we miss you
- come back and finish setup

### Marketing / product updates

Examples:

- newsletter
- launch updates
- city expansion announcements

## Recommended MVP Scope

If we keep the scope tight, the recommended MVP email set is:

1. Email verification
2. Password reset
3. Account deletion confirmation
4. Support / contact email handling
5. Password changed notification
6. Email changed notification

## Current Status Summary

Implemented:

- email verification
- password reset
- account deletion confirmation
- support / contact email forwarding
- welcome email for new Google, Apple, and verified email signups
- security email: password changed
- security email: phone changed
- KYC milestone emails
- important task lifecycle emails
- support confirmation email to the user

Missing but recommended for MVP:

- email changed notification

Nice next step after MVP:

- welcome email
- KYC decision emails
- key task / dispute emails

## Notes

- OTP codes should be fixed in local development only and random in production.
- Transactional emails should preserve Szybka Fucha branding and include basic legal/support footer links.
- Email delivery failures should not block critical account actions unless the action explicitly depends on successful delivery.
