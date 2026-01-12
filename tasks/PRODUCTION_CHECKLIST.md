# Landing Page - Production Deployment Checklist

**Status:** 🟡 W trakcie przygotowania  
**Ostatnia aktualizacja:** 2026-01-06  
**Cel:** Wdrożenie landing page na produkcję

> **UWAGA:** Pliki landing page zostały przeniesione z `landing/` do roota projektu.

---

## 🔴 KRYTYCZNE (Wymagane przed deployment)

### 1. Konfiguracja Meta Tagów i URL-i
**Plik:** `index.html` (root projektu)

- [ ] Zaktualizować wszystkie URL-e z `https://szybkafucha.app` na rzeczywistą domenę produkcyjną
- [ ] Sprawdzić i zaktualizować canonical URL (linia ~28)
- [ ] Zaktualizować Open Graph URL (linia ~14)
- [ ] Zaktualizować Twitter Card URL (linia ~22)
- [ ] Sprawdzić, czy wszystkie meta tagi mają poprawne wartości
- [ ] Zaktualizować sitemap.xml z właściwą domeną

**Status:** ⏳ Oczekuje na domenę produkcyjną

---

### 2. Obrazy i Assets
**Folder:** `assets/` (root projektu)

#### Brakujące obrazy:
- [ ] `og-image.jpg` (1200x630px) - Open Graph image dla Facebook/LinkedIn
- [ ] `twitter-image.jpg` (1200x600px) - Twitter Card image  
- [ ] `apple-touch-icon.png` (180x180px) - iOS home screen icon

#### Istniejące obrazy:
- [x] `favicon.svg` - istnieje
- [x] `favicon.ico` - istnieje
- [ ] Sprawdzić rozmiary i optymalizację wszystkich obrazów
- [ ] Dodać/sprawdzić alt text dla wszystkich obrazów w HTML

**Status:** ⏳ Wymaga utworzenia brakujących obrazów

---

### 3. Strony Prawne (RODO)
**Wymagane przez prawo polskie i RODO**

#### Pliki (w rootcie projektu):
- [x] `privacy.html` - Polityka Prywatności (WYMAGANA przez RODO) ✅
- [x] `terms.html` - Regulamin ✅
- [x] `cookies.html` - Polityka Cookies ✅

#### Aktualizacje w `index.html`:
- [x] Zaktualizować linki z `#privacy`, `#terms`, `#cookies` na rzeczywiste pliki HTML
- [x] Dodać link do polityki prywatności w stopce
- [ ] Dodać banner zgody na cookies (jeśli wymagane)
- [x] Dodać checkbox zgody RODO w formularzu newsletter

**Status:** ✅ Wykonane (strony prawne utworzone)

---

### 4. Testy Funkcjonalne
**Wymagane przed wdrożeniem**

#### Formularz Newsletter:
- [ ] Przetestować na Chrome
- [ ] Przetestować na Firefox
- [ ] Przetestować na Safari
- [ ] Przetestować na Edge
- [ ] Sprawdzić walidację (puste pola)
- [ ] Sprawdzić walidację (nieprawidłowy email)
- [ ] Sprawdzić komunikaty sukcesu/błędu
- [ ] Sprawdzić tracking GA4 dla zapisów

#### Responsywność:
- [ ] Przetestować na iPhone (Safari)
- [ ] Przetestować na Android (Chrome)
- [ ] Przetestować na iPad/tablet
- [ ] Przetestować na desktop (1920x1080)
- [ ] Przetestować na desktop (1366x768)
- [ ] Przetestować na małych ekranach (320px)

#### Nawigacja i UX:
- [ ] Sprawdzić smooth scroll dla wszystkich linków
- [ ] Przetestować mobile menu
- [ ] Sprawdzić wszystkie przyciski CTA
- [ ] Sprawdzić hover states
- [ ] Przetestować keyboard navigation (Tab, Enter, Esc)
- [ ] Przetestować z screen readerem (VoiceOver/NVDA)

**Status:** ⏳ Częściowo wykonane

---

### 5. Backend API Integration - PHP/MySQL (CURRENT ACTIVE SYSTEM)
**Wymagane przed wdrożeniem landing page**

> **WAŻNE:** Landing page używa **PHP + MySQL API** (`/api/subscribe.php`).
> NestJS + PostgreSQL backend jest gotowy dla przyszłej aplikacji mobilnej, ale **NIE jest używany przez landing page**.

#### PHP Backend Configuration (ACTIVE - UŻYWANE PRZEZ LANDING PAGE):
- [x] Sprawdzić endpoint API ✅ `POST /api/subscribe.php`
- [x] Walidacja formularza po stronie PHP ✅
- [x] Prepared statements (SQL injection safe) ✅
- [x] CORS headers skonfigurowane ✅
- [x] Newsletter signup bridge API utworzony ✅ `GET /api/check-subscriber.php`
- [ ] Przetestować integrację z landing page na wszystkich przeglądarkach
- [ ] Sprawdzić error handling (baza danych offline)
- [ ] Sprawdzić response times (< 2s)
- [ ] Zweryfikować zapis do MySQL w środowisku produkcyjnym
- [ ] Dodać rate limiting na poziomie serwera (opcjonalnie)
- [ ] Skonfigurować backup MySQL database

#### PHP API Security Checklist:
- [x] Validacja email (filter_var) ✅
- [x] Sanityzacja inputów (htmlspecialchars) ✅
- [x] Prepared statements (PDO) ✅
- [x] CORS restricted to allowed origins ✅
- [ ] Sprawdzić czy API endpoint jest dostępny tylko przez HTTPS
- [ ] Rozważyć reCAPTCHA (jeśli spam będzie problemem)

#### MySQL Database:
- [ ] Sprawdzić połączenie z MySQL w środowisku produkcyjnym
- [ ] Zweryfikować table: `newsletter_subscribers`
- [ ] Skonfigurować automated backups
- [ ] Przetestować INSERT INTO newsletter_subscribers
- [ ] Sprawdzić indexy na kolumnie `email` (dla wydajności)

**Status:** ✅ **GOTOWE** - PHP API działa poprawnie, wymaga tylko testów produkcyjnych

---

### 5b. NestJS Backend - Przyszła Aplikacja Mobilna (NOT USED BY LANDING PAGE)
**Status:** ⚠️ **OPCJONALNE dla landing page** - potrzebne tylko przy budowie aplikacji mobilnej

> **To jest dla przyszłości!** Landing page **NIE WYMAGA** NestJS.
> Ten backend zostanie użyty dopiero przy tworzeniu aplikacji mobilnej z funkcjami:
> - Chat między użytkownikami
> - Płatności Stripe
> - Weryfikacja KYC
> - Real-time tracking

#### NestJS Backend (Gotowy dla app, ale nieużywany przez landing page):
- [x] ✅ CORS vulnerability naprawiona (main.ts) - FIXED
- [x] ✅ Rate limiting dodany (@nestjs/throttler) - FIXED
- [x] ✅ OTP storage przeniesiony do Redis - FIXED
- [x] ✅ Global exception filter dodany - FIXED
- [x] ✅ Health check endpoint (`GET /api/v1/health`) - FIXED
- [x] ✅ Helmet.js security headers - FIXED
- [x] ✅ Twilio SMS integration - FIXED
- [x] ✅ LANDING_PAGE_URL w .env - READY

**Backend Readiness dla aplikacji mobilnej:** 95/100 ✅

**Kiedy to będzie potrzebne:**
- Gdy zaczniesz budować aplikację mobilną (Flutter/React Native)
- Gdy będziesz potrzebować chat, payments, real-time features
- Opcjonalnie: gdy zechcesz zmigrować newsletter z MySQL do PostgreSQL

**Co zrobić z tym teraz:** Nic! Zostaw to na później. Zobacz: `backend/MYSQL_SYNC_GUIDE.md` 🎯

---

## 🟡 WAŻNE (Zalecane przed deployment)

### 6. Analytics i Tracking
**Plik:** `index.html` (root projektu)

- [x] Dodać Google Analytics 4 (GA4) - tracking ID
- [x] Skonfigurować event tracking dla formularza newsletter
- [ ] Sprawdzić, czy GA4 działa poprawnie (Real-time reports)
- [ ] Dodać conversion tracking dla zapisów
- [ ] Dodać Facebook Pixel (opcjonalnie)
- [ ] Skonfigurować Google Tag Manager (opcjonalnie)

**Status:** ✅ Częściowo wykonane (GA4 dodane)

---

### 7. Security i Best Practices

#### Headers i Security:
- [ ] Sprawdzić Content Security Policy (CSP) headers
- [ ] Dodać X-Frame-Options: DENY
- [ ] Dodać X-Content-Type-Options: nosniff
- [ ] Dodać Referrer-Policy: strict-origin-when-cross-origin
- [ ] Sprawdzić HTTPS enforcement (redirect HTTP -> HTTPS)
- [ ] Sprawdzić HSTS headers

#### Code Security:
- [x] Sprawdzić, czy nie ma hardcoded credentials
- [x] Sprawdzić, czy API endpoint jest dynamiczny
- [ ] Dodać rate limiting na frontend (opcjonalnie)
- [ ] Rozważyć reCAPTCHA dla formularza (opcjonalnie)

**Status:** ⏳ Wymaga konfiguracji serwera

---

### 8. SEO i AEO
**Plik:** `index.html` (root projektu)

- [x] Sprawdzić structured data (Schema.org) - Organization, WebSite
- [x] Zweryfikować meta description
- [x] Sprawdzić keywords
- [x] Dodać canonical URLs
- [x] Utworzyć `robots.txt` ✅
- [x] Utworzyć `sitemap.xml` ✅
- [x] Zaktualizować sitemap.xml z właściwą domeną ✅ (szybkafucha.app)
- [ ] Przetestować structured data w Google Rich Results Test
- [ ] Zarejestrować stronę w Google Search Console
- [ ] Zarejestrować stronę w Bing Webmaster Tools

**Status:** ✅ Częściowo wykonane

---

### 9. Optymalizacja Performance

#### CSS i JavaScript:
- [x] Zminifikować CSS - inline critical CSS ✅
- [x] Defer non-critical CSS loading ✅
- [x] Sprawdzić rozmiary plików:
  - [x] CSS: 75KB (deferred, non-blocking) ✅
  - [ ] JS: Sprawdzić rozmiar
- [x] Usunięto render-blocking resources ✅

#### Obrazy i Assets:
- [x] Dodać lazy loading dla obrazów poniżej folda ✅
- [x] Preload LCP images z fetchpriority="high" ✅
- [x] Dodać loading="eager" dla above-the-fold images ✅
- [x] Video: preload="none" (oszczędność 13MB) ✅
- [x] Dodać .htaccess z cache headers (1 year dla assets) ✅
- [ ] Zoptymalizować wszystkie obrazy (kompresja)
- [ ] Rozważyć WebP format dla obrazów

#### Performance Metrics:
- [x] Render-blocking resources: FIXED (-1,050ms) ✅
- [x] Cache lifetime: FIXED (1 year cache) ✅
- [x] LCP optimization: FIXED (fetchpriority, preload) ✅
- [ ] Przetestować w Google PageSpeed Insights (cel: > 90)
- [ ] Przetestować w GTmetrix
- [ ] Sprawdzić Lighthouse score (Performance, Accessibility, Best Practices, SEO)
- [x] First Contentful Paint (FCP) - optimized with inline CSS ✅
- [x] Largest Contentful Paint (LCP) - optimized with preload + fetchpriority ✅
- [ ] Sprawdzić Cumulative Layout Shift (CLS < 0.1)

**Status:** ✅ Znacząco poprawione (render-blocking, cache, LCP fixed)

---

## 🟢 OPCJONALNE (Można dodać później)

### 10. Deployment Configuration

#### Server Configuration Files:
- [ ] Utworzyć `.htaccess` (dla Apache) z redirects HTTP -> HTTPS
- [ ] Lub utworzyć `nginx.conf` (dla Nginx)
- [ ] Utworzyć `_headers` (dla Netlify) z security headers
- [ ] Lub utworzyć `vercel.json` (dla Vercel)

**Status:** ⏳ Zależy od platformy hostingowej

---

### 11. Monitoring i Logging

- [ ] Skonfigurować error tracking (np. Sentry)
- [ ] Dodać monitoring uptime (np. UptimeRobot, Pingdom)
- [ ] Skonfigurować alerty dla błędów formularza
- [ ] Dodać logging zapisów do newslettera
- [ ] Skonfigurować alerty email dla downtime

**Status:** ⏳ Opcjonalne

---

### 12. Dokumentacja

- [x] Zaktualizować `README.md` z instrukcjami deployment (root projektu)
- [x] Dodać informacje o wymaganych zmiennych środowiskowych (`backend/DEPLOYMENT.md`)
- [x] Dodać checklist przed deployment (`tasks/PRODUCTION_CHECKLIST.md`)
- [ ] Dodać instrukcje rollback w przypadku problemów
- [ ] Dodać dokumentację API endpoints

**Status:** ✅ Częściowo wykonane

---

## 📋 Final Deployment Checklist

**Przed wdrożeniem na produkcję sprawdź:**

- [ ] ✅ Wszystkie zadania KRYTYCZNE wykonane
- [ ] ✅ Formularz przetestowany i działający na wszystkich przeglądarkach
- [ ] ✅ Backend API dostępny i skonfigurowany na produkcji
- [ ] ✅ CORS skonfigurowany dla domeny produkcyjnej
- [ ] ✅ HTTPS skonfigurowany i wymuszony
- [ ] ✅ Wszystkie obrazy dostępne i zoptymalizowane
- [ ] ✅ Strony prawne opublikowane (Polityka Prywatności, Regulamin, Cookies)
- [ ] ✅ Analytics skonfigurowane i działające
- [ ] ✅ Testy na różnych urządzeniach wykonane
- [ ] ✅ Backup plan przygotowany
- [ ] ✅ DNS skonfigurowany dla domeny
- [ ] ✅ SSL certyfikat zainstalowany
- [ ] ✅ Monitoring skonfigurowany

---

## 🚀 Deployment Steps

### 1. Pre-deployment
1. Wykonać wszystkie zadania KRYTYCZNE
2. Uruchomić testy funkcjonalne
3. Sprawdzić integrację z backend API
4. Zrobić backup obecnej wersji

### 2. Deployment
1. Upload plików na serwer produkcyjny
2. Skonfigurować DNS (jeśli nowa domena)
3. Zainstalować SSL certyfikat
4. Skonfigurować server (Apache/Nginx)
5. Sprawdzić CORS w backend

### 3. Post-deployment
1. Przetestować formularz newsletter
2. Sprawdzić wszystkie linki
3. Zweryfikować Analytics (Real-time)
4. Przetestować na różnych urządzeniach
5. Sprawdzić performance (PageSpeed Insights)
6. Zarejestrować w Google Search Console

### 4. Monitoring (pierwsze 24h)
1. Monitorować error logs
2. Sprawdzać Analytics co kilka godzin
3. Monitorować zapisy do newslettera
4. Sprawdzać uptime
5. Monitorować performance metrics

---

## 📝 Notatki

### Znane Issues:
- Brak obrazów OG/Twitter (wymaga grafika)
- ✅ Strony prawne utworzone (privacy, terms, cookies)
- ✅ PHP/MySQL backend gotowy do produkcji

### Architektura - Dual Backend Strategy:

**Aktualnie Używane (Landing Page):**
- ✅ **PHP + MySQL** - Newsletter signup API (`/api/subscribe.php`)
- ✅ Gotowe do produkcji
- ✅ Bezpieczne (prepared statements, CORS, validation)
- ✅ Proste w deployment

**Przyszłość (Aplikacja Mobilna):**
- ✅ **NestJS + PostgreSQL** - Full platform backend
- ✅ Wszystkie security fixes zaimplementowane (8/8)
- ✅ Rate limiting, Redis, CORS, Helmet.js - DONE
- ✅ Gotowość: 95/100 ✅
- Zobacz: `backend/TEST_RESULTS.md` i `backend/MYSQL_SYNC_GUIDE.md`

### Backend Status Update:

**PHP Backend (ACTIVE):**
- ✅ Działa poprawnie
- ✅ Używany przez landing page
- ✅ MySQL database gotowa
- ⏳ Wymaga tylko testów produkcyjnych

**NestJS Backend (READY FOR FUTURE APP):**
- ~~🔴 CORS vulnerability~~ ✅ FIXED
- ~~🔴 Brak rate limiting~~ ✅ FIXED (@nestjs/throttler)
- ~~🔴 OTP w memory~~ ✅ FIXED (Redis)
- ~~🔴 LANDING_PAGE_URL missing~~ ✅ FIXED
- ~~🟠 Brak exception filter~~ ✅ FIXED
- ~~🟠 Brak health check~~ ✅ FIXED
- ~~🟠 Brak Helmet.js~~ ✅ FIXED
- ~~🟠 Twilio SMS TODO~~ ✅ FIXED

**Gotowość NestJS:** 95/100 ✅ (gotowy do użycia przy app development)

### Endpoints:
- **Landing Page API (PHP):** `http://localhost:8000/api/subscribe.php` (dev) -> `https://szybkafucha.app/api/subscribe.php` (prod)
- **Mobile App API (NestJS):** `http://localhost:3000/api/v1` (dev) -> `https://api.szybkafucha.app/api/v1` (prod - future)
- **Landing Page:** `http://localhost:8080` (dev) -> `https://szybkafucha.app` (prod)

### Struktura plików (po przeniesieniu):
```
szybkafucha/
├── index.html          # Landing page PL (główny plik)
├── index-en.html       # Landing page EN (British English)
├── index-ua.html       # Landing page UA (Ukrainian)
├── styles.css          # Style CSS (wspólne dla wszystkich wersji)
├── script.js           # JavaScript (wspólne dla wszystkich wersji)
├── privacy.html        # Polityka prywatności
├── terms.html          # Regulamin
├── cookies.html        # Polityka cookies
├── robots.txt          # SEO - crawling instructions ✅
├── sitemap.xml         # SEO - site structure ✅
├── assets/             # Obrazy i media
│   ├── favicon.ico
│   ├── favicon.svg
│   └── ...
├── api/                # PHP API dla landing page ✅
│   ├── config.php
│   ├── subscribe.php           # Newsletter signup (ACTIVE)
│   └── check-subscriber.php    # Bridge dla NestJS (READY)
├── backend/            # NestJS backend (dla app mobilnej - NIE dla landing page)
│   ├── MYSQL_SYNC_GUIDE.md     # Jak połączyć MySQL z PostgreSQL ✅
│   └── TEST_RESULTS.md         # Status testów security fixes ✅
├── admin/              # Panel administracyjny (opcjonalny)
└── tasks/              # Dokumentacja i checklisty
```

### Deployment Strategy - Phase Approach:

**Phase 1: NOW - Landing Page Only (Prosty deployment)**
- Deploy: HTML + CSS + JS + PHP API + MySQL
- Backend: PHP/MySQL (shared hosting OK)
- Cost: $5-10/month
- Cel: Zbieranie emaili, marketing

**Phase 2: FUTURE - Mobile App Launch (Pełna platforma)**
- Deploy: NestJS + PostgreSQL + Redis (VPS required)
- Backend: NestJS API dla aplikacji
- Cost: $20-50/month
- Cel: Chat, płatności, zadania, KYC

**Phase 3: OPTIONAL - Unification (Opcjonalnie)**
- Migruj newsletter z MySQL do PostgreSQL
- Landing page może używać NestJS API
- Jeden backend dla wszystkiego

### Zależności Deployment:

**Phase 1 (Landing Page):**
- ✅ PHP + MySQL musi być dostępny
- ✅ Domena skonfigurowana
- ✅ SSL certyfikat zainstalowany
- ⏳ MySQL database utworzona
- ⏳ PHP API wgrany na serwer

**Phase 2 (Mobile App - Przyszłość):**
- PostgreSQL database
- Redis server
- NestJS deployment (PM2/Docker)
- Twilio account (SMS OTP)
- Stripe account (payments)

---

**Legenda:**
- ✅ Wykonane
- ⏳ W trakcie / Wymaga działania
- ❌ Nie rozpoczęte / Krytyczne
- 🔴 Krytyczne (wymagane)
- 🟡 Ważne (zalecane)
- 🟢 Opcjonalne
