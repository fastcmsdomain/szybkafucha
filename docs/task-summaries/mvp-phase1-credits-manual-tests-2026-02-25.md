# MVP Phase 1: Flat-Fee Credits Model – Manual Test Plan

**Date**: 2026-02-25
**Developer**: Claude
**Scope**: Full credits system, payment flow, chat moderation, kick, auto-rating

---

## Prerequisites

1. Backend running: `cd backend && npm run start:dev`
2. Database seeded: `npm run seed:fresh`
3. Mobile app running: `flutter run`
4. Two test accounts: one client (szef), one contractor (pracownik)
5. Both accounts should have 0 credits initially

---

## Test 1: Credits Top-Up

### 1.1 Top-Up via Wallet Screen

**Steps (Client):**
1. Login as client → Profile → "Portfel"
2. Verify wallet shows "0,00 zł" balance
3. Tap "Doładuj konto"
4. Select 20 zł preset amount
5. Tap "Doładuj"
6. Complete Stripe payment (test card: `4242 4242 4242 4242`)
7. Confirm top-up succeeded

**Expected:**
- Balance updates to 20,00 zł
- Transaction list shows "Doładowanie konta" entry with +20,00 zł
- Profile screen wallet shortcut shows updated balance

**Steps (Contractor):**
- Repeat steps 1-7 for contractor account

### 1.2 API Verification

```bash
# Get balance
curl -X GET http://localhost:3000/api/v1/payments/credits/balance \
  -H "Authorization: Bearer {jwt_token}"
# Expected: { "credits": 20 }

# Get transactions
curl -X GET http://localhost:3000/api/v1/payments/credits/transactions \
  -H "Authorization: Bearer {jwt_token}"
# Expected: Array with topup transaction
```

---

## Test 2: Atomic Payment on Acceptance

### 2.1 Successful Acceptance (Both have ≥ 10 zł)

**Steps:**
1. Client creates a task (any category)
2. Contractor browses tasks → finds the task → taps "Zgłoś się"
3. Verify contractor apply dialog shows balance info and "10 zł przy akceptacji" warning
4. Contractor confirms application
5. Client opens task tracking → sees contractor application
6. Verify "10 zł" info banner: "Wejście jest darmowe. Płacisz 10 zł tylko gdy wybierzesz pomocnika."
7. Client taps "Akceptuj" on the application
8. Verify payment screen shows:
   - Current credits balance
   - "Opłata za pomocnika: 10,00 zł"
   - Balance after payment
9. Client confirms acceptance

**Expected:**
- Client balance decreases by 10 zł (e.g., 20 → 10)
- Contractor balance decreases by 10 zł (e.g., 20 → 10)
- Task status changes to CONFIRMED
- Both CreditTransaction records created (type: DEDUCTION)

### 2.2 Insufficient Balance – Client

**Steps:**
1. Ensure client has < 10 zł credits
2. Create task, wait for contractor application
3. Client taps "Akceptuj"

**Expected:**
- Dialog appears: "Niewystarczające środki"
- Shows "Potrzebujesz min. 10,00 zł" message
- "Doładuj portfel" button navigates to wallet screen
- Acceptance is NOT processed

### 2.3 Insufficient Balance – Contractor (Shown at Apply)

**Steps:**
1. Ensure contractor has < 10 zł credits
2. Contractor browses tasks → taps "Zgłoś się"

**Expected:**
- Apply dialog shows warning: "Niewystarczające środki. Doładuj konto przed aplikowaniem."
- "Doładuj" CTA button shown

---

## Test 3: Room Slots Display

### 3.1 Slots Badge on Task Cards

**Steps:**
1. Login as contractor
2. Browse available tasks
3. Check each task card in the list

**Expected:**
- Each task card shows a badge like "0/5", "1/5", etc.
- Badge color: primary when not full, gray when full ("Pełny")
- Badge shows people icon

### 3.2 Applications Count in Client View

**Steps:**
1. Login as client → open task tracking for a task with applications
2. Check the applications section header

**Expected:**
- Shows "Zgłoszenia (X/5)" where X is current application count

---

## Test 4: Kick from Room

### 4.1 Successful Kick

**Steps:**
1. Client opens task tracking with pending applications
2. On an application card, tap the "Wyrzuć" button (person_remove icon)
3. Confirm in the bottom sheet: "Czy na pewno chcesz usunąć [name] z pokoju?"
4. Tap "Tak, wyrzuć"

**Expected:**
- Application removed from list
- Contractor's application status becomes "kicked"
- Success snackbar: "Wykonawca usunięty z pokoju"
- Application count decreases

### 4.2 Kick Rate Limit

**Steps:**
1. Kick 4+ contractors from the same task within 5 minutes

**Expected (soft cap at 10, hard cap at 20):**
- First 10 kicks succeed normally
- After 10: warning message (but still allowed)
- After 20: 429 error, message: "Osiągnięto limit"

---

## Test 5: Chat Moderation

### 5.1 Phone Number Blocking

**Steps:**
1. Open task chat (client or contractor)
2. Try to send: "Zadzwoń do mnie 123456789"

**Expected:**
- Message NOT sent
- Error banner appears: "Udostępnianie numerów telefonu w czacie jest niedozwolone."

### 5.2 Email Blocking

**Steps:**
1. In task chat, try to send: "Mój email to jan@example.com"

**Expected:**
- Message NOT sent
- Error banner: "Udostępnianie adresów email w czacie jest niedozwolone."

### 5.3 URL Blocking

**Steps:**
1. In task chat, try to send: "Sprawdź https://example.com"

**Expected:**
- Message NOT sent
- Error banner: "Udostępnianie linków w czacie jest niedozwolone."

### 5.4 Company Name Flagging (Soft Warning)

**Steps:**
1. In task chat, send: "Jestem z firmy XYZ sp.z.o.o"

**Expected:**
- Message IS sent (not blocked)
- Message saved with `flagged: true` in database (admin can review)

---

## Test 6: 5-Minute First Message Timeout

### 6.1 Contractor Sends Within 5 Minutes

**Steps:**
1. Contractor applies for a task
2. Within 5 minutes, contractor sends first message in chat

**Expected:**
- Message sent successfully
- `firstMessageSentAt` recorded in database
- Subsequent messages have no timeout restriction

### 6.2 Contractor Exceeds 5 Minutes

**Steps:**
1. Contractor applies for a task
2. Wait > 5 minutes without sending any message
3. Try to send first message

**Expected:**
- Message NOT sent
- Error: "Minął czas na pierwszą wiadomość (5 min). Twoja aplikacja wygasła."

---

## Test 7: Cancellation Refunds

### 7.1 Client Cancels After Acceptance

**Steps:**
1. Complete acceptance flow (both parties pay 10 zł)
2. Client cancels the task (status: CONFIRMED or IN_PROGRESS)

**Expected:**
- Client (canceller) gets +2 zł refund (20% of 10)
- Contractor (injured) gets +14 zł refund (140% of 10)
- CreditTransaction records created (type: REFUND)
- Client's strikes incremented by 1

### 7.2 Contractor Cancels After Acceptance

**Steps:**
1. Complete acceptance flow
2. Contractor cancels the task

**Expected:**
- Contractor (canceller) gets +2 zł refund
- Client (injured) gets +14 zł refund
- Contractor's strikes incremented by 1

### 7.3 Three-Strike Auto-Ban

**Steps:**
1. Same user cancels 3 tasks total

**Expected:**
- After 3rd cancellation: user.status = SUSPENDED
- User receives notification about suspension
- User cannot perform further actions

---

## Test 8: Auto-7-Day Rating Completion

### 8.1 Stale PENDING_COMPLETE Tasks

**Steps (manual DB verification):**
1. Create a task, complete it to PENDING_COMPLETE status
2. Manually set `completedAt` to 8 days ago in DB
3. Run the scheduler: wait for 2:00 AM cron or trigger manually

**Expected:**
- Task auto-rated: both clientRated and contractorRated set to true
- Auto-rating records created (rating: 5, comment: 'Automatyczna ocena po 7 dniach')
- Task status changes to COMPLETED

---

## Test 9: Wallet Screens

### 9.1 Client Wallet

**Steps:**
1. Login as client → Profile → "Portfel" (or tap wallet shortcut)
2. Verify balance display (large primary text)
3. Verify "Doładuj konto" button works
4. Verify transaction history shows all credit/debit entries
5. Verify amount presets: 20, 50, 100 zł
6. Verify custom amount input (min 20 zł validation)

### 9.2 Contractor Wallet

**Steps:**
1. Login as contractor → Profile → "Portfel"
2. Verify same structure as client wallet
3. Verify info note: "10 zł zostanie pobrane gdy klient Cię wybierze"

### 9.3 Profile Wallet Shortcut

**Steps:**
1. Check both client and contractor profile screens
2. Verify wallet shortcut shows current balance
3. Verify balance color: green if ≥ 10 zł, warning/orange if < 10 zł
4. Verify tapping shortcut navigates to wallet screen

---

## Test 10: Payment Screen Updates

### 10.1 Fee Display

**Steps:**
1. Accept a contractor application → navigate to payment screen

**Expected:**
- Shows "Opłata za pomocnika: 10,00 zł" (NOT 17% commission)
- Shows current credits balance
- Shows "Saldo po płatności: XX,XX zł"
- Info banner: "Wejście do pokoju jest darmowe..."

### 10.2 Insufficient Balance on Payment Screen

**Steps:**
1. With < 10 zł balance, navigate to payment screen

**Expected:**
- Warning: "Niewystarczające środki" in red
- "Doładuj portfel" button present
- Confirm button disabled with "Niewystarczające środki" text

---

## Test Summary Checklist

| # | Test | Status |
|---|------|--------|
| 1.1 | Credits top-up (client) | ☐ |
| 1.1 | Credits top-up (contractor) | ☐ |
| 1.2 | API balance/transactions | ☐ |
| 2.1 | Atomic payment (success) | ☐ |
| 2.2 | Insufficient balance (client) | ☐ |
| 2.3 | Insufficient balance (contractor) | ☐ |
| 3.1 | Room slots badge | ☐ |
| 3.2 | Applications count | ☐ |
| 4.1 | Kick from room | ☐ |
| 4.2 | Kick rate limit | ☐ |
| 5.1 | Phone number blocking | ☐ |
| 5.2 | Email blocking | ☐ |
| 5.3 | URL blocking | ☐ |
| 5.4 | Company name flagging | ☐ |
| 6.1 | First message within 5 min | ☐ |
| 6.2 | First message after 5 min | ☐ |
| 7.1 | Client cancellation refund | ☐ |
| 7.2 | Contractor cancellation refund | ☐ |
| 7.3 | Three-strike auto-ban | ☐ |
| 8.1 | Auto-7d rating | ☐ |
| 9.1 | Client wallet screen | ☐ |
| 9.2 | Contractor wallet screen | ☐ |
| 9.3 | Profile wallet shortcut | ☐ |
| 10.1 | Payment screen fee display | ☐ |
| 10.2 | Payment screen insufficient balance | ☐ |
