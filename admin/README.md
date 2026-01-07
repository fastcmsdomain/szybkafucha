# Panel Administracyjny Szybka Fucha

Panel administracyjny do zarządzania użytkownikami, analizy danych z formularzy i monitorowania aktywności aplikacji.

## 📋 Spis treści

1. [Czym jest panel administracyjny?](#czym-jest-panel-administracyjny)
2. [Jak uruchomić panel?](#jak-uruchomić-panel)
3. [Logowanie](#logowanie)
4. [Przegląd sekcji](#przegląd-sekcji)
5. [Dashboard - Przegląd danych](#dashboard---przegląd-danych)
6. [Users - Zarządzanie użytkownikami](#users---zarządzanie-użytkownikami)
7. [Rozwiązywanie problemów](#rozwiązywanie-problemów)
8. [Wskazówki dla różnych ról](#wskazówki-dla-różnych-ról)

---

## Czym jest panel administracyjny?

Panel administracyjny to narzędzie, które pozwala:
- **Zobacz wszystkich użytkowników**, którzy wypełnili formularz na stronie
- **Analizuj statystyki** - ile osób się zapisało, kto jest aktywny
- **Przeglądaj komentarze i sugestie** użytkowników
- **Sprawdzaj, które usługi są najpopularniejsze**

---

## Jak uruchomić panel?

### Opcja 1: Panel już działa na serwerze (produkcja)

Jeśli panel jest już wdrożony na serwerze, po prostu otwórz w przeglądarce:
```
https://szybkafucha.app/admin
```
lub
```
https://admin.szybkafucha.app
```

### Opcja 2: Uruchomienie lokalne (dla developerów)

**Wymagania:**
- Node.js (wersja 16 lub nowsza)
- npm (zazwyczaj instalowany razem z Node.js)

**Kroki:**

1. **Otwórz terminal** (Terminal na Mac, PowerShell/CMD na Windows)

2. **Przejdź do folderu admin:**
   ```bash
   cd admin
   ```

3. **Zainstaluj zależności** (tylko pierwszy raz):
   ```bash
   npm install
   ```
   ⏱️ To może zająć 2-5 minut

4. **Uruchom panel:**
   ```bash
   npm start
   ```

5. **Otwórz przeglądarkę:**
   Panel automatycznie otworzy się na `http://localhost:3000`

   Jeśli nie otworzy się automatycznie, skopiuj adres `http://localhost:3000` i wklej w przeglądarce.

**Aby zatrzymać panel:**
- Naciśnij `Ctrl + C` w terminalu

---

## Logowanie

### Pierwsze logowanie

1. Otwórz panel administracyjny
2. Zobaczysz ekran logowania
3. **Dla pierwszego uruchomienia:** Skontaktuj się z administratorem systemu, aby otrzymać dane logowania

### Zapamiętanie logowania

Po zalogowaniu, panel zapamięta Twoją sesję. Nie musisz logować się za każdym razem, gdy otwierasz panel.

**Aby wylogować się:**
- Kliknij przycisk "Wyloguj" w prawym górnym rogu

---

## Przegląd sekcji

Panel składa się z kilku głównych sekcji dostępnych w menu po lewej stronie:

### 🏠 Dashboard
Przegląd wszystkich statystyk i najważniejszych danych na jednym ekranie.

### 👥 Users
Lista wszystkich użytkowników, którzy wypełnili formularz. Możesz przeglądać ich dane, komentarze i wybrane usługi.

### 📋 Tasks (W przygotowaniu)
Zarządzanie zleceniami w aplikacji.

### ⚖️ Disputes (W przygotowaniu)
Rozwiązywanie sporów między użytkownikami.

---

## Dashboard - Przegląd danych

Dashboard to główny ekran panelu, który pokazuje najważniejsze informacje na pierwszy rzut oka.

### Co zobaczysz na Dashboard?

#### 1. **Statystyki ogólne** (górna część ekranu)

Cztery kafelki z liczbami:
- **Wszystkich** - łączna liczba osób, które wypełniły formularz
- **Aktywnych** - liczba osób, które są nadal zapisane (zielony kolor)
- **Zleceniodawców** - liczba osób, które chcą zlecać pracę (niebieski kolor)
- **Wykonawców** - liczba osób, które chcą wykonywać pracę (fioletowy kolor)

**Przykład:**
```
Wszystkich: 150
Aktywnych: 142
Zleceniodawców: 95
Wykonawców: 55
```

#### 2. **Najpopularniejsze usługi**

Lista usług, które użytkownicy wybierali najczęściej, np.:
- 🧹 Sprzątanie - 45 wyborów
- 🏠 Montaż - 32 wybory
- 🌿 Ogród - 28 wyborów

**Jak to interpretować?**
- Im więcej wyborów, tym większe zainteresowanie tą usługą
- To pomaga zdecydować, które funkcje aplikacji rozwinąć w pierwszej kolejności

#### 3. **Ostatnio zapisani**

Lista 5 najnowszych użytkowników, którzy wypełnili formularz:
- Imię i nazwisko
- Email
- Data zapisu
- Typ użytkownika (Zleceniodawca/Wykonawca)

**Po co to?**
- Możesz szybko zobaczyć, kto się ostatnio zapisał
- Przydatne do szybkiego kontaktu z nowymi użytkownikami

#### 4. **Użytkownicy z komentarzami**

Liczba osób, które podzieliły się swoimi pomysłami lub sugestiami.

**Dlaczego to ważne?**
- Użytkownicy z komentarzami są bardziej zaangażowani
- Ich opinie mogą pomóc w rozwoju aplikacji

### Jak odświeżyć dane?

Kliknij przycisk **"🔄 Odśwież"** w prawym górnym rogu Dashboard. Panel pobierze najnowsze dane z bazy danych.

---

## Users - Zarządzanie użytkownikami

Sekcja Users pozwala przeglądać i analizować wszystkich użytkowników, którzy wypełnili formularz.

### Statystyki użytkowników

Na górze sekcji Users zobaczysz te same statystyki co na Dashboard:
- Wszystkich
- Aktywnych
- Zleceniodawców
- Wykonawców

### Filtrowanie i wyszukiwanie

#### Wyszukiwanie

W polu **"🔍 Szukaj..."** możesz wpisać:
- Imię użytkownika
- Email użytkownika
- Tekst z komentarza

**Przykład:**
- Wpiszesz "Jan" → zobaczysz wszystkich użytkowników o imieniu Jan
- Wpiszesz "@gmail.com" → zobaczysz wszystkich użytkowników z kontem Gmail
- Wpiszesz "sprzątanie" → zobaczysz użytkowników, którzy wspomnieli o sprzątaniu w komentarzu

#### Filtry

**Filtr "Typ użytkownika":**
- **Wszyscy typy** - pokazuje wszystkich
- **Zleceniodawcy** - tylko osoby, które chcą zlecać pracę
- **Wykonawcy** - tylko osoby, które chcą wykonywać pracę

**Filtr "Status":**
- **Wszystkie statusy** - pokazuje wszystkich
- **Aktywni** - tylko osoby, które są nadal zapisane
- **Nieaktywni** - osoby, które się wypisały

**Przykład użycia:**
Chcesz zobaczyć tylko aktywnych zleceniodawców?
1. Wybierz "Zleceniodawcy" w filtrze typu
2. Wybierz "Aktywni" w filtrze statusu
3. Zobaczysz tylko aktywnych zleceniodawców

### Tabela użytkowników

Tabela pokazuje wszystkich użytkowników z następującymi informacjami:

#### Kolumny w tabeli:

1. **Użytkownik**
   - Imię i nazwisko
   - Email (szary tekst poniżej)

2. **Typ**
   - **Zleceniodawca** (niebieska etykieta) - osoba, która chce zlecać pracę
   - **Wykonawca** (fioletowa etykieta) - osoba, która chce wykonywać pracę

3. **Status**
   - **Aktywny** (zielona etykieta) - użytkownik jest zapisany
   - **Nieaktywny** (czerwona etykieta) - użytkownik się wypisał

4. **Źródło**
   - Skąd użytkownik wypełnił formularz:
     - `formularz_ulepszen_apki` - formularz "Pomóż nam stworzyć lepszą aplikację"
     - `hero` - formularz na stronie głównej (Hero)
     - `banner` - formularz w banerze

5. **Usługi**
   - Lista usług, które użytkownik wybrał
   - Jeśli użytkownik wybrał więcej niż 2 usługi, zobaczysz pierwsze 2 + liczbę pozostałych (np. "+3")

6. **Data zapisu**
   - Data i godzina, kiedy użytkownik wypełnił formularz

7. **Akcje**
   - Przycisk **"👁️ Szczegóły"** - kliknij, aby zobaczyć pełne informacje o użytkowniku

### Szczegóły użytkownika

Aby zobaczyć pełne informacje o użytkowniku:

1. **Kliknij na wiersz** w tabeli lub przycisk **"👁️ Szczegóły"**
2. Pojawi się panel szczegółów nad tabelą

#### Co zobaczysz w szczegółach:

**Dane podstawowe:**
- Imię i nazwisko
- Email
- Typ użytkownika (Zleceniodawca/Wykonawca)
- Źródło zapisu

**Interesujące usługi:**
- Lista wszystkich usług wybranych przez użytkownika
- Każda usługa ma emoji i nazwę (np. 🧹 Sprzątanie)

**Komentarz / Sugestie:**
- Pełny tekst komentarza użytkownika
- Jeśli użytkownik nie zostawił komentarza, zobaczysz "Brak komentarza"

**Daty:**
- Data zapisu
- Ostatnia aktualizacja
- Data wypisania (jeśli użytkownik się wypisał)

**Zgoda RODO:**
- ✓ Wyrażona (zielona etykieta) - użytkownik wyraził zgodę
- ✗ Brak zgody (czerwona etykieta) - użytkownik nie wyraził zgody

**Aby zamknąć szczegóły:**
- Kliknij przycisk **"✕ Zamknij"** w prawym górnym rogu panelu szczegółów

### Odświeżanie danych

Kliknij przycisk **"🔄 Odśwież"** w prawym górnym rogu, aby pobrać najnowsze dane z bazy danych.

---

## Rozwiązywanie problemów

### Problem: Panel nie ładuje się / pokazuje błąd

**Rozwiązanie:**
1. Sprawdź, czy masz połączenie z internetem
2. Odśwież stronę (F5 lub Ctrl+R)
3. Wyczyść cache przeglądarki (Ctrl+Shift+Delete)
4. Spróbuj w innej przeglądarce

### Problem: Nie widzę żadnych użytkowników

**Możliwe przyczyny:**
1. **Brak użytkowników w bazie** - nikt jeszcze nie wypełnił formularza
2. **Filtry są zbyt restrykcyjne** - sprawdź, czy nie masz włączonych filtrów, które wykluczają wszystkich użytkowników
3. **Problem z połączeniem do API** - sprawdź konsolę przeglądarki (F12 → Console)

**Rozwiązanie:**
- Wyłącz wszystkie filtry (ustaw na "Wszyscy")
- Wyczyść pole wyszukiwania
- Kliknij "🔄 Odśwież"

### Problem: Dane są nieaktualne

**Rozwiązanie:**
- Kliknij przycisk **"🔄 Odśwież"** w prawym górnym rogu
- Panel pobierze najnowsze dane z bazy danych

### Problem: Nie mogę się zalogować

**Rozwiązanie:**
1. Sprawdź, czy wpisujesz poprawne dane logowania
2. Skontaktuj się z administratorem systemu
3. Sprawdź, czy masz dostęp do panelu administracyjnego

### Problem: Panel działa wolno

**Możliwe przyczyny:**
1. Duża liczba użytkowników w bazie
2. Wolne połączenie internetowe
3. Problemy z serwerem

**Rozwiązanie:**
- Użyj filtrów, aby ograniczyć liczbę wyświetlanych użytkowników
- Sprawdź połączenie internetowe
- Skontaktuj się z administratorem, jeśli problem się utrzymuje

---

## Wskazówki dla różnych ról

### 👨‍💼 Dla Marketerów

**Co warto sprawdzać codziennie:**
1. **Dashboard** - zobacz, ile nowych osób się zapisało
2. **Najpopularniejsze usługi** - które usługi są najbardziej pożądane?
3. **Użytkownicy z komentarzami** - co użytkownicy mówią o aplikacji?

**Jak wykorzystać dane:**
- **Najpopularniejsze usługi** → skup się na promowaniu tych usług w kampaniach
- **Komentarze użytkowników** → znajdź inspiracje do treści marketingowych
- **Stosunek zleceniodawców do wykonawców** → dostosuj komunikację do większej grupy

**Przykład analizy:**
```
Jeśli widzisz:
- 100 zleceniodawców
- 20 wykonawców

To znaczy, że:
- Musisz więcej reklamować aplikację wśród wykonawców
- Albo aplikacja jest bardziej atrakcyjna dla zleceniodawców
```

### 👨‍💻 Dla Junior Developerów

**Jak uruchomić panel lokalnie:**
1. Otwórz terminal
2. Przejdź do folderu `admin`
3. Uruchom `npm install` (tylko pierwszy raz)
4. Uruchom `npm start`
5. Otwórz `http://localhost:3000`

**Gdzie znajdę kod?**
- `admin/src/pages/Dashboard.tsx` - kod Dashboard
- `admin/src/pages/Users.tsx` - kod sekcji Users
- `admin/src/App.tsx` - główny plik aplikacji

**Jak działa połączenie z bazą danych?**
- Panel pobiera dane z API: `https://szybkafucha.app/api/subscribers.php`
- API zwraca dane w formacie JSON
- Panel wyświetla te dane w czytelnej formie

**Przydatne komendy:**
```bash
npm start          # Uruchom panel w trybie deweloperskim
npm run build      # Zbuduj panel do produkcji
npm test           # Uruchom testy (jeśli są)
```

### 📞 Dla Customer Service

**Jak znaleźć użytkownika:**
1. Przejdź do sekcji **Users**
2. W polu wyszukiwania wpisz:
   - Imię użytkownika
   - Email użytkownika
   - Część komentarza (jeśli pamiętasz)

**Jak sprawdzić szczegóły użytkownika:**
1. Znajdź użytkownika w tabeli
2. Kliknij na wiersz lub przycisk **"👁️ Szczegóły"**
3. Zobaczysz wszystkie informacje:
   - Email (do kontaktu)
   - Wybrane usługi
   - Komentarze/sugestie
   - Status (czy jest aktywny)

**Jak odpowiedzieć na pytania użytkownika:**
- **"Kiedy aplikacja będzie gotowa?"** → Sprawdź komentarze innych użytkowników, może znajdziesz podobne pytania
- **"Czy moje dane są bezpieczne?"** → Użytkownik wyraził zgodę RODO (zobaczysz to w szczegółach)
- **"Jak mogę się wypisać?"** → Status użytkownika pokazuje, czy jest aktywny czy nieaktywny

**Przykład rozmowy z użytkownikiem:**
```
Użytkownik: "Zapisałem się, ale nie widzę aplikacji"
Odpowiedź: "Dziękujemy za zapisanie się! Widzę, że jesteś zapisany jako [Typ użytkownika]. 
Aplikacja jest w fazie rozwoju. Twoje sugestie pomagają nam ją ulepszać. 
Powiadomimy Cię, gdy aplikacja będzie gotowa."
```

---

## Często zadawane pytania (FAQ)

### Q: Jak często aktualizują się dane?
A: Dane są pobierane z bazy danych w czasie rzeczywistym. Kliknij "🔄 Odśwież", aby zobaczyć najnowsze dane.

### Q: Czy mogę edytować dane użytkowników?
A: Obecnie panel pozwala tylko na przeglądanie danych. Edycja będzie dostępna w przyszłych wersjach.

### Q: Jak eksportować dane?
A: Funkcja eksportu będzie dostępna w przyszłych wersjach. Na razie możesz skopiować dane ręcznie z tabeli.

### Q: Co oznacza "Źródło" w danych użytkownika?
A: "Źródło" pokazuje, z którego formularza użytkownik się zapisał:
- `formularz_ulepszen_apki` - formularz "Pomóż nam stworzyć lepszą aplikację"
- `hero` - formularz na stronie głównej
- `banner` - formularz w banerze

### Q: Dlaczego nie widzę niektórych użytkowników?
A: Sprawdź filtry - mogą być zbyt restrykcyjne. Ustaw wszystkie filtry na "Wszyscy" i wyczyść pole wyszukiwania.

---

## Wsparcie techniczne

Jeśli napotkasz problem, którego nie możesz rozwiązać:

1. **Sprawdź sekcję "Rozwiązywanie problemów"** powyżej
2. **Skontaktuj się z administratorem systemu**
3. **Sprawdź konsolę przeglądarki** (F12 → Console) - może zawierać informacje o błędzie

---

## Aktualizacje

Panel jest regularnie aktualizowany. Nowe funkcje będą dodawane stopniowo.

**Ostatnia aktualizacja:** Styczeń 2026

---

**Powodzenia w korzystaniu z panelu administracyjnego! 🚀**
