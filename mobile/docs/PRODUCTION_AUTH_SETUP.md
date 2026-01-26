# Production Authentication Setup Guide

> **Security-first guide** for deploying Szybka Fucha authentication in production environments.

## Table of Contents

1. [Security Overview](#security-overview)
2. [Prerequisites](#prerequisites)
3. [Infrastructure Setup](#infrastructure-setup)
4. [Backend Configuration](#backend-configuration)
5. [Phone OTP Authentication](#phone-otp-authentication)
6. [Google Sign-In Setup](#google-sign-in-setup)
7. [Apple Sign-In Setup](#apple-sign-in-setup)
8. [Mobile App Configuration](#mobile-app-configuration)
9. [Security Hardening](#security-hardening)
10. [Monitoring & Alerting](#monitoring--alerting)
11. [Incident Response](#incident-response)
12. [Compliance Checklist](#compliance-checklist)

---

## Security Overview

### Authentication Flow Architecture

```
┌─────────────────┐      HTTPS Only      ┌─────────────────┐
│   Mobile App    │◄────────────────────►│  Load Balancer  │
│  (Flutter)      │                      │  (TLS 1.3)      │
└─────────────────┘                      └────────┬────────┘
                                                  │
                                         ┌────────▼────────┐
                                         │  Backend API    │
                                         │  (NestJS)       │
                                         └────────┬────────┘
                                                  │
                    ┌─────────────────────────────┼─────────────────────────────┐
                    │                             │                             │
           ┌────────▼────────┐           ┌───────▼───────┐           ┌─────────▼─────────┐
           │   PostgreSQL    │           │     Redis     │           │  External APIs    │
           │   (Encrypted)   │           │   (Encrypted) │           │  Twilio/Google/   │
           └─────────────────┘           └───────────────┘           │  Apple            │
                                                                     └───────────────────┘
```

### Current Implementation Status

| Feature | Status | Security Level |
|---------|--------|----------------|
| Phone OTP | ✅ Implemented | ⚠️ Needs production SMS provider |
| Google OAuth | ⚠️ Partial | ❌ Missing server-side token verification |
| Apple Sign-In | ⚠️ Partial | ❌ Missing server-side token verification |
| JWT Authentication | ✅ Implemented | ⚠️ No refresh token mechanism |
| Rate Limiting | ✅ Implemented | ✅ Production ready |

### Critical Security Gaps to Address

Before deploying to production, you **MUST** implement:

1. **Server-side OAuth token verification** - Currently the backend trusts client-provided IDs
2. **Refresh token mechanism** - Currently only 30-day access tokens
3. **HTTPS enforcement** - Must be configured at infrastructure level

---

## Prerequisites

### Required Infrastructure

| Component | Minimum Spec | Recommended |
|-----------|--------------|-------------|
| Backend Server | 2 vCPU, 4GB RAM | 4 vCPU, 8GB RAM |
| PostgreSQL | 2 vCPU, 4GB RAM, 100GB SSD | Managed DB (RDS/Cloud SQL) |
| Redis | 1 vCPU, 2GB RAM | Managed Redis (ElastiCache/Memorystore) |
| Load Balancer | - | AWS ALB / GCP LB / Cloudflare |

### Required Accounts

| Service | Purpose | Required For |
|---------|---------|--------------|
| Twilio | SMS OTP delivery | Phone authentication |
| Google Cloud | OAuth credentials | Google Sign-In |
| Apple Developer | OAuth credentials | Apple Sign-In |
| Sentry/DataDog | Error monitoring | All (recommended) |

### Software Requirements

- Node.js 20 LTS (not 18 - security patches)
- Docker 24+ with Compose v2
- Flutter 3.x stable channel
- Xcode 15+ (for iOS builds)
- Android Studio Hedgehog+ (for Android builds)

---

## Infrastructure Setup

### 1. TLS/SSL Configuration

**All production traffic MUST use HTTPS/TLS 1.3.**

#### Load Balancer Configuration (AWS ALB Example)

```yaml
# terraform/alb.tf
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = aws_acm_certificate.main.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

# Redirect HTTP to HTTPS
resource "aws_lb_listener" "http_redirect" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
```

### 2. Database Encryption

#### PostgreSQL with Encryption at Rest

```yaml
# docker-compose.prod.yml
services:
  postgres:
    image: postgis/postgis:15-3.3-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    command:
      - "postgres"
      - "-c"
      - "ssl=on"
      - "-c"
      - "ssl_cert_file=/var/lib/postgresql/server.crt"
      - "-c"
      - "ssl_key_file=/var/lib/postgresql/server.key"
```

### 3. Redis Security

```yaml
# docker-compose.prod.yml
services:
  redis:
    image: redis:7-alpine
    command: >
      redis-server
      --requirepass ${REDIS_PASSWORD}
      --appendonly yes
      --maxmemory 256mb
      --maxmemory-policy volatile-lru
```

---

## Backend Configuration

### 1. Environment Variables

Create production environment file with proper secret management:

```bash
# /etc/szybkafucha/.env.production
# NEVER commit this file to version control

# =============================================================================
# CORE SETTINGS
# =============================================================================
NODE_ENV=production
PORT=3000
API_PREFIX=api/v1

# =============================================================================
# DATABASE (Use connection pooling in production)
# =============================================================================
DATABASE_HOST=your-db-host.rds.amazonaws.com
DATABASE_PORT=5432
DATABASE_USERNAME=szybkafucha_prod
DATABASE_PASSWORD=<GENERATE_STRONG_PASSWORD_MIN_32_CHARS>
DATABASE_NAME=szybkafucha_prod
DATABASE_SSL=true
DATABASE_POOL_SIZE=20

# =============================================================================
# REDIS (For OTP storage and caching)
# =============================================================================
REDIS_HOST=your-redis-host.cache.amazonaws.com
REDIS_PORT=6379
REDIS_PASSWORD=<GENERATE_STRONG_PASSWORD>
REDIS_TLS=true

# =============================================================================
# JWT CONFIGURATION
# =============================================================================
# Generate with: openssl rand -base64 64
JWT_SECRET=<GENERATE_64_CHAR_RANDOM_STRING>
JWT_EXPIRES_IN=30d

# =============================================================================
# CORS (Restrict to your domains only)
# =============================================================================
CORS_ORIGIN=https://szybkafucha.pl,https://admin.szybkafucha.pl

# =============================================================================
# TWILIO (SMS OTP)
# =============================================================================
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=<YOUR_AUTH_TOKEN>
TWILIO_PHONE_NUMBER=+48XXXXXXXXX

# =============================================================================
# GOOGLE OAUTH
# =============================================================================
GOOGLE_CLIENT_ID=xxxxxxxxxxxx.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=<YOUR_CLIENT_SECRET>

# =============================================================================
# APPLE SIGN-IN
# =============================================================================
APPLE_CLIENT_ID=pl.szybkafucha.mobile
APPLE_TEAM_ID=XXXXXXXXXX
APPLE_KEY_ID=XXXXXXXXXX
# Store private key in secure vault, reference here
APPLE_PRIVATE_KEY_PATH=/etc/szybkafucha/keys/apple-auth.p8

# =============================================================================
# RATE LIMITING
# =============================================================================
THROTTLE_TTL=60
THROTTLE_LIMIT=100
```

### 2. Secret Management

**Never store secrets in environment files in production.** Use a secrets manager:

#### AWS Secrets Manager

```typescript
// backend/src/config/secrets.service.ts
import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

@Injectable()
export class SecretsService {
  private client = new SecretsManagerClient({ region: 'eu-central-1' });

  async getSecret(secretName: string): Promise<string> {
    const command = new GetSecretValueCommand({ SecretId: secretName });
    const response = await this.client.send(command);
    return response.SecretString;
  }
}
```

#### HashiCorp Vault

```bash
# Store secrets
vault kv put secret/szybkafucha/prod \
  jwt_secret="$(openssl rand -base64 64)" \
  db_password="$(openssl rand -base64 32)" \
  twilio_auth_token="your-token"

# Application reads via Vault Agent
```

### 3. Database Migrations

**Disable TypeORM synchronize in production:**

```typescript
// backend/src/app.module.ts
TypeOrmModule.forRoot({
  // ... other config
  synchronize: false, // CRITICAL: Must be false in production
  migrationsRun: true,
  migrations: ['dist/migrations/*.js'],
})
```

Generate and run migrations:

```bash
# Generate migration from entity changes
npm run typeorm migration:generate -- -n AuthUpdates

# Run migrations
npm run typeorm migration:run
```

---

## Phone OTP Authentication

### Production Configuration

#### Rate Limiting (Already Implemented)

The backend has rate limiting configured:

| Endpoint | Limit | Window |
|----------|-------|--------|
| `POST /auth/phone/request-otp` | 3 requests | 60 seconds |
| `POST /auth/phone/verify` | 5 attempts | 60 seconds |
| Global | 100 requests | 60 seconds |

#### Twilio Production Setup

1. **Upgrade Twilio Account**
   - Verify your business identity
   - Register your phone number for A2P 10DLC (US) or local regulations
   - Set up Messaging Service for better deliverability

2. **Configure Twilio Messaging Service**

```typescript
// backend/src/auth/sms.service.ts
import { Twilio } from 'twilio';

@Injectable()
export class SmsService {
  private client: Twilio;

  constructor(private configService: ConfigService) {
    this.client = new Twilio(
      configService.get('TWILIO_ACCOUNT_SID'),
      configService.get('TWILIO_AUTH_TOKEN'),
    );
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    await this.client.messages.create({
      to: phone,
      messagingServiceSid: this.configService.get('TWILIO_MESSAGING_SERVICE_SID'),
      body: `Twój kod weryfikacyjny Szybka Fucha: ${code}. Ważny przez 5 minut. Nie udostępniaj tego kodu nikomu.`,
    });
  }
}
```

3. **Fraud Prevention**
   - Enable Twilio Verify for built-in fraud detection
   - Set geographic restrictions (Poland only for launch)
   - Monitor for SMS pumping attacks

#### OTP Security Best Practices

```typescript
// backend/src/auth/auth.service.ts - Production OTP generation
private generateOtp(): string {
  // Use cryptographically secure random number
  const array = new Uint32Array(1);
  crypto.getRandomValues(array);
  return String(100000 + (array[0] % 900000));
}
```

### Testing Phone OTP

```bash
# Request OTP
curl -X POST https://api.szybkafucha.pl/api/v1/auth/phone/request-otp \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48123456789"}'

# Expected Response
{
  "message": "OTP sent successfully",
  "expiresIn": 300
}

# Verify OTP
curl -X POST https://api.szybkafucha.pl/api/v1/auth/phone/verify \
  -H "Content-Type: application/json" \
  -d '{"phone": "+48123456789", "code": "123456"}'

# Expected Response
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "uuid",
    "type": "client",
    "status": "active"
  },
  "isNewUser": true
}
```

---

## Google Sign-In Setup

### Critical: Implement Server-Side Token Verification

**The current implementation does NOT verify Google ID tokens server-side.** You must implement this before production.

#### Step 1: Install Google Auth Library

```bash
cd backend
npm install google-auth-library
```

#### Step 2: Implement Token Verification

```typescript
// backend/src/auth/google-auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { OAuth2Client } from 'google-auth-library';

interface GoogleUserPayload {
  sub: string;      // Google User ID (use this, not email)
  email: string;
  email_verified: boolean;
  name?: string;
  picture?: string;
}

@Injectable()
export class GoogleAuthService {
  private client: OAuth2Client;

  constructor(private configService: ConfigService) {
    this.client = new OAuth2Client(
      configService.get('GOOGLE_CLIENT_ID'),
    );
  }

  async verifyIdToken(idToken: string): Promise<GoogleUserPayload> {
    try {
      const ticket = await this.client.verifyIdToken({
        idToken,
        audience: this.configService.get('GOOGLE_CLIENT_ID'),
      });

      const payload = ticket.getPayload();

      if (!payload) {
        throw new UnauthorizedException('Invalid Google token');
      }

      if (!payload.email_verified) {
        throw new UnauthorizedException('Google email not verified');
      }

      return {
        sub: payload.sub,
        email: payload.email!,
        email_verified: payload.email_verified,
        name: payload.name,
        picture: payload.picture,
      };
    } catch (error) {
      throw new UnauthorizedException('Failed to verify Google token');
    }
  }
}
```

#### Step 3: Update Auth Service

```typescript
// backend/src/auth/auth.service.ts
async loginWithGoogle(idToken: string, userType?: UserType): Promise<AuthResponse> {
  // Verify the token server-side
  const googleUser = await this.googleAuthService.verifyIdToken(idToken);

  // Use Google's sub (subject) as the unique identifier, NOT email
  let user = await this.usersService.findByGoogleId(googleUser.sub);

  if (!user) {
    // Check if user exists with this email
    user = await this.usersService.findByEmail(googleUser.email);

    if (user) {
      // Link Google account to existing user
      await this.usersService.linkGoogleAccount(user.id, googleUser.sub);
    } else {
      // Create new user
      user = await this.usersService.create({
        googleId: googleUser.sub,
        email: googleUser.email,
        name: googleUser.name,
        avatarUrl: googleUser.picture,
        type: userType || UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
    }
  }

  return this.generateToken(user);
}
```

#### Step 4: Update DTO

```typescript
// backend/src/auth/dto/google-auth.dto.ts
import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { UserType } from '../../users/entities/user.entity';

export class GoogleAuthDto {
  @IsString()
  @IsNotEmpty()
  idToken: string;  // Changed from googleId to idToken

  @IsOptional()
  @IsEnum(UserType)
  userType?: UserType;
}
```

#### Step 5: Update Controller

```typescript
// backend/src/auth/auth.controller.ts
@Post('google')
async loginWithGoogle(@Body() dto: GoogleAuthDto) {
  return this.authService.loginWithGoogle(dto.idToken, dto.userType);
}
```

### Google Cloud Console Setup

1. **Create OAuth 2.0 Credentials**

   - Go to [Google Cloud Console](https://console.cloud.google.com)
   - Navigate to APIs & Services > Credentials
   - Create OAuth 2.0 Client IDs for:
     - iOS application (Bundle ID: `pl.szybkafucha.mobile`)
     - Android application (Package: `pl.szybkafucha.mobile`, SHA-1 fingerprint)
     - Web application (for backend verification)

2. **Configure OAuth Consent Screen**

   - User Type: External
   - Scopes: `email`, `profile`, `openid`
   - Add privacy policy and terms of service URLs

3. **Production Verification**

   - Submit for Google verification before launch
   - Required for apps with >100 users

### Mobile App Integration

```dart
// mobile/lib/services/google_sign_in_service.dart
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  Future<String?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final auth = await account.authentication;

      // Return the ID token for backend verification
      return auth.idToken;
    } catch (e) {
      rethrow;
    }
  }
}

// In auth_provider.dart
Future<void> loginWithGoogle() async {
  final idToken = await _googleSignInService.signIn();
  if (idToken == null) return;

  final response = await _api.post('/auth/google', data: {
    'idToken': idToken,
  });

  // Handle response...
}
```

---

## Apple Sign-In Setup

### Critical: Implement Server-Side Token Verification

**The current implementation does NOT verify Apple ID tokens server-side.** You must implement this before production.

#### Step 1: Install Dependencies

```bash
cd backend
npm install jsonwebtoken jwks-rsa
```

#### Step 2: Implement Apple Token Verification

```typescript
// backend/src/auth/apple-auth.service.ts
import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as jwt from 'jsonwebtoken';
import jwksClient from 'jwks-rsa';

interface AppleTokenPayload {
  sub: string;           // Apple User ID
  email?: string;        // May be private relay email
  email_verified?: boolean;
  is_private_email?: boolean;
}

@Injectable()
export class AppleAuthService {
  private jwksClient: jwksClient.JwksClient;

  constructor(private configService: ConfigService) {
    this.jwksClient = jwksClient({
      jwksUri: 'https://appleid.apple.com/auth/keys',
      cache: true,
      cacheMaxAge: 86400000, // 24 hours
    });
  }

  async verifyIdentityToken(identityToken: string): Promise<AppleTokenPayload> {
    try {
      // Decode header to get key ID
      const decoded = jwt.decode(identityToken, { complete: true });
      if (!decoded || !decoded.header.kid) {
        throw new UnauthorizedException('Invalid Apple token format');
      }

      // Get the signing key from Apple
      const key = await this.jwksClient.getSigningKey(decoded.header.kid);
      const publicKey = key.getPublicKey();

      // Verify the token
      const payload = jwt.verify(identityToken, publicKey, {
        algorithms: ['RS256'],
        issuer: 'https://appleid.apple.com',
        audience: this.configService.get('APPLE_CLIENT_ID'),
      }) as AppleTokenPayload;

      return {
        sub: payload.sub,
        email: payload.email,
        email_verified: payload.email_verified,
        is_private_email: payload.is_private_email,
      };
    } catch (error) {
      throw new UnauthorizedException('Failed to verify Apple token');
    }
  }
}
```

#### Step 3: Update Auth Service

```typescript
// backend/src/auth/auth.service.ts
async loginWithApple(
  identityToken: string,
  fullName?: { givenName?: string; familyName?: string },
  userType?: UserType,
): Promise<AuthResponse> {
  // Verify the token server-side
  const appleUser = await this.appleAuthService.verifyIdentityToken(identityToken);

  // Use Apple's sub (subject) as the unique identifier
  let user = await this.usersService.findByAppleId(appleUser.sub);

  if (!user) {
    // Check if user exists with this email (if provided)
    if (appleUser.email) {
      user = await this.usersService.findByEmail(appleUser.email);

      if (user) {
        // Link Apple account to existing user
        await this.usersService.linkAppleAccount(user.id, appleUser.sub);
      }
    }

    if (!user) {
      // Create new user
      const name = fullName
        ? `${fullName.givenName || ''} ${fullName.familyName || ''}`.trim()
        : undefined;

      user = await this.usersService.create({
        appleId: appleUser.sub,
        email: appleUser.email,
        name: name || undefined,
        type: userType || UserType.CLIENT,
        status: UserStatus.ACTIVE,
      });
    }
  }

  return this.generateToken(user);
}
```

#### Step 4: Update DTO

```typescript
// backend/src/auth/dto/apple-auth.dto.ts
import { IsString, IsNotEmpty, IsOptional, IsEnum, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { UserType } from '../../users/entities/user.entity';

class AppleFullName {
  @IsOptional()
  @IsString()
  givenName?: string;

  @IsOptional()
  @IsString()
  familyName?: string;
}

export class AppleAuthDto {
  @IsString()
  @IsNotEmpty()
  identityToken: string;  // Changed from appleId to identityToken

  @IsOptional()
  @ValidateNested()
  @Type(() => AppleFullName)
  fullName?: AppleFullName;

  @IsOptional()
  @IsEnum(UserType)
  userType?: UserType;
}
```

### Apple Developer Portal Setup

1. **Configure App ID**

   - Go to [Apple Developer Portal](https://developer.apple.com)
   - Identifiers > App IDs
   - Enable "Sign in with Apple" capability

2. **Create Service ID** (for web/backend)

   - Identifiers > Services IDs
   - Register identifier: `pl.szybkafucha.service`
   - Configure domains and return URLs

3. **Create Private Key**

   - Keys > Create new key
   - Enable "Sign in with Apple"
   - Download `.p8` file (store securely!)
   - Note the Key ID

4. **Store Key Securely**

   ```bash
   # Store in secrets manager, not filesystem
   aws secretsmanager create-secret \
     --name szybkafucha/apple-auth-key \
     --secret-string file://AuthKey_XXXXXXXX.p8
   ```

### Mobile App Integration (iOS)

```dart
// mobile/lib/services/apple_sign_in_service.dart
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AppleSignInService {
  Future<AppleSignInResult> signIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      return AppleSignInResult(
        identityToken: credential.identityToken!,
        givenName: credential.givenName,
        familyName: credential.familyName,
      );
    } catch (e) {
      rethrow;
    }
  }
}

// In auth_provider.dart
Future<void> loginWithApple() async {
  final result = await _appleSignInService.signIn();

  final response = await _api.post('/auth/apple', data: {
    'identityToken': result.identityToken,
    'fullName': {
      'givenName': result.givenName,
      'familyName': result.familyName,
    },
  });

  // Handle response...
}
```

---

## Mobile App Configuration

### API Configuration

```dart
// mobile/lib/core/api/api_config.dart
class ApiConfig {
  // NEVER enable dev mode in production builds
  static const bool devModeEnabled = false;

  // Production API URL
  static const String prodBaseUrl = 'https://api.szybkafucha.pl/api/v1';

  // Development API URL (only used when devModeEnabled = true)
  static const String devBaseUrl = 'http://localhost:3000/api/v1';

  static String get baseUrl => devModeEnabled ? devBaseUrl : prodBaseUrl;

  // Connection timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
```

### Secure Token Storage

```dart
// mobile/lib/core/storage/secure_storage.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static const _tokenKey = 'auth_token';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}
```

### Certificate Pinning (Recommended)

```dart
// mobile/lib/core/api/certificate_pinning.dart
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureCertificatePinning(Dio dio) {
  (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
    final client = HttpClient();
    client.badCertificateCallback = (cert, host, port) {
      // Only allow your domain
      if (host != 'api.szybkafucha.pl') return false;

      // Verify certificate fingerprint
      final fingerprint = cert.sha256.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');

      // Your certificate's SHA-256 fingerprint
      const expectedFingerprint = 'XX:XX:XX:...';

      return fingerprint.toUpperCase() == expectedFingerprint.toUpperCase();
    };
    return client;
  };
}
```

### Build Configuration

#### iOS (Release Build)

```bash
# Build for release
flutter build ios --release

# Archive for App Store
# Open in Xcode: Product > Archive
```

#### Android (Release Build)

```bash
# Create keystore (once)
keytool -genkey -v -keystore szybkafucha-release.keystore \
  -alias szybkafucha \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# Configure signing in android/app/build.gradle
# Build release APK
flutter build apk --release

# Build release App Bundle (for Play Store)
flutter build appbundle --release
```

---

## Security Hardening

### 1. HTTP Security Headers

```typescript
// backend/src/main.ts
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // Security headers
  app.use(helmet({
    contentSecurityPolicy: {
      directives: {
        defaultSrc: ["'self'"],
        styleSrc: ["'self'", "'unsafe-inline'"],
        imgSrc: ["'self'", 'data:', 'https:'],
        scriptSrc: ["'self'"],
      },
    },
    hsts: {
      maxAge: 31536000,
      includeSubDomains: true,
      preload: true,
    },
  }));

  // CORS with strict origin checking
  app.enableCors({
    origin: (origin, callback) => {
      const allowedOrigins = process.env.CORS_ORIGIN?.split(',') || [];
      if (!origin || allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        callback(new Error('Not allowed by CORS'));
      }
    },
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
  });

  await app.listen(3000);
}
```

### 2. Input Validation & Sanitization

```typescript
// backend/src/main.ts
import { ValidationPipe } from '@nestjs/common';

app.useGlobalPipes(new ValidationPipe({
  whitelist: true,           // Strip unknown properties
  forbidNonWhitelisted: true, // Throw on unknown properties
  transform: true,            // Transform payloads to DTO instances
  transformOptions: {
    enableImplicitConversion: false, // Prevent type coercion attacks
  },
}));
```

### 3. Rate Limiting Configuration

```typescript
// backend/src/app.module.ts
import { ThrottlerModule } from '@nestjs/throttler';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        name: 'short',
        ttl: 1000,    // 1 second
        limit: 10,    // 10 requests per second
      },
      {
        name: 'medium',
        ttl: 60000,   // 1 minute
        limit: 100,   // 100 requests per minute
      },
      {
        name: 'long',
        ttl: 3600000, // 1 hour
        limit: 1000,  // 1000 requests per hour
      },
    ]),
  ],
})
```

### 4. Audit Logging

```typescript
// backend/src/common/interceptors/audit.interceptor.ts
@Injectable()
export class AuditInterceptor implements NestInterceptor {
  constructor(private logger: Logger) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const { method, url, ip } = request;

    return next.handle().pipe(
      tap(() => {
        this.logger.log({
          event: 'api_access',
          userId: user?.id,
          method,
          url,
          ip,
          timestamp: new Date().toISOString(),
        });
      }),
    );
  }
}
```

### 5. Implement Refresh Tokens

```typescript
// backend/src/auth/auth.service.ts
interface TokenPair {
  accessToken: string;
  refreshToken: string;
}

async generateTokenPair(user: User): Promise<TokenPair> {
  const payload = { sub: user.id, type: user.type };

  const accessToken = this.jwtService.sign(payload, {
    expiresIn: '15m', // Short-lived access token
  });

  const refreshToken = this.jwtService.sign(
    { sub: user.id, type: 'refresh' },
    { expiresIn: '30d' },
  );

  // Store refresh token hash in database for revocation
  await this.storeRefreshToken(user.id, refreshToken);

  return { accessToken, refreshToken };
}

async refreshAccessToken(refreshToken: string): Promise<TokenPair> {
  try {
    const payload = this.jwtService.verify(refreshToken);

    if (payload.type !== 'refresh') {
      throw new UnauthorizedException('Invalid token type');
    }

    // Verify refresh token is still valid in database
    const isValid = await this.validateStoredRefreshToken(payload.sub, refreshToken);
    if (!isValid) {
      throw new UnauthorizedException('Refresh token revoked');
    }

    const user = await this.usersService.findById(payload.sub);
    if (!user || user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException('User not found or inactive');
    }

    // Rotate refresh token
    return this.generateTokenPair(user);
  } catch (error) {
    throw new UnauthorizedException('Invalid refresh token');
  }
}
```

---

## Monitoring & Alerting

### 1. Application Monitoring

```typescript
// backend/src/common/interceptors/metrics.interceptor.ts
import { Injectable, NestInterceptor, ExecutionContext, CallHandler } from '@nestjs/common';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';
import * as Sentry from '@sentry/node';

@Injectable()
export class MetricsInterceptor implements NestInterceptor {
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const request = context.switchToHttp().getRequest();
    const startTime = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const duration = Date.now() - startTime;
          // Send to your metrics service (DataDog, Prometheus, etc.)
          this.recordMetric(request.url, request.method, 200, duration);
        },
        error: (error) => {
          const duration = Date.now() - startTime;
          this.recordMetric(request.url, request.method, error.status || 500, duration);
          Sentry.captureException(error);
        },
      }),
    );
  }
}
```

### 2. Security Alerts

Set up alerts for:

| Event | Threshold | Action |
|-------|-----------|--------|
| Failed login attempts | > 10/minute from same IP | Block IP, notify security |
| OTP request spike | > 100/minute globally | Rate limit, investigate |
| JWT validation failures | > 50/minute | Investigate token leak |
| New admin login | Any | Notify team |
| User account linking | Any | Log for audit |

### 3. Health Checks

```typescript
// backend/src/health/health.controller.ts
@Controller('health')
export class HealthController {
  constructor(
    private health: HealthCheckService,
    private db: TypeOrmHealthIndicator,
    private redis: RedisHealthIndicator,
  ) {}

  @Get()
  @HealthCheck()
  check() {
    return this.health.check([
      () => this.db.pingCheck('database'),
      () => this.redis.checkHealth('redis'),
    ]);
  }
}
```

---

## Incident Response

### Authentication Breach Playbook

#### 1. JWT Secret Compromised

```bash
# 1. Rotate JWT secret immediately
export JWT_SECRET=$(openssl rand -base64 64)

# 2. Restart all backend instances
kubectl rollout restart deployment/backend

# 3. All users will need to re-authenticate
# Tokens signed with old secret will be invalid

# 4. Investigate how secret was compromised
# Check access logs, audit trails
```

#### 2. Mass Account Takeover Suspected

```sql
-- 1. Identify affected accounts
SELECT * FROM users
WHERE updated_at > NOW() - INTERVAL '1 hour'
AND (google_id IS NOT NULL OR apple_id IS NOT NULL);

-- 2. Suspend suspicious accounts
UPDATE users SET status = 'SUSPENDED'
WHERE id IN (SELECT ...);

-- 3. Invalidate all sessions (if using refresh tokens)
DELETE FROM refresh_tokens WHERE user_id IN (SELECT ...);
```

#### 3. SMS OTP Abuse (Pumping Attack)

```bash
# 1. Enable Twilio Fraud Guard
# 2. Block abused phone number prefixes
# 3. Implement additional verification (CAPTCHA)
# 4. Review rate limits
```

---

## Compliance Checklist

### GDPR Requirements

- [ ] User can request data export (`GET /users/me/data-export`)
- [ ] User can delete account (`DELETE /users/me`)
- [ ] Consent recorded for marketing communications
- [ ] Privacy policy accessible and up-to-date
- [ ] Data processing agreements with Twilio, Google, Apple
- [ ] OTP codes auto-expire (5 minutes) - implemented
- [ ] JWT tokens have expiration - implemented (30 days)

### Security Audit Checklist

- [ ] Server-side OAuth token verification (Google) - **TODO**
- [ ] Server-side OAuth token verification (Apple) - **TODO**
- [ ] Refresh token mechanism - **TODO**
- [ ] HTTPS enforced at load balancer level
- [ ] Database encryption at rest enabled
- [ ] Redis authentication enabled
- [ ] Secrets stored in secrets manager (not env files)
- [ ] Rate limiting configured and tested
- [ ] Security headers configured (HSTS, CSP, etc.)
- [ ] Audit logging enabled
- [ ] Monitoring and alerting configured
- [ ] Incident response procedures documented

### Pre-Launch Checklist

- [ ] All TODO items above completed
- [ ] Penetration testing performed
- [ ] Load testing performed (target: 1000 concurrent users)
- [ ] Disaster recovery tested
- [ ] Backup procedures verified
- [ ] On-call rotation established
- [ ] Runbooks documented for common issues

---

## API Reference

### Authentication Endpoints

| Endpoint | Method | Auth | Rate Limit | Description |
|----------|--------|------|------------|-------------|
| `/auth/phone/request-otp` | POST | None | 3/60s | Request SMS OTP |
| `/auth/phone/verify` | POST | None | 5/60s | Verify OTP, get tokens |
| `/auth/google` | POST | None | 10/60s | Google Sign-In |
| `/auth/apple` | POST | None | 10/60s | Apple Sign-In |
| `/auth/refresh` | POST | Refresh Token | 10/60s | Refresh access token |
| `/auth/logout` | POST | JWT | 10/60s | Invalidate refresh token |

### Request/Response Examples

#### Phone OTP Request

```bash
POST /api/v1/auth/phone/request-otp
Content-Type: application/json

{
  "phone": "+48123456789"
}
```

```json
// 200 OK
{
  "message": "OTP sent successfully",
  "expiresIn": 300
}

// 429 Too Many Requests
{
  "statusCode": 429,
  "message": "Rate limit exceeded. Try again in 60 seconds."
}
```

#### Google Sign-In (After implementing token verification)

```bash
POST /api/v1/auth/google
Content-Type: application/json

{
  "idToken": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "userType": "client"
}
```

```json
// 200 OK
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "eyJhbGciOiJIUzI1NiIs...",
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "type": "client",
    "email": "user@gmail.com",
    "name": "Jan Kowalski",
    "status": "active"
  }
}

// 401 Unauthorized
{
  "statusCode": 401,
  "message": "Failed to verify Google token"
}
```

---

## Next Steps After Authentication

1. **Implement KYC verification** for contractors (Onfido integration)
2. **Configure Stripe payments** for escrow system
3. **Set up push notifications** (Firebase Cloud Messaging)
4. **Deploy to staging environment** for integration testing
5. **Perform security audit** before production launch

---

## Support

For issues with this setup:

1. Check [Troubleshooting](#troubleshooting) section
2. Review backend logs: `docker logs szybkafucha-backend`
3. Check monitoring dashboards
4. Contact security team for auth-related issues

---

*Last updated: 2026-01-18*
*Version: 1.0.0*
