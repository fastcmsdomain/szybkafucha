/// Polish strings for Szybka Fucha app
/// All user-facing strings should be defined here for easy localization
abstract class AppStrings {
  // ============ App ============
  static const String appName = 'Szybka Fucha';
  static const String appTagline = 'Pomoc jest bliżej niż myślisz';

  // ============ Common ============
  static const String loading = 'Ładowanie...';
  static const String error = 'Błąd';
  static const String success = 'Sukces';
  static const String cancel = 'Anuluj';
  static const String confirm = 'Potwierdź';
  static const String save = 'Zapisz';
  static const String delete = 'Usuń';
  static const String edit = 'Edytuj';
  static const String close = 'Zamknij';
  static const String back = 'Wróć';
  static const String next = 'Dalej';
  static const String done = 'Gotowe';
  static const String retry = 'Spróbuj ponownie';
  static const String yes = 'Tak';
  static const String no = 'Nie';
  static const String ok = 'OK';
  static const String search = 'Szukaj';
  static const String noResults = 'Brak wyników';
  static const String seeAll = 'Zobacz wszystkie';
  static const String continueText = 'Kontynuuj';
  static const String selectCategory = 'Wybierz kategorię';
  static const String schedule = 'Termin';
  static const String now = 'Teraz';
  static const String scheduleForLater = 'Zaplanuj na później';
  static const String activeTasks = 'Aktywne zlecenia';
  static const String viewHistory = 'Zobacz historię';
  static const String noActiveTasks = 'Brak aktywnych zleceń';

  // ============ Welcome Screen ============
  static const String welcomeTitle = 'Pomoc jest bliżej niż myślisz';
  static const String welcomeSubtitle =
      'Znajdź pomocnika do drobnych zadań w kilka minut';
  static const String iNeedHelp = 'Szukam pomocy';
  static const String iWantToEarn = 'Chcę pomagać i zarabiać';
  static const String termsAgreement =
      'Dołączając, akceptujesz Regulamin i Politykę Prywatności';

  // ============ Auth ============
  static const String login = 'Zaloguj się';
  static const String logout = 'Wyloguj się';
  static const String register = 'Zarejestruj się';
  static const String continueWithGoogle = 'Kontynuuj z Google';
  static const String continueWithApple = 'Kontynuuj z Apple';
  static const String continueWithPhone = 'Kontynuuj z numerem telefonu';
  static const String orContinueWith = 'lub kontynuuj przez';
  static const String phoneNumber = 'Numer telefonu';
  static const String enterPhoneNumber = 'Wpisz numer telefonu';
  static const String sendCode = 'Wyślij kod';
  static const String verificationCode = 'Kod weryfikacyjny';
  static const String enterCode = 'Wpisz kod z SMS';
  static const String resendCode = 'Wyślij ponownie';
  static const String resendCodeIn = 'Wyślij ponownie za';
  static const String invalidPhoneNumber = 'Nieprawidłowy numer telefonu';
  static const String invalidCode = 'Nieprawidłowy kod';
  static const String codeSent = 'Kod został wysłany';

  // ============ Registration ============
  static const String yourName = 'Twoje imię';
  static const String enterYourName = 'Wpisz swoje imię';
  static const String selectUserType = 'Wybierz typ konta';
  static const String iAmClient = 'Szukam pomocy';
  static const String iAmContractor = 'Chcę pomagać';
  static const String clientDescription =
      'Znajdź pomocników do drobnych zadań';
  static const String contractorDescription =
      'Zarabiaj pomagając innym';

  // ============ Categories ============
  static const String categories = 'Kategorie';
  static const String categoryPackages = 'Paczki';
  static const String categoryShopping = 'Zakupy';
  static const String categoryQueues = 'Kolejki';
  static const String categoryAssembly = 'Montaż';
  static const String categoryMoving = 'Przeprowadzki';
  static const String categoryCleaning = 'Sprzątanie';

  // ============ Task Creation ============
  static const String createTask = 'Utwórz zlecenie';
  static const String taskTitle = 'Tytuł zlecenia';
  static const String taskDescription = 'Opis zlecenia';
  static const String describeTask = 'Opisz zadanie...';
  static const String taskLocation = 'Lokalizacja';
  static const String selectLocation = 'Wybierz lokalizację';
  static const String taskBudget = 'Budżet';
  static const String suggestedBudget = 'Sugerowany budżet';
  static const String taskDate = 'Data wykonania';
  static const String selectDate = 'Wybierz datę';
  static const String taskTime = 'Godzina';
  static const String selectTime = 'Wybierz godzinę';
  static const String asap = 'Jak najszybciej';
  static const String postTask = 'Opublikuj zlecenie';

  // ============ Task Status ============
  static const String statusPosted = 'Opublikowane';
  static const String statusAccepted = 'Zaakceptowane';
  static const String statusInProgress = 'W trakcie';
  static const String statusCompleted = 'Zakończone';
  static const String statusCancelled = 'Anulowane';
  static const String statusDisputed = 'Sporne';

  // ============ Task Details ============
  static const String taskDetails = 'Szczegóły zlecenia';
  static const String postedBy = 'Zleceniodawca';
  static const String acceptedBy = 'Wykonawca';
  static const String budget = 'Budżet';
  static const String location = 'Lokalizacja';
  static const String dateTime = 'Data i godzina';
  static const String description = 'Opis';
  static const String acceptTask = 'Przyjmij zlecenie';
  static const String cancelTask = 'Anuluj zlecenie';
  static const String completeTask = 'Zakończ zlecenie';
  static const String reportProblem = 'Zgłoś problem';

  // ============ Tracking ============
  static const String tracking = 'Śledzenie';
  static const String contractorOnTheWay = 'Wykonawca w drodze';
  static const String estimatedArrival = 'Szacowany czas przybycia';
  static const String minutes = 'min';
  static const String arrived = 'Na miejscu';
  static const String workInProgress = 'Praca w toku';

  // ============ Chat ============
  static const String chat = 'Czat';
  static const String typeMessage = 'Napisz wiadomość...';
  static const String send = 'Wyślij';
  static const String messageDelivered = 'Dostarczono';
  static const String messageRead = 'Przeczytano';

  // ============ Rating ============
  static const String rateTask = 'Oceń zlecenie';
  static const String howWasService = 'Jak oceniasz wykonaną usługę?';
  static const String leaveReview = 'Zostaw opinię (opcjonalnie)';
  static const String submitRating = 'Wyślij ocenę';
  static const String addTip = 'Dodaj napiwek';
  static const String tipAmount = 'Kwota napiwku';

  // ============ Contractor ============
  static const String availableTasks = 'Dostępne zlecenia';
  static const String myTasks = 'Moje zlecenia';
  static const String noAvailableTasks = 'Brak dostępnych zleceń w okolicy';
  static const String goOnline = 'Przejdź online';
  static const String goOffline = 'Przejdź offline';
  static const String youAreOnline = 'Jesteś online';
  static const String youAreOffline = 'Jesteś offline';

  // ============ Earnings ============
  static const String earnings = 'Zarobki';
  static const String todayEarnings = 'Dzisiaj';
  static const String weekEarnings = 'Ten tydzień';
  static const String monthEarnings = 'Ten miesiąc';
  static const String totalEarnings = 'Łącznie';
  static const String withdraw = 'Wypłać';
  static const String withdrawFunds = 'Wypłać środki';
  static const String availableBalance = 'Dostępne saldo';
  static const String pendingBalance = 'Oczekujące';
  static const String transactionHistory = 'Historia transakcji';

  // ============ Profile ============
  static const String profile = 'Profil';
  static const String editProfile = 'Edytuj profil';
  static const String myReviews = 'Moje opinie';
  static const String settings = 'Ustawienia';
  static const String help = 'Pomoc';
  static const String about = 'O aplikacji';
  static const String termsOfService = 'Regulamin';
  static const String privacyPolicy = 'Polityka prywatności';
  static const String version = 'Wersja';
  static const String completedTasks = 'Ukończone zlecenia';
  static const String rating = 'Ocena';
  static const String memberSince = 'Członek od';

  // ============ KYC ============
  static const String kycVerification = 'Weryfikacja tożsamości';
  static const String kycRequired = 'Wymagana weryfikacja';
  static const String kycDescription =
      'Aby przyjmować zlecenia, musisz zweryfikować swoją tożsamość';
  static const String startVerification = 'Rozpocznij weryfikację';
  static const String uploadId = 'Prześlij dokument tożsamości';
  static const String takeSelfie = 'Zrób selfie';
  static const String verificationPending = 'Weryfikacja w toku';
  static const String verificationApproved = 'Weryfikacja zatwierdzona';
  static const String verificationRejected = 'Weryfikacja odrzucona';

  // ============ Notifications ============
  static const String notifications = 'Powiadomienia';
  static const String noNotifications = 'Brak powiadomień';
  static const String markAllRead = 'Oznacz wszystkie jako przeczytane';

  // ============ Settings ============
  static const String notificationSettings = 'Ustawienia powiadomień';
  static const String pushNotifications = 'Powiadomienia push';
  static const String emailNotifications = 'Powiadomienia email';
  static const String smsNotifications = 'Powiadomienia SMS';
  static const String language = 'Język';
  static const String deleteAccount = 'Usuń konto';
  static const String deleteAccountWarning =
      'Czy na pewno chcesz usunąć konto? Ta operacja jest nieodwracalna.';

  // ============ Errors ============
  static const String errorGeneric = 'Wystąpił błąd. Spróbuj ponownie.';
  static const String errorNetwork = 'Brak połączenia z internetem';
  static const String errorServer = 'Błąd serwera. Spróbuj ponownie później.';
  static const String errorUnauthorized = 'Sesja wygasła. Zaloguj się ponownie.';
  static const String errorForbidden = 'Brak uprawnień do wykonania tej operacji';
  static const String errorNotFound = 'Nie znaleziono';
  static const String errorValidation = 'Nieprawidłowe dane';
  static const String errorLocationPermission = 'Wymagany dostęp do lokalizacji';
  static const String errorCameraPermission = 'Wymagany dostęp do kamery';

  // ============ Success Messages ============
  static const String taskCreated = 'Zlecenie zostało utworzone';
  static const String taskAccepted = 'Zlecenie zostało przyjęte';
  static const String taskCompleted = 'Zlecenie zostało zakończone';
  static const String taskCancelled = 'Zlecenie zostało anulowane';
  static const String ratingSubmitted = 'Dziękujemy za ocenę!';
  static const String profileUpdated = 'Profil został zaktualizowany';
  static const String withdrawalRequested = 'Wypłata została zlecona';

  // ============ Empty States ============
  static const String noTasks = 'Brak zleceń';
  static const String noTasksDescription = 'Nie masz jeszcze żadnych zleceń';
  static const String noHistory = 'Brak historii';
  static const String noHistoryDescription = 'Historia zleceń pojawi się tutaj';
  static const String noMessages = 'Brak wiadomości';
  static const String noMessagesDescription = 'Rozpocznij rozmowę';

  // ============ Time ============
  static const String today = 'Dzisiaj';
  static const String yesterday = 'Wczoraj';
  static const String justNow = 'Przed chwilą';
  static const String minutesAgo = 'min temu';
  static const String hoursAgo = 'godz. temu';
  static const String daysAgo = 'dni temu';

  // ============ Currency ============
  static const String currency = 'PLN';
  static const String currencySymbol = 'zł';
}
