Plan: Infrastruktura Testów Multi-Device dla Flutter
Cel
Stworzenie infrastruktury do automatycznego testowania na dwóch symulatorach iOS jednocześnie (klient + wykonawca) z możliwością testowania pełnego cyklu życia zlecenia.

Architektura

┌─────────────────────┐     ┌─────────────────────┐
│   Symulator 1       │     │   Symulator 2       │
│   (Klient)          │     │   (Wykonawca)       │
│   iPhone 16 Pro     │     │   iPhone 6         │
└─────────────────────┘     └─────────────────────┘
          │                           │
          ▼                           ▼
┌─────────────────────┐     ┌─────────────────────┐
│  integration_test   │     │  integration_test   │
│  DEVICE_ROLE=client │     │  DEVICE_ROLE=       │
│                     │     │  contractor         │
└─────────────────────┘     └─────────────────────┘
          │                           │
          └───────────┬───────────────┘
                      ▼
         ┌────────────────────────┐
         │  Test Orchestrator     │
         │  (Shell Script)        │
         │  - Uruchamia symulatory│
         │  - Koordynuje testy    │
         │  - Zbiera wyniki       │
         └────────────────────────┘
                      │
                      ▼
         ┌────────────────────────┐
         │  Backend (NestJS)      │
         │  - Prawdziwe API       │
         │  - WebSocket events    │
         │  - Seeded test data    │
         └────────────────────────┘
Struktura Plików

mobile/
├── integration_test/
│   ├── config/
│   │   └── test_config.dart          # Konfiguracja (timeouty, URL-e)
│   │
│   ├── utils/
│   │   ├── test_app.dart             # Wrapper aplikacji z override'ami
│   │   ├── test_api_client.dart      # Klient API do weryfikacji stanu
│   │   ├── test_sync.dart            # Synchronizacja między urządzeniami
│   │   └── widget_helpers.dart       # Helpery do znajdowania widgetów
│   │
│   ├── robots/                       # Page Object Pattern
│   │   ├── base_robot.dart
│   │   ├── auth_robot.dart           # Logowanie
│   │   ├── client/
│   │   │   ├── create_task_robot.dart
│   │   │   └── task_tracking_robot.dart
│   │   └── contractor/
│   │       ├── task_list_robot.dart
│   │       └── active_task_robot.dart
│   │
│   ├── scenarios/                    # Scenariusze testowe
│   │   ├── task_visibility_test.dart
│   │   ├── full_lifecycle_test.dart
│   │   ├── client_cancel_test.dart
│   │   ├── contractor_cancel_test.dart
│   │   └── client_reject_contractor_test.dart
│   │
│   └── app_test.dart                 # Entry point (wykrywa rolę)
│
└── scripts/
    ├── run_multi_device_tests.sh     # Główny skrypt
    ├── setup_test_simulators.sh      # Tworzenie symulatorów
    └── run_scenario.sh               # Pojedynczy scenariusz
Kluczowe Komponenty
1. Synchronizacja (Plik-based + API polling)

// integration_test/utils/test_sync.dart
class TestSync {
  static const _syncDir = '/tmp/szybkafucha_tests';

  // Zapisz marker synchronizacji
  static Future<void> setMarker(String key, String value);

  // Czekaj na marker od drugiego urządzenia
  static Future<void> waitForMarker(String key, String expected, {Duration timeout});

  // Sprawdź status zadania przez API
  static Future<TaskStatus> getTaskStatus(String taskId);

  // Czekaj aż zadanie osiągnie status
  static Future<void> waitForTaskStatus(String taskId, TaskStatus expected);
}
2. Test App Wrapper

// integration_test/utils/test_app.dart
class TestApp {
  static Widget create({required DeviceRole role}) {
    return ProviderScope(
      overrides: [
        // Wyłącz dev mode - używamy prawdziwego backendu
        // Override API config na localhost:3000
      ],
      child: const SzybkaFuchaApp(),
    );
  }
}
3. Robots (Page Objects)

// integration_test/robots/client/create_task_robot.dart
class CreateTaskRobot {
  final WidgetTester tester;

  Future<void> selectCategory(TaskCategory category);
  Future<void> enterDescription(String text);
  Future<void> setLocation(double lat, double lng);
  Future<void> setBudget(double amount);
  Future<String> submitAndGetTaskId();
}
Scenariusze Testowe
Scenariusz 1: Widoczność Utworzonego Zadania

CLIENT                              CONTRACTOR
  │                                     │
  ├── Loguje się                        ├── Loguje się
  ├── Tworzy zadanie                    │
  ├── setMarker('task_created', taskId) │
  │                                     ├── waitForMarker('task_created')
  │                                     ├── Odświeża listę zadań
  │                                     ├── Weryfikuje że zadanie jest widoczne
  │                                     └── setMarker('task_visible', 'true')
  └── waitForMarker('task_visible')

Scenariusz 2: Pełny Cykl Życia

CLIENT                              CONTRACTOR
  │                                     │
  ├── Tworzy zadanie (POSTED)           │
  ├── signal: task_created              │
  │                                     ├── wait: task_created
  │                                     ├── Akceptuje (ACCEPTED)
  │                                     └── signal: accepted
  ├── wait: accepted                    │
  ├── Potwierdza wykonawcę (CONFIRMED)  │
  ├── signal: confirmed                 │
  │                                     ├── wait: confirmed
  │                                     ├── Rozpoczyna (IN_PROGRESS)
  │                                     └── signal: in_progress
  ├── wait: in_progress                 │
  │                                     ├── Kończy (COMPLETED)
  │                                     └── signal: completed
  │
  ├── wait: completed                   ├── wait: completed
  ├── Potwierdza i ocenia               ├── Potwierdza i ocenia
  └── DONE                              └── DONE


Scenariusz 3: Anulowanie przez Klienta

CLIENT                              CONTRACTOR
  │                                     │
  ├── Tworzy zadanie                    │
  │                                     ├── Akceptuje zadanie
  ├── wait: accepted                    │
  ├── ANULUJE zadanie                   │
  ├── signal: cancelled                 │
  │                                     ├── wait: cancelled
  │                                     ├── Weryfikuje że zadanie zniknęło
  │                                     └── Weryfikuje powiadomienie


Scenariusz 4: Anulowanie przez Wykonawcę

CLIENT                              CONTRACTOR
  │                                     │
  ├── Tworzy zadanie                    │
  │                                     ├── Akceptuje zadanie
  ├── wait: accepted                    │
  │                                     ├── ANULUJE zadanie
  │                                     └── signal: contractor_cancelled
  ├── wait: contractor_cancelled        │
  ├── Weryfikuje że zadanie wróciło     │
  │   do statusu POSTED                 │
  └── Weryfikuje powiadomienie          │



Scenariusz 5: Odrzucenie Wykonawcy przez Klienta

CLIENT                              CONTRACTOR
  │                                     │
  ├── Tworzy zadanie                    │
  │                                     ├── Akceptuje zadanie
  ├── wait: accepted                    │
  ├── ODRZUCA wykonawcę                 │
  ├── signal: rejected                  │
  │                                     ├── wait: rejected
  │                                     ├── Weryfikuje że zadanie zniknęło
  │                                     │   z aktywnych
  │                                     └── Weryfikuje powiadomienie
  ├── Zadanie wraca do POSTED           │
  └── Czeka na innego wykonawcę         │


Skrypt Orkiestracyjny

#!/bin/bash
# scripts/run_multi_device_tests.sh

# 1. Sprawdź czy backend działa
curl -s http://localhost:3000/api/v1/health || exit 1

# 2. Zresetuj bazę danych
cd ../backend && npm run seed:fresh

# 3. Uruchom symulatory
xcrun simctl boot "iPhone 16 Pro"
xcrun simctl boot "iPhone 16"

# 4. Wyczyść folder synchronizacji
rm -rf /tmp/szybkafucha_tests && mkdir -p /tmp/szybkafucha_tests

# 5. Uruchom testy równolegle
DEVICE_ROLE=client flutter test integration_test/ \
  --device-id="iPhone 16 Pro" &
CLIENT_PID=$!

DEVICE_ROLE=contractor flutter test integration_test/ \
  --device-id="iPhone 16" &
CONTRACTOR_PID=$!

# 6. Czekaj na zakończenie
wait $CLIENT_PID
CLIENT_EXIT=$?

wait $CONTRACTOR_PID
CONTRACTOR_EXIT=$?

# 7. Raportuj wyniki
if [ $CLIENT_EXIT -eq 0 ] && [ $CONTRACTOR_EXIT -eq 0 ]; then
  echo "✅ ALL TESTS PASSED"
  exit 0
else
  echo "❌ TESTS FAILED"
  exit 1
fi
Kroki Implementacji
Faza 1: Infrastruktura Bazowa
Dodaj zależność integration_test do pubspec.yaml

Plik: pubspec.yaml
Utwórz strukturę folderów

integration_test/config/
integration_test/utils/
integration_test/robots/
integration_test/scenarios/
scripts/
Zaimplementuj test_config.dart

Timeouty, URL backendu, nazwy symulatorów
Zaimplementuj test_sync.dart

Synchronizacja plikowa + API polling
Faza 2: Robots (Page Objects)
Zaimplementuj base_robot.dart

Wspólne metody: tap, enterText, waitFor, scroll
Zaimplementuj auth_robot.dart

loginAsClient(), loginAsContractor()
Zaimplementuj robots dla klienta

create_task_robot.dart
task_tracking_robot.dart
Zaimplementuj robots dla wykonawcy

task_list_robot.dart
active_task_robot.dart
Faza 3: Scenariusze Testowe
Zaimplementuj task_visibility_test.dart

Najprostszy test - dobry na początek
Zaimplementuj full_lifecycle_test.dart

Pełny cykl od utworzenia do oceny
Zaimplementuj testy anulowania

client_cancel_test.dart
contractor_cancel_test.dart
client_reject_contractor_test.dart
Faza 4: Skrypty i Dokumentacja
Utwórz skrypty shell

run_multi_device_tests.sh
setup_test_simulators.sh
run_scenario.sh
Dodaj README z instrukcjami

Jak uruchomić testy
Jak dodać nowe scenariusze
Troubleshooting
Pliki do Modyfikacji
Plik	Zmiana
pubspec.yaml	Dodać integration_test: sdk: flutter
Nowe pliki w integration_test/	Cała infrastruktura testowa
Nowe pliki w scripts/	Skrypty orkiestracyjne
Weryfikacja
Jak przetestować infrastrukturę:
Uruchom backend


cd backend && npm run start:dev
Zresetuj dane testowe


cd backend && npm run seed:fresh
Uruchom testy


cd mobile && ./scripts/run_multi_device_tests.sh
Sprawdź wyniki

Logi w /tmp/szybkafucha_tests/
Exit code 0 = sukces
Oczekiwany Output

[INFO] Starting multi-device tests...
[INFO] Backend is running
[INFO] Database seeded
[INFO] Simulators booted
[INFO] Running tests...
[SUCCESS] Client tests: PASSED
[SUCCESS] Contractor tests: PASSED
==========================================
✅ ALL TESTS PASSED
==========================================
Użycie przez AI Agenta
Po implementacji, AI agent może testować nowe funkcje poprzez:


# Testuj konkretny scenariusz
./scripts/run_scenario.sh client_cancel

# Testuj wszystkie scenariusze
./scripts/run_multi_device_tests.sh

# Verbose mode
VERBOSE=true ./scripts/run_multi_device_tests.sh
Wyniki są jasne (PASSED/FAILED) i łatwe do interpretacji przez agenta.

