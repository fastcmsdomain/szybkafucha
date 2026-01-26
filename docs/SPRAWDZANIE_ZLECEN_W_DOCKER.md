# Jak sprawdzić zlecenia w Docker Desktop

## Metoda 1: pgAdmin (Najprostsza - Interfejs Graficzny) ⭐

### Krok 1: Otwórz pgAdmin
1. Otwórz przeglądarkę i przejdź do: **http://localhost:5050**
2. Zaloguj się:
   - **Email**: `admin@szybkafucha.pl`
   - **Hasło**: `admin123`

### Krok 2: Dodaj serwer bazy danych
1. Kliknij prawym przyciskiem na "Servers" → "Register" → "Server"
2. W zakładce **General**:
   - **Name**: `Szybka Fucha DB`
3. W zakładce **Connection**:
   - **Host name/address**: `postgres` (nazwa serwisu w docker-compose)
   - **Port**: `5432`
   - **Maintenance database**: `szybkafucha`
   - **Username**: `szybkafucha`
   - **Password**: `szybkafucha_dev_password`
   - ✅ Zaznacz "Save password"
4. Kliknij "Save"

### Krok 3: Sprawdź zlecenia
1. Rozwiń drzewo: **Servers** → **Szybka Fucha DB** → **Databases** → **szybkafucha** → **Schemas** → **public** → **Tables**
2. Kliknij prawym przyciskiem na tabelę **tasks**
3. Wybierz **View/Edit Data** → **All Rows**
4. Zobaczysz wszystkie zlecenia w formie tabeli

### Przydatne zapytania SQL w pgAdmin
Możesz też użyć Query Tool (Tools → Query Tool):

```sql
-- Wszystkie zlecenia
SELECT * FROM tasks ORDER BY "createdAt" DESC;

-- Aktywne zlecenia (nowe, przyjęte, w trakcie)
SELECT * FROM tasks 
WHERE status IN ('created', 'accepted', 'in_progress')
ORDER BY "createdAt" DESC;

-- Zlecenia z informacjami o kliencie
SELECT 
  t.id,
  t.title,
  t.category,
  t.status,
  t."budgetAmount",
  t."createdAt",
  u.name as "clientName",
  u.phone as "clientPhone"
FROM tasks t
LEFT JOIN users u ON t."clientId" = u.id
ORDER BY t."createdAt" DESC;

-- Statystyki zleceń
SELECT 
  status,
  COUNT(*) as count,
  SUM("budgetAmount") as total_budget
FROM tasks
GROUP BY status;

-- Ostatnie 10 zleceń
SELECT * FROM tasks 
ORDER BY "createdAt" DESC 
LIMIT 10;
```

---

## Metoda 2: Docker Desktop - Terminal Kontenera

### Krok 1: Otwórz terminal kontenera
1. Otwórz **Docker Desktop**
2. Znajdź kontener **szybkafucha-postgres**
3. Kliknij na niego, a następnie zakładkę **"Exec"** lub **"Terminal"**

### Krok 2: Połącz się z bazą danych
W terminalu kontenera wykonaj:

```bash
psql -U szybkafucha -d szybkafucha
```

### Krok 3: Wykonaj zapytania SQL

```sql
-- Wszystkie zlecenia
SELECT * FROM tasks ORDER BY "createdAt" DESC;

-- Zlecenia z klientami
SELECT 
  t.id,
  t.title,
  t.category,
  t.status,
  t."budgetAmount",
  u.name as client_name
FROM tasks t
LEFT JOIN users u ON t."clientId" = u.id
ORDER BY t."createdAt" DESC;

-- Wyjście z psql
\q
```

---

## Metoda 3: Terminal lokalny (psql)

Jeśli masz zainstalowany `psql` lokalnie:

```bash
# Połącz się z bazą w kontenerze
psql -h localhost -p 5432 -U szybkafucha -d szybkafucha

# Hasło: szybkafucha_dev_password
```

Następnie wykonaj zapytania SQL jak w Metodzie 2.

---

## Metoda 4: Docker exec (z terminala)

Możesz też wykonać zapytanie bezpośrednio z terminala:

```bash
# Wszystkie zlecenia
docker exec -it szybkafucha-postgres psql -U szybkafucha -d szybkafucha -c "SELECT * FROM tasks ORDER BY \"createdAt\" DESC;"

# Tylko aktywne zlecenia
docker exec -it szybkafucha-postgres psql -U szybkafucha -d szybkafucha -c "SELECT id, title, status, \"budgetAmount\", \"createdAt\" FROM tasks WHERE status IN ('created', 'accepted', 'in_progress') ORDER BY \"createdAt\" DESC;"

# Statystyki
docker exec -it szybkafucha-postgres psql -U szybkafucha -d szybkafucha -c "SELECT status, COUNT(*) as count FROM tasks GROUP BY status;"
```

---

## Metoda 5: Docker Desktop - Logs

Możesz też sprawdzić logi aplikacji backend, które pokazują operacje na zleceniach:

1. W Docker Desktop znajdź kontener backendu (jeśli jest uruchomiony)
2. Otwórz zakładkę **"Logs"**
3. Szukaj wpisów związanych z tworzeniem zleceń

---

## Przydatne informacje

### Dane logowania do bazy danych:
- **Host**: `localhost` (lub `postgres` z wnętrza sieci Docker)
- **Port**: `5432`
- **Database**: `szybkafucha`
- **Username**: `szybkafucha`
- **Password**: `szybkafucha_dev_password`

### Struktura tabeli tasks:
- `id` - UUID zlecenia
- `clientId` - ID klienta (z tabeli users)
- `contractorId` - ID wykonawcy (null jeśli nie przyjęte)
- `category` - Kategoria (paczki, zakupy, kolejki, montaz, przeprowadzki, sprzatanie)
- `title` - Tytuł zlecenia
- `description` - Opis
- `status` - Status (created, accepted, in_progress, completed, cancelled, disputed)
- `budgetAmount` - Budżet zlecenia
- `finalAmount` - Finalna kwota (po zakończeniu)
- `createdAt` - Data utworzenia
- `acceptedAt` - Data przyjęcia przez wykonawcę
- `startedAt` - Data rozpoczęcia
- `completedAt` - Data zakończenia

---

## Rozwiązywanie problemów

### Problem: Nie mogę połączyć się z pgAdmin
**Rozwiązanie**: Sprawdź czy kontener pgAdmin jest uruchomiony:
```bash
docker-compose ps
```

Jeśli nie, uruchom:
```bash
docker-compose up -d pgadmin
```

### Problem: Błąd połączenia z bazą w pgAdmin
**Rozwiązanie**: Upewnij się, że używasz `postgres` jako hostname (nie `localhost`), ponieważ pgAdmin działa w tej samej sieci Docker co PostgreSQL.

### Problem: Nie widzę tabeli tasks
**Rozwiązanie**: Sprawdź czy migracje zostały uruchomione:
```bash
cd backend
npm run migration:run
```

---

## Najszybszy sposób (polecany)

**Użyj pgAdmin** - to najprostszy i najbardziej wizualny sposób:
1. Otwórz http://localhost:5050
2. Zaloguj się
3. Dodaj serwer (host: `postgres`)
4. Kliknij prawym na tabelę `tasks` → View/Edit Data

Gotowe! 🎉
