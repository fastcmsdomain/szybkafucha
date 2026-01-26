# Jak zatrzymać i uruchomić ponownie Backend Server

## 🛑 Zatrzymanie serwera

### Metoda 1: W terminalu gdzie działa serwer (Najprostsza)

Jeśli serwer działa w terminalu:
1. Przejdź do terminala gdzie działa `npm run start:dev`
2. Naciśnij **`Ctrl + C`** (lub **`Cmd + C`** na Mac)
3. Serwer zostanie zatrzymany

### Metoda 2: Znajdź i zabij proces

```bash
# Znajdź proces Node.js działający na porcie 3000
lsof -ti:3000

# Lub znajdź wszystkie procesy NestJS
ps aux | grep "nest start"

# Zabij proces (użyj PID z powyższych komend)
kill <PID>

# Lub zabij wszystkie procesy Node na porcie 3000
kill $(lsof -ti:3000)
```

### Metoda 3: Zatrzymaj wszystkie procesy Node

```bash
# Zabij wszystkie procesy node (ostrożnie!)
pkill -f "nest start"
```

---

## ▶️ Uruchomienie serwera ponownie

### Krok 1: Upewnij się, że Docker działa

```bash
# Sprawdź czy PostgreSQL i Redis są uruchomione
docker-compose ps

# Jeśli nie, uruchom je:
docker-compose up -d postgres redis
```

### Krok 2: Uruchom backend

```bash
# Przejdź do katalogu backend
cd backend

# Uruchom serwer w trybie development
npm run start:dev
```

### Alternatywnie: Użyj skryptu startowego

```bash
cd backend
./start-dev.sh
```

Ten skrypt automatycznie:
- Sprawdzi czy `.env` istnieje
- Uruchomi Docker services (jeśli nie działają)
- Poczeka aż PostgreSQL będzie gotowy
- Uruchomi backend

---

## 🔄 Szybkie zatrzymanie i restart

### W jednym terminalu:

```bash
# Zatrzymaj (Ctrl+C) i uruchom ponownie:
cd backend && npm run start:dev
```

### W dwóch krokach:

```bash
# Terminal 1: Zatrzymaj
kill $(lsof -ti:3000)

# Terminal 2: Uruchom
cd backend && npm run start:dev
```

---

## ✅ Sprawdzenie czy serwer działa

```bash
# Sprawdź health endpoint
curl http://localhost:3000/api/v1/health

# Sprawdź czy port 3000 jest zajęty
lsof -i:3000

# Sprawdź procesy Node
ps aux | grep "nest start"
```

---

## 🐛 Rozwiązywanie problemów

### Problem: Port 3000 jest już zajęty

```bash
# Znajdź proces używający portu 3000
lsof -ti:3000

# Zabij proces
kill $(lsof -ti:3000)

# Lub użyj innego portu (zmień w backend/.env)
PORT=3001
```

### Problem: Serwer nie startuje

1. **Sprawdź czy Docker działa:**
   ```bash
   docker-compose ps
   ```

2. **Sprawdź logi:**
   ```bash
   cd backend
   npm run start:dev
   # Zobacz błędy w terminalu
   ```

3. **Sprawdź czy .env istnieje:**
   ```bash
   cd backend
   ls -la .env
   ```

### Problem: Błąd połączenia z bazą danych

```bash
# Sprawdź czy PostgreSQL działa
docker exec szybkafucha-postgres pg_isready -U szybkafucha

# Sprawdź logi PostgreSQL
docker-compose logs postgres

# Restart PostgreSQL
docker-compose restart postgres
```

---

## 📝 Przykładowy workflow

```bash
# 1. Zatrzymaj serwer (w terminalu gdzie działa)
# Naciśnij Ctrl+C

# 2. Sprawdź czy Docker działa
docker-compose ps

# 3. Uruchom ponownie
cd backend
npm run start:dev

# 4. Sprawdź czy działa
curl http://localhost:3000/api/v1/health
```

---

## 💡 Wskazówki

- **Zawsze zatrzymuj serwer przed wyłączeniem komputera** - użyj `Ctrl+C`
- **Użyj `npm run start:dev`** dla development (automatyczne przeładowanie przy zmianach)
- **Użyj `npm run start:prod`** dla produkcji (wymaga wcześniejszego `npm run build`)
- **Sprawdź logi** jeśli coś nie działa - błędy są wyświetlane w terminalu
