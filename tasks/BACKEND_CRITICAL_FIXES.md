# Backend - Krytyczne Poprawki Przed Production

**Status:** 🔴 WYMAGANE
**Ostatnia aktualizacja:** 2026-01-10
**Gotowość produkcyjna:** 65/100

---

## 🔴 KRYTYCZNE PROBLEMY (BLOCKER dla production)

### 1. CORS Security Vulnerability ⚠️ NAJWYŻSZY PRIORYTET

**Problem:**
`backend/src/main.ts:40-42` - W trybie production WSZYSTKIE origins są dozwolone!

```typescript
// NIEBEZPIECZNY KOD - USUŃ TO!
if (isProduction) {
  return callback(null, true);  // ⚠️ Każda domena może wywołać API!
}
```

**Wpływ:**
- Każdy może wywołać API z dowolnej domeny
- Naruszenie bezpieczeństwa CORS
- Potencjalne ataki CSRF

**Rozwiązanie:**

```typescript
// backend/src/main.ts - POPRAWIONA WERSJA
app.enableCors({
  origin: (origin, callback) => {
    const allowedOrigins = [
      process.env.FRONTEND_URL,
      process.env.ADMIN_URL,
      process.env.LANDING_PAGE_URL, // DODAJ TO!
    ].filter(Boolean);

    // Tylko w development pozwalaj localhost
    if (!isProduction) {
      allowedOrigins.push('http://localhost:8080');
    }

    // USUŃ blanket approval dla production!
    // Sprawdź czy origin jest na liście
    if (!origin || allowedOrigins.includes(origin)) {
      callback(null, true);
    } else {
      callback(new Error('Not allowed by CORS'));
    }
  },
  credentials: true,
  methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
  allowedHeaders: 'Content-Type,Authorization',
});
```

**Kroki:**
1. ✅ Dodać `LANDING_PAGE_URL` do `.env`
2. ✅ Usunąć `if (isProduction)` blanket approval
3. ✅ Przetestować CORS z różnych origin
4. ✅ Zweryfikować że landing page działa

**Plik:** `backend/src/main.ts`
**Czas:** 15 minut
**Priorytet:** 🔴🔴🔴 KRYTYCZNY

---

### 2. Brak Rate Limiting - DoS/Spam Vulnerability

**Problem:**
Zero implementacji rate limiting - newsletter endpoint podatny na spam.

**Wpływ:**
- Możliwość spamowania newslettera
- DoS attack na endpoint newsletter/subscribe
- Brute force na auth endpoints (OTP)
- Wysokie koszty bazy danych

**Rozwiązanie:**

```bash
# Instalacja
cd backend
npm install @nestjs/throttler
```

```typescript
// backend/src/app.module.ts - DODAJ
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';

@Module({
  imports: [
    // ... inne imports
    ThrottlerModule.forRoot({
      ttl: 60,      // Time to live (sekundy)
      limit: 10,    // Max requests w TTL
    }),
  ],
  providers: [
    // Global rate limiting guard
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
```

```typescript
// backend/src/newsletter/newsletter.controller.ts - DODAJ
import { Throttle } from '@nestjs/throttler';

@Controller('newsletter')
export class NewsletterController {

  @Post('subscribe')
  @Throttle(3, 60) // Override: max 3 requests per 60s
  async subscribe(@Body() dto: SubscribeNewsletterDto) {
    return this.newsletterService.subscribe(dto);
  }
}
```

**Konfiguracja dla innych endpoints:**
- Newsletter: 3 requests / 60s (subskrypcja)
- OTP Request: 3 requests / 60s (SMS limit)
- OTP Verify: 5 requests / 60s (próby weryfikacji)
- Login: 5 requests / 60s
- Payments: 10 requests / 60s

**Kroki:**
1. ✅ Zainstalować @nestjs/throttler
2. ✅ Dodać ThrottlerModule do app.module.ts
3. ✅ Dodać global ThrottlerGuard
4. ✅ Dodać @Throttle() dekoratory do newslettera
5. ✅ Dodać @Throttle() do auth endpoints
6. ✅ Przetestować z Artillery lub k6

**Plik:** `backend/src/app.module.ts`, `backend/src/newsletter/newsletter.controller.ts`
**Czas:** 30 minut
**Priorytet:** 🔴🔴🔴 KRYTYCZNY

---

### 3. OTP Storage w Memory - Data Loss Risk

**Problem:**
`backend/src/auth/auth.service.ts:12` - OTP kody są w `Map<string, OtpData>` (RAM)

```typescript
// PROBLEM - OTP w pamięci RAM!
private otpStore = new Map<string, OtpData>();
```

**Wpływ:**
- Restart serwera = utrata wszystkich kodów OTP
- Brak skalowania (każdy serwer ma własną mapę)
- Użytkownik nie może zweryfikować OTP po restarcie
- Nie działa z load balancerem (multiple instances)

**Rozwiązanie:**

```bash
# Redis już jest skonfigurowany w docker-compose.yml!
# Trzeba tylko go użyć
```

```typescript
// backend/src/auth/auth.service.ts - POPRAWIONA WERSJA
import { Injectable, Inject } from '@nestjs/common';
import { CACHE_MANAGER } from '@nestjs/cache-manager';
import { Cache } from 'cache-manager';

@Injectable()
export class AuthService {
  constructor(
    @Inject(CACHE_MANAGER) private cacheManager: Cache,
    // ... inne dependencies
  ) {}

  // USUŃ: private otpStore = new Map<string, OtpData>();

  async generateAndStoreOtp(phoneNumber: string): Promise<string> {
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000); // 5 min

    // Zapisz w Redis z TTL
    await this.cacheManager.set(
      `otp:${phoneNumber}`,
      { otp, expiresAt },
      300000, // 5 min TTL (milliseconds)
    );

    return otp;
  }

  async verifyOtp(phoneNumber: string, otp: string): Promise<boolean> {
    const stored = await this.cacheManager.get<{ otp: string; expiresAt: Date }>(
      `otp:${phoneNumber}`,
    );

    if (!stored) {
      return false; // OTP nie istnieje lub wygasł
    }

    if (new Date() > new Date(stored.expiresAt)) {
      await this.cacheManager.del(`otp:${phoneNumber}`);
      return false; // Wygasł
    }

    if (stored.otp !== otp) {
      return false; // Nieprawidłowy kod
    }

    // Usuń po użyciu (one-time use)
    await this.cacheManager.del(`otp:${phoneNumber}`);
    return true;
  }
}
```

```typescript
// backend/src/app.module.ts - DODAJ CacheModule
import { CacheModule } from '@nestjs/cache-manager';
import * as redisStore from 'cache-manager-redis-store';

@Module({
  imports: [
    // ... inne imports
    CacheModule.register({
      store: redisStore,
      host: process.env.REDIS_HOST || 'localhost',
      port: parseInt(process.env.REDIS_PORT) || 6379,
      password: process.env.REDIS_PASSWORD,
      ttl: 300, // Default TTL 5 min
    }),
  ],
})
```

**Kroki:**
1. ✅ Zainstalować `cache-manager` i `cache-manager-redis-store`
2. ✅ Dodać CacheModule do app.module.ts
3. ✅ Przepisać auth.service.ts na Redis
4. ✅ Dodać REDIS_PASSWORD do .env
5. ✅ Przetestować OTP flow
6. ✅ Sprawdzić Redis w docker-compose

**Plik:** `backend/src/auth/auth.service.ts`, `backend/src/app.module.ts`
**Czas:** 45 minut
**Priorytet:** 🔴🔴 KRYTYCZNY (przed skalowaniem)

---

### 4. Environment Variables - LANDING_PAGE_URL Missing

**Problem:**
`.env` i `.env.example` nie zawierają `LANDING_PAGE_URL`

**Wpływ:**
- CORS nie zadziała dla landing page
- Newsletter form zwróci błąd CORS

**Rozwiązanie:**

```bash
# backend/.env - DODAJ
LANDING_PAGE_URL=https://szybkafucha.app
```

```bash
# backend/.env.example - DODAJ
# Frontend URLs for CORS
FRONTEND_URL=http://localhost:3001
ADMIN_URL=http://localhost:3002
LANDING_PAGE_URL=https://szybkafucha.app  # <-- DODAJ TO!
```

**Dodatkowe brakujące zmienne:**

```bash
# SMS/OTP (Twilio)
TWILIO_ACCOUNT_SID=your_account_sid
TWILIO_AUTH_TOKEN=your_auth_token
TWILIO_PHONE_NUMBER=+48...

# KYC Verification (Onfido)
ONFIDO_API_TOKEN=your_onfido_token

# Redis Authentication
REDIS_PASSWORD=your_redis_password  # Dla production
```

**Kroki:**
1. ✅ Dodać LANDING_PAGE_URL do .env i .env.example
2. ✅ Dodać TWILIO_* variables
3. ✅ Dodać ONFIDO_API_TOKEN
4. ✅ Dodać REDIS_PASSWORD
5. ✅ Zaktualizować DEPLOYMENT.md z nową listą zmiennych

**Plik:** `backend/.env.example`, `backend/DEPLOYMENT.md`
**Czas:** 10 minut
**Priorytet:** 🔴🔴 KRYTYCZNY

---

## 🟠 WYSOKIE PROBLEMY (Powinny być naprawione)

### 5. Brak Global Exception Filter

**Problem:**
Brak spójnego formatu odpowiedzi błędów. Dokumentacja mówi:

```json
{
  "success": true,
  "message": "...",
  "data": {...}
}
```

Ale kontrolery zwracają raw data lub NestJS default errors.

**Rozwiązanie:**

```typescript
// backend/src/common/filters/http-exception.filter.ts - NOWY PLIK
import {
  ExceptionFilter,
  Catch,
  ArgumentsHost,
  HttpException,
  HttpStatus,
  Logger,
} from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger(AllExceptionsFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse<Response>();
    const request = ctx.getRequest<Request>();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Internal server error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const exceptionResponse = exception.getResponse();
      message = typeof exceptionResponse === 'string'
        ? exceptionResponse
        : (exceptionResponse as any).message || message;
    }

    // Log error
    this.logger.error(
      `${request.method} ${request.url} - ${status} - ${message}`,
      exception instanceof Error ? exception.stack : '',
    );

    // Consistent response format
    response.status(status).json({
      success: false,
      message: Array.isArray(message) ? message : [message],
      statusCode: status,
      timestamp: new Date().toISOString(),
      path: request.url,
    });
  }
}
```

```typescript
// backend/src/main.ts - DODAJ
import { AllExceptionsFilter } from './common/filters/http-exception.filter';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Global exception filter
  app.useGlobalFilters(new AllExceptionsFilter());

  // ... reszta konfiguracji
}
```

**Kroki:**
1. ✅ Utworzyć `src/common/filters/http-exception.filter.ts`
2. ✅ Dodać do main.ts jako global filter
3. ✅ Przetestować różne błędy (400, 404, 500)
4. ✅ Sprawdzić format odpowiedzi

**Czas:** 30 minut
**Priorytet:** 🟠 WYSOKIE

---

### 6. Brak Health Check Endpoint

**Problem:**
Nie ma `/health` endpoint dla load balancera / monitoringu.

**Rozwiązanie:**

```typescript
// backend/src/health/health.controller.ts - NOWY PLIK
import { Controller, Get } from '@nestjs/common';
import {
  HealthCheck,
  HealthCheckService,
  TypeOrmHealthIndicator,
} from '@nestjs/terminus';

@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.db.pingCheck('database'),
    ]);
  }
}
```

```bash
npm install @nestjs/terminus
```

**Kroki:**
1. ✅ Zainstalować @nestjs/terminus
2. ✅ Utworzyć health.controller.ts
3. ✅ Dodać HealthModule do app.module.ts
4. ✅ Przetestować `GET /api/v1/health`

**Czas:** 20 minut
**Priorytet:** 🟠 WYSOKIE

---

### 7. Brak Security Headers (Helmet.js)

**Problem:**
Brak security headers (CSP, X-Frame-Options, etc.)

**Rozwiązanie:**

```bash
npm install helmet
```

```typescript
// backend/src/main.ts - DODAJ
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security headers
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        scriptSrc: ["'self'"],
        imgSrc: ["'self'", 'data:', 'https:'],
      },
    },
    crossOriginEmbedderPolicy: false, // For Stripe
  }));

  // ... reszta
}
```

**Kroki:**
1. ✅ Zainstalować helmet
2. ✅ Dodać do main.ts
3. ✅ Przetestować headers z curl
4. ✅ Sprawdzić czy Stripe działa

**Czas:** 15 minut
**Priorytet:** 🟠 WYSOKIE

---

### 8. Twilio Integration dla SMS OTP

**Problem:**
`auth.service.ts:66` - TODO: Implement Twilio SMS sending

**Rozwiązanie:**

```bash
npm install twilio
```

```typescript
// backend/src/auth/auth.service.ts
import * as twilio from 'twilio';

export class AuthService {
  private twilioClient: twilio.Twilio;

  constructor() {
    this.twilioClient = twilio(
      process.env.TWILIO_ACCOUNT_SID,
      process.env.TWILIO_AUTH_TOKEN,
    );
  }

  async sendOtp(phoneNumber: string, otp: string): Promise<void> {
    try {
      await this.twilioClient.messages.create({
        body: `Twój kod weryfikacyjny Szybka Fucha: ${otp}. Ważny 5 minut.`,
        from: process.env.TWILIO_PHONE_NUMBER,
        to: phoneNumber,
      });
      this.logger.log(`OTP sent to ${phoneNumber}`);
    } catch (error) {
      this.logger.error(`Failed to send OTP to ${phoneNumber}`, error);
      throw new BadRequestException('Nie udało się wysłać SMS');
    }
  }
}
```

**Kroki:**
1. ✅ Założyć konto Twilio (trial lub paid)
2. ✅ Dodać zmienne TWILIO_* do .env
3. ✅ Zainstalować twilio SDK
4. ✅ Zaimplementować sendOtp()
5. ✅ Przetestować wysyłkę SMS

**Czas:** 1 godzina (z rejestracją Twilio)
**Priorytet:** 🟠 WYSOKIE (dla production auth)

---

## 🟡 ŚREDNIE PROBLEMY (Nice to have)

### 9. Request/Response Logging Middleware

```typescript
// backend/src/common/middleware/logger.middleware.ts
import { Injectable, NestMiddleware, Logger } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

@Injectable()
export class LoggerMiddleware implements NestMiddleware {
  private logger = new Logger('HTTP');

  use(req: Request, res: Response, next: NextFunction) {
    const { method, originalUrl, ip } = req;
    const userAgent = req.get('user-agent') || '';
    const startTime = Date.now();

    res.on('finish', () => {
      const { statusCode } = res;
      const contentLength = res.get('content-length');
      const responseTime = Date.now() - startTime;

      this.logger.log(
        `${method} ${originalUrl} ${statusCode} ${contentLength || 0}b - ${responseTime}ms - ${ip} - ${userAgent}`,
      );
    });

    next();
  }
}
```

**Czas:** 30 minut

---

### 10. Database Migrations

```bash
# Zamiast synchronize: true
cd backend
npm install -D @nestjs/typeorm typeorm

# Generuj migration
npm run typeorm migration:generate -- -n InitialSchema

# Run migration
npm run typeorm migration:run
```

**Czas:** 1 godzina

---

## 📋 PLAN DZIAŁANIA - PRIORYTET

**Czas łączny: ~4-5 godzin**

### Dzień 1 - Krytyczne (2-3h):
1. ✅ Naprawić CORS vulnerability (15 min)
2. ✅ Dodać LANDING_PAGE_URL do .env (10 min)
3. ✅ Zaimplementować rate limiting (30 min)
4. ✅ Przenieść OTP do Redis (45 min)
5. ✅ Dodać global exception filter (30 min)
6. ✅ Dodać health check endpoint (20 min)

### Dzień 2 - Wysokie (2h):
1. ✅ Dodać Helmet.js security headers (15 min)
2. ✅ Zaimplementować Twilio SMS (1h)
3. ✅ Dodać request logging middleware (30 min)
4. ✅ Przetestować wszystko end-to-end (15 min)

### Dzień 3 - Średnie (opcjonalne):
1. ✅ Skonfigurować database migrations
2. ✅ Dodać testy e2e dla newsletter
3. ✅ Skonfigurować monitoring (Sentry)

---

## ✅ CHECKLIST PRZED DEPLOYMENT

- [ ] 🔴 CORS vulnerability naprawiona
- [ ] 🔴 Rate limiting dodany
- [ ] 🔴 OTP storage w Redis
- [ ] 🔴 LANDING_PAGE_URL w .env
- [ ] 🟠 Global exception filter
- [ ] 🟠 Health check endpoint
- [ ] 🟠 Helmet.js security headers
- [ ] 🟠 Twilio SMS integration
- [ ] 🟡 Request logging
- [ ] 🟡 Database migrations

---

**Następny krok:** Rozpocznij od naprawy CORS vulnerability - to najważniejszy problem bezpieczeństwa!
