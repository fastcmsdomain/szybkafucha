---
description: Scan for security anti-patterns and hardcoded secrets
allowed-tools: Grep, Glob, Read
---

# Security Audit

Scan the Flutter codebase and backend for security vulnerabilities, hardcoded secrets, and insecure patterns.

Reference: `tasks/development-guidelines-ios-android-flutter (1).md` — Security Best Practices section.

## Steps

### 1. Hardcoded Secrets

**Search for hardcoded API keys, tokens, and passwords in `.dart` files:**

Grep in `mobile/lib/` for:
- `apiKey\s*=\s*['"]` — hardcoded API keys
- `token\s*=\s*['"]` — hardcoded tokens
- `password\s*=\s*['"]` — hardcoded passwords
- `secret\s*=\s*['"]` — hardcoded secrets
- `sk_live_` or `sk_test_` — Stripe keys
- `AIza` — Google API keys
- `Bearer\s+[A-Za-z0-9]` — hardcoded Bearer tokens

**Exclude**: Test files, mock data, and variable declarations without values.

### 2. Insecure URLs

**Find HTTP (non-HTTPS) URLs:**
Grep for `http://` in `.dart` files under `mobile/lib/`.

**Acceptable exceptions**:
- `http://localhost` — development only
- `http://10.0.2.2` — Android emulator localhost
- `http://127.0.0.1` — loopback

**Flag**: Any other `http://` URL that should be `https://`.

Check that `api_config.dart` uses HTTPS for production URLs.

### 3. Secure Storage Usage

**Verify sensitive data storage:**
- Grep for `SharedPreferences` — what data is stored? Flag if tokens, passwords, or PII are stored here
- Grep for `flutter_secure_storage` or `SecureStorage` — verify tokens and credentials use this
- Check `mobile/lib/core/storage/secure_storage.dart` — what keys are stored securely?

**Data classification:**
- Tokens, passwords, keys → MUST use `flutter_secure_storage`
- User preferences (theme, language) → OK in `SharedPreferences`
- User PII (name, email, phone) → Should use `flutter_secure_storage`

### 4. Debug/Print Statements

**Find debug output that might leak sensitive data:**
Grep for:
- `print(` in `mobile/lib/` (excluding test files)
- `debugPrint(` with variables that might contain tokens/passwords
- `log(` with sensitive context

**Check**: Do any print statements output:
- Auth tokens or JWT
- User passwords or credentials
- API responses with PII
- Payment/financial data

### 5. .gitignore Coverage

**Verify sensitive files are gitignored:**
Read `mobile/.gitignore` and verify it includes:
- `.env`
- `*.jks` (Android keystore)
- `*.p12` (iOS certificates)
- `key.properties`
- `firebase_options.dart` (or verify it doesn't contain production keys)
- `google-services.json`
- `GoogleService-Info.plist`

Also check root `.gitignore` for:
- `backend/.env`
- Any credential files

### 6. Certificate Pinning

**Check for certificate pinning on critical endpoints:**
- Read `mobile/lib/core/api/api_client.dart` — is certificate pinning implemented for production?
- Check if Dio has SSL/certificate configuration
- This is recommended for payment and auth endpoints

### 7. Input Validation

**Check for input sanitization:**
- Grep for `TextEditingController` — are inputs validated before sending to API?
- Check form screens for validation logic
- Verify that user inputs are not directly interpolated into queries or URLs

### 8. Dependency Vulnerabilities

**Check for known vulnerable packages:**
- Read `mobile/pubspec.lock` for package versions
- Flag any packages with known security issues
- Check if all packages are on recent versions

### 9. Report Summary

```
## Security Audit Results

### CRITICAL (must fix before release)
- [hardcoded secrets, insecure storage of tokens]

### WARNING (fix before production)
- [HTTP URLs, missing certificate pinning]
- [debug prints with sensitive data]

### INFO (best practices)
- [gitignore gaps, input validation improvements]

### Stats
- Hardcoded secrets found: X
- Insecure URLs: X
- Debug prints with potential leaks: X
- Secure storage compliance: X%
```
