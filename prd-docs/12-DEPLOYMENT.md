# 12 - Deployment & DevOps

## 1. Environment Configuration

### 1.1 Environment Files
```bash
# .env.example (commit to repo)
VITE_API_URL=https://review-analysis-server.trynewways.com
VITE_APP_NAME=Review Analyzer
VITE_APP_VERSION=1.0.0

# .env.development (local dev)
VITE_API_URL=http://localhost:8000
VITE_APP_NAME=Review Analyzer (Dev)
VITE_APP_VERSION=dev

# .env.production (production build)
VITE_API_URL=https://review-analysis-server.trynewways.com
VITE_APP_NAME=Review Analyzer
VITE_APP_VERSION=1.0.0
```

### 1.2 Environment Type Definitions
```typescript
// src/vite-env.d.ts
/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_NAME: string;
  readonly VITE_APP_VERSION: string;
  // White-label overrides (optional)
  readonly VITE_APP_LOGO?: string;
  readonly VITE_COLOR_PRIMARY?: string;
  readonly VITE_COLOR_ACCENT?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
```

### 1.3 Config Loader
```typescript
// src/config/env.config.ts
export const envConfig = {
  apiUrl: import.meta.env.VITE_API_URL || 'http://localhost:8000',
  appName: import.meta.env.VITE_APP_NAME || 'Review Analyzer',
  appVersion: import.meta.env.VITE_APP_VERSION || 'dev',
  isDev: import.meta.env.DEV,
  isProd: import.meta.env.PROD,
} as const;
```

---

## 2. Build Configuration

### 2.1 Vite Config
```typescript
// vite.config.ts
import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  return {
    plugins: [react()],

    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
      },
    },

    build: {
      outDir: 'dist',
      sourcemap: mode !== 'production',
      minify: 'terser',
      terserOptions: {
        compress: {
          drop_console: mode === 'production',
          drop_debugger: true,
        },
      },
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom', 'react-router-dom'],
            ui: ['@radix-ui/react-dialog', '@radix-ui/react-dropdown-menu'],
            charts: ['recharts'],
          },
        },
      },
    },

    server: {
      port: 3000,
      proxy: {
        '/api': {
          target: env.VITE_API_URL || 'http://localhost:8000',
          changeOrigin: true,
          rewrite: (path) => path.replace(/^\/api/, ''),
        },
      },
    },

    preview: {
      port: 3000,
    },
  };
});
```

### 2.2 TypeScript Config
```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,

    /* Bundler mode */
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "noEmit": true,
    "jsx": "react-jsx",

    /* Linting */
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,

    /* Path aliases */
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"],
  "references": [{ "path": "./tsconfig.node.json" }]
}
```

---

## 3. Docker Configuration

### 3.1 Dockerfile
```dockerfile
# Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci

# Copy source and build
COPY . .
ARG VITE_API_URL
ARG VITE_APP_NAME
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_APP_NAME=$VITE_APP_NAME

RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy built files
COPY --from=builder /app/dist /usr/share/nginx/html

# Health check
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/health || exit 1

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

### 3.2 Nginx Config
```nginx
# nginx.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied expired no-cache no-store private auth;
    gzip_types text/plain text/css text/xml text/javascript application/x-javascript application/xml application/javascript;

    # Cache static assets
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # SPA fallback - serve index.html for all routes
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
```

### 3.3 Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  frontend:
    build:
      context: .
      args:
        VITE_API_URL: ${VITE_API_URL:-https://review-analysis-server.trynewways.com}
        VITE_APP_NAME: ${VITE_APP_NAME:-Review Analyzer}
    ports:
      - "3000:80"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3
```

---

## 4. CI/CD Pipeline

### 4.1 GitHub Actions
```yaml
# .github/workflows/deploy.yml
name: Build and Deploy

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  lint-and-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Lint
        run: npm run lint

      - name: Type check
        run: npm run type-check

      - name: Run tests
        run: npm run test -- --coverage

  build:
    needs: lint-and-test
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Build
        run: npm run build
        env:
          VITE_API_URL: ${{ secrets.VITE_API_URL }}
          VITE_APP_NAME: Review Analyzer

      - name: Upload build artifacts
        uses: actions/upload-artifact@v4
        with:
          name: dist
          path: dist/

  docker:
    needs: build
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    permissions:
      contents: read
      packages: write

    steps:
      - uses: actions/checkout@v4

      - name: Log in to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Extract metadata
        id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=sha
            type=raw,value=latest

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          labels: ${{ steps.meta.outputs.labels }}
          build-args: |
            VITE_API_URL=${{ secrets.VITE_API_URL }}
            VITE_APP_NAME=Review Analyzer

  deploy:
    needs: docker
    runs-on: ubuntu-latest
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'

    steps:
      - name: Deploy to Coolify
        run: |
          curl -X POST \
            -H "Authorization: Bearer ${{ secrets.COOLIFY_TOKEN }}" \
            -H "Content-Type: application/json" \
            "${{ secrets.COOLIFY_WEBHOOK_URL }}"
```

### 4.2 Package Scripts
```json
// package.json scripts
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx --report-unused-disable-directives --max-warnings 0",
    "lint:fix": "eslint . --ext ts,tsx --fix",
    "type-check": "tsc --noEmit",
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest --coverage",
    "docker:build": "docker build -t review-analyzer-frontend .",
    "docker:run": "docker run -p 3000:80 review-analyzer-frontend"
  }
}
```

---

## 5. Hosting Options

### 5.1 Coolify (Recommended)
```yaml
# coolify configuration
# Set these in Coolify dashboard:
# - Build Command: npm run build
# - Output Directory: dist
# - Node Version: 20

# Environment Variables (in Coolify):
VITE_API_URL=https://review-analysis-server.trynewways.com
VITE_APP_NAME=Review Analyzer
```

### 5.2 Vercel
```json
// vercel.json
{
  "buildCommand": "npm run build",
  "outputDirectory": "dist",
  "framework": "vite",
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ],
  "headers": [
    {
      "source": "/assets/(.*)",
      "headers": [
        { "key": "Cache-Control", "value": "public, max-age=31536000, immutable" }
      ]
    }
  ]
}
```

### 5.3 Netlify
```toml
# netlify.toml
[build]
  command = "npm run build"
  publish = "dist"

[[redirects]]
  from = "/*"
  to = "/index.html"
  status = 200

[[headers]]
  for = "/assets/*"
  [headers.values]
    Cache-Control = "public, max-age=31536000, immutable"
```

### 5.4 AWS S3 + CloudFront
```yaml
# cloudformation-frontend.yml (excerpt)
Resources:
  S3Bucket:
    Type: AWS::S3::Bucket
    Properties:
      BucketName: review-analyzer-frontend
      WebsiteConfiguration:
        IndexDocument: index.html
        ErrorDocument: index.html

  CloudFrontDistribution:
    Type: AWS::CloudFront::Distribution
    Properties:
      DistributionConfig:
        Origins:
          - DomainName: !GetAtt S3Bucket.RegionalDomainName
            Id: S3Origin
            S3OriginConfig:
              OriginAccessIdentity: ''
        DefaultCacheBehavior:
          TargetOriginId: S3Origin
          ViewerProtocolPolicy: redirect-to-https
          CachePolicyId: 658327ea-f89d-4fab-a63d-7e88639e58f6
        CustomErrorResponses:
          - ErrorCode: 404
            ResponseCode: 200
            ResponsePagePath: /index.html
```

---

## 6. Monitoring & Analytics

### 6.1 Error Tracking (Sentry)
```typescript
// src/lib/sentry.ts
import * as Sentry from '@sentry/react';

if (import.meta.env.PROD) {
  Sentry.init({
    dsn: import.meta.env.VITE_SENTRY_DSN,
    integrations: [
      Sentry.browserTracingIntegration(),
      Sentry.replayIntegration(),
    ],
    tracesSampleRate: 0.1,
    replaysSessionSampleRate: 0.1,
    replaysOnErrorSampleRate: 1.0,
  });
}

// Wrap App with ErrorBoundary
export const SentryErrorBoundary = Sentry.ErrorBoundary;
```

### 6.2 Analytics (Plausible)
```html
<!-- index.html - Privacy-friendly analytics -->
<script
  defer
  data-domain="review-analyzer.yourdomain.com"
  src="https://plausible.io/js/script.js"
></script>
```

### 6.3 Performance Monitoring
```typescript
// src/lib/performance.ts
export const reportWebVitals = () => {
  if ('performance' in window) {
    // First Contentful Paint
    const paintEntries = performance.getEntriesByType('paint');
    const fcp = paintEntries.find((e) => e.name === 'first-contentful-paint');

    if (fcp) {
      console.log('FCP:', fcp.startTime);
    }

    // Largest Contentful Paint
    const observer = new PerformanceObserver((list) => {
      const entries = list.getEntries();
      const lastEntry = entries[entries.length - 1];
      console.log('LCP:', lastEntry.startTime);
    });

    observer.observe({ type: 'largest-contentful-paint', buffered: true });
  }
};
```

---

## 7. Security Checklist

### 7.1 HTTP Security Headers
```nginx
# Already in nginx.conf, but verify:
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data: https:; font-src 'self' data:; connect-src 'self' https://review-analysis-server.trynewways.com;" always;
```

### 7.2 Environment Security
- Never commit `.env` files with real secrets
- Use GitHub Secrets for CI/CD variables
- Rotate API keys periodically
- Enable HTTPS only (redirect HTTP)

### 7.3 Build Security
```json
// package.json - audit dependencies
{
  "scripts": {
    "audit": "npm audit --production",
    "audit:fix": "npm audit fix"
  }
}
```

---

## 8. Production Checklist

### Pre-Deployment
- [ ] All environment variables configured
- [ ] API URL points to production backend
- [ ] Console logs removed (terser handles this)
- [ ] Source maps disabled for production
- [ ] Dependencies audited for vulnerabilities

### Build Verification
- [ ] `npm run build` completes without errors
- [ ] `npm run preview` works correctly
- [ ] All routes load properly
- [ ] API calls work with production backend
- [ ] Authentication flow works end-to-end

### Post-Deployment
- [ ] HTTPS certificate valid
- [ ] All pages accessible
- [ ] No console errors in browser
- [ ] Forms submit correctly
- [ ] Images and assets load
- [ ] Mobile responsiveness verified

### Monitoring Setup
- [ ] Error tracking configured (Sentry)
- [ ] Analytics enabled (Plausible/GA)
- [ ] Uptime monitoring active
- [ ] Performance baseline established

---

## 9. Rollback Procedures

### Docker Rollback
```bash
# List previous images
docker images review-analyzer-frontend

# Rollback to specific tag
docker stop frontend
docker run -d --name frontend -p 3000:80 review-analyzer-frontend:previous-sha
```

### Coolify Rollback
1. Go to Coolify dashboard
2. Select the application
3. Go to "Deployments" tab
4. Click "Rollback" on the previous successful deployment

### Manual Rollback
```bash
# If using Git-based deployment
git revert HEAD
git push origin main

# Or deploy specific commit
git checkout <commit-sha>
npm run build
# Deploy dist/ folder
```

---

## 10. Scaling Considerations

### Static Asset CDN
- Use Cloudflare or CloudFront for global distribution
- Enable asset caching with long TTL
- Purge cache on deployments

### API Optimization
- Implement request caching where appropriate
- Use React Query's stale-while-revalidate pattern
- Consider API response compression

### Bundle Optimization
```bash
# Analyze bundle size
npm install -D rollup-plugin-visualizer

# Add to vite.config.ts
import { visualizer } from 'rollup-plugin-visualizer';

plugins: [
  react(),
  visualizer({ open: true }),
]
```
