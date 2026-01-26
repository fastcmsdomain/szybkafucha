# KYC Verification - Post MVP

## Status: Tymczasowo wyłączone dla testowania

## Opis
Weryfikacja tożsamości (KYC - Know Your Customer) wykonawców przed pozwoleniem im na przejście w tryb online i przyjmowanie zleceń.

## Wymagane zmiany przed produkcją

### Backend
**Plik:** `backend/src/contractor/contractor.service.ts`

Odkomentować sprawdzenie KYC w metodzie `setAvailability()`:

```typescript
// Obecnie zakomentowane - odkomentować przed produkcją:
if (isOnline && profile.kycStatus !== KycStatus.VERIFIED) {
  throw new BadRequestException(
    'Complete KYC verification before going online',
  );
}
```

### Mobile App
Obsługa błędu KYC jest już zaimplementowana w:
- `mobile/lib/core/providers/contractor_availability_provider.dart` - tłumaczenie komunikatu błędu na polski
- `mobile/lib/features/contractor/screens/contractor_home_screen.dart` - wyświetlanie komunikatu użytkownikowi

## Proces KYC (do zaimplementowania)
1. Wykonawca przesyła zdjęcie dokumentu tożsamości
2. Wykonawca przesyła selfie do weryfikacji
3. Wykonawca podaje dane konta bankowego do wypłat
4. System (Onfido) weryfikuje dokumenty
5. Po pozytywnej weryfikacji `kycStatus` zmienia się na `VERIFIED`
6. Wykonawca może przejść w tryb online

## Endpointy KYC (już istnieją)
- `POST /contractor/kyc/id` - przesłanie dokumentu tożsamości
- `POST /contractor/kyc/selfie` - przesłanie selfie
- `POST /contractor/kyc/bank` - przesłanie danych bankowych

## Priorytiet
**Wysoki** - wymagane przed publicznym uruchomieniem aplikacji dla bezpieczeństwa użytkowników.
