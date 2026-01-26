# Proces Tworzenia i Odbierania Zleceń

## Spis Treści
1. [Diagram Przepływu](#diagram-przepływu)
2. [Proces Tworzenia Zlecenia (Zleceniodawca)](#proces-tworzenia-zlecenia-zleceniodawca)
3. [Proces Odbierania Zlecenia (Zleceniobiorca)](#proces-odbierania-zlecenia-zleceniobiorca)
4. [Cykl Życia Zlecenia](#cykl-życia-zlecenia)
5. [Komunikacja między stronami](#komunikacja-między-stronami)
6. [Aktualny Stan Implementacji](#aktualny-stan-implementacji)

---

## Diagram Przepływu

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           ZLECENIODAWCA (Klient)                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   1. TWORZENIE ZLECENIA                                                      │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │  📝 Wybierz kategorię (Paczki, Zakupy, Kolejki, Montaż, itd.)       │  │
│   │  📝 Opisz zadanie (min. 10 znaków)                                   │  │
│   │  📍 Podaj lokalizację (GPS lub adres)                                │  │
│   │  💰 Ustal budżet (30-500 PLN)                                        │  │
│   │  ⏰ Wybierz termin (Teraz lub zaplanuj)                              │  │
│   │  ✅ Podsumowanie i potwierdzenie                                     │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                               │                                              │
│                               ▼                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │  📤 POST /api/v1/tasks                                               │  │
│   │  → Zlecenie zapisane w bazie danych                                  │  │
│   │  → Status: CREATED (utworzone)                                       │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                │ WebSocket: new_task_nearby
                                │ Push Notification
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        BACKEND (Serwer NestJS)                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   2. MATCHOWANIE WYKONAWCÓW                                                  │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │  🔍 Znajdź wykonawców:                                               │  │
│   │     - Online (isOnline = true)                                       │  │
│   │     - Zweryfikowani (kycStatus = VERIFIED)                           │  │
│   │     - Pasująca kategoria                                             │  │
│   │     - W promieniu 20km od lokalizacji zlecenia                       │  │
│   │                                                                      │  │
│   │  📊 Oblicz ranking (score):                                          │  │
│   │     Score = (ocena × 40%) + (ukończenia × 30%) + (bliskość × 30%)   │  │
│   │                                                                      │  │
│   │  📤 Wyślij powiadomienie do TOP 5 wykonawców                        │  │
│   │     - WebSocket (jeśli online w aplikacji)                           │  │
│   │     - Push Notification (jeśli offline)                              │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ZLECENIOBIORCA (Wykonawca)                            │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   3. ODBIÓR ZLECENIA                                                         │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │  🔔 Otrzymuje alert o nowym zleceniu                                 │  │
│   │  ⏱️ 45 sekund na decyzję                                            │  │
│   │                                                                      │  │
│   │  Widzi:                                                              │  │
│   │  - Kategoria i opis                                                  │  │
│   │  - Lokalizacja i odległość                                           │  │
│   │  - Cena (ile może zarobić)                                           │  │
│   │  - Informacje o kliencie (ocena)                                     │  │
│   │                                                                      │  │
│   │  [PRZYJMIJ] lub [ODRZUĆ]                                             │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                               │                                              │
│                               ▼                                              │
│   ┌──────────────────────────────────────────────────────────────────────┐  │
│   │  📤 PUT /api/v1/tasks/:id/accept                                     │  │
│   │  → Status: ACCEPTED (zaakceptowane)                                  │  │
│   │  → Zlecenie przypisane do wykonawcy                                  │  │
│   └──────────────────────────────────────────────────────────────────────┘  │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
                                │
                                │ WebSocket: task:status
                                ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                           REALIZACJA ZLECENIA                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│   4. WYKONANIE PRACY                                                         │
│                                                                              │
│   WYKONAWCA:                          ZLECENIODAWCA:                         │
│   ┌────────────────────────┐          ┌────────────────────────┐            │
│   │ "Wyruszyłem" →         │ ──────▶  │ Widzi status: W DRODZE │            │
│   │ Status: ON_THE_WAY     │          │ Widzi lokalizację GPS  │            │
│   └────────────────────────┘          └────────────────────────┘            │
│              │                                   │                           │
│              ▼                                   ▼                           │
│   ┌────────────────────────┐          ┌────────────────────────┐            │
│   │ "Jestem na miejscu" →  │ ──────▶  │ Status: NA MIEJSCU     │            │
│   │ Status: ARRIVED        │          │ Może napisać w chacie  │            │
│   └────────────────────────┘          └────────────────────────┘            │
│              │                                   │                           │
│              ▼                                   ▼                           │
│   ┌────────────────────────┐          ┌────────────────────────┐            │
│   │ "Rozpoczynam pracę" →  │ ──────▶  │ Status: PRACA W TOKU   │            │
│   │ Status: IN_PROGRESS    │          │                        │            │
│   └────────────────────────┘          └────────────────────────┘            │
│              │                                   │                           │
│              ▼                                   ▼                           │
│   ┌────────────────────────┐          ┌────────────────────────┐            │
│   │ "Zakończ zlecenie" →   │ ──────▶  │ Status: ZAKOŃCZONE     │            │
│   │ Status: COMPLETED      │          │ Prośba o potwierdzenie │            │
│   │ + zdjęcia jako dowód   │          │                        │            │
│   └────────────────────────┘          └────────────────────────┘            │
│                                                  │                           │
│                                                  ▼                           │
│                                       ┌────────────────────────┐            │
│                                       │ [POTWIERDŹ WYKONANIE]  │            │
│                                       │ PUT /tasks/:id/confirm │            │
│                                       │ → Płatność uwolniona   │            │
│                                       │ → Ocena i napiwek      │            │
│                                       └────────────────────────┘            │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Proces Tworzenia Zlecenia (Zleceniodawca)

### Krok 1: Wybór Kategorii
Zleceniodawca wybiera jedną z 6 kategorii:

| Kategoria | Ikona | Cena Min | Cena Max | Czas Est. |
|-----------|-------|----------|----------|-----------|
| Paczki | 📦 | 30 PLN | 60 PLN | 30 min |
| Zakupy | 🛒 | 40 PLN | 80 PLN | 45 min |
| Kolejki | ⏳ | 50 PLN | 100 PLN | 60 min |
| Montaż | 🔧 | 80 PLN | 200 PLN | 90 min |
| Przeprowadzki | 🚚 | 100 PLN | 300 PLN | 120 min |
| Sprzątanie | 🧹 | 80 PLN | 250 PLN | 90 min |

### Krok 2: Opis Zadania
- Minimum 10 znaków
- Maximum 500 znaków
- Powinien zawierać szczegóły: co, gdzie, kiedy

**Przykład dobrego opisu:**
> "Proszę odebrać paczkę z paczkomatu InPost przy ul. Marszałkowskiej 100. Kod odbioru podam w wiadomości. Dostarczyć pod adres Złota 44, mieszkanie 12."

### Krok 3: Lokalizacja
Dwie opcje:
1. **Automatyczne GPS** - aplikacja pobiera aktualną lokalizację
2. **Ręczny adres** - wpisanie adresu w pole tekstowe

### Krok 4: Budżet
- Suwak z zakresem dla wybranej kategorii
- Sugerowana cena ustawiona domyślnie
- Minimum 30 PLN

### Krok 5: Termin
- **TERAZ** - zlecenie natychmiastowe
- **ZAPLANUJ** - wybór daty i godziny z kalendarzem

### Krok 6: Podsumowanie
Użytkownik widzi wszystkie dane przed zatwierdzeniem:
- Kategoria
- Opis
- Adres
- Budżet
- Termin

Po kliknięciu "Zamów pomocnika" → zlecenie trafia do systemu.

---

## Proces Odbierania Zlecenia (Zleceniobiorca)

### Warunki wstępne:
1. Wykonawca musi być **online** (toggle włączony)
2. Wykonawca musi być **zweryfikowany** (KYC completed)
3. Wykonawca musi mieć **pasującą kategorię** w profilu
4. Wykonawca musi być **w zasięgu** (domyślnie 20km)

### Otrzymanie Alertu

Gdy pojawi się nowe zlecenie, wykonawca widzi:

```
┌─────────────────────────────────────────┐
│         🔔 NOWE ZLECENIE!               │
│                                         │
│         💰 45 PLN                       │
│                                         │
│  📦 Paczki                              │
│  "Odbiór paczki z paczkomatu..."       │
│                                         │
│  📍 ul. Marszałkowska 100              │
│     2.3 km • ~8 min                     │
│                                         │
│  👤 Jan K. ⭐ 4.8                       │
│                                         │
│  ⏱️ Pozostało: 38 sekund               │
│  ████████████░░░░░░░░                   │
│                                         │
│  [  PRZYJMIJ ZLECENIE  ]               │
│  [      Odrzuć        ]                │
└─────────────────────────────────────────┘
```

### Po Akceptacji

1. Zlecenie zostaje przypisane do wykonawcy
2. Status zmienia się na `ACCEPTED`
3. Zleceniodawca otrzymuje powiadomienie
4. Wykonawca widzi ekran "Aktywne zlecenie"
5. Rozpoczyna się śledzenie lokalizacji

### Przebieg Realizacji

| Krok | Akcja Wykonawcy | Status | Widok Zleceniodawcy |
|------|-----------------|--------|---------------------|
| 1 | Klika "Wyruszyłem" | ON_THE_WAY | "Wykonawca w drodze" + mapa |
| 2 | Klika "Jestem na miejscu" | ARRIVED | "Wykonawca na miejscu" |
| 3 | Klika "Rozpoczynam pracę" | IN_PROGRESS | "Praca w toku" |
| 4 | Klika "Zakończ" + zdjęcia | COMPLETED | "Potwierdź wykonanie" |

---

## Cykl Życia Zlecenia

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
                    │ IN_PROGRESS │  ← Praca w toku
                    │(w realizacji)│
                    └──────┬──────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
    │  CANCELLED  │ │  COMPLETED  │ │  DISPUTED   │
    │ (anulowane) │ │ (ukończone) │ │   (spór)    │
    └─────────────┘ └──────┬──────┘ └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   RATED     │  ← Ocena wystawiona
                    │  (ocenione) │
                    └─────────────┘
```

### Statusy zlecenia:

| Status | Opis | Kto może zmienić |
|--------|------|------------------|
| `CREATED` | Nowe zlecenie, czeka na wykonawcę | System |
| `ACCEPTED` | Wykonawca przyjął zlecenie | Wykonawca |
| `IN_PROGRESS` | Praca w toku | Wykonawca |
| `COMPLETED` | Praca zakończona, czeka na potwierdzenie | Wykonawca |
| `CANCELLED` | Anulowane | Zleceniodawca/Wykonawca |
| `DISPUTED` | Spór - wymaga interwencji admina | Zleceniodawca |

---

## Komunikacja między stronami

### Chat (WebSocket)
- Dostępny po akceptacji zlecenia
- Wiadomości w czasie rzeczywistym
- Historia zapisywana w bazie danych

### Połączenie telefoniczne
- Dostępne po akceptacji
- Otwiera aplikację telefonu z numerem

### Powiadomienia Push
- Nowe zlecenie w pobliżu
- Zmiana statusu zlecenia
- Nowa wiadomość w chacie
- Płatność otrzymana

---

## Aktualny Stan Implementacji

### ✅ Co działa:
- UI wszystkich ekranów (formularz, historia, dashboard)
- Backend API (wszystkie endpointy)
- Baza danych (schemat, relacje)
- Algorytm matchowania wykonawców
- WebSocket infrastruktura
- Push notifications (backend)

### ❌ Co NIE działa (mock data):
- Tworzenie zleceń NIE wywołuje API
- Historia zleceń pokazuje DEMO dane
- Dashboard wykonawcy pokazuje DEMO dane
- Akceptacja używa symulacji
- Chat pokazuje "wkrótce dostępne"

### 🔧 Co trzeba zrobić:
1. Stworzyć `TaskProvider` (Riverpod)
2. Podłączyć formularz do API
3. Podłączyć listę zleceń klienta do API
4. Podłączyć listę zleceń wykonawcy do API
5. Podłączyć akceptację do API
6. Włączyć real-time alerty

---

## Prowizja i Płatności

### Model biznesowy:
- **Prowizja platformy**: 17%
- **Wykonawca otrzymuje**: 83%

### Przykład:
```
Zlecenie: 100 PLN
├── Wykonawca: 83 PLN
└── Platforma: 17 PLN
```

### Przepływ płatności:
1. Zleceniodawca tworzy zlecenie → środki blokowane (hold)
2. Wykonawca akceptuje → środki w escrow
3. Zleceniodawca potwierdza → środki uwolnione
4. Wykonawca może wypłacić na konto

---

*Dokument zaktualizowany: 2026-01-22*
