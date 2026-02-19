# Current Update Log

This file tracks all changes made by Claude in the repository. New entries are added at the top (most recent first).

Each entry documents:
- What was changed
- Which files were modified
- System impact
- Potential conflicts or risks

## [2026-02-19] Wybór roli przy pierwszej rejestracji (RoleSelectionScreen)

- **Developer/Agent**: Claude
- **Scope of Changes**: Dodano dedykowany ekran wyboru roli (Szef / Pracownik) wyświetlany raz po onboardingu przed ekranem logowania — aby nowi użytkownicy logujący się przez Google/Apple nie byli domyślnie rejestrowani jako klienci.
- **Files Changed**:
  - `mobile/lib/features/auth/screens/role_selection_screen.dart` – Nowy ekran z dwoma kartami `_RoleCard` (Szef/Pracownik), przycisk Kontynuuj (nieaktywny do wyboru), animowane wskaźniki selekcji
  - `mobile/lib/features/auth/auth.dart` – Dodano export `role_selection_screen.dart`
  - `mobile/lib/core/storage/secure_storage.dart` – Dodano klucz `selectedRole` do `StorageKeys`, dodano `saveSelectedRole`, `getSelectedRole`, `deleteSelectedRole`
  - `mobile/lib/core/providers/auth_provider.dart` – Dodano pole `selectedRole: String?` do `AuthState`, getter `roleSelected`, metodę `setSelectedRole()`, logikę migracji (istniejący zalogowany użytkownik → rola pobierana z `userTypes.first`), czyszczenie roli przy `resetOnboarding()`
  - `mobile/lib/core/router/routes.dart` – Dodano `roleSelection = '/role-selection'`
  - `mobile/lib/core/router/app_router.dart` – Dodano przekierowanie: jeśli `onboardingComplete && !roleSelected` → `/role-selection`; dodano `GoRoute` dla roleSelection; getter `roleSelected` w `_AuthStateNotifier`; zalogowany użytkownik jest przekierowywany z ekranu wyboru roli
  - `mobile/lib/features/auth/screens/onboarding_screen.dart` – Zmieniono cel nawigacji z `Routes.browse`/`Routes.welcome` na `Routes.roleSelection` (w `_completeOnboarding` i przycisku "Zaloguj się")
  - `mobile/lib/features/auth/screens/welcome_screen.dart` – Usunięto `UserTypeSelector` i `_selectedUserType`; dodano getter `_userType` czytający `authProvider.selectedRole ?? 'client'`
- **System Impact**: Nowy krok w onboarding flow — rola przechowywana w bezpiecznym storage i zapamiętywana między sesjami. Istniejący zalogowani użytkownicy: migracja auto-uzupełnia rolę z danych konta (transparentna aktualizacja). Wylogowani bez zapisanej roli: zobaczą wybór raz przy następnym starcie.
- **Related Tasks/PRD**: Rejestracja Google/Apple — zapobieganie domyślnemu przypisaniu roli klienta
- **Potential Conflicts/Risks**: `welcome_screen.dart` — usunięto `UserTypeSelector`; jeśli widget ten jest używany gdzie indziej, wymaga sprawdzenia (nie jest — widget był inline)

## [2026-02-19] Ekran historii zleceń wykonawcy + nowa zakładka w nawigacji

- **Developer/Agent**: Claude
- **Scope of Changes**: Dodano ekran historii zleceń dla wykonawcy (2 taby: Aktywne + Historia) oraz nową zakładkę "Historia" w dolnym menu nawigacyjnym między "Zlecenia" a "Zarobki".
- **Files Changed**:
  - `mobile/lib/features/contractor/screens/contractor_task_history_screen.dart` – Nowy ekran z tabami: aktywne zadania (contractorActiveTasksProvider) + historia (contractorHistoryProvider), karty zadań z nawigacją i bottom sheet ze szczegółami
  - `mobile/lib/features/contractor/screens/screens.dart` – Dodano export nowego ekranu
  - `mobile/lib/core/providers/task_provider.dart` – Dodano `ContractorHistoryState`, `ContractorHistoryNotifier`, `contractorHistoryProvider` (ładuje zakończone/anulowane zadania)
  - `mobile/lib/core/router/routes.dart` – Dodano `contractorTaskHistory = '/contractor/history'`
  - `mobile/lib/core/router/app_router.dart` – Dodano route dla historii, rozszerzono `_ContractorShell` do 5 zakładek, zaktualizowano `_calculateSelectedIndex` i `_onItemTapped`
- **System Impact**: Nawigacja wykonawcy rozszerzona z 4 do 5 zakładek; nowy provider ładuje historię zadań z `/tasks/contractor/applications`
- **Related Tasks/PRD**: Funkcja historii zleceń dla wykonawcy
- **Potential Conflicts/Risks**: Indeksy zakładek nawigacji zmieniły się (Zarobki: 2→3, Profil: 3→4) — jeśli gdzieś są hardkodowane indeksy zakładek, mogą wymagać aktualizacji

## [2026-02-19] Fix: Badge — nie opuszczaj task roomu po zamknięciu czatu/ekranu

- **Developer/Agent**: Claude
- **Scope of Changes**: Badge nadal nie działał w client_home_screen (kontraktor→klient) i w ogóle dla klienta→wykonawcy. Root cause: `leaveChat()` i `dispose()` wywoływały `leaveTask()` → użytkownik wychodził z room → przestawał otrzymywać `message:new`.
- **Files Changed**:
  - `mobile/lib/features/chat/providers/chat_provider.dart` – usunięto `leaveTask()` z `leaveChat()`. Task room pozostaje aktywny po zamknięciu czatu.
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – usunięto wywołanie `_leaveTaskRoom()` z `dispose()` i usunięto nieużywaną metodę.
- **System Impact**: Użytkownicy pozostają w task roomach przez cały czas sesji WS → badge działa na wszystkich ekranach w obu kierunkach. Cleanup rooms następuje naturalnie przy disconneccie; reconnect auto-joinuje z powrotem.
- **Potential Conflicts/Risks**: Brak. Roomy są lightweight w Socket.io. Nie opuszczamy rooma przez nawigację — to jest poprawne zachowanie.

---

## [2026-02-19] Fix: Badge — auto-join task rooms on WS connect (backend)

- **Developer/Agent**: Claude
- **Scope of Changes**: Badge nadal nie działał bo backend emituje `message:new` tylko do pokoju `task:${taskId}`, a użytkownik dołącza do tego pokoju dopiero po otwarciu czatu. Teraz backend auto-joinuje wszystkie aktywne task roomy przy połączeniu WS.
- **Files Changed**:
  - `backend/src/realtime/realtime.service.ts` – dodano `getActiveTaskIdsForUser(userId)` — query o aktywne taski
  - `backend/src/realtime/realtime.gateway.ts` – `handleConnection()`: fire-and-forget auto-join do aktywnych task roomów
- **System Impact**: Użytkownik po połączeniu WS automatycznie jest w task roomach wszystkich aktywnych zadań → badge działa bez wcześniejszego otwierania czatu.
- **Potential Conflicts/Risks**: Jeden DB query na połączenie. Fire-and-forget — błąd jest logowany, nie przerywa połączenia.

---

## [2026-02-19] Fix: Unread message badge never showing count

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed `unreadMessagesProvider` so the red badge counter actually appears when a new message arrives. Root cause: `chatMessagesProvider` (the intermediary) is a `StreamProvider` that auto-disposes when no widget watches it (i.e., when no chat screen is open), removing its WS listener. Bypassed it entirely by registering directly with `WebSocketService.on()`. Also eagerly initialized the provider at app startup so it listens from the first frame.
- **Files Changed**:
  - `mobile/lib/core/providers/unread_messages_provider.dart` – Removed dependency on `chatMessagesProvider`; now calls `webSocketService.on(WebSocketConfig.messageNew, onNewMessage)` directly; re-registers listener on login (for logout→login cycle); `ref.onDispose` removes listener
  - `mobile/lib/core/widgets/websocket_initializer.dart` – Added `import unread_messages_provider.dart`; added `ref.read(unreadMessagesProvider)` in `initState()` for eager initialization
- **System Impact**: Badge count increments in real-time whenever a new message arrives from another user, on all 4 screens (client home, contractor home, task tracking, active task). Count clears when user opens the chat.
- **Potential Conflicts/Risks**: If `WebSocketService.disconnect()` is called (on logout), its `_listeners.clear()` removes our callback. This is handled by re-registering via `ref.listen(authProvider, ...)` when user logs back in.

---

## [2026-02-19] Fix: Map tiles not loading on iOS (flutter_map built-in cache issue)

- **Developer/Agent**: Claude
- **Scope of Changes**: Disabled `flutter_map` v8.2.2's built-in tile caching provider to fix blank map on iOS. Also ran `pod install`.
- **Files Changed**:
  - `mobile/lib/core/widgets/sf_map_view.dart` – Added explicit `tileProvider: NetworkTileProvider(cachingProvider: const DisabledMapCachingProvider())` to `TileLayer`
  - `mobile/ios/Podfile.lock` – Updated by `pod install`
- **Root Cause**: `flutter_map` v8.2.2 added built-in tile caching (`BuiltInMapCachingProvider`) that depends on `path_provider`. The caching provider initializes asynchronously in a fire-and-forget function. If initialization fails or hangs, the internal `_cacheDirectoryPathReady` Completer never completes, causing `getTile()` to await indefinitely. Result: tiles never load, no console errors.
- **System Impact**: Map tiles now load directly from OSM network (no local caching). Performance slightly reduced due to no tile caching, but maps work correctly.
- **Related Tasks/PRD**: Map feature on client task tracking and contractor active task screens
- **Potential Conflicts/Risks**: Tile caching disabled until properly re-enabled. To restore caching: ensure `path_provider` is properly initialized and remove the `cachingProvider` override.


**Important**: Claude must read this file before starting any new task to avoid conflicts and regressions.

---

## [2026-02-19] Real-time Chat — Duplikaty wiadomości (Bug Fix)

- **Developer/Agent**: Claude
- **Scope of Changes**: Naprawiono dwa bugi powodujące wielokrotne wyświetlanie wysłanej wiadomości w UI
- **Files Changed**:
  - `mobile/lib/core/services/websocket_service.dart` – lokalny fire `message:new` w `sendMessage()` przeniesiony do bloku `devMode` (wcześniej odpalał się zawsze, tworząc duplikat przed odpowiedzią backendu)
  - `mobile/lib/features/chat/providers/chat_provider.dart` – `ChatNotifier` otrzymuje `_currentUserId`; `_handleIncomingMessage` ignoruje własne wiadomości (backend broadcastuje `message:new` z powrotem do nadawcy); dodany import `auth_provider.dart`
- **System Impact**: Wysłana wiadomość pojawia się dokładnie raz; odebrana wiadomość pojawia się po właściwej stronie bańki
- **Potential Conflicts/Risks**: `chatProvider.family` teraz czyta `currentUserProvider` — jeśli user nie jest zalogowany w momencie tworzenia providera, `currentUserId` będzie pustym stringiem (bezpieczne)

---

## [2026-02-18] Real-time Chat Wiring (Client ↔ Contractor)

- **Developer/Agent**: Claude
- **Scope of Changes**: Connected the pre-built chat UI to navigation and fixed two bugs in ChatProvider. Backend (REST + WebSocket) was already complete. Changes were purely mobile-side wiring.
- **Files Changed**:
  - `mobile/lib/core/router/app_router.dart` – Replaced `PlaceholderScreen` with `ChatScreen` for the client chat route, mirroring existing contractor pattern
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Added `auth_provider.dart` import; `_openChatWithContractor()` now passes `extra` map with taskTitle, contractor name/avatar, and current user id/name
  - `mobile/lib/features/contractor/screens/active_task_screen.dart` – Added `auth_provider.dart` import; `_openChat()` now passes `extra` map with taskTitle, client name/avatar, and current user id/name
  - `mobile/lib/features/chat/providers/chat_provider.dart` – Fixed `_handleIncomingMessage` to filter by `taskId`; fixed `leaveChat()` to call `_webSocketService.off()` to remove listener and prevent memory leak
- **System Impact**: Chat is now fully functional end-to-end — both client and contractor can open a chat screen from their active task views, messages load from REST history and arrive in real-time via WebSocket
- **Related Tasks/PRD**: Real-time messaging feature
- **Potential Conflicts/Risks**: None — no backend changes, no existing UI changes

---

## [2026-02-13] Multi-Contractor Bidding System (Licytacja Zleceń)

- **Developer/Agent**: Claude
- **Scope of Changes**: Replaced the old "first-come-first-served" task acceptance model with a bidding system where multiple contractors (configurable max, default 5) can apply for a task with proposed prices and optional messages. Client sees a list of applicants with profiles (avatar, rating, bio, completed tasks, proposed price) and can accept or reject each. Old `ACCEPTED` status flow replaced: `CREATED → contractors apply → client picks one → CONFIRMED`. Full backend + mobile implementation with WebSocket real-time updates.
- **Files Changed**:
  - `backend/src/tasks/entities/task-application.entity.ts` – NEW: TaskApplication entity with ApplicationStatus enum, unique constraint, indexes
  - `backend/src/tasks/dto/apply-task.dto.ts` – NEW: DTO for contractor applications (proposedPrice min 35, optional message max 500)
  - `backend/src/tasks/entities/task.entity.ts` – Added maxApplications field (default 5)
  - `backend/src/tasks/tasks.module.ts` – Registered TaskApplication entity
  - `backend/src/tasks/dto/create-task.dto.ts` – Added optional maxApplications field (1-20)
  - `backend/src/tasks/tasks.service.ts` – Major: added applyForTask, getApplications, acceptApplication, rejectApplication, withdrawApplication, getMyApplications; deprecated old acceptTask/confirmContractor/rejectContractor; updated cancelTask to auto-reject pending applications
  - `backend/src/tasks/tasks.controller.ts` – New endpoints: POST :id/apply, GET :id/applications, PUT :id/applications/:appId/accept, PUT :id/applications/:appId/reject, DELETE :id/apply, GET contractor/applications; old endpoints return 410 Gone
  - `backend/src/realtime/realtime.gateway.ts` – Added APPLICATION_NEW, APPLICATION_ACCEPTED, APPLICATION_REJECTED, APPLICATION_WITHDRAWN, APPLICATION_COUNT events
  - `mobile/lib/features/client/models/task_application.dart` – NEW: TaskApplication and MyApplication models with ApplicationStatus enum
  - `mobile/lib/features/client/models/task.dart` – Added applicationCount and maxApplications fields
  - `mobile/lib/features/client/widgets/application_card.dart` – NEW: Widget showing contractor bid with accept/reject buttons
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Major: 4-step flow (applications→confirmed→inProgress→completed), WebSocket listener for application events, error display, removed old confirm/reject flow
  - `mobile/lib/features/contractor/widgets/nearby_task_card.dart` – Changed button from "Przyjmij" to "Zgłoś się"
  - `mobile/lib/features/contractor/screens/contractor_task_list_screen.dart` – Replaced _acceptTask with _showApplyDialog (price + message fields)
  - `mobile/lib/features/contractor/screens/my_applications_screen.dart` – NEW: Contractor's application history with statuses
  - `mobile/lib/core/providers/task_provider.dart` – Added taskApplicationsProvider, myApplicationsProvider; replaced acceptTask with applyForTask
  - `mobile/lib/core/providers/websocket_provider.dart` – Added applicationUpdatesProvider and applicationResultProvider streams
  - `mobile/lib/core/services/websocket_service.dart` – Added 5 application event listeners
  - `mobile/lib/core/config/websocket_config.dart` – Added 5 application event name constants
  - `mobile/lib/core/router/routes.dart` – Added contractorMyApplications route
- **System Impact**: Major flow change - task acceptance now goes through bidding system. Old direct-accept endpoints return 410 Gone for backward compatibility. WebSocket events notify both clients and contractors in real-time.
- **Related Tasks/PRD**: Multi-Contractor Bidding System (tasks/Multi-Contractor-Bidding.md), PRD Section 4.3 Matching Module
- **Potential Conflicts/Risks**:
  - Old mobile clients hitting deprecated endpoints will get 410 Gone errors
  - Test spec files need updating for new maxApplications field on Task entity
  - ACCEPTED status still in Task entity enum for DB backward compat but not used in new flow

---

## [2026-02-14] Expand Task Categories from 6 to 17 Across Backend, Mobile, Admin, Landing, and Docs

- **Developer/Agent**: Codex
- **Scope of Changes**: Extended task category support from 6 to 17 categories with synchronized updates across backend enums and seeds, Flutter category model and contractor profile UI, admin category labels, PL/EN/UA landing filters, and documentation
- **Files Changed**:
  - `backend/src/contractor/entities/contractor-profile.entity.ts` – Added 11 new enum values in `TaskCategory` (`naprawy`, `ogrod`, `transport`, `zwierzeta`, `elektryk`, `hydraulik`, `malowanie`, `zlota_raczka`, `komputery`, `sport`, `inne`)
  - `backend/src/tasks/entities/task.entity.ts` – Updated `category` field comment to reflect generic `TaskCategory` string storage instead of old 6-category list
  - `backend/src/database/seeds/seed.data.ts` – Expanded contractor category profiles and added sample tasks covering all 11 newly added categories (full category coverage in seeded tasks)
  - `mobile/lib/features/client/models/task_category.dart` – Added 11 enum values and 11 new `TaskCategoryData` entries (name, description, icon, color, price range, unit, estimated duration)
  - `mobile/lib/features/client/screens/category_selection_screen.dart` – Updated screen comment to neutral wording for full category set
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Replaced hardcoded 6-category list with dynamic chips generated from `TaskCategoryData.all`; uses enum key for backend payload and localized display name for UI
  - `admin/src/pages/Tasks.tsx` – Added 11 new entries to `CATEGORY_LABELS` including emoji labels for admin task list
  - `index.html` – Updated app preview category filter bar to 17 Polish category buttons
  - `en/index.html` – Updated app preview category filter bar to 17 British English category buttons
  - `ua/index.html` – Updated app preview category filter bar to 17 Ukrainian category buttons
  - `CLAUDE.md` – Updated "Task Categories" section from 6 to full list of 17
  - `currentupdate.md` – Added this changelog entry
- **System Impact**:
  - Backend DTO validation based on `@IsEnum(TaskCategory)` now accepts the 11 new category values automatically
  - Seed dataset now includes realistic examples for every new category, improving local testing and demo coverage
  - Mobile and contractor profile UI now share a single source of truth for category definitions, reducing future drift risk
  - Admin task category rendering now shows friendly labels for all supported categories (no raw key fallback for new ones)
  - Landing pages now present the complete category universe consistently across PL/EN/UA variants
- **Related Tasks/PRD**: `tasks/dodatkowe-kategorie.md` (Fixly-inspired category expansion)
- **Potential Conflicts/Risks**:
  - Existing production content/marketing screenshots may still reference old 6-category set and should be refreshed
  - If any external integration hardcodes old category allowlists, it must be updated to include new keys
  - Ukrainian labels were translated in-page; wording can be refined later by native-language review if needed

---

## [2026-02-13] Add Flutter Development Skills & Commands

- **Developer/Agent**: Claude
- **Scope of Changes**: Created 7 Claude Code slash commands and 2 autonomous skills for Flutter code quality, testing, performance, accessibility, security, and iOS/Android platform compliance
- **Files Changed**:
  - `.claude/commands/flutter-analyze.md` – Command: Run flutter analyze + enhanced lint checks (naming, const, theme tokens, file size)
  - `.claude/commands/flutter-test.md` – Command: Run tests with coverage and report untested files by priority
  - `.claude/commands/audit-performance.md` – Command: Detect performance anti-patterns (ListView, Container, Opacity, saveLayer, missing const)
  - `.claude/commands/audit-accessibility.md` – Command: Check WCAG 2.1 AA, iOS HIG, Material accessibility compliance (Semantics, touch targets, contrast, dark mode)
  - `.claude/commands/audit-security.md` – Command: Scan for hardcoded secrets, insecure URLs, improper storage, debug prints
  - `.claude/commands/audit-platform.md` – Command: Check iOS HIG and Material Design 3 compliance (typography, spacing, navigation, M3 components)
  - `.claude/commands/audit-all.md` – Command: Run all audits and produce unified summary report with scores
  - `.claude/commands/flutter-quality-gate/SKILL.md` – Skill: Auto-triggers when modifying Flutter code to enforce naming, widget patterns, theme tokens, performance
  - `.claude/commands/platform-compliance/SKILL.md` – Skill: Auto-triggers when modifying screen files to enforce touch targets, typography, accessibility, spacing
- **System Impact**: New development workflow tools. Commands invoked via `/flutter-analyze`, `/flutter-test`, `/audit-performance`, `/audit-accessibility`, `/audit-security`, `/audit-platform`, `/audit-all`. Skills auto-apply when editing Flutter files.
- **Related Tasks/PRD**: Based on `tasks/development-guidelines-ios-android-flutter (1).md` guidelines document
- **Potential Conflicts/Risks**: None — these are read-only audit tools that don't modify code. Skills provide guidance when writing new code.

---

## [2026-02-11] Fix 3 Bugs from Manual Testing of Email Auth

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed 3 bugs found during manual testing of email + password authentication
- **Files Changed**:
  - `backend/src/auth/auth.service.ts` – Changed `findByEmail` to `findByEmailWithPassword` in `requestPasswordReset` method. The original `findByEmail` never loaded `passwordHash` (due to `select: false` on entity), so the `!user.passwordHash` check always returned early without storing the OTP in Redis.
  - `backend/src/auth/auth.service.spec.ts` – Updated 2 test mocks in `requestPasswordReset` tests to use `findByEmailWithPassword` instead of `findByEmail`.
  - `mobile/lib/core/providers/auth_provider.dart` – Modified `registerWithEmail` to NOT set state to `AuthStatus.authenticated` (was triggering GoRouter redirect to home before email verify screen could show). Added new `activateSession()` method that reads saved auth data from storage and sets authenticated state.
  - `mobile/lib/core/router/app_router.dart` – Removed `emailVerify` from `isAuthRoute` check. Added `isEmailVerifyRoute` variable so email verification screen is accessible for both authenticated and unauthenticated users.
  - `mobile/lib/features/auth/screens/email_verification_screen.dart` – Updated verify success and "Zweryfikuj później" (skip) to call `activateSession()` instead of `context.pop()`.
  - `mobile/lib/features/auth/screens/email_register_screen.dart` – Added "Zaloguj się" TextButton next to duplicate email error message.
- **System Impact**: Fixes email verification flow, password reset flow, and improves duplicate email UX
- **Related Tasks/PRD**: Email + Password Authentication feature
- **Potential Conflicts/Risks**: `registerWithEmail` now keeps state as `unauthenticated` until `activateSession()` is called — this is intentional but different from other auth methods (phone, Google, Apple) which set authenticated immediately.

---

## [2026-02-11] Add Email + Password Authentication (4th Auth Method)

- **Developer/Agent**: Claude
- **Scope of Changes**: Added email + password as a 4th authentication method alongside existing Phone/OTP, Google OAuth, and Apple Sign-In. Full backend API + Flutter mobile integration.
- **Files Changed**:
  - `backend/package.json` – Added bcrypt, @types/bcrypt, nodemailer, @types/nodemailer dependencies
  - `backend/src/users/entities/user.entity.ts` – Added passwordHash (select:false), passwordUpdatedAt, emailVerified, failedLoginAttempts, lockedUntil fields
  - `backend/src/users/users.service.ts` – Added findByEmailWithPassword, incrementFailedLoginAttempts, resetFailedLoginAttempts, setEmailVerified, updatePassword methods
  - `backend/src/auth/dto/register-email.dto.ts` – New DTO for email registration
  - `backend/src/auth/dto/login-email.dto.ts` – New DTO for email login
  - `backend/src/auth/dto/verify-email.dto.ts` – New DTO for email verification
  - `backend/src/auth/dto/request-password-reset.dto.ts` – New DTO for password reset request
  - `backend/src/auth/dto/reset-password.dto.ts` – New DTO for password reset
  - `backend/src/auth/email.service.ts` – New EmailService for sending OTP emails (console log in dev, SMTP in prod)
  - `backend/src/auth/auth.service.ts` – Added registerWithEmail, loginWithEmail, verifyEmailOtp, resendEmailVerificationOtp, requestPasswordReset, resetPassword methods
  - `backend/src/auth/auth.controller.ts` – Added 6 new endpoints: POST /auth/email/{register,login,verify,resend-verification,request-password-reset,reset-password}
  - `backend/src/auth/auth.module.ts` – Added EmailService to providers
  - `backend/src/auth/auth.service.spec.ts` – Added 17 new tests for email auth (total: 315 tests passing)
  - `mobile/lib/core/providers/auth_provider.dart` – Added registerWithEmail, loginWithEmail, verifyEmail, resendEmailVerification, requestPasswordReset, resetPassword methods
  - `mobile/lib/features/auth/widgets/social_login_button.dart` – Added email type to SocialLoginType enum
  - `mobile/lib/core/router/routes.dart` – Added emailLogin, emailRegister, emailVerify, forgotPassword routes
  - `mobile/lib/core/router/app_router.dart` – Added GoRoute entries for 4 new screens + updated isAuthRoute guard
  - `mobile/lib/features/auth/auth.dart` – Added exports for 4 new screens
  - `mobile/lib/features/auth/screens/welcome_screen.dart` – Added email login button after phone button
  - `mobile/lib/features/auth/screens/email_login_screen.dart` – New email login screen
  - `mobile/lib/features/auth/screens/email_register_screen.dart` – New registration screen with password strength indicator
  - `mobile/lib/features/auth/screens/email_verification_screen.dart` – New OTP verification screen
  - `mobile/lib/features/auth/screens/forgot_password_screen.dart` – New password reset screen (2-step: email → OTP+new password)
- **System Impact**: New auth method added. 6 new API endpoints. 4 new Flutter screens. Welcome screen updated with email button. Security: bcrypt cost 12, account lockout (5 attempts → 15min), rate limiting on all endpoints, anti-enumeration on password reset, OTP via Redis with TTL.
- **Related Tasks/PRD**: Authentication system expansion, PRD user registration requirements
- **Potential Conflicts/Risks**: New User entity fields (passwordHash, emailVerified, failedLoginAttempts, lockedUntil) require DB sync. SMTP env vars needed for production email sending. No impact on existing Phone/Google/Apple auth flows.

---

## [2026-02-11] Fix Contractor Card Showing 0.0 Rating and 0 Tasks on Task Tracking Screen

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed contractor card on task tracking screen showing default 0.0 rating and 0 completed tasks instead of real values from backend. Root cause was two-fold: (1) all data sources (WebSocket, task data, `/public` endpoint) returned stale cached values from `contractor_profiles` table, (2) provider listener overwrote fetched data via reference comparison bug.
- **Files Changed**:
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Added `_fetchContractorStats()` method that fetches BOTH `/contractor/:id/public` and `/contractor/:id/reviews` endpoints to get real computed rating data; added `_fetchedStatsContractorId` tracking to prevent provider listener from overwriting fetched data; fixed `clientTasksProvider` listener to compare contractor by ID instead of reference
  - `backend/src/contractor/contractor.service.ts` – Fixed `getPublicProfile()` to compute real `ratingAvg` and `ratingCount` from `ratings` table using SQL AVG/COUNT instead of returning stale cached values from `contractor_profiles` table
- **Root Cause**: Three issues combined: (1) `contractor_profiles.ratingAvg` and `ratingCount` columns default to 0 and are never updated when ratings are submitted, (2) `/contractor/:id/public` endpoint returned these stale values, (3) `clientTasksProvider` listener used reference comparison (`task.contractor != _contractor`) causing fetched real data to be overwritten
- **System Impact**: Contractor card now shows real rating and review count. Backend `/public` endpoint now returns computed ratings for all consumers.
- **Related Tasks/PRD**: Contractor profile display, task tracking UI
- **Potential Conflicts/Risks**: Additional API call (reviews endpoint) per contractor assignment on mobile; mitigated by `_fetchedStatsContractorId` preventing re-fetches. Backend change adds one SQL query to `/public` endpoint.

---

## [2026-02-09] Disable Dual Role Functionality for MVP

- **Developer/Agent**: Claude
- **Scope of Changes**: Disabled dual-role functionality to simplify MVP - users can no longer switch between client and contractor roles after initial registration
- **Files Changed**:
  - `backend/src/auth/auth.service.ts` – Modified phone OTP, Google, and Apple auth methods to only add roles for new users (when `types.length === 0`); prevents automatic role addition on subsequent logins
  - `backend/src/users/users.controller.ts` – Added validation guards to `PATCH /users/me/type` and `POST /users/me/add-role` endpoints to block role changes for users who already have roles (throws `BadRequestException`)
  - `mobile/lib/features/settings/screens/settings_screen.dart` – Removed role switch UI: deleted `_buildRoleSwitchTile()`, `_showRoleSwitchConfirmation()`, and `_performRoleSwitch()` methods; cleaned up unused imports
- **System Impact**:
  - **Role Locking**: Users' roles are now locked after initial registration - client stays client, contractor stays contractor
  - **Backend Protection**: Even if role switch endpoints are called directly, they return 400 error for existing users
  - **Login Behavior**: Selecting different user type on welcome screen no longer adds second role
  - **Settings UI**: "Zmienić rolę?" (Change role) button removed from settings screen
  - **Auth Provider**: `switchUserType()`, `addRole()`, and `setActiveRole()` methods remain in auth provider (not exposed in UI, may be useful post-MVP)
  - **User Type Selector**: Welcome/login screens still allow user type selection (required for initial registration)
- **Related Tasks/PRD**: MVP simplification - reduces complexity in onboarding and navigation logic
- **Potential Conflicts/Risks**:
  - **Rollback Path**: To re-enable dual-role: (1) Remove validation guards in controller, (2) Restore auto-add logic in auth service (revert to `!user.types.includes(userType)` check), (3) Restore role switch UI in settings screen
  - **Admin Override**: Admin panel may need updates if support team needs to manually change user roles
  - **Testing**: Users wanting to switch roles must create new account during MVP period
  - **Post-MVP**: Feature can be easily re-enabled by reverting these changes

---

## [2026-02-07] Bug Fixes: Location Timeout, Task Visibility, RenderFlex Overflow

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed three bugs discovered during testing: location timeout, tasks not visible to contractor, and RenderFlex overflow on task tracking screen

- **Files Changed**:
  - `mobile/lib/core/services/location_service.dart` – Increased GPS timeout from 15s to 30s; added fallback from high to medium accuracy on TimeoutException
  - `backend/src/tasks/tasks.controller.ts` – Added `role` query parameter to `GET /tasks` endpoint; explicit role param allows dual-role users to fetch correct task list (client's own tasks vs available tasks for contractor)
  - `mobile/lib/core/providers/task_provider.dart` – Client `loadTasks()` now passes `role=client`; Contractor `loadTasks()` now passes `role=contractor`
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Replaced `SafeArea(top: false)` wrapper in `_buildBottomPanel()` with bottom safe area padding added to `SingleChildScrollView` content padding, preventing RenderFlex overflow when screen is inside _ClientShell with NavigationBar

- **System Impact**: Location detection more reliable on cold GPS start; contractor now correctly sees available tasks (not their own client tasks); task tracking bottom panel no longer overflows
- **Related Tasks/PRD**: Task lifecycle flow, dual-role user experience
- **Potential Conflicts/Risks**: The `role` query parameter change means older mobile app versions calling `GET /tasks` without `role` param will still work (backward compatible — defaults to contractor if user has contractor type, otherwise client)

---

## [2026-02-05] Dual-Role Architecture Implementation - Complete Backend & Mobile Migration

- **Developer/Agent**: Claude
- **Scope of Changes**: Complete implementation of dual-role architecture allowing users to be both clients AND contractors simultaneously, with separate profile data and ratings for each role
- **Files Changed**:

  **Backend - Database Entities:**
  - `backend/src/users/entities/user.entity.ts` – Changed `type` from single enum to `types` array (simple-array type)
  - `backend/src/client/entities/client-profile.entity.ts` – **NEW**: Created ClientProfile entity for client-specific bio and ratings
  - `backend/src/tasks/entities/rating.entity.ts` – Added `role` field ('client' | 'contractor') to separate ratings by role

  **Backend - Services:**
  - `backend/src/users/users.service.ts` – Added `addRole()` method for role switching
  - `backend/src/client/client.service.ts` – Complete rewrite with lazy profile creation, role-based ratings (`role='client'`)
  - `backend/src/contractor/contractor.service.ts` – Added `isProfileComplete()` validation, role-based ratings (`role='contractor'`)
  - `backend/src/tasks/tasks.service.ts` – Added profile completion guard in `acceptTask()`, added `role` field to `rateTask()`

  **Backend - Controllers:**
  - `backend/src/users/users.controller.ts` – Added `POST /users/me/add-role` endpoint
  - `backend/src/client/client.controller.ts` – Added `PUT /client/profile` endpoint for client bio
  - `backend/src/contractor/contractor.controller.ts` – Added `GET /contractor/profile/complete` endpoint
  - `backend/src/client/dto/update-client-profile.dto.ts` – **NEW**: Created DTO for client profile updates

  **Backend - Auth:**
  - `backend/src/auth/auth.service.ts` – Updated all auth methods (phone, Google, Apple) to use `types` array
  - `backend/src/auth/types/auth-user.type.ts` – Changed `type: UserType` to `types: string[]`
  - `backend/src/auth/strategies/jwt.strategy.ts` – Updated JWT payload to use `types` array
  - `backend/src/admin/admin.service.ts` – Updated user count queries to search arrays with LIKE pattern

  **Backend - Tasks:**
  - `backend/src/tasks/tasks.controller.ts` – Updated role check from `req.user.type === UserType.CLIENT` to `req.user.types.includes(UserType.CLIENT)`

  **Mobile - Core:**
  - `mobile/lib/core/providers/auth_provider.dart` – Updated User model with `userTypes` array, added `isClient`, `isContractor`, `hasBothRoles` getters, added `addRole()` and `setActiveRole()` methods, added `activeRole` to AuthState
  - `mobile/lib/core/providers/contractor_availability_provider.dart` – Updated contractor check from `userType != 'contractor'` to `!userTypes.contains('contractor')`
  - `mobile/lib/core/providers/task_provider.dart` – Added profile completion guard before task acceptance

  **Mobile - Profile Screens:**
  - `mobile/lib/features/client/screens/client_profile_screen.dart` – Split save: shared data to `/users/me`, client bio to `/client/profile`
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Added categories selector, service radius slider, profile progress bar, validation, split save endpoints
  - `mobile/lib/features/contractor/screens/contractor_home_screen.dart` – Added profile completion check and banner

  **Mobile - Router:**
  - `mobile/lib/core/router/app_router.dart` – Redirected ContractorRegistrationScreen to profile edit

  **Seed Data:**
  - `backend/src/database/seeds/seed.data.ts` – Updated all users to `types` array, added dual-role user example, separated bio fields

- **System Impact**:
  - **BREAKING CHANGE**: User entity `type` field replaced with `types` array - all code accessing `user.type` updated to `user.types`
  - **New Table**: `client_profiles` table created for client-specific data (bio, ratings)
  - **Rating Separation**: Client and contractor ratings now tracked separately with `role` field
  - **Lazy Profile Creation**: Profiles created on first edit, not when role added
  - **Profile Completion Validation**: Contractors BLOCKED from accepting tasks until profile complete (name, address, bio, categories, service radius, KYC)
  - **Registration Flow**: User registers with email/phone/OAuth, immediately enters app, adds roles later
  - **TypeScript Migration**: Fixed 19 compilation errors related to type → types change
  - **Flutter Migration**: Fixed 2 compilation errors (user.userType → user.userTypes)

- **API Endpoints Added**:
  - `POST /users/me/add-role` – Add client or contractor role to user
  - `PUT /client/profile` – Update client profile (bio)
  - `GET /contractor/profile/complete` – Check if contractor profile is complete

- **Validation Rules**:
  - **Client**: Only name required to create tasks; phone, address, bio optional
  - **Contractor**: Name, address, bio, categories (min 1), service radius, KYC required to accept tasks

- **Related Tasks/PRD**: `/Users/simacbook/.claude/plans/staged-shimmying-cerf.md` - Complete dual-role architecture plan
- **Potential Conflicts/Risks**:
  - Any code checking `user.type` will fail - must use `user.types.includes()` or `user.types.contains()`
  - Database migration required - existing users need `type` → `types` conversion
  - Existing ratings may need `role` field backfilled (set based on toUser's type)
  - Profile screens heavily modified - future changes should be aware of split endpoint architecture
  - Auth flow changed - code expecting single userType may break

---

## [2026-02-03] BUGFIX: Task Images Not Saving to Database + URL Validation Fix

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed critical bug where task images were not being saved to database due to URL validation failure
- **Files Changed**:
  - `backend/src/users/file-storage.service.ts` – Updated to return full URLs (http://localhost:3000/uploads/...) instead of relative paths (/uploads/...)
  - `backend/src/tasks/dto/create-task.dto.ts` – Relaxed URL validation to accept localhost URLs without TLD requirement
  - `mobile/lib/features/client/screens/create_task_screen.dart` – Added error handling and logging for image upload failures
- **Root Cause**:
  - **Primary Issue**: `@IsUrl()` validator rejected localhost URLs because they lack a TLD (.com, .pl, etc.)
  - Upload endpoint returned relative URLs: `/uploads/tasks/filename.jpg` (fixed)
  - Even after fix, validator rejected `http://localhost:3000/...` URLs
  - Upload failures were silently caught with `debugPrint`, user never saw errors
- **Fix Applied**:
  **Backend - File Storage:**
  - Added `serverUrl` config (default: `http://localhost:3000`)
  - Updated `uploadAvatar()` to return full URL: `${this.serverUrl}${this.baseUrl}/${filename}`
  - Updated `uploadTaskImage()` to return full URL: `${this.serverUrl}${this.taskImagesBaseUrl}/${filename}`
  - Updated `deleteAvatar()` to handle both full URLs and relative paths for backward compatibility

  **Backend - URL Validation:**
  - Changed `@IsUrl({}, { each: true })` to `@IsUrl({ protocols: ['http', 'https'], require_protocol: true, require_tld: false }, { each: true })`
  - `require_tld: false` allows localhost URLs without `.com`/`.pl` suffix
  - This was the KEY fix - validator was rejecting `http://localhost:3000/uploads/...`

  **Mobile App:**
  - Added upload failure counter and user-facing error messages
  - Enhanced logging with stack traces for debugging
  - Shows SnackBar warning if any images fail to upload: "Nie udało się przesłać X zdjęć"
  - Task creation continues even if some images fail (non-blocking)
- **System Impact**:
  - **Breaking Change**: Upload endpoints now return full URLs instead of relative paths
  - Mobile app `getFullMediaUrl()` helper already handles both formats (checks for http:// prefix)
  - Existing tasks with `null` imageUrls remain unaffected (images were never uploaded)
  - New task images will now correctly save to database and display in mobile app
  - Users will now see errors if image uploads fail
- **Environment Variable**:
  - New optional config: `SERVER_URL` (defaults to `http://localhost:3000`)
  - Production deployment should set `SERVER_URL=https://api.szybkafucha.pl`
- **Testing**:
  - Backend restarted with fixed validation rules (PID: 75664)
  - Health check: ✅ `http://localhost:3000/api/v1/health` responds correctly
  - Upload endpoint verified: Images saved to `backend/uploads/tasks/` directory
  - Ready for testing with new task creation (should accept `http://localhost:3000/...` URLs now)
- **Related Issue**: Tasks `75c491a8-8a58-4f18-b4be-a1f15f030d47` and `975f1f7b-57b4-422f-885e-a286e59c7d92` had imageUrls null in database
- **Potential Conflicts/Risks**:
  - Any code expecting relative URLs from upload endpoints will need adjustment
  - Avatar uploads also affected - verify existing avatar display still works

---

## [2026-02-03] Task Alert Screen: Added Time/Date and Images Display

- **Developer/Agent**: Claude
- **Scope of Changes**: Enhanced task alert screen (contractor's task details view before accepting) with creation time, scheduled time, and task images display
- **Files Changed**:
  - `mobile/lib/features/contractor/screens/task_alert_screen.dart` – Added "Szczegóły" section showing creation time, scheduled time (or "Natychmiast"), and task images with preview functionality
- **System Impact**:
  - **Creation Time**: Displays relative time (e.g., "Przed chwilą", "5 min temu") using existing `_getTimeAgo()` method
  - **Scheduled Time**: Shows formatted date/time (dd.mm.yyyy o hh:mm) if task has `scheduledAt`, otherwise shows "Natychmiast" with warning icon
  - **Task Images**: Horizontal scrollable list of images (if `imageUrls` exists) with tap-to-zoom functionality
  - **Image Preview**: Full-screen dialog with InteractiveViewer for zooming
  - New section appears between "Opis zlecenia" and "Lokalizacja" sections
- **Related Tasks/PRD**: Consistent with recent task details enhancements (2026-02-03 entry)
- **Potential Conflicts/Risks**:
  - This screen was modified - future changes to task_alert_screen.dart should be aware of the new "Szczegóły" section
  - Image display depends on `imageUrls` field being populated by backend

---

## [2026-02-03] Create Task Screen Enhancements: Budget Input, Images, Scheduled Time

- **Developer/Agent**: Claude
- **Scope of Changes**: Enhanced task creation screen with budget input field (min 35 PLN), image upload, and scheduled time display. Added task details view for both client and contractor screens.
- **Files Changed**:
  **Backend:**
  - `backend/src/app.module.ts` – Added ServeStaticModule to serve uploads directory
  - `backend/src/users/file-storage.service.ts` – Added `uploadTaskImage()` method for task images
  - `backend/src/tasks/tasks.controller.ts` – Added `POST /tasks/upload-image` endpoint for task image uploads

  **Mobile - Task Creation:**
  - `mobile/lib/features/client/screens/create_task_screen.dart` – Replaced budget slider with text input field (min 35 PLN), added `_uploadImages()` method, imports for Dio FormData

  **Mobile - Models:**
  - `mobile/lib/core/providers/task_provider.dart` – Added `imageUrls` to CreateTaskDto, updated ContractorTask copyWith extension
  - `mobile/lib/features/client/models/task.dart` – Added `imageUrls` field with JSON parsing and copyWith support
  - `mobile/lib/features/contractor/models/contractor_task.dart` – Added `scheduledAt` and `imageUrls` fields with JSON parsing

  **Mobile - Task Viewing:**
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Added `_showTaskDetails()` method with full task info (category, description, address, budget, scheduled time, images), `_showFullImage()` for image preview
  - `mobile/lib/features/contractor/screens/active_task_screen.dart` – Added scheduled time and images display in `_buildTaskInfoCard()`, `_showFullImage()` for image preview

- **System Impact**:
  - **Budget Validation**: Minimum 35 PLN enforced in both frontend (input validator) and backend (`@Min(35)` in DTO)
  - **Image Upload Flow**: Client picks images → uploads to `/tasks/upload-image` → receives URLs → creates task with `imageUrls` array
  - **File Storage**: Task images stored in `uploads/tasks/` directory, served at `/uploads/tasks/<filename>`
  - **Scheduled Time**: Visible in task details for both client and contractor
  - **Task Images**: Displayed under description in task details, with tap-to-zoom functionality

- **API Endpoints Added**:
  - `POST /tasks/upload-image` – Upload task image, returns `{ imageUrl, message }`

- **Related Tasks/PRD**: `tasks/job_flow.md` - UI enhancements
- **Potential Conflicts/Risks**:
  - ServeStaticModule may conflict with other static file configurations
  - Image upload requires backend to be running to store files
  - Large images may slow down task creation (consider client-side compression)

---

## [2026-02-03] Complete Dual-Rating System Implementation

- **Developer/Agent**: Claude
- **Scope of Changes**: Implemented full dual-rating system where task status changes to COMPLETED only when BOTH client and contractor have rated. Fixed database schema, backend logic, and connected mobile screens to API.
- **Files Changed**:
  - `backend/src/tasks/entities/task.entity.ts` – Added `clientRated`, `contractorRated` (boolean) columns and `PENDING_COMPLETE` enum value
  - `backend/src/tasks/tasks.service.ts` – Updated `rateTask()` to set rating flags and change status when both rated; `completeTask()` requires `PENDING_COMPLETE`; added `confirmCompletion()` for client to confirm job done
  - `backend/src/tasks/tasks.controller.ts` – Added `PUT /tasks/:id/confirm-completion` endpoint
  - `mobile/lib/features/client/screens/task_completion_screen.dart` – Connected to backend: `confirmTask()`, `rateTask()`, `addTip()`
  - `mobile/lib/features/contractor/screens/review_client_screen.dart` – Connected to backend API for rating submission
  - `mobile/lib/core/providers/task_provider.dart` – `confirmTask()` calls `/confirm-completion`, `rateTask()` and `addTip()` call respective endpoints
- **System Impact**:
  - **Task flow**: `IN_PROGRESS` → `PENDING_COMPLETE` (client confirms) → stays `PENDING_COMPLETE` (contractor acknowledges) → `COMPLETED` (when both rate)
  - **Rating saves to database**: Ratings table stores `taskId`, `fromUserId`, `toUserId`, `rating` (1-5), `comment`
  - **Dual-rating tracking**: `clientRated`/`contractorRated` flags track who has rated
  - **API endpoints**:
    - `PUT /tasks/:id/confirm-completion` – client confirms job done
    - `POST /tasks/:id/rate` – submit rating (sets clientRated or contractorRated)
    - `POST /tasks/:id/tip` – add tip (works in PENDING_COMPLETE or COMPLETED)
  - **Notifications**: Both parties notified when task becomes COMPLETED
- **Related Tasks/PRD**: `tasks/job_flow.md` points 8-11
- **Potential Conflicts/Risks**:
  - Existing tasks in PENDING_COMPLETE need both parties to rate before completing
  - Payment release timing currently happens when contractor calls completeTask

---

## [2026-01-31] Fix Avatar URL and Public Profile Endpoint

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed two issues preventing avatar/bio from showing in contractor profile and client popup
- **Files Changed**:
  - `mobile/lib/core/api/api_config.dart` – Added `serverUrl` constants and `getFullMediaUrl()` helper
  - `mobile/lib/core/providers/auth_provider.dart` – Updated User.fromJson to convert relative avatar URLs to full URLs
  - `mobile/lib/features/client/models/contractor.dart` – Updated Contractor.fromJson to convert avatar URLs
  - `mobile/lib/core/services/websocket_service.dart` – Updated ContractorInfo.fromJson to convert avatar URLs
  - `backend/src/contractor/contractor.service.ts` – Added UsersService injection, updated getPublicProfile to fall back to User data
- **System Impact**:
  - Avatar URLs now include full server URL (e.g., `http://localhost:3000/uploads/avatars/file.jpg`)
  - Public profile endpoint no longer throws 404 if contractor_profiles entry doesn't exist
  - Bio and avatar now correctly display in client popup
- **Related Tasks/PRD**: Contractor profile management
- **Potential Conflicts/Risks**: None


1. **Avatar not visible**: Backend returned relative URL `/uploads/avatars/file.jpg`, but NetworkImage needs full URL
2. **Bio/Profile error**: `getPublicProfile` threw 404 if no `contractor_profiles` entry existed - now falls back to User data

---

## [2026-01-31] Contractor Profile Photo Upload

- **Developer/Agent**: Claude
- **Scope of Changes**: Implemented photo upload functionality in contractor profile screen
- **Files Changed**:
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Added photo picker and upload to `POST /users/me/avatar`
- **System Impact**:
  - Contractors can now upload profile photos from camera or gallery
  - Photos are uploaded to backend via multipart form data
  - Avatar displays in contractor profile and client popup (via existing code)
- **Related Tasks/PRD**: Contractor profile management
- **Potential Conflicts/Risks**: None

**Features Added**:
- Bottom sheet with camera/gallery selection
- Image picker with size optimization (1024x1024, 85% quality)
- Upload loading indicator on avatar
- Success/error feedback via SnackBar

---

## [2026-01-31] Bug Fix: Contractor Bio Not Persisting After Save

- **Developer/Agent**: Claude
- **Scope of Changes**: Fixed bug where contractor bio ("o mnie") wasn't persisting after save
- **Files Changed**:
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Added `refreshUser()` call after successful profile save
- **System Impact**:
  - After saving profile, authProvider is now refreshed to fetch updated user data from backend
  - Bio field now correctly persists when user exits and re-enters profile screen
- **Related Tasks/PRD**: Contractor profile management
- **Potential Conflicts/Risks**: None

**Root Cause**: After `api.put('/users/me')` succeeded, the `authProvider` was not refreshed. When user re-entered the profile screen, the old bio was loaded from stale authProvider state.

**Fix Applied**:
```dart
await api.put('/users/me', data: payload);
// Refresh user data in authProvider to update local state
await ref.read(authProvider.notifier).refreshUser();
```

---

## [2026-01-31] Contractor Profile Database Integration

- **Developer/Agent**: Claude
- **Scope of Changes**: Integrated contractor profile with database - bio persistence, real ratings display, public profile endpoint, WebSocket bio transmission
- **Files Changed**:
  - `backend/src/contractor/contractor.controller.ts` – Added `GET /:userId/public` endpoint
  - `backend/src/contractor/contractor.service.ts` – Added `getPublicProfile()` method
  - `backend/src/realtime/realtime.gateway.ts` – Added `bio` field to contractor broadcast type
  - `backend/src/tasks/tasks.service.ts` – Include bio when broadcasting task acceptance
  - `mobile/lib/features/client/models/contractor.dart` – Added `bio` field with JSON parsing
  - `mobile/lib/features/client/screens/task_tracking_screen.dart` – Refactored Profil popup to fetch real data
  - `mobile/lib/features/contractor/screens/contractor_profile_screen.dart` – Fixed bio initialization, added real ratings fetch
  - `mobile/lib/core/services/websocket_service.dart` – Added `bio` field to `ContractorInfo`
  - `docs/task-summaries/contractor-profile-integration-2026-01-31.md` – Created detailed documentation
- **System Impact**:
  - New API endpoint: `GET /contractor/:userId/public` (requires JWT)
  - Contractor profile screen now shows real ratings from database
  - Client "Profil" popup shows real bio from database
  - WebSocket task acceptance now includes contractor bio
- **Related Tasks/PRD**: Contractor profile management, task tracking UI
- **Potential Conflicts/Risks**:
  - Files modified in contractor module - future changes should check this entry
  - WebSocket message format changed (added bio field) - mobile clients must be updated

---

## [2026-01-29] Initial currentupdate.md Setup

- **Developer/Agent**: Claude
- **Scope of Changes**: Created `currentupdate.md` file and added change tracking rules to `CLAUDE.md`
- **Files Changed**:
  - `currentupdate.md` – Created new change log file
  - `CLAUDE.md` – Added "Change Tracking with currentupdate.md" section with mandatory workflow rules
- **System Impact**: Establishes change tracking system to prevent regressions and identify conflicts
- **Related Tasks/PRD**: Documentation standards implementation
- **Potential Conflicts/Risks**: None (initial setup)

---
