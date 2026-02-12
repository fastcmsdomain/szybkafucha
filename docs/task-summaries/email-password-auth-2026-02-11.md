# Implementacja: Logowanie i rejestracja przez email + hasło

**Data**: 2026-02-11
**Autor**: Claude
**Status**: Ukończone

---

## Spis treści

1. [Przegląd](#przegląd)
2. [Architektura i przechowywanie danych](#architektura-i-przechowywanie-danych)
3. [Endpointy API](#endpointy-api)
4. [Bezpieczeństwo](#bezpieczeństwo)
5. [Ekrany mobilne (Flutter)](#ekrany-mobilne-flutter)
6. [Testowanie manualne](#testowanie-manualne)
7. [Testy jednostkowe](#testy-jednostkowe)
8. [Zmienione pliki](#zmienione-pliki)
9. [Konfiguracja środowiska](#konfiguracja-środowiska)

---

## Przegląd

Dodano **email + hasło** jako 4. metodę logowania/rejestracji (obok Phone/OTP, Google OAuth, Apple Sign-In). Implementacja obejmuje:

- Rejestrację z emailem, hasłem i wyborem roli (klient/wykonawca)
- Logowanie z emailem i hasłem
- Weryfikację adresu email kodem OTP (6 cyfr)
- Resetowanie hasła przez OTP wysyłany na email
- Blokadę konta po 5 nieudanych próbach logowania (15 min cooldown)
- Rate limiting na wszystkich endpointach

---

## Architektura i przechowywanie danych

### Gdzie hasła są przechowywane?

Hasła są przechowywane w tabeli `users` w bazie PostgreSQL:

| Kolumna | Typ | Opis |
|---------|-----|------|
| `passwordHash` | VARCHAR(255), nullable | Hash hasła (bcrypt, cost factor 12). Oznaczone `select: false` - **nigdy nie jest zwracane w standardowych zapytaniach** |
| `passwordUpdatedAt` | TIMESTAMP, nullable | Data ostatniej zmiany hasła |
| `emailVerified` | BOOLEAN, default: false | Czy email został zweryfikowany kodem OTP |
| `failedLoginAttempts` | INT, default: 0 | Licznik nieudanych prób logowania |
| `lockedUntil` | TIMESTAMP, nullable | Do kiedy konto jest zablokowane |

**Plik**: `backend/src/users/entities/user.entity.ts`

```typescript
// Hasło NIGDY nie jest zwracane w domyślnych zapytaniach
@Column({ type: 'varchar', length: 255, nullable: true, select: false })
passwordHash: string | null;
```

### Jak hasło jest hashowane?

- Algorytm: **bcrypt** z kosztem (salt rounds) = **12**
- Salt jest automatycznie generowany i osadzony w hashu
- Format: `$2b$12$...` (standard bcrypt)
- Porównanie: `bcrypt.compare()` (timing-safe, odporne na timing attacks)

```typescript
// Hashowanie przy rejestracji
const hashedPassword = await bcrypt.hash(password, 12);

// Porównanie przy logowaniu
const isValid = await bcrypt.compare(password, user.passwordHash);
```

### Gdzie kody OTP są przechowywane?

Kody OTP są przechowywane w **Redis** (cache) z automatycznym wygaśnięciem (TTL = 5 minut):

| Klucz Redis | Przeznaczenie | TTL |
|-------------|---------------|-----|
| `email-verify:{email}` | Weryfikacja adresu email | 5 min |
| `password-reset:{email}` | Reset hasła | 5 min |

- Kody są **jednorazowe** - usuwane z Redis po poprawnym użyciu
- W trybie deweloperskim kod zawsze = `123456`
- W produkcji: losowy 6-cyfrowy kod

### Jak działa wysyłanie emaili?

**Plik**: `backend/src/auth/email.service.ts`

| Tryb | Zachowanie |
|------|-----------|
| **Development** (`NODE_ENV !== 'production'`) | Kod OTP logowany w konsoli: `[DEV] Email OTP for jan@example.com: 123456` |
| **Production** | Email wysyłany przez SMTP (nodemailer) z szablonem HTML |

---

## Endpointy API

Base URL: `http://localhost:3000/api/v1`

### POST `/auth/email/register`

Rejestracja nowego konta z emailem i hasłem.

**Rate limit**: 3 zapytania / 60 sekund

**Body:**
```json
{
  "email": "jan@example.com",
  "password": "Haslo123!",
  "name": "Jan Kowalski",       // opcjonalne
  "userType": "client"           // "client" lub "contractor"
}
```

**Odpowiedź (201):**
```json
{
  "accessToken": "eyJhbG...",
  "user": { "id": "uuid", "email": "jan@example.com", "emailVerified": false, ... },
  "isNewUser": true
}
```

**Błędy:**
- `409 Conflict` - Email już istnieje
- `400 Bad Request` - Nieprawidłowe dane (email, hasło nie spełnia wymagań)

---

### POST `/auth/email/login`

Logowanie z emailem i hasłem.

**Rate limit**: 5 zapytań / 60 sekund

**Body:**
```json
{
  "email": "jan@example.com",
  "password": "Haslo123!"
}
```

**Odpowiedź (200):**
```json
{
  "accessToken": "eyJhbG...",
  "user": { "id": "uuid", "email": "jan@example.com", ... },
  "isNewUser": false
}
```

**Błędy:**
- `401 Unauthorized` - Nieprawidłowy email lub hasło
- `423 Locked` - Konto zablokowane (za dużo nieudanych prób)

---

### POST `/auth/email/verify`

Weryfikacja adresu email kodem OTP.

**Rate limit**: 5 zapytań / 60 sekund

**Body:**
```json
{
  "email": "jan@example.com",
  "code": "123456"
}
```

**Odpowiedź (200):**
```json
{
  "message": "Email zweryfikowany pomyślnie"
}
```

---

### POST `/auth/email/resend-verification`

Ponowne wysłanie kodu weryfikacyjnego.

**Rate limit**: 3 zapytania / 60 sekund

**Body:**
```json
{
  "email": "jan@example.com"
}
```

---

### POST `/auth/email/request-password-reset`

Żądanie resetu hasła. **Zawsze zwraca tę samą odpowiedź** (ochrona przed enumeracją kont).

**Rate limit**: 3 zapytania / 60 sekund

**Body:**
```json
{
  "email": "jan@example.com"
}
```

**Odpowiedź (200):**
```json
{
  "message": "Jeśli konto istnieje, wysłaliśmy kod na podany adres email"
}
```

---

### POST `/auth/email/reset-password`

Reset hasła z kodem OTP i nowym hasłem.

**Rate limit**: 3 zapytań / 60 sekund

**Body:**
```json
{
  "email": "jan@example.com",
  "code": "123456",
  "newPassword": "NoweHaslo456!"
}
```

**Odpowiedź (200):**
```json
{
  "message": "Hasło zostało zmienione"
}
```

---

## Bezpieczeństwo

### Wymagania dotyczące hasła

Hasło musi spełniać **wszystkie** poniższe kryteria:

- Minimum 8 znaków
- Co najmniej 1 wielka litera (A-Z)
- Co najmniej 1 mała litera (a-z)
- Co najmniej 1 cyfra (0-9)
- Co najmniej 1 znak specjalny (@$!%*?&#)

Regex walidacji: `(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&#])`

### Blokada konta (Account Lockout)

| Parametr | Wartość |
|----------|---------|
| Próg blokady | 5 nieudanych prób logowania |
| Czas blokady | 15 minut |
| Reset licznika | Po udanym logowaniu |
| Kod HTTP przy blokadzie | 423 Locked |

### Ochrona przed enumeracją kont

Endpoint `/auth/email/request-password-reset` **zawsze** zwraca tę samą odpowiedź, niezależnie od tego czy email istnieje w bazie. Atakujący nie może ustalić, które adresy email mają konta.

### Rate limiting

Wszystkie endpointy mają ograniczenia liczby zapytań (Throttle):

| Endpoint | Limit |
|----------|-------|
| `/auth/email/register` | 3 / 60s |
| `/auth/email/login` | 5 / 60s |
| `/auth/email/verify` | 5 / 60s |
| `/auth/email/resend-verification` | 3 / 60s |
| `/auth/email/request-password-reset` | 3 / 60s |
| `/auth/email/reset-password` | 3 / 60s |

---

## Ekrany mobilne (Flutter)

### 1. Ekran logowania (`email_login_screen.dart`)

- Pole email + pole hasło (z przyciskiem pokaż/ukryj)
- Przycisk "Zaloguj się"
- Link "Zapomniałeś hasła?" → ekran resetu
- Link "Nie masz konta? Zarejestruj się" → ekran rejestracji
- Obsługa błędów: 401 (złe dane), 423 (konto zablokowane), brak sieci

### 2. Ekran rejestracji (`email_register_screen.dart`)

- Pola: imię (opcjonalne), email, hasło, potwierdzenie hasła
- Wskaźnik siły hasła (pasek: Słabe/Średnie/Dobre/Silne)
- Lista wymagań hasła z checkboxami (real-time)
- Wybór roli (klient/wykonawca) - `UserTypeSelector`
- Po rejestracji → automatyczne przejście do weryfikacji email

### 3. Ekran weryfikacji email (`email_verification_screen.dart`)

- 6 pól na kod OTP z auto-przejściem między polami
- Auto-submit po wpisaniu 6. cyfry
- Przycisk "Wyślij kod ponownie" z odliczaniem 60s
- Link "Zweryfikuj później" (opcjonalnie pomiń)

### 4. Ekran resetu hasła (`forgot_password_screen.dart`)

Dwuetapowy proces:

**Krok 1**: Podaj email → "Wyślij kod resetujący"
**Krok 2**: Podaj kod OTP + nowe hasło + potwierdzenie → "Zmień hasło"

### 5. Ekran powitalny (`welcome_screen.dart`)

Dodano przycisk "Kontynuuj z e-mailem" po przycisku logowania telefonem:

```
[Kontynuuj z Google]
[Kontynuuj z Apple]
─── lub ───
[Kontynuuj z numerem telefonu]
[Kontynuuj z e-mailem]        ← NOWY
```

---

## Testowanie manualne

### Wymagania

1. Backend uruchomiony: `cd backend && npm run start:dev`
2. PostgreSQL + Redis uruchomione: `docker-compose up -d postgres redis`
3. Flutter app uruchomiona: `cd mobile && flutter run`

### Scenariusz 1: Rejestracja nowego konta

1. Otwórz aplikację → ekran powitalny
2. Kliknij **"Kontynuuj z e-mailem"**
3. Na ekranie logowania kliknij **"Nie masz konta? Zarejestruj się"**
4. Wypełnij formularz:
   - Imię: `Test User` (opcjonalne)
   - Email: `test@example.com`
   - Hasło: `Haslo123!` (obserwuj wskaźnik siły)
   - Potwierdź hasło: `Haslo123!`
   - Rola: Klient
5. Kliknij **"Zarejestruj się"**
6. **Oczekiwany wynik**: Przejście do ekranu weryfikacji email
7. Sprawdź konsolę backendu - szukaj logów:
   ```
   [DEV] Email OTP for test@example.com: 123456
   ```
8. Wpisz kod `123456` na ekranie weryfikacji
9. **Oczekiwany wynik**: SnackBar "Email zweryfikowany pomyślnie!" i powrót

### Scenariusz 2: Logowanie

1. Ekran powitalny → **"Kontynuuj z e-mailem"**
2. Wpisz email: `test@example.com` i hasło: `Haslo123!`
3. Kliknij **"Zaloguj się"**
4. **Oczekiwany wynik**: Automatyczne przekierowanie do ekranu głównego (klient lub wykonawca)

### Scenariusz 3: Błędne hasło i blokada konta

1. Spróbuj zalogować się z **błędnym hasłem** 5 razy
2. Po 5. próbie: **Oczekiwany wynik**: Komunikat "Konto tymczasowo zablokowane"
3. Poczekaj 15 minut (lub zresetuj w bazie danych)
4. Spróbuj ponownie z prawidłowym hasłem
5. **Oczekiwany wynik**: Logowanie powiedzie się

**Ręczny reset blokady (SQL):**
```sql
UPDATE users
SET "failedLoginAttempts" = 0, "lockedUntil" = NULL
WHERE email = 'test@example.com';
```

### Scenariusz 4: Reset hasła

1. Ekran logowania → **"Zapomniałeś hasła?"**
2. Wpisz email: `test@example.com`
3. Kliknij **"Wyślij kod resetujący"**
4. Sprawdź konsolę backendu - szukaj: `[DEV] Email OTP for test@example.com: 123456`
5. Wpisz kod `123456`
6. Wpisz nowe hasło: `NoweHaslo456!` + potwierdzenie
7. Kliknij **"Zmień hasło"**
8. **Oczekiwany wynik**: SnackBar "Hasło zostało zmienione" i przejście do logowania
9. Zaloguj się nowym hasłem
10. **Oczekiwany wynik**: Logowanie powiedzie się

### Scenariusz 5: Duplikat emaila

1. Spróbuj zarejestrować się ponownie z `test@example.com`
2. **Oczekiwany wynik**: Komunikat "Konto z tym adresem email już istnieje"

### Scenariusz 6: Walidacja hasła

1. Na ekranie rejestracji wpisz słabe hasła i sprawdź:
   - `abc` → "Hasło musi mieć minimum 8 znaków"
   - `abcdefgh` → Brak wielkiej litery, cyfry, znaku specjalnego
   - `Abcdefgh1!` → Wszystkie wymagania spełnione (zielone checkboxy)

### Testowanie API przez curl

```bash
# Rejestracja
curl -X POST http://localhost:3000/api/v1/auth/email/register \
  -H "Content-Type: application/json" \
  -d '{"email":"curl@test.com","password":"Haslo123!","userType":"client"}'

# Logowanie
curl -X POST http://localhost:3000/api/v1/auth/email/login \
  -H "Content-Type: application/json" \
  -d '{"email":"curl@test.com","password":"Haslo123!"}'

# Weryfikacja email (kod z konsoli)
curl -X POST http://localhost:3000/api/v1/auth/email/verify \
  -H "Content-Type: application/json" \
  -d '{"email":"curl@test.com","code":"123456"}'

# Reset hasła - żądanie
curl -X POST http://localhost:3000/api/v1/auth/email/request-password-reset \
  -H "Content-Type: application/json" \
  -d '{"email":"curl@test.com"}'

# Reset hasła - zmiana (kod z konsoli)
curl -X POST http://localhost:3000/api/v1/auth/email/reset-password \
  -H "Content-Type: application/json" \
  -d '{"email":"curl@test.com","code":"123456","newPassword":"NoweHaslo456!"}'
```

### Weryfikacja danych w bazie danych

Połącz się z pgAdmin (`http://localhost:5050`) lub psql:

```sql
-- Sprawdź użytkownika
SELECT id, email, "emailVerified", "failedLoginAttempts", "lockedUntil", "passwordUpdatedAt"
FROM users
WHERE email = 'test@example.com';

-- Sprawdź czy passwordHash jest ustawiony (select: false normalnie ukrywa to pole)
SELECT id, email, "passwordHash" IS NOT NULL as has_password
FROM users
WHERE email = 'test@example.com';

-- NIE ROBIMY: SELECT passwordHash - nie wyświetlaj hashy w logach!
```

---

## Testy jednostkowe

### Uruchomienie testów

```bash
cd backend && npm test
```

### Wynik: 315 testów, 14 zestawów, wszystkie przechodzą

### Testy email auth (17 testów)

**registerWithEmail** (4 testy):
- Rejestracja nowego użytkownika z hashowanym hasłem
- Rzucenie ConflictException gdy email już istnieje
- Wysłanie OTP weryfikacyjnego po rejestracji
- Utworzenie konta z typem "contractor" gdy podano userType

**loginWithEmail** (5 testów):
- Zwrócenie tokenu dla prawidłowych danych
- Rzucenie UnauthorizedException dla złego hasła
- Rzucenie UnauthorizedException dla nieistniejącego użytkownika
- Rzucenie HttpException (423) dla zablokowanego konta
- Rzucenie UnauthorizedException dla zablokowanego/zawieszonego użytkownika

**verifyEmailOtp** (3 testy):
- Weryfikacja email z prawidłowym kodem
- Rzucenie BadRequestException dla wygasłego kodu
- Rzucenie BadRequestException dla złego kodu

**requestPasswordReset** (2 testy):
- Wysłanie OTP resetu gdy użytkownik istnieje
- Ta sama odpowiedź gdy użytkownik nie istnieje (anty-enumeracja)

**resetPassword** (3 testy):
- Reset hasła z prawidłowym OTP
- Rzucenie BadRequestException dla nieprawidłowego OTP
- Rzucenie BadRequestException dla wygasłego OTP

### Flutter analyze

```bash
flutter analyze
```

Wynik: **0 błędów** w nowych plikach email auth (tylko pre-istniejące info/warningi w innych plikach).

---

## Zmienione pliki

### Backend - zmodyfikowane:
| Plik | Zmiana |
|------|--------|
| `backend/package.json` | Dodano bcrypt, @types/bcrypt, nodemailer, @types/nodemailer |
| `backend/src/users/entities/user.entity.ts` | Dodano 5 nowych pól (passwordHash, emailVerified, lockout) |
| `backend/src/users/users.service.ts` | Dodano 5 metod (findByEmailWithPassword, lockout, etc.) |
| `backend/src/auth/auth.service.ts` | Dodano 6 metod email auth + stałe bezpieczeństwa |
| `backend/src/auth/auth.controller.ts` | Dodano 6 endpointów z rate limitingiem |
| `backend/src/auth/auth.module.ts` | Dodano EmailService do providers |
| `backend/src/auth/auth.service.spec.ts` | Dodano 17 nowych testów |

### Backend - nowe:
| Plik | Opis |
|------|------|
| `backend/src/auth/email.service.ts` | Serwis wysyłania emaili (nodemailer / console log) |
| `backend/src/auth/dto/register-email.dto.ts` | DTO rejestracji |
| `backend/src/auth/dto/login-email.dto.ts` | DTO logowania |
| `backend/src/auth/dto/verify-email.dto.ts` | DTO weryfikacji email |
| `backend/src/auth/dto/request-password-reset.dto.ts` | DTO żądania resetu |
| `backend/src/auth/dto/reset-password.dto.ts` | DTO resetu hasła |

### Mobile - zmodyfikowane:
| Plik | Zmiana |
|------|--------|
| `mobile/lib/core/providers/auth_provider.dart` | Dodano 6 metod email auth |
| `mobile/lib/features/auth/widgets/social_login_button.dart` | Dodano typ `email` |
| `mobile/lib/core/router/routes.dart` | Dodano 4 nowe trasy |
| `mobile/lib/core/router/app_router.dart` | Dodano GoRoute dla 4 ekranów + guard |
| `mobile/lib/features/auth/auth.dart` | Dodano eksporty 4 nowych ekranów |
| `mobile/lib/features/auth/screens/welcome_screen.dart` | Dodano przycisk email |

### Mobile - nowe:
| Plik | Opis |
|------|------|
| `mobile/lib/features/auth/screens/email_login_screen.dart` | Ekran logowania |
| `mobile/lib/features/auth/screens/email_register_screen.dart` | Ekran rejestracji |
| `mobile/lib/features/auth/screens/email_verification_screen.dart` | Ekran weryfikacji OTP |
| `mobile/lib/features/auth/screens/forgot_password_screen.dart` | Ekran resetu hasła |

---

## Konfiguracja środowiska

### Zmienne środowiskowe (produkcja)

Dodaj do `backend/.env`:

```bash
# SMTP - wymagane w produkcji
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=noreply@szybkafucha.pl
SMTP_PASSWORD=your_smtp_app_password
SMTP_FROM=Szybka Fucha <noreply@szybkafucha.pl>
```

### Tryb deweloperski

W trybie deweloperskim (`NODE_ENV=development`):
- Emaile **nie są wysyłane** - kody OTP logowane w konsoli
- Kod OTP zawsze = `123456` (ten sam pattern co SMS OTP)
- Nie wymaga konfiguracji SMTP

---

## Diagram przepływu

```
┌─────────────┐     ┌──────────────┐     ┌──────────────┐
│  Welcome     │────>│ Email Login  │────>│  Home Screen │
│  Screen      │     │  Screen      │     │  (redirect)  │
└──────┬───────┘     └──────┬───────┘     └──────────────┘
       │                    │
       │                    ├── "Nie masz konta?" ──> Email Register ──> Email Verify
       │                    │
       │                    └── "Zapomniałeś hasła?" ──> Forgot Password
       │
       ├── Google OAuth
       ├── Apple Sign-In
       └── Phone/OTP
```

```
Rejestracja:   Register ──> JWT token ──> Verify Email (OTP) ──> emailVerified=true
Logowanie:     Login ──> bcrypt.compare ──> JWT token ──> Home
Reset hasła:   Request OTP ──> Enter OTP + new password ──> bcrypt.hash ──> Login
Blokada:       5x wrong password ──> lockedUntil = now+15min ──> HTTP 423
```
