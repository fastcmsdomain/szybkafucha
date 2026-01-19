# How to Change Admin Login Credentials

## 📍 Location

The admin login credentials are stored in:
```
admin/src/config/auth.config.ts
```

## 🔐 How to Change

### Step 1: Open the Config File

Open `admin/src/config/auth.config.ts` in your editor.

### Step 2: Update Credentials

Change the `adminEmail` and `adminPassword` values:

```typescript
export const authConfig = {
  // Change this to your desired email
  adminEmail: 'your-email@example.com',
  
  // Change this to your desired password
  adminPassword: 'YourSecurePassword123!',
  
  // ... rest of config
};
```

### Step 3: Rebuild the Admin Panel

After changing credentials, rebuild the admin panel:

```bash
cd admin
npm run build
```

### Step 4: Deploy

Upload the new `admin/build/` files to your server.

---

## ⚠️ Security Notes

**Current Implementation:**
- Credentials are hardcoded in the frontend code
- This is **NOT secure** for production use
- Anyone with access to the built JavaScript can see the credentials

**Recommended for Production:**
1. **Use Backend Authentication:**
   - Create a login API endpoint in your backend
   - Store credentials securely in the database (hashed)
   - Use JWT tokens with expiration
   - Implement proper session management

2. **Environment Variables:**
   - Move credentials to environment variables
   - Use `.env` files (but don't commit them!)
   - Access via `process.env.REACT_APP_ADMIN_EMAIL`

3. **Two-Factor Authentication:**
   - Add 2FA for additional security
   - Use SMS or authenticator apps

---

## 🔄 Quick Change Example

**Current credentials:**
- Email: `admin@szybkafucha.pl`
- Password: `Redjansz280307!!`

**To change to:**
- Email: `newadmin@example.com`
- Password: `NewSecurePass456!`

**Edit `admin/src/config/auth.config.ts`:**
```typescript
export const authConfig = {
  adminEmail: 'newadmin@example.com',
  adminPassword: 'NewSecurePass456!',
  // ...
};
```

Then rebuild and deploy.

---

## 📝 After Changing

1. Test login with new credentials
2. Remove old credentials from git history (if committed)
3. Update any documentation with old credentials
4. Consider implementing proper backend auth

---

**File Location:** `admin/src/config/auth.config.ts`
