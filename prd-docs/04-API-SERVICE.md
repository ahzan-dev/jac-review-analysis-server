# 04 - API Service Layer

## 1. API Configuration

### 1.1 Base URL
```typescript
// src/config/env.config.ts
export const API_BASE_URL = import.meta.env.VITE_API_URL || 'https://review-analysis-server.trynewways.com';
```

### 1.2 Axios Instance
```typescript
// src/services/api.ts
import axios, { AxiosError, InternalAxiosRequestConfig } from 'axios';
import { useAuthStore } from '@/store/authStore';

export const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 240000, // 2 minutes for analysis requests
  headers: {
    'Content-Type': 'application/json',
  },
});

// Request interceptor - add JWT token
api.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    const token = useAuthStore.getState().token;
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Response interceptor - handle errors
api.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => {
    if (error.response?.status === 401) {
      useAuthStore.getState().logout();
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);
```

---

## 2. API Response Wrapper

All API responses follow this structure:

```typescript
// src/types/api.types.ts
export interface ApiResponse<T> {
  ok: boolean;
  type: 'response' | 'error';
  data: {
    result: T;
  };
}

export interface ApiError {
  ok: false;
  type: 'error';
  error: string;
  message?: string;
}

// Walker result wrapper
export interface WalkerResult<T> {
  _jac_type: string;
  _jac_id: string;
  _jac_archetype: 'walker';
  // ... walker properties
  output?: T;
}
```

---

## 3. TypeScript Interfaces

### 3.1 Authentication Types
```typescript
// src/types/auth.types.ts

export interface LoginRequest {
  email: string;
  password: string;
}

export interface RegisterRequest {
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  user: {
    id: string;
    email: string;
  };
}

export interface UserProfile {
  status: 'found' | 'created';
  role: 'user' | 'admin';
  subscription: 'free' | 'pro' | 'enterprise';
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

export interface CreateProfileRequest {
  subscription_tier?: 'free' | 'pro' | 'enterprise';
}
```

### 3.2 Analysis Types
```typescript
// src/types/analysis.types.ts

export interface AnalyzeUrlRequest {
  url: string;
  max_reviews?: number;          // default: 100
  analysis_depth?: 'basic' | 'standard' | 'deep';  // default: 'deep'
  force_refresh?: boolean;       // default: false
  freshness_days?: number;       // default: 7
}

export interface ReanalyzeRequest {
  business_id: string;
  report_type?: 'basic' | 'standard' | 'deep';
  force_sentiment?: boolean;
}
```

### 3.3 Full Report Types
```typescript
// src/types/report.types.ts

export interface FullReport {
  success: boolean;
  data_source: 'serpapi' | 'mock' | 'cache' | 'reanalysis' | 'stored';
  generated_at: string;
  from_cache?: boolean;

  business: BusinessInfo;
  health_score: HealthScore;
  sentiment: SentimentAnalysis;
  themes: Theme[];
  trends: TrendAnalysis;
  critical_issues: CriticalIssue[];
  swot: SwotAnalysis;
  recommendations: BrandAwareRecommendations;
  recommendations_legacy: LegacyRecommendations;
  executive_summary: ExecutiveSummary;
  key_findings: string[];
  statistics: ReviewStatistics;

  usage?: UsageInfo;
  cache_info?: CacheInfo;
}

export interface BusinessInfo {
  name: string;
  type: string;
  type_normalized: string;
  address: string;
  phone: string;
  website: string;
  google_rating: number;
  total_reviews: number;
  reviews_analyzed: number;
  price_level: string;
  coordinates: {
    lat: number;
    lng: number;
  };
  opening_hours: Record<string, string>;
  photos_count: number;
}

export interface HealthScore {
  overall: number;
  grade: 'A+' | 'A' | 'A-' | 'B+' | 'B' | 'B-' | 'C+' | 'C' | 'C-' | 'D' | 'F';
  confidence: 'high' | 'medium' | 'low';
  breakdown: Record<string, number>;
  trend: 'improving' | 'stable' | 'declining';
}

export interface SentimentAnalysis {
  distribution: {
    positive: { count: number; percentage: number };
    negative: { count: number; percentage: number };
    neutral: { count: number; percentage: number };
  };
  average_score: number;
  sample_size_adequacy: 'sufficient' | 'limited' | 'minimal';
}

export interface Theme {
  name: string;
  mention_count: number;
  sentiment_score: number;
  sentiment_label: 'positive' | 'negative' | 'neutral';
  confidence: 'high' | 'medium' | 'low';
  sub_themes: SubTheme[];
  sample_quotes: {
    positive: string[];
    negative: string[];
  };
}

export interface SubTheme {
  name: string;
  mentions: number;
  sentiment: number;
  positive_pct: number;
  verdict: 'excellent' | 'good' | 'average' | 'poor' | 'critical';
}

export interface TrendAnalysis {
  period_analyzed: string;
  overall_trend: {
    direction: 'improving' | 'stable' | 'declining';
    change: string;
  };
  monthly_breakdown: MonthlyTrend[];
}

export interface MonthlyTrend {
  month: string;
  review_count: number;
  sentiment: number;
  avg_rating: number;
}

export interface CriticalIssue {
  issue: string;
  severity: 'high' | 'medium' | 'low';
  mention_count: number;
  suggested_action: string;
}

export interface SwotAnalysis {
  strengths: SwotItem[];
  weaknesses: SwotItem[];
  opportunities: SwotItem[];
  threats: SwotItem[];
}

export interface SwotItem {
  point: string;
  evidence_count: number;
}

export interface BrandAwareRecommendations {
  brand_context: {
    price_positioning: string;
    brand_positioning: string;
    protected_strengths: string[];
    brand_risks: string[];
  };
  issue_severity_summary: string;
  immediate: Recommendation[];
  short_term: Recommendation[];
  long_term: Recommendation[];
  do_not: ProtectiveRecommendation[];
  overall_risk_assessment: string;
}

export interface Recommendation {
  action: string;
  action_type: 'monitor' | 'communicate' | 'experiment' | 'change';
  reason: string;
  evidence: {
    issue: string;
    mention_count: number;
    mention_percentage: number;
    severity: 'high' | 'medium' | 'low';
    sample_feedback: string[];
    customer_segments: string[];
  };
  expected_impact: string;
  downside_risk: string;
  effort: 'low' | 'medium' | 'high';
  risk_level: 'low' | 'medium' | 'high';
  confidence_level: 'high' | 'medium' | 'low';
  priority_score: number;
  caution_note: string;
}

export interface ProtectiveRecommendation {
  area: string;
  do_not_action: string;
  rationale: string;
  evidence_count: number;
}

export interface LegacyRecommendations {
  immediate: LegacyRecommendation[];
  short_term: LegacyRecommendation[];
  long_term: LegacyRecommendation[];
}

export interface LegacyRecommendation {
  action: string;
  reason: string;
  expected_impact: string;
  effort: 'low' | 'medium' | 'high';
  priority_score: number;
}

export interface ExecutiveSummary {
  headline: string;
  one_liner: string;
  key_metric: string;
  full_summary: string;
}

export interface ReviewStatistics {
  reviews_analyzed: number;
  date_range: {
    from: string;
    to: string;
  };
  rating_distribution: Record<string, number>;
  avg_review_length: number;
  reviews_with_photos: number;
  response_rate: string;
}

export interface UsageInfo {
  analyses_today: number;
  daily_limit: number;
  businesses_count: number;
  business_limit: number;
  tier: string;
}

export interface CacheInfo {
  from_cache: boolean;
  data_age_days?: number;
  freshness_threshold_days?: number;
  fetched_at?: string;
  message: string;
}
```

### 3.4 Business Types
```typescript
// src/types/business.types.ts

export interface Business {
  place_id: string;
  name: string;
  address: string;
  rating: number;
  total_reviews: number;
  business_type: string;
  status: 'fetched' | 'analyzing' | 'completed' | 'failed';
  fetched_at: string;
  last_analyzed_at: string;
}

export interface BusinessListResponse {
  businesses: Business[];
  total: number;
}

export interface DeleteBusinessRequest {
  business_id: string;
}
```

### 3.5 Review Types
```typescript
// src/types/review.types.ts

export interface Review {
  review_id: string;
  author: string;
  author_image: string;
  rating: number;
  text: string;
  date: string;
  relative_date: string;
  likes: number;
  sentiment: 'positive' | 'negative' | 'neutral';
  sentiment_score: number;
  themes: string[];
  keywords: string[];
  emotion: string;
  owner_response?: string;
  owner_response_date?: string;
}

export interface GetReviewsRequest {
  business_id: string;
  sentiment_filter?: 'positive' | 'negative' | 'neutral' | 'all';
  rating_filter?: number;
  limit?: number;
  offset?: number;
}

export interface ReviewsResponse {
  reviews: Review[];
  total: number;
  filters_applied: {
    sentiment?: string;
    rating?: number;
  };
}
```

### 3.6 Admin Types
```typescript
// src/types/admin.types.ts

export interface UpdateSubscriptionRequest {
  target_email: string;
  new_tier: 'free' | 'pro' | 'enterprise';
}

export interface DiagnosticsResponse {
  environment: {
    LLM_MODEL: string;
    DEBUG: string;
    PORT: string;
    OPENAI_API_KEY: string;
    SERPAPI_KEY: string;
  };
  system_info: {
    python_version: string;
    cwd: string;
  };
}
```

---

## 4. Service Functions

### 4.1 Auth Service
```typescript
// src/services/auth.service.ts
import { api } from './api';
import type {
  LoginRequest,
  RegisterRequest,
  AuthResponse,
  UserProfile,
  CreateProfileRequest,
} from '@/types/auth.types';

export const authService = {
  async login(data: LoginRequest): Promise<AuthResponse> {
    const response = await api.post('/user/login', data);
    return response.data;
  },

  async register(data: RegisterRequest): Promise<AuthResponse> {
    const response = await api.post('/user/register', data);
    return response.data;
  },

  async createProfile(data?: CreateProfileRequest): Promise<UserProfile> {
    const response = await api.post('/walker/create_user_profile', data || {});
    return response.data.data.result;
  },

  async getProfile(): Promise<UserProfile> {
    const response = await api.post('/walker/get_user_profile', {});
    return response.data.data.result;
  },
};
```

### 4.2 Analysis Service
```typescript
// src/services/analysis.service.ts
import { api } from './api';
import type {
  AnalyzeUrlRequest,
  ReanalyzeRequest,
} from '@/types/analysis.types';
import type { FullReport } from '@/types/report.types';

export const analysisService = {
  async analyzeUrl(data: AnalyzeUrlRequest): Promise<FullReport> {
    const response = await api.post('/walker/AnalyzeUrl', data);
    // The response structure: { ok, type, data: { result: { output: FullReport } } }
    return response.data.data.result.output || response.data.data.result;
  },

  async reanalyze(data: ReanalyzeRequest): Promise<FullReport> {
    const response = await api.post('/walker/Reanalyze', data);
    return response.data.data.result.output || response.data.data.result;
  },

  async getReport(businessId: string): Promise<FullReport> {
    const response = await api.post('/walker/GetReport', {
      business_id: businessId,
    });
    return response.data.data.result.output || response.data.data.result;
  },
};
```

### 4.3 Business Service
```typescript
// src/services/business.service.ts
import { api } from './api';
import type { Business, BusinessListResponse } from '@/types/business.types';

export const businessService = {
  async getBusinesses(): Promise<BusinessListResponse> {
    const response = await api.post('/walker/GetBusinesses', {});
    return response.data.data.result;
  },

  async deleteBusiness(businessId: string): Promise<{ success: boolean }> {
    const response = await api.post('/walker/DeleteBusiness', {
      business_id: businessId,
    });
    return response.data.data.result;
  },
};
```

### 4.4 Review Service
```typescript
// src/services/review.service.ts
import { api } from './api';
import type { GetReviewsRequest, ReviewsResponse } from '@/types/review.types';

export const reviewService = {
  async getReviews(params: GetReviewsRequest): Promise<ReviewsResponse> {
    const response = await api.post('/walker/GetReviews', params);
    return response.data.data.result;
  },
};
```

### 4.5 Admin Service
```typescript
// src/services/admin.service.ts
import { api } from './api';
import type {
  UpdateSubscriptionRequest,
  DiagnosticsResponse,
} from '@/types/admin.types';

export const adminService = {
  async updateSubscription(data: UpdateSubscriptionRequest): Promise<{ success: boolean }> {
    const response = await api.post('/walker/update_subscription', data);
    return response.data.data.result;
  },

  async getDiagnostics(): Promise<DiagnosticsResponse> {
    const response = await api.post('/walker/diagnostics', {});
    return response.data.data.result;
  },

  async healthCheck(): Promise<{ status: string; service: string; version: string }> {
    const response = await api.post('/walker/health_check', {});
    return response.data.data.result;
  },
};
```

---

## 5. Custom Hooks with TanStack Query

### 5.1 useAuth Hook
```typescript
// src/hooks/useAuth.ts
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { authService } from '@/services/auth.service';
import { useAuthStore } from '@/store/authStore';

export const useProfile = () => {
  return useQuery({
    queryKey: ['profile'],
    queryFn: authService.getProfile,
    staleTime: 5 * 60 * 1000, // 5 minutes
  });
};

export const useLogin = () => {
  const setAuth = useAuthStore((state) => state.setAuth);
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: authService.login,
    onSuccess: (data) => {
      setAuth(data.token, data.user);
      queryClient.invalidateQueries({ queryKey: ['profile'] });
    },
  });
};
```

### 5.2 useReport Hook
```typescript
// src/hooks/useReport.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { analysisService } from '@/services/analysis.service';
import type { AnalyzeUrlRequest } from '@/types/analysis.types';

export const useReport = (businessId: string) => {
  return useQuery({
    queryKey: ['report', businessId],
    queryFn: () => analysisService.getReport(businessId),
    enabled: !!businessId,
    staleTime: 10 * 60 * 1000, // 10 minutes
  });
};

export const useAnalyzeUrl = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (params: AnalyzeUrlRequest) => analysisService.analyzeUrl(params),
    onSuccess: (data) => {
      // Invalidate businesses list to show new business
      queryClient.invalidateQueries({ queryKey: ['businesses'] });
      // Cache the report
      if (data.business) {
        queryClient.setQueryData(['report', data.business.name], data);
      }
    },
  });
};
```

### 5.3 useBusinesses Hook
```typescript
// src/hooks/useBusinesses.ts
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { businessService } from '@/services/business.service';

export const useBusinesses = () => {
  return useQuery({
    queryKey: ['businesses'],
    queryFn: businessService.getBusinesses,
    staleTime: 2 * 60 * 1000, // 2 minutes
  });
};

export const useDeleteBusiness = () => {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: businessService.deleteBusiness,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['businesses'] });
    },
  });
};
```

---

## 6. Error Handling

```typescript
// src/utils/error-handler.ts
import { AxiosError } from 'axios';
import { toast } from '@/components/ui/toast';

export interface ApiErrorResponse {
  error: string;
  message?: string;
  limit?: number;
  used?: number;
}

export const handleApiError = (error: unknown): string => {
  if (error instanceof AxiosError) {
    const data = error.response?.data as ApiErrorResponse | undefined;

    // Handle specific error cases
    if (data?.error === 'Daily analysis limit reached') {
      toast({
        title: 'Limit Reached',
        description: `You've used ${data.used}/${data.limit} analyses today. Upgrade for more.`,
        variant: 'destructive',
      });
      return data.error;
    }

    if (data?.error === 'User profile not found') {
      return 'Please complete your profile setup first.';
    }

    if (data?.error) {
      return data.error;
    }

    // Generic HTTP errors
    switch (error.response?.status) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 403:
        return 'You do not have permission to perform this action.';
      case 404:
        return 'The requested resource was not found.';
      case 429:
        return 'Too many requests. Please wait a moment.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'An unexpected error occurred.';
    }
  }

  if (error instanceof Error) {
    return error.message;
  }

  return 'An unknown error occurred.';
};
```
