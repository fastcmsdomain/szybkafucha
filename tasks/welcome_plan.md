# Welcome Onboarding & Public Browse — Implementation Plan

## Goal
Let first-time users see what the app offers before requiring login. Encourage engagement through 3 onboarding screens, then show available tasks publicly.

## New User Flow
```
App opens
  ├── Returning (not logged in) → PublicBrowseScreen
  ├── First launch → OnboardingScreen (3 pages) → PublicBrowseScreen
  ├── Returning (not logged in) → PublicBrowseScreen
  └── Logged in → ClientHome / ContractorHome (existing)
```

## Existing Logged-In User Flow
```
Użytkownik otwiera aplikację
  └── Jeśli zalogowany:
      ├── Ekran powitalny: "Hej {User name}"
      └── Przekierowanie do ekranu zleceń:
          Tab 1: MAPA (zlecenia z całej Polski)
          Tab 2: LISTA (zlecenia z całej Polski)
```

### UX Notes (existing user)
- Powitanie ma używać nazwy zalogowanego użytkownika.
- Dla zalogowanego wykonawcy domyślnym ekranem po starcie jest ekran zleceń `MAPA/LISTA`.
 Dane na mapie i liście nie są zawężane do jednego miasta - mają pokazywać zlecenia z całej Polski.


## Onboarding Screens (3 pages with PageView)

| # | Title | Subtitle | Button |
|---|-------|----------|--------|
| 1 | Potrzebujesz pomocy? Znajdź ją w 5 minut | Szybka Fucha łączy Cię z pomocnikami w Twojej okolicy | Sprawdź jak to działa |
| 2 | Szybko, prosto, bezpiecznie | Zweryfikowani wykonawcy, bezpieczne płatności i system ocen | Zobacz korzyści |
| 3 | Zarabiaj lub zlecaj — wybór należy do Ciebie | Przeglądaj dostępne zlecenia i zacznij działać już teraz | Zobacz zlecenia |

Design: Colorful icons, dot indicators, "Pomiń" skip button on pages 1-2.

## Public Browse Screen
- Map + list tabs (same as ClientTaskListScreen but no auth required)
- "Zaloguj się" button in AppBar
- "Dodaj zlecenie" FAB → navigates to login

## Changes Required

### New Files
- `mobile/lib/features/auth/screens/onboarding_screen.dart` — 3-page PageView
- `mobile/lib/features/auth/screens/public_browse_screen.dart` — public task browse
- `mobile/lib/core/providers/public_tasks_provider.dart` — provider for public endpoint
- `backend/src/tasks/public-tasks.controller.ts` — `GET /tasks/browse` (no auth)

### Modified Files
- `mobile/lib/core/router/routes.dart` — add `/onboarding`, `/browse` routes
- `mobile/lib/core/router/app_router.dart` — redirect logic for 3 states
- `mobile/lib/core/providers/auth_provider.dart` — add `onboardingComplete` to state
- `mobile/lib/core/l10n/app_strings.dart` — add onboarding strings
- `mobile/lib/features/auth/auth.dart` — export new screens
- `backend/src/tasks/tasks.module.ts` — register PublicTasksController

### Already Exists (reuse)
- `secure_storage.dart` → `isOnboardingComplete()` / `setOnboardingComplete()`
- `tasks.service.ts` → `findAllAvailable()`
- Map widgets, task cards, task models
