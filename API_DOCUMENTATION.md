# API Documentation - Credit Package System

## Base URL

```
Production: https://review-analysis-server.trynewways.com
Local: http://localhost:8000
```

---

## Credit Calculation Rules

### Formula
```
credits_required = CEILING(total_reviews / 100)
```

### Credit Usage by Review Count

| Reviews | Credits Required | Cost (Bronze @ $5/credit) |
|---------|------------------|---------------------------|
| 1-100   | 1 credit         | $5.00                     |
| 101-200 | 2 credits        | $10.00                    |
| 201-300 | 3 credits        | $15.00                    |
| 500     | 5 credits        | $25.00                    |
| 1000    | 10 credits       | $50.00                    |

### Key Points
- **1 credit = up to 100 reviews analyzed**
- Credits scale linearly with review count
- Each full or partial block of 100 reviews = 1 credit
- The `max_reviews` parameter determines credit cost

---

## Response Structure

All API responses follow this structure:

```json
{
  "ok": true,
  "type": "response",
  "data": {
    "result": { ... },
    "reports": [ { ... } ]  // <-- EXTRACT THIS
  },
  "error": null,
  "meta": { ... }
}
```

### Frontend Extraction

**IMPORTANT:** Always extract `data.reports[0]` for the actual response data.

```typescript
// TypeScript/JavaScript example
const response = await fetch(url, options);
const json = await response.json();

// Extract the actual data
const result = json.data.reports[0];

// Now use result.success, result.data, result.error, etc.
if (result.success) {
  console.log(result.data);
} else {
  console.error(result.error);
}
```

---

## Authentication

All endpoints (except `get_credit_packages`) require JWT authentication.

```
Authorization: Bearer <jwt_token>
```

### Get Token (Registration/Login)

```http
POST /user/register
Content-Type: application/json

{
  "username": "string",
  "password": "string"
}
```

**Response:**
```json
{
  "ok": true,
  "data": {
    "username": "farhan",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "root_id": "7431d5d81bf64ce4839cb92ccef1b84c"
  }
}
```

---

## API Endpoints

### 1. Create Profile

Creates a user profile after registration. Must be called once after first registration.

```http
POST /walker/create_profile
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:** None required

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "credits": 0,
  "message": "Profile created. Purchase a credit package to start analyzing."
}
```

**Error Response (profile already exists):**
```json
{
  "success": false,
  "error": "User profile already exists"
}
```

---

### 2. Get Credit Balance

Returns current credit balance and usage statistics.

```http
POST /walker/get_credit_balance
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:** None required

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "data": {
    "credits": {
      "available": 11,
      "used": 1
    },
    "note": "1 credit = up to 100 reviews. Formula: ceil(reviews / 100)"
  },
  "timestamp": "2026-01-25 21:33:29.120238"
}
```

**TypeScript Interface:**
```typescript
interface CreditBalance {
  success: true;
  data: {
    credits: {
      available: number;
      used: number;
    };
    note: string;
  };
  timestamp: string;
}
```

---

### 3. Get Credit Packages

Returns available credit packages for purchase. No authentication required.

```http
POST /walker/get_credit_packages
Content-Type: application/json
```

**Request Body:** None required

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "data": {
    "packages": [
      {
        "id": "bronze",
        "name": "Bronze",
        "credits": 1,
        "price": 5.0,
        "currency": "USD",
        "price_per_credit": 5.0
      },
      {
        "id": "silver",
        "name": "Silver",
        "credits": 5,
        "price": 22.0,
        "currency": "USD",
        "price_per_credit": 4.4
      },
      {
        "id": "gold",
        "name": "Gold",
        "credits": 12,
        "price": 48.0,
        "currency": "USD",
        "price_per_credit": 4.0
      },
      {
        "id": "platinum",
        "name": "Platinum",
        "credits": 30,
        "price": 110.0,
        "currency": "USD",
        "price_per_credit": 3.67
      }
    ],
    "note": "1 credit = up to 100 reviews. Formula: ceil(reviews / 100)"
  },
  "timestamp": "2026-01-25 21:32:45.756442"
}
```

**TypeScript Interface:**
```typescript
interface CreditPackage {
  id: "bronze" | "silver" | "gold" | "platinum";
  name: string;
  credits: number;
  price: number;
  currency: string;
  price_per_credit: number;
}

interface GetPackagesResponse {
  success: true;
  data: {
    packages: CreditPackage[];
    note: string;
  };
  timestamp: string;
}
```

---

### 4. Purchase Credit Package

Processes payment and adds credits to user account.

```http
POST /walker/purchase_credit_package
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "package": "gold",
  "payment_method": {
    "card_number": "4242424242424242",
    "exp_month": 12,
    "exp_year": 2026,
    "cvc": "123"
  }
}
```

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "data": {
    "purchase": {
      "package": "gold",
      "package_name": "Gold",
      "credits_added": 12,
      "price": 48.0,
      "currency": "USD"
    },
    "balance": {
      "credits": 12
    },
    "transaction_id": "7bc2d7af-4e0f-4a5c-96a8-f27dccc57612"
  },
  "timestamp": "2026-01-25 21:04:07.950522",
  "metadata": {
    "message": "Successfully purchased Gold package! 12 credits added."
  }
}
```

**Error Responses (`data.reports[0]`):**

Invalid package:
```json
{
  "success": false,
  "error": {
    "code": "INVALID_PACKAGE",
    "message": "Invalid package: diamond",
    "details": {
      "valid_packages": ["bronze", "silver", "gold", "platinum"]
    }
  }
}
```

Card declined:
```json
{
  "success": false,
  "error": {
    "code": "CARD_DECLINED",
    "message": "Card declined",
    "details": {
      "decline_code": "generic_decline"
    }
  }
}
```

Insufficient funds:
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Insufficient funds",
    "details": {
      "decline_code": "insufficient_funds"
    }
  }
}
```

**TypeScript Interface:**
```typescript
interface PurchaseRequest {
  package: "bronze" | "silver" | "gold" | "platinum";
  payment_method: {
    card_number: string;
    exp_month: number;
    exp_year: number;
    cvc: string;
  };
}

interface PurchaseSuccessResponse {
  success: true;
  data: {
    purchase: {
      package: string;
      package_name: string;
      credits_added: number;
      price: number;
      currency: string;
    };
    balance: {
      credits: number;
    };
    transaction_id: string;
  };
  timestamp: string;
  metadata: {
    message: string;
  };
}
```

---

### 5. Analyze URL

Runs analysis on a Google Maps business URL. **Credit cost = ceil(max_reviews / 100)**.

```http
POST /walker/AnalyzeUrl
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "url": "https://www.google.com/maps/place/...",
  "max_reviews": 100,
  "analysis_depth": "deep",
  "force_refresh": false,
  "freshness_days": 7
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| url | string | required | Google Maps place URL |
| max_reviews | int | 100 | Max reviews to analyze (20/50/100/200) |
| analysis_depth | string | "deep" | "basic", "standard", or "deep" |
| force_refresh | bool | false | Force re-fetch even if cached |
| freshness_days | int | 7 | Cache validity in days |

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "business": {
    "name": "The Kingsbury Colombo",
    "place_id": "ChIJ...",
    "business_type": "HOTEL"
  },
  "health_score": {
    "overall": 82,
    "grade": "B+",
    "breakdown": { ... }
  },
  "themes": [ ... ],
  "executive_summary": { ... },
  "recommendations": { ... },
  "credits": {
    "used": 1,
    "remaining": 11,
    "calculation": "100 reviews = 1 credit(s)"
  },
  "cache_info": {
    "from_cache": false,
    "message": "Fresh data fetched from API"
  }
}
```

**Insufficient Credits Error (`data.reports[0]`):**
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_CREDITS",
    "message": "Insufficient credits: need 1, have 0",
    "timestamp": "2026-01-25 21:03:36.277739",
    "details": {
      "required": 1,
      "available": 0,
      "shortage": 1,
      "action": "Purchase a credit package to continue"
    }
  }
}
```

**TypeScript Interface:**
```typescript
interface AnalyzeRequest {
  url: string;
  max_reviews?: number;
  analysis_depth?: "basic" | "standard" | "deep";
  force_refresh?: boolean;
  freshness_days?: number;
}

interface AnalyzeSuccessResponse {
  success: true;
  business: { ... };
  health_score: { ... };
  themes: Array<{ ... }>;
  credits: {
    used: number;
    remaining: number;
    calculation: string;  // e.g., "100 reviews = 1 credit(s)"
  };
  cache_info: {
    from_cache: boolean;
    message: string;
  };
}

interface InsufficientCreditsError {
  success: false;
  error: {
    code: "INSUFFICIENT_CREDITS";
    message: string;
    timestamp: string;
    details: {
      required: number;
      available: number;
      shortage: number;
      action: string;
    };
  };
}
```

---

### 6. Get Payment History

Returns purchase history for the authenticated user.

```http
POST /walker/get_payment_history
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "limit": 20,
  "offset": 0
}
```

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "data": {
    "purchases": [
      {
        "transaction_id": "7bc2d7af-4e0f-4a5c-96a8-f27dccc57612",
        "package": "gold",
        "credits": 12,
        "description": "Purchased Gold package (12 credits) for $48.0",
        "date": "2026-01-25 21:04:07.950335"
      }
    ],
    "pagination": {
      "total": 1,
      "limit": 20,
      "offset": 0,
      "has_more": false
    }
  },
  "timestamp": "2026-01-25 21:31:31.710612"
}
```

**TypeScript Interface:**
```typescript
interface PaymentHistoryRequest {
  limit?: number;
  offset?: number;
}

interface Purchase {
  transaction_id: string;
  package: string;
  credits: number;
  description: string;
  date: string;
}

interface PaymentHistoryResponse {
  success: true;
  data: {
    purchases: Purchase[];
    pagination: {
      total: number;
      limit: number;
      offset: number;
      has_more: boolean;
    };
  };
  timestamp: string;
}
```

---

### 7. Get Credit History

Returns all credit transactions (purchases, usage, grants, refunds).

```http
POST /walker/get_credit_history
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "limit": 20,
  "offset": 0,
  "transaction_type": ""
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| limit | int | 20 | Max records to return |
| offset | int | 0 | Pagination offset |
| transaction_type | string | "" | Filter: "purchase", "usage", "grant", "refund" (empty = all) |

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "data": {
    "transactions": [
      {
        "transaction_id": "7bc2d7af-4e0f-4a5c-96a8-f27dccc57612",
        "type": "purchase",
        "amount": 12,
        "balance_after": 12,
        "package": "gold",
        "description": "Purchased Gold package (12 credits) for $48.0",
        "date": "2026-01-25 21:04:07.950335"
      }
    ],
    "pagination": {
      "total": 1,
      "limit": 20,
      "offset": 0,
      "has_more": false
    }
  },
  "timestamp": "2026-01-25 21:31:56.700865"
}
```

**TypeScript Interface:**
```typescript
interface CreditHistoryRequest {
  limit?: number;
  offset?: number;
  transaction_type?: "purchase" | "usage" | "grant" | "refund" | "";
}

interface CreditTransaction {
  transaction_id: string;
  type: "purchase" | "usage" | "grant" | "refund";
  amount: number;
  balance_after: number;
  package: string | null;
  description: string;
  date: string;
}

interface CreditHistoryResponse {
  success: true;
  data: {
    transactions: CreditTransaction[];
    pagination: {
      total: number;
      limit: number;
      offset: number;
      has_more: boolean;
    };
  };
  timestamp: string;
}
```

---

### 8. Get User Profile

Returns user profile information.

```http
POST /walker/get_user_profile
Authorization: Bearer <token>
Content-Type: application/json
```

**Request Body:** None required

**Success Response (`data.reports[0]`):**
```json
{
  "success": true,
  "role": "user",
  "credits": {
    "available": 11,
    "used": 1
  },
  "businesses_count": 1,
  "is_active": true
}
```

**TypeScript Interface:**
```typescript
interface UserProfile {
  success: true;
  role: "user" | "admin";
  credits: {
    available: number;
    used: number;
  };
  businesses_count: number;
  is_active: boolean;
}
```

---

## Error Codes Reference

| Code | Description |
|------|-------------|
| `INSUFFICIENT_CREDITS` | User doesn't have enough credits |
| `INVALID_PACKAGE` | Invalid package ID provided |
| `CARD_DECLINED` | Payment card was declined |
| `INSUFFICIENT_FUNDS` | Card has insufficient funds |
| `VALIDATION_ERROR` | Invalid input data |
| `NOT_FOUND` | Resource not found |
| `UNAUTHORIZED` | Authentication failed or account inactive |
| `INTERNAL_ERROR` | Server error |

---

## Test Cards (Development)

| Card Number | Result |
|-------------|--------|
| `4242424242424242` | Success |
| `4000000000000002` | Card declined |
| `4000000000009995` | Insufficient funds |

---

## Frontend API Service Example

```typescript
// api.ts
const BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000';

interface ApiResponse<T> {
  ok: boolean;
  type: string;
  data: {
    result: any;
    reports: T[];
  };
  error: any;
  meta: any;
}

async function apiCall<T>(
  endpoint: string,
  body?: object,
  token?: string
): Promise<T> {
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(`${BASE_URL}${endpoint}`, {
    method: 'POST',
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const json: ApiResponse<T> = await response.json();

  // Extract the actual response from reports[0]
  if (json.ok && json.data.reports.length > 0) {
    return json.data.reports[0];
  }

  throw new Error(json.error || 'API request failed');
}

// Usage examples
export const api = {
  createProfile: (token: string) =>
    apiCall<{ success: boolean; credits: number; message: string }>(
      '/walker/create_profile',
      undefined,
      token
    ),

  getCreditBalance: (token: string) =>
    apiCall<CreditBalance>('/walker/get_credit_balance', undefined, token),

  getPackages: () =>
    apiCall<GetPackagesResponse>('/walker/get_credit_packages'),

  purchasePackage: (token: string, request: PurchaseRequest) =>
    apiCall<PurchaseSuccessResponse>(
      '/walker/purchase_credit_package',
      request,
      token
    ),

  analyzeUrl: (token: string, request: AnalyzeRequest) =>
    apiCall<AnalyzeSuccessResponse>('/walker/AnalyzeUrl', request, token),

  getPaymentHistory: (token: string, limit = 20, offset = 0) =>
    apiCall<PaymentHistoryResponse>(
      '/walker/get_payment_history',
      { limit, offset },
      token
    ),

  getCreditHistory: (token: string, limit = 20, offset = 0, type = '') =>
    apiCall<CreditHistoryResponse>(
      '/walker/get_credit_history',
      { limit, offset, transaction_type: type },
      token
    ),

  getUserProfile: (token: string) =>
    apiCall<UserProfile>('/walker/get_user_profile', undefined, token),
};
```

---

## Quick Reference

| Action | Endpoint | Auth Required |
|--------|----------|---------------|
| Create profile | `POST /walker/create_profile` | Yes |
| Get balance | `POST /walker/get_credit_balance` | Yes |
| Get packages | `POST /walker/get_credit_packages` | No |
| Purchase package | `POST /walker/purchase_credit_package` | Yes |
| Analyze URL | `POST /walker/AnalyzeUrl` | Yes |
| Payment history | `POST /walker/get_payment_history` | Yes |
| Credit history | `POST /walker/get_credit_history` | Yes |
| User profile | `POST /walker/get_user_profile` | Yes |
