# Postman Setup Guide for Szybka Fucha API

This guide will help you set up Postman to test the Szybka Fucha API.

---

## 📦 Files Included

1. **`szybka-fucha-api.postman_collection.json`** - Complete API collection with all endpoints
2. **`szybka-fucha-local.postman_environment.json`** - Environment variables for local development

---

## 🚀 Quick Setup (5 minutes)

### Step 1: Import Collection

1. Open **Postman**
2. Click **Import** button (top left)
3. Click **Upload Files**
4. Select `szybka-fucha-api.postman_collection.json`
5. Click **Import**

### Step 2: Import Environment

1. Click **Import** again
2. Select `szybka-fucha-local.postman_environment.json`
3. Click **Import**

### Step 3: Select Environment

1. Click the **Environments** dropdown (top right)
2. Select **"Szybka Fucha Local"**

### Step 4: Start Testing!

1. Expand **"Szybka Fucha API"** collection
2. Go to **Auth** folder
3. Run **"Request OTP"** → **"Verify OTP"**
4. JWT token is automatically saved! 🎉

---

## 🔧 Environment Variables

The environment includes these variables:

| Variable | Description | Example |
|----------|-------------|---------|
| `base_url` | API base URL | `http://localhost:3000/api/v1` |
| `jwt_token` | Current JWT token (auto-saved) | `eyJhbGci...` |
| `client_token` | Client user JWT token | `eyJhbGci...` |
| `contractor_token` | Contractor user JWT token | `eyJhbGci...` |
| `task_id` | Last created task ID (auto-saved) | `uuid-here` |
| `user_id` | Current user ID (auto-saved) | `uuid-here` |

---

## 📝 How to Use

### Authentication Flow

1. **Request OTP**
   - Run: `Auth → Request OTP`
   - Body: `{ "phone": "+48123456789" }`
   - Response includes OTP code (mock: `123456`)

2. **Verify OTP**
   - Run: `Auth → Verify OTP`
   - Body: `{ "phone": "+48123456789", "code": "123456", "userType": "client" }`
   - ✅ **JWT token is automatically saved to `jwt_token` variable**

3. **All subsequent requests** use the saved token automatically!

### Complete Task Flow

#### As Client:

1. **Authenticate as Client**
   ```
   Auth → Verify OTP
   Body: { "userType": "client" }
   → Token saved to jwt_token
   ```

2. **Create Task**
   ```
   Tasks → Create Task
   → Task ID automatically saved to task_id variable
   ```

3. **List My Tasks**
   ```
   Tasks → List Tasks (Client)
   ```

#### As Contractor:

1. **Authenticate as Contractor**
   ```
   Auth → Verify OTP
   Body: { "userType": "contractor" }
   → Save token manually to contractor_token if needed
   ```

2. **Setup Profile**
   ```
   Contractor → Update Contractor Profile
   Contractor → Set Availability (isOnline: true)
   Contractor → Update Location
   ```

3. **View Available Tasks**
   ```
   Tasks → List Tasks (Contractor)
   Query params: lat=52.2297&lng=21.0122&categories=paczki
   ```

4. **Accept Task**
   ```
   Tasks → Accept Task
   Replace :id with {{task_id}} or actual task ID
   ```

5. **Start Task**
   ```
   Tasks → Start Task
   ```

6. **Complete Task**
   ```
   Tasks → Complete Task
   Body: { "completionPhotos": ["https://..."] }
   ```

#### Back to Client:

1. **Confirm Task**
   ```
   Tasks → Confirm Task
   (Switch back to client_token in environment)
   ```

2. **Rate Task**
   ```
   Tasks → Rate Task
   Body: { "rating": 5, "comment": "Świetna praca!" }
   ```

---

## 🎯 Tips & Tricks

### Using Multiple Users

To test with both client and contractor:

1. **First Authentication (Client)**
   - Run `Verify OTP` with `userType: "client"`
   - Token saved to `jwt_token`
   - Manually copy to `client_token` in environment

2. **Second Authentication (Contractor)**
   - Run `Verify OTP` with `userType: "contractor"`
   - Token saved to `jwt_token`
   - Manually copy to `contractor_token` in environment

3. **Switch Between Users**
   - Change `jwt_token` value in environment
   - Or use `client_token` / `contractor_token` directly in request headers

### Auto-Save Features

The collection includes test scripts that automatically:
- ✅ Save JWT token after authentication
- ✅ Save task ID after creating a task
- ✅ Save user ID after getting profile

### Using Variables in Requests

Replace hardcoded values with variables:

**Before:**
```
GET /tasks/123e4567-e89b-12d3-a456-426614174000
```

**After:**
```
GET /tasks/{{task_id}}
```

Postman will automatically replace `{{task_id}}` with the actual value from your environment.

---

## 🔍 Troubleshooting

### Token Not Saving

If JWT token isn't being saved automatically:

1. Check **Tests** tab in the request
2. Verify the script is present:
   ```javascript
   if (pm.response.code === 200) {
       const jsonData = pm.response.json();
       if (jsonData.access_token) {
           pm.environment.set("jwt_token", jsonData.access_token);
       }
   }
   ```
3. Make sure environment is selected (top right)

### 401 Unauthorized

- Token might be expired (24h default)
- Re-run `Verify OTP` to get a new token
- Check that `Authorization: Bearer {{jwt_token}}` header is present

### 404 Not Found

- Verify `base_url` is correct: `http://localhost:3000/api/v1`
- Make sure backend is running: `npm run start:dev` in backend folder
- Check Docker containers are running: `docker compose ps`

### Variables Not Working

- Ensure environment is selected (dropdown top right)
- Check variable name matches exactly (case-sensitive)
- Verify variable is enabled in environment

---

## 📚 Collection Structure

```
Szybka Fucha API
├── Auth
│   ├── Request OTP
│   ├── Verify OTP (auto-saves JWT)
│   ├── Google Sign-In
│   └── Apple Sign-In
├── Users
│   ├── Get My Profile (auto-saves user_id)
│   └── Update My Profile
├── Tasks
│   ├── Create Task (auto-saves task_id)
│   ├── List Tasks (Client)
│   ├── List Tasks (Contractor)
│   ├── Get Task Details
│   ├── Accept Task
│   ├── Start Task
│   ├── Complete Task
│   ├── Confirm Task
│   ├── Cancel Task
│   ├── Rate Task
│   └── Add Tip
└── Contractor
    ├── Get Contractor Profile
    ├── Update Contractor Profile
    ├── Set Availability
    ├── Update Location
    ├── Submit KYC ID
    ├── Submit KYC Selfie
    └── Submit KYC Bank
```

---

## 🎓 Example Workflow

### Full End-to-End Test

1. **Setup Client**
   ```
   Auth → Verify OTP (userType: "client")
   Users → Get My Profile
   ```

2. **Create Task**
   ```
   Tasks → Create Task
   {
     "category": "zakupy",
     "title": "Kup produkty",
     "locationLat": 52.2297,
     "locationLng": 21.0122,
     "address": "Warszawa",
     "budgetAmount": 100
   }
   ```

3. **Setup Contractor**
   ```
   Auth → Verify OTP (userType: "contractor")
   Contractor → Update Contractor Profile
   Contractor → Set Availability (isOnline: true)
   Contractor → Update Location
   ```

4. **Contractor Finds Task**
   ```
   Tasks → List Tasks (Contractor)
   Query: ?lat=52.2297&lng=21.0122&categories=zakupy
   ```

5. **Contractor Accepts**
   ```
   Tasks → Accept Task
   (Use task_id from step 2)
   ```

6. **Contractor Completes**
   ```
   Tasks → Start Task
   Tasks → Complete Task
   ```

7. **Client Confirms**
   ```
   (Switch to client_token)
   Tasks → Confirm Task
   Tasks → Rate Task
   ```

---

## 📞 Need Help?

- Check `api-summary.md` for detailed endpoint documentation
- Verify backend is running: `http://localhost:3000/api/v1`
- Check Docker: `docker compose ps`
- View backend logs for error details

---

**Happy Testing! 🚀**
