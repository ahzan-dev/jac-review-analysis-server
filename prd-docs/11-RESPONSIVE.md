# 11 - Responsive Design

## 1. Breakpoint System

### 1.1 Tailwind Default Breakpoints
```typescript
// Breakpoint reference
const breakpoints = {
  sm: '640px',   // Small tablets, large phones landscape
  md: '768px',   // Tablets
  lg: '1024px',  // Small laptops
  xl: '1280px',  // Desktops
  '2xl': '1536px', // Large screens
};
```

### 1.2 Design Targets
| Device | Breakpoint | Layout |
|--------|------------|--------|
| Mobile | < 640px | Single column, stacked |
| Tablet | 640px - 1023px | Two columns, compact nav |
| Desktop | 1024px+ | Full layout, sidebar |

---

## 2. Layout Adaptations

### 2.1 Main Layout Responsive
```typescript
// src/components/layout/MainLayout.tsx
import { useState, useEffect } from 'react';
import { Outlet } from 'react-router-dom';
import { Menu, X } from 'lucide-react';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { Button } from '@/components/ui/button';
import { Sheet, SheetContent, SheetTrigger } from '@/components/ui/sheet';

export const MainLayout = () => {
  const [isMobile, setIsMobile] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  useEffect(() => {
    const checkMobile = () => setIsMobile(window.innerWidth < 1024);
    checkMobile();
    window.addEventListener('resize', checkMobile);
    return () => window.removeEventListener('resize', checkMobile);
  }, []);

  return (
    <div className="min-h-screen bg-background">
      {/* Mobile Header with Hamburger */}
      <header className="sticky top-0 z-50 border-b bg-background/95 backdrop-blur lg:hidden">
        <div className="flex h-14 items-center justify-between px-4">
          <Sheet open={sidebarOpen} onOpenChange={setSidebarOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon">
                <Menu className="h-5 w-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-64 p-0">
              <Sidebar onNavigate={() => setSidebarOpen(false)} />
            </SheetContent>
          </Sheet>

          <span className="font-semibold">Review Analyzer</span>

          <div className="w-10" /> {/* Spacer for balance */}
        </div>
      </header>

      <div className="flex">
        {/* Desktop Sidebar */}
        <aside className="hidden w-64 shrink-0 border-r lg:block">
          <Sidebar />
        </aside>

        {/* Main Content */}
        <main className="flex-1">
          <Header className="hidden lg:flex" />
          <div className="p-4 md:p-6 lg:p-8">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
};
```

### 2.2 Mobile Navigation
```typescript
// src/components/layout/MobileNav.tsx
import { Link, useLocation } from 'react-router-dom';
import { Home, Search, Building2, User } from 'lucide-react';

const navItems = [
  { icon: Home, label: 'Home', path: '/' },
  { icon: Search, label: 'Analyze', path: '/analyze' },
  { icon: Building2, label: 'Business', path: '/businesses' },
  { icon: User, label: 'Profile', path: '/profile' },
];

export const MobileNav = () => {
  const location = useLocation();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 border-t bg-background lg:hidden">
      <div className="flex h-16 items-center justify-around">
        {navItems.map(({ icon: Icon, label, path }) => {
          const isActive = location.pathname === path;
          return (
            <Link
              key={path}
              to={path}
              className={`flex flex-col items-center gap-1 px-3 py-2 text-xs ${
                isActive
                  ? 'text-primary'
                  : 'text-muted-foreground hover:text-foreground'
              }`}
            >
              <Icon className="h-5 w-5" />
              <span>{label}</span>
            </Link>
          );
        })}
      </div>
    </nav>
  );
};
```

---

## 3. Component Responsive Patterns

### 3.1 Dashboard Grid
```typescript
// Responsive grid for dashboard cards
<div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
  <StatsCard title="Analyses Today" value={stats.analysesToday} />
  <StatsCard title="Businesses" value={stats.totalBusinesses} />
  <StatsCard title="Remaining" value={stats.remaining} />
  <StatsCard title="Subscription" value={stats.tier} />
</div>
```

### 3.2 Report Layout
```typescript
// src/pages/analysis/ReportPage.tsx - Responsive sections

// Two-column on desktop, stacked on mobile
<div className="grid gap-6 lg:grid-cols-3">
  {/* Business Info - Full width on mobile, 1/3 on desktop */}
  <div className="lg:col-span-1">
    <BusinessInfoCard business={report.business} />
  </div>

  {/* Health Score - Full width on mobile, 2/3 on desktop */}
  <div className="lg:col-span-2">
    <HealthScoreCard score={report.health_score} />
  </div>
</div>

// Responsive tabs that become scrollable on mobile
<Tabs defaultValue="themes" className="w-full">
  <TabsList className="w-full justify-start overflow-x-auto">
    <TabsTrigger value="themes">Themes</TabsTrigger>
    <TabsTrigger value="recommendations">Recommendations</TabsTrigger>
    <TabsTrigger value="swot">SWOT</TabsTrigger>
    <TabsTrigger value="trends">Trends</TabsTrigger>
  </TabsList>
  {/* Tab content */}
</Tabs>
```

### 3.3 Table to Cards Pattern
```typescript
// src/components/shared/ResponsiveTable.tsx
interface Column<T> {
  key: keyof T;
  label: string;
  render?: (value: T[keyof T], row: T) => React.ReactNode;
}

interface ResponsiveTableProps<T> {
  data: T[];
  columns: Column<T>[];
  onRowClick?: (row: T) => void;
}

export function ResponsiveTable<T extends { id: string }>({
  data,
  columns,
  onRowClick,
}: ResponsiveTableProps<T>) {
  return (
    <>
      {/* Desktop Table */}
      <div className="hidden md:block">
        <Table>
          <TableHeader>
            <TableRow>
              {columns.map((col) => (
                <TableHead key={String(col.key)}>{col.label}</TableHead>
              ))}
            </TableRow>
          </TableHeader>
          <TableBody>
            {data.map((row) => (
              <TableRow
                key={row.id}
                onClick={() => onRowClick?.(row)}
                className={onRowClick ? 'cursor-pointer hover:bg-muted' : ''}
              >
                {columns.map((col) => (
                  <TableCell key={String(col.key)}>
                    {col.render
                      ? col.render(row[col.key], row)
                      : String(row[col.key])}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>

      {/* Mobile Cards */}
      <div className="space-y-3 md:hidden">
        {data.map((row) => (
          <Card
            key={row.id}
            onClick={() => onRowClick?.(row)}
            className={onRowClick ? 'cursor-pointer active:bg-muted' : ''}
          >
            <CardContent className="p-4">
              {columns.map((col) => (
                <div key={String(col.key)} className="flex justify-between py-1">
                  <span className="text-sm text-muted-foreground">
                    {col.label}
                  </span>
                  <span className="text-sm font-medium">
                    {col.render
                      ? col.render(row[col.key], row)
                      : String(row[col.key])}
                  </span>
                </div>
              ))}
            </CardContent>
          </Card>
        ))}
      </div>
    </>
  );
}
```

### 3.4 Responsive Charts
```typescript
// src/components/charts/ResponsiveChart.tsx
import { ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip } from 'recharts';

interface ResponsiveChartProps {
  data: Array<{ name: string; value: number }>;
}

export const ResponsiveBarChart = ({ data }: ResponsiveChartProps) => {
  return (
    <div className="h-64 w-full sm:h-80">
      <ResponsiveContainer width="100%" height="100%">
        <BarChart
          data={data}
          layout="vertical"
          margin={{ top: 5, right: 30, left: 20, bottom: 5 }}
        >
          <XAxis type="number" hide />
          <YAxis
            type="category"
            dataKey="name"
            width={80}
            tick={{ fontSize: 12 }}
          />
          <Tooltip />
          <Bar dataKey="value" fill="hsl(var(--primary))" radius={[0, 4, 4, 0]} />
        </BarChart>
      </ResponsiveContainer>
    </div>
  );
};
```

---

## 4. Touch Interactions

### 4.1 Touch-Friendly Buttons
```typescript
// Minimum touch target: 44x44px
<Button className="min-h-[44px] min-w-[44px]">
  Submit
</Button>

// Icon buttons with proper touch targets
<Button variant="ghost" size="icon" className="h-11 w-11">
  <Settings className="h-5 w-5" />
</Button>
```

### 4.2 Swipe Actions (Optional)
```typescript
// src/components/shared/SwipeableCard.tsx
import { useSwipeable } from 'react-swipeable';

interface SwipeableCardProps {
  children: React.ReactNode;
  onSwipeLeft?: () => void;
  onSwipeRight?: () => void;
}

export const SwipeableCard = ({
  children,
  onSwipeLeft,
  onSwipeRight,
}: SwipeableCardProps) => {
  const handlers = useSwipeable({
    onSwipedLeft: onSwipeLeft,
    onSwipedRight: onSwipeRight,
    trackMouse: false,
    trackTouch: true,
  });

  return (
    <div {...handlers} className="touch-pan-y">
      {children}
    </div>
  );
};
```

---

## 5. Form Adaptations

### 5.1 Responsive Form Layout
```typescript
// Analysis form - full width inputs on mobile
<form className="space-y-4">
  <div className="space-y-2">
    <Label htmlFor="url">Google Maps URL</Label>
    <Input
      id="url"
      placeholder="https://maps.google.com/..."
      className="w-full"
    />
  </div>

  {/* Settings row - stacked on mobile, inline on desktop */}
  <div className="flex flex-col gap-4 sm:flex-row sm:items-end">
    <div className="flex-1 space-y-2">
      <Label>Max Reviews</Label>
      <Select defaultValue="100">
        <SelectTrigger>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="50">50 reviews</SelectItem>
          <SelectItem value="100">100 reviews</SelectItem>
          <SelectItem value="200">200 reviews</SelectItem>
        </SelectContent>
      </Select>
    </div>

    <div className="flex-1 space-y-2">
      <Label>Analysis Depth</Label>
      <Select defaultValue="deep">
        <SelectTrigger>
          <SelectValue />
        </SelectTrigger>
        <SelectContent>
          <SelectItem value="quick">Quick</SelectItem>
          <SelectItem value="standard">Standard</SelectItem>
          <SelectItem value="deep">Deep</SelectItem>
        </SelectContent>
      </Select>
    </div>
  </div>

  <Button type="submit" className="w-full sm:w-auto">
    Analyze
  </Button>
</form>
```

### 5.2 Mobile-Optimized Dialogs
```typescript
// Use drawer on mobile, dialog on desktop
import { useMediaQuery } from '@/hooks/useMediaQuery';
import { Dialog, DialogContent } from '@/components/ui/dialog';
import { Drawer, DrawerContent } from '@/components/ui/drawer';

interface ResponsiveModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  children: React.ReactNode;
}

export const ResponsiveModal = ({
  open,
  onOpenChange,
  children,
}: ResponsiveModalProps) => {
  const isDesktop = useMediaQuery('(min-width: 768px)');

  if (isDesktop) {
    return (
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="max-w-lg">{children}</DialogContent>
      </Dialog>
    );
  }

  return (
    <Drawer open={open} onOpenChange={onOpenChange}>
      <DrawerContent className="px-4 pb-8">{children}</DrawerContent>
    </Drawer>
  );
};
```

---

## 6. Utility Hooks

### 6.1 useMediaQuery
```typescript
// src/hooks/useMediaQuery.ts
import { useState, useEffect } from 'react';

export const useMediaQuery = (query: string): boolean => {
  const [matches, setMatches] = useState(false);

  useEffect(() => {
    const media = window.matchMedia(query);
    setMatches(media.matches);

    const listener = (e: MediaQueryListEvent) => setMatches(e.matches);
    media.addEventListener('change', listener);

    return () => media.removeEventListener('change', listener);
  }, [query]);

  return matches;
};

// Usage
const isMobile = useMediaQuery('(max-width: 639px)');
const isTablet = useMediaQuery('(min-width: 640px) and (max-width: 1023px)');
const isDesktop = useMediaQuery('(min-width: 1024px)');
```

### 6.2 useBreakpoint
```typescript
// src/hooks/useBreakpoint.ts
import { useState, useEffect } from 'react';

type Breakpoint = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | '2xl';

const breakpoints = {
  xs: 0,
  sm: 640,
  md: 768,
  lg: 1024,
  xl: 1280,
  '2xl': 1536,
};

export const useBreakpoint = (): Breakpoint => {
  const [breakpoint, setBreakpoint] = useState<Breakpoint>('xs');

  useEffect(() => {
    const handleResize = () => {
      const width = window.innerWidth;
      if (width >= breakpoints['2xl']) setBreakpoint('2xl');
      else if (width >= breakpoints.xl) setBreakpoint('xl');
      else if (width >= breakpoints.lg) setBreakpoint('lg');
      else if (width >= breakpoints.md) setBreakpoint('md');
      else if (width >= breakpoints.sm) setBreakpoint('sm');
      else setBreakpoint('xs');
    };

    handleResize();
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return breakpoint;
};
```

---

## 7. Performance Considerations

### 7.1 Lazy Loading for Mobile
```typescript
// Lazy load heavy components
const ReportCharts = lazy(() => import('@/components/report/ReportCharts'));
const JsonViewer = lazy(() => import('@/components/shared/JsonViewer'));

// Usage with suspense
<Suspense fallback={<Skeleton className="h-64 w-full" />}>
  <ReportCharts data={report} />
</Suspense>
```

### 7.2 Conditional Rendering
```typescript
// Don't render complex charts on mobile initially
const isMobile = useMediaQuery('(max-width: 639px)');

{!isMobile && <DetailedTrendChart data={trends} />}
{isMobile && <SimpleTrendList data={trends} />}
```

### 7.3 Image Optimization
```typescript
// Responsive images
<img
  src="/logo.svg"
  alt="Logo"
  className="h-8 w-auto sm:h-10"
  loading="lazy"
/>

// Picture element for different sizes
<picture>
  <source media="(min-width: 1024px)" srcSet="/hero-desktop.webp" />
  <source media="(min-width: 640px)" srcSet="/hero-tablet.webp" />
  <img src="/hero-mobile.webp" alt="Hero" className="w-full" />
</picture>
```

---

## 8. Testing Responsive Layouts

### 8.1 Device Presets
```typescript
// Common device widths for testing
const deviceWidths = {
  'iPhone SE': 375,
  'iPhone 12': 390,
  'iPhone 12 Pro Max': 428,
  'iPad Mini': 768,
  'iPad Pro': 1024,
  'MacBook Air': 1280,
  'Desktop': 1440,
  'Large Desktop': 1920,
};
```

### 8.2 Visual Regression Testing
```typescript
// playwright.config.ts
export default {
  projects: [
    { name: 'Mobile', use: { viewport: { width: 375, height: 812 } } },
    { name: 'Tablet', use: { viewport: { width: 768, height: 1024 } } },
    { name: 'Desktop', use: { viewport: { width: 1280, height: 720 } } },
  ],
};
```

---

## 9. Responsive Checklist

### Pages
- [ ] Dashboard adapts from 4-column to single column
- [ ] Analysis form inputs stack on mobile
- [ ] Report sections collapse to accordion on mobile
- [ ] Business list uses cards on mobile, table on desktop
- [ ] Admin panel is functional on tablet+

### Components
- [ ] Sidebar collapses to hamburger menu on mobile
- [ ] Bottom navigation appears on mobile
- [ ] Modals become bottom sheets on mobile
- [ ] Tables transform to card lists on mobile
- [ ] Charts resize appropriately

### Typography
- [ ] Headings scale down on mobile
- [ ] Body text remains readable (16px minimum)
- [ ] Line lengths don't exceed ~75 characters

### Touch
- [ ] All buttons meet 44px minimum touch target
- [ ] Adequate spacing between interactive elements
- [ ] No hover-only interactions on mobile

### Performance
- [ ] Images lazy loaded
- [ ] Heavy components code-split
- [ ] Simplified visualizations on mobile
