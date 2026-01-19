# 09 - Admin Panel Specification

## 1. Overview

The admin panel is a separate section of the application accessible only to users with the `admin` role. It provides functionality for managing users, viewing system diagnostics, and monitoring platform health.

**Route:** `/admin/*`
**Layout:** Dedicated `AdminLayout` component

---

## 2. Access Control

### 2.1 Admin Detection
```typescript
// After login, check if user is admin
const { data: profile } = useProfile();
const isAdmin = profile?.role === 'admin';

// Store in Zustand for quick access
useAuthStore.getState().setAdmin(isAdmin);
```

### 2.2 Protected Admin Routes
```typescript
// Route configuration
<Route element={<ProtectedRoute requireAdmin />}>
  <Route path="admin" element={<AdminLayout />}>
    <Route index element={<AdminDashboard />} />
    <Route path="users" element={<UserManagement />} />
    <Route path="diagnostics" element={<Diagnostics />} />
  </Route>
</Route>
```

---

## 3. Admin Layout

```typescript
// src/components/layout/AdminLayout.tsx
import { Outlet, Link, useLocation } from 'react-router-dom';
import { cn } from '@/lib/utils';
import { LayoutDashboard, Users, Server, ArrowLeft } from 'lucide-react';
import { brandConfig } from '@/config/branding.config';

const adminNav = [
  { name: 'Overview', href: '/admin', icon: LayoutDashboard },
  { name: 'Users', href: '/admin/users', icon: Users },
  { name: 'Diagnostics', href: '/admin/diagnostics', icon: Server },
];

export const AdminLayout = () => {
  const location = useLocation();

  return (
    <div className="flex min-h-screen bg-gray-100">
      {/* Sidebar */}
      <aside className="w-64 border-r bg-white">
        <div className="flex h-16 items-center border-b px-6">
          <Link to="/" className="flex items-center gap-2 text-gray-600 hover:text-gray-900">
            <ArrowLeft className="h-4 w-4" />
            <span className="text-sm">Back to App</span>
          </Link>
        </div>

        <div className="p-4">
          <div className="mb-4 text-xs font-semibold uppercase tracking-wider text-gray-400">
            Admin Panel
          </div>
          <nav className="space-y-1">
            {adminNav.map((item) => {
              const isActive = location.pathname === item.href;
              return (
                <Link
                  key={item.name}
                  to={item.href}
                  className={cn(
                    'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                    isActive
                      ? 'bg-gray-900 text-white'
                      : 'text-gray-600 hover:bg-gray-100 hover:text-gray-900'
                  )}
                >
                  <item.icon className="h-5 w-5" />
                  {item.name}
                </Link>
              );
            })}
          </nav>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 p-8">
        <div className="mx-auto max-w-6xl">
          <Outlet />
        </div>
      </main>
    </div>
  );
};
```

---

## 4. Admin Dashboard

### 4.1 Layout
```
┌─────────────────────────────────────────────────────────────────┐
│  Admin Dashboard                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  System Status                                                  │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐ │
│  │  API Status     │  │  LLM Model      │  │  Last Health    │ │
│  │  🟢 Healthy     │  │  gpt-4o-mini    │  │  Check: 2m ago  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘ │
│                                                                 │
│  Quick Actions                                                  │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  [Manage Users]      [View Diagnostics]                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  System Info                                                    │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Service: review-analyzer                                │   │
│  │  Version: 2.0                                            │   │
│  │  Environment: production                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.2 Implementation
```typescript
// src/pages/admin/AdminDashboard.tsx
import { useQuery } from '@tanstack/react-query';
import { adminService } from '@/services/admin.service';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Link } from 'react-router-dom';
import { Users, Server, CheckCircle, AlertCircle } from 'lucide-react';

export const AdminDashboard = () => {
  const { data: healthCheck, isLoading: healthLoading, error: healthError } = useQuery({
    queryKey: ['admin', 'health'],
    queryFn: adminService.healthCheck,
    refetchInterval: 60000, // Refetch every minute
  });

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-gray-900">Admin Dashboard</h1>

      {/* System Status Cards */}
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center gap-3">
              {healthError ? (
                <AlertCircle className="h-8 w-8 text-red-500" />
              ) : (
                <CheckCircle className="h-8 w-8 text-green-500" />
              )}
              <div>
                <p className="text-sm text-gray-500">API Status</p>
                <p className="text-lg font-semibold">
                  {healthError ? 'Error' : healthCheck?.status || 'Checking...'}
                </p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div>
              <p className="text-sm text-gray-500">Service</p>
              <p className="text-lg font-semibold">
                {healthCheck?.service || 'review-analyzer'}
              </p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div>
              <p className="text-sm text-gray-500">Version</p>
              <p className="text-lg font-semibold">
                {healthCheck?.version || '2.0'}
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Quick Actions */}
      <Card>
        <CardHeader>
          <CardTitle>Quick Actions</CardTitle>
        </CardHeader>
        <CardContent className="flex gap-4">
          <Button asChild>
            <Link to="/admin/users">
              <Users className="mr-2 h-4 w-4" />
              Manage Users
            </Link>
          </Button>
          <Button variant="outline" asChild>
            <Link to="/admin/diagnostics">
              <Server className="mr-2 h-4 w-4" />
              View Diagnostics
            </Link>
          </Button>
        </CardContent>
      </Card>
    </div>
  );
};
```

---

## 5. User Management

### 5.1 Layout
```
┌─────────────────────────────────────────────────────────────────┐
│  User Management                                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 🔍 Search by email...                   [Tier: All ▼]   │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Email                 │ Tier       │ Status  │ Actions │   │
│  │  ────────────────────────────────────────────────────── │   │
│  │  john@example.com      │ Free       │ Active  │ [Edit]  │   │
│  │  jane@example.com      │ Pro        │ Active  │ [Edit]  │   │
│  │  corp@enterprise.com   │ Enterprise │ Active  │ [Edit]  │   │
│  │  inactive@test.com     │ Free       │ Inactive│ [Edit]  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  Showing 4 users                                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 5.2 Implementation
```typescript
// src/pages/admin/UserManagement.tsx
import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { adminService } from '@/services/admin.service';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Badge } from '@/components/ui/badge';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from '@/components/ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';
import { Edit2, Search } from 'lucide-react';

interface User {
  email: string;
  tier: 'free' | 'pro' | 'enterprise';
  is_active: boolean;
}

// Note: Backend doesn't have a list users endpoint yet
// This would need to be added to auth_walkers.jac
const mockUsers: User[] = [
  { email: 'john@example.com', tier: 'free', is_active: true },
  { email: 'jane@example.com', tier: 'pro', is_active: true },
];

export const UserManagement = () => {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [newTier, setNewTier] = useState<string>('');
  const queryClient = useQueryClient();

  const updateMutation = useMutation({
    mutationFn: (data: { email: string; tier: string }) =>
      adminService.updateSubscription({
        target_email: data.email,
        new_tier: data.tier as 'free' | 'pro' | 'enterprise',
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin', 'users'] });
      setSelectedUser(null);
    },
  });

  const handleEditClick = (user: User) => {
    setSelectedUser(user);
    setNewTier(user.tier);
  };

  const handleSave = () => {
    if (selectedUser && newTier) {
      updateMutation.mutate({
        email: selectedUser.email,
        tier: newTier,
      });
    }
  };

  const filteredUsers = mockUsers.filter((user) =>
    user.email.toLowerCase().includes(searchTerm.toLowerCase())
  );

  const tierBadgeVariant = (tier: string) => {
    switch (tier) {
      case 'enterprise':
        return 'bg-purple-100 text-purple-800';
      case 'pro':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-semibold text-gray-900">User Management</h1>

      {/* Search */}
      <div className="flex gap-4">
        <div className="relative flex-1">
          <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
          <Input
            placeholder="Search by email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-10"
          />
        </div>
      </div>

      {/* User Table */}
      <Card>
        <CardContent className="p-0">
          <table className="w-full">
            <thead className="border-b bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-500">
                  Email
                </th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-500">
                  Tier
                </th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-500">
                  Status
                </th>
                <th className="px-4 py-3 text-left text-sm font-medium text-gray-500">
                  Actions
                </th>
              </tr>
            </thead>
            <tbody>
              {filteredUsers.map((user) => (
                <tr key={user.email} className="border-b">
                  <td className="px-4 py-3 text-sm">{user.email}</td>
                  <td className="px-4 py-3">
                    <Badge className={tierBadgeVariant(user.tier)}>
                      {user.tier}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Badge
                      variant={user.is_active ? 'default' : 'secondary'}
                    >
                      {user.is_active ? 'Active' : 'Inactive'}
                    </Badge>
                  </td>
                  <td className="px-4 py-3">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => handleEditClick(user)}
                    >
                      <Edit2 className="h-4 w-4" />
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </CardContent>
      </Card>

      {/* Edit Dialog */}
      <Dialog open={!!selectedUser} onOpenChange={() => setSelectedUser(null)}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>Edit User: {selectedUser?.email}</DialogTitle>
          </DialogHeader>

          <div className="space-y-4 py-4">
            <div>
              <label className="mb-2 block text-sm font-medium">
                Subscription Tier
              </label>
              <Select value={newTier} onValueChange={setNewTier}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="free">
                    Free (5 businesses, 10 analyses/day)
                  </SelectItem>
                  <SelectItem value="pro">
                    Pro (50 businesses, 100 analyses/day)
                  </SelectItem>
                  <SelectItem value="enterprise">
                    Enterprise (Unlimited)
                  </SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setSelectedUser(null)}>
              Cancel
            </Button>
            <Button
              onClick={handleSave}
              disabled={updateMutation.isPending}
            >
              {updateMutation.isPending ? 'Saving...' : 'Save Changes'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
};
```

---

## 6. Diagnostics Page

### 6.1 Layout
```
┌─────────────────────────────────────────────────────────────────┐
│  System Diagnostics                              [Refresh]      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Environment Variables                                          │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  LLM_MODEL:        gpt-4o-mini                          │   │
│  │  DEBUG:            false                                │   │
│  │  PORT:             8000                                 │   │
│  │  OPENAI_API_KEY:   sk-proj-abc123def...                 │   │
│  │  SERPAPI_KEY:      202df7ff9f7ac073...                  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  System Information                                             │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │  Python Version:   3.12.1 (main, Dec 20 2024)           │   │
│  │  Working Dir:      /app                                 │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Implementation
```typescript
// src/pages/admin/Diagnostics.tsx
import { useQuery } from '@tanstack/react-query';
import { adminService } from '@/services/admin.service';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Skeleton } from '@/components/ui/skeleton';
import { RefreshCw, Server, Code } from 'lucide-react';

export const Diagnostics = () => {
  const {
    data: diagnostics,
    isLoading,
    refetch,
    isFetching,
  } = useQuery({
    queryKey: ['admin', 'diagnostics'],
    queryFn: adminService.getDiagnostics,
  });

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-semibold text-gray-900">
          System Diagnostics
        </h1>
        <Button
          variant="outline"
          onClick={() => refetch()}
          disabled={isFetching}
        >
          <RefreshCw className={`mr-2 h-4 w-4 ${isFetching ? 'animate-spin' : ''}`} />
          Refresh
        </Button>
      </div>

      {/* Environment Variables */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Server className="h-5 w-5" />
            Environment Variables
          </CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-full" />
            </div>
          ) : (
            <div className="space-y-2 font-mono text-sm">
              {diagnostics?.environment &&
                Object.entries(diagnostics.environment).map(([key, value]) => (
                  <div key={key} className="flex">
                    <span className="w-40 flex-shrink-0 text-gray-500">{key}:</span>
                    <span className="text-gray-900">{value}</span>
                  </div>
                ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* System Information */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Code className="h-5 w-5" />
            System Information
          </CardTitle>
        </CardHeader>
        <CardContent>
          {isLoading ? (
            <div className="space-y-2">
              <Skeleton className="h-4 w-full" />
              <Skeleton className="h-4 w-full" />
            </div>
          ) : (
            <div className="space-y-2 font-mono text-sm">
              {diagnostics?.system_info &&
                Object.entries(diagnostics.system_info).map(([key, value]) => (
                  <div key={key} className="flex">
                    <span className="w-40 flex-shrink-0 text-gray-500">
                      {key.replace(/_/g, ' ')}:
                    </span>
                    <span className="text-gray-900">{value}</span>
                  </div>
                ))}
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
};
```

---

## 7. Admin Service

```typescript
// src/services/admin.service.ts
import { api } from './api';

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

export interface HealthCheckResponse {
  status: string;
  service: string;
  version: string;
}

export const adminService = {
  async updateSubscription(data: UpdateSubscriptionRequest): Promise<{ success: boolean }> {
    const response = await api.post('/walker/update_subscription', data);
    return response.data.data.result;
  },

  async getDiagnostics(): Promise<DiagnosticsResponse> {
    const response = await api.post('/walker/diagnostics', {});
    return response.data.data.result;
  },

  async healthCheck(): Promise<HealthCheckResponse> {
    const response = await api.post('/walker/health_check', {});
    return response.data.data.result;
  },
};
```

---

## 8. Future Admin Features (Not in MVP)

1. **User Listing Endpoint**
   - Backend needs `list_users` walker (admin only)
   - Pagination support
   - Filtering by tier, status

2. **Analytics Dashboard**
   - Total analyses per day/week/month
   - Most analyzed businesses
   - Error rate tracking
   - API latency metrics

3. **Audit Log**
   - Track admin actions
   - User activity log
   - API usage per user

4. **Bulk Operations**
   - Bulk update subscriptions
   - Export user data
   - Batch operations
