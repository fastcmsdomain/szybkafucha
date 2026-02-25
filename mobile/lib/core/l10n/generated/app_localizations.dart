import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_pl.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('pl'),
    Locale('uk'),
  ];

  /// No description provided for @appName.
  ///
  /// In pl, this message translates to:
  /// **'SzybkaFucha'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc jest bliżej niż myślisz'**
  String get appTagline;

  /// No description provided for @loading.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie...'**
  String get loading;

  /// No description provided for @error.
  ///
  /// In pl, this message translates to:
  /// **'Błąd'**
  String get error;

  /// No description provided for @success.
  ///
  /// In pl, this message translates to:
  /// **'Sukces'**
  String get success;

  /// No description provided for @cancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź'**
  String get confirm;

  /// No description provided for @save.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In pl, this message translates to:
  /// **'Usuń'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj'**
  String get edit;

  /// No description provided for @close.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij'**
  String get close;

  /// No description provided for @back.
  ///
  /// In pl, this message translates to:
  /// **'Wróć'**
  String get back;

  /// No description provided for @next.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get next;

  /// No description provided for @done.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe'**
  String get done;

  /// No description provided for @retry.
  ///
  /// In pl, this message translates to:
  /// **'Spróbuj ponownie'**
  String get retry;

  /// No description provided for @yes.
  ///
  /// In pl, this message translates to:
  /// **'Tak'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In pl, this message translates to:
  /// **'Nie'**
  String get no;

  /// No description provided for @ok.
  ///
  /// In pl, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @search.
  ///
  /// In pl, this message translates to:
  /// **'Szukaj'**
  String get search;

  /// No description provided for @noResults.
  ///
  /// In pl, this message translates to:
  /// **'Brak wyników'**
  String get noResults;

  /// No description provided for @seeAll.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz wszystkie'**
  String get seeAll;

  /// No description provided for @continueText.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj'**
  String get continueText;

  /// No description provided for @selectCategory.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz kategorię'**
  String get selectCategory;

  /// No description provided for @schedule.
  ///
  /// In pl, this message translates to:
  /// **'Termin'**
  String get schedule;

  /// No description provided for @now.
  ///
  /// In pl, this message translates to:
  /// **'Teraz'**
  String get now;

  /// No description provided for @scheduleForLater.
  ///
  /// In pl, this message translates to:
  /// **'Zaplanuj na później'**
  String get scheduleForLater;

  /// No description provided for @activeTasks.
  ///
  /// In pl, this message translates to:
  /// **'Aktywne zlecenia'**
  String get activeTasks;

  /// No description provided for @viewHistory.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz historię'**
  String get viewHistory;

  /// No description provided for @noActiveTasks.
  ///
  /// In pl, this message translates to:
  /// **'Brak aktywnych zleceń'**
  String get noActiveTasks;

  /// No description provided for @welcomeTitle.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc jest bliżej niż myślisz'**
  String get welcomeTitle;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Znajdź pomocnika do drobnych zadań w kilka minut'**
  String get welcomeSubtitle;

  /// No description provided for @iNeedHelp.
  ///
  /// In pl, this message translates to:
  /// **'Szukam pomocy'**
  String get iNeedHelp;

  /// No description provided for @iWantToEarn.
  ///
  /// In pl, this message translates to:
  /// **'Chcę pomagać i zarabiać'**
  String get iWantToEarn;

  /// No description provided for @termsAgreement.
  ///
  /// In pl, this message translates to:
  /// **'Dołączając, akceptujesz Regulamin i Politykę Prywatności'**
  String get termsAgreement;

  /// No description provided for @login.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In pl, this message translates to:
  /// **'Wyloguj się'**
  String get logout;

  /// No description provided for @register.
  ///
  /// In pl, this message translates to:
  /// **'Zarejestruj się'**
  String get register;

  /// No description provided for @continueWithGoogle.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z Apple'**
  String get continueWithApple;

  /// No description provided for @continueWithPhone.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj z numerem telefonu'**
  String get continueWithPhone;

  /// No description provided for @orContinueWith.
  ///
  /// In pl, this message translates to:
  /// **'lub kontynuuj przez'**
  String get orContinueWith;

  /// No description provided for @phoneNumber.
  ///
  /// In pl, this message translates to:
  /// **'Numer telefonu'**
  String get phoneNumber;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz numer telefonu'**
  String get enterPhoneNumber;

  /// No description provided for @sendCode.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij kod'**
  String get sendCode;

  /// No description provided for @verificationCode.
  ///
  /// In pl, this message translates to:
  /// **'Kod weryfikacyjny'**
  String get verificationCode;

  /// No description provided for @enterCode.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz kod z SMS'**
  String get enterCode;

  /// No description provided for @resendCode.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij ponownie'**
  String get resendCode;

  /// No description provided for @resendCodeIn.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij ponownie za'**
  String get resendCodeIn;

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy numer telefonu'**
  String get invalidPhoneNumber;

  /// No description provided for @invalidCode.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowy kod'**
  String get invalidCode;

  /// No description provided for @codeSent.
  ///
  /// In pl, this message translates to:
  /// **'Kod został wysłany'**
  String get codeSent;

  /// No description provided for @yourName.
  ///
  /// In pl, this message translates to:
  /// **'Twoje imię'**
  String get yourName;

  /// No description provided for @enterYourName.
  ///
  /// In pl, this message translates to:
  /// **'Wpisz swoje imię'**
  String get enterYourName;

  /// No description provided for @selectUserType.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz typ konta'**
  String get selectUserType;

  /// No description provided for @iAmClient.
  ///
  /// In pl, this message translates to:
  /// **'Szukam pomocy'**
  String get iAmClient;

  /// No description provided for @iAmContractor.
  ///
  /// In pl, this message translates to:
  /// **'Chcę pomagać'**
  String get iAmContractor;

  /// No description provided for @clientDescription.
  ///
  /// In pl, this message translates to:
  /// **'Znajdź pomocników do drobnych zadań'**
  String get clientDescription;

  /// No description provided for @contractorDescription.
  ///
  /// In pl, this message translates to:
  /// **'Zarabiaj pomagając innym'**
  String get contractorDescription;

  /// No description provided for @categories.
  ///
  /// In pl, this message translates to:
  /// **'Kategorie'**
  String get categories;

  /// No description provided for @categoryPackages.
  ///
  /// In pl, this message translates to:
  /// **'Paczki'**
  String get categoryPackages;

  /// No description provided for @categoryShopping.
  ///
  /// In pl, this message translates to:
  /// **'Zakupy'**
  String get categoryShopping;

  /// No description provided for @categoryQueues.
  ///
  /// In pl, this message translates to:
  /// **'Kolejki'**
  String get categoryQueues;

  /// No description provided for @categoryAssembly.
  ///
  /// In pl, this message translates to:
  /// **'Montaż'**
  String get categoryAssembly;

  /// No description provided for @categoryMoving.
  ///
  /// In pl, this message translates to:
  /// **'Przeprowadzki'**
  String get categoryMoving;

  /// No description provided for @categoryCleaning.
  ///
  /// In pl, this message translates to:
  /// **'Sprzątanie'**
  String get categoryCleaning;

  /// No description provided for @createTask.
  ///
  /// In pl, this message translates to:
  /// **'Utwórz zlecenie'**
  String get createTask;

  /// No description provided for @taskTitle.
  ///
  /// In pl, this message translates to:
  /// **'Tytuł zlecenia'**
  String get taskTitle;

  /// No description provided for @taskDescription.
  ///
  /// In pl, this message translates to:
  /// **'Opis zlecenia'**
  String get taskDescription;

  /// No description provided for @describeTask.
  ///
  /// In pl, this message translates to:
  /// **'Opisz zadanie...'**
  String get describeTask;

  /// No description provided for @taskLocation.
  ///
  /// In pl, this message translates to:
  /// **'Lokalizacja'**
  String get taskLocation;

  /// No description provided for @selectLocation.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz lokalizację'**
  String get selectLocation;

  /// No description provided for @taskBudget.
  ///
  /// In pl, this message translates to:
  /// **'Budżet'**
  String get taskBudget;

  /// No description provided for @suggestedBudget.
  ///
  /// In pl, this message translates to:
  /// **'Sugerowany budżet'**
  String get suggestedBudget;

  /// No description provided for @taskDate.
  ///
  /// In pl, this message translates to:
  /// **'Data wykonania'**
  String get taskDate;

  /// No description provided for @selectDate.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz datę'**
  String get selectDate;

  /// No description provided for @taskTime.
  ///
  /// In pl, this message translates to:
  /// **'Godzina'**
  String get taskTime;

  /// No description provided for @selectTime.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz godzinę'**
  String get selectTime;

  /// No description provided for @asap.
  ///
  /// In pl, this message translates to:
  /// **'Jak najszybciej'**
  String get asap;

  /// No description provided for @postTask.
  ///
  /// In pl, this message translates to:
  /// **'Opublikuj zlecenie'**
  String get postTask;

  /// No description provided for @statusPosted.
  ///
  /// In pl, this message translates to:
  /// **'Opublikowane'**
  String get statusPosted;

  /// No description provided for @statusAccepted.
  ///
  /// In pl, this message translates to:
  /// **'Zaakceptowane'**
  String get statusAccepted;

  /// No description provided for @statusInProgress.
  ///
  /// In pl, this message translates to:
  /// **'W trakcie'**
  String get statusInProgress;

  /// No description provided for @statusCompleted.
  ///
  /// In pl, this message translates to:
  /// **'Zakończone'**
  String get statusCompleted;

  /// No description provided for @statusCancelled.
  ///
  /// In pl, this message translates to:
  /// **'Anulowane'**
  String get statusCancelled;

  /// No description provided for @statusDisputed.
  ///
  /// In pl, this message translates to:
  /// **'Sporne'**
  String get statusDisputed;

  /// No description provided for @taskDetails.
  ///
  /// In pl, this message translates to:
  /// **'Szczegóły zlecenia'**
  String get taskDetails;

  /// No description provided for @postedBy.
  ///
  /// In pl, this message translates to:
  /// **'Zleceniodawca'**
  String get postedBy;

  /// No description provided for @acceptedBy.
  ///
  /// In pl, this message translates to:
  /// **'Wykonawca'**
  String get acceptedBy;

  /// No description provided for @budget.
  ///
  /// In pl, this message translates to:
  /// **'Budżet'**
  String get budget;

  /// No description provided for @location.
  ///
  /// In pl, this message translates to:
  /// **'Lokalizacja'**
  String get location;

  /// No description provided for @dateTime.
  ///
  /// In pl, this message translates to:
  /// **'Data i godzina'**
  String get dateTime;

  /// No description provided for @description.
  ///
  /// In pl, this message translates to:
  /// **'Opis'**
  String get description;

  /// No description provided for @acceptTask.
  ///
  /// In pl, this message translates to:
  /// **'Przyjmij zlecenie'**
  String get acceptTask;

  /// No description provided for @cancelTask.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj zlecenie'**
  String get cancelTask;

  /// No description provided for @completeTask.
  ///
  /// In pl, this message translates to:
  /// **'Zakończ zlecenie'**
  String get completeTask;

  /// No description provided for @reportProblem.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoś problem'**
  String get reportProblem;

  /// No description provided for @tracking.
  ///
  /// In pl, this message translates to:
  /// **'Śledzenie'**
  String get tracking;

  /// No description provided for @contractorOnTheWay.
  ///
  /// In pl, this message translates to:
  /// **'Wykonawca w drodze'**
  String get contractorOnTheWay;

  /// No description provided for @estimatedArrival.
  ///
  /// In pl, this message translates to:
  /// **'Szacowany czas przybycia'**
  String get estimatedArrival;

  /// No description provided for @minutes.
  ///
  /// In pl, this message translates to:
  /// **'min'**
  String get minutes;

  /// No description provided for @arrived.
  ///
  /// In pl, this message translates to:
  /// **'Na miejscu'**
  String get arrived;

  /// No description provided for @workInProgress.
  ///
  /// In pl, this message translates to:
  /// **'Praca w toku'**
  String get workInProgress;

  /// No description provided for @chat.
  ///
  /// In pl, this message translates to:
  /// **'Czat'**
  String get chat;

  /// No description provided for @typeMessage.
  ///
  /// In pl, this message translates to:
  /// **'Napisz wiadomość...'**
  String get typeMessage;

  /// No description provided for @send.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij'**
  String get send;

  /// No description provided for @messageDelivered.
  ///
  /// In pl, this message translates to:
  /// **'Dostarczono'**
  String get messageDelivered;

  /// No description provided for @messageRead.
  ///
  /// In pl, this message translates to:
  /// **'Przeczytano'**
  String get messageRead;

  /// No description provided for @rateTask.
  ///
  /// In pl, this message translates to:
  /// **'Oceń zlecenie'**
  String get rateTask;

  /// No description provided for @howWasService.
  ///
  /// In pl, this message translates to:
  /// **'Jak oceniasz wykonaną usługę?'**
  String get howWasService;

  /// No description provided for @leaveReview.
  ///
  /// In pl, this message translates to:
  /// **'Zostaw opinię (opcjonalnie)'**
  String get leaveReview;

  /// No description provided for @submitRating.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij ocenę'**
  String get submitRating;

  /// No description provided for @addTip.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj napiwek'**
  String get addTip;

  /// No description provided for @tipAmount.
  ///
  /// In pl, this message translates to:
  /// **'Kwota napiwku'**
  String get tipAmount;

  /// No description provided for @availableTasks.
  ///
  /// In pl, this message translates to:
  /// **'Dostępne zlecenia'**
  String get availableTasks;

  /// No description provided for @myTasks.
  ///
  /// In pl, this message translates to:
  /// **'Moje zlecenia'**
  String get myTasks;

  /// No description provided for @noAvailableTasks.
  ///
  /// In pl, this message translates to:
  /// **'Brak dostępnych zleceń w okolicy'**
  String get noAvailableTasks;

  /// No description provided for @earnings.
  ///
  /// In pl, this message translates to:
  /// **'Zarobki'**
  String get earnings;

  /// No description provided for @todayEarnings.
  ///
  /// In pl, this message translates to:
  /// **'Dzisiaj'**
  String get todayEarnings;

  /// No description provided for @weekEarnings.
  ///
  /// In pl, this message translates to:
  /// **'Ten tydzień'**
  String get weekEarnings;

  /// No description provided for @monthEarnings.
  ///
  /// In pl, this message translates to:
  /// **'Ten miesiąc'**
  String get monthEarnings;

  /// No description provided for @totalEarnings.
  ///
  /// In pl, this message translates to:
  /// **'Łącznie'**
  String get totalEarnings;

  /// No description provided for @withdraw.
  ///
  /// In pl, this message translates to:
  /// **'Wypłać'**
  String get withdraw;

  /// No description provided for @withdrawFunds.
  ///
  /// In pl, this message translates to:
  /// **'Wypłać środki'**
  String get withdrawFunds;

  /// No description provided for @availableBalance.
  ///
  /// In pl, this message translates to:
  /// **'Dostępne saldo'**
  String get availableBalance;

  /// No description provided for @pendingBalance.
  ///
  /// In pl, this message translates to:
  /// **'Oczekujące'**
  String get pendingBalance;

  /// No description provided for @transactionHistory.
  ///
  /// In pl, this message translates to:
  /// **'Historia transakcji'**
  String get transactionHistory;

  /// No description provided for @menuHome.
  ///
  /// In pl, this message translates to:
  /// **'Główna'**
  String get menuHome;

  /// No description provided for @menuTasks.
  ///
  /// In pl, this message translates to:
  /// **'Zlecenia'**
  String get menuTasks;

  /// No description provided for @menuProfile.
  ///
  /// In pl, this message translates to:
  /// **'Profil'**
  String get menuProfile;

  /// No description provided for @profile.
  ///
  /// In pl, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @editProfile.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj profil'**
  String get editProfile;

  /// No description provided for @myReviews.
  ///
  /// In pl, this message translates to:
  /// **'Moje opinie'**
  String get myReviews;

  /// No description provided for @settings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get settings;

  /// No description provided for @help.
  ///
  /// In pl, this message translates to:
  /// **'Pomoc'**
  String get help;

  /// No description provided for @about.
  ///
  /// In pl, this message translates to:
  /// **'O aplikacji'**
  String get about;

  /// No description provided for @termsOfService.
  ///
  /// In pl, this message translates to:
  /// **'Regulamin'**
  String get termsOfService;

  /// No description provided for @privacyPolicy.
  ///
  /// In pl, this message translates to:
  /// **'Polityka prywatności'**
  String get privacyPolicy;

  /// No description provided for @version.
  ///
  /// In pl, this message translates to:
  /// **'Wersja'**
  String get version;

  /// No description provided for @completedTasks.
  ///
  /// In pl, this message translates to:
  /// **'Ukończone zlecenia'**
  String get completedTasks;

  /// No description provided for @rating.
  ///
  /// In pl, this message translates to:
  /// **'Ocena'**
  String get rating;

  /// No description provided for @memberSince.
  ///
  /// In pl, this message translates to:
  /// **'Członek od'**
  String get memberSince;

  /// No description provided for @kycVerification.
  ///
  /// In pl, this message translates to:
  /// **'Weryfikacja tożsamości'**
  String get kycVerification;

  /// No description provided for @kycRequired.
  ///
  /// In pl, this message translates to:
  /// **'Wymagana weryfikacja'**
  String get kycRequired;

  /// No description provided for @kycDescription.
  ///
  /// In pl, this message translates to:
  /// **'Aby przyjmować zlecenia, musisz zweryfikować swoją tożsamość'**
  String get kycDescription;

  /// No description provided for @startVerification.
  ///
  /// In pl, this message translates to:
  /// **'Rozpocznij weryfikację'**
  String get startVerification;

  /// No description provided for @uploadId.
  ///
  /// In pl, this message translates to:
  /// **'Prześlij dokument tożsamości'**
  String get uploadId;

  /// No description provided for @takeSelfie.
  ///
  /// In pl, this message translates to:
  /// **'Zrób selfie'**
  String get takeSelfie;

  /// No description provided for @verificationPending.
  ///
  /// In pl, this message translates to:
  /// **'Weryfikacja w toku'**
  String get verificationPending;

  /// No description provided for @verificationApproved.
  ///
  /// In pl, this message translates to:
  /// **'Weryfikacja zatwierdzona'**
  String get verificationApproved;

  /// No description provided for @verificationRejected.
  ///
  /// In pl, this message translates to:
  /// **'Weryfikacja odrzucona'**
  String get verificationRejected;

  /// No description provided for @notifications.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia'**
  String get notifications;

  /// No description provided for @noNotifications.
  ///
  /// In pl, this message translates to:
  /// **'Brak powiadomień'**
  String get noNotifications;

  /// No description provided for @markAllRead.
  ///
  /// In pl, this message translates to:
  /// **'Oznacz wszystkie jako przeczytane'**
  String get markAllRead;

  /// No description provided for @notificationSettings.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia powiadomień'**
  String get notificationSettings;

  /// No description provided for @pushNotifications.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia push'**
  String get pushNotifications;

  /// No description provided for @emailNotifications.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia email'**
  String get emailNotifications;

  /// No description provided for @smsNotifications.
  ///
  /// In pl, this message translates to:
  /// **'Powiadomienia SMS'**
  String get smsNotifications;

  /// No description provided for @language.
  ///
  /// In pl, this message translates to:
  /// **'Język'**
  String get language;

  /// No description provided for @deleteAccount.
  ///
  /// In pl, this message translates to:
  /// **'Usuń konto'**
  String get deleteAccount;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno chcesz usunąć konto? Ta operacja jest nieodwracalna.'**
  String get deleteAccountWarning;

  /// No description provided for @errorGeneric.
  ///
  /// In pl, this message translates to:
  /// **'Wystąpił błąd. Spróbuj ponownie.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In pl, this message translates to:
  /// **'Brak połączenia z internetem'**
  String get errorNetwork;

  /// No description provided for @errorServer.
  ///
  /// In pl, this message translates to:
  /// **'Błąd serwera. Spróbuj ponownie później.'**
  String get errorServer;

  /// No description provided for @errorUnauthorized.
  ///
  /// In pl, this message translates to:
  /// **'Sesja wygasła. Zaloguj się ponownie.'**
  String get errorUnauthorized;

  /// No description provided for @errorForbidden.
  ///
  /// In pl, this message translates to:
  /// **'Brak uprawnień do wykonania tej operacji'**
  String get errorForbidden;

  /// No description provided for @errorNotFound.
  ///
  /// In pl, this message translates to:
  /// **'Nie znaleziono'**
  String get errorNotFound;

  /// No description provided for @errorValidation.
  ///
  /// In pl, this message translates to:
  /// **'Nieprawidłowe dane'**
  String get errorValidation;

  /// No description provided for @errorLocationPermission.
  ///
  /// In pl, this message translates to:
  /// **'Wymagany dostęp do lokalizacji'**
  String get errorLocationPermission;

  /// No description provided for @errorCameraPermission.
  ///
  /// In pl, this message translates to:
  /// **'Wymagany dostęp do kamery'**
  String get errorCameraPermission;

  /// No description provided for @taskCreated.
  ///
  /// In pl, this message translates to:
  /// **'Zlecenie zostało utworzone'**
  String get taskCreated;

  /// No description provided for @taskAccepted.
  ///
  /// In pl, this message translates to:
  /// **'Zlecenie zostało przyjęte'**
  String get taskAccepted;

  /// No description provided for @taskCompleted.
  ///
  /// In pl, this message translates to:
  /// **'Zlecenie zostało zakończone'**
  String get taskCompleted;

  /// No description provided for @taskCancelled.
  ///
  /// In pl, this message translates to:
  /// **'Zlecenie zostało anulowane'**
  String get taskCancelled;

  /// No description provided for @ratingSubmitted.
  ///
  /// In pl, this message translates to:
  /// **'Dziękujemy za ocenę!'**
  String get ratingSubmitted;

  /// No description provided for @profileUpdated.
  ///
  /// In pl, this message translates to:
  /// **'Profil został zaktualizowany'**
  String get profileUpdated;

  /// No description provided for @withdrawalRequested.
  ///
  /// In pl, this message translates to:
  /// **'Wypłata została zlecona'**
  String get withdrawalRequested;

  /// No description provided for @noTasks.
  ///
  /// In pl, this message translates to:
  /// **'Brak zleceń'**
  String get noTasks;

  /// No description provided for @noTasksDescription.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz jeszcze żadnych zleceń'**
  String get noTasksDescription;

  /// No description provided for @noHistory.
  ///
  /// In pl, this message translates to:
  /// **'Brak historii'**
  String get noHistory;

  /// No description provided for @noHistoryDescription.
  ///
  /// In pl, this message translates to:
  /// **'Historia zleceń pojawi się tutaj'**
  String get noHistoryDescription;

  /// No description provided for @noMessages.
  ///
  /// In pl, this message translates to:
  /// **'Brak wiadomości'**
  String get noMessages;

  /// No description provided for @noMessagesDescription.
  ///
  /// In pl, this message translates to:
  /// **'Rozpocznij rozmowę'**
  String get noMessagesDescription;

  /// No description provided for @today.
  ///
  /// In pl, this message translates to:
  /// **'Dzisiaj'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In pl, this message translates to:
  /// **'Wczoraj'**
  String get yesterday;

  /// No description provided for @justNow.
  ///
  /// In pl, this message translates to:
  /// **'Przed chwilą'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In pl, this message translates to:
  /// **'min temu'**
  String get minutesAgo;

  /// No description provided for @hoursAgo.
  ///
  /// In pl, this message translates to:
  /// **'godz. temu'**
  String get hoursAgo;

  /// No description provided for @daysAgo.
  ///
  /// In pl, this message translates to:
  /// **'dni temu'**
  String get daysAgo;

  /// No description provided for @currency.
  ///
  /// In pl, this message translates to:
  /// **'PLN'**
  String get currency;

  /// No description provided for @currencySymbol.
  ///
  /// In pl, this message translates to:
  /// **'zł'**
  String get currencySymbol;

  /// No description provided for @onboardingTitle1.
  ///
  /// In pl, this message translates to:
  /// **'Potrzebujesz pomocy?'**
  String get onboardingTitle1;

  /// No description provided for @onboardingSubtitle1.
  ///
  /// In pl, this message translates to:
  /// **'Znajdź ją w 5 minut'**
  String get onboardingSubtitle1;

  /// No description provided for @onboardingDescription1.
  ///
  /// In pl, this message translates to:
  /// **'Szybka Fucha łączy Cię z pomocnikami w Twojej okolicy'**
  String get onboardingDescription1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In pl, this message translates to:
  /// **'Szybko, prosto, bezpiecznie'**
  String get onboardingTitle2;

  /// No description provided for @onboardingSubtitle2.
  ///
  /// In pl, this message translates to:
  /// **'Zweryfikowani wykonawcy'**
  String get onboardingSubtitle2;

  /// No description provided for @onboardingDescription2.
  ///
  /// In pl, this message translates to:
  /// **'System ocen i bezpieczne płatności'**
  String get onboardingDescription2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In pl, this message translates to:
  /// **'Zarabiaj lub zlecaj'**
  String get onboardingTitle3;

  /// No description provided for @onboardingSubtitle3.
  ///
  /// In pl, this message translates to:
  /// **'Wybór należy do Ciebie'**
  String get onboardingSubtitle3;

  /// No description provided for @onboardingDescription3.
  ///
  /// In pl, this message translates to:
  /// **'Przeglądaj dostępne zlecenia i zacznij działać już teraz'**
  String get onboardingDescription3;

  /// No description provided for @onboardingSkip.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get onboardingNext;

  /// No description provided for @onboardingStart.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz zlecenia'**
  String get onboardingStart;

  /// No description provided for @publicBrowseTitle.
  ///
  /// In pl, this message translates to:
  /// **'Dostępne zlecenia'**
  String get publicBrowseTitle;

  /// No description provided for @publicBrowseAddTask.
  ///
  /// In pl, this message translates to:
  /// **'Dodaj zlecenie'**
  String get publicBrowseAddTask;

  /// No description provided for @publicBrowseLoginPromptTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get publicBrowseLoginPromptTitle;

  /// No description provided for @publicBrowseLoginPromptMessage.
  ///
  /// In pl, this message translates to:
  /// **'Aby dodać zlecenie, musisz się najpierw zalogować.'**
  String get publicBrowseLoginPromptMessage;

  /// No description provided for @publicBrowseLoginPromptCancel.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj'**
  String get publicBrowseLoginPromptCancel;

  /// No description provided for @publicBrowseLoginPromptConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Zaloguj się'**
  String get publicBrowseLoginPromptConfirm;

  /// No description provided for @accountSection.
  ///
  /// In pl, this message translates to:
  /// **'Konto'**
  String get accountSection;

  /// No description provided for @payments.
  ///
  /// In pl, this message translates to:
  /// **'Płatności'**
  String get payments;

  /// No description provided for @paymentsCardsPayouts.
  ///
  /// In pl, this message translates to:
  /// **'Karty i konto do wypłat'**
  String get paymentsCardsPayouts;

  /// No description provided for @reviews.
  ///
  /// In pl, this message translates to:
  /// **'Opinie'**
  String get reviews;

  /// No description provided for @security.
  ///
  /// In pl, this message translates to:
  /// **'Bezpieczeństwo'**
  String get security;

  /// No description provided for @preferences.
  ///
  /// In pl, this message translates to:
  /// **'Preferencje'**
  String get preferences;

  /// No description provided for @support.
  ///
  /// In pl, this message translates to:
  /// **'Wsparcie'**
  String get support;

  /// No description provided for @userFallback.
  ///
  /// In pl, this message translates to:
  /// **'Użytkownik'**
  String get userFallback;

  /// No description provided for @contractorLabel.
  ///
  /// In pl, this message translates to:
  /// **'Wykonawca'**
  String get contractorLabel;

  /// No description provided for @clientLabel.
  ///
  /// In pl, this message translates to:
  /// **'Klient'**
  String get clientLabel;

  /// No description provided for @logoutConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno chcesz się wylogować?'**
  String get logoutConfirm;

  /// No description provided for @accountDeleteLongWarning.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno chcesz usunąć swoje konto? Ta operacja jest nieodwracalna i wszystkie Twoje dane zostaną trwale usunięte.'**
  String get accountDeleteLongWarning;

  /// No description provided for @chooseLanguage.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz język'**
  String get chooseLanguage;

  /// No description provided for @languagePolish.
  ///
  /// In pl, this message translates to:
  /// **'Polski'**
  String get languagePolish;

  /// No description provided for @languageUkrainian.
  ///
  /// In pl, this message translates to:
  /// **'Українська'**
  String get languageUkrainian;

  /// No description provided for @versionWithNumber.
  ///
  /// In pl, this message translates to:
  /// **'Wersja 1.0.0'**
  String get versionWithNumber;

  /// No description provided for @taskListMapTab.
  ///
  /// In pl, this message translates to:
  /// **'MAPA'**
  String get taskListMapTab;

  /// No description provided for @taskListListTab.
  ///
  /// In pl, this message translates to:
  /// **'LISTA'**
  String get taskListListTab;

  /// No description provided for @taskListFilters.
  ///
  /// In pl, this message translates to:
  /// **'Filtry'**
  String get taskListFilters;

  /// No description provided for @taskListSelectedFiltersCount.
  ///
  /// In pl, this message translates to:
  /// **'{count} wybrane'**
  String taskListSelectedFiltersCount(int count);

  /// No description provided for @taskListClearFilters.
  ///
  /// In pl, this message translates to:
  /// **'Wyczyść'**
  String get taskListClearFilters;

  /// No description provided for @taskListMultiSelectHint.
  ///
  /// In pl, this message translates to:
  /// **'Możesz zaznaczyć wiele kategorii'**
  String get taskListMultiSelectHint;

  /// No description provided for @taskListNoCategoriesToFilter.
  ///
  /// In pl, this message translates to:
  /// **'Brak kategorii do filtrowania'**
  String get taskListNoCategoriesToFilter;

  /// No description provided for @taskListTasksCount.
  ///
  /// In pl, this message translates to:
  /// **'{count} zleceń'**
  String taskListTasksCount(int count);

  /// No description provided for @taskListMapEmptyHint.
  ///
  /// In pl, this message translates to:
  /// **'Na mapie pojawią się zlecenia,\ngdy będą dostępne.'**
  String get taskListMapEmptyHint;

  /// No description provided for @taskListNoTasksForSelectedCategories.
  ///
  /// In pl, this message translates to:
  /// **'Brak zleceń dla wybranych kategorii.'**
  String get taskListNoTasksForSelectedCategories;

  /// No description provided for @taskListLoadingTasks.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie zleceń...'**
  String get taskListLoadingTasks;

  /// No description provided for @taskListKycRequiredToApply.
  ///
  /// In pl, this message translates to:
  /// **'Aby aplikować na zlecenia, musisz najpierw zweryfikować swoją tożsamość.'**
  String get taskListKycRequiredToApply;

  /// No description provided for @taskListApplyDialogTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoś się do zlecenia'**
  String get taskListApplyDialogTitle;

  /// No description provided for @taskListClientBudget.
  ///
  /// In pl, this message translates to:
  /// **'Budżet klienta: {price} zł'**
  String taskListClientBudget(String price);

  /// No description provided for @taskListYourPriceLabel.
  ///
  /// In pl, this message translates to:
  /// **'Twoja cena (zł)'**
  String get taskListYourPriceLabel;

  /// No description provided for @taskListMinPriceHint.
  ///
  /// In pl, this message translates to:
  /// **'Min. 35 zł'**
  String get taskListMinPriceHint;

  /// No description provided for @taskListMessageOptional.
  ///
  /// In pl, this message translates to:
  /// **'Wiadomość (opcjonalnie)'**
  String get taskListMessageOptional;

  /// No description provided for @taskListExperienceHint.
  ///
  /// In pl, this message translates to:
  /// **'Opisz swoje doświadczenie...'**
  String get taskListExperienceHint;

  /// No description provided for @taskListSendApplication.
  ///
  /// In pl, this message translates to:
  /// **'Wyślij zgłoszenie'**
  String get taskListSendApplication;

  /// No description provided for @taskListMinimumPriceError.
  ///
  /// In pl, this message translates to:
  /// **'Minimalna cena to 35 zł'**
  String get taskListMinimumPriceError;

  /// No description provided for @taskListApplicationSent.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszenie wysłane! Czekaj na decyzję klienta.'**
  String get taskListApplicationSent;

  /// No description provided for @taskTrackingYou.
  ///
  /// In pl, this message translates to:
  /// **'Ty'**
  String get taskTrackingYou;

  /// No description provided for @taskTrackingRefreshStatus.
  ///
  /// In pl, this message translates to:
  /// **'Odśwież status'**
  String get taskTrackingRefreshStatus;

  /// No description provided for @taskTrackingMoreOptions.
  ///
  /// In pl, this message translates to:
  /// **'Więcej opcji'**
  String get taskTrackingMoreOptions;

  /// No description provided for @taskTrackingNoAddress.
  ///
  /// In pl, this message translates to:
  /// **'Brak adresu'**
  String get taskTrackingNoAddress;

  /// No description provided for @taskTrackingNoDescription.
  ///
  /// In pl, this message translates to:
  /// **'Brak opisu'**
  String get taskTrackingNoDescription;

  /// No description provided for @taskTrackingScheduleNow.
  ///
  /// In pl, this message translates to:
  /// **'Termin: Teraz'**
  String get taskTrackingScheduleNow;

  /// No description provided for @taskTrackingScheduleAt.
  ///
  /// In pl, this message translates to:
  /// **'Termin: {dateTime}'**
  String taskTrackingScheduleAt(String dateTime);

  /// No description provided for @taskTrackingScheduleUnset.
  ///
  /// In pl, this message translates to:
  /// **'Termin: Nie określono'**
  String get taskTrackingScheduleUnset;

  /// No description provided for @taskTrackingScheduleUnspecified.
  ///
  /// In pl, this message translates to:
  /// **'Nie określono'**
  String get taskTrackingScheduleUnspecified;

  /// No description provided for @taskTrackingStatusApplicationsTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszenia wykonawców'**
  String get taskTrackingStatusApplicationsTitle;

  /// No description provided for @taskTrackingStatusConfirmedTitle.
  ///
  /// In pl, this message translates to:
  /// **'Wykonawca potwierdzony'**
  String get taskTrackingStatusConfirmedTitle;

  /// No description provided for @taskTrackingStatusInProgressTitle.
  ///
  /// In pl, this message translates to:
  /// **'Praca w toku'**
  String get taskTrackingStatusInProgressTitle;

  /// No description provided for @taskTrackingStatusCompletedTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zakończone'**
  String get taskTrackingStatusCompletedTitle;

  /// No description provided for @taskTrackingStatusApplicationsSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Czekamy na zgłoszenia...'**
  String get taskTrackingStatusApplicationsSubtitle;

  /// No description provided for @taskTrackingStatusConfirmedSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Czekamy na rozpoczęcie pracy'**
  String get taskTrackingStatusConfirmedSubtitle;

  /// No description provided for @taskTrackingStatusInProgressSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Zadanie jest realizowane'**
  String get taskTrackingStatusInProgressSubtitle;

  /// No description provided for @taskTrackingStatusCompletedSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Zadanie zostało ukończone'**
  String get taskTrackingStatusCompletedSubtitle;

  /// No description provided for @taskTrackingStepApplications.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszenia'**
  String get taskTrackingStepApplications;

  /// No description provided for @taskTrackingStepConfirmed.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdzony'**
  String get taskTrackingStepConfirmed;

  /// No description provided for @taskTrackingStepInProgress.
  ///
  /// In pl, this message translates to:
  /// **'W trakcie'**
  String get taskTrackingStepInProgress;

  /// No description provided for @taskTrackingStepDone.
  ///
  /// In pl, this message translates to:
  /// **'Gotowe'**
  String get taskTrackingStepDone;

  /// No description provided for @taskTrackingLoadingApplications.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie zgłoszeń...'**
  String get taskTrackingLoadingApplications;

  /// No description provided for @taskTrackingApplicationsLoadErrorTitle.
  ///
  /// In pl, this message translates to:
  /// **'Błąd ładowania zgłoszeń'**
  String get taskTrackingApplicationsLoadErrorTitle;

  /// No description provided for @taskTrackingWaitingForApplications.
  ///
  /// In pl, this message translates to:
  /// **'Czekamy na zgłoszenia wykonawców...'**
  String get taskTrackingWaitingForApplications;

  /// No description provided for @taskTrackingWaitingForApplicationsSubtitle.
  ///
  /// In pl, this message translates to:
  /// **'Wykonawcy z Twojej okolicy będą się zgłaszać z proponowaną ceną'**
  String get taskTrackingWaitingForApplicationsSubtitle;

  /// No description provided for @taskTrackingApplicationsCount.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszenia ({current}/{max})'**
  String taskTrackingApplicationsCount(int current, int max);

  /// No description provided for @taskTrackingAcceptFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się zaakceptować: {error}'**
  String taskTrackingAcceptFailed(String error);

  /// No description provided for @taskTrackingRejectFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się odrzucić: {error}'**
  String taskTrackingRejectFailed(String error);

  /// No description provided for @taskTrackingReviewsCount.
  ///
  /// In pl, this message translates to:
  /// **'{count} opinii'**
  String taskTrackingReviewsCount(int count);

  /// No description provided for @taskTrackingShowContractorProfile.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż profil wykonawcy'**
  String get taskTrackingShowContractorProfile;

  /// No description provided for @taskTrackingConfirmCompletion.
  ///
  /// In pl, this message translates to:
  /// **'Potwierdź zakończenie'**
  String get taskTrackingConfirmCompletion;

  /// No description provided for @taskTrackingCancelling.
  ///
  /// In pl, this message translates to:
  /// **'Anulowanie...'**
  String get taskTrackingCancelling;

  /// No description provided for @taskTrackingSupportSubject.
  ///
  /// In pl, this message translates to:
  /// **'Zgłoszenie problemu - zlecenie {taskId}'**
  String taskTrackingSupportSubject(String taskId);

  /// No description provided for @taskTrackingSupportDescribeProblem.
  ///
  /// In pl, this message translates to:
  /// **'Opisz problem:'**
  String get taskTrackingSupportDescribeProblem;

  /// No description provided for @taskTrackingSupportContextHeader.
  ///
  /// In pl, this message translates to:
  /// **'--- Kontekst ---'**
  String get taskTrackingSupportContextHeader;

  /// No description provided for @taskTrackingSupportTaskId.
  ///
  /// In pl, this message translates to:
  /// **'Task ID: {taskId}'**
  String taskTrackingSupportTaskId(String taskId);

  /// No description provided for @taskTrackingSupportStatus.
  ///
  /// In pl, this message translates to:
  /// **'Status: {status}'**
  String taskTrackingSupportStatus(String status);

  /// No description provided for @taskTrackingSupportCategory.
  ///
  /// In pl, this message translates to:
  /// **'Kategoria: {category}'**
  String taskTrackingSupportCategory(String category);

  /// No description provided for @taskTrackingNoCategory.
  ///
  /// In pl, this message translates to:
  /// **'brak'**
  String get taskTrackingNoCategory;

  /// No description provided for @taskTrackingOpenMailFailed.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się otworzyć aplikacji pocztowej'**
  String get taskTrackingOpenMailFailed;

  /// No description provided for @taskTrackingOpenMailFailedWithError.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się otworzyć aplikacji pocztowej: {error}'**
  String taskTrackingOpenMailFailedWithError(String error);

  /// No description provided for @taskTrackingImages.
  ///
  /// In pl, this message translates to:
  /// **'Zdjęcia'**
  String get taskTrackingImages;

  /// No description provided for @taskTrackingShowTaskImage.
  ///
  /// In pl, this message translates to:
  /// **'Pokaż zdjęcie zlecenia'**
  String get taskTrackingShowTaskImage;

  /// No description provided for @taskTrackingCloseImagePreview.
  ///
  /// In pl, this message translates to:
  /// **'Zamknij podgląd zdjęcia'**
  String get taskTrackingCloseImagePreview;

  /// No description provided for @taskTrackingCancelDialogTitle.
  ///
  /// In pl, this message translates to:
  /// **'Anuluj zlecenie?'**
  String get taskTrackingCancelDialogTitle;

  /// No description provided for @taskTrackingCancelDialogContent.
  ///
  /// In pl, this message translates to:
  /// **'Czy na pewno chcesz anulować to zlecenie? Może to wiązać się z opłatą.'**
  String get taskTrackingCancelDialogContent;

  /// No description provided for @taskTrackingCancelDialogConfirm.
  ///
  /// In pl, this message translates to:
  /// **'Tak, anuluj'**
  String get taskTrackingCancelDialogConfirm;

  /// No description provided for @taskTrackingCancelError.
  ///
  /// In pl, this message translates to:
  /// **'Błąd anulowania: {error}'**
  String taskTrackingCancelError(String error);

  /// No description provided for @taskTrackingNoComment.
  ///
  /// In pl, this message translates to:
  /// **'Brak komentarza.'**
  String get taskTrackingNoComment;

  /// No description provided for @taskTrackingBasedOnReviews.
  ///
  /// In pl, this message translates to:
  /// **'na podstawie {count} opinii'**
  String taskTrackingBasedOnReviews(int count);

  /// No description provided for @taskTrackingNoReviewsToDisplay.
  ///
  /// In pl, this message translates to:
  /// **'Brak opinii do wyświetlenia.'**
  String get taskTrackingNoReviewsToDisplay;

  /// No description provided for @taskTrackingContractorProfile.
  ///
  /// In pl, this message translates to:
  /// **'Profil wykonawcy'**
  String get taskTrackingContractorProfile;

  /// No description provided for @taskTrackingFailedToLoadProfile.
  ///
  /// In pl, this message translates to:
  /// **'Nie udało się pobrać pełnego profilu'**
  String get taskTrackingFailedToLoadProfile;

  /// No description provided for @taskTrackingNoContractorDescription.
  ///
  /// In pl, this message translates to:
  /// **'Brak opisu wykonawcy.'**
  String get taskTrackingNoContractorDescription;

  /// No description provided for @taskTrackingDateOfBirth.
  ///
  /// In pl, this message translates to:
  /// **'Data urodzenia'**
  String get taskTrackingDateOfBirth;

  /// No description provided for @taskListAllTab.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko'**
  String get taskListAllTab;

  /// No description provided for @taskListEarningsTab.
  ///
  /// In pl, this message translates to:
  /// **'Przychody'**
  String get taskListEarningsTab;

  /// No description provided for @taskListWithdrawalsTab.
  ///
  /// In pl, this message translates to:
  /// **'Wypłaty'**
  String get taskListWithdrawalsTab;

  /// No description provided for @earningsMinimumWithdrawInfo.
  ///
  /// In pl, this message translates to:
  /// **'Minimalna kwota wypłaty: 50 zł'**
  String get earningsMinimumWithdrawInfo;

  /// No description provided for @earningsWithdrawButtonLabel.
  ///
  /// In pl, this message translates to:
  /// **'Wypłać {amount} zł'**
  String earningsWithdrawButtonLabel(String amount);

  /// No description provided for @earningsWithdrawRequested.
  ///
  /// In pl, this message translates to:
  /// **'Zlecono wypłatę {amount} zł'**
  String earningsWithdrawRequested(String amount);

  /// No description provided for @earningsInfoTitle.
  ///
  /// In pl, this message translates to:
  /// **'O zarobkach'**
  String get earningsInfoTitle;

  /// No description provided for @earningsInfoEarningsDescription.
  ///
  /// In pl, this message translates to:
  /// **'Zarobki z ukończonych zleceń'**
  String get earningsInfoEarningsDescription;

  /// No description provided for @earningsInfoPendingDescription.
  ///
  /// In pl, this message translates to:
  /// **'Środki czekające na potwierdzenie klienta'**
  String get earningsInfoPendingDescription;

  /// No description provided for @earningsInfoWithdrawalsDescription.
  ///
  /// In pl, this message translates to:
  /// **'Przelewy na Twoje konto bankowe'**
  String get earningsInfoWithdrawalsDescription;

  /// No description provided for @earningsInfoCommissionTitle.
  ///
  /// In pl, this message translates to:
  /// **'Prowizja'**
  String get earningsInfoCommissionTitle;

  /// No description provided for @earningsInfoCommissionDescription.
  ///
  /// In pl, this message translates to:
  /// **'Platforma pobiera 17% od każdego zlecenia'**
  String get earningsInfoCommissionDescription;

  /// No description provided for @earningsWithdrawInfoText.
  ///
  /// In pl, this message translates to:
  /// **'Środki zostaną przelane na Twoje konto bankowe w ciągu 1-3 dni roboczych.'**
  String get earningsWithdrawInfoText;

  /// No description provided for @earningsAmountInvalid.
  ///
  /// In pl, this message translates to:
  /// **'Wprowadź poprawną kwotę'**
  String get earningsAmountInvalid;

  /// No description provided for @earningsMinimumWithdrawError.
  ///
  /// In pl, this message translates to:
  /// **'Minimalna kwota wypłaty to 50 zł'**
  String get earningsMinimumWithdrawError;

  /// No description provided for @earningsInsufficientFunds.
  ///
  /// In pl, this message translates to:
  /// **'Nie masz wystarczających środków'**
  String get earningsInsufficientFunds;

  /// No description provided for @genericErrorWithPrefix.
  ///
  /// In pl, this message translates to:
  /// **'Błąd: {error}'**
  String genericErrorWithPrefix(String error);

  /// No description provided for @comingSoon.
  ///
  /// In pl, this message translates to:
  /// **'{feature} - wkrótce dostępne'**
  String comingSoon(String feature);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['pl', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'pl':
      return AppLocalizationsPl();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
