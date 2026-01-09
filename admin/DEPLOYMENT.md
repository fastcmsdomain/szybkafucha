# Wdrożenie Panelu Administracyjnego Szybka Fucha

Kompletna instrukcja wdrożenia panelu administracyjnego na serwer produkcyjny.

## 📋 Spis treści

1. [Wymagania](#wymagania)
2. [Struktura plików](#struktura-plików)
3. [Krok po kroku - Wdrożenie](#krok-po-kroku---wdrożenie)
4. [Konfiguracja serwera](#konfiguracja-serwera)
5. [Aktualizacja panelu](#aktualizacja-panelu)
6. [Rozwiązywanie problemów](#rozwiązywanie-problemów)

---

## Wymagania

### Serwer
- Serwer WWW (Apache, Nginx, LiteSpeed)
- PHP 7.4+ (dla API)
- MySQL/MariaDB (baza danych)
- SSL/HTTPS (zalecane)

### Lokalne środowisko (do budowania)
- Node.js 16+
- npm 8+

---

## Struktura plików

### Co jest czym?

`
szybkafucha/
├── admin/                      # Panel administracyjny (React)
│   ├── src/                    # Kod źródłowy (NIE wgrywać na serwer)
│   ├── build/                  # Zbudowana aplikacja (TO wgrywamy!)
│   │   ├── index.html          # Główny plik HTML
│   │   ├── static/             # Pliki JS, CSS
│   │   │   └── js/
│   │   │       └── main.*.js   # Skompilowany kod React
│   │   ├── favicon.ico
│   │   ├── manifest.json
│   │   └── robots.txt
│   ├── package.json
│   └── DEPLOYMENT.md           # Ta dokumentacja
│
├── api/                        # Backend PHP (API)
│   ├── config.php              # Konfiguracja bazy danych
│   ├── subscribe.php           # API zapisu do newslettera
│   └── subscribers.php         # API pobierania użytkowników
│
├── index.html                  # Landing page
├── styles.css                  # Style landing page
└── script.js                   # JavaScript landing page
`

---

## Krok po kroku - Wdrożenie

### Krok 1: Zbuduj panel administracyjny

Na swoim komputerze (lokalnie):

`bash
# Przejdź do folderu admin
cd admin

# Zainstaluj zależności (jeśli jeszcze nie zainstalowane)
npm install

# Zbuduj aplikację produkcyjną
npm run build
`

Po zakończeniu w folderze `admin/build/` pojawią się zbudowane pliki.

### Krok 2: Przygotuj strukturę na serwerze

Struktura katalogów na serwerze powinna wyglądać tak:

`
/public_html/                    # lub /var/www/html/ lub /htdocs/
├── index.html                   # Landing page
├── styles.css
├── script.js
├── assets/                      # Obrazki, video
├── api/                         # Backend PHP
│   ├── config.php
│   ├── subscribe.php
│   └── subscribers.php
└── admin/                       # Panel administracyjny
    ├── index.html
    ├── static/
    │   └── js/
    │       └── main.*.js
    ├── favicon.ico
    ├── manifest.json
    └── robots.txt
`

### Krok 3: Wgraj pliki na serwer

#### Opcja A: Przez FTP/SFTP (FileZilla, WinSCP, Cyberduck)

1. Połącz się z serwerem przez FTP/SFTP
2. Przejdź do katalogu głównego strony (np. `public_html`)
3. **Wgraj folder `api/`** - cały folder z plikami PHP
4. **Stwórz folder `admin/`** na serwerze
5. **Wgraj zawartość `admin/build/`** do folderu `admin/` na serwerze

**WAŻNE:** Wgrywasz zawartość folderu `build/`, NIE sam folder `build/`!

`
Lokalnie:                        Na serwerze:
admin/build/index.html     →     admin/index.html
admin/build/static/        →     admin/static/
admin/build/favicon.ico    →     admin/favicon.ico
`

#### Opcja B: Przez SSH/terminal

`bash
# Połącz się z serwerem
ssh user@szybkafucha.app

# Przejdź do katalogu strony
cd /var/www/html

# Stwórz folder admin (jeśli nie istnieje)
mkdir -p admin

# Na komputerze lokalnym - wyślij pliki
scp -r admin/build/* user@szybkafucha.app:/var/www/html/admin/
scp -r api/* user@szybkafucha.app:/var/www/html/api/
`

#### Opcja C: Przez panel hostingowy (cPanel, DirectAdmin)

1. Zaloguj się do panelu hostingowego
2. Otwórz "File Manager" / "Menedżer plików"
3. Przejdź do `public_html`
4. Stwórz folder `admin`
5. Wgraj pliki z `admin/build/` do folderu `admin`
6. Wgraj pliki z `api/` do folderu `api`

### Krok 4: Skonfiguruj API

Edytuj plik `api/config.php` na serwerze:

`php
<?php
// Konfiguracja bazy danych
define('DB_HOST', 'localhost');           // Host bazy danych
define('DB_NAME', 'nazwa_bazy');          // Nazwa bazy danych
define('DB_USER', 'uzytkownik');          // Użytkownik bazy
define('DB_PASS', 'haslo');               // Hasło do bazy

// Dozwolone domeny (CORS)
define('ALLOWED_ORIGIN', 'https://szybkafucha.app');
`

### Krok 5: Sprawdź uprawnienia plików

Na serwerze Linux ustaw odpowiednie uprawnienia:

`bash
# Pliki PHP - tylko odczyt i wykonanie
chmod 644 api/*.php

# Folder admin - odczyt
chmod 755 admin/
chmod 644 admin/*
chmod 755 admin/static/
chmod 755 admin/static/js/
chmod 644 admin/static/js/*
`

### Krok 6: Przetestuj

1. **Sprawdź API:** Otwórz `https://szybkafucha.app/api/subscribers.php`
   - Powinieneś zobaczyć JSON z danymi użytkowników

2. **Sprawdź panel:** Otwórz `https://szybkafucha.app/admin/`
   - Powinieneś zobaczyć panel administracyjny

---

## Konfiguracja serwera

### Apache (.htaccess)

Jeśli używasz Apache, stwórz plik `admin/.htaccess`:

`apache
<IfModule mod_rewrite.c>
  RewriteEngine On
  RewriteBase /admin/
  RewriteRule ^index\.html$ - [L]
  RewriteCond %{REQUEST_FILENAME} !-f
  RewriteCond %{REQUEST_FILENAME} !-d
  RewriteCond %{REQUEST_FILENAME} !-l
  RewriteRule . /admin/index.html [L]
</IfModule>

# Kompresja
<IfModule mod_deflate.c>
  AddOutputFilterByType DEFLATE text/html text/plain text/css application/javascript application/json
</IfModule>

# Cache
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType text/css "access plus 1 year"
  ExpiresByType application/javascript "access plus 1 year"
  ExpiresByType image/png "access plus 1 year"
  ExpiresByType image/jpeg "access plus 1 year"
</IfModule>
`

### Nginx

Jeśli używasz Nginx, dodaj do konfiguracji:

`nginx
location /admin {
    alias /var/www/html/admin;
    try_files $uri $uri/ /admin/index.html;
    
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}

location /api {
    alias /var/www/html/api;
    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_param SCRIPT_FILENAME $request_filename;
        include fastcgi_params;
    }
}
`

---

## Aktualizacja panelu

Gdy wprowadzisz zmiany w kodzie panelu:

### 1. Zbuduj nową wersję

`bash
cd admin
npm run build
`

### 2. Wgraj nowe pliki

Wgraj **tylko zmienione pliki** z `admin/build/` na serwer:

- Głównie: `admin/static/js/main.*.js` (nazwa pliku się zmieni!)
- Opcjonalnie: `admin/index.html`

### 3. Wyczyść cache przeglądarki

Poinformuj użytkowników, aby wyczyscili cache (Ctrl+Shift+R) lub:
- Pliki JS mają unikalne nazwy (hash), więc cache powinien się zaktualizować automatycznie

---

## Rozwiązywanie problemów

### Problem: Panel pokazuje białą stronę

**Przyczyna:** Brak pliku `index.html` lub nieprawidłowa ścieżka

**Rozwiązanie:**
1. Sprawdź czy `admin/index.html` istnieje na serwerze
2. Sprawdź czy `admin/static/js/main.*.js` istnieje
3. Otwórz konsolę przeglądarki (F12) i sprawdź błędy

### Problem: "Failed to fetch" / Błąd ładowania danych

**Przyczyna:** Problem z API lub CORS

**Rozwiązanie:**
1. Sprawdź czy API działa: `https://szybkafucha.app/api/subscribers.php`
2. Sprawdź `api/config.php` - dane do bazy danych
3. Sprawdź logi PHP na serwerze
4. Upewnij się, że `ALLOWED_ORIGIN` w `config.php` jest poprawny

### Problem: 404 Not Found dla /admin

**Przyczyna:** Folder `admin` nie istnieje lub nieprawidłowe uprawnienia

**Rozwiązanie:**
1. Sprawdź czy folder `admin/` istnieje
2. Sprawdź uprawnienia: `chmod 755 admin/`
3. Sprawdź konfigurację serwera (Apache/Nginx)

### Problem: Stara wersja panelu mimo aktualizacji

**Przyczyna:** Cache przeglądarki

**Rozwiązanie:**
1. Wyczyść cache: Ctrl+Shift+R (hard refresh)
2. Lub: Ctrl+Shift+Delete → Wyczyść cache
3. Lub: Otwórz w trybie prywatnym/incognito

---

## Checklist wdrożenia

- [ ] Zbudowano panel: `npm run build`
- [ ] Wgrano `api/config.php` z poprawnymi danymi bazy
- [ ] Wgrano `api/subscribe.php`
- [ ] Wgrano `api/subscribers.php`
- [ ] Stworzono folder `admin/` na serwerze
- [ ] Wgrano zawartość `admin/build/` do `admin/`
- [ ] Ustawiono uprawnienia plików
- [ ] API działa: `/api/subscribers.php` zwraca JSON
- [ ] Panel działa: `/admin/` wyświetla się poprawnie
- [ ] Dane użytkowników ładują się w panelu

---

## Szybkie komendy

`bash
# Zbuduj panel
cd admin && npm run build

# Wyślij na serwer (SSH)
scp -r admin/build/* user@server:/var/www/html/admin/

# Sprawdź API
curl https://szybkafucha.app/api/subscribers.php

# Sprawdź logi PHP (na serwerze)
tail -f /var/log/apache2/error.log
# lub
tail -f /var/log/nginx/error.log
`

---

## Kontakt

W razie problemów:
- Sprawdź logi serwera
- Sprawdź konsolę przeglądarki (F12)
- Skontaktuj się z administratorem

---

**Ostatnia aktualizacja:** Styczeń 2026

