# Backend Deployment Guide

## 📦 Pliki do skopiowania na serwer

### ✅ WYMAGANE pliki:

```
backend/
├── dist/                    # Skompilowany kod JavaScript (lub zbuduj na serwerze)
├── package.json             # Zależności i skrypty
├── package-lock.json        # Dokładne wersje zależności
└── .env                     # Konfiguracja (stwórz na serwerze, NIE kopiuj z repo!)
```

### ❌ NIE kopiuj:

```
backend/
├── src/                     # Kod źródłowy TypeScript (niepotrzebny w produkcji)
├── test/                    # Testy (niepotrzebne w produkcji)
├── node_modules/            # Zainstaluj na serwerze przez npm
├── tsconfig.json            # Konfiguracja TypeScript (tylko do build)
├── tsconfig.build.json      # Konfiguracja build (tylko do build)
├── nest-cli.json            # Konfiguracja NestJS CLI (tylko do build)
├── eslint.config.mjs        # Linter (narzędzie dev)
├── .prettierrc              # Formatter (narzędzie dev)
└── README.md                # Dokumentacja (opcjonalnie)
```

---

## 🚀 Instrukcja deploymentu

### Opcja 1: Build lokalnie + kopiuj dist (Zalecane)

**Krok 1: Zbuduj projekt lokalnie**
```bash
cd backend
npm install
npm run build
```

**Krok 2: Skopiuj na serwer**
```bash
# Skopiuj tylko potrzebne pliki
scp -r dist/ user@server:/path/to/backend/
scp package.json user@server:/path/to/backend/
scp package-lock.json user@server:/path/to/backend/
```

**Krok 3: Na serwerze**
```bash
cd /path/to/backend
npm ci --production  # Instaluje tylko dependencies (bez devDependencies)
```

---

### Opcja 2: Build na serwerze

**Krok 1: Skopiuj źródła na serwer**
```bash
# Skopiuj pliki potrzebne do build
scp -r src/ user@server:/path/to/backend/
scp package.json user@server:/path/to/backend/
scp package-lock.json user@server:/path/to/backend/
scp tsconfig.json user@server:/path/to/backend/
scp tsconfig.build.json user@server:/path/to/backend/
scp nest-cli.json user@server:/path/to/backend/
```

**Krok 2: Na serwerze**
```bash
cd /path/to/backend
npm install
npm run build
npm ci --production  # Usuń devDependencies po build
```

---

## ⚙️ Konfiguracja (.env)

**Stwórz plik `.env` na serwerze** z następującymi zmiennymi:

```env
# Environment
NODE_ENV=production

# Server
PORT=3000
API_PREFIX=api/v1

# Database (PostgreSQL)
DATABASE_HOST=localhost
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha
DATABASE_PASSWORD=twoje_bezpieczne_haslo
DATABASE_NAME=szybkafucha

# CORS - URL landing page (WAŻNE!)
# Ustaw dokładny URL landing page, aby CORS działał poprawnie
LANDING_PAGE_URL=https://szybkafucha.app

# Frontend URLs (opcjonalnie)
FRONTEND_URL=https://app.szybkafucha.app
ADMIN_URL=https://admin.szybkafucha.app

# JWT Secret (wygeneruj bezpieczny klucz)
JWT_SECRET=twoj_bardzo_dlugi_i_bezpieczny_secret_key_minimum_32_znaki

# SMTP (wymagane do email verification i resetu hasla)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=noreply@szybkafucha.app
SMTP_PASSWORD=twoje_haslo_smtp
SMTP_FROM=Szybka Fucha <noreply@szybkafucha.app>
# Opcjonalne; jesli brak, aplikacja ustawi true dla portu 465
SMTP_SECURE=false

# Stripe (jeśli używasz płatności)
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...

# Onfido (jeśli używasz weryfikacji KYC)
ONFIDO_API_TOKEN=...

# SMS/OTP Provider (jeśli używasz)
# Dodaj konfigurację swojego providera
```

**Email verification**
- Rejestracja email dla `client` i `contractor` korzysta z tego samego szablonu OTP.
- Bez poprawnej konfiguracji `SMTP_*` backend zapisze kod OTP, ale nie dostarczy maila do użytkownika.
- Po wdrozeniu wykonaj smoke test: rejestracja, resend verification i reset hasla.

**⚠️ WAŻNE:**
- NIE commituj pliku `.env` do git (jest w `.gitignore`)
- Użyj silnych haseł w produkcji
- Wygeneruj nowy `JWT_SECRET` dla produkcji

---

## 🏃 Uruchomienie

### Uruchomienie bezpośrednie:
```bash
cd /path/to/backend
npm run start:prod
```

### Uruchomienie z PM2 (Zalecane dla produkcji):
```bash
# Zainstaluj PM2 globalnie
npm install -g pm2

# Uruchom aplikację
pm2 start dist/main.js --name szybkafucha-api

# Zapisz konfigurację PM2
pm2 save
pm2 startup  # Uruchomi się automatycznie po restarcie serwera
```

### Uruchomienie jako systemd service:
Stwórz plik `/etc/systemd/system/szybkafucha-api.service`:

```ini
[Unit]
Description=Szybka Fucha API
After=network.target postgresql.service

[Service]
Type=simple
User=www-data
WorkingDirectory=/path/to/backend
Environment=NODE_ENV=production
ExecStart=/usr/bin/node dist/main.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Następnie:
```bash
sudo systemctl daemon-reload
sudo systemctl enable szybkafucha-api
sudo systemctl start szybkafucha-api
```

---

## 🔧 Konfiguracja Nginx (Reverse Proxy)

Jeśli chcesz, aby API było dostępne pod `https://szybkafucha.app/api/`:

```nginx
server {
    listen 80;
    server_name szybkafucha.app;

    # Landing page (statyczne pliki)
    location / {
        root /var/www/szybkafucha;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Alternatywnie - osobny subdomena:**
```nginx
# api.szybkafucha.app
server {
    listen 80;
    server_name api.szybkafucha.app;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**⚠️ Pamiętaj:**
- Jeśli używasz osobnego subdomena (`api.szybkafucha.app`), zaktualizuj `script.js` w rootcie projektu
- Skonfiguruj SSL (Let's Encrypt) dla HTTPS

---

## ✅ Weryfikacja

Po uruchomieniu sprawdź:

1. **Health check:**
```bash
curl http://localhost:3000/api/v1/health
```

2. **Newsletter endpoint (test lokalny):**
```bash
curl -X POST http://localhost:3000/api/v1/newsletter/subscribe \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com","userType":"client","consent":true,"source":"test"}'
```

3. **Newsletter endpoint (test produkcyjny):**
```bash
curl -X POST https://api.szybkafucha.app/api/v1/newsletter/subscribe \
  -H "Content-Type: application/json" \
  -H "Origin: https://szybkafucha.app" \
  -d '{"name":"Test User","email":"test@example.com","userType":"client","consent":true,"source":"landing_page"}'
```

**Oczekiwana odpowiedź:**
```json
{
  "success": true,
  "message": "Dziękujemy za zapisanie się do newslettera!"
}
```

3. **Logi:**
```bash
# PM2
pm2 logs szybkafucha-api

# systemd
sudo journalctl -u szybkafucha-api -f
```

---

## 📝 Checklist przed deploymentem

- [ ] Zbudowano projekt (`npm run build`)
- [ ] Skopiowano `dist/`, `package.json`, `package-lock.json`
- [ ] Utworzono plik `.env` na serwerze z wszystkimi zmiennymi
- [ ] Zainstalowano zależności (`npm ci --production`)
- [ ] Skonfigurowano bazę danych PostgreSQL
- [ ] Uruchomiono migracje bazy danych (jeśli są)
- [ ] Skonfigurowano reverse proxy (nginx)
- [ ] Skonfigurowano SSL/HTTPS
- [ ] Przetestowano endpoint `/api/v1/health`
- [ ] Przetestowano endpoint `/api/v1/newsletter/subscribe`
- [ ] Skonfigurowano automatyczne uruchamianie (PM2/systemd)
- [ ] Skonfigurowano logi i monitoring

---

---

## 📧 Newsletter API - Dokumentacja

### Endpoint: POST /api/v1/newsletter/subscribe

**URL produkcyjny:** `https://api.szybkafucha.app/api/v1/newsletter/subscribe`

**Request Body:**
```json
{
  "name": "Jan Kowalski",
  "email": "jan@example.com",
  "userType": "client",
  "consent": true,
  "source": "landing_page"
}
```

**Pola:**
| Pole | Typ | Wymagane | Opis |
|------|-----|----------|------|
| name | string | ✅ | Imię i nazwisko (2-255 znaków) |
| email | string | ✅ | Adres email (walidowany) |
| userType | string | ✅ | `"client"` lub `"contractor"` |
| consent | boolean | ✅ | Zgoda RODO (musi być `true`) |
| source | string | ❌ | Źródło zapisu (np. `"landing_page"`, `"landing_page_hero"`) |

**Odpowiedzi:**

✅ **Sukces (200):**
```json
{
  "success": true,
  "message": "Dziękujemy za zapisanie się do newslettera!"
}
```

⚠️ **Już zapisany (200):**
```json
{
  "success": true,
  "message": "Już jesteś zapisany do newslettera!"
}
```

❌ **Błąd walidacji (400):**
```json
{
  "statusCode": 400,
  "message": ["Proszę podać poprawny adres e-mail"],
  "error": "Bad Request"
}
```

### Dane zapisywane w bazie:

Tabela: `newsletter_subscribers`

| Kolumna | Typ | Opis |
|---------|-----|------|
| id | UUID | Unikalny identyfikator |
| name | VARCHAR(255) | Imię i nazwisko |
| email | VARCHAR(255) | Email (unique index) |
| userType | VARCHAR(20) | `client` lub `contractor` |
| consent | BOOLEAN | Zgoda RODO |
| source | VARCHAR(50) | Źródło zapisu |
| isActive | BOOLEAN | Czy aktywny (soft delete) |
| subscribedAt | TIMESTAMP | Data zapisu |
| unsubscribedAt | TIMESTAMP | Data wypisania (nullable) |
| createdAt | TIMESTAMP | Data utworzenia rekordu |
| updatedAt | TIMESTAMP | Data ostatniej aktualizacji |

### Endpointy administracyjne (wymagają autoryzacji):

- `GET /api/v1/newsletter/subscribers` - lista wszystkich subskrybentów
- `GET /api/v1/newsletter/stats` - statystyki (total, clients, contractors)
- `POST /api/v1/newsletter/unsubscribe?email=xxx` - wypisanie z newslettera

---

## 🆘 Troubleshooting

### Błąd: "Cannot find module"
```bash
# Upewnij się, że zainstalowałeś zależności
npm ci --production
```

### Błąd: "Database connection failed"
- Sprawdź zmienne `DATABASE_*` w `.env`
- Sprawdź, czy PostgreSQL działa: `sudo systemctl status postgresql`
- Sprawdź, czy baza istnieje: `psql -U szybkafucha -d szybkafucha`

### Błąd: "CORS error"
- Sprawdź `LANDING_PAGE_URL` w `.env` (musi być dokładnie `https://szybkafucha.app`)
- Sprawdź konfigurację CORS w `src/main.ts`
- Upewnij się, że frontend wysyła żądania na `https://api.szybkafucha.app`
- Sprawdź, czy nagłówek `Origin` jest poprawny

### Błąd: "Newsletter subscription failed"
- Sprawdź, czy baza danych jest dostępna
- Sprawdź, czy tabela `newsletter_subscribers` istnieje
- Sprawdź logi: `pm2 logs szybkafucha-api | grep newsletter`
- Przetestuj endpoint ręcznie: `curl -X POST ...`

### Błąd: "Unexpected token '<'" (JSON parse error)
- Backend zwraca HTML zamiast JSON (prawdopodobnie 404)
- Sprawdź, czy endpoint istnieje: `/api/v1/newsletter/subscribe`
- Sprawdź, czy API_PREFIX jest ustawiony na `api/v1`

### Aplikacja nie startuje
- Sprawdź logi: `pm2 logs` lub `journalctl -u szybkafucha-api`
- Sprawdź, czy port 3000 jest wolny: `lsof -i :3000`
- Sprawdź zmienne środowiskowe: `printenv | grep DATABASE`
