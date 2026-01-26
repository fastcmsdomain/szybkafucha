# Poradnik: Powiadomienia Push i Chat w Szybka Fucha

## Spis treści
1. [Konfiguracja SHA-1 dla Androida](#1-konfiguracja-sha-1-dla-androida)
2. [Jak testować bez fizycznego telefonu](#2-jak-testować-bez-fizycznego-telefonu)
3. [Co dają powiadomienia push](#3-co-dają-powiadomienia-push)
4. [Gdzie i jak używać powiadomień](#4-gdzie-i-jak-używać-powiadomień)
5. [Chat między wykonawcą a zleceniodawcą](#5-chat-między-wykonawcą-a-zleceniodawcą)
6. [Jak testować powiadomienia](#6-jak-testować-powiadomienia)

---

## 1. Konfiguracja SHA-1 dla Androida

### Twój SHA-1 fingerprint (debug):
```
6E:32:81:F6:73:F1:72:0B:44:D9:41:F5:9D:EF:79:47:87:4F:27:DB
```

### Jak dodać SHA-1 do Firebase:

1. **Otwórz Firebase Console**: https://console.firebase.google.com/
2. **Wybierz projekt**: `szybkafucha-e695b`
3. **Przejdź do ustawień**:
   - Kliknij ikonę koła zębatego (⚙️) → "Ustawienia projektu"
4. **Znajdź aplikację Android**:
   - Przewiń do sekcji "Twoje aplikacje"
   - Znajdź `pl.szybkafucha.mobile` (Android)
5. **Dodaj SHA-1**:
   - Kliknij "Dodaj odcisk palca"
   - Wklej: `6E:32:81:F6:73:F1:72:0B:44:D9:41:F5:9D:EF:79:47:87:4F:27:DB`
   - Zapisz

### Po co jest SHA-1?
SHA-1 to "odcisk palca" Twojej aplikacji. Firebase używa go żeby:
- Zweryfikować że powiadomienia idą do prawdziwej aplikacji
- Zabezpieczyć logowanie przez Google
- Chronić przed fałszywymi aplikacjami

---

## 2. Jak testować bez fizycznego telefonu

### Symulator iOS (zalecane dla Ciebie)
```bash
cd mobile
flutter run -d "iPhone 16"
```

**UWAGA**: Symulator iOS NIE obsługuje powiadomień push!
- Możesz testować UI aplikacji
- Chat będzie działał (przez WebSocket)
- Powiadomienia push wymagają prawdziwego iPhone'a

### Emulator Android
```bash
# Lista dostępnych emulatorów
flutter emulators

# Uruchom emulator
flutter emulators --launch <nazwa_emulatora>

# Uruchom aplikację
flutter run
```

**Android Emulator** OBSŁUGUJE powiadomienia push jeśli ma Google Play Services.

### Kiedy potrzebujesz fizycznego telefonu?

| Funkcja | Symulator iOS | Emulator Android | Fizyczny telefon |
|---------|---------------|------------------|------------------|
| UI/UX | ✅ | ✅ | ✅ |
| Chat (WebSocket) | ✅ | ✅ | ✅ |
| Powiadomienia Push | ❌ | ✅ (z Google Play) | ✅ |
| Logowanie Google | ❌ | ✅ | ✅ |
| Logowanie Apple | ❌ | ❌ | ✅ (tylko iOS) |

### Jeśli chcesz użyć fizycznego telefonu:

**Dla iPhone:**
- Kabel: Lightning → USB-C (lub Lightning → USB-A)
- Potrzebujesz Apple Developer Account (darmowe lub płatne)
- Musisz skonfigurować code signing w Xcode

**Dla Androida:**
- Kabel: USB-C → USB-C (lub USB-C → USB-A)
- Włącz "Opcje programisty" i "Debugowanie USB" w telefonie
- Prostsze niż iOS - nie wymaga dodatkowych kont

---

## 3. Co dają powiadomienia push

### Dla Zleceniodawcy (Klienta):

| Powiadomienie | Kiedy | Treść |
|---------------|-------|-------|
| Zlecenie zaakceptowane | Wykonawca przyjął zlecenie | "Anna N. przyjęła Twoje zlecenie!" |
| Zlecenie rozpoczęte | Wykonawca zaczął pracę | "Praca nad 'Sprzątanie mieszkania' się rozpoczęła" |
| Zlecenie ukończone | Wykonawca zakończył | "Zlecenie ukończone! Potwierdź wykonanie." |
| Nowa wiadomość | Wykonawca napisał | "Anna: Jestem pod adresem" |
| Płatność pobrana | Środki pobrane | "Płatność 150 PLN została pobrana" |
| Zwrot środków | Anulowano zlecenie | "Zwrócono 150 PLN na Twoje konto" |

### Dla Wykonawcy (Kontraktora):

| Powiadomienie | Kiedy | Treść |
|---------------|-------|-------|
| Nowe zlecenie w pobliżu | Klient dodał zadanie | "Nowe zlecenie 'Zakupy' - 500m od Ciebie!" |
| Potwierdzenie klienta | Klient zatwierdził pracę | "Klient potwierdził wykonanie zlecenia!" |
| Płatność otrzymana | Przelew na konto | "Otrzymałeś 124.50 PLN za 'Sprzątanie'" |
| Nowa wiadomość | Klient napisał | "Jan: Czy możesz przyjść o 15:00?" |
| Ocena otrzymana | Klient wystawił ocenę | "Otrzymałeś ocenę ⭐⭐⭐⭐⭐ (5.0)" |
| Napiwek | Klient dał napiwek | "Otrzymałeś napiwek 20 PLN!" |

### Dla Obu Stron:

| Powiadomienie | Kiedy | Treść |
|---------------|-------|-------|
| Zlecenie anulowane | Jedna ze stron anulowała | "Zlecenie 'Zakupy' zostało anulowane" |
| Spór otwarty | Zgłoszono problem | "Otwarto spór dotyczący zlecenia" |
| Spór rozwiązany | Admin rozstrzygnął | "Spór został rozwiązany" |

---

## 4. Gdzie i jak używać powiadomień

### Architektura powiadomień

```
┌─────────────────────────────────────────────────────────────┐
│                        BACKEND                               │
│  ┌─────────────┐    ┌──────────────┐    ┌────────────────┐ │
│  │ TaskService │───▶│ Notification │───▶│ Firebase Admin │ │
│  │ ChatService │    │   Service    │    │      SDK       │ │
│  │ PayService  │    └──────────────┘    └────────────────┘ │
│  └─────────────┘           │                     │         │
└────────────────────────────│─────────────────────│─────────┘
                             │                     │
                             ▼                     ▼
                    ┌─────────────┐        ┌─────────────┐
                    │   Baza DB   │        │   Firebase  │
                    │ (historia)  │        │   Cloud     │
                    └─────────────┘        │  Messaging  │
                                           └─────────────┘
                                                  │
                                                  ▼
                    ┌─────────────────────────────────────────┐
                    │              APLIKACJA MOBILNA           │
                    │  ┌──────────────────────────────────┐   │
                    │  │     NotificationService          │   │
                    │  │  - Odbiera FCM token            │   │
                    │  │  - Pokazuje powiadomienia       │   │
                    │  │  - Przekierowuje po kliknięciu  │   │
                    │  └──────────────────────────────────┘   │
                    └─────────────────────────────────────────┘
```

### Gdzie w kodzie są powiadomienia?

**Backend:**
```
backend/src/notifications/
├── notifications.module.ts      # Moduł NestJS
├── notifications.service.ts     # Logika wysyłania
├── templates/                   # 20+ szablonów powiadomień
│   ├── new-task-nearby.ts
│   ├── task-accepted.ts
│   ├── new-message.ts
│   └── ...
└── dto/
    └── send-notification.dto.ts
```

**Mobile:**
```
mobile/lib/core/
├── services/
│   └── notification_service.dart    # Obsługa FCM
├── providers/
│   └── notification_provider.dart   # Riverpod provider
├── widgets/
│   └── notification_initializer.dart # Auto-inicjalizacja
└── router/
    └── notification_router.dart     # Przekierowania
```

### Jak wysłać powiadomienie z backendu?

```typescript
// backend/src/tasks/tasks.service.ts
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class TasksService {
  constructor(
    private notifications: NotificationsService,
  ) {}

  async acceptTask(taskId: string, contractorId: string) {
    // ... logika akceptacji ...

    // Wyślij powiadomienie do zleceniodawcy
    await this.notifications.sendTaskAccepted({
      userId: task.clientId,
      taskId: task.id,
      taskTitle: task.title,
      contractorName: contractor.name,
    });
  }
}
```

---

## 5. Chat między wykonawcą a zleceniodawcą

### Jak działa chat?

```
┌─────────────┐         WebSocket          ┌─────────────┐
│   KLIENT    │◀─────────────────────────▶│  WYKONAWCA  │
│  (Telefon)  │                            │  (Telefon)  │
└──────┬──────┘                            └──────┬──────┘
       │                                          │
       │        ┌─────────────────────┐          │
       └───────▶│   BACKEND (NestJS)  │◀─────────┘
                │   WebSocket Gateway │
                │   /realtime         │
                └──────────┬──────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │  PostgreSQL │
                    │  (historia) │
                    └─────────────┘
```

### Ekran chatu w aplikacji

**Lokalizacja:** `mobile/lib/features/chat/`

```
chat/
├── screens/
│   └── chat_screen.dart         # Główny ekran chatu
├── widgets/
│   ├── message_bubble.dart      # Bańka wiadomości
│   ├── message_input.dart       # Pole do pisania
│   └── chat_header.dart         # Nagłówek z info o zleceniu
└── providers/
    └── chat_provider.dart       # Stan czatu (Riverpod)
```

### Jak używać chatu?

**1. Zleceniodawca otwiera chat:**
- Wchodzi w szczegóły zlecenia
- Klika przycisk "Napisz do wykonawcy"
- Otwiera się ekran chatu

**2. Wykonawca otwiera chat:**
- Wchodzi w akceptowane zlecenie
- Klika "Napisz do klienta"
- Lub klika powiadomienie o nowej wiadomości

**3. Wysyłanie wiadomości:**
```dart
// mobile/lib/features/chat/providers/chat_provider.dart
Future<void> sendMessage(String taskId, String content) async {
  // 1. Wyślij przez WebSocket (natychmiastowe)
  _websocket.sendMessage(taskId, content);

  // 2. Zapisz lokalnie (optymistyczne UI)
  _addLocalMessage(content);

  // 3. Backend zapisze do bazy i wyśle push do odbiorcy
}
```

### Przepływ wiadomości

```
Wykonawca pisze "Jestem pod adresem"
              │
              ▼
┌─────────────────────────────────┐
│ WebSocket wysyła do backendu   │
└─────────────────────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│ Backend zapisuje do PostgreSQL │
│ + wysyła push notification     │
└─────────────────────────────────┘
              │
              ├──────────────────────────┐
              ▼                          ▼
┌─────────────────────────┐  ┌─────────────────────────┐
│ WebSocket do klienta    │  │ Push notification       │
│ (jeśli app otwarta)     │  │ (jeśli app zamknięta)   │
└─────────────────────────┘  └─────────────────────────┘
              │                          │
              ▼                          ▼
┌─────────────────────────────────────────────────────┐
│         Klient widzi wiadomość natychmiast          │
└─────────────────────────────────────────────────────┘
```

### Scenariusze użycia chatu

**Przed rozpoczęciem zlecenia:**
- Wykonawca: "Czy mogę przyjść o 16:00 zamiast 15:00?"
- Klient: "Tak, 16:00 pasuje"

**W trakcie zlecenia:**
- Wykonawca: "Jestem pod wskazanym adresem"
- Klient: "Kod do domofonu: 1234#"

**Po zakończeniu:**
- Wykonawca: "Skończyłem, wszystko posprzątane!"
- Klient: "Dziękuję, świetna robota!"

---

## 6. Jak testować powiadomienia

### Metoda 1: Emulator Android z Google Play

```bash
# 1. Utwórz emulator z Google Play (w Android Studio)
# Nazwa: Pixel_7_API_34

# 2. Uruchom emulator
flutter emulators --launch Pixel_7_API_34

# 3. Uruchom aplikację
cd mobile
flutter run

# 4. Zaloguj się w aplikacji
# 5. FCM token zostanie automatycznie zarejestrowany
```

### Metoda 2: Firebase Console (Test Message)

1. Otwórz: https://console.firebase.google.com/
2. Wybierz projekt → Cloud Messaging
3. Kliknij "Send your first message"
4. Wypełnij:
   - Tytuł: "Test powiadomienia"
   - Treść: "To jest testowa wiadomość"
5. Wybierz "Send test message"
6. Wklej FCM token urządzenia

### Metoda 3: Backend API (Zalecane)

```bash
# 1. Uruchom backend
cd backend
npm run start:dev

# 2. Wyślij testowe powiadomienie (wymaga JWT)
curl -X POST http://localhost:3000/api/v1/notifications/test \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test",
    "body": "Testowa wiadomość",
    "type": "test"
  }'
```

### Metoda 4: Mock Mode (Bez Firebase)

Jeśli Firebase nie działa, aplikacja przechodzi w tryb mock:
- Powiadomienia są logowane do konsoli
- UI działa normalnie
- Chat działa przez WebSocket

```dart
// Sprawdź logi w terminalu Flutter
flutter run
// Szukaj: "✅ FCM Token obtained" lub "❌ Failed to get FCM token"
```

### Checklist testowania

- [ ] SHA-1 dodany do Firebase Console
- [ ] `google-services.json` w `mobile/android/app/`
- [ ] `GoogleService-Info.plist` w `mobile/ios/Runner/`
- [ ] Backend uruchomiony z prawidłowymi Firebase credentials
- [ ] Aplikacja uruchomiona na emulatorze/urządzeniu
- [ ] Użytkownik zalogowany
- [ ] FCM token widoczny w logach

---

## Szybki start - Co zrobić teraz?

### Krok 1: Dodaj SHA-1 do Firebase
1. Otwórz https://console.firebase.google.com/
2. Projekt `szybkafucha-e695b` → Ustawienia → Aplikacja Android
3. Dodaj fingerprint: `6E:32:81:F6:73:F1:72:0B:44:D9:41:F5:9D:EF:79:47:87:4F:27:DB`

### Krok 2: Uruchom na emulatorze Android
```bash
# Terminal 1 - Backend
cd backend && npm run start:dev

# Terminal 2 - Aplikacja
cd mobile && flutter run
```

### Krok 3: Zaloguj się i sprawdź logi
Szukaj w konsoli:
```
✅ Firebase initialized
✅ FCM Token obtained: xxx...
✅ FCM token registered with backend
```

### Krok 4: Wyślij testowe powiadomienie
Z Firebase Console → Cloud Messaging → Send test message

---

## Problemy i rozwiązania

| Problem | Rozwiązanie |
|---------|-------------|
| "Failed to get FCM token" | Sprawdź google-services.json i SHA-1 |
| Powiadomienia nie przychodzą | Sprawdź czy backend ma Firebase credentials |
| Chat nie działa | Sprawdź czy WebSocket jest włączony (devModeEnabled = false) |
| "No valid code signing" (iOS) | Skonfiguruj Team w Xcode lub użyj symulatora |

---

## Kontakt

Masz pytania? Sprawdź:
- `/tasks/tasks-prd-szybka-fucha.md` - Pełna dokumentacja
- `/backend/DEPLOYMENT.md` - Instrukcja wdrożenia
- `CLAUDE.md` - Instrukcje dla AI

---

*Ostatnia aktualizacja: 2026-01-22*
