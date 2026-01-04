# Landing Page - Deployment Checklist

Checklist do wdrożenia landing page na produkcję.

---

## Krytyczne (przed deployment)

### 1. Konfiguracja Meta Tagów i URL-i
- [x] Zaktualizować wszystkie URL-e na `szybkafucha.app`
- [x] Sprawdzić i zaktualizować canonical URL
- [x] Zaktualizować Open Graph URL
- [x] Zaktualizować Twitter Card URL
- [x] Sprawdzić, czy wszystkie meta tagi mają poprawne wartości

### 2. Obrazy i Assets
- [x] `og-image.jpg` (1200x630px) - Open Graph image
- [x] `twitter-image.jpg` (1200x600px) - Twitter Card image
- [x] `apple-touch-icon.png` (180x180px) - iOS home screen icon
- [x] `favicon.svg` / `favicon.ico`
- [ ] Sprawdzić rozmiary i optymalizację istniejących obrazów
- [ ] Dodać alt text dla wszystkich obrazów w HTML

### 3. Strony Prawne (RODO)
- [x] `privacy.html` - Polityka Prywatności
- [x] `terms.html` - Regulamin
- [x] `cookies.html` - Polityka Cookies
- [x] Zaktualizować linki w `index.html` na rzeczywiste pliki
- [ ] Zaktualizować dane firmy (adres, NIP) w stronach prawnych
- [ ] Dodać banner zgody na cookies (opcjonalnie)

### 4. SEO
- [x] `robots.txt` - instrukcje dla crawlerów
- [x] `sitemap.xml` - mapa strony
- [x] Structured data (Schema.org) - MobileApplication, FAQPage
- [x] Meta description
- [x] Canonical URLs

---

## Ważne (zalecane przed deployment)

### 5. Analytics i Tracking
- [x] Dodać Google Analytics 4 (GA4) - skrypt dodany
- [ ] **Zamienić `G-XXXXXXXXXX` na rzeczywisty ID GA4**
- [x] Skonfigurować event tracking dla formularza newsletter
- [ ] Dodać Facebook Pixel (opcjonalnie)
- [ ] Dodać conversion tracking dla zapisów do newslettera

### 6. Security i Best Practices
- [x] Sprawdzić, czy nie ma hardcoded credentials w kodzie
- [ ] Zweryfikować Content Security Policy (CSP) headers
- [ ] Sprawdzić HTTPS enforcement
- [ ] Dodać security headers (X-Frame-Options, X-Content-Type-Options)
- [ ] Sprawdzić, czy formularz ma protection przed spamem (reCAPTCHA)

### 7. Optymalizacja Performance
- [ ] Zminifikować CSS (opcjonalnie - `cssnano`)
- [ ] Zminifikować JavaScript (opcjonalnie - `terser`)
- [x] Sprawdzić rozmiary plików (CSS: 35KB, JS: 22KB - OK)
- [ ] Dodać lazy loading dla obrazów poniżej folda
- [ ] Sprawdzić użycie Google Fonts (hostować lokalnie?)

---

## Testy

### 8. Testy Funkcjonalne
- [x] Przetestować formularz newsletter (API działa)
- [ ] Przetestować na różnych przeglądarkach (Chrome, Firefox, Safari, Edge)
- [ ] Sprawdzić walidację formularza (puste pola, nieprawidłowy email)
- [ ] Przetestować responsywność (mobile, tablet, desktop)
- [ ] Przetestować nawigację i smooth scroll
- [ ] Sprawdzić dostępność (WCAG 2.2) - keyboard navigation

### 9. Testy Integracyjne
- [x] Przetestować połączenie z backend API (localhost)
- [ ] Przetestować na środowisku produkcyjnym
- [ ] Sprawdzić CORS configuration w backend dla domeny produkcyjnej
- [ ] Przetestować zapis danych do bazy PostgreSQL
- [ ] Sprawdzić error handling (gdy API nie działa)

---

## Deployment Configuration

### 10. Pliki konfiguracyjne
- [x] `robots.txt`
- [x] `sitemap.xml`
- [ ] `.htaccess` (Apache) lub `nginx.conf` (Nginx) - redirect HTTP -> HTTPS
- [ ] `_headers` (Netlify) lub `vercel.json` (Vercel) - security headers

### 11. Infrastruktura
- [ ] Skonfigurować domenę `szybkafucha.app`
- [ ] Skonfigurować HTTPS/SSL
- [ ] Skonfigurować DNS:
  - [ ] `szybkafucha.app` -> serwer landing page
  - [ ] `api.szybkafucha.app` -> serwer backend
- [ ] Uruchomić backend na `api.szybkafucha.app`
- [ ] Skonfigurować CORS w backendzie dla domeny produkcyjnej

---

## Opcjonalne (można dodać później)

### 12. Monitoring i Logging
- [ ] Skonfigurować error tracking (Sentry)
- [ ] Dodać monitoring uptime (UptimeRobot)
- [ ] Skonfigurować alerty dla błędów formularza
- [ ] Dodać logging zapisów do newslettera

### 13. Dodatkowe
- [ ] Dodać prawdziwe zdjęcia do `assets/`
- [ ] reCAPTCHA dla formularza
- [ ] A/B testing

---

## Final Checklist

Przed uruchomieniem produkcji upewnij się:

- [ ] Wszystkie krytyczne zadania wykonane
- [ ] **ID Google Analytics zamieniony z `G-XXXXXXXXXX`**
- [ ] **Dane firmy zaktualizowane w stronach prawnych**
- [ ] Formularz przetestowany i działający
- [ ] Backend API dostępny i skonfigurowany
- [ ] CORS skonfigurowany dla domeny produkcyjnej
- [ ] HTTPS skonfigurowany
- [ ] Wszystkie obrazy dostępne i zoptymalizowane
- [ ] Strony prawne opublikowane
- [ ] Testy na różnych urządzeniach wykonane
- [ ] Backup plan przygotowany

---

## Struktura plików produkcyjnych

`landing/`
├── `index.html` - główna strona
├── `privacy.html` - Polityka Prywatności
├── `terms.html` - Regulamin
├── `cookies.html` - Polityka Cookies
├── `robots.txt` - instrukcje dla crawlerów
├── `sitemap.xml` - mapa strony
├── `styles.css` - style CSS (35KB)
├── `script.js` - JavaScript (22KB)
└── `assets/`
    ├── `favicon.ico`
    ├── `favicon.svg`
    ├── `apple-touch-icon.png` (180x180px)
    ├── `og-image.jpg` (1200x630px)
    ├── `twitter-image.jpg` (1200x600px)
    └── [inne obrazy]

---

*Ostatnia aktualizacja: 4 stycznia 2026*
