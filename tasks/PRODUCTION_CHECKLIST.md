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

### 5. Testy Integracyjne Backend API
**Wymagane przed wdrożeniem**

#### Backend Configuration:
- [ ] Sprawdzić endpoint API na produkcji: `https://api.szybkafucha.app/api/v1/newsletter/subscribe`
- [ ] Zweryfikować CORS configuration w backend (domena produkcyjna)
- [ ] Przetestować zapis danych do bazy PostgreSQL
- [ ] Sprawdzić error handling (API offline)
- [ ] Przetestować timeout scenarios
- [ ] Sprawdzić rate limiting
- [ ] Przetestować walidację po stronie backend
- [ ] Sprawdzić response times (< 2s)

#### Environment Variables:
- [ ] Ustawić `LANDING_PAGE_URL` w backend `.env`
- [ ] Ustawić `NODE_ENV=production` w backend
- [ ] Sprawdzić wszystkie zmienne środowiskowe

**Status:** ⏳ Wymaga środowiska produkcyjnego

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
- [x] Utworzyć `robots.txt`
- [x] Utworzyć `sitemap.xml`
- [ ] Zaktualizować sitemap.xml z właściwą domeną
- [ ] Przetestować structured data w Google Rich Results Test
- [ ] Zarejestrować stronę w Google Search Console
- [ ] Zarejestrować stronę w Bing Webmaster Tools

**Status:** ✅ Częściowo wykonane

---

### 9. Optymalizacja Performance

#### CSS i JavaScript:
- [ ] Zminifikować CSS (użyć `cssnano` lub online tool)
- [ ] Zminifikować JavaScript (użyć `terser`)
- [ ] Sprawdzić rozmiary plików:
  - [ ] CSS < 50KB (obecnie: ~XXkB)
  - [ ] JS < 30KB (obecnie: ~XXkB)
- [ ] Rozważyć code splitting (jeśli pliki > 100KB)

#### Obrazy i Assets:
- [ ] Dodać lazy loading dla obrazów poniżej folda
- [ ] Zoptymalizować wszystkie obrazy (kompresja)
- [ ] Rozważyć WebP format dla obrazów
- [ ] Sprawdzić Google Fonts (może warto hostować lokalnie)

#### Performance Metrics:
- [ ] Przetestować w Google PageSpeed Insights (cel: > 90)
- [ ] Przetestować w GTmetrix
- [ ] Sprawdzić Lighthouse score (Performance, Accessibility, Best Practices, SEO)
- [ ] Sprawdzić First Contentful Paint (FCP < 1.8s)
- [ ] Sprawdzić Largest Contentful Paint (LCP < 2.5s)
- [ ] Sprawdzić Cumulative Layout Shift (CLS < 0.1)

**Status:** ⏳ Nie rozpoczęte

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
- Brak stron prawnych (wymaga prawnika/copywritera)
- Środowisko produkcyjne backend nie jest jeszcze gotowe

### Kontakt:
- Backend API: `http://localhost:3000` (dev) -> `https://api.szybkafucha.app` (prod)
- Landing Page: `http://localhost:8080` (dev) -> `https://szybkafucha.app` (prod)

### Struktura plików (po przeniesieniu):
```
szybkafucha/
├── index.html          # Landing page (główny plik)
├── styles.css          # Style CSS
├── script.js           # JavaScript
├── privacy.html        # Polityka prywatności
├── terms.html          # Regulamin
├── cookies.html        # Polityka cookies
├── assets/             # Obrazy i media
│   ├── favicon.ico
│   ├── favicon.svg
│   └── ...
├── backend/            # Backend NestJS (osobny deployment)
├── admin/              # Panel administracyjny (opcjonalny)
└── tasks/              # Dokumentacja i checklisty
```

### Zależności:
- Backend musi być wdrożony PRZED landing page
- Domena musi być skonfigurowana PRZED deployment
- SSL certyfikat musi być zainstalowany PRZED uruchomieniem

---

**Legenda:**
- ✅ Wykonane
- ⏳ W trakcie / Wymaga działania
- ❌ Nie rozpoczęte / Krytyczne
- 🔴 Krytyczne (wymagane)
- 🟡 Ważne (zalecane)
- 🟢 Opcjonalne
