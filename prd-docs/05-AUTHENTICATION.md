# 05 - Authentication

## 1. Auth Flow Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        AUTHENTICATION FLOW                          │
└─────────────────────────────────────────────────────────────────────┘

New User:
┌──────────┐    ┌──────────┐    ┌─────────────┐    ┌──────────┐
│ Register │───▶│ Get JWT  │───▶│ Create      │───▶│ Dashboard│
│ Page     │    │ Token    │    │ Profile     │    │          │
└──────────┘    └──────────┘    └─────────────┘    └──────────┘

Returning User:
┌──────────┐    ┌──────────┐    ┌──────────┐
│ Login    │───▶│ Get JWT  │───▶│ Dashboard│
│ Page     │    │ Token    │    │          │
└──────────┘    └──────────┘    └──────────┘

Token Refresh:
┌──────────┐    ┌──────────┐    ┌──────────┐
│ API Call │───▶│ 401      │───▶│ Redirect │
│ (expired)│    │ Response │    │ to Login │
└──────────┘    └──────────┘    └──────────┘
```

---

## 2. Auth Store (Zustand)

```typescript
// src/store/authStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface User {
  id: string;
  email: string;
}

interface AuthState {
  token: string | null;
  user: User | null;
  isAuthenticated: boolean;
  isAdmin: boolean;

  // Actions
  setAuth: (token: string, user: User) => void;
  setAdmin: (isAdmin: boolean) => void;
  logout: () => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set) => ({
      token: null,
      user: null,
      isAuthenticated: false,
      isAdmin: false,

      setAuth: (token, user) =>
        set({
          token,
          user,
          isAuthenticated: true,
        }),

      setAdmin: (isAdmin) =>
        set({ isAdmin }),

      logout: () =>
        set({
          token: null,
          user: null,
          isAuthenticated: false,
          isAdmin: false,
        }),
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        token: state.token,
        user: state.user,
        isAuthenticated: state.isAuthenticated,
        isAdmin: state.isAdmin,
      }),
    }
  )
);
```

---

## 3. Protected Route Component

```typescript
// src/components/auth/ProtectedRoute.tsx
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { LoadingSpinner } from '@/components/shared/LoadingSpinner';
import { useProfile } from '@/hooks/useAuth';

interface ProtectedRouteProps {
  requireAdmin?: boolean;
}

export const ProtectedRoute = ({ requireAdmin = false }: ProtectedRouteProps) => {
  const location = useLocation();
  const { isAuthenticated, isAdmin } = useAuthStore();
  const { isLoading } = useProfile();

  // Show loading while checking auth
  if (isLoading) {
    return (
      <div className="flex h-screen items-center justify-center">
        <LoadingSpinner size="lg" />
      </div>
    );
  }

  // Redirect to login if not authenticated
  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // Redirect to dashboard if not admin but admin required
  if (requireAdmin && !isAdmin) {
    return <Navigate to="/" replace />;
  }

  return <Outlet />;
};
```

---

## 4. Login Page

```typescript
// src/pages/auth/LoginPage.tsx
import { useState } from 'react';
import { useNavigate, useLocation, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useLogin } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { brandConfig } from '@/config/branding.config';

const loginSchema = z.object({
  email: z.string().email('Please enter a valid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
});

type LoginFormData = z.infer<typeof loginSchema>;

export const LoginPage = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [error, setError] = useState<string | null>(null);
  const { mutate: login, isPending } = useLogin();

  const from = (location.state as { from?: Location })?.from?.pathname || '/';

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<LoginFormData>({
    resolver: zodResolver(loginSchema),
  });

  const onSubmit = (data: LoginFormData) => {
    setError(null);
    login(data, {
      onSuccess: () => {
        navigate(from, { replace: true });
      },
      onError: (err) => {
        setError('Invalid email or password');
      },
    });
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1 text-center">
          <img
            src={brandConfig.logo}
            alt={brandConfig.appName}
            className="mx-auto h-10 w-auto"
          />
          <CardTitle className="text-2xl font-semibold">Welcome back</CardTitle>
          <CardDescription>
            Sign in to your account to continue
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            {error && (
              <Alert variant="destructive">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <div className="space-y-2">
              <label htmlFor="email" className="text-sm font-medium">
                Email
              </label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                {...register('email')}
                className={errors.email ? 'border-red-500' : ''}
              />
              {errors.email && (
                <p className="text-sm text-red-500">{errors.email.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <label htmlFor="password" className="text-sm font-medium">
                Password
              </label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                {...register('password')}
                className={errors.password ? 'border-red-500' : ''}
              />
              {errors.password && (
                <p className="text-sm text-red-500">{errors.password.message}</p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={isPending}>
              {isPending ? 'Signing in...' : 'Sign in'}
            </Button>
          </form>

          <div className="mt-6 text-center text-sm">
            <span className="text-gray-500">Don't have an account?</span>{' '}
            <Link to="/register" className="font-medium text-blue-600 hover:underline">
              Sign up
            </Link>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
```

---

## 5. Register Page

```typescript
// src/pages/auth/RegisterPage.tsx
import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { authService } from '@/services/auth.service';
import { useAuthStore } from '@/store/authStore';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { brandConfig } from '@/config/branding.config';

const registerSchema = z.object({
  email: z.string().email('Please enter a valid email'),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: "Passwords don't match",
  path: ['confirmPassword'],
});

type RegisterFormData = z.infer<typeof registerSchema>;

export const RegisterPage = () => {
  const navigate = useNavigate();
  const setAuth = useAuthStore((state) => state.setAuth);
  const [error, setError] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<RegisterFormData>({
    resolver: zodResolver(registerSchema),
  });

  const onSubmit = async (data: RegisterFormData) => {
    setError(null);
    setIsLoading(true);

    try {
      // Step 1: Register user
      const authResponse = await authService.register({
        email: data.email,
        password: data.password,
      });

      // Step 2: Set auth state
      setAuth(authResponse.token, authResponse.user);

      // Step 3: Create user profile
      await authService.createProfile({ subscription_tier: 'free' });

      // Step 4: Navigate to dashboard
      navigate('/', { replace: true });
    } catch (err: any) {
      setError(err.response?.data?.error || 'Registration failed');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gray-50 px-4">
      <Card className="w-full max-w-md">
        <CardHeader className="space-y-1 text-center">
          <img
            src={brandConfig.logo}
            alt={brandConfig.appName}
            className="mx-auto h-10 w-auto"
          />
          <CardTitle className="text-2xl font-semibold">Create an account</CardTitle>
          <CardDescription>
            Get started with your free account
          </CardDescription>
        </CardHeader>

        <CardContent>
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            {error && (
              <Alert variant="destructive">
                <AlertDescription>{error}</AlertDescription>
              </Alert>
            )}

            <div className="space-y-2">
              <label htmlFor="email" className="text-sm font-medium">
                Email
              </label>
              <Input
                id="email"
                type="email"
                placeholder="you@example.com"
                {...register('email')}
                className={errors.email ? 'border-red-500' : ''}
              />
              {errors.email && (
                <p className="text-sm text-red-500">{errors.email.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <label htmlFor="password" className="text-sm font-medium">
                Password
              </label>
              <Input
                id="password"
                type="password"
                placeholder="••••••••"
                {...register('password')}
                className={errors.password ? 'border-red-500' : ''}
              />
              {errors.password && (
                <p className="text-sm text-red-500">{errors.password.message}</p>
              )}
            </div>

            <div className="space-y-2">
              <label htmlFor="confirmPassword" className="text-sm font-medium">
                Confirm Password
              </label>
              <Input
                id="confirmPassword"
                type="password"
                placeholder="••••••••"
                {...register('confirmPassword')}
                className={errors.confirmPassword ? 'border-red-500' : ''}
              />
              {errors.confirmPassword && (
                <p className="text-sm text-red-500">{errors.confirmPassword.message}</p>
              )}
            </div>

            <Button type="submit" className="w-full" disabled={isLoading}>
              {isLoading ? 'Creating account...' : 'Create account'}
            </Button>
          </form>

          <div className="mt-6 text-center text-sm">
            <span className="text-gray-500">Already have an account?</span>{' '}
            <Link to="/login" className="font-medium text-blue-600 hover:underline">
              Sign in
            </Link>
          </div>

          <p className="mt-4 text-center text-xs text-gray-500">
            By creating an account, you agree to our{' '}
            <a href="#" className="underline">Terms of Service</a> and{' '}
            <a href="#" className="underline">Privacy Policy</a>.
          </p>
        </CardContent>
      </Card>
    </div>
  );
};
```

---

## 6. Auth Route Configuration

```typescript
// src/App.tsx
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ProtectedRoute } from '@/components/auth/ProtectedRoute';
import { MainLayout } from '@/components/layout/MainLayout';
import { AdminLayout } from '@/components/layout/AdminLayout';

// Auth pages
import { LoginPage } from '@/pages/auth/LoginPage';
import { RegisterPage } from '@/pages/auth/RegisterPage';

// Protected pages
import { DashboardPage } from '@/pages/dashboard/DashboardPage';
import { AnalyzePage } from '@/pages/analysis/AnalyzePage';
import { ReportPage } from '@/pages/analysis/ReportPage';
// ... other imports

// Admin pages
import { AdminDashboard } from '@/pages/admin/AdminDashboard';
import { UserManagement } from '@/pages/admin/UserManagement';

const queryClient = new QueryClient();

export const App = () => {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          {/* Public routes */}
          <Route path="/login" element={<LoginPage />} />
          <Route path="/register" element={<RegisterPage />} />

          {/* Protected routes */}
          <Route element={<ProtectedRoute />}>
            <Route element={<MainLayout />}>
              <Route index element={<DashboardPage />} />
              <Route path="analyze" element={<AnalyzePage />} />
              <Route path="report/:businessId" element={<ReportPage />} />
              {/* ... other routes */}
            </Route>
          </Route>

          {/* Admin routes */}
          <Route element={<ProtectedRoute requireAdmin />}>
            <Route path="admin" element={<AdminLayout />}>
              <Route index element={<AdminDashboard />} />
              <Route path="users" element={<UserManagement />} />
              {/* ... other admin routes */}
            </Route>
          </Route>

          {/* 404 */}
          <Route path="*" element={<NotFoundPage />} />
        </Routes>
      </BrowserRouter>
    </QueryClientProvider>
  );
};
```

---

## 7. Session Management

### 7.1 Token Expiry Handling
```typescript
// In api.ts interceptor
api.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const originalRequest = error.config;

    if (error.response?.status === 401 && originalRequest) {
      // Clear auth state
      useAuthStore.getState().logout();

      // Redirect to login with return URL
      const currentPath = window.location.pathname;
      window.location.href = `/login?redirect=${encodeURIComponent(currentPath)}`;
    }

    return Promise.reject(error);
  }
);
```

### 7.2 Auto-refresh Profile on Focus
```typescript
// In App.tsx or a dedicated hook
import { useEffect } from 'react';
import { useQueryClient } from '@tanstack/react-query';

export const useRefreshOnFocus = () => {
  const queryClient = useQueryClient();

  useEffect(() => {
    const handleFocus = () => {
      queryClient.invalidateQueries({ queryKey: ['profile'] });
    };

    window.addEventListener('focus', handleFocus);
    return () => window.removeEventListener('focus', handleFocus);
  }, [queryClient]);
};
```

---

## 8. Role-Based Access

```typescript
// src/hooks/usePermissions.ts
import { useAuthStore } from '@/store/authStore';
import { useProfile } from './useAuth';

export const usePermissions = () => {
  const { isAdmin } = useAuthStore();
  const { data: profile } = useProfile();

  return {
    isAdmin,
    canAnalyze: profile?.is_active && (profile?.limits.remaining_today ?? 0) > 0,
    canAddBusiness: profile?.is_active && (profile?.limits.remaining_businesses ?? 0) > 0,
    tier: profile?.subscription || 'free',
    limits: profile?.limits,
  };
};

// Usage in components
const { canAnalyze, tier } = usePermissions();

{!canAnalyze && (
  <Alert>
    <AlertDescription>
      You've reached your daily limit. Upgrade to continue.
    </AlertDescription>
  </Alert>
)}
```
