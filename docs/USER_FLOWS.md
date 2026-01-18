# Review Analyzer - User Flows & Production Checklist

## Table of Contents
1. [Authentication & User Management](#1-authentication--user-management)
2. [Analysis Flows](#2-analysis-flows)
3. [Report Retrieval](#3-report-retrieval)
4. [Caching & Freshness System](#4-caching--freshness-system)
5. [Admin Operations](#5-admin-operations)
6. [API Endpoints Summary](#6-api-endpoints-summary)
7. [Production Checklist](#7-production-checklist)

---

## 1. Authentication & User Management

### Flow 1.1: User Registration & Profile Creation

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  POST /user/    │────▶│  JWT Token      │────▶│  POST /walker/  │
│  register       │     │  Generated      │     │  create_user_   │
│  {email, pass}  │     │                 │     │  profile        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  UserProfile    │
                                                │  Node Created   │
                                                │  on User Root   │
                                                └─────────────────┘
```

**API Calls:**
1. `POST /user/register` - Register new user (JAC built-in)
2. `POST /walker/create_user_profile` - Create profile with tier settings

**Request Example:**
```json
POST /walker/create_user_profile
Authorization: Bearer <jwt_token>
{
    "subscription_tier": "free"  // "free" | "pro" | "enterprise"
}
```

**Response:**
```json
{
    "status": "created",
    "tier": "free",
    "limits": {
        "businesses": 5,
        "daily_analyses": 10
    }
}
```

### Flow 1.2: User Login & Profile Retrieval

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  POST /user/    │────▶│  JWT Token      │────▶│  POST /walker/  │
│  login          │     │  Returned       │     │  get_user_      │
│  {email, pass}  │     │                 │     │  profile        │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  Profile +      │
                                                │  Usage Stats    │
                                                │  Returned       │
                                                └─────────────────┘
```

**Response Example:**
```json
{
    "status": "found",
    "role": "user",
    "subscription": "free",
    "limits": {
        "max_businesses": 5,
        "current_businesses": 2,
        "remaining_businesses": 3,
        "daily_analysis_limit": 10,
        "analyses_today": 3,
        "remaining_today": 7
    },
    "is_active": true
}
```

---

## 2. Analysis Flows

### Flow 2.1: First-Time Analysis (Fresh Fetch)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  AnalyzeUrl     │────▶│  Check Profile  │────▶│  Check Cache    │
│  {url, params}  │     │  & Limits       │     │  (Not Found)    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FULL PIPELINE (5 Stages)                     │
├─────────────────────────────────────────────────────────────────┤
│  Stage 1: DataFetcherAgent                                      │
│    └── Fetches reviews from SERP API                            │
│    └── Creates Business node + Review nodes                     │
│                                                                 │
│  Stage 2: SentimentAnalyzerAgent                                │
│    └── Batch sentiment analysis (5 reviews per LLM call)        │
│    └── Updates Review nodes with sentiment data                 │
│                                                                 │
│  Stage 3: PatternAnalyzerAgent                                  │
│    └── Creates Analysis node with health score, SWOT            │
│    └── Creates Theme nodes                                      │
│                                                                 │
│  Stage 4: ReportGeneratorAgent                                  │
│    └── Creates Report node with executive summary               │
│    └── Generates legacy recommendations                         │
│                                                                 │
│  Stage 5: RecommendationAgent                                   │
│    └── Generates brand-aware recommendations                    │
│    └── Stores in Report node (avoids future LLM calls)          │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │  Full Output    │
                        │  Returned       │
                        │  from_cache:    │
                        │  false          │
                        └─────────────────┘
```

**Request:**
```json
POST /walker/AnalyzeUrl
Authorization: Bearer <jwt_token>
{
    "url": "https://www.google.com/maps/place/...",
    "max_reviews": 100,
    "analysis_depth": "deep",
    "force_mock": false,
    "force_refresh": false,
    "freshness_days": 7
}
```

### Flow 2.2: Repeat Analysis (Cache Hit)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  AnalyzeUrl     │────▶│  Check Cache    │────▶│  Found & Fresh  │
│  (same URL)     │     │  by place_id    │     │  (< 7 days)     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                REANALYZE PIPELINE (Stages 2-5)                  │
├─────────────────────────────────────────────────────────────────┤
│  ❌ Stage 1: SKIPPED (uses cached reviews)                      │
│                                                                 │
│  ✅ Stage 2: SentimentAnalyzerAgent (on cached reviews)         │
│  ✅ Stage 3: PatternAnalyzerAgent                               │
│  ✅ Stage 4: ReportGeneratorAgent                               │
│  ✅ Stage 5: RecommendationAgent                                │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
                        ┌─────────────────┐
                        │  Full Output    │
                        │  from_cache:    │
                        │  true           │
                        │  + cache_info   │
                        └─────────────────┘
```

**Cache Info in Response:**
```json
{
    "cache_info": {
        "from_cache": true,
        "data_age_days": 3,
        "freshness_threshold_days": 7,
        "fetched_at": "2024-01-15T10:30:00",
        "message": "Using cached reviews. Use force_refresh=true to re-fetch."
    }
}
```

### Flow 2.3: Force Refresh (Stale Data / Manual Override)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  AnalyzeUrl     │────▶│  Check Cache    │────▶│  force_refresh  │
│  force_refresh: │     │  Found but...   │     │  = true OR      │
│  true           │     │                 │     │  data > 7 days  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                    FULL PIPELINE (All 5 Stages)                 │
├─────────────────────────────────────────────────────────────────┤
│  DataFetcherAgent (REFRESH MODE):                               │
│    └── Finds existing Business node                             │
│    └── Clears old Reviews, Themes, Analysis, Reports            │
│    └── Re-fetches fresh reviews from SERP API                   │
│    └── Updates Business node timestamps                         │
└─────────────────────────────────────────────────────────────────┘
```

---

## 3. Report Retrieval

### Flow 3.1: Get Stored Report (No LLM Calls)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  GetReport      │────▶│  Find Business  │────▶│  Read Stored    │
│  {business_id}  │     │  by place_id    │     │  Nodes          │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                ┌───────────────────────┴───────────────────────┐
                                │                                               │
                                ▼                                               ▼
                        ┌─────────────────┐                             ┌─────────────────┐
                        │  Business +     │                             │  Report Node    │
                        │  Analysis +     │                             │  (with stored   │
                        │  Themes         │                             │  brand-aware    │
                        │                 │                             │  recommendations)│
                        └─────────────────┘                             └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  Full Output    │
                                                │  (Instant -     │
                                                │  No LLM calls)  │
                                                └─────────────────┘
```

**Key Point:** GetReport reads stored data only - no LLM calls required.

### Flow 3.2: Reanalyze (Force Re-run Analysis)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Reanalyze      │────▶│  Find Business  │────▶│  Run Stages     │
│  {business_id}  │     │  + Reviews      │     │  2-5 on         │
│                 │     │                 │     │  existing data  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  Full Output    │
                                                │  (LLM calls for │
                                                │  fresh analysis)│
                                                └─────────────────┘
```

**Use Cases:**
- Re-run analysis after algorithm improvements
- Force sentiment recalculation with `force_sentiment: true`
- Generate new recommendations based on same reviews

---

## 4. Caching & Freshness System

### Cache Decision Flow

```
                    ┌─────────────────────────┐
                    │  AnalyzeUrl Request     │
                    │  with URL               │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  Parse URL              │
                    │  Extract place_id       │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼─────────────┐
                    │  force_mock = true?     │──────Yes──────┐
                    └───────────┬─────────────┘               │
                                │ No                          │
                    ┌───────────▼─────────────┐               │
                    │  force_refresh = true?  │──────Yes──────┤
                    └───────────┬─────────────┘               │
                                │ No                          │
                    ┌───────────▼─────────────┐               │
                    │  Business exists        │               │
                    │  with this place_id?    │               │
                    └───────────┬─────────────┘               │
                        │               │                     │
                      Yes               No                    │
                        │               │                     │
            ┌───────────▼─────────────┐ │                     │
            │  Check freshness:       │ │                     │
            │  fetched_at within      │ │                     │
            │  freshness_days?        │ │                     │
            └───────────┬─────────────┘ │                     │
                │               │       │                     │
              Yes               No      │                     │
                │               │       │                     │
    ┌───────────▼───────┐       │       │                     │
    │ ReanalyzePipeline │       └───────┴─────────────────────┤
    │ (Stages 2-5)      │                                     │
    │ from_cache: true  │                                     │
    └───────────────────┘                                     │
                                                              │
                                        ┌─────────────────────▼─────┐
                                        │ FullPipelineAgent         │
                                        │ (All 5 Stages)            │
                                        │ from_cache: false         │
                                        └───────────────────────────┘
```

### Freshness Configuration

| Parameter | Default | Description |
|-----------|---------|-------------|
| `freshness_days` | 7 | Days before data is considered stale |
| `force_refresh` | false | Bypass cache and re-fetch from API |
| `force_mock` | false | Use mock data (skips cache check) |

---

## 5. Admin Operations

### Flow 5.1: Create Admin User

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Register User  │────▶│  create_user_   │────▶│  create_admin   │
│  (normal flow)  │     │  profile        │     │  {secret_key}   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  Profile        │
                                                │  Upgraded to    │
                                                │  ADMIN role     │
                                                │  + Enterprise   │
                                                └─────────────────┘
```

**Security:** Requires `ADMIN_SETUP_SECRET` environment variable.

### Flow 5.2: Update User Subscription (Admin Only)

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Admin calls    │────▶│  Verify admin   │────▶│  Find target    │
│  update_        │     │  from OWN       │     │  user profile   │
│  subscription   │     │  profile        │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
                                                ┌─────────────────┐
                                                │  Update tier    │
                                                │  & limits       │
                                                └─────────────────┘
```

---

## 6. API Endpoints Summary

### Authentication Endpoints (JAC Built-in)
| Endpoint | Method | Description |
|----------|--------|-------------|
| `/user/register` | POST | Register new user |
| `/user/login` | POST | Login & get JWT |

### User Management Walkers
| Walker | Auth | Description |
|--------|------|-------------|
| `create_user_profile` | JWT | Create profile after registration |
| `get_user_profile` | JWT | Get profile & usage stats |
| `create_admin` | JWT + Secret | Upgrade to admin role |
| `update_subscription` | JWT (Admin) | Change user tier |

### Analysis Walkers
| Walker | Auth | Description | Output |
|--------|------|-------------|--------|
| `AnalyzeUrl` | JWT | Analyze Google Maps URL | Full Report |
| `Reanalyze` | JWT | Re-run analysis on existing data | Full Report |
| `ReanalyzePipeline` | Internal | Cache-mode analysis (Stages 2-5) | Full Report |

### Data Retrieval Walkers
| Walker | Auth | Description | LLM Calls |
|--------|------|-------------|-----------|
| `GetReport` | JWT | Get stored report | None |
| `GetReviews` | JWT | Get reviews with filters | None |
| `GetBusinesses` | JWT | List all businesses | None |
| `GetStats` | JWT | System statistics | None |

### Management Walkers
| Walker | Auth | Description |
|--------|------|-------------|
| `DeleteBusiness` | JWT | Delete business & related data |
| `diagnostics` | JWT (Admin) | Environment info |
| `health_check` | None | Service health |

---

## 7. Production Checklist

### Environment Variables Required

| Variable | Required | Description |
|----------|----------|-------------|
| `OPENAI_API_KEY` | Yes | For LLM calls |
| `SERPAPI_KEY` | Yes | For Google Maps data |
| `ADMIN_SETUP_SECRET` | Yes | For admin creation |
| `LLM_MODEL` | No | Default: gpt-4o-mini |
| `PORT` | No | Server port |
| `DEBUG` | No | Debug mode |

### Security Checklist

- [x] JWT authentication on all protected endpoints
- [x] User isolation via JAC's root-based access control
- [x] Admin verification from authenticated user's own profile
- [x] Rate limiting via subscription tiers
- [x] Daily analysis limits with automatic reset
- [x] Business count limits per tier
- [x] Secret key requirement for admin creation

### Data Flow Verification

- [x] AnalyzeUrl → Full output with all sections
- [x] Reanalyze → Full output (same structure as AnalyzeUrl)
- [x] ReanalyzePipeline → Full output (cache mode)
- [x] GetReport → Full output (reads stored data, no LLM)
- [x] Brand-aware recommendations stored in Report node
- [x] Caching system with configurable freshness window
- [x] Duplicate business detection by place_id

### Output Structure (All 4 Walkers Return Same Format)

```json
{
    "success": true,
    "data_source": "serpapi|mock|cache|reanalysis|stored",
    "from_cache": true|false,
    "generated_at": "ISO timestamp",

    "business": { /* Business details */ },
    "health_score": { /* Score, grade, breakdown */ },
    "sentiment": { /* Distribution, scores */ },
    "themes": [ /* Theme analysis */ ],
    "trends": { /* Monthly breakdown */ },
    "critical_issues": [ /* Issues list */ ],
    "swot": { /* Strengths, weaknesses, etc */ },

    "recommendations": {
        "brand_context": { /* Positioning info */ },
        "issue_severity_summary": "...",
        "immediate": [ /* Brand-aware recommendations */ ],
        "short_term": [ /* ... */ ],
        "long_term": [ /* ... */ ],
        "do_not": [ /* Protective recommendations */ ],
        "overall_risk_assessment": "..."
    },

    "recommendations_legacy": { /* Backward compatibility */ },
    "executive_summary": { /* Report content */ },
    "key_findings": [ /* ... */ ],
    "statistics": { /* Review stats */ },

    "usage": { /* Only in AnalyzeUrl */ },
    "cache_info": { /* Only when from_cache=true */ }
}
```

### Subscription Tiers

| Tier | Max Businesses | Daily Analyses | Notes |
|------|----------------|----------------|-------|
| Free | 5 | 10 | Default tier |
| Pro | 50 | 100 | Paid tier |
| Enterprise | Unlimited (-1) | Unlimited (-1) | Custom |

---

## Verification Summary

| Feature | Status | Location |
|---------|--------|----------|
| User registration & profiles | ✅ | auth_walkers.jac |
| JWT authentication | ✅ | All protected walkers |
| Subscription tiers & limits | ✅ | auth_walkers.jac, main.jac |
| Caching/freshness system | ✅ | main.jac:93-150 |
| RecommendationAgent in Reanalyze | ✅ | api_walkers.jac:427-430 |
| Brand-aware recs stored | ✅ | models.jac:346-353, walkers.jac:1641-1652 |
| Full output from all walkers | ✅ | main.jac, api_walkers.jac, walkers.jac |
| GetAnalysis removed | ✅ | Not in api_walkers.jac |
| Duplicate business detection | ✅ | walkers.jac:300-321 |
| Refresh mode clears old data | ✅ | walkers.jac:331-350 |

**Status: READY FOR PRODUCTION** ✅
