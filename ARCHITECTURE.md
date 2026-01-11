# Szybka Fucha - Architecture Overview

**Last Updated:** 2026-01-10

---

## 🎯 Dual Backend Strategy

This project uses **two separate backend systems** for different purposes:

```
┌─────────────────────────────────────────────────────────────┐
│                    SZYBKA FUCHA PLATFORM                    │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────┐    ┌──────────────────────────────┐
│   PHASE 1: NOW           │    │   PHASE 2: FUTURE            │
│   Landing Page           │    │   Mobile Application         │
└──────────────────────────┘    └──────────────────────────────┘
         │                                  │
         ▼                                  ▼
┌──────────────────────────┐    ┌──────────────────────────────┐
│  Frontend:               │    │  Frontend:                   │
│  - HTML/CSS/JS           │    │  - Flutter / React Native    │
│  - 3 language versions   │    │  - iOS + Android             │
│  - Static files          │    │  - Web dashboard (React)     │
└──────────┬───────────────┘    └────────────┬─────────────────┘
           │                                  │
           ▼                                  ▼
┌──────────────────────────┐    ┌──────────────────────────────┐
│  Backend:                │    │  Backend:                    │
│  PHP + MySQL             │    │  NestJS + PostgreSQL         │
│  /api/subscribe.php      │    │  Full REST API               │
│  Newsletter only         │    │  WebSocket support           │
│  Simple & cheap          │    │  Payments, Chat, KYC         │
└──────────┬───────────────┘    └────────────┬─────────────────┘
           │                                  │
           ▼                                  ▼
┌──────────────────────────┐    ┌──────────────────────────────┐
│  Database:               │    │  Database:                   │
│  MySQL                   │    │  PostgreSQL + PostGIS        │
│  newsletter_subscribers  │◄───┤  Users, Tasks, Messages,     │
│  table                   │    │  Payments, Ratings, etc.     │
└──────────────────────────┘    └──────────────────────────────┘
                                        ▲
                  Bridge API ───────────┘
              (check-subscriber.php)
```

---

## 📋 System Comparison

| Feature | PHP/MySQL (Landing Page) | NestJS/PostgreSQL (Mobile App) |
|---------|-------------------------|--------------------------------|
| **Purpose** | Newsletter collection | Full platform features |
| **Status** | ✅ ACTIVE (in use) | ✅ READY (for future app) |
| **Technology** | PHP 7.4+, MySQL 8.0 | NestJS 11, PostgreSQL 15, Redis |
| **Hosting** | Shared hosting OK | VPS/Cloud required |
| **Cost** | $5-10/month | $20-50/month |
| **Complexity** | Simple | Complex |
| **Features** | Email signup only | Auth, Chat, Payments, KYC |
| **Scalability** | Low (100s of users) | High (millions of users) |
| **Real-time** | ❌ No | ✅ Yes (WebSocket) |
| **Mobile-ready** | ❌ Web only | ✅ Native apps |

---

## 🔄 Data Sync Strategy

### Current Flow (Landing Page → MySQL):
```
User fills form on landing page
         ↓
    POST /api/subscribe.php
         ↓
    Stored in MySQL
    (newsletter_subscribers table)
```

### Future Flow (App Registration):
```
User downloads mobile app
         ↓
    Registers with email/phone
         ↓
    NestJS calls check-subscriber.php
         ↓
    PHP checks MySQL for existing subscriber
         ↓
    Returns user data if found
         ↓
    NestJS pre-fills name, preferences
         ↓
    User saved to PostgreSQL
    (users table)
```

**Result:** Seamless experience - no duplicate data entry!

See: [`backend/MYSQL_SYNC_GUIDE.md`](backend/MYSQL_SYNC_GUIDE.md)

---

## 📂 File Structure

### Landing Page (Production-Ready):
```
/
├── index.html          # Polish version
├── index-en.html       # British English version
├── index-ua.html       # Ukrainian version
├── styles.css          # Shared styles
├── script.js           # Shared JavaScript
├── privacy.html        # Privacy policy
├── terms.html          # Terms of service
├── cookies.html        # Cookie policy
├── robots.txt          # SEO
├── sitemap.xml         # SEO
├── assets/             # Images, videos
└── api/                # PHP backend
    ├── config.php
    ├── subscribe.php           # Newsletter signup (ACTIVE)
    └── check-subscriber.php    # Bridge for NestJS (READY)
```

### Mobile App Backend (Ready for Development):
```
backend/
├── src/
│   ├── auth/               # JWT, Google, Apple, Phone OTP
│   ├── users/              # User management
│   ├── tasks/              # Task CRUD & lifecycle
│   ├── messages/           # In-app chat
│   ├── realtime/           # WebSocket gateway
│   ├── payments/           # Stripe escrow
│   ├── contractor/         # Contractor profiles
│   ├── kyc/                # Onfido verification
│   ├── newsletter/         # Newsletter module
│   ├── admin/              # Admin operations
│   ├── health/             # Health check ✅
│   └── common/
│       └── filters/
│           └── http-exception.filter.ts  # Global errors ✅
├── MYSQL_SYNC_GUIDE.md     # How to sync data ✅
├── TEST_RESULTS.md         # Security fixes status ✅
└── SETUP.md                # Development setup
```

---

## 🚀 Deployment Strategy

### Phase 1: Landing Page (NOW)
**What to deploy:**
- HTML files (index.html, index-en.html, index-ua.html)
- CSS/JS files
- Assets folder
- PHP API (`/api/` folder)
- MySQL database

**Where to deploy:**
- Shared hosting (e.g., Hostinger, Bluehost) ✅
- Or VPS (e.g., DigitalOcean, AWS Lightsail)

**Requirements:**
- PHP 7.4+ support
- MySQL 8.0+ database
- SSL certificate
- Domain configured

**Cost:** $5-10/month

---

### Phase 2: Mobile App (FUTURE)
**What to deploy:**
- NestJS backend (`backend/` folder)
- PostgreSQL database
- Redis server

**Where to deploy:**
- VPS required (DigitalOcean, AWS EC2, Google Cloud)
- Or Platform-as-a-Service (Railway, Render, Heroku)

**Requirements:**
- Node.js 18+
- PostgreSQL with PostGIS extension
- Redis server
- Twilio account (SMS)
- Stripe account (payments)
- Onfido account (KYC)

**Cost:** $20-50/month (scales with usage)

---

## 🔒 Security Status

### PHP/MySQL (Landing Page):
- ✅ Prepared statements (SQL injection safe)
- ✅ Input validation (email, name, consent)
- ✅ Input sanitization (htmlspecialchars)
- ✅ CORS configured
- ✅ HTTPS enforced
- ⏳ Rate limiting (optional, server-level)

**Status:** Production-ready ✅

---

### NestJS/PostgreSQL (Mobile App):
- ✅ CORS vulnerability fixed
- ✅ Rate limiting added (@nestjs/throttler)
- ✅ OTP storage in Redis (was in memory)
- ✅ Global exception filter
- ✅ Health check endpoint
- ✅ Helmet.js security headers
- ✅ Twilio SMS integration
- ✅ JWT authentication
- ✅ Role-based access control

**Status:** Production-ready (95/100) ✅

See: [`backend/TEST_RESULTS.md`](backend/TEST_RESULTS.md)

---

## 📊 Feature Comparison

| Feature | Landing Page | Mobile App |
|---------|-------------|------------|
| Newsletter Signup | ✅ | ✅ |
| User Registration | ❌ | ✅ |
| Phone OTP Login | ❌ | ✅ |
| Google/Apple Login | ❌ | ✅ |
| Post Tasks | ❌ | ✅ |
| Accept Tasks | ❌ | ✅ |
| In-app Chat | ❌ | ✅ |
| Real-time Notifications | ❌ | ✅ |
| Payments (Stripe) | ❌ | ✅ |
| Escrow System | ❌ | ✅ |
| KYC Verification | ❌ | ✅ |
| Ratings & Reviews | ❌ | ✅ |
| Location Tracking | ❌ | ✅ |
| Admin Dashboard | ❌ | ✅ |

---

## 🛠️ Technology Stack

### Landing Page
- **Frontend:** Vanilla HTML5, CSS3, JavaScript (ES6+)
- **Backend:** PHP 7.4+
- **Database:** MySQL 8.0+
- **Server:** Apache/Nginx
- **Deployment:** Shared hosting / VPS

### Mobile Application
- **Mobile:** Flutter (iOS + Android) [planned]
- **Web Dashboard:** React 19 + Chakra UI
- **Backend:** NestJS 11 + TypeScript
- **Database:** PostgreSQL 15 + PostGIS
- **Cache:** Redis 7
- **Real-time:** Socket.io (WebSocket)
- **Authentication:** JWT + Passport.js
- **Payments:** Stripe
- **SMS:** Twilio
- **KYC:** Onfido
- **Deployment:** Docker + PM2 / Kubernetes

---

## 📈 Scalability Path

### Stage 1: Landing Page Only (Current)
- Users: 0 → 1,000 subscribers
- Infrastructure: Shared hosting
- Cost: $5-10/month
- Focus: Marketing, email collection

### Stage 2: MVP Mobile App
- Users: 100 → 10,000 active users
- Infrastructure: Single VPS
- Cost: $20-50/month
- Focus: Core features (tasks, chat, payments)

### Stage 3: Growth
- Users: 10,000 → 100,000 active users
- Infrastructure: Load balancer + multiple servers
- Cost: $200-500/month
- Focus: Scaling, performance optimization

### Stage 4: Scale
- Users: 100,000+
- Infrastructure: Microservices, CDN, auto-scaling
- Cost: $1,000+/month
- Focus: Regional expansion, advanced features

---

## 🔗 Integration Points

### Bridge API
**File:** `/api/check-subscriber.php`

Allows NestJS backend to check if a user exists in the MySQL newsletter database.

**Usage:**
```bash
GET /api/check-subscriber.php?email=user@example.com
```

**Response:**
```json
{
  "success": true,
  "found": true,
  "data": {
    "name": "Jan Kowalski",
    "email": "jan@example.com",
    "user_type": "client",
    "services": ["cleaning", "shopping"],
    "city": "Warszawa"
  }
}
```

**When to use:**
- During app user registration
- To pre-fill user data from newsletter
- To track which app users came from landing page

---

## 📝 Development Workflow

### Working on Landing Page:
```bash
# Serve static files
python3 -m http.server 8000

# Open browser
http://localhost:8000/index.html       # Polish
http://localhost:8000/index-en.html    # English
http://localhost:8000/index-ua.html    # Ukrainian
```

### Working on Mobile App Backend:
```bash
# Start services
docker compose up -d postgres redis

# Start NestJS
cd backend
npm run start:dev

# API available at
http://localhost:3000/api/v1
```

---

## 🎯 Summary

**For Landing Page Deployment:**
- Use PHP/MySQL (simple, cheap, works)
- Deploy to shared hosting
- Focus on getting users

**For Mobile App Development:**
- Use NestJS/PostgreSQL (powerful, scalable, ready)
- All features already built
- Backend security fixes completed (95/100)
- Just build the frontend mobile app

**Data Sharing:**
- Bridge API ready (`check-subscriber.php`)
- Seamless user experience
- No data duplication
- Optional full migration later

---

## 📚 Documentation

- **Production Checklist:** [`tasks/PRODUCTION_CHECKLIST.md`](tasks/PRODUCTION_CHECKLIST.md)
- **MySQL Sync Guide:** [`backend/MYSQL_SYNC_GUIDE.md`](backend/MYSQL_SYNC_GUIDE.md)
- **Test Results:** [`backend/TEST_RESULTS.md`](backend/TEST_RESULTS.md)
- **Backend Setup:** [`backend/SETUP.md`](backend/SETUP.md)
- **Product Requirements:** [`tasks/prd-szybka-fucha.md`](tasks/prd-szybka-fucha.md)

---

**Version:** 1.0
**Author:** Claude Code
**Project:** Szybka Fucha
