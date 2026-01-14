# Admin Panel API Integration Guide

## Overview

This document describes the API integration between the Admin Panel (React) and the Backend (NestJS).

## Changes Made

### 1. New API Service (`admin/src/services/api.ts`)

Created a centralized API service that provides:
- **Base URL Configuration**: Uses `REACT_APP_API_URL` environment variable
- **Auth Token Handling**: Automatically includes JWT token from localStorage
- **Type-safe API Functions**: Typed interfaces for Tasks and Disputes

### 2. Updated Pages

#### Tasks Page (`admin/src/pages/Tasks.tsx`)
- Removed hardcoded `MOCK_TASKS` array
- Connected to `GET /admin/tasks` endpoint
- Added status filter dropdown (native HTML select for Chakra v3 compatibility)
- Shows loading spinner and error states
- Calculates stats from real data

#### Disputes Page (`admin/src/pages/Disputes.tsx`)
- Removed hardcoded `MOCK_DISPUTES` array
- Connected to `GET /admin/disputes` endpoint
- Added dispute resolution modal using `@ark-ui/react` Dialog (Chakra UI v3 compatible)
- Three resolution options:
  - Pay contractor
  - Refund client
  - Split 50/50
- Connected to `PUT /admin/disputes/:id/resolve` endpoint

### 3. Environment Configuration

Created `.env` and `.env.example` files for API URL configuration:
```bash
REACT_APP_API_URL=http://localhost:3000/api/v1
```

### 4. Chakra UI v3 Compatibility

The admin panel uses Chakra UI v3, which has a different API than v2:
- **Modal**: Replaced with `@ark-ui/react` Dialog component
- **Select**: Replaced with native HTML `<select>` element
- **Button loading**: Uses `loading` prop instead of `isLoading`
- **useDisclosure**: Uses `open` instead of `isOpen` (replaced with React useState)

## API Endpoints Used

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/admin/tasks` | GET | List all tasks with filters |
| `/admin/disputes` | GET | List disputed tasks |
| `/admin/disputes/:id/resolve` | PUT | Resolve a dispute |

## Running Locally

### Prerequisites
1. Backend must be running on `localhost:3000`
2. Database must be seeded with test data
3. Admin user must be logged in

### Start Commands
```bash
# Terminal 1: Start backend
cd backend
docker-compose up -d postgres redis
npm run start:dev

# Terminal 2: Start admin panel
cd admin
npm start
```

### Authentication
The admin panel uses mock authentication. Use these credentials:
- **Email**: admin@szybkafucha.pl
- **Password**: admin123

**Note**: For the Tasks and Disputes pages to work, you need a real JWT token from the backend. The mock auth token won't work with the backend API.

## Real Authentication Setup

To fully connect the admin panel to the backend:

1. Update Login.tsx to call `POST /auth/phone/request-otp` and `POST /auth/phone/verify`
2. Store the real JWT token in localStorage
3. Ensure the logged-in user has admin privileges (UserType.ADMIN)

## API Response Formats

### Tasks Response
```typescript
interface PaginatedResponse<Task> {
  data: Task[];
  total: number;
  page: number;
  limit: number;
  totalPages: number;
}

interface Task {
  id: string;
  title: string;
  description: string;
  category: string;
  status: 'created' | 'accepted' | 'in_progress' | 'completed' | 'cancelled' | 'disputed';
  budgetAmount: number;
  finalAmount: number | null;
  clientId: string;
  contractorId: string | null;
  client?: { id: string; name: string; email: string };
  contractor?: { id: string; name: string; email: string } | null;
  address: string;
  createdAt: string;
}
```

### Dispute Resolution
```typescript
type DisputeResolution = 'refund' | 'pay_contractor' | 'split';

// PUT /admin/disputes/:id/resolve
{
  resolution: DisputeResolution;
  notes: string;
}
```

## Troubleshooting

### "Error loading data" message
- Ensure backend is running (`npm run start:dev` in backend/)
- Check browser console for CORS errors
- Verify `.env` file has correct `REACT_APP_API_URL`

### 401 Unauthorized errors
- The mock auth token doesn't work with the backend
- Need to implement real authentication or create an admin user in the database

### Empty task/dispute lists
- Run database seeds: `cd backend && npm run seed`
- Check that seeded data includes tasks with various statuses

## Files Changed

```
admin/
├── src/
│   ├── services/
│   │   └── api.ts           # NEW: Centralized API service
│   └── pages/
│       ├── Tasks.tsx        # UPDATED: Connected to backend API
│       └── Disputes.tsx     # UPDATED: Connected to backend API
├── .env                     # NEW: Environment configuration
└── .env.example             # NEW: Environment template
```

## Next Steps

1. **Implement Real Auth**: Replace mock login with actual backend authentication
2. **Add Users API**: Connect Users.tsx to `/admin/users` endpoint
3. **Add Dashboard API**: Connect Dashboard.tsx to `/admin/dashboard` endpoint
4. **Add Error Boundaries**: Better error handling for API failures
5. **Add React Query**: Use TanStack Query for caching and state management
