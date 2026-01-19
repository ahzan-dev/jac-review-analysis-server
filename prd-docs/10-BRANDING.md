# 10 - Branding & Theming

## 1. Branding Configuration

### 1.1 Configuration File
```typescript
// src/config/branding.config.ts

export interface BrandConfig {
  // Identity
  appName: string;
  tagline: string;
  logo: string;
  logoAlt: string;
  favicon: string;

  // Colors (CSS custom properties)
  colors: {
    primary: string;
    primaryForeground: string;
    secondary: string;
    secondaryForeground: string;
    accent: string;
    accentForeground: string;
    background: string;
    foreground: string;
    muted: string;
    mutedForeground: string;
    border: string;
    success: string;
    warning: string;
    destructive: string;
  };

  // Typography
  fonts: {
    heading: string;
    body: string;
    mono: string;
  };

  // Footer
  footer: {
    company: string;
    year: number;
    links: Array<{
      label: string;
      href: string;
    }>;
  };

  // Contact
  contact: {
    email: string;
    website: string;
  };
}

export const brandConfig: BrandConfig = {
  // Identity
  appName: 'Review Analyzer',
  tagline: 'AI-Powered Review Insights',
  logo: '/logo.svg',
  logoAlt: 'Review Analyzer Logo',
  favicon: '/favicon.ico',

  // Monochromatic color palette
  colors: {
    primary: '#1a1a1a',
    primaryForeground: '#ffffff',
    secondary: '#4a4a4a',
    secondaryForeground: '#ffffff',
    accent: '#0066cc',
    accentForeground: '#ffffff',
    background: '#ffffff',
    foreground: '#1a1a1a',
    muted: '#f8f9fa',
    mutedForeground: '#6c757d',
    border: '#e9ecef',
    success: '#198754',
    warning: '#ffc107',
    destructive: '#dc3545',
  },

  // Typography
  fonts: {
    heading: 'Inter, system-ui, sans-serif',
    body: 'Inter, system-ui, sans-serif',
    mono: 'JetBrains Mono, Consolas, monospace',
  },

  // Footer
  footer: {
    company: 'Your Company Name',
    year: new Date().getFullYear(),
    links: [
      { label: 'Privacy Policy', href: '/privacy' },
      { label: 'Terms of Service', href: '/terms' },
      { label: 'Contact', href: '/contact' },
    ],
  },

  // Contact
  contact: {
    email: 'support@example.com',
    website: 'https://example.com',
  },
};
```

---

## 2. Tailwind CSS Configuration

### 2.1 tailwind.config.js
```javascript
// tailwind.config.js
import { brandConfig } from './src/config/branding.config';

/** @type {import('tailwindcss').Config} */
export default {
  darkMode: ['class'],
  content: [
    './index.html',
    './src/**/*.{js,ts,jsx,tsx}',
  ],
  theme: {
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'sans-serif'],
        mono: ['JetBrains Mono', 'Consolas', 'monospace'],
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      spacing: {
        '18': '4.5rem',
        '88': '22rem',
      },
    },
  },
  plugins: [require('tailwindcss-animate')],
};
```

### 2.2 CSS Variables (globals.css)
```css
/* src/styles/globals.css */
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    /* Monochromatic palette */
    --background: 0 0% 100%;
    --foreground: 0 0% 10%;

    --card: 0 0% 100%;
    --card-foreground: 0 0% 10%;

    --primary: 0 0% 10%;
    --primary-foreground: 0 0% 100%;

    --secondary: 0 0% 96%;
    --secondary-foreground: 0 0% 10%;

    --muted: 0 0% 96%;
    --muted-foreground: 0 0% 45%;

    --accent: 214 100% 40%;
    --accent-foreground: 0 0% 100%;

    --destructive: 0 84% 60%;
    --destructive-foreground: 0 0% 100%;

    --border: 0 0% 90%;
    --input: 0 0% 90%;
    --ring: 214 100% 40%;

    --radius: 0.5rem;
  }

  /* High white space utility classes */
  .section-spacing {
    @apply py-12 md:py-16 lg:py-20;
  }

  .container-narrow {
    @apply mx-auto max-w-4xl px-4 sm:px-6 lg:px-8;
  }

  .container-wide {
    @apply mx-auto max-w-7xl px-4 sm:px-6 lg:px-8;
  }
}

@layer base {
  * {
    @apply border-border;
  }

  body {
    @apply bg-background text-foreground;
    font-feature-settings: "rlig" 1, "calt" 1;
  }
}

/* Typography */
h1, h2, h3, h4, h5, h6 {
  @apply font-semibold tracking-tight;
}

h1 {
  @apply text-3xl md:text-4xl;
}

h2 {
  @apply text-2xl md:text-3xl;
}

h3 {
  @apply text-xl md:text-2xl;
}

/* Custom scrollbar */
::-webkit-scrollbar {
  width: 8px;
  height: 8px;
}

::-webkit-scrollbar-track {
  @apply bg-muted;
}

::-webkit-scrollbar-thumb {
  @apply bg-muted-foreground/30 rounded-full;
}

::-webkit-scrollbar-thumb:hover {
  @apply bg-muted-foreground/50;
}
```

---

## 3. Using Brand Config in Components

### 3.1 Logo Component
```typescript
// src/components/shared/Logo.tsx
import { brandConfig } from '@/config/branding.config';

interface LogoProps {
  size?: 'sm' | 'md' | 'lg';
  showText?: boolean;
}

const sizes = {
  sm: 'h-6',
  md: 'h-8',
  lg: 'h-10',
};

export const Logo = ({ size = 'md', showText = true }: LogoProps) => {
  return (
    <div className="flex items-center gap-2">
      <img
        src={brandConfig.logo}
        alt={brandConfig.logoAlt}
        className={sizes[size]}
      />
      {showText && (
        <span className="font-semibold text-foreground">
          {brandConfig.appName}
        </span>
      )}
    </div>
  );
};
```

### 3.2 Footer Component
```typescript
// src/components/layout/Footer.tsx
import { brandConfig } from '@/config/branding.config';

export const Footer = () => {
  return (
    <footer className="border-t bg-muted/50">
      <div className="container-wide py-8">
        <div className="flex flex-col items-center justify-between gap-4 md:flex-row">
          <div className="text-sm text-muted-foreground">
            © {brandConfig.footer.year} {brandConfig.footer.company}. All rights reserved.
          </div>
          <nav className="flex gap-6">
            {brandConfig.footer.links.map((link) => (
              <a
                key={link.label}
                href={link.href}
                className="text-sm text-muted-foreground hover:text-foreground"
              >
                {link.label}
              </a>
            ))}
          </nav>
        </div>
      </div>
    </footer>
  );
};
```

### 3.3 Document Title Hook
```typescript
// src/hooks/useDocumentTitle.ts
import { useEffect } from 'react';
import { brandConfig } from '@/config/branding.config';

export const useDocumentTitle = (title?: string) => {
  useEffect(() => {
    document.title = title
      ? `${title} | ${brandConfig.appName}`
      : brandConfig.appName;
  }, [title]);
};

// Usage in pages
const DashboardPage = () => {
  useDocumentTitle('Dashboard');
  // ...
};
```

---

## 4. White-Label Customization

### 4.1 Environment-Based Branding
```typescript
// src/config/branding.config.ts

// Load from environment or use defaults
export const brandConfig: BrandConfig = {
  appName: import.meta.env.VITE_APP_NAME || 'Review Analyzer',
  logo: import.meta.env.VITE_APP_LOGO || '/logo.svg',
  // ... other properties

  colors: {
    primary: import.meta.env.VITE_COLOR_PRIMARY || '#1a1a1a',
    accent: import.meta.env.VITE_COLOR_ACCENT || '#0066cc',
    // ... other colors
  },
};
```

### 4.2 .env Example
```bash
# .env.client-acme
VITE_APP_NAME="ACME Review Pro"
VITE_APP_LOGO="/acme-logo.svg"
VITE_COLOR_PRIMARY="#2563eb"
VITE_COLOR_ACCENT="#059669"
```

### 4.3 Build for Different Clients
```bash
# Build for default branding
npm run build

# Build for ACME client
cp .env.client-acme .env.local && npm run build
```

---

## 5. Design Tokens

### 5.1 Spacing Scale
```css
/* Spacing system (based on 4px grid) */
--space-1: 0.25rem;   /* 4px */
--space-2: 0.5rem;    /* 8px */
--space-3: 0.75rem;   /* 12px */
--space-4: 1rem;      /* 16px */
--space-5: 1.25rem;   /* 20px */
--space-6: 1.5rem;    /* 24px */
--space-8: 2rem;      /* 32px */
--space-10: 2.5rem;   /* 40px */
--space-12: 3rem;     /* 48px */
--space-16: 4rem;     /* 64px */
```

### 5.2 Typography Scale
```css
/* Font sizes */
--text-xs: 0.75rem;     /* 12px */
--text-sm: 0.875rem;    /* 14px */
--text-base: 1rem;      /* 16px */
--text-lg: 1.125rem;    /* 18px */
--text-xl: 1.25rem;     /* 20px */
--text-2xl: 1.5rem;     /* 24px */
--text-3xl: 1.875rem;   /* 30px */
--text-4xl: 2.25rem;    /* 36px */

/* Font weights */
--font-normal: 400;
--font-medium: 500;
--font-semibold: 600;
--font-bold: 700;

/* Line heights */
--leading-tight: 1.25;
--leading-normal: 1.5;
--leading-relaxed: 1.75;
```

### 5.3 Shadow Scale
```css
/* Shadows */
--shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
--shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
--shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
--shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
```

---

## 6. Component Styling Guidelines

### 6.1 Card Pattern
```typescript
// Consistent card styling
<Card className="bg-card shadow-sm hover:shadow-md transition-shadow">
  <CardHeader className="pb-4">
    <CardTitle className="text-lg font-semibold">{title}</CardTitle>
  </CardHeader>
  <CardContent className="pt-0">
    {children}
  </CardContent>
</Card>
```

### 6.2 Button Variants
```typescript
// Primary action
<Button>Save Changes</Button>

// Secondary action
<Button variant="outline">Cancel</Button>

// Destructive action
<Button variant="destructive">Delete</Button>

// Ghost/subtle action
<Button variant="ghost">Learn More</Button>

// Link style
<Button variant="link">View All</Button>
```

### 6.3 Form Layout
```typescript
// Consistent form spacing
<form className="space-y-6">
  <div className="space-y-2">
    <Label htmlFor="email">Email</Label>
    <Input id="email" type="email" />
    <p className="text-sm text-muted-foreground">
      We'll never share your email.
    </p>
  </div>

  <div className="space-y-2">
    <Label htmlFor="password">Password</Label>
    <Input id="password" type="password" />
  </div>

  <Button type="submit" className="w-full">
    Submit
  </Button>
</form>
```

---

## 7. Favicon and Meta Tags

### 7.1 index.html
```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <!-- Primary Meta Tags -->
    <title>Review Analyzer - AI-Powered Review Insights</title>
    <meta name="title" content="Review Analyzer - AI-Powered Review Insights" />
    <meta name="description" content="Analyze Google Maps reviews with AI to get actionable insights for your business." />

    <!-- Open Graph / Facebook -->
    <meta property="og:type" content="website" />
    <meta property="og:title" content="Review Analyzer" />
    <meta property="og:description" content="AI-Powered Review Analysis" />
    <meta property="og:image" content="/og-image.png" />

    <!-- Twitter -->
    <meta property="twitter:card" content="summary_large_image" />
    <meta property="twitter:title" content="Review Analyzer" />
    <meta property="twitter:description" content="AI-Powered Review Analysis" />
    <meta property="twitter:image" content="/og-image.png" />

    <!-- Theme Color -->
    <meta name="theme-color" content="#1a1a1a" />
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
```
