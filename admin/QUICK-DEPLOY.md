# Szybkie wdrożenie panelu administracyjnego

## TL;DR - Co wgrać i gdzie?

### Na serwer wgrywasz:

| Co wgrać (lokalnie) | Gdzie na serwerze |
|---------------------|-------------------|
| `admin/build/*` (zawartość!) | `/public_html/admin/` |
| `api/*` | `/public_html/api/` |

### NIE wgrywasz:
- `admin/src/` - to kod źródłowy
- `admin/node_modules/` - zależności developerskie
- `admin/build/` jako folder - tylko jego zawartość!

---

## 3 kroki do wdrożenia

### 1. Zbuduj panel (na swoim komputerze)

`bash
cd admin
npm install    # tylko pierwszy raz
npm run build
`

### 2. Wgraj pliki na serwer

**Przez FTP (FileZilla/WinSCP):**

1. Połącz się z serwerem
2. Przejdź do `public_html` (lub głównego katalogu strony)
3. Stwórz folder `admin` (jeśli nie istnieje)
4. Otwórz lokalnie folder `admin/build/`
5. Zaznacz WSZYSTKIE pliki w `build/` i wgraj do `admin/` na serwerze

**Struktura po wgraniu:**
`
public_html/
├── admin/
│   ├── index.html        ← z admin/build/
│   ├── static/           ← z admin/build/
│   │   └── js/
│   │       └── main.*.js
│   ├── favicon.ico       ← z admin/build/
│   └── ...
└── api/
    ├── config.php
    ├── subscribe.php
    └── subscribers.php
`

### 3. Sprawdź czy działa

Otwórz w przeglądarce:
- `https://twoja-domena.pl/admin/`

---

## Aktualizacja panelu

Po zmianach w kodzie:

`bash
cd admin
npm run build
`

Następnie wgraj nową zawartość `admin/build/` na serwer (nadpisz stare pliki).

---

## Częste błędy

| Problem | Rozwiązanie |
|---------|-------------|
| Biała strona | Sprawdź czy `admin/index.html` istnieje |
| "Failed to fetch" | Sprawdź czy API działa: `/api/subscribers.php` |
| Stara wersja | Wyczyść cache: Ctrl+Shift+R |

---

Szczegółowa dokumentacja: [DEPLOYMENT.md](./DEPLOYMENT.md)

