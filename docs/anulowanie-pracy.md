# Lista Testów - Anulowanie Zleceń / Task Cancellation Test List

## 📋 Spis Treści / Table of Contents

- [Wersja Polska](#wersja-polska)
- [English Version](#english-version)

---

# Wersja Polska

## Przegląd

Dokument zawiera kompleksową listę testów dla funkcjonalności anulowania zleceń we wszystkich możliwych scenariuszach, dla wszystkich ról użytkowników i wszystkich statusów zleceń.

## Role Użytkowników

- **Szef (Zleceniodawca / Client)**: Tworzy zlecenia, płaci za usługi
- **Pracownik (Zleceniobiorca / Contractor)**: Przyjmuje zlecenia, wykonuje pracę
- **Admin**: Operator platformy, zarządza sporami

## Statusy Zleceń

1. **CREATED** - Zlecenie utworzone, czeka na pracownika
2. **ACCEPTED** - Pracownik przyjął zlecenie
3. **CONFIRMED** - Szef potwierdził pracownika
4. **IN_PROGRESS** - Praca w trakcie realizacji
5. **COMPLETED** - Zlecenie zakończone
6. **CANCELLED** - Zlecenie anulowane
7. **DISPUTED** - Spór wymagający interwencji admina

---

## Testy Funkcjonalne - Szef (Client)

### TC-CL-001: Anulowanie zlecenia w statusie CREATED

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `CREATED`
- Zlecenie nie ma przypisanego pracownika

**Kroki:**
1. Szef otwiera listę swoich zleceń
2. Wybiera zlecenie ze statusem "Opublikowane"
3. Klika przycisk "Anuluj"
4. Potwierdza anulowanie w dialogu

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancelledAt` jest ustawione
- ✅ Powód anulowania jest zapisany (jeśli podany)
- ✅ Zlecenie znika z listy dostępnych zleceń dla pracowników
- ✅ Szef widzi zlecenie jako anulowane w historii
- ✅ Brak powiadomień (nie ma przypisanego pracownika)

---

### TC-CL-002: Anulowanie zlecenia w statusie ACCEPTED

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `ACCEPTED`
- Pracownik zaakceptował zlecenie

**Kroki:**
1. Szef otwiera szczegóły zlecenia
2. Widzi status "Zaakceptowane"
3. Klika przycisk "Anuluj"
4. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancelledAt` jest ustawione
- ✅ Pracownik otrzymuje powiadomienie push o anulowaniu
- ✅ Pracownik widzi zlecenie jako anulowane
- ✅ Płatność (jeśli była zablokowana) jest zwracana
- ✅ Pracownik może przyjąć inne zlecenia

---

### TC-CL-003: Anulowanie zlecenia w statusie CONFIRMED

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `CONFIRMED`
- Szef potwierdził pracownika

**Kroki:**
1. Szef otwiera szczegóły zlecenia
2. Widzi status "Potwierdzone"
3. Klika przycisk "Anuluj"
4. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancelledAt` jest ustawione
- ✅ Pracownik otrzymuje powiadomienie push
- ✅ Płatność jest zwracana (jeśli była zablokowana)
- ✅ Zlecenie nie jest już dostępne dla pracownika

---

### TC-CL-004: Anulowanie zlecenia w statusie IN_PROGRESS

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `IN_PROGRESS`
- Pracownik rozpoczął pracę

**Kroki:**
1. Szef otwiera ekran śledzenia zlecenia
2. Widzi status "W trakcie"
3. Klika przycisk "Anuluj"
4. Potwierdza anulowanie (może wymagać podania powodu)

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancelledAt` jest ustawione
- ✅ Powód anulowania jest zapisany
- ✅ Pracownik otrzymuje powiadomienie push
- ✅ Płatność jest zwracana
- ✅ Może być wymagana interwencja admina (w zależności od polityki)

---

### TC-CL-005: Próba anulowania zlecenia COMPLETED

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `COMPLETED`

**Kroki:**
1. Szef otwiera historię zleceń
2. Wybiera zakończone zlecenie
3. Próbuje kliknąć "Anuluj" (jeśli przycisk jest widoczny)

**Oczekiwany rezultat:**
- ✅ Przycisk "Anuluj" nie jest widoczny lub jest nieaktywny
- ✅ Jeśli API jest wywołane, zwraca błąd 400: "Cannot cancel completed task"
- ✅ Status zlecenia pozostaje `COMPLETED`

---

### TC-CL-006: Próba anulowania zlecenia CANCELLED

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `CANCELLED`

**Kroki:**
1. Szef otwiera historię zleceń
2. Wybiera anulowane zlecenie
3. Próbuje anulować ponownie

**Oczekiwany rezultat:**
- ✅ Przycisk "Anuluj" nie jest widoczny
- ✅ Jeśli API jest wywołane, zwraca błąd 400: "Cannot cancel already cancelled task"
- ✅ Status zlecenia pozostaje `CANCELLED`

---

### TC-CL-007: Anulowanie zlecenia z podaniem powodu

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `ACCEPTED` lub `IN_PROGRESS`

**Kroki:**
1. Szef otwiera szczegóły zlecenia
2. Klika "Anuluj"
3. W dialogu wpisuje powód: "Zmiana planów"
4. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancellationReason` zawiera "Zmiana planów"
- ✅ Powód jest widoczny w historii zleceń
- ✅ Pracownik widzi powód w powiadomieniu

---

### TC-CL-008: Anulowanie zlecenia bez podania powodu

**Warunki wstępne:**
- Szef jest zalogowany
- Zlecenie istnieje ze statusem `CREATED`

**Kroki:**
1. Szef otwiera szczegóły zlecenia
2. Klika "Anuluj"
3. Potwierdza bez wpisywania powodu

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancellationReason` jest `null`
- ✅ Anulowanie działa poprawnie (powód jest opcjonalny)

---

### TC-CL-009: Próba anulowania cudzego zlecenia

**Warunki wstępne:**
- Szef A jest zalogowany
- Zlecenie należy do Szefa B

**Kroki:**
1. Szef A próbuje wywołać API: `PUT /tasks/{taskId}/cancel`
2. Używa ID zlecenia należącego do innego szefa

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 403: "You cannot cancel this task"
- ✅ Status zlecenia nie zmienia się
- ✅ Zlecenie pozostaje niezmienione

---

## Testy Funkcjonalne - Pracownik (Contractor)

### TC-CO-001: Anulowanie zlecenia w statusie ACCEPTED

**Warunki wstępne:**
- Pracownik jest zalogowany
- Pracownik zaakceptował zlecenie (status `ACCEPTED`)
- Zlecenie jest przypisane do pracownika

**Kroki:**
1. Pracownik otwiera ekran aktywnego zlecenia
2. Widzi status "Zaakceptowane"
3. Klika przycisk "Anuluj zlecenie" w menu opcji
4. Potwierdza anulowanie w dialogu

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CREATED` (nie `CANCELLED`)
- ✅ Pole `contractorId` jest ustawione na `null`
- ✅ Pole `acceptedAt` jest ustawione na `null`
- ✅ Zlecenie wraca do puli dostępnych zleceń
- ✅ Szef otrzymuje powiadomienie: "Wykonawca zrezygnował ze zlecenia"
- ✅ Inni pracownicy mogą teraz zobaczyć i zaakceptować zlecenie
- ✅ Pracownik może przyjąć inne zlecenia

---

### TC-CO-002: Anulowanie zlecenia w statusie CONFIRMED

**Warunki wstępne:**
- Pracownik jest zalogowany
- Zlecenie istnieje ze statusem `CONFIRMED`
- Szef potwierdził pracownika

**Kroki:**
1. Pracownik otwiera ekran aktywnego zlecenia
2. Widzi status "Potwierdzone"
3. Klika "Anuluj zlecenie"
4. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CREATED`
- ✅ Pole `contractorId` jest ustawione na `null`
- ✅ Zlecenie wraca do puli dostępnych
- ✅ Szef otrzymuje powiadomienie
- ✅ Płatność (jeśli była zablokowana) pozostaje zablokowana dla nowego pracownika

---

### TC-CO-003: Anulowanie zlecenia w statusie IN_PROGRESS

**Warunki wstępne:**
- Pracownik jest zalogowany
- Zlecenie istnieje ze statusem `IN_PROGRESS`
- Pracownik rozpoczął pracę

**Kroki:**
1. Pracownik otwiera ekran aktywnego zlecenia
2. Widzi status "W trakcie"
3. Klika "Anuluj zlecenie"
4. Potwierdza anulowanie (może wymagać podania powodu)

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CREATED`
- ✅ Pole `contractorId` jest ustawione na `null`
- ✅ Pole `startedAt` jest ustawione na `null`
- ✅ Zlecenie wraca do puli dostępnych
- ✅ Szef otrzymuje powiadomienie z powodem (jeśli podany)
- ✅ Może wpłynąć na ocenę pracownika (w zależności od polityki)

---

### TC-CO-004: Próba anulowania zlecenia COMPLETED

**Warunki wstępne:**
- Pracownik jest zalogowany
- Zlecenie istnieje ze statusem `COMPLETED`

**Kroki:**
1. Pracownik otwiera historię zleceń
2. Wybiera zakończone zlecenie
3. Próbuje anulować

**Oczekiwany rezultat:**
- ✅ Przycisk "Anuluj" nie jest widoczny
- ✅ Jeśli API jest wywołane, zwraca błąd 400: "Cannot cancel completed task"
- ✅ Status zlecenia pozostaje `COMPLETED`

---

### TC-CO-005: Próba anulowania zlecenia, którego pracownik nie przyjął

**Warunki wstępne:**
- Pracownik A jest zalogowany
- Zlecenie jest przypisane do Pracownika B (status `ACCEPTED`)

**Kroki:**
1. Pracownik A próbuje wywołać API: `PUT /tasks/{taskId}/cancel`
2. Używa ID zlecenia przypisanego do innego pracownika

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 403: "You cannot cancel this task"
- ✅ Status zlecenia nie zmienia się
- ✅ Zlecenie pozostaje przypisane do Pracownika B

---

### TC-CO-006: Anulowanie zlecenia z podaniem powodu

**Warunki wstępne:**
- Pracownik jest zalogowany
- Zlecenie istnieje ze statusem `ACCEPTED`

**Kroki:**
1. Pracownik otwiera ekran aktywnego zlecenia
2. Klika "Anuluj zlecenie"
3. W dialogu wpisuje powód: "Nagła sytuacja rodzinna"
4. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CREATED`
- ✅ Powód jest zapisany (jeśli backend to obsługuje)
- ✅ Szef widzi powód w powiadomieniu
- ✅ Zlecenie wraca do puli dostępnych

---

## Testy Funkcjonalne - Admin

### TC-AD-001: Admin anuluje zlecenie w dowolnym statusie

**Warunki wstępne:**
- Admin jest zalogowany
- Zlecenie istnieje w dowolnym statusie (oprócz COMPLETED, CANCELLED)

**Kroki:**
1. Admin otwiera panel administracyjny
2. Wybiera zlecenie do anulowania
3. Klika "Anuluj zlecenie"
4. Podaje powód administracyjny
5. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Pole `cancelledAt` jest ustawione
- ✅ Powód administracyjny jest zapisany
- ✅ Szef otrzymuje powiadomienie
- ✅ Pracownik otrzymuje powiadomienie (jeśli był przypisany)
- ✅ Płatność jest zwracana (jeśli była zablokowana)

---

### TC-AD-002: Admin anuluje zlecenie w sporze (DISPUTED)

**Warunki wstępne:**
- Admin jest zalogowany
- Zlecenie istnieje ze statusem `DISPUTED`

**Kroki:**
1. Admin otwiera panel rozwiązywania sporów
2. Wybiera zlecenie w sporze
3. Klika "Anuluj zlecenie"
4. Podaje powód rozwiązania sporu
5. Potwierdza anulowanie

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Spór jest zamknięty
- ✅ Powód rozwiązania jest zapisany
- ✅ Obie strony otrzymują powiadomienia
- ✅ Płatność jest zwracana lub rozdzielana zgodnie z decyzją admina

---

## Testy Integracyjne

### TC-INT-001: Anulowanie zlecenia z zablokowaną płatnością

**Warunki wstępne:**
- Szef utworzył zlecenie i zablokował płatność
- Pracownik zaakceptował zlecenie (płatność w escrow)

**Kroki:**
1. Szef anuluje zlecenie w statusie `ACCEPTED`

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Płatność jest zwracana do szefa
- ✅ Pracownik nie otrzymuje płatności
- ✅ Transakcja jest odnotowana w historii płatności

---

### TC-INT-002: Anulowanie zlecenia podczas aktywnego chatu

**Warunki wstępne:**
- Zlecenie istnieje ze statusem `ACCEPTED`
- Szef i pracownik prowadzą aktywną rozmowę w chacie

**Kroki:**
1. Szef anuluje zlecenie podczas trwającej rozmowy

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Chat pozostaje dostępny do przeglądania (historia)
- ✅ Nowe wiadomości mogą być zablokowane (w zależności od polityki)
- ✅ Pracownik widzi powiadomienie o anulowaniu w chacie

---

### TC-INT-003: Anulowanie zlecenia z aktywnym śledzeniem lokalizacji

**Warunki wstępne:**
- Zlecenie istnieje ze statusem `IN_PROGRESS`
- Pracownik udostępnia swoją lokalizację w czasie rzeczywistym
- Szef śledzi lokalizację na mapie

**Kroki:**
1. Szef anuluje zlecenie podczas śledzenia

**Oczekiwany rezultat:**
- ✅ Status zlecenia zmienia się na `CANCELLED`
- ✅ Śledzenie lokalizacji jest zatrzymane
- ✅ Mapa pokazuje komunikat o anulowaniu
- ✅ Pracownik otrzymuje powiadomienie i może przestać udostępniać lokalizację

---

## Testy UI/UX

### TC-UI-001: Dialog potwierdzenia anulowania

**Warunki wstępne:**
- Użytkownik (szef lub pracownik) jest zalogowany
- Zlecenie może być anulowane

**Kroki:**
1. Użytkownik klika przycisk "Anuluj"
2. Otwiera się dialog potwierdzenia

**Oczekiwany rezultat:**
- ✅ Dialog wyświetla się poprawnie
- ✅ Zawiera tytuł: "Anulować zlecenie?"
- ✅ Zawiera opis konsekwencji
- ✅ Ma przyciski "Nie" i "Tak, anuluj"
- ✅ Przycisk "Tak, anuluj" jest wyróżniony kolorem (czerwony)
- ✅ Dialog można zamknąć klikając poza nim (opcjonalnie)

---

### TC-UI-002: Pole powodu anulowania

**Warunki wstępne:**
- Użytkownik otwiera dialog anulowania

**Kroki:**
1. Użytkownik klika "Anuluj"
2. Widzi pole tekstowe na powód (opcjonalne)

**Oczekiwany rezultat:**
- ✅ Pole powodu jest widoczne (jeśli wymagane w danym statusie)
- ✅ Placeholder: "Powód anulowania (opcjonalne)"
- ✅ Maksymalna długość tekstu jest ograniczona (np. 500 znaków)
- ✅ Można anulować bez podania powodu (jeśli opcjonalne)

---

### TC-UI-003: Wizualna reprezentacja anulowanego zlecenia

**Warunki wstępne:**
- Zlecenie zostało anulowane

**Kroki:**
1. Użytkownik otwiera historię zleceń
2. Widzi anulowane zlecenie

**Oczekiwany rezultat:**
- ✅ Status jest wyświetlony jako "Anulowane"
- ✅ Badge statusu ma odpowiedni kolor (szary)
- ✅ Ikona anulowania jest widoczna
- ✅ Data anulowania jest wyświetlona
- ✅ Powód anulowania jest widoczny (jeśli podany)

---

## Testy Wydajnościowe

### TC-PERF-001: Anulowanie wielu zleceń jednocześnie

**Warunki wstępne:**
- Szef ma 10 aktywnych zleceń

**Kroki:**
1. Szef anuluje wszystkie 10 zleceń szybko po sobie

**Oczekiwany rezultat:**
- ✅ Wszystkie anulowania są przetworzone poprawnie
- ✅ Czas odpowiedzi API < 500ms dla każdego żądania
- ✅ Brak błędów race condition
- ✅ Wszystkie powiadomienia są wysłane

---

## Testy Bezpieczeństwa

### TC-SEC-001: Próba anulowania bez autoryzacji

**Warunki wstępne:**
- Brak tokena JWT

**Kroki:**
1. Wywołanie API: `PUT /tasks/{taskId}/cancel` bez nagłówka Authorization

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 401: "Unauthorized"
- ✅ Status zlecenia nie zmienia się

---

### TC-SEC-002: Próba anulowania z nieprawidłowym tokenem

**Warunki wstępne:**
- Nieprawidłowy token JWT

**Kroki:**
1. Wywołanie API z nieprawidłowym tokenem

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 401: "Unauthorized"
- ✅ Status zlecenia nie zmienia się

---

### TC-SEC-003: Próba anulowania z wygasłym tokenem

**Warunki wstępne:**
- Wygasły token JWT

**Kroki:**
1. Wywołanie API z wygasłym tokenem

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 401: "Token expired"
- ✅ Status zlecenia nie zmienia się

---

## Testy Powiadomień

### TC-NOT-001: Powiadomienie push po anulowaniu przez szefa

**Warunki wstępne:**
- Pracownik ma włączone powiadomienia push
- Zlecenie jest przypisane do pracownika

**Kroki:**
1. Szef anuluje zlecenie

**Oczekiwany rezultat:**
- ✅ Pracownik otrzymuje powiadomienie push
- ✅ Tytuł: "Zlecenie anulowane"
- ✅ Treść zawiera tytuł zlecenia i powód (jeśli podany)
- ✅ Kliknięcie w powiadomienie otwiera szczegóły zlecenia

---

### TC-NOT-002: Powiadomienie push po anulowaniu przez pracownika

**Warunki wstępne:**
- Szef ma włączone powiadomienia push
- Pracownik zaakceptował zlecenie

**Kroki:**
1. Pracownik anuluje zlecenie

**Oczekiwany rezultat:**
- ✅ Szef otrzymuje powiadomienie push
- ✅ Tytuł: "Wykonawca zrezygnował ze zlecenia"
- ✅ Treść informuje, że zlecenie jest ponownie dostępne
- ✅ Kliknięcie w powiadomienie otwiera szczegóły zlecenia

---

### TC-NOT-003: Powiadomienie WebSocket w czasie rzeczywistym

**Warunki wstępne:**
- Szef i pracownik mają otwartą aplikację
- Oboje są połączeni z WebSocket

**Kroki:**
1. Szef anuluje zlecenie

**Oczekiwany rezultat:**
- ✅ Pracownik otrzymuje natychmiastowe powiadomienie przez WebSocket
- ✅ Status zlecenia aktualizuje się w UI bez odświeżania
- ✅ UI pokazuje komunikat o anulowaniu

---

## Testy Edge Cases

### TC-EDGE-001: Anulowanie zlecenia podczas aktualizacji statusu

**Warunki wstępne:**
- Zlecenie jest w trakcie zmiany statusu (np. z ACCEPTED na IN_PROGRESS)

**Kroki:**
1. Pracownik klika "Rozpocznij zadanie"
2. Równocześnie szef klika "Anuluj"

**Oczekiwany rezultat:**
- ✅ Jeden z żądań się powiedzie, drugi zwróci błąd
- ✅ Backend obsługuje race condition poprawnie
- ✅ Status końcowy jest spójny
- ✅ Użytkownik otrzymuje odpowiedni komunikat błędu

---

### TC-EDGE-002: Anulowanie zlecenia z bardzo długim powodem

**Warunki wstępne:**
- Użytkownik próbuje anulować z powodem > 500 znaków

**Kroki:**
1. Użytkownik wpisuje powód > 500 znaków
2. Próbuje anulować

**Oczekiwany rezultat:**
- ✅ Frontend ogranicza długość tekstu
- ✅ Jeśli tekst jest za długi, API zwraca błąd walidacji
- ✅ Komunikat błędu jest czytelny

---

### TC-EDGE-003: Anulowanie zlecenia z nieprawidłowym ID

**Warunki wstępne:**
- Użytkownik próbuje anulować zlecenie z nieprawidłowym UUID

**Kroki:**
1. Wywołanie API: `PUT /tasks/invalid-id/cancel`

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 400: "Invalid task ID format"
- ✅ Status żadnego zlecenia nie zmienia się

---

### TC-EDGE-004: Anulowanie nieistniejącego zlecenia

**Warunki wstępne:**
- Zlecenie nie istnieje w bazie danych

**Kroki:**
1. Wywołanie API: `PUT /tasks/{non-existent-uuid}/cancel`

**Oczekiwany rezultat:**
- ✅ API zwraca błąd 404: "Task not found"
- ✅ Status żadnego zlecenia nie zmienia się

---

## Podsumowanie Testów

### Statystyki

- **Całkowita liczba testów**: 40+
- **Testy dla Szefa**: 9
- **Testy dla Pracownika**: 6
- **Testy dla Admina**: 2
- **Testy Integracyjne**: 3
- **Testy UI/UX**: 3
- **Testy Wydajnościowe**: 1
- **Testy Bezpieczeństwa**: 3
- **Testy Powiadomień**: 3
- **Testy Edge Cases**: 4

### Priorytety

- **P0 (Krytyczne)**: TC-CL-001, TC-CL-002, TC-CO-001, TC-SEC-001, TC-SEC-002
- **P1 (Wysokie)**: TC-CL-003, TC-CL-004, TC-CO-002, TC-CO-003, TC-INT-001
- **P2 (Średnie)**: TC-CL-007, TC-CO-006, TC-UI-001, TC-NOT-001, TC-NOT-002
- **P3 (Niskie)**: TC-PERF-001, TC-EDGE-001, TC-EDGE-002

---

# English Version

## Overview

This document contains a comprehensive test list for task cancellation functionality in all possible scenarios, for all user roles and all task statuses.

## User Roles

- **Client (Szef)**: Creates tasks, pays for services
- **Contractor (Pracownik)**: Accepts tasks, performs work
- **Admin**: Platform operator, manages disputes

## Task Statuses

1. **CREATED** - Task created, waiting for contractor
2. **ACCEPTED** - Contractor accepted the task
3. **CONFIRMED** - Client confirmed the contractor
4. **IN_PROGRESS** - Work in progress
5. **COMPLETED** - Task completed
6. **CANCELLED** - Task cancelled
7. **DISPUTED** - Dispute requiring admin intervention

---

## Functional Tests - Client

### TC-CL-001: Cancel task in CREATED status

**Prerequisites:**
- Client is logged in
- Task exists with `CREATED` status
- Task has no assigned contractor

**Steps:**
1. Client opens their task list
2. Selects task with "Posted" status
3. Clicks "Cancel" button
4. Confirms cancellation in dialog

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancelledAt` field is set
- ✅ Cancellation reason is saved (if provided)
- ✅ Task disappears from available tasks list for contractors
- ✅ Client sees task as cancelled in history
- ✅ No notifications (no assigned contractor)

---

### TC-CL-002: Cancel task in ACCEPTED status

**Prerequisites:**
- Client is logged in
- Task exists with `ACCEPTED` status
- Contractor accepted the task

**Steps:**
1. Client opens task details
2. Sees "Accepted" status
3. Clicks "Cancel" button
4. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancelledAt` field is set
- ✅ Contractor receives push notification about cancellation
- ✅ Contractor sees task as cancelled
- ✅ Payment (if held) is refunded
- ✅ Contractor can accept other tasks

---

### TC-CL-003: Cancel task in CONFIRMED status

**Prerequisites:**
- Client is logged in
- Task exists with `CONFIRMED` status
- Client confirmed the contractor

**Steps:**
1. Client opens task details
2. Sees "Confirmed" status
3. Clicks "Cancel" button
4. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancelledAt` field is set
- ✅ Contractor receives push notification
- ✅ Payment is refunded (if held)
- ✅ Task is no longer available for contractor

---

### TC-CL-004: Cancel task in IN_PROGRESS status

**Prerequisites:**
- Client is logged in
- Task exists with `IN_PROGRESS` status
- Contractor started work

**Steps:**
1. Client opens task tracking screen
2. Sees "In Progress" status
3. Clicks "Cancel" button
4. Confirms cancellation (may require reason)

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancelledAt` field is set
- ✅ Cancellation reason is saved
- ✅ Contractor receives push notification
- ✅ Payment is refunded
- ✅ May require admin intervention (depending on policy)

---

### TC-CL-005: Attempt to cancel COMPLETED task

**Prerequisites:**
- Client is logged in
- Task exists with `COMPLETED` status

**Steps:**
1. Client opens task history
2. Selects completed task
3. Tries to click "Cancel" (if button is visible)

**Expected Result:**
- ✅ "Cancel" button is not visible or disabled
- ✅ If API is called, returns 400 error: "Cannot cancel completed task"
- ✅ Task status remains `COMPLETED`

---

### TC-CL-006: Attempt to cancel CANCELLED task

**Prerequisites:**
- Client is logged in
- Task exists with `CANCELLED` status

**Steps:**
1. Client opens task history
2. Selects cancelled task
3. Tries to cancel again

**Expected Result:**
- ✅ "Cancel" button is not visible
- ✅ If API is called, returns 400 error: "Cannot cancel already cancelled task"
- ✅ Task status remains `CANCELLED`

---

### TC-CL-007: Cancel task with reason provided

**Prerequisites:**
- Client is logged in
- Task exists with `ACCEPTED` or `IN_PROGRESS` status

**Steps:**
1. Client opens task details
2. Clicks "Cancel"
3. In dialog enters reason: "Change of plans"
4. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancellationReason` field contains "Change of plans"
- ✅ Reason is visible in task history
- ✅ Contractor sees reason in notification

---

### TC-CL-008: Cancel task without providing reason

**Prerequisites:**
- Client is logged in
- Task exists with `CREATED` status

**Steps:**
1. Client opens task details
2. Clicks "Cancel"
3. Confirms without entering reason

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancellationReason` field is `null`
- ✅ Cancellation works correctly (reason is optional)

---

### TC-CL-009: Attempt to cancel another client's task

**Prerequisites:**
- Client A is logged in
- Task belongs to Client B

**Steps:**
1. Client A tries to call API: `PUT /tasks/{taskId}/cancel`
2. Uses task ID belonging to another client

**Expected Result:**
- ✅ API returns 403 error: "You cannot cancel this task"
- ✅ Task status does not change
- ✅ Task remains unchanged

---

## Functional Tests - Contractor

### TC-CO-001: Cancel task in ACCEPTED status

**Prerequisites:**
- Contractor is logged in
- Contractor accepted task (status `ACCEPTED`)
- Task is assigned to contractor

**Steps:**
1. Contractor opens active task screen
2. Sees "Accepted" status
3. Clicks "Cancel task" button in options menu
4. Confirms cancellation in dialog

**Expected Result:**
- ✅ Task status changes to `CREATED` (not `CANCELLED`)
- ✅ `contractorId` field is set to `null`
- ✅ `acceptedAt` field is set to `null`
- ✅ Task returns to available tasks pool
- ✅ Client receives notification: "Contractor released the task"
- ✅ Other contractors can now see and accept the task
- ✅ Contractor can accept other tasks

---

### TC-CO-002: Cancel task in CONFIRMED status

**Prerequisites:**
- Contractor is logged in
- Task exists with `CONFIRMED` status
- Client confirmed the contractor

**Steps:**
1. Contractor opens active task screen
2. Sees "Confirmed" status
3. Clicks "Cancel task"
4. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CREATED`
- ✅ `contractorId` field is set to `null`
- ✅ Task returns to available pool
- ✅ Client receives notification
- ✅ Payment (if held) remains held for new contractor

---

### TC-CO-003: Cancel task in IN_PROGRESS status

**Prerequisites:**
- Contractor is logged in
- Task exists with `IN_PROGRESS` status
- Contractor started work

**Steps:**
1. Contractor opens active task screen
2. Sees "In Progress" status
3. Clicks "Cancel task"
4. Confirms cancellation (may require reason)

**Expected Result:**
- ✅ Task status changes to `CREATED`
- ✅ `contractorId` field is set to `null`
- ✅ `startedAt` field is set to `null`
- ✅ Task returns to available pool
- ✅ Client receives notification with reason (if provided)
- ✅ May affect contractor rating (depending on policy)

---

### TC-CO-004: Attempt to cancel COMPLETED task

**Prerequisites:**
- Contractor is logged in
- Task exists with `COMPLETED` status

**Steps:**
1. Contractor opens task history
2. Selects completed task
3. Tries to cancel

**Expected Result:**
- ✅ "Cancel" button is not visible
- ✅ If API is called, returns 400 error: "Cannot cancel completed task"
- ✅ Task status remains `COMPLETED`

---

### TC-CO-005: Attempt to cancel task not assigned to contractor

**Prerequisites:**
- Contractor A is logged in
- Task is assigned to Contractor B (status `ACCEPTED`)

**Steps:**
1. Contractor A tries to call API: `PUT /tasks/{taskId}/cancel`
2. Uses task ID assigned to another contractor

**Expected Result:**
- ✅ API returns 403 error: "You cannot cancel this task"
- ✅ Task status does not change
- ✅ Task remains assigned to Contractor B

---

### TC-CO-006: Cancel task with reason provided

**Prerequisites:**
- Contractor is logged in
- Task exists with `ACCEPTED` status

**Steps:**
1. Contractor opens active task screen
2. Clicks "Cancel task"
3. In dialog enters reason: "Family emergency"
4. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CREATED`
- ✅ Reason is saved (if backend supports it)
- ✅ Client sees reason in notification
- ✅ Task returns to available pool

---

## Functional Tests - Admin

### TC-AD-001: Admin cancels task in any status

**Prerequisites:**
- Admin is logged in
- Task exists in any status (except COMPLETED, CANCELLED)

**Steps:**
1. Admin opens admin panel
2. Selects task to cancel
3. Clicks "Cancel task"
4. Provides administrative reason
5. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ `cancelledAt` field is set
- ✅ Administrative reason is saved
- ✅ Client receives notification
- ✅ Contractor receives notification (if assigned)
- ✅ Payment is refunded (if held)

---

### TC-AD-002: Admin cancels task in DISPUTED status

**Prerequisites:**
- Admin is logged in
- Task exists with `DISPUTED` status

**Steps:**
1. Admin opens dispute resolution panel
2. Selects disputed task
3. Clicks "Cancel task"
4. Provides dispute resolution reason
5. Confirms cancellation

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ Dispute is closed
- ✅ Resolution reason is saved
- ✅ Both parties receive notifications
- ✅ Payment is refunded or split according to admin decision

---

## Integration Tests

### TC-INT-001: Cancel task with held payment

**Prerequisites:**
- Client created task and held payment
- Contractor accepted task (payment in escrow)

**Steps:**
1. Client cancels task in `ACCEPTED` status

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ Payment is refunded to client
- ✅ Contractor does not receive payment
- ✅ Transaction is recorded in payment history

---

### TC-INT-002: Cancel task during active chat

**Prerequisites:**
- Task exists with `ACCEPTED` status
- Client and contractor are having active conversation in chat

**Steps:**
1. Client cancels task during ongoing conversation

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ Chat remains accessible for viewing (history)
- ✅ New messages may be blocked (depending on policy)
- ✅ Contractor sees cancellation notification in chat

---

### TC-INT-003: Cancel task with active location tracking

**Prerequisites:**
- Task exists with `IN_PROGRESS` status
- Contractor is sharing location in real-time
- Client is tracking location on map

**Steps:**
1. Client cancels task during tracking

**Expected Result:**
- ✅ Task status changes to `CANCELLED`
- ✅ Location tracking is stopped
- ✅ Map shows cancellation message
- ✅ Contractor receives notification and can stop sharing location

---

## UI/UX Tests

### TC-UI-001: Cancellation confirmation dialog

**Prerequisites:**
- User (client or contractor) is logged in
- Task can be cancelled

**Steps:**
1. User clicks "Cancel" button
2. Confirmation dialog opens

**Expected Result:**
- ✅ Dialog displays correctly
- ✅ Contains title: "Cancel task?"
- ✅ Contains description of consequences
- ✅ Has "No" and "Yes, cancel" buttons
- ✅ "Yes, cancel" button is highlighted (red color)
- ✅ Dialog can be closed by clicking outside (optionally)

---

### TC-UI-002: Cancellation reason field

**Prerequisites:**
- User opens cancellation dialog

**Steps:**
1. User clicks "Cancel"
2. Sees text field for reason (optional)

**Expected Result:**
- ✅ Reason field is visible (if required in given status)
- ✅ Placeholder: "Cancellation reason (optional)"
- ✅ Maximum text length is limited (e.g., 500 characters)
- ✅ Can cancel without providing reason (if optional)

---

### TC-UI-003: Visual representation of cancelled task

**Prerequisites:**
- Task has been cancelled

**Steps:**
1. User opens task history
2. Sees cancelled task

**Expected Result:**
- ✅ Status is displayed as "Cancelled"
- ✅ Status badge has appropriate color (gray)
- ✅ Cancellation icon is visible
- ✅ Cancellation date is displayed
- ✅ Cancellation reason is visible (if provided)

---

## Performance Tests

### TC-PERF-001: Cancel multiple tasks simultaneously

**Prerequisites:**
- Client has 10 active tasks

**Steps:**
1. Client cancels all 10 tasks quickly one after another

**Expected Result:**
- ✅ All cancellations are processed correctly
- ✅ API response time < 500ms for each request
- ✅ No race condition errors
- ✅ All notifications are sent

---

## Security Tests

### TC-SEC-001: Attempt to cancel without authorization

**Prerequisites:**
- No JWT token

**Steps:**
1. Call API: `PUT /tasks/{taskId}/cancel` without Authorization header

**Expected Result:**
- ✅ API returns 401 error: "Unauthorized"
- ✅ Task status does not change

---

### TC-SEC-002: Attempt to cancel with invalid token

**Prerequisites:**
- Invalid JWT token

**Steps:**
1. Call API with invalid token

**Expected Result:**
- ✅ API returns 401 error: "Unauthorized"
- ✅ Task status does not change

---

### TC-SEC-003: Attempt to cancel with expired token

**Prerequisites:**
- Expired JWT token

**Steps:**
1. Call API with expired token

**Expected Result:**
- ✅ API returns 401 error: "Token expired"
- ✅ Task status does not change

---

## Notification Tests

### TC-NOT-001: Push notification after cancellation by client

**Prerequisites:**
- Contractor has push notifications enabled
- Task is assigned to contractor

**Steps:**
1. Client cancels task

**Expected Result:**
- ✅ Contractor receives push notification
- ✅ Title: "Task cancelled"
- ✅ Content contains task title and reason (if provided)
- ✅ Clicking notification opens task details

---

### TC-NOT-002: Push notification after cancellation by contractor

**Prerequisites:**
- Client has push notifications enabled
- Contractor accepted task

**Steps:**
1. Contractor cancels task

**Expected Result:**
- ✅ Client receives push notification
- ✅ Title: "Contractor released the task"
- ✅ Content informs that task is available again
- ✅ Clicking notification opens task details

---

### TC-NOT-003: WebSocket notification in real-time

**Prerequisites:**
- Client and contractor have app open
- Both are connected to WebSocket

**Steps:**
1. Client cancels task

**Expected Result:**
- ✅ Contractor receives immediate notification via WebSocket
- ✅ Task status updates in UI without refresh
- ✅ UI shows cancellation message

---

## Edge Cases Tests

### TC-EDGE-001: Cancel task during status update

**Prerequisites:**
- Task is in process of status change (e.g., from ACCEPTED to IN_PROGRESS)

**Steps:**
1. Contractor clicks "Start task"
2. Simultaneously client clicks "Cancel"

**Expected Result:**
- ✅ One request succeeds, other returns error
- ✅ Backend handles race condition correctly
- ✅ Final status is consistent
- ✅ User receives appropriate error message

---

### TC-EDGE-002: Cancel task with very long reason

**Prerequisites:**
- User tries to cancel with reason > 500 characters

**Steps:**
1. User enters reason > 500 characters
2. Tries to cancel

**Expected Result:**
- ✅ Frontend limits text length
- ✅ If text is too long, API returns validation error
- ✅ Error message is clear

---

### TC-EDGE-003: Cancel task with invalid ID

**Prerequisites:**
- User tries to cancel task with invalid UUID

**Steps:**
1. Call API: `PUT /tasks/invalid-id/cancel`

**Expected Result:**
- ✅ API returns 400 error: "Invalid task ID format"
- ✅ Status of any task does not change

---

### TC-EDGE-004: Cancel non-existent task

**Prerequisites:**
- Task does not exist in database

**Steps:**
1. Call API: `PUT /tasks/{non-existent-uuid}/cancel`

**Expected Result:**
- ✅ API returns 404 error: "Task not found"
- ✅ Status of any task does not change

---

## Test Summary

### Statistics

- **Total number of tests**: 40+
- **Tests for Client**: 9
- **Tests for Contractor**: 6
- **Tests for Admin**: 2
- **Integration Tests**: 3
- **UI/UX Tests**: 3
- **Performance Tests**: 1
- **Security Tests**: 3
- **Notification Tests**: 3
- **Edge Cases Tests**: 4

### Priorities

- **P0 (Critical)**: TC-CL-001, TC-CL-002, TC-CO-001, TC-SEC-001, TC-SEC-002
- **P1 (High)**: TC-CL-003, TC-CL-004, TC-CO-002, TC-CO-003, TC-INT-001
- **P2 (Medium)**: TC-CL-007, TC-CO-006, TC-UI-001, TC-NOT-001, TC-NOT-002
- **P3 (Low)**: TC-PERF-001, TC-EDGE-001, TC-EDGE-002

---

*Document created: 2026-01-24*
*Last updated: 2026-01-24*
