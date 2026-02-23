# Post-MVP: Zmiana e-maila i numeru telefonu

## Kontekst MVP

W wersji MVP zmiana e-maila i numeru telefonu odbywa się ręcznie przez pomoc techniczną.
Użytkownicy widzą komunikat: **"Aby zmienić, napisz na kontakt@szybkafucha.app"**

---

## Flow MVP (ręczny — przez admina)

### Kiedy użytkownik napisze e-mail na kontakt@szybkafucha.app

**1. Weryfikacja tożsamości (admin)**
- Sprawdź, czy e-mail pochodzi z adresu powiązanego z kontem LUB poproś o potwierdzenie numeru telefonu (ostatnie 4 cyfry)
- Opcjonalnie: poproś o zdjęcie dokumentu tożsamości (dla zmiany numeru telefonu)

**2. Zmiana danych w panelu admina**
- Wejdź w **Admin Panel → Użytkownicy → wyszukaj po telefonie/emailu**
- Kliknij użytkownika → Edytuj
- Zmień pole `email` lub `phone`
- Zapisz

**3. Odpowiedź do użytkownika**
- Potwierdź zmianę e-mailem zwrotnym
- Poinformuj, że nowe dane logowania obowiązują natychmiast

> ⚠️ **Ważne**: Zmiana numeru telefonu dezaktywuje możliwość logowania starym numerem. Upewnij się, że nowy numer jest poprawny przed zapisaniem.

---

## Flow Post-MVP (zautomatyzowany — samodzielna zmiana)

### A. Zmiana e-maila

```
Użytkownik                    Backend                       Nowy e-mail
     |                           |                               |
     |-- [1] POST /users/me/     |                               |
     |   change-email            |                               |
     |   { newEmail }            |                               |
     |                           |-- [2] Wyślij OTP (6 cyfr) --> |
     |                           |   na newEmail                 |
     |                           |   (ważny 10 min)              |
     |<-- 200 "Kod wysłany" -----|                               |
     |                           |                               |
     |   [3] Użytkownik wpisuje  |                               |
     |   kod z nowego e-maila    |                               |
     |                           |                               |
     |-- [4] POST /users/me/     |                               |
     |   change-email/verify     |                               |
     |   { newEmail, otp }       |                               |
     |                           |-- [5] Zapisz nowy e-mail ---> |
     |                           |   emailVerified = true        |
     |<-- 200 "E-mail zmieniony" |                               |
```

**Endpointy do zbudowania:**
```
POST /users/me/change-email
  Body: { newEmail: string }
  Auth: JWT wymagany
  Rate limit: 3 próby / 60 min
  Odpowiedź: 200 { message: "Verification code sent to new email" }

POST /users/me/change-email/verify
  Body: { newEmail: string, otp: string }
  Auth: JWT wymagany
  Rate limit: 5 prób / 60 min
  Odpowiedź: 200 { message: "Email updated successfully" }
```

**Logika backendu:**
- Sprawdź, czy `newEmail` nie jest już zajęty przez innego użytkownika
- Przechowaj `pendingEmail` + `pendingEmailOtp` + `pendingEmailOtpExpiry` w tabeli `users`
- Po weryfikacji: `user.email = newEmail`, `user.emailVerified = true`, wyczyść pending fields

---

### B. Zmiana numeru telefonu

```
Użytkownik                    Backend                    Nowy numer SMS
     |                           |                               |
     |-- [1] POST /users/me/     |                               |
     |   change-phone            |                               |
     |   { newPhone }            |                               |
     |                           |-- [2] Wyślij SMS OTP -------> |
     |                           |   na newPhone                 |
     |                           |   (ważny 5 min)               |
     |<-- 200 "SMS wysłany" -----|                               |
     |                           |                               |
     |   [3] Użytkownik wpisuje  |                               |
     |   kod z SMS               |                               |
     |                           |                               |
     |-- [4] POST /users/me/     |                               |
     |   change-phone/verify     |                               |
     |   { newPhone, otp }       |                               |
     |                           |-- [5] Zapisz nowy numer ----> |
     |<-- 200 "Numer zmieniony"  |                               |
```

**Endpointy do zbudowania:**
```
POST /users/me/change-phone
  Body: { newPhone: string }   // format E.164, np. +48501234567
  Auth: JWT wymagany
  Rate limit: 3 próby / 60 min
  Odpowiedź: 200 { message: "SMS code sent to new phone number" }

POST /users/me/change-phone/verify
  Body: { newPhone: string, otp: string }
  Auth: JWT wymagany
  Rate limit: 5 prób / 60 min
  Odpowiedź: 200 { message: "Phone number updated successfully" }
```

**Logika backendu:**
- Sprawdź, czy `newPhone` nie jest już zajęty przez innego użytkownika
- Przechowaj `pendingPhone` + `pendingPhoneOtp` + `pendingPhoneOtpExpiry` w tabeli `users`
- Po weryfikacji: `user.phone = newPhone`, wyczyść pending fields
- ⚠️ Unieważnij wszystkie aktywne sesje JWT (force re-login z nowym numerem)

---

## Zmiany w bazie danych (migracja)

```sql
ALTER TABLE users ADD COLUMN pending_email VARCHAR(255);
ALTER TABLE users ADD COLUMN pending_email_otp VARCHAR(6);
ALTER TABLE users ADD COLUMN pending_email_otp_expiry TIMESTAMP;
ALTER TABLE users ADD COLUMN pending_phone VARCHAR(20);
ALTER TABLE users ADD COLUMN pending_phone_otp VARCHAR(6);
ALTER TABLE users ADD COLUMN pending_phone_otp_expiry TIMESTAMP;
```

---

## Zmiany w Flutter (mobile)

Zamiast zablokowanego pola z info-tekstem, dodać przycisk "Zmień" obok pola:

```
[📧 jan@example.com  🔒]  [Zmień →]
```

Przycisk "Zmień →" otwiera `ChangeEmailScreen` / `ChangePhoneScreen`:
1. Formularz z nowym adresem/numerem
2. Spinner + wysyłka kodu
3. Ekran OTP (identyczny jak przy rejestracji)
4. Po sukcesie: powrót do profilu, odświeżenie danych

---

## Szacowany nakład pracy post-MVP

| Zadanie | Czas |
|---------|------|
| Backend: endpointy change-email + change-phone | ~3h |
| Backend: migracja DB + pending fields | ~30 min |
| Flutter: ChangeEmailScreen + ChangePhoneScreen | ~2h |
| Flutter: integracja z OTP screen (reuse) | ~1h |
| Testy | ~1h |
| **Łącznie** | **~7-8h** |
