# Dodatkowe Kategorie Zleceń (Inspiracja: Fixly.pl)

## Kontekst

Rozszerzenie kategorii zleceń w Szybka Fucha z **6 do 17 kategorii**, inspirowane serwisem [Fixly.pl](https://fixly.pl/). Wszystkie nowe kategorie są dopasowane do modelu mikro-zleceń (szybkie, natychmiastowe zadania).

---

## Obecne kategorie (6 — bez zmian)

| # | Klucz enum | Wartość | Nazwa | Opis | Ikona | Kolor | Cena (PLN) | Czas |
|---|-----------|---------|-------|------|-------|-------|------------|------|
| 1 | PACZKI | paczki | Paczki | Odbiór i dostawa paczek | inventory_2 | #6366F1 (Indigo) | 30-60 | 30 min |
| 2 | ZAKUPY | zakupy | Zakupy | Zakupy i dostawy | shopping_cart | #10B981 (Emerald) | 40-80 | 45 min |
| 3 | KOLEJKI | kolejki | Kolejki | Czekanie w kolejkach | schedule | #F59E0B (Amber) | 50-100/h | 60 min |
| 4 | MONTAZ | montaz | Montaż | Składanie mebli i drobne naprawy | build | #3B82F6 (Blue) | 60-120 | 90 min |
| 5 | PRZEPROWADZKI | przeprowadzki | Przeprowadzki | Pomoc przy przeprowadzce | local_shipping | #8B5CF6 (Violet) | 80-150/h | 120 min |
| 6 | SPRZATANIE | sprzatanie | Sprzątanie | Szybkie sprzątanie | cleaning_services | #EC4899 (Pink) | 100-180 | 120 min |

---

## Nowe kategorie (11)

| # | Klucz enum | Wartość | Nazwa | Opis | Ikona | Kolor | Cena (PLN) | Czas |
|---|-----------|---------|-------|------|-------|-------|------------|------|
| 7 | NAPRAWY | naprawy | Naprawy | Drobne naprawy domowe | home_repair_service | #EF4444 (Red) | 60-150 | 60 min |
| 8 | OGROD | ogrod | Ogród | Prace ogrodowe i porządkowe | yard | #22C55E (Green) | 80-200/h | 120 min |
| 9 | TRANSPORT | transport | Transport | Przewóz rzeczy i osób | directions_car | #0EA5E9 (Sky) | 50-120 | 60 min |
| 10 | ZWIERZETA | zwierzeta | Zwierzęta | Opieka nad zwierzętami | pets | #F97316 (Orange) | 40-80/h | 60 min |
| 11 | ELEKTRYK | elektryk | Elektryk | Drobne prace elektryczne | electrical_services | #FACC15 (Yellow) | 80-200 | 60 min |
| 12 | HYDRAULIK | hydraulik | Hydraulik | Drobne prace hydrauliczne | plumbing | #06B6D4 (Cyan) | 80-200 | 60 min |
| 13 | MALOWANIE | malowanie | Malowanie | Malowanie ścian i pomieszczeń | format_paint | #A855F7 (Purple) | 100-250 | 180 min |
| 14 | ZLOTA_RACZKA | zlota_raczka | Złota rączka | Wieszanie, mocowanie, drobne prace | construction | #D97706 (Amber) | 50-150 | 60 min |
| 15 | KOMPUTERY | komputery | Komputery | Pomoc z komputerem i elektroniką | computer | #3B82F6 (Blue) | 60-150 | 60 min |
| 16 | SPORT | sport | Sport | Trening, aktywność fizyczna | fitness_center | #10B981 (Emerald) | 60-120/h | 60 min |
| 17 | INNE | inne | Inne | Inne zadania i usługi | more_horiz | #6B7280 (Gray) | 35-200 | 60 min |

---

## Emoji do admin panelu

```
naprawy:      🔨 Naprawy
ogrod:        🌿 Ogród
transport:    🚗 Transport
zwierzeta:    🐾 Zwierzęta
elektryk:     ⚡ Elektryk
hydraulik:    🔧 Hydraulik
malowanie:    🎨 Malowanie
zlota_raczka: 🛠️ Złota rączka
komputery:    💻 Komputery
sport:        🏋️ Sport
inne:         📋 Inne
```

---

## Pliki do modyfikacji

### Backend
1. **`backend/src/contractor/entities/contractor-profile.entity.ts`** — Dodanie 11 wartości do enum `TaskCategory`
2. **`backend/src/database/seeds/seed.data.ts`** — Aktualizacja danych testowych (nowe kategorie w profilach kontraktów i przykładowe zlecenia)

### Mobile (Flutter)
3. **`mobile/lib/features/client/models/task_category.dart`** — Dodanie 11 wartości do enum `TaskCategory` + 11 nowych wpisów `TaskCategoryData` (nazwa, opis, ikona, kolor, cena, czas)

### Admin Panel (React)
4. **`admin/src/pages/Tasks.tsx`** — Dodanie 11 wpisów do `CATEGORY_LABELS`

### Landing Pages
5. **`index.html`** — Aktualizacja przycisków filtrów kategorii
6. **`index-en.html`** — Tłumaczenie na angielski (British English)
7. **`index-ua.html`** — Tłumaczenie na ukraiński

### Dokumentacja
8. **`CLAUDE.md`** — Aktualizacja sekcji "Task Categories"
9. **`currentupdate.md`** — Wpis o zmianach

### Pliki auto-adaptujące się (bez zmian, tylko weryfikacja)
- `backend/src/tasks/dto/create-task.dto.ts` — `@IsEnum(TaskCategory)` automatycznie waliduje nowe wartości
- `backend/src/tasks/entities/task.entity.ts` — Przechowuje jako `varchar(50)`, brak ograniczeń
- `backend/src/tasks/tasks.service.ts` — Filtrowanie `IN (:...categories)` działa z dowolnymi wartościami
- `mobile/lib/features/client/screens/category_selection_screen.dart` — Iteruje `TaskCategoryData.all` w scrollowalnym `Wrap`
- `mobile/lib/features/contractor/models/contractor_task.dart` — Używa tego samego enum `TaskCategory`

---

## Kolejność wdrożenia

1. Backend enum (`contractor-profile.entity.ts`)
2. Mobile enum + dane (`task_category.dart`)
3. Admin panel labels (`Tasks.tsx`)
4. Seed data (`seed.data.ts`)
5. Landing pages (3 pliki HTML)
6. Weryfikacja ekranów (category selection, contractor profile)
7. Aktualizacja dokumentacji (`CLAUDE.md`, `currentupdate.md`)

---

## Weryfikacja

1. `cd backend && npm run lint` — brak błędów TypeScript
2. `cd backend && npm test` — testy przechodzą
3. `cd mobile && flutter analyze` — brak błędów Dart
4. Wizualna kontrola: ekran wyboru kategorii pokazuje 17 kategorii w scrollowalnej siatce
5. Wizualna kontrola: admin panel Tasks pokazuje nowe etykiety

---

## Ocena ryzyka

- **Niskie ryzyko** — zmiana addytywna (rozszerzenie enumów, dodanie wpisów)
- **Kompatybilność wsteczna** — istniejące zlecenia z obecnymi kategoriami pozostają bez zmian
- **Bezpieczeństwo bazy danych** — kategoria przechowywana jako `varchar(50)`, bez migracji
- **Brak konfliktów** z ostatnimi wpisami w `currentupdate.md`
