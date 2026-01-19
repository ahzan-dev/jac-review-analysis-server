# 07 - Components Library

## 1. Component Organization

```
src/components/
├── ui/                 # shadcn/ui base components
├── layout/             # Layout components
├── report/             # Report-specific components
├── business/           # Business-related components
├── auth/               # Authentication components
└── shared/             # Shared utility components
```

---

## 2. shadcn/ui Components (Base)

Install these components from shadcn/ui:

```bash
npx shadcn-ui@latest add button
npx shadcn-ui@latest add card
npx shadcn-ui@latest add input
npx shadcn-ui@latest add label
npx shadcn-ui@latest add select
npx shadcn-ui@latest add checkbox
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add alert
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add table
npx shadcn-ui@latest add progress
npx shadcn-ui@latest add skeleton
npx shadcn-ui@latest add separator
npx shadcn-ui@latest add dropdown-menu
npx shadcn-ui@latest add tooltip
npx shadcn-ui@latest add collapsible
npx shadcn-ui@latest add accordion
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add scroll-area
```

---

## 3. Layout Components

### 3.1 MainLayout
```typescript
// src/components/layout/MainLayout.tsx
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export const MainLayout = () => {
  return (
    <div className="flex min-h-screen bg-gray-50">
      <Sidebar />
      <div className="flex flex-1 flex-col">
        <Header />
        <main className="flex-1 p-6 lg:p-8">
          <div className="mx-auto max-w-7xl">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};
```

### 3.2 Sidebar
```typescript
// src/components/layout/Sidebar.tsx
import { Link, useLocation } from 'react-router-dom';
import { cn } from '@/lib/utils';
import {
  LayoutDashboard,
  Search,
  Building2,
  MessageSquare,
  Settings,
  Shield,
} from 'lucide-react';
import { useAuthStore } from '@/store/authStore';
import { brandConfig } from '@/config/branding.config';

const navigation = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Analyze', href: '/analyze', icon: Search },
  { name: 'Businesses', href: '/businesses', icon: Building2 },
  { name: 'Settings', href: '/settings', icon: Settings },
];

const adminNavigation = [
  { name: 'Admin', href: '/admin', icon: Shield },
];

export const Sidebar = () => {
  const location = useLocation();
  const { isAdmin } = useAuthStore();

  return (
    <aside className="hidden w-64 flex-col border-r bg-white lg:flex">
      {/* Logo */}
      <div className="flex h-16 items-center border-b px-6">
        <img
          src={brandConfig.logo}
          alt={brandConfig.appName}
          className="h-8 w-auto"
        />
        <span className="ml-2 text-lg font-semibold">
          {brandConfig.appName}
        </span>
      </div>

      {/* Navigation */}
      <nav className="flex-1 space-y-1 p-4">
        {navigation.map((item) => {
          const isActive = location.pathname === item.href;
          return (
            <Link
              key={item.name}
              to={item.href}
              className={cn(
                'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-gray-100 text-gray-900'
                  : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
              )}
            >
              <item.icon className="h-5 w-5" />
              {item.name}
            </Link>
          );
        })}

        {isAdmin && (
          <>
            <div className="my-4 border-t" />
            {adminNavigation.map((item) => (
              <Link
                key={item.name}
                to={item.href}
                className={cn(
                  'flex items-center gap-3 rounded-lg px-3 py-2 text-sm font-medium transition-colors',
                  location.pathname.startsWith(item.href)
                    ? 'bg-gray-100 text-gray-900'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                )}
              >
                <item.icon className="h-5 w-5" />
                {item.name}
              </Link>
            ))}
          </>
        )}
      </nav>
    </aside>
  );
};
```

### 3.3 Header
```typescript
// src/components/layout/Header.tsx
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/store/authStore';
import { useProfile } from '@/hooks/useAuth';
import { Button } from '@/components/ui/button';
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { LogOut, Settings, User } from 'lucide-react';

export const Header = () => {
  const navigate = useNavigate();
  const { user, logout } = useAuthStore();
  const { data: profile } = useProfile();

  const initials = user?.email?.slice(0, 2).toUpperCase() || 'U';

  const handleLogout = () => {
    logout();
    navigate('/login');
  };

  return (
    <header className="flex h-16 items-center justify-between border-b bg-white px-6">
      {/* Mobile menu button would go here */}
      <div className="flex-1" />

      {/* Right side */}
      <div className="flex items-center gap-4">
        {/* Usage indicator */}
        {profile && (
          <div className="hidden text-sm text-gray-500 md:block">
            {profile.limits.analyses_today} / {profile.limits.daily_analysis_limit} analyses today
          </div>
        )}

        {/* User menu */}
        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="relative h-10 w-10 rounded-full">
              <Avatar>
                <AvatarFallback>{initials}</AvatarFallback>
              </Avatar>
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end" className="w-56">
            <div className="px-2 py-1.5">
              <p className="text-sm font-medium">{user?.email}</p>
              <p className="text-xs text-gray-500">
                {profile?.subscription || 'Free'} plan
              </p>
            </div>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={() => navigate('/settings')}>
              <Settings className="mr-2 h-4 w-4" />
              Settings
            </DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem onClick={handleLogout}>
              <LogOut className="mr-2 h-4 w-4" />
              Log out
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>
    </header>
  );
};
```

---

## 4. Shared Components

### 4.1 LoadingSpinner
```typescript
// src/components/shared/LoadingSpinner.tsx
import { cn } from '@/lib/utils';
import { Loader2 } from 'lucide-react';

interface LoadingSpinnerProps {
  size?: 'sm' | 'md' | 'lg';
  className?: string;
}

const sizes = {
  sm: 'h-4 w-4',
  md: 'h-8 w-8',
  lg: 'h-12 w-12',
};

export const LoadingSpinner = ({ size = 'md', className }: LoadingSpinnerProps) => {
  return (
    <Loader2 className={cn('animate-spin text-gray-400', sizes[size], className)} />
  );
};
```

### 4.2 EmptyState
```typescript
// src/components/shared/EmptyState.tsx
import { ReactNode } from 'react';
import { Button } from '@/components/ui/button';

interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}

export const EmptyState = ({ icon, title, description, action }: EmptyStateProps) => {
  return (
    <div className="flex flex-col items-center justify-center py-12 text-center">
      {icon && (
        <div className="mb-4 text-gray-400">
          {icon}
        </div>
      )}
      <h3 className="text-lg font-medium text-gray-900">{title}</h3>
      <p className="mt-1 text-sm text-gray-500">{description}</p>
      {action && (
        <Button onClick={action.onClick} className="mt-4">
          {action.label}
        </Button>
      )}
    </div>
  );
};
```

### 4.3 PageHeader
```typescript
// src/components/shared/PageHeader.tsx
import { ReactNode } from 'react';

interface PageHeaderProps {
  title: string;
  description?: string;
  action?: ReactNode;
}

export const PageHeader = ({ title, description, action }: PageHeaderProps) => {
  return (
    <div className="mb-8 flex items-center justify-between">
      <div>
        <h1 className="text-2xl font-semibold text-gray-900">{title}</h1>
        {description && (
          <p className="mt-1 text-sm text-gray-500">{description}</p>
        )}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
};
```

### 4.4 ConfirmDialog
```typescript
// src/components/shared/ConfirmDialog.tsx
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog';

interface ConfirmDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  title: string;
  description: string;
  confirmLabel?: string;
  cancelLabel?: string;
  onConfirm: () => void;
  variant?: 'default' | 'destructive';
}

export const ConfirmDialog = ({
  open,
  onOpenChange,
  title,
  description,
  confirmLabel = 'Confirm',
  cancelLabel = 'Cancel',
  onConfirm,
  variant = 'default',
}: ConfirmDialogProps) => {
  return (
    <AlertDialog open={open} onOpenChange={onOpenChange}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{title}</AlertDialogTitle>
          <AlertDialogDescription>{description}</AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel>{cancelLabel}</AlertDialogCancel>
          <AlertDialogAction
            onClick={onConfirm}
            className={variant === 'destructive' ? 'bg-red-600 hover:bg-red-700' : ''}
          >
            {confirmLabel}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  );
};
```

### 4.5 StatCard
```typescript
// src/components/shared/StatCard.tsx
import { Card, CardContent } from '@/components/ui/card';
import { Progress } from '@/components/ui/progress';
import { ReactNode } from 'react';

interface StatCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  progress?: {
    current: number;
    max: number;
  };
  icon?: ReactNode;
  action?: ReactNode;
}

export const StatCard = ({
  title,
  value,
  subtitle,
  progress,
  icon,
  action,
}: StatCardProps) => {
  const progressPercent = progress
    ? Math.round((progress.current / progress.max) * 100)
    : undefined;

  return (
    <Card>
      <CardContent className="p-6">
        <div className="flex items-start justify-between">
          <div>
            <p className="text-sm font-medium text-gray-500">{title}</p>
            <p className="mt-1 text-2xl font-semibold text-gray-900">{value}</p>
            {subtitle && (
              <p className="mt-1 text-sm text-gray-500">{subtitle}</p>
            )}
          </div>
          {icon && <div className="text-gray-400">{icon}</div>}
        </div>

        {progress && (
          <div className="mt-4">
            <Progress value={progressPercent} className="h-2" />
            <p className="mt-1 text-xs text-gray-500">
              {progress.current} of {progress.max}
            </p>
          </div>
        )}

        {action && <div className="mt-4">{action}</div>}
      </CardContent>
    </Card>
  );
};
```

---

## 5. Business Components

### 5.1 BusinessCard
```typescript
// src/components/business/BusinessCard.tsx
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Star, MapPin, Trash2, RefreshCw, Eye } from 'lucide-react';
import { formatDistanceToNow } from 'date-fns';
import { Business } from '@/types/business.types';

interface BusinessCardProps {
  business: Business;
  onViewReport: (id: string) => void;
  onRefresh: (id: string) => void;
  onDelete: (id: string) => void;
  isDeleting?: boolean;
  isRefreshing?: boolean;
}

export const BusinessCard = ({
  business,
  onViewReport,
  onRefresh,
  onDelete,
  isDeleting,
  isRefreshing,
}: BusinessCardProps) => {
  return (
    <Card>
      <CardContent className="p-4">
        <div className="flex items-start justify-between">
          <div className="flex-1">
            <h3 className="font-medium text-gray-900">{business.name}</h3>
            <p className="mt-1 flex items-center gap-1 text-sm text-gray-500">
              <MapPin className="h-3 w-3" />
              {business.address}
            </p>
          </div>
          <Badge variant="outline">{business.business_type}</Badge>
        </div>

        <div className="mt-4 flex items-center gap-4 text-sm">
          <div className="flex items-center gap-1">
            <Star className="h-4 w-4 fill-yellow-400 text-yellow-400" />
            <span className="font-medium">{business.rating}</span>
            <span className="text-gray-500">
              ({business.total_reviews.toLocaleString()} reviews)
            </span>
          </div>
        </div>

        <div className="mt-2 text-xs text-gray-500">
          Last analyzed {formatDistanceToNow(new Date(business.last_analyzed_at))} ago
        </div>

        <div className="mt-4 flex gap-2">
          <Button
            size="sm"
            onClick={() => onViewReport(business.place_id)}
          >
            <Eye className="mr-1 h-4 w-4" />
            View Report
          </Button>
          <Button
            size="sm"
            variant="outline"
            onClick={() => onRefresh(business.place_id)}
            disabled={isRefreshing}
          >
            <RefreshCw className={`mr-1 h-4 w-4 ${isRefreshing ? 'animate-spin' : ''}`} />
            Refresh
          </Button>
          <Button
            size="sm"
            variant="ghost"
            onClick={() => onDelete(business.place_id)}
            disabled={isDeleting}
            className="text-red-600 hover:bg-red-50 hover:text-red-700"
          >
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </CardContent>
    </Card>
  );
};
```

---

## 6. Form Components

### 6.1 UrlInput
```typescript
// src/components/shared/UrlInput.tsx
import { forwardRef } from 'react';
import { Input } from '@/components/ui/input';
import { cn } from '@/lib/utils';
import { Link } from 'lucide-react';

interface UrlInputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  error?: string;
}

export const UrlInput = forwardRef<HTMLInputElement, UrlInputProps>(
  ({ className, error, ...props }, ref) => {
    return (
      <div className="relative">
        <Link className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
        <Input
          ref={ref}
          type="url"
          className={cn(
            'pl-10',
            error && 'border-red-500 focus-visible:ring-red-500',
            className
          )}
          {...props}
        />
        {error && (
          <p className="mt-1 text-sm text-red-500">{error}</p>
        )}
      </div>
    );
  }
);

UrlInput.displayName = 'UrlInput';
```

---

## 7. Chart Components

### 7.1 SentimentPieChart
```typescript
// src/components/charts/SentimentPieChart.tsx
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';

interface SentimentPieChartProps {
  data: {
    positive: { count: number; percentage: number };
    negative: { count: number; percentage: number };
    neutral: { count: number; percentage: number };
  };
}

const COLORS = {
  positive: '#22c55e',
  neutral: '#94a3b8',
  negative: '#ef4444',
};

export const SentimentPieChart = ({ data }: SentimentPieChartProps) => {
  const chartData = [
    { name: 'Positive', value: data.positive.count, percentage: data.positive.percentage },
    { name: 'Neutral', value: data.neutral.count, percentage: data.neutral.percentage },
    { name: 'Negative', value: data.negative.count, percentage: data.negative.percentage },
  ];

  return (
    <ResponsiveContainer width="100%" height={200}>
      <PieChart>
        <Pie
          data={chartData}
          cx="50%"
          cy="50%"
          innerRadius={50}
          outerRadius={80}
          paddingAngle={2}
          dataKey="value"
        >
          {chartData.map((entry, index) => (
            <Cell
              key={`cell-${index}`}
              fill={COLORS[entry.name.toLowerCase() as keyof typeof COLORS]}
            />
          ))}
        </Pie>
        <Tooltip
          formatter={(value, name, props) => [
            `${props.payload.percentage}% (${value})`,
            name,
          ]}
        />
        <Legend />
      </PieChart>
    </ResponsiveContainer>
  );
};
```

### 7.2 TrendLineChart
```typescript
// src/components/charts/TrendLineChart.tsx
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';
import { MonthlyTrend } from '@/types/report.types';

interface TrendLineChartProps {
  data: MonthlyTrend[];
}

export const TrendLineChart = ({ data }: TrendLineChartProps) => {
  const chartData = data.map((item) => ({
    month: item.month,
    sentiment: Math.round(item.sentiment * 100),
    rating: item.avg_rating,
    reviews: item.review_count,
  }));

  return (
    <ResponsiveContainer width="100%" height={300}>
      <LineChart data={chartData}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
        <XAxis dataKey="month" tick={{ fontSize: 12 }} />
        <YAxis
          yAxisId="left"
          domain={[0, 100]}
          tick={{ fontSize: 12 }}
          label={{ value: 'Sentiment %', angle: -90, position: 'insideLeft' }}
        />
        <YAxis
          yAxisId="right"
          orientation="right"
          domain={[1, 5]}
          tick={{ fontSize: 12 }}
          label={{ value: 'Rating', angle: 90, position: 'insideRight' }}
        />
        <Tooltip />
        <Line
          yAxisId="left"
          type="monotone"
          dataKey="sentiment"
          stroke="#3b82f6"
          strokeWidth={2}
          dot={{ r: 4 }}
          name="Sentiment"
        />
        <Line
          yAxisId="right"
          type="monotone"
          dataKey="rating"
          stroke="#22c55e"
          strokeWidth={2}
          dot={{ r: 4 }}
          name="Rating"
        />
      </LineChart>
    </ResponsiveContainer>
  );
};
```

---

## 8. Component Guidelines

### 8.1 Naming Conventions
- PascalCase for components: `BusinessCard.tsx`
- camelCase for hooks: `useReport.ts`
- kebab-case for utilities: `format-date.ts`

### 8.2 File Structure
```typescript
// Component file structure
import { ... } from 'react';           // React imports
import { ... } from 'react-router-dom'; // Third-party imports
import { ... } from '@/components/ui';  // Internal UI imports
import { ... } from '@/hooks';          // Hooks
import { ... } from '@/types';          // Types
import { cn } from '@/lib/utils';       // Utilities

// Types/Interfaces
interface ComponentProps { ... }

// Component
export const Component = ({ ... }: ComponentProps) => {
  // Hooks
  // State
  // Effects
  // Handlers
  // Render
};
```

### 8.3 Accessibility
- All interactive elements must be keyboard accessible
- Use semantic HTML elements
- Provide aria-labels for icon-only buttons
- Ensure sufficient color contrast (4.5:1 minimum)
- Support screen readers with proper ARIA attributes
