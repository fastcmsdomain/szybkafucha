# Flow Wykonawcy - Obsługa Zlecenia

## 📋 Przegląd

Dokument opisuje pełny flow wykonawcy (contractor) w aplikacji mobilnej Szybka Fucha, od momentu przyjęcia zlecenia do jego zakończenia lub anulowania. Wszystkie operacje są zintegrowane z backend API.

---

## 🔄 Diagram Flow

```
[Ekran Główny Wykonawcy]
        ↓
[Przeglądanie dostępnych zleceń]
        ↓
[Akceptacja zlecenia] → PUT /tasks/:id/accept
        ↓
[Ustawienie aktywnego zlecenia w provider]
        ↓
[Nawigacja do ekranu aktywnego zlecenia]
        ↓
[Wyświetlenie szczegółów zlecenia] → GET /tasks/:id (jeśli potrzebne)
        ↓
        ├─→ [Rozpoczęcie zlecenia] → PUT /tasks/:id/start
        │         ↓
        │   [Status: IN_PROGRESS]
        │         ↓
        │   [Zakończenie zlecenia] → PUT /tasks/:id/complete
        │         ↓
        │   [Wyczyszczenie provider]
        │         ↓
        │   [Powrót do ekranu głównego]
        │
        └─→ [Anulowanie zlecenia] → PUT /tasks/:id/cancel
                  ↓
            [Wyczyszczenie provider]
                  ↓
            [Powrót do ekranu głównego]
```

---

## 📱 Szczegółowy Flow Krok po Kroku

### 1. Ekran Główny Wykonawcy (`contractor_home_screen.dart`)

**Lokalizacja:** `mobile/lib/features/contractor/screens/contractor_home_screen.dart`

**Stan początkowy:**
- Wykonawca widzi listę dostępnych zleceń
- Zlecenia są pobierane z backend przez `availableTasksProvider`
- Provider automatycznie ładuje zlecenia przy inicjalizacji

**Provider:** `availableTasksProvider` (z `task_provider.dart`)

---

### 2. Akceptacja Zlecenia

**Akcja:** Wykonawca klika przycisk "Przyjmij zlecenie" na karcie zlecenia

**Kod:**
```dart
// contractor_home_screen.dart - metoda _acceptTask()
Future<void> _acceptTask(ContractorTask task) async {
  try {
    // 1. Wywołanie API - akceptacja zlecenia
    final acceptedTask = await ref
        .read(availableTasksProvider.notifier)
        .acceptTask(task.id);
    
    // 2. Ustawienie zlecenia jako aktywnego w provider
    ref.read(activeTaskProvider.notifier).setTask(acceptedTask);
    
    // 3. Nawigacja do ekranu aktywnego zlecenia
    context.push(Routes.contractorTask(task.id));
  } catch (e) {
    // Obsługa błędu
  }
}
```

**API Call:**
- **Endpoint:** `PUT /api/v1/tasks/:id/accept`
- **Method:** `availableTasksProvider.notifier.acceptTask(taskId)`
- **Akcja:** 
  - Wywołuje `PUT /tasks/:id/accept` na backend
  - Backend zmienia status zlecenia na `accepted`
  - Backend przypisuje `contractorId` do zlecenia
  - Zlecenie jest usuwane z listy dostępnych zleceń
  - Zwraca zaktualizowane zlecenie

**Provider Update:**
- `activeTaskProvider.notifier.setTask(acceptedTask)` - ustawia zlecenie jako aktywne
- Zlecenie jest teraz dostępne w całej aplikacji przez `activeTaskProvider`

**Rezultat:**
- Zlecenie ma status `accepted`
- Zlecenie jest przypisane do wykonawcy
- Wykonawca jest przekierowany do ekranu aktywnego zlecenia

---

### 3. Ekran Aktywnego Zlecenia (`active_task_screen.dart`)

**Lokalizacja:** `mobile/lib/features/contractor/screens/active_task_screen.dart`

**Inicjalizacja:**
```dart
@override
void initState() {
  super.initState();
  // Sprawdzenie czy zlecenie jest już w provider
  Future.microtask(() {
    final currentTask = ref.read(activeTaskProvider).task;
    if (currentTask == null || currentTask.id != widget.taskId) {
      // Pobranie zlecenia z backend jeśli nie ma w provider
      ref.read(activeTaskProvider.notifier).fetchTask(widget.taskId);
    } else {
      // Synchronizacja lokalnego statusu
      setState(() {
        _currentStatus = currentTask.status;
      });
    }
  });
}
```

**Pobieranie zlecenia z backend:**
- **Metoda:** `fetchTask(taskId)` w `ActiveTaskNotifier`
- **API Call:** `GET /api/v1/tasks/:id`
- **Użycie:** Wywoływane jeśli zlecenie nie jest w provider lub ID się nie zgadza

**Wyświetlane informacje:**
- Szczegóły zlecenia (kategoria, adres, klient)
- Status zlecenia
- Mapa z lokalizacją
- Przyciski akcji w zależności od statusu

---

### 4. Rozpoczęcie Zlecenia

**Akcja:** Wykonawca klika przycisk "Wyruszyłem" na ekranie aktywnego zlecenia

**Kod:**
```dart
// active_task_screen.dart
Future<void> _handleStartTask() async {
  setState(() => _isUpdating = true);
  
  try {
    // Wywołanie API - rozpoczęcie zlecenia
    await ref.read(activeTaskProvider.notifier).updateStatus(
      widget.taskId,
      'start',
    );
    
    setState(() {
      _currentStatus = ContractorTaskStatus.inProgress;
      _isUpdating = false;
    });
  } catch (e) {
    // Obsługa błędu
  }
}
```

**API Call:**
- **Endpoint:** `PUT /api/v1/tasks/:id/start`
- **Method:** `activeTaskProvider.notifier.updateStatus(taskId, 'start')`
- **Akcja:**
  - Wywołuje `PUT /tasks/:id/start` na backend
  - Backend zmienia status zlecenia na `in_progress`
  - Backend ustawia `startedAt` timestamp
  - Klient otrzymuje powiadomienie o rozpoczęciu zlecenia

**Provider Update:**
- Status zlecenia w provider jest aktualizowany na `inProgress`
- `startedAt` jest ustawiane na aktualny czas

**Rezultat:**
- Status zlecenia: `in_progress`
- Przycisk "Wyruszyłem" jest ukryty
- Dostępne są opcje: "Zakończ zlecenie" lub "Anuluj"

---

### 5. Zakończenie Zlecenia

**Akcja:** Wykonawca klika "Zakończ zlecenie" i przechodzi do ekranu zakończenia

**Ekran zakończenia:** `task_completion_screen.dart`

**Kroki:**
1. Wykonawca może dodać zdjęcia potwierdzające wykonanie (opcjonalne)
2. Wykonawca może dodać notatki (opcjonalne)
3. Wykonawca klika "Zakończ zlecenie"

**Kod:**
```dart
// task_completion_screen.dart
Future<void> _submitCompletion() async {
  setState(() => _isSubmitting = true);
  
  try {
    // Konwersja zdjęć na URL (w produkcji - upload do storage)
    final photoUrls = _photos.map((photo) => photo.path).toList();
    
    // Wywołanie API - zakończenie zlecenia
    await ref.read(activeTaskProvider.notifier).completeTask(
      widget.taskId,
      photos: photoUrls.isNotEmpty ? photoUrls : null,
    );
    
    // Wyczyszczenie aktywnego zlecenia z provider
    ref.read(activeTaskProvider.notifier).clearTask();
    
    // Powrót do ekranu głównego
    if (mounted) {
      context.go(Routes.contractorHome);
    }
  } catch (e) {
    // Obsługa błędu
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

**API Call:**
- **Endpoint:** `PUT /api/v1/tasks/:id/complete`
- **Method:** `activeTaskProvider.notifier.completeTask(taskId, photos: ...)`
- **Request Body:**
  ```json
  {
    "completionPhotos": ["url1", "url2"] // opcjonalne
  }
  ```
- **Akcja:**
  - Wywołuje `PUT /tasks/:id/complete` na backend
  - Backend zmienia status zlecenia na `completed`
  - Backend ustawia `completedAt` timestamp
  - Backend zapisuje zdjęcia potwierdzające (jeśli podane)
  - Backend oblicza `finalAmount` i `commissionAmount`
  - Klient otrzymuje powiadomienie o zakończeniu zlecenia

**Provider Update:**
- Status zlecenia w provider jest aktualizowany na `completed`
- `completedAt` jest ustawiane na aktualny czas
- **Provider jest czyszczony:** `clearTask()` - zlecenie nie jest już aktywne

**Rezultat:**
- Status zlecenia: `completed`
- Zlecenie jest zakończone
- Wykonawca wraca do ekranu głównego
- Klient może teraz potwierdzić zlecenie i ocenić wykonawcę

---

### 6. Anulowanie Zlecenia

**Akcja:** Wykonawca klika "Anuluj zlecenie" na ekranie aktywnego zlecenia

**Kod:**
```dart
// active_task_screen.dart
Future<void> _handleCancelTask() async {
  // Pokazanie dialogu potwierdzenia
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Anulować zlecenie?'),
      content: Text('Czy na pewno chcesz anulować to zlecenie?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Nie'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Tak, anuluj'),
        ),
      ],
    ),
  );
  
  if (confirmed == true) {
    setState(() => _isUpdating = true);
    
    try {
      // Wywołanie API - anulowanie zlecenia
      await ref.read(activeTaskProvider.notifier).updateStatus(
        widget.taskId,
        'cancel',
      );
      
      // Wyczyszczenie aktywnego zlecenia z provider
      ref.read(activeTaskProvider.notifier).clearTask();
      
      // Powrót do ekranu głównego
      if (mounted) {
        context.go(Routes.contractorHome);
      }
    } catch (e) {
      // Obsługa błędu
    } finally {
      setState(() => _isUpdating = false);
    }
  }
}
```

**API Call:**
- **Endpoint:** `PUT /api/v1/tasks/:id/cancel`
- **Method:** `activeTaskProvider.notifier.updateStatus(taskId, 'cancel')`
- **Request Body (opcjonalne):**
  ```json
  {
    "reason": "Powód anulowania" // opcjonalne
  }
  ```
- **Akcja:**
  - Wywołuje `PUT /tasks/:id/cancel` na backend
  - Backend zmienia status zlecenia na `cancelled`
  - Backend ustawia `cancelledAt` timestamp
  - Backend zapisuje powód anulowania (jeśli podany)
  - Klient otrzymuje powiadomienie o anulowaniu zlecenia
  - Zlecenie wraca do puli dostępnych zleceń (status `created`)

**Provider Update:**
- Status zlecenia w provider jest aktualizowany na `cancelled`
- `cancelledAt` jest ustawiane na aktualny czas
- **Provider jest czyszczony:** `clearTask()` - zlecenie nie jest już aktywne

**Rezultat:**
- Status zlecenia: `cancelled`
- Zlecenie jest anulowane
- Wykonawca wraca do ekranu głównego
- Zlecenie może być ponownie przyjęte przez innego wykonawcę

---

## 🔧 Komponenty Techniczne

### Providers

#### 1. `availableTasksProvider`
- **Typ:** `StateNotifierProvider<AvailableTasksNotifier, AvailableTasksState>`
- **Zakres:** Lista dostępnych zleceń dla wykonawcy
- **Metody:**
  - `loadTasks()` - pobiera dostępne zlecenia z backend
  - `acceptTask(taskId)` - akceptuje zlecenie (PUT /tasks/:id/accept)
  - `refresh()` - odświeża listę zleceń

#### 2. `activeTaskProvider`
- **Typ:** `StateNotifierProvider<ActiveTaskNotifier, ActiveTaskState>`
- **Zakres:** Aktualnie aktywne zlecenie wykonawcy
- **Metody:**
  - `setTask(task)` - ustawia zlecenie jako aktywne
  - `fetchTask(taskId)` - pobiera zlecenie z backend (GET /tasks/:id)
  - `updateStatus(taskId, action)` - aktualizuje status (PUT /tasks/:id/{action})
  - `completeTask(taskId, photos)` - kończy zlecenie (PUT /tasks/:id/complete)
  - `clearTask()` - czyści aktywne zlecenie

### API Endpoints

| Endpoint | Method | Opis | Używane przez |
|----------|--------|------|----------------|
| `/tasks` | GET | Lista dostępnych zleceń | `availableTasksProvider.loadTasks()` |
| `/tasks/:id` | GET | Szczegóły zlecenia | `activeTaskProvider.fetchTask()` |
| `/tasks/:id/accept` | PUT | Akceptacja zlecenia | `availableTasksProvider.acceptTask()` |
| `/tasks/:id/start` | PUT | Rozpoczęcie zlecenia | `activeTaskProvider.updateStatus('start')` |
| `/tasks/:id/complete` | PUT | Zakończenie zlecenia | `activeTaskProvider.completeTask()` |
| `/tasks/:id/cancel` | PUT | Anulowanie zlecenia | `activeTaskProvider.updateStatus('cancel')` |

### Statusy Zlecenia

| Status | Opis | Kiedy |
|--------|------|-------|
| `created` | Nowe zlecenie | Po utworzeniu przez klienta |
| `accepted` | Przyjęte przez wykonawcę | Po akceptacji |
| `in_progress` | W trakcie realizacji | Po rozpoczęciu przez wykonawcę |
| `completed` | Zakończone | Po zakończeniu przez wykonawcę |
| `cancelled` | Anulowane | Po anulowaniu przez klienta lub wykonawcę |

---

## 📊 Przykładowy Flow z Kodem

### Scenariusz: Pełny cykl zlecenia

```dart
// 1. Wykonawca widzi dostępne zlecenia
final availableTasks = ref.watch(availableTasksProvider);
// Provider automatycznie ładuje zlecenia: GET /tasks

// 2. Wykonawca akceptuje zlecenie
await ref.read(availableTasksProvider.notifier).acceptTask('task-123');
// API: PUT /tasks/task-123/accept
// Provider: activeTaskProvider.setTask(acceptedTask)

// 3. Nawigacja do ekranu aktywnego zlecenia
context.push(Routes.contractorTask('task-123'));

// 4. Ekran sprawdza czy zlecenie jest w provider
final activeTask = ref.watch(activeTaskProvider).task;
if (activeTask == null) {
  // Pobiera z backend jeśli nie ma
  await ref.read(activeTaskProvider.notifier).fetchTask('task-123');
  // API: GET /tasks/task-123
}

// 5. Wykonawca rozpoczyna zlecenie
await ref.read(activeTaskProvider.notifier).updateStatus('task-123', 'start');
// API: PUT /tasks/task-123/start
// Status: accepted → in_progress

// 6. Wykonawca kończy zlecenie
await ref.read(activeTaskProvider.notifier).completeTask(
  'task-123',
  photos: ['photo1.jpg', 'photo2.jpg'],
);
// API: PUT /tasks/task-123/complete
// Status: in_progress → completed

// 7. Wyczyszczenie provider i powrót
ref.read(activeTaskProvider.notifier).clearTask();
context.go(Routes.contractorHome);
```

---

## ✅ Checklist Integracji

- [x] `fetchTask(taskId)` - pobieranie zlecenia z backend
- [x] `activeTaskProvider` - zarządzanie aktywnym zleceniem
- [x] Ekran aktywnego zlecenia używa provider zamiast mocków
- [x] Przycisk "Wyruszyłem" wywołuje API (PUT /tasks/:id/start)
- [x] Ekran zakończenia wywołuje API (PUT /tasks/:id/complete)
- [x] Anulowanie zlecenia wywołuje API (PUT /tasks/:id/cancel)
- [x] Provider jest czyszczony po zakończeniu/anulowaniu
- [x] Ustawienie aktywnego zlecenia po akceptacji

---

## 🐛 Obsługa Błędów

### Błąd podczas akceptacji zlecenia
- Zlecenie może być już przyjęte przez innego wykonawcę
- Zlecenie może być anulowane przez klienta
- **Obsługa:** Wyświetlenie komunikatu błędu, odświeżenie listy zleceń

### Błąd podczas aktualizacji statusu
- Zlecenie może być już w innym statusie
- Brak połączenia z internetem
- **Obsługa:** Wyświetlenie komunikatu błędu, możliwość ponowienia próby

### Błąd podczas zakończenia zlecenia
- Problem z uploadem zdjęć
- Błąd walidacji na backend
- **Obsługa:** Wyświetlenie komunikatu błędu, możliwość ponowienia bez zdjęć

---

## 📝 Notatki Techniczne

1. **State Management:** Używamy Riverpod do zarządzania stanem
2. **API Client:** Wszystkie wywołania API przechodzą przez `ApiClient`
3. **Error Handling:** Błędy są obsługiwane lokalnie w każdym ekranie
4. **Navigation:** Używamy `go_router` do nawigacji
5. **Provider Lifecycle:** Provider jest czyszczony po zakończeniu/anulowaniu zlecenia

---

## 🔄 Następne Kroki

- [ ] Dodanie WebSocket do real-time updates statusu zlecenia
- [ ] Dodanie powiadomień push dla zmian statusu
- [ ] Implementacja uploadu zdjęć do cloud storage
- [ ] Dodanie możliwości edycji zlecenia przed rozpoczęciem
- [ ] Implementacja systemu ocen po zakończeniu zlecenia
