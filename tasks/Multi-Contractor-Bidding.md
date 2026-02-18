# System Licytowania Zleceń (Multi-Contractor Bidding)

**Data**: 2026-02-13
**Status**: Dokumentacja / Plan implementacji
**Priorytet**: Nowa funkcjonalność

---

## Context

Obecnie system działa na zasadzie "pierwszy bierze" - jeden wykonawca akceptuje zlecenie, klient potwierdza lub odrzuca (i wtedy szuka od nowa). To ogranicza klienta - nie ma wyboru, nie widzi konkurencyjnych ofert.

**Cel**: Wielu wykonawców może zgłaszać się do zlecenia z własną ceną i opcjonalną wiadomością. Klient widzi listę kandydatów (profil, zdjęcie, rating, cena, opis) i wybiera najlepszego. Max 5 zgłoszeń na zlecenie (konfigurowalne).

**Zmiana flow**:
```
STARY: CREATED → ACCEPTED (1 wykonawca) → klient potwierdza/odrzuca → CONFIRMED
NOWY:  CREATED → wykonawcy aplikują (max 5) → klient wybiera jednego → CONFIRMED
```

Status `ACCEPTED` zostaje usunięty z flow - po wyborze wykonawcy task przechodzi od razu do `CONFIRMED`.

---

## Kluczowe decyzje projektowe

| Decyzja | Wybór |
|---------|-------|
| Model cenowy | Wykonawcy proponują własną cenę (licytacja) |
| Wiadomość przy zgłoszeniu | Tak, opcjonalna (max 500 znaków) |
| Stary flow (direct accept) | Zastąpiony całkowicie nowym systemem |
| Max zgłoszeń na task | 5 (konfigurowalne w kodzie) |

---

## Faza 1: Backend - Nowa encja `TaskApplication`

### 1.1 Nowa encja `TaskApplication`

**Plik**: `backend/src/tasks/entities/task-application.entity.ts` (nowy)

```typescript
export enum ApplicationStatus {
  PENDING = 'pending',
  ACCEPTED = 'accepted',
  REJECTED = 'rejected',
  WITHDRAWN = 'withdrawn',
}

@Entity('task_applications')
export class TaskApplication {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column('uuid')
  taskId: string;

  @ManyToOne(() => Task)
  @JoinColumn({ name: 'taskId' })
  task: Task;

  @Column('uuid')
  contractorId: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'contractorId' })
  contractor: User;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  proposedPrice: number;

  @Column({ type: 'text', nullable: true })
  message: string | null;

  @Column({ type: 'enum', enum: ApplicationStatus, default: ApplicationStatus.PENDING })
  status: ApplicationStatus;

  @CreateDateColumn()
  createdAt: Date;

  @Column({ type: 'timestamp', nullable: true })
  respondedAt: Date | null;
}
```

**Indeksy bazy danych**:
- `(taskId, contractorId)` - UNIQUE (jeden wykonawca = jedno zgłoszenie na task)
- `(taskId, status)` - szybkie filtrowanie aktywnych zgłoszeń
- `(contractorId, status)` - lista zgłoszeń wykonawcy

### 1.2 Modyfikacje encji Task

**Plik**: `backend/src/tasks/entities/task.entity.ts`

- Dodać pole `maxApplications` (default 5, konfigurowalne):
  ```typescript
  @Column({ type: 'int', default: 5 })
  maxApplications: number;
  ```
- Status `ACCEPTED` pozostaje w enumie (backward compat z istniejącymi danymi), ale nie jest używany w nowym flow
- `contractorId` nadal istnieje - ustawiany dopiero po wyborze wykonawcy przez klienta

### 1.3 Rejestracja encji

**Plik**: `backend/src/tasks/tasks.module.ts`

- Dodać `TaskApplication` do `TypeOrmModule.forFeature([Task, Rating, ContractorProfile, TaskApplication])`

---

## Faza 2: Backend - Nowe endpointy i logika

### 2.1 Nowe DTO

**Plik**: `backend/src/tasks/dto/apply-task.dto.ts` (nowy)

```typescript
export class ApplyTaskDto {
  @IsNumber()
  @Min(35) // minimalna cena z PRD
  proposedPrice: number;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  message?: string;
}
```

### 2.2 Nowe metody w `TasksService`

**Plik**: `backend/src/tasks/tasks.service.ts`

| Metoda | Opis |
|--------|------|
| `applyForTask(taskId, contractorId, dto)` | Wykonawca składa aplikację. Waliduje: task CREATED, profil kompletny, nie przekroczono max, nie aplikował wcześniej. Tworzy `TaskApplication`. Emituje WebSocket event do klienta. |
| `getApplications(taskId, clientId)` | Pobiera listę aplikacji z profilami wykonawców (avatar, rating, completedTasks, bio, distance). Tylko właściciel taska. |
| `acceptApplication(taskId, applicationId, clientId)` | Klient akceptuje aplikację. Ustawia `contractorId` na tasku, status → CONFIRMED, `finalAmount` = proposedPrice. Auto-odrzuca pozostałe aplikacje. Emituje WebSocket do wszystkich aplikantów. |
| `rejectApplication(taskId, applicationId, clientId)` | Klient odrzuca konkretną aplikację. Status aplikacji → REJECTED. Powiadamia wykonawcę. |
| `withdrawApplication(taskId, contractorId)` | Wykonawca wycofuje swoją aplikację. Status → WITHDRAWN. |
| `getMyApplications(contractorId)` | Lista aplikacji wykonawcy (do wyświetlenia statusów). |

### 2.3 Modyfikacje istniejących metod

| Metoda | Zmiana |
|--------|--------|
| `acceptTask()` | Przekierować na `applyForTask()` lub usunąć - zastąpiony nowym endpointem |
| `confirmContractor()` | Zastąpiony przez `acceptApplication()` |
| `rejectContractor()` | Zastąpiony przez `rejectApplication()` |
| `cancelTask()` | Dodać logikę: auto-odrzuć wszystkie pending aplikacje przy anulowaniu |
| `create()` | Obsłużyć opcjonalne `maxApplications` z DTO |

### 2.4 Nowe endpointy w `TasksController`

**Plik**: `backend/src/tasks/tasks.controller.ts`

| Endpoint | Metoda HTTP | Rola | Opis |
|----------|-------------|------|------|
| `POST /tasks/:id/apply` | POST | Contractor | Zgłoszenie się do zlecenia (z ceną + wiadomością) |
| `GET /tasks/:id/applications` | GET | Client | Lista zgłoszeń z profilami wykonawców |
| `PUT /tasks/:id/applications/:appId/accept` | PUT | Client | Akceptacja konkretnego wykonawcy |
| `PUT /tasks/:id/applications/:appId/reject` | PUT | Client | Odrzucenie konkretnego wykonawcy |
| `DELETE /tasks/:id/apply` | DELETE | Contractor | Wycofanie swojego zgłoszenia |
| `GET /contractor/applications` | GET | Contractor | Moje zgłoszenia (statusy) |

**Stare endpointy** (deprecation):
- `PUT /tasks/:id/accept` → zwraca 410 Gone z info o nowym endpoincie
- `PUT /tasks/:id/confirm-contractor` → zwraca 410 Gone
- `PUT /tasks/:id/reject-contractor` → zwraca 410 Gone

### 2.5 WebSocket events

**Plik**: `backend/src/realtime/realtime.gateway.ts`

Nowe eventy w `ServerEvent`:
```typescript
APPLICATION_NEW = 'application:new',          // → klient (nowe zgłoszenie)
APPLICATION_ACCEPTED = 'application:accepted', // → wykonawca (został wybrany)
APPLICATION_REJECTED = 'application:rejected', // → wykonawca (odrzucony)
APPLICATION_WITHDRAWN = 'application:withdrawn', // → klient (wykonawca się wycofał)
APPLICATION_COUNT = 'application:count',       // → klient (aktualizacja licznika)
```

Nowe metody broadcast:
- `broadcastNewApplication(taskId, clientId, applicationSummary)` - do klienta
- `broadcastApplicationResult(contractorId, taskId, status)` - do wykonawcy
- `broadcastApplicationCount(taskId, clientId, count)` - do klienta (licznik)

---

## Faza 3: Mobile - Model danych

### 3.1 Nowy model `TaskApplication`

**Plik**: `mobile/lib/features/client/models/task_application.dart` (nowy)

```dart
class TaskApplication {
  final String id;
  final String taskId;
  final String contractorId;
  final String contractorName;
  final String? contractorAvatarUrl;
  final double contractorRating;
  final int contractorReviewCount;
  final int contractorCompletedTasks;
  final bool contractorIsVerified;
  final bool contractorIsOnline;
  final double? distanceKm;
  final int? etaMinutes;
  final double proposedPrice;
  final String? message;
  final String status; // pending, accepted, rejected, withdrawn
  final DateTime createdAt;

  const TaskApplication({
    required this.id,
    required this.taskId,
    required this.contractorId,
    required this.contractorName,
    this.contractorAvatarUrl,
    required this.contractorRating,
    required this.contractorReviewCount,
    required this.contractorCompletedTasks,
    required this.contractorIsVerified,
    required this.contractorIsOnline,
    this.distanceKm,
    this.etaMinutes,
    required this.proposedPrice,
    this.message,
    required this.status,
    required this.createdAt,
  });

  factory TaskApplication.fromJson(Map<String, dynamic> json) {
    // ... parsing logic
  }
}
```

### 3.2 Modyfikacja modelu `Task`

**Plik**: `mobile/lib/features/client/models/task.dart`

- Dodać `int applicationCount` (liczba zgłoszeń)
- Dodać `int maxApplications` (limit)

---

## Faza 4: Mobile - Provider i API

### 4.1 Nowy provider `taskApplicationsProvider`

**Plik**: `mobile/lib/core/providers/task_provider.dart` (rozszerzenie)

```dart
class TaskApplicationsState {
  final List<TaskApplication> applications;
  final bool isLoading;
  final String? error;
}

final taskApplicationsProvider = StateNotifierProvider.family<
    TaskApplicationsNotifier, TaskApplicationsState, String>(
  (ref, taskId) => TaskApplicationsNotifier(ref, taskId),
);
```

**Metody**:
- `loadApplications(taskId)` - GET `/tasks/:id/applications`
- `acceptApplication(taskId, applicationId)` - PUT `/tasks/:id/applications/:appId/accept`
- `rejectApplication(taskId, applicationId)` - PUT `/tasks/:id/applications/:appId/reject`

### 4.2 Modyfikacja `availableTasksProvider` (strona wykonawcy)

- `acceptTask()` → zmienić na `applyForTask(taskId, proposedPrice, message?)`
- Endpoint: POST `/tasks/:id/apply` z body `{ proposedPrice, message? }`
- Po aplikacji: nie przenoś na active task screen (bo jeszcze nie jesteś wybrany)

### 4.3 Nowy provider `contractorApplicationsProvider`

- Lista moich zgłoszeń ze statusami
- GET `/contractor/applications`
- Real-time update przez WebSocket (accepted/rejected)

---

## Faza 5: Mobile - UI klienta (task tracking)

### 5.1 Modyfikacja `TaskTrackingScreen`

**Plik**: `mobile/lib/features/client/screens/task_tracking_screen.dart`

**Zmiana flow statusów**:
```
STARY: searching → accepted → confirmed → inProgress → completed (5 kroków)
NOWY:  applications → confirmed → inProgress → completed (4 kroki)
```

**Nowy widok "applications" (status CREATED)**:
- Header: "Zgłoszenia wykonawców" + licznik "X/5"
- Lista kart wykonawców (scrollowalna)
- Każda karta zawiera:
  - Avatar
  - Imię + verified badge
  - Opis wykonawcy pobrant z profilu wykonawcy
  - Rating (gwiazdki + liczba opinii)
  - Ukończone zlecenia
  - Odległość + ETA
  - **Proponowana cena** (wyróżniona, porównanie z budżetem klienta)
  - Opcjonalna wiadomość wykonawcy
  - Dwa buttony: "Akceptuj" (zielony) i "Odrzuć" (czerwony)
- Kliknięcie w kartę → bottom sheet z pełnym profilem (jak istniejący `_ContractorProfileSheet`)
- Empty state: "Czekamy na zgłoszenia wykonawców..." z animacją

**Uwaga**: Istniejący `ContractorSelectionScreen` (`mobile/lib/features/client/screens/contractor_selection_screen.dart`) ma już layout kart, sorting i profile sheet - można go zaadaptować jako bazę. Aktualnie używa mock data.

### 5.2 Nowy widget `ApplicationCard`

**Plik**: `mobile/lib/features/client/widgets/application_card.dart` (nowy)

- Avatar, imię, rating, completed tasks, distance/ETA
- Proponowana cena (duża, wyróżniona kolorem jeśli < budżetu klienta)
- Opcjonalna wiadomość (cytowany tekst)
- "Akceptuj" + "Odrzuć" buttony
- Tap na kartę → pełny profil w bottom sheet

---

## Faza 6: Mobile - UI wykonawcy

### 6.1 Modyfikacja `NearbyTaskCard`

**Plik**: `mobile/lib/features/contractor/widgets/nearby_task_card.dart`

- Button "Przyjmij" → "Zgłoś się"
- Po kliknięciu → dialog z:
  - Pole na proponowaną cenę (z budżetem klienta jako podpowiedź)
  - Opcjonalne pole na wiadomość (max 500 znaków)
  - Button "Wyślij zgłoszenie"

### 6.2 Nowy ekran "Moje zgłoszenia"

**Plik**: `mobile/lib/features/contractor/screens/my_applications_screen.dart` (nowy)

- Lista moich zgłoszeń z statusami (oczekuje, zaakceptowane, odrzucone)
- Real-time update statusów
- Możliwość wycofania (swipe)
- Dostęp z profilu wykonawcy lub nawigacji

### 6.3 Modyfikacja `ContractorTaskListScreen`

**Plik**: `mobile/lib/features/contractor/screens/contractor_task_list_screen.dart`

- Dodać tab lub badge pokazujący liczbę aktywnych zgłoszeń
- Oznaczyć zadania, na które już się zgłosiłem (żeby nie aplikować podwójnie)

---

## Faza 7: WebSocket integration (mobile)

**Plik**: `mobile/lib/core/services/websocket_service.dart`

Nowe listenery:
- `application:new` → odśwież listę aplikacji (klient)
- `application:accepted` → powiadomienie + nawigacja na active task (wykonawca)
- `application:rejected` → powiadomienie + aktualizacja statusu (wykonawca)
- `application:withdrawn` → odśwież listę (klient)
- `application:count` → aktualizacja licznika (klient)

---

## Edge Cases i reguły biznesowe

| Scenariusz | Zachowanie |
|------------|------------|
| Wykonawca próbuje aplikować 2x na ten sam task | Błąd 409 Conflict - Pop up "Aplikacja na to zlecenie juz została złożona" |
| Aplikacja gdy max osiągnięty (5/5) | Błąd 400 "Osiągnięto limit zgłoszeń" |
| Klient anuluje task z pending aplikacjami | Auto-reject wszystkich, powiadomienie |
| Wykonawca wycofuje się | Status → WITHDRAWN, miejsce się zwalnia (nowi mogą aplikować) |
| Klient akceptuje jednego | Reszta auto-rejected, powiadomienia push |
| Nikt nie aplikuje | Brak auto-timeout na MVP - klient może anulować ręcznie |
| Wykonawca z aktywnym taskiem aplikuje | Dozwolone - może mieć pending aplikacje + 1 aktywny task |
| Proponowana cena < minimum (35 PLN) | Błąd walidacji 400 |
| Proponowana cena > budżetu klienta | Dozwolone - klient decyduje czy warto |

---

## Pliki do zmodyfikowania (podsumowanie)

### Backend - nowe pliki:
- `backend/src/tasks/entities/task-application.entity.ts`
- `backend/src/tasks/dto/apply-task.dto.ts`

### Backend - modyfikacje:
- `backend/src/tasks/entities/task.entity.ts` - pole `maxApplications`
- `backend/src/tasks/tasks.module.ts` - rejestracja `TaskApplication`
- `backend/src/tasks/tasks.service.ts` - nowe metody + modyfikacja istniejących
- `backend/src/tasks/tasks.controller.ts` - nowe endpointy
- `backend/src/realtime/realtime.gateway.ts` - nowe eventy
- `backend/src/realtime/realtime.service.ts` - nowe typy eventów

### Mobile - nowe pliki:
- `mobile/lib/features/client/models/task_application.dart`
- `mobile/lib/features/client/widgets/application_card.dart`
- `mobile/lib/features/contractor/screens/my_applications_screen.dart`

### Mobile - modyfikacje:
- `mobile/lib/features/client/models/task.dart` - nowe pola
- `mobile/lib/features/client/screens/task_tracking_screen.dart` - widok aplikacji
- `mobile/lib/features/contractor/widgets/nearby_task_card.dart` - "Zgłoś się" + dialog
- `mobile/lib/features/contractor/screens/contractor_task_list_screen.dart` - badge/oznaczenia
- `mobile/lib/core/providers/task_provider.dart` - nowe providery
- `mobile/lib/core/services/websocket_service.dart` - nowe eventy
- `mobile/lib/core/router/routes.dart` - nowa trasa dla "Moje zgłoszenia"

---

## Kolejność implementacji

1. **Backend encja** - `TaskApplication` entity + modyfikacja Task entity
2. **Backend serwis** - nowe metody w `TasksService`
3. **Backend kontroler** - nowe endpointy + deprecation starych
4. **Backend WebSocket** - nowe eventy
5. **Mobile modele** - `TaskApplication` model + modyfikacja Task
6. **Mobile providery** - nowe state management
7. **Mobile UI klienta** - lista aplikacji w task tracking
8. **Mobile UI wykonawcy** - dialog zgłoszenia + moje zgłoszenia
9. **Testy** - unit + e2e dla nowych endpointów

---

## Weryfikacja / Testowanie

1. **Backend**: Uruchomić `npm run start:dev`, testować endpointy przez curl/Postman
2. **Scenariusz happy path**:
   - Klient tworzy task → task CREATED
   - 3 wykonawców aplikuje z różnymi cenami → GET applications zwraca 3
   - Klient odrzuca 1 → status REJECTED, count = 2
   - Klient akceptuje 1 → task CONFIRMED, contractorId ustawiony, pozostali REJECTED
   - Dalszy flow (start → complete → rate) bez zmian
3. **Scenariusz edge**: 6-ty wykonawca próbuje aplikować → 400 error
4. **WebSocket**: Sprawdzić real-time powiadomienia w logach
5. **Mobile**: `flutter run` i przetestować cały flow klient + wykonawca

---

## Diagram nowego flow

```
Klient                          System                         Wykonawcy
|                               |                              |
+-- POST /tasks                 |                              |
|   (Tworzy zlecenie)           +-- Status: CREATED            |
|                               |   maxApplications: 5         |
|                               |                              |
|                               +-- Notify contractors ------->|
|                               |   (WebSocket + push)         |
|                               |                              |
|                               |                              +-- POST /tasks/:id/apply
|                               |                              |   { proposedPrice, message? }
|                               |                              |
|   application:new <-----------+-- TaskApplication PENDING    |
|   (real-time update)          |                              |
|                               |                              +-- POST /tasks/:id/apply
|                               |                              |   (kolejny wykonawca)
|   application:new <-----------+-- TaskApplication PENDING    |
|                               |                              |
+-- GET /tasks/:id/applications |                              |
|   (Lista kandydatów)          |                              |
|                               |                              |
+-- PUT .../accept              |                              |
|   (Wybiera wykonawcę)        +-- Task: CONFIRMED            |
|                               |   contractorId: wybrany      |
|                               |   finalAmount: proposedPrice |
|                               |                              |
|                               +-- Auto-reject reszty ------->| application:rejected
|                               +-- Notify wybranego --------->| application:accepted
|                               |                              |
|                               |   (Dalej jak dotychczas)     |
|                               |                              +-- PUT /tasks/:id/start
|                               +-- Status: IN_PROGRESS        |
|                               |                              |
```
