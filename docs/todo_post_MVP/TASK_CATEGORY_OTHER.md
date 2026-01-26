# TODO: Dodać kategorię "other" do TaskCategory

## Problem
Enum `TaskCategory` ma tylko 6 kategorii. Jeśli backend wyśle nieznaną kategorię, aplikacja używa fallback (`paczki`).

## Obecne kategorie
```dart
enum TaskCategory {
  paczki,
  zakupy,
  kolejki,
  montaz,
  przeprowadzki,
  sprzatanie,
}
```

## Do zrobienia
1. Dodać `other` do enum `TaskCategory`
2. Dodać `TaskCategoryData` dla `other` z generyczną ikoną i kolorami
3. Zaktualizować fallback w `contractor_home_screen.dart`:
   ```dart
   orElse: () => TaskCategory.other,
   ```

## Pliki do zmiany
- `mobile/lib/features/client/models/task_category.dart`
- `mobile/lib/features/contractor/screens/contractor_home_screen.dart`

## Priorytet
Niski - dla MVP fallback na `paczki` wystarczy.
