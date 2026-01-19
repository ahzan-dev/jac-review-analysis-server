# 03 - Architecture & Folder Structure

## 1. Project Structure

```
review-analyzer-frontend/
├── public/
│   ├── favicon.ico
│   ├── logo.svg
│   └── robots.txt
│
├── src/
│   ├── assets/                    # Static assets
│   │   ├── images/
│   │   └── fonts/
│   │
│   ├── components/                # Reusable components
│   │   ├── ui/                    # shadcn/ui components
│   │   │   ├── button.tsx
│   │   │   ├── card.tsx
│   │   │   ├── input.tsx
│   │   │   └── ...
│   │   │
│   │   ├── layout/                # Layout components
│   │   │   ├── MainLayout.tsx
│   │   │   ├── AdminLayout.tsx
│   │   │   ├── Sidebar.tsx
│   │   │   ├── Header.tsx
│   │   │   └── Footer.tsx
│   │   │
│   │   ├── report/                # Report display components
│   │   │   ├── ReportContainer.tsx
│   │   │   ├── ExecutiveSummary.tsx
│   │   │   ├── HealthScoreCard.tsx
│   │   │   ├── SentimentChart.tsx
│   │   │   ├── ThemeAnalysis.tsx
│   │   │   ├── RecommendationsList.tsx
│   │   │   ├── SwotAnalysis.tsx
│   │   │   ├── TrendsChart.tsx
│   │   │   ├── CriticalIssues.tsx
│   │   │   ├── ReviewBrowser.tsx
│   │   │   └── JsonViewer.tsx
│   │   │
│   │   ├── business/              # Business-related components
│   │   │   ├── BusinessCard.tsx
│   │   │   ├── BusinessList.tsx
│   │   │   └── BusinessFilters.tsx
│   │   │
│   │   ├── auth/                  # Auth components
│   │   │   ├── LoginForm.tsx
│   │   │   ├── RegisterForm.tsx
│   │   │   └── ProtectedRoute.tsx
│   │   │
│   │   └── shared/                # Shared components
│   │       ├── LoadingSpinner.tsx
│   │       ├── ErrorBoundary.tsx
│   │       ├── EmptyState.tsx
│   │       ├── PageHeader.tsx
│   │       └── ConfirmDialog.tsx
│   │
│   ├── pages/                     # Page components
│   │   ├── auth/
│   │   │   ├── LoginPage.tsx
│   │   │   └── RegisterPage.tsx
│   │   │
│   │   ├── dashboard/
│   │   │   └── DashboardPage.tsx
│   │   │
│   │   ├── analysis/
│   │   │   ├── AnalyzePage.tsx
│   │   │   └── ReportPage.tsx
│   │   │
│   │   ├── businesses/
│   │   │   ├── BusinessListPage.tsx
│   │   │   └── BusinessDetailPage.tsx
│   │   │
│   │   ├── reviews/
│   │   │   └── ReviewsPage.tsx
│   │   │
│   │   ├── settings/
│   │   │   └── SettingsPage.tsx
│   │   │
│   │   ├── admin/
│   │   │   ├── AdminDashboard.tsx
│   │   │   ├── UserManagement.tsx
│   │   │   └── Diagnostics.tsx
│   │   │
│   │   └── NotFoundPage.tsx
│   │
│   ├── services/                  # API services
│   │   ├── api.ts                 # Axios instance
│   │   ├── auth.service.ts
│   │   ├── analysis.service.ts
│   │   ├── business.service.ts
│   │   ├── review.service.ts
│   │   └── admin.service.ts
│   │
│   ├── hooks/                     # Custom hooks
│   │   ├── useAuth.ts
│   │   ├── useReport.ts
│   │   ├── useBusinesses.ts
│   │   └── useReviews.ts
│   │
│   ├── store/                     # Zustand stores
│   │   ├── authStore.ts
│   │   └── uiStore.ts
│   │
│   ├── types/                     # TypeScript types
│   │   ├── auth.types.ts
│   │   ├── report.types.ts
│   │   ├── business.types.ts
│   │   ├── review.types.ts
│   │   └── api.types.ts
│   │
│   ├── utils/                     # Utility functions
│   │   ├── formatters.ts
│   │   ├── validators.ts
│   │   ├── constants.ts
│   │   └── helpers.ts
│   │
│   ├── config/                    # Configuration
│   │   ├── branding.config.ts
│   │   ├── routes.config.ts
│   │   └── env.config.ts
│   │
│   ├── styles/                    # Global styles
│   │   └── globals.css
│   │
│   ├── App.tsx                    # Root component
│   ├── main.tsx                   # Entry point
│   └── vite-env.d.ts
│
├── .env.example
├── .eslintrc.cjs
├── .prettierrc
├── tailwind.config.js
├── tsconfig.json
├── vite.config.ts
└── package.json
```

---

## 2. Architecture Patterns

### 2.1 Component Pattern
```
Feature-First Organization
├── Components grouped by feature/domain
├── UI components separate from feature components
├── Container/Presentational separation where beneficial
└── Colocate tests with components
```

### 2.2 State Management Pattern
```
Hybrid Approach
├── Server State: TanStack Query (API data)
├── Client State: Zustand (auth, UI preferences)
├── Form State: React Hook Form (local)
└── URL State: React Router (navigation, filters)
```

### 2.3 Service Layer Pattern
```
API Abstraction
├── Services encapsulate API calls
├── Services handle request/response transformation
├── Hooks consume services via TanStack Query
└── Components use hooks, never services directly
```

---

## 3. Data Flow

```
┌─────────────────────────────────────────────────────────────┐
│                        Component                             │
│  ┌─────────────────────────────────────────────────────┐    │
│  │                     useQuery()                       │    │
│  │  ┌─────────────────────────────────────────────┐    │    │
│  │  │              Service Function               │    │    │
│  │  │  ┌─────────────────────────────────────┐   │    │    │
│  │  │  │           Axios Instance            │   │    │    │
│  │  │  │  ┌─────────────────────────────┐   │   │    │    │
│  │  │  │  │     API (Backend)           │   │   │    │    │
│  │  │  │  └─────────────────────────────┘   │   │    │    │
│  │  │  └─────────────────────────────────────┘   │    │    │
│  │  └─────────────────────────────────────────────┘    │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘

Example:
ReportPage.tsx
  └─> useReport(businessId)           // Custom hook
        └─> useQuery(['report', id])  // TanStack Query
              └─> getReport(id)       // Service function
                    └─> api.post()    // Axios
                          └─> API     // Backend
```

---

## 4. Routing Structure

```typescript
const routes = [
  // Public routes
  { path: '/login', element: <LoginPage /> },
  { path: '/register', element: <RegisterPage /> },

  // Protected routes (requires auth)
  {
    path: '/',
    element: <MainLayout />,
    children: [
      { index: true, element: <DashboardPage /> },
      { path: 'analyze', element: <AnalyzePage /> },
      { path: 'report/:businessId', element: <ReportPage /> },
      { path: 'businesses', element: <BusinessListPage /> },
      { path: 'businesses/:id', element: <BusinessDetailPage /> },
      { path: 'reviews/:businessId', element: <ReviewsPage /> },
      { path: 'settings', element: <SettingsPage /> },
    ],
  },

  // Admin routes (requires admin role)
  {
    path: '/admin',
    element: <AdminLayout />,
    children: [
      { index: true, element: <AdminDashboard /> },
      { path: 'users', element: <UserManagement /> },
      { path: 'diagnostics', element: <Diagnostics /> },
    ],
  },

  // 404
  { path: '*', element: <NotFoundPage /> },
];
```

---

## 5. Error Handling Strategy

### 5.1 API Errors
```typescript
// Axios interceptor handles:
├── 401: Redirect to login, clear auth state
├── 403: Show permission denied message
├── 404: Show not found state
├── 429: Show rate limit message
├── 500: Show generic error, log to console
└── Network: Show offline message
```

### 5.2 Component Errors
```typescript
// ErrorBoundary handles:
├── Render errors: Show fallback UI
├── Log error to console (or service)
└── Provide retry mechanism
```

### 5.3 Form Errors
```typescript
// Zod + React Hook Form handles:
├── Validation errors: Show inline messages
├── Server errors: Map to form fields
└── Unknown errors: Show toast notification
```

---

## 6. Performance Optimizations

### 6.1 Code Splitting
```typescript
// Lazy load pages
const ReportPage = lazy(() => import('./pages/analysis/ReportPage'));
const AdminDashboard = lazy(() => import('./pages/admin/AdminDashboard'));
```

### 6.2 Memoization
```typescript
// Use for expensive computations
const processedThemes = useMemo(() =>
  processThemeData(report.themes),
  [report.themes]
);

// Use for callback stability
const handleDelete = useCallback(() => {
  deleteBusiness(id);
}, [id, deleteBusiness]);
```

### 6.3 Query Optimization
```typescript
// Stale time for infrequently changing data
useQuery({
  queryKey: ['businesses'],
  queryFn: getBusinesses,
  staleTime: 5 * 60 * 1000, // 5 minutes
});

// Prefetching for better UX
queryClient.prefetchQuery({
  queryKey: ['report', businessId],
  queryFn: () => getReport(businessId),
});
```

---

## 7. Security Considerations

### 7.1 Authentication
- JWT stored in memory (Zustand) + httpOnly cookie refresh
- Token refresh on 401 responses
- Logout clears all stored data

### 7.2 XSS Prevention
- React automatically escapes rendered content
- Avoid `dangerouslySetInnerHTML`
- Sanitize any user-generated content

### 7.3 HTTPS
- All API calls over HTTPS
- Strict transport security headers

### 7.4 Input Validation
- Client-side validation with Zod
- Never trust client data (server validates)
