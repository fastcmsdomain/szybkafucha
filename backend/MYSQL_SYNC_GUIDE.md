# MySQL Newsletter → PostgreSQL App User Sync Guide

## Quick Summary

**Problem:** Newsletter subscribers in MySQL need to seamlessly become app users in PostgreSQL

**Solution:** API Bridge - NestJS calls PHP endpoint to check if user exists in newsletter database

---

## ✅ What I've Created For You

### 1. PHP Endpoint: `/api/check-subscriber.php`

**Purpose:** Allow NestJS to check if an email exists in MySQL newsletter database

**Usage:**
```bash
GET /api/check-subscriber.php?email=user@example.com
```

**Response if found:**
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

---

## 🎯 How It Works

### User Journey:

```
Step 1: User signs up on landing page
        ↓
    Stored in MySQL (newsletter_subscribers)

Step 2: User downloads mobile app (weeks later)
        ↓
    Enters email during app registration
        ↓
    NestJS calls: check-subscriber.php?email=...
        ↓
    PHP returns: user data from MySQL
        ↓
    NestJS pre-fills: name, preferences, user type
        ↓
    User completes registration easily
        ↓
    Stored in PostgreSQL (users table)
```

### Result:
- ✅ User doesn't have to re-enter their name
- ✅ App knows their preferences (client/contractor)
- ✅ Seamless experience
- ✅ Data stays synchronized

---

## 🔧 Implementation Options

### Option A: Auto-Check During Registration (Recommended)

When user registers in the app, automatically check newsletter database:

**Add to backend/.env:**
```bash
PHP_API_URL=http://localhost:8000
```

**Production .env:**
```bash
PHP_API_URL=https://szybkafucha.app
```

**Code changes needed in `auth.service.ts`:**

```typescript
// Add this method to AuthService class
private async checkNewsletterSubscriber(email: string): Promise<any | null> {
  try {
    const phpApiUrl = this.configService.get<string>('PHP_API_URL', 'http://localhost:8000');
    const response = await fetch(
      `${phpApiUrl}/api/check-subscriber.php?email=${encodeURIComponent(email)}`
    );

    if (!response.ok) return null;

    const result = await response.json();
    return result.found ? result.data : null;
  } catch (error) {
    this.logger.error('Error checking newsletter subscriber', error);
    return null; // Don't fail registration if check fails
  }
}

// In authenticateWithGoogle() method, before creating new user:
if (!user) {
  // Check newsletter database
  const newsletterData = await this.checkNewsletterSubscriber(email);

  isNewUser = true;
  user = await this.usersService.create({
    googleId,
    email,
    name: newsletterData?.name || name, // Use newsletter name if available
    avatarUrl,
    type: newsletterData?.user_type || userType || UserType.CLIENT,
    status: UserStatus.ACTIVE,
  });
}
```

### Option B: Manual Sync (For Bulk Migration)

Create an admin endpoint to sync all newsletter subscribers at once:

```bash
POST /api/v1/newsletter/sync-from-mysql
Authorization: Bearer <admin-jwt-token>
```

This would:
1. Fetch all active subscribers from MySQL
2. Create corresponding records in PostgreSQL
3. Return report: `{ synced: 150, skipped: 25 }`

---

## 📋 Setup Checklist

### ✅ Already Done:
- [x] Created `/api/check-subscriber.php` endpoint
- [x] Added CORS headers for NestJS access
- [x] Added email validation and security

### 📝 TODO (When You're Ready for App Development):

1. **Add environment variable:**
   ```bash
   # backend/.env
   PHP_API_URL=http://localhost:8000
   ```

2. **Install fetch in NestJS** (if not already available):
   ```bash
   cd backend
   npm install node-fetch
   ```

3. **Add the check method to auth.service.ts** (see Option A code above)

4. **Test the integration:**
   ```bash
   # Start PHP server
   python3 -m http.server 8000

   # Start NestJS
   cd backend && npm run start:dev

   # Test endpoint directly
   curl "http://localhost:8000/api/check-subscriber.php?email=test@test.com"
   ```

---

## 🔐 Security Considerations

### ✅ Safe:
- PHP endpoint validates email format
- Uses prepared statements (SQL injection safe)
- Only returns active subscribers
- CORS allows only your domains

### ⚠️ Production Checklist:
- [ ] Use HTTPS for PHP API URL in production
- [ ] Restrict CORS to your production domain
- [ ] Add rate limiting to PHP endpoint
- [ ] Monitor for suspicious requests
- [ ] Don't expose sensitive fields (passwords, tokens)

---

## 🚀 Deployment

### Development:
```bash
PHP_API_URL=http://localhost:8000
```

### Production:
```bash
PHP_API_URL=https://szybkafucha.app
```

Make sure the PHP API is accessible from wherever NestJS is hosted:
- Same server: Use localhost or internal IP
- Different servers: Use public HTTPS URL
- Behind firewall: Open necessary ports

---

## 📊 Data Mapping

| MySQL Field | PostgreSQL Field | Notes |
|------------|------------------|-------|
| `name` | `user.name` | Direct copy |
| `email` | `user.email` | Direct copy |
| `user_type` | `user.type` | client/contractor |
| `services` | `user.metadata` | JSON array |
| `city` | `user.metadata` | Optional |
| `comments` | `user.metadata` | Optional feedback |

### What DOESN'T Sync:
- ❌ `subscribed_at` (newsletter-specific)
- ❌ `unsubscribed_at` (newsletter-specific)
- ❌ `is_active` (only check this flag, don't copy)

---

## 🧪 Testing

### Test 1: PHP Endpoint Works
```bash
curl "http://localhost:8000/api/check-subscriber.php?email=test@example.com"
```

Expected: JSON response with success=true

### Test 2: Email Not Found
```bash
curl "http://localhost:8000/api/check-subscriber.php?email=doesnotexist@example.com"
```

Expected: `{ "success": true, "found": false }`

### Test 3: Invalid Email
```bash
curl "http://localhost:8000/api/check-subscriber.php?email=notanemail"
```

Expected: HTTP 400 error

### Test 4: NestJS Integration (After Implementation)
```bash
# Register in app with email that exists in newsletter
# Check NestJS logs for "Newsletter subscriber found" message
# Verify user.name was pre-filled
```

---

## 💡 Benefits of This Approach

### ✅ Pros:
- **Loose coupling:** Systems stay independent
- **No database migration:** Each system keeps its own DB
- **Gradual rollout:** Can implement when ready
- **Fault tolerant:** App works even if PHP API is down
- **Simple:** Just HTTP request, no complex sync logic

### ❌ Alternatives (NOT Recommended):
- **Shared database:** Too complex, mixes technologies
- **Direct DB connection:** Tight coupling, security risk
- **Manual CSV export:** Not scalable, error-prone
- **Real-time sync:** Over-engineering for this use case

---

## 🎯 When to Use

### Use This If:
- ✅ You want newsletter subscribers to have smooth app onboarding
- ✅ You want to pre-fill user data during registration
- ✅ You want to know which app users came from newsletter
- ✅ You want to maintain separate databases

### Don't Use This If:
- ❌ You never plan to build the app (just landing page)
- ❌ You're okay with users entering data twice
- ❌ You want to completely replace PHP with NestJS (different solution needed)

---

## 📞 Next Steps

### Right Now:
- ✅ PHP endpoint is ready to use
- ✅ Test it with curl command above

### When Building Mobile App:
1. Add `PHP_API_URL` to backend/.env
2. Add check method to auth.service.ts
3. Test integration
4. Deploy to production

### Later (Optional):
- Create bulk sync endpoint for admin
- Add Redis caching for frequent checks
- Monitor sync success rate
- Consider migrating everything to NestJS eventually

---

## Questions?

**Q: Do I need to do this now?**
A: No! The PHP endpoint is ready. Implement the NestJS part when you start building the mobile app.

**Q: What if the PHP API is down?**
A: User registration still works, just won't pre-fill data from newsletter.

**Q: Can users from the app subscribe to the newsletter?**
A: Yes, but that's a different flow (app → PHP API subscribe endpoint).

**Q: Should I migrate all newsletter data to PostgreSQL?**
A: Not necessary. Keep newsletter in MySQL. Only sync individual users when they register in app.
