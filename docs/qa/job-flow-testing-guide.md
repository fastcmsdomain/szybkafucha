# Job Flow Testing Guide

This guide covers the complete task flow testing scenarios for QA and manual testing.

## Prerequisites

1. Backend running: `cd backend && npm run start:dev`
2. Mobile app running on simulator/device
3. Test accounts:
   - Client account (to post tasks)
   - Contractor account (to accept tasks)

## Task Status Flow

```
CREATED → ACCEPTED → CONFIRMED → IN_PROGRESS → PENDING_COMPLETE → COMPLETED
```

## Test Scenarios

### 1. Happy Path - Complete Flow

#### 1.1 Client Creates Task
**Steps:**
1. Login as client
2. Tap "Dodaj zlecenie" button
3. Select category (e.g., Sprzatanie)
4. Enter description (min 10 characters)
5. Add photos (optional)
6. Enter address or use current location
7. Set budget (minimum 35 PLN)
8. Choose schedule (now or later)
9. Tap "Znajdz pomocnika"

**Expected:**
- Task created with status `CREATED`
- Task appears in client's active tasks list
- Rainbow progress dots show at step 1 (Szukanie)

---

#### 1.2 Contractor Accepts Task
**Steps:**
1. Login as contractor
2. Go to available tasks (map or list view)
3. Find the newly created task
4. Tap on task to view details
5. Tap "Przyjmij zlecenie"

**Expected:**
- Task status changes to `ACCEPTED`
- Client receives notification "Pomocnik znaleziony"
- Client sees contractor profile card
- Contractor sees "Oczekuje na potwierdzenie" (disabled button)
- Both sides see progress at step 2

---

#### 1.3 Client Confirms Contractor
**Steps:**
1. As client, view active task
2. Review contractor profile
3. Tap "Zatwierdz"
4. Payment popup appears with:
   - "Gotowka" button
   - "Karta" button
5. Select payment method
6. Tap "Zatwierdz" in popup

**Expected:**
- Task status changes to `CONFIRMED`
- Contractor receives notification
- Contractor's "Rozpocznij" button becomes enabled
- Progress moves to step 3

---

#### 1.4 Contractor Starts Work
**Steps:**
1. As contractor, view active task
2. Tap "Rozpocznij"

**Expected:**
- Task status changes to `IN_PROGRESS`
- Client receives notification "Praca w toku"
- Both sides see progress at step 4 (W trakcie)
- Contractor's "Zakoncz zlecenie" is disabled
- Info message: "Klient musi potwierdzic zakonczenie"

---

#### 1.5 Client Confirms Completion
**Steps:**
1. As client, view active task
2. Tap "Potwierdz zakonczenie"

**Expected:**
- Task status changes to `PENDING_COMPLETE`
- Contractor receives notification
- Contractor's "Zakoncz zlecenie" button becomes enabled
- Info message changes to "Klient potwierdził zakończenie"

---

#### 1.6 Contractor Completes Task
**Steps:**
1. As contractor, view active task
2. Tap "Zakoncz zlecenie"
3. Complete completion screen:
   - Add photo proof (optional)
   - Add notes (optional)
4. Tap "Potwierdz zakonczenie"

**Expected:**
- Task status changes to `COMPLETED`
- Success dialog shows earnings
- "Ocen klienta" button available

---

#### 1.7 Both Parties Rate
**Steps:**
1. As contractor, tap "Ocen klienta"
2. Select star rating (1-5, required)
3. Add review text (optional)
4. Tap "Wyslij ocene"

5. As client, tap "Zlecenie zakonczone"
6. Select star rating (1-5, required)
7. Add review text (optional)
8. Set tip amount (optional)
9. Tap "Wyslij opinie"

**Expected:**
- Both ratings saved
- `clientRated` and `contractorRated` flags set to true
- Ratings appear on user profiles

---

### 2. Rejection Flow

#### 2.1 Client Rejects Contractor
**Steps:**
1. Contractor accepts task (status: ACCEPTED)
2. As client, tap "Odrzuc i szukaj innego"
3. Confirm rejection

**Expected:**
- Task status returns to `CREATED`
- Contractor is removed from task
- Task becomes available again
- New contractors are notified

---

### 3. Cancellation Flows

#### 3.1 Client Cancels Before Accept
**Steps:**
1. Create task (status: CREATED)
2. As client, tap "Anuluj zlecenie"
3. Confirm cancellation

**Expected:**
- Task status changes to `CANCELLED`
- Task removed from available tasks

---

#### 3.2 Contractor Releases Task
**Steps:**
1. Contractor accepts task (status: ACCEPTED)
2. As contractor, tap "Anuluj"
3. Confirm cancellation

**Expected:**
- Task status returns to `CREATED`
- Task becomes available again
- Client receives notification

---

#### 3.3 Client Cancels After Accept
**Steps:**
1. Contractor accepts task (status: ACCEPTED)
2. As client, tap "Anuluj zlecenie"
3. Confirm cancellation

**Expected:**
- Task status changes to `CANCELLED`
- Contractor receives notification
- Contractor redirected to home

---

### 4. Validation Tests

#### 4.1 Budget Minimum
**Steps:**
1. Create task with budget < 35 PLN

**Expected:**
- Validation error displayed
- Task not created

---

#### 4.2 Rating Required
**Steps:**
1. Complete task flow
2. As contractor, try to submit without rating

**Expected:**
- "Wyslij ocene" button disabled
- Cannot submit without selecting stars

---

### 5. Real-Time Updates

#### 5.1 Status Changes Without Refresh
**Steps:**
1. Open client and contractor apps side by side
2. Complete each status transition
3. Observe both screens

**Expected:**
- Status changes appear instantly on both screens
- No manual refresh needed
- Progress dots update automatically
- Contractor/client cards appear/update automatically

---

### 6. UI Verification

#### 6.1 Rainbow Progress Dots
**Verify on both Client and Contractor screens:**
- [ ] 5 colored dots (client) or 4 dots (contractor)
- [ ] Colors are rainbow gradient (red, orange, green, blue, purple)
- [ ] Completed steps show checkmark icon
- [ ] Current step has glow effect
- [ ] Connecting lines show gradient when completed

#### 6.2 Payment Popup
**Verify when client confirms contractor:**
- [ ] Bottom sheet appears
- [ ] "Gotowka" and "Karta" buttons side by side
- [ ] Selection highlight works
- [ ] "Zatwierdz" disabled until selection
- [ ] "Anuluj" closes popup

#### 6.3 Contractor Status Buttons
**Verify button states:**
- [ ] ACCEPTED: "Oczekuje na potwierdzenie" (disabled) + "Anuluj"
- [ ] CONFIRMED: "Rozpocznij" (enabled)
- [ ] IN_PROGRESS: "Zakoncz zlecenie" (disabled)
- [ ] PENDING_COMPLETE: "Zakoncz zlecenie" (enabled)

---

## API Endpoints Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/tasks` | POST | Create task |
| `/tasks/:id/accept` | PUT | Contractor accepts |
| `/tasks/:id/confirm-contractor` | PUT | Client confirms contractor |
| `/tasks/:id/reject-contractor` | PUT | Client rejects contractor |
| `/tasks/:id/start` | PUT | Contractor starts work |
| `/tasks/:id/confirm-completion` | PUT | Client confirms completion |
| `/tasks/:id/complete` | PUT | Contractor completes |
| `/tasks/:id/cancel` | PUT | Cancel task |
| `/tasks/:id/rate` | POST | Submit rating |
| `/tasks/:id/tip` | POST | Add tip |

---

## Known Issues

- None currently documented

---

## Test Environment

- Backend: http://localhost:3000
- Mobile: iOS Simulator / Android Emulator
- Database: PostgreSQL (docker-compose)
