# 02 - Technology Stack

## 1. Core Framework

### 1.1 Build Tool
```
Vite 5.x
├── Lightning fast HMR
├── Native ES modules
├── Optimized production builds
└── Built-in TypeScript support
```

### 1.2 UI Framework
```
React 18.x
├── Concurrent rendering
├── Automatic batching
├── Suspense for data fetching
└── Strict mode enabled
```

### 1.3 Language
```
TypeScript 5.x
├── Strict mode enabled
├── Path aliases configured
└── Full type coverage
```

---

## 2. UI Library

### 2.1 Component Library
```
shadcn/ui
├── Built on Radix UI primitives
├── Fully customizable
├── Copy-paste components
├── Accessible by default
└── Dark mode support (optional)
```

### 2.2 Styling
```
Tailwind CSS 3.x
├── Utility-first CSS
├── Custom monochromatic theme
├── JIT compilation
└── Responsive utilities
```

---

## 3. State Management

### 3.1 Global State
```
Zustand 4.x
├── Minimal boilerplate
├── TypeScript friendly
├── Devtools support
└── Persist middleware for auth
```

### 3.2 Server State
```
TanStack Query (React Query) 5.x
├── Caching and deduplication
├── Background refetching
├── Optimistic updates
├── Loading/error states
└── Infinite queries for pagination
```

---

## 4. Routing

```
React Router 6.x
├── Nested routes
├── Layout routes
├── Protected routes
├── Lazy loading
└── Breadcrumbs support
```

---

## 5. API Communication

### 5.1 HTTP Client
```
Axios 1.x
├── Request/response interceptors
├── JWT token injection
├── Error handling
├── Request cancellation
└── Timeout configuration
```

---

## 6. Forms & Validation

### 6.1 Form Handling
```
React Hook Form 7.x
├── Uncontrolled components
├── Minimal re-renders
├── TypeScript integration
└── Field arrays
```

### 6.2 Schema Validation
```
Zod 3.x
├── TypeScript-first
├── Runtime validation
├── Custom error messages
└── Schema inference
```

---

## 7. Data Visualization

### 7.1 Charts
```
Recharts 2.x
├── Declarative API
├── Responsive containers
├── Customizable tooltips
├── Animation support
└── Types included
```

**Chart Types Needed:**
- Bar charts (sentiment distribution)
- Line charts (trends over time)
- Pie/donut charts (rating distribution)
- Radar charts (theme breakdown)

---

## 8. PDF Export

```
html2pdf.js
├── Client-side generation
├── CSS support
├── Page breaks
└── No server required

Alternative: @react-pdf/renderer
├── React components
├── More control
└── Larger bundle
```

---

## 9. Icons

```
Lucide React
├── 1000+ icons
├── Tree-shakeable
├── Consistent style
└── Customizable size/color
```

---

## 10. Development Tools

### 10.1 Linting
```
ESLint 8.x
├── @typescript-eslint
├── eslint-plugin-react
├── eslint-plugin-react-hooks
└── Prettier integration
```

### 10.2 Formatting
```
Prettier 3.x
├── Consistent formatting
├── Tailwind plugin
└── Import sorting
```

### 10.3 Git Hooks
```
Husky + lint-staged
├── Pre-commit linting
├── Type checking
└── Format on commit
```

---

## 11. Package.json Dependencies

```json
{
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.21.0",
    "@tanstack/react-query": "^5.17.0",
    "zustand": "^4.4.7",
    "axios": "^1.6.5",
    "react-hook-form": "^7.49.2",
    "@hookform/resolvers": "^3.3.3",
    "zod": "^3.22.4",
    "recharts": "^2.10.3",
    "html2pdf.js": "^0.10.1",
    "lucide-react": "^0.303.0",
    "clsx": "^2.1.0",
    "tailwind-merge": "^2.2.0",
    "class-variance-authority": "^0.7.0",
    "date-fns": "^3.2.0"
  },
  "devDependencies": {
    "@types/react": "^18.2.47",
    "@types/react-dom": "^18.2.18",
    "@vitejs/plugin-react": "^4.2.1",
    "typescript": "^5.3.3",
    "vite": "^5.0.11",
    "tailwindcss": "^3.4.1",
    "postcss": "^8.4.33",
    "autoprefixer": "^10.4.16",
    "eslint": "^8.56.0",
    "@typescript-eslint/eslint-plugin": "^6.18.1",
    "@typescript-eslint/parser": "^6.18.1",
    "prettier": "^3.2.2",
    "prettier-plugin-tailwindcss": "^0.5.11"
  }
}
```

---

## 12. Browser Support

| Browser | Version |
|---------|---------|
| Chrome | Last 2 versions |
| Firefox | Last 2 versions |
| Safari | Last 2 versions |
| Edge | Last 2 versions |
| Mobile Safari | iOS 14+ |
| Chrome Android | Last 2 versions |

---

## 13. Performance Targets

| Metric | Target |
|--------|--------|
| First Contentful Paint | < 1.5s |
| Largest Contentful Paint | < 2.5s |
| Time to Interactive | < 3.0s |
| Cumulative Layout Shift | < 0.1 |
| Bundle Size (gzipped) | < 150KB initial |
