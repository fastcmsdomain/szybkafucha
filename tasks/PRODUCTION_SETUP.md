# Production Setup Guide - Newsletter Form

## ✅ Co zostało zrobione

1. **Auto-detection API endpoint** - Landing page automatycznie wykrywa środowisko (dev/prod)
2. **CORS configuration** - Backend akceptuje requesty z różnych domen
3. **Environment variables** - Konfiguracja przez zmienne środowiskowe

## 🔧 Konfiguracja dla Produkcji

### 1. Backend (.env)

Dodaj do `backend/.env`:

```env
NODE_ENV=production
PORT=3000
API_PREFIX=api/v1

# Database (production)
DATABASE_HOST=your-production-db-host
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha
DATABASE_PASSWORD=your-secure-password
DATABASE_NAME=szybkafucha

# CORS Origins
FRONTEND_URL=https://app.szybkafucha.pl
ADMIN_URL=https://admin.szybkafucha.pl
LANDING_PAGE_URL=https://szybkafucha.pl

# JWT
JWT_SECRET=your-super-secret-jwt-key-change-in-production
JWT_EXPIRATION_TIME=3600s
```

### 2. Landing Page - API Endpoint

Landing page automatycznie wykrywa środowisko:
- **Development**: `http://localhost:3000/api/v1/newsletter/subscribe`
- **Production**: Automatycznie używa `https://api.szybkafucha.pl/api/v1/newsletter/subscribe`

Jeśli chcesz użyć innej domeny API, zmień w `landing/script.js`:

```javascript
// Option 1: Same domain
return `${protocol}//${hostname}/api/v1/newsletter/subscribe`;

// Option 2: Custom API domain
const apiDomain = 'api.szybkafucha.pl'; // Twój custom domain
return `${protocol}//${apiDomain}/api/v1/newsletter/subscribe`;
```

### 3. HTTPS/SSL

**Wymagane dla produkcji!**

- Użyj Let's Encrypt (darmowe SSL)
- Lub kup certyfikat SSL
- Skonfiguruj reverse proxy (Nginx/Apache) z SSL

### 4. Rate Limiting (Zalecane)

Zainstaluj i skonfiguruj rate limiting:

```bash
cd backend
npm install @nestjs/throttler
```

Dodaj do `app.module.ts`:

```typescript
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot({
      ttl: 60, // 60 seconds
      limit: 10, // 10 requests per minute
    }),
    // ... other modules
  ],
})
```

Dodaj guard do newsletter controller:

```typescript
import { Throttle } from '@nestjs/throttler';

@Controller('newsletter')
export class NewsletterController {
  @Post('subscribe')
  @Throttle(5, 60) // 5 requests per minute
  async subscribe(@Body() dto: SubscribeNewsletterDto) {
    // ...
  }
}
```

### 5. Database Backup

**Krytyczne dla produkcji!**

Skonfiguruj automatyczne backupy:

```bash
# Przykład cron job dla backupu
0 2 * * * docker compose exec postgres pg_dump -U szybkafucha szybkafucha > /backups/szybkafucha_$(date +\%Y\%m\%d).sql
```

### 6. Monitoring i Logging

Zalecane narzędzia:
- **Sentry** - Error tracking
- **LogRocket** - Session replay
- **DataDog** / **New Relic** - APM
- **Winston** / **Pino** - Structured logging

### 7. Environment Variables Security

**Nigdy nie commituj `.env` do Git!**

Użyj:
- `.env.example` - template bez wartości
- `.gitignore` - ignoruj `.env`
- Secret management (AWS Secrets Manager, HashiCorp Vault)

## 📋 Checklist przed wdrożeniem

- [ ] Zmieniono `NODE_ENV=production` w backend
- [ ] Skonfigurowano domenę produkcyjną w CORS
- [ ] Włączono HTTPS/SSL
- [ ] Skonfigurowano rate limiting
- [ ] Skonfigurowano backup bazy danych
- [ ] Zmieniono JWT_SECRET na bezpieczny klucz
- [ ] Skonfigurowano monitoring i logowanie
- [ ] Przetestowano formularz na domenie produkcyjnej
- [ ] Skonfigurowano firewall i security rules
- [ ] Przetestowano backup i restore

## 🚀 Deployment

### Opcja 1: Same Domain (Proste)

```
Landing Page: https://szybkafucha.pl
Backend API:  https://szybkafucha.pl/api/v1
```

**Nginx config:**
```nginx
server {
    listen 443 ssl;
    server_name szybkafucha.pl;

    # Landing page
    location / {
        root /var/www/landing;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Opcja 2: Separate Domains (Zalecane)

```
Landing Page: https://szybkafucha.pl
Backend API:  https://api.szybkafucha.pl
```

**Wymaga:**
- Subdomain DNS record dla `api.szybkafucha.pl`
- SSL certificate dla subdomain
- CORS configuration w backend

## 🔒 Security Best Practices

1. **Rate Limiting** - Ochrona przed spamem
2. **Input Validation** - Już zaimplementowane (class-validator)
3. **SQL Injection** - TypeORM używa prepared statements (bezpieczne)
4. **XSS Protection** - Sanityzacja danych wejściowych
5. **HTTPS Only** - Wymusz HTTPS w produkcji
6. **CORS** - Ograniczone do dozwolonych domen
7. **Environment Variables** - Wrażliwe dane w .env, nie w kodzie

## 📊 Monitoring Newsletter Subscriptions

### Sprawdzanie danych:

**Przez pgAdmin:**
1. Zaloguj się do pgAdmin
2. Servers → Szybka Fucha → Databases → szybkafucha
3. Tables → newsletter_subscribers → View Data

**Przez API (admin only):**
```bash
GET /api/v1/newsletter/subscribers
GET /api/v1/newsletter/stats
```

**Przez terminal:**
```bash
docker compose exec postgres psql -U szybkafucha -d szybkafucha -c "SELECT * FROM newsletter_subscribers;"
```

## 🐛 Troubleshooting

### Formularz nie wysyła danych

1. Sprawdź konsolę przeglądarki (F12) - błędy JavaScript
2. Sprawdź Network tab - czy request idzie do API
3. Sprawdź CORS - czy backend akceptuje domenę
4. Sprawdź backend logs - czy request dotarł

### CORS errors

1. Dodaj domenę do `LANDING_PAGE_URL` w `.env`
2. Restart backend
3. Sprawdź, czy domena jest w `allowedOrigins`

### Database connection errors

1. Sprawdź, czy PostgreSQL działa
2. Sprawdź credentials w `.env`
3. Sprawdź firewall rules

## 📝 Notes

- Landing page automatycznie wykrywa środowisko (dev/prod)
- Backend używa zmiennych środowiskowych dla konfiguracji
- Wszystkie dane są zapisywane w PostgreSQL
- Formularz działa zarówno na localhost jak i na domenie produkcyjnej
