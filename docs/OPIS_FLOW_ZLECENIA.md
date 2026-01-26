# Opis Aktualnego Flow Zlecenia między Wykonawcą a Zleceniodawcą

## 📋 Przegląd

Dokument opisuje kompletny przepływ zlecenia od momentu utworzenia przez zleceniodawcę do zakończenia i oceny, z uwzględnieniem wszystkich interakcji między stronami.

---

## 🔄 Diagram Przepływu - Pełny Cykl

```
┌─────────────────────────────────────────────────────────────────┐
│                    ZLECENIODAWCA (Klient)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. TWORZENIE ZLECENIA                                           │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ POST /api/v1/tasks                                       │   │
│  │ - Kategoria (paczki, zakupy, kolejki, montaż, itd.)     │   │
│  │ - Opis zadania (min. 10 znaków)                         │   │
│  │ - Lokalizacja (GPS: lat, lng + adres tekstowy)          │   │
│  │ - Budżet (30-500 PLN)                                    │   │
│  │ - Termin (teraz lub zaplanowany)                        │   │
│  └──────────────────────────────────────────────────────────┘   │
│                          │                                        │
│                          ▼                                        │
│  Status: CREATED                                                 │
│  → Zlecenie zapisane w bazie                                    │
│  → Backend znajduje dostępnych wykonawców                       │
│  → Powiadomienia push do TOP 5 wykonawców                      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ WebSocket / Push Notification
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    WYKONAWCA (Contractor)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  2. OTRZYMANIE POWIADOMIENIA                                     │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ 🔔 Alert o nowym zleceniu                               │   │
│  │ - Kategoria i opis                                       │   │
│  │ - Lokalizacja i odległość                               │   │
│  │ - Cena (budżet)                                         │   │
│  │ - Informacje o kliencie (ocena)                         │   │
│  │ - ⏱️ 45 sekund na decyzję                               │   │
│  └──────────────────────────────────────────────────────────┘   │
│                          │                                        │
│                          ▼                                        │
│  3. AKCEPTACJA ZLECENIA                                          │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │ PUT /api/v1/tasks/:id/accept                             │   │
│  │ → Status: ACCEPTED                                       │   │
│  │ → Zlecenie przypisane do wykonawcy                       │   │
│  │ → Płatność blokowana (escrow)                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                          │                                        │
│                          ▼                                        │
│  Status: ACCEPTED                                                 │
│  → Zleceniodawca otrzymuje powiadomienie                        │
│  → Wykonawca widzi ekran "Aktywne zlecenie"                     │
│  → Rozpoczyna się śledzenie lokalizacji                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                          │
                          │ WebSocket: task:status
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    REALIZACJA ZLECENIA                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  WYKONAWCA                          ZLECENIODAWCA               │
│  ┌──────────────────┐              ┌──────────────────┐       │
│  │ 4. ROZPOCZĘCIE   │              │ Widzi status:     │       │
│  │ PUT /tasks/:id/  │ ────────────▶ │ ACCEPTED          │       │
│  │ start            │              │ Widzi dane         │       │
│  │                  │              │ wykonawcy:         │       │
│  │ Status:          │              │ - Imię             │       │
│  │ IN_PROGRESS      │              │ - Zdjęcie         │       │
│  │                  │              │ - Opinie          │       │
│  │                  │              │ - Ocena            │       │
│  └──────────────────┘              └──────────────────┘       │
│           │                                 │                    │
│           │                                 │                    │
│           ▼                                 ▼                    │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │ Wykonawca widzi: │              │ Może:            │         │
│  │ - Mapę z trasą   │              │ - Zaakceptować   │         │
│  │ - Szczegóły      │              │   wykonawcę       │         │
│  │ - Chat/Call      │              │   (przed start)  │         │
│  │ - Przycisk       │              │ - Odrzucić       │         │
│  │   "Wyruszyłem"   │              │   wykonawcę      │         │
│  └──────────────────┘              └──────────────────┘         │
│           │                                 │                    │
│           │                                 │                    │
│           ▼                                 ▼                    │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │ 5. ZAKOŃCZENIE   │              │ Widzi status:     │         │
│  │ PUT /tasks/:id/  │ ────────────▶ │ COMPLETED         │         │
│  │ complete         │              │ Prośba o          │         │
│  │ + zdjęcia        │              │ potwierdzenie     │         │
│  │ (opcjonalne)     │              │                   │         │
│  │                  │              │                   │         │
│  │ Status:          │              │                   │         │
│  │ COMPLETED        │              │                   │         │
│  └──────────────────┘              └──────────────────┘         │
│           │                                 │                    │
│           │                                 │                    │
│           ▼                                 ▼                    │
│  ┌──────────────────┐              ┌──────────────────┐       │
│  │ Wykonawca:        │              │ 6. POTWIERDZENIE │       │
│  │ - Provider        │              │ PUT /tasks/:id/   │       │
│  │   wyczyszczony    │              │ confirm           │       │
│  │ - Powrót do       │              │                   │       │
│  │   ekranu głównego │              │ → Płatność        │       │
│  │                   │              │   uwolniona       │       │
│  │                   │              │ → finalAmount     │       │
│  │                   │              │ → commissionAmount│       │
│  └──────────────────┘              └──────────────────┘       │
│           │                                 │                    │
│           │                                 │                    │
│           ▼                                 ▼                    │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │                  │              │ 7. OCENA         │         │
│  │                  │              │ POST /tasks/:id/ │         │
│  │                  │              │ rate              │         │
│  │                  │              │                   │         │
│  │                  │              │ - Rating (1-5)    │         │
│  │                  │              │ - Komentarz       │         │
│  │                  │              │ - Napiwek         │         │
│  │                  │              │   (opcjonalny)    │         │
│  └──────────────────┘              └──────────────────┘         │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 📱 Szczegółowy Opis Kroków

### 1. Tworzenie Zlecenia (Zleceniodawca)

**Endpoint:** `POST /api/v1/tasks`

**Proces:**
1. Zleceniodawca wypełnia formularz:
   - Wybór kategorii (paczki, zakupy, kolejki, montaż, przeprowadzki, sprzątanie)
   - Opis zadania (min. 10 znaków)
   - Lokalizacja (GPS automatyczny lub ręczny adres)
   - Budżet (30-500 PLN, suwak z sugerowaną ceną)
   - Termin (TERAZ lub zaplanowany)

2. Po kliknięciu "Zamów pomocnika":
   - Wywołanie API `POST /tasks`
   - Backend waliduje dane
   - Zlecenie zapisane w bazie ze statusem `CREATED`
   - Backend uruchamia algorytm matchowania wykonawców

**Algorytm Matchowania:**
- Znajduje wykonawców:
  - Online (`isOnline = true`)
  - Zweryfikowanych (`kycStatus = VERIFIED`)
  - Z pasującą kategorią w profilu
  - W promieniu 20km od lokalizacji zlecenia
- Oblicza ranking (score):
  ```
  Score = (ocena × 40%) + (ukończenia × 30%) + (bliskość × 30%)
  ```
- Wysyła powiadomienia do TOP 5 wykonawców:
  - WebSocket (jeśli online w aplikacji)
  - Push Notification (jeśli offline)

**Status zlecenia:** `CREATED`

---

### 2. Otrzymanie Powiadomienia (Wykonawca)

**Proces:**
1. Wykonawca otrzymuje alert o nowym zleceniu:
   - Full-screen modal z szczegółami
   - Wyświetlane informacje:
     - 💰 Cena (budżet)
     - 📦 Kategoria
     - 📝 Opis zadania
     - 📍 Lokalizacja i odległość
     - 👤 Informacje o kliencie (ocena)
   - ⏱️ Timer: 45 sekund na decyzję
   - Przyciski: [PRZYJMIJ ZLECENIE] / [ODRZUĆ]

2. Jeśli wykonawca nie odpowie w 45 sekund:
   - Zlecenie trafia do następnego wykonawcy z listy
   - Powiadomienie wysyłane do kolejnego w rankingu

---

### 3. Akceptacja Zlecenia (Wykonawca)

**Endpoint:** `PUT /api/v1/tasks/:id/accept`

**Proces:**
1. Wykonawca klika "Przyjmij zlecenie"
2. Wywołanie API:
   - Backend sprawdza:
     - Czy wykonawca jest zweryfikowany
     - Czy zlecenie jest jeszcze dostępne (status `CREATED`)
     - Czy wykonawca nie ma już aktywnego zlecenia
   - Aktualizacja zlecenia:
     - Status: `CREATED` → `ACCEPTED`
     - `contractorId` = ID wykonawcy
     - `acceptedAt` = aktualny timestamp
   - Blokada płatności (escrow):
     - Środki klienta są blokowane
     - Czekają na potwierdzenie zakończenia

3. Po akceptacji:
   - Wykonawca:
     - Zlecenie ustawione jako aktywne w `activeTaskProvider`
     - Nawigacja do ekranu "Aktywne zlecenie"
     - Widzi szczegóły zlecenia i lokalizację
   - Zleceniodawca:
     - Otrzymuje powiadomienie o akceptacji
     - **Widzi dane wykonawcy:**
       - Imię
       - Zdjęcie (avatar)
       - Opinie (historia ocen)
       - Średnia ocena
     - **Może zaakceptować wykonawcę przed rozpoczęciem** (TODO - wymagane wg `/docs/to_do-now.md`)

**Status zlecenia:** `ACCEPTED`

---

### 4. Rozpoczęcie Zlecenia (Wykonawca)

**Endpoint:** `PUT /api/v1/tasks/:id/start`

**Proces:**
1. Wykonawca na ekranie aktywnego zlecenia:
   - Widzi mapę z lokalizacją zlecenia
   - Widzi szczegóły (kategoria, adres, klient)
   - Ma dostęp do chatu i telefonu
   - Przycisk "Wyruszyłem"

2. Po kliknięciu "Wyruszyłem":
   - Wywołanie API `PUT /tasks/:id/start`
   - Backend aktualizuje:
     - Status: `ACCEPTED` → `IN_PROGRESS`
     - `startedAt` = aktualny timestamp
   - Zleceniodawca otrzymuje powiadomienie:
     - Status zmieniony na "W trakcie"
     - Może śledzić lokalizację wykonawcy na mapie (jeśli zaimplementowane)

**Status zlecenia:** `IN_PROGRESS`

**Uwaga:** Wykonawca może również anulować zlecenie przed rozpoczęciem:
- `PUT /tasks/:id/cancel`
- Status: `ACCEPTED` → `CANCELLED`
- Zlecenie wraca do puli dostępnych

---

### 5. Zakończenie Zlecenia (Wykonawca)

**Endpoint:** `PUT /api/v1/tasks/:id/complete`

**Proces:**
1. Wykonawca kończy pracę:
   - Przechodzi do ekranu zakończenia (`task_completion_screen.dart`)
   - Może dodać zdjęcia potwierdzające (opcjonalne):
     - Upload zdjęć do cloud storage
     - URL-e zapisywane w `completionPhotos`
   - Może dodać notatki (opcjonalne)

2. Po kliknięciu "Zakończ zlecenie":
   - Wywołanie API `PUT /tasks/:id/complete`
   - Request body:
     ```json
     {
       "completionPhotos": ["url1", "url2"] // opcjonalne
     }
     ```
   - Backend:
     - Sprawdza czy status to `IN_PROGRESS`
     - Aktualizuje:
       - Status: `IN_PROGRESS` → `COMPLETED`
       - `completedAt` = aktualny timestamp
       - `completionPhotos` = zdjęcia (jeśli podane)
       - Oblicza `finalAmount` i `commissionAmount` (17% prowizji)
     - Wysyła powiadomienie do zleceniodawcy

3. Po zakończeniu:
   - Wykonawca:
     - `activeTaskProvider` jest czyszczony (`clearTask()`)
     - Powrót do ekranu głównego
     - Zlecenie zakończone, czeka na potwierdzenie klienta
   - Zleceniodawca:
     - Otrzymuje powiadomienie o zakończeniu
     - Widzi status: `COMPLETED`
     - Prośba o potwierdzenie wykonania

**Status zlecenia:** `COMPLETED`

---

### 6. Potwierdzenie Zakończenia (Zleceniodawca)

**Endpoint:** `PUT /api/v1/tasks/:id/confirm`

**Proces:**
1. Zleceniodawca widzi zlecenie ze statusem `COMPLETED`:
   - Może zobaczyć zdjęcia potwierdzające (jeśli wykonawca dodał)
   - Przycisk "Potwierdź wykonanie"

2. Po kliknięciu "Potwierdź wykonanie":
   - Wywołanie API `PUT /tasks/:id/confirm`
   - Backend:
     - Sprawdza czy status to `COMPLETED`
     - Uruchamia płatność:
       - Capture payment (uwolnienie środków z escrow)
       - Oblicza kwoty:
         - `finalAmount` = budżet zlecenia
         - `commissionAmount` = 17% z `finalAmount`
         - Wykonawca otrzymuje: `finalAmount - commissionAmount`
     - Aktualizuje status (pozostaje `COMPLETED`, ale płatność uwolniona)

3. Po potwierdzeniu:
   - Płatność przetworzona
   - Wykonawca otrzymuje środki (może wypłacić)
   - Zleceniodawca może teraz ocenić wykonawcę

---

### 7. Ocena i Napiwek (Zleceniodawca)

**Endpoint:** `POST /api/v1/tasks/:id/rate`

**Proces:**
1. Po potwierdzeniu zlecenia, zleceniodawca widzi ekran oceny:
   - 5 gwiazdek (rating 1-5)
   - Pole tekstowe na komentarz (opcjonalne, max 500 znaków)
   - Opcje napiwku: 0, 5, 10, 15, 20 PLN lub custom

2. Po wysłaniu oceny:
   - Wywołanie API `POST /tasks/:id/rate`
   - Request body:
     ```json
     {
       "rating": 5,
       "comment": "Świetna praca, bardzo polecam!"
     }
     ```
   - Backend:
     - Zapisuje ocenę w tabeli `ratings`
     - Aktualizuje średnią ocenę wykonawcy (`rating_avg`, `rating_count`)
   - Jeśli dodano napiwek:
     - Wywołanie `POST /tasks/:id/tip`
     - Napiwek idzie w 100% do wykonawcy (bez prowizji)

3. Po ocenie:
   - Zlecenie zakończone
   - Wykonawca otrzymuje ocenę i może zobaczyć komentarz
   - Zleceniodawca może zobaczyć zlecenie w historii

---

## 🔄 Statusy Zlecenia - State Machine

```
                    ┌─────────────┐
                    │   CREATED   │  ← Zleceniodawca tworzy
                    │  (utworzone)│
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  CANCELLED  │ │  ACCEPTED   │ │  (timeout)  │
    │ (anulowane) │ │(zaakceptow.)│ │ brak chętnych│
    └─────────────┘ └──────┬──────┘ └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ IN_PROGRESS │  ← Wykonawca rozpoczyna
                    │(w realizacji)│
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  CANCELLED  │ │  COMPLETED   │ │  DISPUTED   │
    │ (anulowane) │ │ (ukończone) │ │   (spór)    │
    └─────────────┘ └──────┬──────┘ └─────────────┘
                           │
                           │ (po potwierdzeniu)
                           ▼
                    ┌─────────────┐
                    │   RATED     │  ← Ocena wystawiona
                    │  (ocenione) │
                    └─────────────┘
```

### Tabela Statusów

| Status | Opis | Kto może zmienić | Następny status |
|--------|------|------------------|-----------------|
| `CREATED` | Nowe zlecenie, czeka na wykonawcę | System | `ACCEPTED`, `CANCELLED` |
| `ACCEPTED` | Wykonawca przyjął zlecenie | Wykonawca | `IN_PROGRESS`, `CANCELLED` |
| `IN_PROGRESS` | Praca w toku | Wykonawca | `COMPLETED`, `CANCELLED`, `DISPUTED` |
| `COMPLETED` | Praca zakończona, czeka na potwierdzenie | Wykonawca | `RATED` (po potwierdzeniu) |
| `CANCELLED` | Anulowane | Zleceniodawca/Wykonawca | - |
| `DISPUTED` | Spór - wymaga interwencji admina | Zleceniodawca | Rozwiązane przez admina |

---

## 💬 Komunikacja między Stronami

### Chat (WebSocket)
- **Dostępny:** Po akceptacji zlecenia (`ACCEPTED`)
- **Funkcjonalność:**
  - Wiadomości w czasie rzeczywistym
  - Historia zapisywana w bazie danych
  - Push notifications dla nowych wiadomości (jeśli app zamknięta)
- **Użycie:**
  - Przed rozpoczęciem: koordynacja, pytania
  - W trakcie: aktualizacje, instrukcje

### Połączenie Telefoniczne
- **Dostępne:** Po akceptacji zlecenia
- **Funkcjonalność:**
  - Maskowany numer (ochrona prywatności)
  - Otwiera aplikację telefonu z numerem
- **Użycie:**
  - Szybka komunikacja w trakcie realizacji

### Powiadomienia Push
- **Typy:**
  - Nowe zlecenie w pobliżu (wykonawca)
  - Zlecenie zaakceptowane (zleceniodawca)
  - Zmiana statusu zlecenia (obie strony)
  - Nowa wiadomość w chacie (obie strony)
  - Płatność otrzymana (wykonawca)

---

## 💰 Przepływ Płatności

### Model Biznesowy
- **Prowizja platformy:** 17%
- **Wykonawca otrzymuje:** 83%

### Przykład
```
Zlecenie: 100 PLN
├── Wykonawca: 83 PLN (83%)
└── Platforma: 17 PLN (17%)
```

### Kroki Płatności
1. **Tworzenie zlecenia:**
   - Zleceniodawca tworzy zlecenie
   - Środki blokowane (hold) na karcie

2. **Akceptacja zlecenia:**
   - Wykonawca akceptuje
   - Środki w escrow (zabezpieczone)

3. **Potwierdzenie zakończenia:**
   - Zleceniodawca potwierdza
   - Środki uwolnione:
     - 83 PLN → wykonawca (może wypłacić)
     - 17 PLN → platforma

4. **Napiwek (opcjonalny):**
   - 100% idzie do wykonawcy (bez prowizji)

---

## 🔧 Komponenty Techniczne

### Backend API Endpoints

| Endpoint | Method | Opis | Używane przez |
|----------|--------|------|---------------|
| `/tasks` | POST | Tworzenie zlecenia | Zleceniodawca |
| `/tasks` | GET | Lista zleceń (filtrowana) | Oboje |
| `/tasks/:id` | GET | Szczegóły zlecenia | Oboje |
| `/tasks/:id/accept` | PUT | Akceptacja zlecenia | Wykonawca |
| `/tasks/:id/start` | PUT | Rozpoczęcie zlecenia | Wykonawca |
| `/tasks/:id/complete` | PUT | Zakończenie zlecenia | Wykonawca |
| `/tasks/:id/confirm` | PUT | Potwierdzenie zakończenia | Zleceniodawca |
| `/tasks/:id/cancel` | PUT | Anulowanie zlecenia | Oboje |
| `/tasks/:id/rate` | POST | Ocena zlecenia | Zleceniodawca |
| `/tasks/:id/tip` | POST | Dodanie napiwku | Zleceniodawca |

### Mobile Providers (Riverpod)

#### Dla Wykonawcy:
- `availableTasksProvider` - lista dostępnych zleceń
- `activeTaskProvider` - aktualnie aktywne zlecenie

#### Dla Zleceniodawcy:
- `clientTasksProvider` - lista zleceń klienta
- `taskProvider` - zarządzanie zleceniami klienta

### WebSocket Events

| Event | Opis | Wysyłane do |
|-------|------|-------------|
| `new_task_nearby` | Nowe zlecenie w pobliżu | Wykonawca |
| `task:status` | Zmiana statusu zlecenia | Oboje |
| `task:accepted` | Zlecenie zaakceptowane | Zleceniodawca |
| `task:completed` | Zlecenie zakończone | Zleceniodawca |
| `message:new` | Nowa wiadomość w chacie | Oboje |

---

## ⚠️ Obsługa Błędów i Wyjątków

### Błędy podczas Akceptacji
- **Zlecenie już przyjęte:** Inny wykonawca zdążył zaakceptować
- **Zlecenie anulowane:** Klient anulował przed akceptacją
- **Wykonawca niezweryfikowany:** Brak weryfikacji KYC
- **Obsługa:** Wyświetlenie komunikatu błędu, odświeżenie listy

### Błędy podczas Aktualizacji Statusu
- **Zlecenie w innym statusie:** Próba zmiany nieprawidłowego statusu
- **Brak połączenia:** Problem z internetem
- **Obsługa:** Wyświetlenie komunikatu, możliwość ponowienia

### Błędy podczas Zakończenia
- **Problem z uploadem zdjęć:** Błąd cloud storage
- **Błąd walidacji:** Nieprawidłowe dane
- **Obsługa:** Możliwość ponowienia bez zdjęć lub z innymi

---

## 📝 Uwagi i TODO

### Zgodnie z `/docs/to_do-now.md`:

1. **Po akceptacji zlecenia przez wykonawcę:**
   - ✅ Zleceniodawca widzi dane wykonawcy (imię, zdjęcie, opinie)
   - ⚠️ **TODO:** Zleceniodawca musi mieć możliwość zaakceptowania wykonawcy przed rozpoczęciem zlecenia

2. **Aktualizacja ekranu wykonawcy:**
   - ⚠️ **TODO:** Aktualizacja statusów w UI wykonawcy

3. **Mapa:**
   - ⚠️ **TODO:** Implementacja śledzenia lokalizacji w czasie rzeczywistym

4. **Chat:**
   - ⚠️ **TODO:** Pełna implementacja chatu (obecnie "wkrótce dostępne")

5. **Telefon:**
   - ⚠️ **TODO:** Implementacja maskowanego numeru telefonu

---

## 📊 Przykładowy Scenariusz - Pełny Cykl

### Krok po Kroku:

1. **10:00** - Zleceniodawca tworzy zlecenie "Odbierz paczkę z paczkomatu"
   - Status: `CREATED`
   - Budżet: 45 PLN

2. **10:01** - Backend znajduje 5 wykonawców w promieniu 10km
   - Wysyła powiadomienia do TOP 5

3. **10:02** - Wykonawca #1 otrzymuje alert
   - Ma 45 sekund na decyzję
   - Klika "Przyjmij zlecenie"

4. **10:02** - Wykonawca akceptuje zlecenie
   - Status: `ACCEPTED`
   - Zleceniodawca widzi dane wykonawcy
   - Zleceniodawca akceptuje wykonawcę (TODO)

5. **10:15** - Wykonawca klika "Wyruszyłem"
   - Status: `IN_PROGRESS`
   - Zleceniodawca widzi status "W trakcie"

6. **10:45** - Wykonawca kończy pracę
   - Dodaje zdjęcie paczki
   - Klika "Zakończ zlecenie"
   - Status: `COMPLETED`

7. **10:46** - Zleceniodawca potwierdza wykonanie
   - `PUT /tasks/:id/confirm`
   - Płatność uwolniona: 45 PLN
   - Wykonawca otrzymuje: 37.35 PLN (83%)
   - Platforma: 7.65 PLN (17%)

8. **10:47** - Zleceniodawca ocenia wykonawcę
   - Rating: 5 gwiazdek
   - Komentarz: "Świetna praca!"
   - Napiwek: 5 PLN
   - Wykonawca otrzymuje dodatkowo 5 PLN (100% napiwku)

9. **10:48** - Zlecenie zakończone
   - Status: `RATED` (wewnętrznie)
   - Wykonawca może wypłacić środki
   - Ocena zapisana w profilu wykonawcy

---

## 🔄 Następne Kroki (TODO)

- [ ] Implementacja akceptacji wykonawcy przez zleceniodawcę przed startem
- [ ] Aktualizacja ekranu wykonawcy z pełnymi statusami
- [ ] Implementacja mapy z śledzeniem lokalizacji w czasie rzeczywistym
- [ ] Pełna implementacja chatu (WebSocket + UI)
- [ ] Implementacja maskowanego numeru telefonu
- [ ] Upload zdjęć do cloud storage (obecnie mock)
- [ ] Integracja Stripe Connect dla płatności
- [ ] System ocen i recenzji (pełna implementacja)

---

*Dokument zaktualizowany: 2026-01-22*
*Na podstawie analizy kodu i dokumentacji projektu Szybka Fucha*
