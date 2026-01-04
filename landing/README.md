# Szybka Fucha - Landing Page

Strona reklamowa do zbierania zapisów na newsletter przed oficjalnym startem aplikacji Szybka Fucha.

## ✨ Funkcje

- **Mobile-first design** - responsywny na wszystkie urządzenia
- **Formularz zapisu** - 4 pola: imię, email, typ użytkownika (zleceniodawca/wykonawca), zgoda
- **WCAG 2.2 compliant** - dostępność dla wszystkich użytkowników
- **SEO optimized** - meta tagi, Open Graph, structured data
- **AEO ready** - FAQ schema dla Answer Engine Optimization
- **Zero frameworków** - czysty HTML, CSS, JS dla maksymalnej wydajności

## 🚀 Szybki start

### Lokalne uruchomienie

Najprostszy sposób - użyj wbudowanego serwera Python:

`python3 -m http.server 8000`

Lub Node.js:

`npx serve`

Następnie otwórz http://localhost:8000 w przeglądarce.

### Produkcja

Skopiuj pliki na serwer statyczny (np. Vercel, Netlify, GitHub Pages, AWS S3).

## 📁 Struktura plików

`landing/`
├── `index.html` - główna strona HTML
├── `styles.css` - wszystkie style CSS
├── `script.js` - JavaScript (walidacja, menu, analytics)
├── `assets/` - folder na zdjęcia i grafiki
│   ├── `favicon.svg` - ikona strony
│   └── `.gitkeep` - instrukcje dla obrazów
└── `README.md` - ten plik

## 🖼️ Wymagane obrazy

Dodaj następujące obrazy do folderu `assets/`:

| Plik | Rozmiar | Opis |
|------|---------|------|
| `og-image.jpg` | 1200x630px | Obraz dla Open Graph (Facebook, LinkedIn) |
| `twitter-image.jpg` | 1200x600px | Obraz dla Twitter Cards |
| `apple-touch-icon.png` | 180x180px | Ikona dla iOS home screen |
| `hero-phone.png` | ~300x600px | Screenshot aplikacji do mockupu telefonu |
| `client-photo.jpg` | ~400x400px | Zdjęcie reprezentujące zleceniodawcę |
| `contractor-photo.jpg` | ~400x400px | Zdjęcie reprezentujące wykonawcę |

## 🔧 Konfiguracja

### API Endpoint

W pliku `script.js` zaktualizuj endpoint API dla formularza:

`const CONFIG = {`
`  apiEndpoint: '/api/newsletter/subscribe', // Zmień na swój endpoint`
`  ...`
`}`

### Meta tagi

W `index.html` zaktualizuj:
- `<meta property="og:url">` - URL produkcyjny
- `<link rel="canonical">` - URL kanoniczny
- Obrazy OG i Twitter

### Analytics

Dodaj skrypty Google Analytics 4 i/lub Facebook Pixel przed zamknięciem `</head>`:

`<!-- Google Analytics -->`
`<script async src="https://www.googletagmanager.com/gtag/js?id=G-XXXXXXXXXX"></script>`
`<script>`
`  window.dataLayer = window.dataLayer || [];`
`  function gtag(){dataLayer.push(arguments);}`
`  gtag('js', new Date());`
`  gtag('config', 'G-XXXXXXXXXX');`
`</script>`

## 📊 Dane z formularza

Aktualnie formularz zapisuje dane do `localStorage` (demo mode).

Aby połączyć z backendem:

1. Odkomentuj fetch w `script.js` (linia ~230)
2. Ustaw poprawny `CONFIG.apiEndpoint`
3. Backend powinien akceptować POST z JSON:

`{`
`  "name": "Jan Kowalski",`
`  "email": "jan@email.com",`
`  "userType": "client" | "contractor",`
`  "consent": true,`
`  "timestamp": "2026-01-02T12:00:00.000Z",`
`  "source": "landing_page"`
`}`

## ♿ Dostępność (WCAG 2.2)

- Kontrast kolorów minimum 4.5:1 dla tekstu
- Focus states dla wszystkich interaktywnych elementów
- Skip link do głównej treści
- ARIA labels dla ikon i przycisków
- Reduced motion dla użytkowników z preferencją
- Semantic HTML5 elements
- Formularze z proper labels i error messages

## 🔍 SEO & AEO

### Structured Data

- MobileApplication schema (strona główna)
- FAQPage schema (sekcja FAQ)

### Meta tagi

- Description, keywords, author
- Open Graph (Facebook, LinkedIn)
- Twitter Cards
- Canonical URL

## 📱 Breakpoints

| Nazwa | Min-width | Opis |
|-------|-----------|------|
| Mobile | 0px | Bazowy styl (mobile-first) |
| Tablet | 640px | Tablet portrait |
| Desktop | 768px | Desktop, menu nawigacyjne |
| Large | 1024px | Duże ekrany |
| XL | 1280px | Ekstra duże ekrany |

## 🎨 Kolory

| Nazwa | Hex | Użycie |
|-------|-----|--------|
| Primary | #E94560 | Przyciski, akcenty |
| Primary Dark | #D13A54 | Hover states |
| Secondary | #1A1A2E | Dark backgrounds |
| Success | #10B981 | Checkmarks, success |
| Gray 900 | #111827 | Nagłówki |
| Gray 600 | #4B5563 | Tekst body |

## 📦 Performance

- Brak zewnętrznych bibliotek JS
- Krytyczne CSS inline (opcjonalnie)
- Lazy loading dla obrazów
- Preconnect dla Google Fonts
- Minimal DOM operations
- Passive scroll listeners

## 🌐 Wsparcie przeglądarek

- Chrome 90+
- Firefox 90+
- Safari 14+
- Edge 90+
- iOS Safari 14+
- Android Chrome 90+

## 📝 TODO przed publikacją

- [x] Zaktualizować URL-e w meta tagach (szybkafucha.app)
- [x] Skonfigurować endpoint API dla newslettera (auto-detection)
- [x] Dodać Google Analytics 4 (wymaga ID: G-XXXXXXXXXX)
- [x] Stworzyć strony: Polityka Prywatności, Regulamin, Cookies
- [x] Utworzyć robots.txt i sitemap.xml
- [x] Utworzyć og-image.jpg i twitter-image.jpg
- [ ] Zamienić G-XXXXXXXXXX na rzeczywisty ID Google Analytics
- [ ] Dodać prawdziwe zdjęcia do `assets/` (opcjonalnie)
- [ ] Zminifikować CSS i JS (opcjonalnie)
- [ ] Skonfigurować HTTPS i domenę produkcyjną

## 🚀 Deployment Checklist

Przed wdrożeniem na produkcję upewnij się, że:

1. **Google Analytics**: Zamień `G-XXXXXXXXXX` w `index.html` na swój rzeczywisty ID GA4
2. **Domena**: Skonfiguruj domenę `szybkafucha.app` i HTTPS
3. **Backend API**: Uruchom backend na `api.szybkafucha.app`
4. **CORS**: Skonfiguruj CORS w backendzie dla domeny produkcyjnej
5. **DNS**: Ustaw rekordy DNS:
   - `szybkafucha.app` -> serwer landing page
   - `api.szybkafucha.app` -> serwer backend
6. **Dane prawne**: Zaktualizuj dane firmy w `privacy.html` i `terms.html`

## 📁 Struktura plików produkcyjnych

`landing/`
├── `index.html` - główna strona
├── `privacy.html` - Polityka Prywatności
├── `terms.html` - Regulamin
├── `cookies.html` - Polityka Cookies
├── `robots.txt` - instrukcje dla crawlerów
├── `sitemap.xml` - mapa strony
├── `styles.css` - style CSS
├── `script.js` - JavaScript
└── `assets/` - obrazy i grafiki
    ├── `favicon.ico`
    ├── `favicon.svg`
    ├── `apple-touch-icon.png`
    ├── `og-image.jpg` (1200x630px)
    └── `twitter-image.jpg` (1200x600px)

## 📄 Licencja

© 2026 Szybka Fucha. Wszelkie prawa zastrzeżone.
