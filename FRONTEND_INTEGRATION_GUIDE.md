# Frontend Integration Guide

Complete guide for integrating the Review Analyzer API with your frontend application.

---

## Breaking Changes (v2.0)

### Renamed Endpoints

| Old Endpoint | New Endpoint | Notes |
|--------------|--------------|-------|
| `/walker/create_user_profile` | `/walker/create_profile` | Now accepts `tier_requested` parameter |
| `/walker/create_user_profile_with_plan` | `/walker/create_profile` | Merged into single endpoint |
| `/walker/process_payment_dummy` | `/walker/process_payment` | Renamed for production |

### Removed Endpoints

| Endpoint | Reason |
|----------|--------|
| `/walker/generate_session_token` | JWT handles sessions |
| `/walker/validate_session_token` | JWT handles validation |
| `/walker/revoke_session_token` | Use logout flow |
| `/walker/start_onboarding` | Removed - not needed |
| `/walker/complete_onboarding_step` | Removed - not needed |
| `/walker/skip_onboarding` | Removed - not needed |
| `/walker/diagnose_profile` | Removed - debugging only |
| `/walker/delete_profile` | Removed - debugging only |

### Response Format Changes

All responses now use consistent format:
```typescript
// Old format (inconsistent)
{ status: "found", ... }
{ status: "created", ... }

// New format (consistent)
{ success: true, ... }
{ success: false, error: "..." }
```

---

## API Endpoints Overview

### Authentication (2 endpoints)
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/user/register` | POST | No | Register new user |
| `/user/login` | POST | No | Login existing user |

### Profile & Subscription (6 endpoints)
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/walker/create_profile` | POST | Yes | Create profile with tier selection |
| `/walker/get_user_profile` | POST | Yes | Get profile and limits |
| `/walker/initiate_payment` | POST | Yes | Start payment process |
| `/walker/process_payment` | POST | Yes | Complete payment |
| `/walker/get_subscription_details` | POST | Yes | Get full subscription info |
| `/walker/schedule_downgrade` | POST | Yes | Schedule tier downgrade |
| `/walker/cancel_subscription` | POST | Yes | Cancel subscription |

### Analysis (4 endpoints)
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/walker/AnalyzeUrl` | POST | Yes | Analyze Google Maps URL |
| `/walker/Reanalyze` | POST | Yes | Re-run analysis |
| `/walker/GetReport` | POST | Yes | Get full report |
| `/walker/GetReviews` | POST | Yes | Get reviews with filters |

### Business Management (3 endpoints)
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/walker/GetBusinesses` | POST | Yes | List all businesses |
| `/walker/DeleteBusiness` | POST | Yes | Delete business |
| `/walker/GetStats` | POST | Yes | Get user statistics |

### Admin (2 endpoints)
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/walker/create_admin` | POST | Yes | Setup admin account |
| `/walker/update_subscription` | POST | Yes | Update user tier (admin) |

### Health (2 endpoints)
| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/walker/health_check` | POST | No | Health check |
| `/walker/ready` | POST | No | Readiness probe |

---

## User Flow Diagrams

### Simple Registration Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        REGISTRATION FLOW                             │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────┐
                    │  User visits │
                    │  /register   │
                    └──────┬───────┘
                           │
                           ▼
                ┌──────────────────────┐
                │  POST /user/register │
                │  {username, password}│
                └──────────┬───────────┘
                           │
                           ▼
                    ┌──────────────┐
                    │ Store token  │
                    │ in localStorage│
                    └──────┬───────┘
                           │
                           ▼
              ┌────────────────────────────┐
              │ Select subscription tier   │
              │ [FREE] [PRO] [ENTERPRISE]  │
              └────────────┬───────────────┘
                           │
           ┌───────────────┼───────────────┐
           │               │               │
           ▼               ▼               ▼
       ┌───────┐       ┌───────┐       ┌───────┐
       │ FREE  │       │  PRO  │       │ENTERPR│
       └───┬───┘       └───┬───┘       └───┬───┘
           │               │               │
           ▼               ▼               ▼
    ┌─────────────┐  ┌─────────────┐  ┌─────────────┐
    │create_profile│  │create_profile│  │create_profile│
    │tier: "free" │  │tier: "pro"  │  │tier: "enterp│
    └─────┬───────┘  └─────┬───────┘  └──────┬──────┘
          │                │                  │
          ▼                ▼                  ▼
    ┌───────────┐    ┌───────────┐     ┌───────────┐
    │  ACTIVE   │    │ PENDING   │     │ PENDING   │
    │  FREE     │    │ PAYMENT   │     │ PAYMENT   │
    └─────┬─────┘    └─────┬─────┘     └─────┬─────┘
          │                │                  │
          │                └────────┬─────────┘
          │                         │
          │                         ▼
          │               ┌─────────────────┐
          │               │ Payment Flow    │
          │               │ (see below)     │
          │               └────────┬────────┘
          │                        │
          └────────────┬───────────┘
                       │
                       ▼
              ┌─────────────────┐
              │    DASHBOARD    │
              │  Ready to use!  │
              └─────────────────┘
```

### Payment Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PAYMENT FLOW                                 │
└─────────────────────────────────────────────────────────────────────┘

       ┌─────────────────────────────┐
       │  User has pending_payment   │
       │  status after create_profile│
       └─────────────┬───────────────┘
                     │
                     ▼
       ┌─────────────────────────────┐
       │  Show Payment Form          │
       │  - Card number              │
       │  - Expiry date              │
       │  - CVC                      │
       │  - Billing interval toggle  │
       └─────────────┬───────────────┘
                     │
                     ▼
       ┌─────────────────────────────┐
       │  POST /walker/initiate_payment│
       │  {                          │
       │    tier: "pro",             │
       │    billing_interval: "monthly"│
       │  }                          │
       └─────────────┬───────────────┘
                     │
                     ▼
       ┌─────────────────────────────┐
       │  Response:                  │
       │  {                          │
       │    payment_id: "uuid...",   │
       │    amount: 29,              │
       │    client_secret: "..."     │
       │  }                          │
       └─────────────┬───────────────┘
                     │
                     ▼
       ┌─────────────────────────────┐
       │  POST /walker/process_payment │
       │  {                          │
       │    payment_id: "uuid...",   │
       │    payment_method: {        │
       │      card_number: "4242..", │
       │      exp_month: 12,         │
       │      exp_year: 2025,        │
       │      cvc: "123"             │
       │    }                        │
       │  }                          │
       └─────────────┬───────────────┘
                     │
         ┌───────────┴───────────┐
         │                       │
         ▼                       ▼
   ┌───────────┐           ┌───────────┐
   │  SUCCESS  │           │  FAILED   │
   │  {        │           │  {        │
   │   success:│           │   success:│
   │   true,   │           │   false,  │
   │   tier:   │           │   error:  │
   │   "pro"   │           │   "Card   │
   │  }        │           │   declined│
   └─────┬─────┘           └─────┬─────┘
         │                       │
         ▼                       ▼
   ┌───────────┐           ┌───────────┐
   │ Redirect  │           │ Show Error│
   │ Dashboard │           │ Retry     │
   └───────────┘           └───────────┘
```

### Subscription Management Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                   SUBSCRIPTION MANAGEMENT                            │
└─────────────────────────────────────────────────────────────────────┘

                    ┌──────────────────┐
                    │  Settings Page   │
                    │  /settings/billing│
                    └────────┬─────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │ GET /walker/get_subscription_details│
              └──────────────┬───────────────┘
                             │
                             ▼
              ┌──────────────────────────────┐
              │  Display:                    │
              │  - Current tier: PRO         │
              │  - Price: $29/month          │
              │  - Next billing: Feb 24      │
              │  - Days until renewal: 29    │
              └──────────────┬───────────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
   ┌───────────┐       ┌───────────┐       ┌───────────┐
   │  UPGRADE  │       │ DOWNGRADE │       │  CANCEL   │
   └─────┬─────┘       └─────┬─────┘       └─────┬─────┘
         │                   │                   │
         ▼                   ▼                   ▼
   ┌───────────┐       ┌───────────┐       ┌───────────┐
   │initiate_  │       │schedule_  │       │cancel_    │
   │payment    │       │downgrade  │       │subscription│
   │tier:      │       │target_tier│       │immediate: │
   │"enterprise│       │: "free"   │       │true/false │
   └───────────┘       └───────────┘       └───────────┘
```

---

## TypeScript Types

Add these types to your `types/index.ts` or `types/api.ts`:

```typescript
// ═══════════════════════════════════════════════════════════════════
// AUTHENTICATION TYPES
// ═══════════════════════════════════════════════════════════════════

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  password: string;
}

export interface AuthResponse {
  username: string;
  token: string;
  root_id: string;
}

// ═══════════════════════════════════════════════════════════════════
// PROFILE TYPES
// ═══════════════════════════════════════════════════════════════════

export type SubscriptionTier = "free" | "pro" | "enterprise";
export type SubscriptionStatus = "active" | "pending_payment" | "cancelled";
export type BillingInterval = "monthly" | "annual";

export interface CreateProfileRequest {
  tier_requested: SubscriptionTier;
}

export interface CreateProfileResponse {
  success: boolean;
  tier: SubscriptionTier;
  subscription_status: SubscriptionStatus;
  pending_upgrade?: SubscriptionTier;
  next_step?: string;
  limits: {
    max_businesses: number;
    daily_analyses: number;
  };
}

export interface UserProfile {
  success: boolean;
  role: "user" | "admin";
  subscription: {
    tier: SubscriptionTier;
    status: SubscriptionStatus;
    pending_upgrade: string;
  };
  limits: {
    max_businesses: number;
    current_businesses: number;
    remaining_businesses: number;
    daily_analysis_limit: number;
    analyses_today: number;
    remaining_today: number;
  };
  is_active: boolean;
}

// ═══════════════════════════════════════════════════════════════════
// PAYMENT TYPES
// ═══════════════════════════════════════════════════════════════════

export interface InitiatePaymentRequest {
  tier: "pro" | "enterprise";
  billing_interval: BillingInterval;
  upgrade_from?: string;
}

export interface InitiatePaymentResponse {
  payment_id: string;
  amount: number;
  currency: string;
  tier: string;
  billing_interval: BillingInterval;
  proration_credit: number;
  status: string;
  client_secret: string;
  message: string;
}

export interface PaymentMethod {
  card_number: string;
  exp_month: number;
  exp_year: number;
  cvc: string;
}

export interface ProcessPaymentRequest {
  payment_id: string;
  payment_method: PaymentMethod;
}

export interface ProcessPaymentResponse {
  success: boolean;
  payment_id: string;
  status: string;
  subscription: {
    tier: SubscriptionTier;
    status: string;
    billing_interval: BillingInterval;
    start_date: string;
    end_date: string;
    next_billing_date: string;
    limits: {
      max_businesses: number;
      daily_analyses: number;
    };
  };
  transaction_id: string;
  message: string;
}

export interface PaymentError {
  success: false;
  error: string;
  payment_id: string;
  decline_code?: string;
}

// ═══════════════════════════════════════════════════════════════════
// SUBSCRIPTION TYPES
// ═══════════════════════════════════════════════════════════════════

export interface SubscriptionDetails {
  subscription: {
    tier: SubscriptionTier;
    status: SubscriptionStatus;
    price: number;
    currency: string;
    billing_interval: BillingInterval;
    annual_savings: number;
    start_date: string;
    end_date: string;
    next_billing_date: string;
    days_until_renewal: number;
    pending_upgrade: string;
    pending_downgrade: string;
  };
  limits: {
    max_businesses: number;
    current_businesses: number;
    remaining_businesses: number;
    daily_analysis_limit: number;
    analyses_today: number;
    remaining_today: number;
  };
  can_upgrade: boolean;
  can_downgrade: boolean;
}

export interface ScheduleDowngradeRequest {
  target_tier: SubscriptionTier;
}

export interface ScheduleDowngradeResponse {
  downgrade_scheduled: boolean;
  current_tier: SubscriptionTier;
  target_tier: SubscriptionTier;
  effective_date: string;
  days_until_downgrade: number;
  message: string;
}

export interface CancelSubscriptionRequest {
  immediate: boolean;
}

export interface CancelSubscriptionResponse {
  cancelled: boolean;
  immediate: boolean;
  current_tier?: SubscriptionTier;
  new_tier?: SubscriptionTier;
  access_until?: string;
  message: string;
  transaction_id: string;
}

// ═══════════════════════════════════════════════════════════════════
// ANALYSIS TYPES (existing - no changes)
// ═══════════════════════════════════════════════════════════════════

export interface AnalyzeUrlRequest {
  url: string;
  max_reviews?: number;
  analysis_depth?: "quick" | "standard" | "deep";
  freshness_days?: number;
  force_refresh?: boolean;
}

export interface ReanalyzeRequest {
  business_id: string;
  report_type?: "quick" | "deep";
  force_sentiment?: boolean;
}

export interface GetReviewsRequest {
  business_id: string;
  limit?: number;
  sentiment_filter?: "positive" | "negative" | "neutral" | "mixed" | "";
  min_rating?: number;
  max_rating?: number;
  sort_by?: "date" | "rating" | "sentiment_score";
}

// ... (FullReport, BusinessListResponse, ReviewsResponse types remain unchanged)
```

---

## Updated API Service

Replace your `services/api.ts` with this updated version:

```typescript
import type {
  LoginRequest,
  RegisterRequest,
  AuthResponse,
  CreateProfileRequest,
  CreateProfileResponse,
  UserProfile,
  InitiatePaymentRequest,
  InitiatePaymentResponse,
  ProcessPaymentRequest,
  ProcessPaymentResponse,
  SubscriptionDetails,
  ScheduleDowngradeRequest,
  ScheduleDowngradeResponse,
  CancelSubscriptionRequest,
  CancelSubscriptionResponse,
  AnalyzeUrlRequest,
  ReanalyzeRequest,
  FullReport,
  BusinessListResponse,
  GetReviewsRequest,
  ReviewsResponse,
  UpdateSubscriptionRequest,
  HealthCheckResponse,
} from "@/types";

const API_BASE_URL = "https://review-analysis-server.trynewways.com";

// ═══════════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════════

const getToken = (): string | null => {
  if (typeof window === "undefined") return null;
  try {
    const authStorage = localStorage.getItem("auth-storage");
    if (authStorage) {
      const parsed = JSON.parse(authStorage);
      return parsed.state?.token || null;
    }
  } catch {
    return null;
  }
  return null;
};

async function apiRequest<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const token = getToken();

  const headers: HeadersInit = {
    "Content-Type": "application/json",
    ...options.headers,
  };

  if (token) {
    (headers as Record<string, string>)["Authorization"] = `Bearer ${token}`;
  }

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    ...options,
    headers,
  });

  if (response.status === 401) {
    if (typeof window !== "undefined") {
      localStorage.removeItem("auth-storage");
      window.location.href = "/login";
    }
    throw new Error("Unauthorized");
  }

  const data = await response.json();

  if (!response.ok) {
    throw new Error(data.error || data.message || "An error occurred");
  }

  return data;
}

// Walker request helper - extracts reports[0] from JAC response
async function walkerRequest<T>(
  walker: string,
  payload: Record<string, unknown> = {}
): Promise<T> {
  const response = await apiRequest<{
    ok: boolean;
    data: {
      reports: T[];
    };
  }>(`/walker/${walker}`, {
    method: "POST",
    body: JSON.stringify(payload),
  });

  if (!response.data.reports || response.data.reports.length === 0) {
    throw new Error("No reports found in response");
  }

  const report = response.data.reports[0] as any;

  // Check for error in response
  if (report.success === false) {
    throw new Error(report.error || "Request failed");
  }

  return report as T;
}

// ═══════════════════════════════════════════════════════════════════
// AUTH SERVICE
// ═══════════════════════════════════════════════════════════════════

export const authService = {
  async login(data: LoginRequest): Promise<AuthResponse> {
    const response = await apiRequest<{
      ok: boolean;
      data: AuthResponse;
      error: string | null;
    }>("/user/login", {
      method: "POST",
      body: JSON.stringify(data),
    });

    if (!response.ok || !response.data) {
      throw new Error(response.error || "Login failed");
    }

    return response.data;
  },

  async register(data: RegisterRequest): Promise<AuthResponse> {
    const response = await apiRequest<{
      ok: boolean;
      data: AuthResponse;
      error: string | null;
    }>("/user/register", {
      method: "POST",
      body: JSON.stringify(data),
    });

    if (!response.ok || !response.data) {
      throw new Error(response.error || "Registration failed");
    }

    return response.data;
  },

  // UPDATED: Now uses create_profile instead of create_user_profile
  async createProfile(
    data: CreateProfileRequest = { tier_requested: "free" }
  ): Promise<CreateProfileResponse> {
    return walkerRequest<CreateProfileResponse>("create_profile", data);
  },

  async getProfile(): Promise<UserProfile> {
    return walkerRequest<UserProfile>("get_user_profile", {});
  },
};

// ═══════════════════════════════════════════════════════════════════
// PAYMENT SERVICE (NEW)
// ═══════════════════════════════════════════════════════════════════

export const paymentService = {
  async initiatePayment(
    data: InitiatePaymentRequest
  ): Promise<InitiatePaymentResponse> {
    return walkerRequest<InitiatePaymentResponse>("initiate_payment", data);
  },

  // UPDATED: Now uses process_payment instead of process_payment_dummy
  async processPayment(
    data: ProcessPaymentRequest
  ): Promise<ProcessPaymentResponse> {
    return walkerRequest<ProcessPaymentResponse>("process_payment", data);
  },
};

// ═══════════════════════════════════════════════════════════════════
// SUBSCRIPTION SERVICE (NEW)
// ═══════════════════════════════════════════════════════════════════

export const subscriptionService = {
  async getDetails(): Promise<SubscriptionDetails> {
    return walkerRequest<SubscriptionDetails>("get_subscription_details", {});
  },

  async scheduleDowngrade(
    data: ScheduleDowngradeRequest
  ): Promise<ScheduleDowngradeResponse> {
    return walkerRequest<ScheduleDowngradeResponse>("schedule_downgrade", data);
  },

  async cancel(
    data: CancelSubscriptionRequest
  ): Promise<CancelSubscriptionResponse> {
    return walkerRequest<CancelSubscriptionResponse>(
      "cancel_subscription",
      data
    );
  },
};

// ═══════════════════════════════════════════════════════════════════
// ANALYSIS SERVICE (unchanged)
// ═══════════════════════════════════════════════════════════════════

export const analysisService = {
  async analyzeUrl(data: AnalyzeUrlRequest): Promise<FullReport> {
    return walkerRequest<FullReport>("AnalyzeUrl", data);
  },

  async reanalyze(data: ReanalyzeRequest): Promise<FullReport> {
    return walkerRequest<FullReport>("Reanalyze", data);
  },

  async getReport(businessId: string): Promise<FullReport> {
    return walkerRequest<FullReport>("GetReport", { business_id: businessId });
  },
};

// ═══════════════════════════════════════════════════════════════════
// BUSINESS SERVICE (unchanged)
// ═══════════════════════════════════════════════════════════════════

export const businessService = {
  async getBusinesses(): Promise<BusinessListResponse> {
    return walkerRequest<BusinessListResponse>("GetBusinesses", {});
  },

  async deleteBusiness(businessId: string): Promise<{ success: boolean }> {
    return walkerRequest<{ success: boolean }>("DeleteBusiness", {
      business_id: businessId,
    });
  },

  async getStats(): Promise<any> {
    return walkerRequest<any>("GetStats", {});
  },
};

// ═══════════════════════════════════════════════════════════════════
// REVIEW SERVICE (unchanged)
// ═══════════════════════════════════════════════════════════════════

export const reviewService = {
  async getReviews(params: GetReviewsRequest): Promise<ReviewsResponse> {
    return walkerRequest<ReviewsResponse>("GetReviews", params);
  },
};

// ═══════════════════════════════════════════════════════════════════
// ADMIN SERVICE
// ═══════════════════════════════════════════════════════════════════

export const adminService = {
  async updateSubscription(
    data: UpdateSubscriptionRequest
  ): Promise<{ success: boolean }> {
    return walkerRequest<{ success: boolean }>("update_subscription", data);
  },

  async healthCheck(): Promise<HealthCheckResponse> {
    return walkerRequest<HealthCheckResponse>("health_check", {});
  },
};
```

---

## React Hooks Examples

### useAuth Hook

```typescript
// hooks/useAuth.ts
import { create } from "zustand";
import { persist } from "zustand/middleware";
import { authService } from "@/services/api";

interface AuthState {
  token: string | null;
  username: string | null;
  isAuthenticated: boolean;
  profile: UserProfile | null;

  login: (username: string, password: string) => Promise<void>;
  register: (
    username: string,
    password: string,
    tier: SubscriptionTier
  ) => Promise<void>;
  logout: () => void;
  fetchProfile: () => Promise<void>;
}

export const useAuth = create<AuthState>()(
  persist(
    (set, get) => ({
      token: null,
      username: null,
      isAuthenticated: false,
      profile: null,

      login: async (username, password) => {
        const response = await authService.login({ username, password });
        set({
          token: response.token,
          username: response.username,
          isAuthenticated: true,
        });

        // Fetch profile after login
        await get().fetchProfile();
      },

      register: async (username, password, tier) => {
        // 1. Register user
        const response = await authService.register({ username, password });
        set({
          token: response.token,
          username: response.username,
          isAuthenticated: true,
        });

        // 2. Create profile with selected tier
        await authService.createProfile({ tier_requested: tier });

        // 3. Fetch profile
        await get().fetchProfile();
      },

      logout: () => {
        set({
          token: null,
          username: null,
          isAuthenticated: false,
          profile: null,
        });
      },

      fetchProfile: async () => {
        try {
          const profile = await authService.getProfile();
          set({ profile });
        } catch (error) {
          console.error("Failed to fetch profile:", error);
        }
      },
    }),
    {
      name: "auth-storage",
      partialize: (state) => ({
        token: state.token,
        username: state.username,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);
```

### usePayment Hook

```typescript
// hooks/usePayment.ts
import { useState } from "react";
import { paymentService, authService } from "@/services/api";

export function usePayment() {
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const processUpgrade = async (
    tier: "pro" | "enterprise",
    billingInterval: "monthly" | "annual",
    paymentMethod: PaymentMethod
  ) => {
    setLoading(true);
    setError(null);

    try {
      // 1. Initiate payment
      const paymentIntent = await paymentService.initiatePayment({
        tier,
        billing_interval: billingInterval,
      });

      // 2. Process payment
      const result = await paymentService.processPayment({
        payment_id: paymentIntent.payment_id,
        payment_method: paymentMethod,
      });

      if (!result.success) {
        throw new Error(result.message || "Payment failed");
      }

      return result;
    } catch (err) {
      const message = err instanceof Error ? err.message : "Payment failed";
      setError(message);
      throw err;
    } finally {
      setLoading(false);
    }
  };

  return { processUpgrade, loading, error };
}
```

---

## Page Integration Examples

### Registration Page

```tsx
// pages/register.tsx
import { useState } from "react";
import { useAuth } from "@/hooks/useAuth";
import { useRouter } from "next/router";

type Tier = "free" | "pro" | "enterprise";

export default function RegisterPage() {
  const router = useRouter();
  const { register } = useAuth();

  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [selectedTier, setSelectedTier] = useState<Tier>("free");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");

    try {
      await register(username, password, selectedTier);

      // Redirect based on tier
      if (selectedTier === "free") {
        router.push("/dashboard");
      } else {
        // Redirect to payment page for paid tiers
        router.push("/checkout");
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : "Registration failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleSubmit}>
      <input
        type="text"
        value={username}
        onChange={(e) => setUsername(e.target.value)}
        placeholder="Username"
      />
      <input
        type="password"
        value={password}
        onChange={(e) => setPassword(e.target.value)}
        placeholder="Password"
      />

      {/* Tier Selection */}
      <div className="tier-selection">
        <TierCard
          tier="free"
          price={0}
          selected={selectedTier === "free"}
          onSelect={() => setSelectedTier("free")}
        />
        <TierCard
          tier="pro"
          price={29}
          selected={selectedTier === "pro"}
          onSelect={() => setSelectedTier("pro")}
        />
        <TierCard
          tier="enterprise"
          price={99}
          selected={selectedTier === "enterprise"}
          onSelect={() => setSelectedTier("enterprise")}
        />
      </div>

      {error && <p className="error">{error}</p>}

      <button type="submit" disabled={loading}>
        {loading ? "Creating account..." : "Create Account"}
      </button>
    </form>
  );
}
```

### Checkout Page

```tsx
// pages/checkout.tsx
import { useState, useEffect } from "react";
import { useAuth } from "@/hooks/useAuth";
import { usePayment } from "@/hooks/usePayment";
import { useRouter } from "next/router";

export default function CheckoutPage() {
  const router = useRouter();
  const { profile, fetchProfile } = useAuth();
  const { processUpgrade, loading, error } = usePayment();

  const [billingInterval, setBillingInterval] = useState<"monthly" | "annual">(
    "monthly"
  );
  const [cardNumber, setCardNumber] = useState("");
  const [expMonth, setExpMonth] = useState("");
  const [expYear, setExpYear] = useState("");
  const [cvc, setCvc] = useState("");

  // Check if user needs payment
  useEffect(() => {
    if (profile?.subscription.status !== "pending_payment") {
      router.push("/dashboard");
    }
  }, [profile]);

  const tier = profile?.subscription.pending_upgrade as "pro" | "enterprise";
  const price = billingInterval === "monthly"
    ? (tier === "pro" ? 29 : 99)
    : (tier === "pro" ? 295 : 1009);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    try {
      await processUpgrade(tier, billingInterval, {
        card_number: cardNumber,
        exp_month: parseInt(expMonth),
        exp_year: parseInt(expYear),
        cvc,
      });

      // Refresh profile and redirect
      await fetchProfile();
      router.push("/dashboard?upgraded=true");
    } catch (err) {
      // Error is handled by usePayment hook
    }
  };

  return (
    <div className="checkout">
      <h1>Complete Your {tier?.toUpperCase()} Subscription</h1>

      {/* Billing Interval Toggle */}
      <div className="billing-toggle">
        <button
          className={billingInterval === "monthly" ? "active" : ""}
          onClick={() => setBillingInterval("monthly")}
        >
          Monthly
        </button>
        <button
          className={billingInterval === "annual" ? "active" : ""}
          onClick={() => setBillingInterval("annual")}
        >
          Annual (Save 15%)
        </button>
      </div>

      <p className="price">
        ${price}/{billingInterval === "monthly" ? "mo" : "yr"}
      </p>

      {/* Payment Form */}
      <form onSubmit={handleSubmit}>
        <input
          type="text"
          value={cardNumber}
          onChange={(e) => setCardNumber(e.target.value)}
          placeholder="Card Number"
          maxLength={16}
        />
        <div className="row">
          <input
            type="text"
            value={expMonth}
            onChange={(e) => setExpMonth(e.target.value)}
            placeholder="MM"
            maxLength={2}
          />
          <input
            type="text"
            value={expYear}
            onChange={(e) => setExpYear(e.target.value)}
            placeholder="YYYY"
            maxLength={4}
          />
          <input
            type="text"
            value={cvc}
            onChange={(e) => setCvc(e.target.value)}
            placeholder="CVC"
            maxLength={4}
          />
        </div>

        {error && <p className="error">{error}</p>}

        <button type="submit" disabled={loading}>
          {loading ? "Processing..." : `Pay $${price}`}
        </button>
      </form>

      {/* Test Card Info */}
      <div className="test-info">
        <p>Test Card: 4242 4242 4242 4242</p>
        <p>Decline: 4000 0000 0000 0002</p>
      </div>
    </div>
  );
}
```

---

## Pricing Reference

| Tier | Monthly | Annual | Annual Savings | Businesses | Daily Analyses |
|------|---------|--------|----------------|------------|----------------|
| Free | $0 | $0 | - | 5 | 10 |
| Pro | $29 | $295 | $53 (15%) | 50 | 100 |
| Enterprise | $99 | $1,009 | $179 (15%) | Unlimited | Unlimited |

---

## Test Cards

| Card Number | Result |
|-------------|--------|
| `4242424242424242` | Success |
| `4000000000000002` | Declined |
| `4000000000009995` | Insufficient funds |

---

## Checklist for Frontend Migration

- [ ] Update `types/index.ts` with new types
- [ ] Replace `services/api.ts` with updated version
- [ ] Update auth hook to use `create_profile` instead of `create_user_profile`
- [ ] Add `paymentService` calls
- [ ] Add `subscriptionService` calls
- [ ] Create/update checkout page
- [ ] Create/update billing settings page
- [ ] Remove references to removed endpoints (onboarding, session tokens)
- [ ] Test full registration flow
- [ ] Test payment flow with test cards
- [ ] Test subscription management (downgrade, cancel)
