# Push Notifications - Konfiguracja Post-MVP

## Przegląd

Ten dokument opisuje kroki potrzebne do uruchomienia push notifications na prawdziwych urządzeniach (iPhone i Android Samsung).

**Status:** Odłożone do fazy post-MVP
**Priorytet:** Wysoki (krytyczne dla UX)

---

## Android (Samsung i inne)

### Co potrzebujesz:
- **Konto Google** (darmowe)
- **Firebase projekt** (już skonfigurowany ✅)
- **Telefon Android** z włączonym trybem deweloperskim

### Kroki konfiguracji:

#### 1. Włącz tryb deweloperski na telefonie Samsung
```
Ustawienia → Informacje o telefonie → Numer kompilacji (kliknij 7 razy)
→ Wróć do Ustawień → Opcje deweloperskie → Włącz debugowanie USB
```

#### 2. Podłącz telefon do komputera
```bash
# Sprawdź czy urządzenie jest widoczne
adb devices

# Powinieneś zobaczyć coś takiego:
# List of devices attached
# XXXXXXXXXX    device
```

#### 3. Uruchom aplikację na telefonie
```bash
cd mobile
flutter run -d <device_id>

# lub jeśli masz tylko jedno urządzenie:
flutter run
```

#### 4. Firebase Cloud Messaging - Android
**Już skonfigurowane!** Plik `google-services.json` jest w projekcie.

Android **NIE wymaga** dodatkowych kluczy ani certyfikatów - FCM działa od razu po zainstalowaniu aplikacji na prawdziwym urządzeniu.

#### 5. Testowanie
Po uruchomieniu aplikacji na Androidzie:
1. Zaloguj się jako użytkownik
2. W logach zobaczysz: `✅ FCM Token obtained: xxx...`
3. Token zostanie zarejestrowany w backendzie

---

## iOS (iPhone)

### Co potrzebujesz:
- **Apple Developer Account** ($99/rok) - **WYMAGANE**
- **Mac z Xcode** (już masz ✅)
- **iPhone** z iOS 13+
- **Kabel USB** do podłączenia iPhone'a

### Kroki konfiguracji:

#### 1. Utwórz Apple Developer Account
1. Wejdź na https://developer.apple.com/programs/
2. Zaloguj się swoim Apple ID
3. Opłać subskrypcję ($99/rok)
4. Poczekaj na aktywację (do 48h)

#### 2. Wygeneruj APNS Key w Apple Developer Portal
```
1. Zaloguj się: https://developer.apple.com/account
2. Certificates, Identifiers & Profiles → Keys
3. Kliknij "+" aby utworzyć nowy klucz
4. Nazwa: "Szybka Fucha APNS Key"
5. Zaznacz: ✅ Apple Push Notifications service (APNs)
6. Kliknij "Continue" → "Register"
7. WAŻNE: Pobierz plik .p8 (możesz pobrać tylko RAZ!)
8. Zanotuj: Key ID (np. ABC123DEFG)
9. Zanotuj: Team ID (widoczny w prawym górnym rogu)
```

#### 3. Wgraj APNS Key do Firebase
```
1. Firebase Console → Project Settings → Cloud Messaging
2. Sekcja "Apple app configuration"
3. Kliknij "Upload" przy APNs Authentication Key
4. Wgraj plik .p8
5. Wpisz Key ID
6. Wpisz Team ID
7. Zapisz
```

#### 4. Skonfiguruj Xcode
```
1. Otwórz ios/Runner.xcworkspace w Xcode
2. Kliknij "Runner" w nawigatorze projektu
3. Tab "Signing & Capabilities"
4. Wybierz swój Team (Apple Developer Account)
5. Kliknij "+ Capability"
6. Dodaj "Push Notifications"
7. Dodaj "Background Modes" → zaznacz "Remote notifications"
```

#### 5. Zarejestruj urządzenie
Przy pierwszym uruchomieniu na iPhone:
1. Podłącz iPhone kablem USB
2. Xcode automatycznie zarejestruje urządzenie w Developer Portal
3. Może być wymagane "Trust This Computer" na telefonie

#### 6. Uruchom aplikację
```bash
cd mobile
flutter run -d <iphone_device_id>

# lub przez Xcode:
# Product → Run (Cmd+R)
```

#### 7. Testowanie
1. Zaloguj się w aplikacji
2. Zaakceptuj prośbę o powiadomienia
3. W logach: `✅ FCM Token obtained: xxx...`

---

## Backend - Wysyłanie powiadomień

### Obecny stan:
- ✅ Endpoint `/users/me/fcm-token` - zapisuje token użytkownika
- ❌ Brak logiki wysyłania powiadomień

### Do implementacji:

#### 1. Zainstaluj Firebase Admin SDK
```bash
cd backend
npm install firebase-admin
```

#### 2. Pobierz Service Account Key
```
Firebase Console → Project Settings → Service accounts
→ Generate new private key → Pobierz JSON
→ Zapisz jako backend/firebase-service-account.json
→ DODAJ DO .gitignore!
```

#### 3. Utwórz NotificationService
```typescript
// backend/src/notifications/notification.service.ts
import * as admin from 'firebase-admin';

@Injectable()
export class NotificationService {
  constructor() {
    admin.initializeApp({
      credential: admin.credential.cert('./firebase-service-account.json'),
    });
  }

  async sendToUser(userId: string, title: string, body: string, data?: any) {
    const user = await this.userRepository.findOne(userId);
    if (!user?.fcmToken) return;

    await admin.messaging().send({
      token: user.fcmToken,
      notification: { title, body },
      data,
    });
  }
}
```

#### 4. Dodaj wysyłanie powiadomień w kluczowych miejscach:

| Zdarzenie | Odbiorca | Tytuł | Treść |
|-----------|----------|-------|-------|
| Nowe zlecenie | Wykonawcy w pobliżu | "Nowe zlecenie!" | "{kategoria} - {adres}" |
| Zlecenie zaakceptowane | Klient | "Znaleziono wykonawcę!" | "{imię} przyjął Twoje zlecenie" |
| Wykonawca w drodze | Klient | "Wykonawca jedzie!" | "ETA: {czas} min" |
| Wykonawca na miejscu | Klient | "Wykonawca na miejscu" | "{imię} dotarł" |
| Zlecenie zakończone | Klient | "Zlecenie zakończone" | "Potwierdź i oceń wykonawcę" |
| Nowa wiadomość | Odbiorca | "{imię}" | "{treść wiadomości}" |
| Płatność otrzymana | Wykonawca | "Płatność!" | "Otrzymałeś {kwota} zł" |

---

## Testowanie push notifications

### Przez Firebase Console (najprostsze):
```
1. Firebase Console → Cloud Messaging → Send your first message
2. Notification title: "Test"
3. Notification text: "To jest test"
4. Send test message
5. Wklej FCM token z logów aplikacji
6. Wyślij
```

### Przez cURL:
```bash
# Potrzebujesz Server Key z Firebase Console → Project Settings → Cloud Messaging
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_UŻYTKOWNIKA",
    "notification": {
      "title": "Test",
      "body": "Testowe powiadomienie"
    }
  }'
```

### Przez backend (po implementacji):
```bash
# Endpoint do testowania (tylko dev)
curl -X POST http://localhost:3000/api/v1/notifications/test \
  -H "Authorization: Bearer JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"title": "Test", "body": "Testowe powiadomienie"}'
```

---

## Checklist przed uruchomieniem

### Android:
- [ ] Telefon Android z włączonym USB debugging
- [ ] `google-services.json` w projekcie (jest ✅)
- [ ] Uruchomienie przez `flutter run`

### iOS:
- [ ] Apple Developer Account (opłacony)
- [ ] APNS Key (.p8) wygenerowany
- [ ] APNS Key wgrany do Firebase
- [ ] Push Notifications capability w Xcode
- [ ] Background Modes → Remote notifications w Xcode
- [ ] iPhone zarejestrowany jako development device

### Backend:
- [ ] Firebase Admin SDK zainstalowany
- [ ] Service Account Key pobrany i skonfigurowany
- [ ] NotificationService zaimplementowany
- [ ] Wysyłanie powiadomień w TasksService, MessagesService

---

## Znane problemy

### iOS Simulator nie obsługuje push
**Rozwiązanie:** Testuj tylko na prawdziwym iPhone

### Token FCM się zmienia
**Rozwiązanie:** Już obsłużone - `onTokenRefresh` aktualizuje token w backendzie

### Powiadomienia nie dochodzą w tle (iOS)
**Rozwiązanie:** Sprawdź czy Background Modes są włączone w Xcode

### "APNS token has not been set yet"
**Rozwiązanie:**
- Na symulatorze: ignoruj (symulator nie obsługuje APNS)
- Na prawdziwym urządzeniu: sprawdź konfigurację w Xcode

---

## Szacowany czas implementacji

| Zadanie | Czas |
|---------|------|
| Konfiguracja Apple Developer + APNS | 1-2h (+ czas oczekiwania na aktywację konta) |
| Konfiguracja Firebase Admin w backendzie | 1h |
| NotificationService implementation | 2-3h |
| Integracja z TasksService, MessagesService | 2h |
| Testowanie na urządzeniach | 2h |
| **RAZEM** | ~8-10h |

---

## Powiązane pliki w projekcie

```
mobile/
├── lib/core/services/notification_service.dart  # FCM client
├── lib/core/widgets/notification_initializer.dart
├── ios/Runner/Info.plist  # iOS permissions
└── android/app/google-services.json  # Firebase config

backend/
├── src/users/users.controller.ts  # PUT /users/me/fcm-token
└── src/notifications/  # TODO: Create this module
```
