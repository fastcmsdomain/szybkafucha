# Multi-Device Integration Tests

Infrastruktura do automatycznego testowania aplikacji na dwóch symulatorach iOS jednocześnie - jeden jako klient, drugi jako wykonawca.

## Wymagania

- macOS z Xcode
- Flutter SDK
- Backend NestJS uruchomiony na `localhost:3000`
- Dwa symulatory iOS (domyślnie: iPhone 16 Pro, iPhone 16)

## Struktura

```
integration_test/
├── config/
│   └── test_config.dart       # Konfiguracja (timeouty, URL-e)
├── utils/
│   ├── test_app.dart          # Wrapper aplikacji
│   └── test_sync.dart         # Synchronizacja między urządzeniami
├── robots/                    # Page Object Pattern
│   ├── base_robot.dart
│   ├── auth_robot.dart
│   ├── client/
│   │   ├── create_task_robot.dart
│   │   └── task_tracking_robot.dart
│   └── contractor/
│       ├── task_list_robot.dart
│       └── active_task_robot.dart
└── scenarios/
    └── full_lifecycle_test.dart
```

## Uruchomienie

### 1. Uruchom backend

```bash
cd backend
npm run start:dev
```

### 2. Zresetuj bazę danych

```bash
cd backend
npm run seed:fresh
```

### 3. Uruchom testy

```bash
cd mobile
./scripts/run_multi_device_tests.sh
```

### Opcje

```bash
# Konkretny scenariusz
./scripts/run_scenario.sh full_lifecycle

# Tryb verbose (więcej logów)
VERBOSE=true ./scripts/run_multi_device_tests.sh

# Wszystkie scenariusze
./scripts/run_multi_device_tests.sh
```

## Scenariusze testowe

### full_lifecycle
Pełny cykl życia zlecenia:
1. Klient tworzy zlecenie
2. Wykonawca akceptuje
3. Klient potwierdza wykonawcę
4. Wykonawca rozpoczyna pracę
5. Wykonawca kończy pracę
6. Klient ocenia wykonawcę
7. Wykonawca ocenia klienta

## Jak działają testy

### Synchronizacja

Testy używają synchronizacji plikowej (`/tmp/szybkafucha_tests/`) do koordynacji między urządzeniami:

```dart
// Klient sygnalizuje utworzenie zadania
await TestSync.setMarker('task_created', 'true');

// Wykonawca czeka na sygnał
await TestSync.waitForMarkerValue('task_created', 'true');
```

### Robots (Page Objects)

Każdy ekran ma dedykowanego "robota" z metodami do interakcji:

```dart
final authRobot = AuthRobot(tester);
await authRobot.loginAsClient();

final createTaskRobot = CreateTaskRobot(tester);
await createTaskRobot.createTask(
  category: TaskCategory.paczki,
  description: 'Test task',
  budget: 75.0,
);
```

## Dodawanie nowych scenariuszy

1. Utwórz plik w `integration_test/scenarios/`:

```dart
// integration_test/scenarios/my_scenario_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../config/test_config.dart';
import '../utils/test_app.dart';
import '../utils/test_sync.dart';
import '../robots/auth_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final deviceRole = DeviceRole.fromEnvironment();

  group('My Scenario', () {
    if (deviceRole == DeviceRole.client) {
      testWidgets('Client flow', (tester) async {
        // Client test code
      });
    } else {
      testWidgets('Contractor flow', (tester) async {
        // Contractor test code
      });
    }
  });
}
```

2. Uruchom:

```bash
./scripts/run_scenario.sh my_scenario
```

## Troubleshooting

### Backend nie działa
```
[ERROR] Backend is not running at http://localhost:3000
```
Rozwiązanie: `cd backend && npm run start:dev`

### Symulator nie znaleziony
```
[ERROR] Client simulator 'iPhone 16 Pro' not found
```
Rozwiązanie: Zmień nazwy symulatorów w `run_multi_device_tests.sh` lub utwórz dedykowane symulatory:
```bash
./scripts/setup_test_simulators.sh
```

### Timeout podczas oczekiwania na marker
```
TimeoutException: Timeout waiting for marker: contractor_accepted
```
Możliwe przyczyny:
- Drugi symulator nie uruchomił się poprawnie
- Test na drugim urządzeniu zakończył się błędem
- Sprawdź logi w `/tmp/szybkafucha_tests/`

### Test nie znajduje elementów UI
Upewnij się, że:
- Texty w robotach odpowiadają rzeczywistym textom w UI
- UI jest w języku polskim
- Ekran załadował się przed próbą interakcji

## Dla AI Agenta

Po implementacji nowych funkcji, uruchom testy aby zweryfikować:

```bash
./scripts/run_multi_device_tests.sh full_lifecycle
```

Wynik `✅ ALL TESTS PASSED` oznacza sukces.
Wynik `❌ SOME TESTS FAILED` - sprawdź logi w `/tmp/szybkafucha_tests/`.
