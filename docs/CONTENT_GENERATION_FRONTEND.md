# Content Generation - Frontend Implementation Guide

> **Status**: Implementation-Ready Frontend Specification
> **Last Updated**: 2026-02-07
> **Backend Plan**: `docs/CONTENT_GENERATION_PLAN.md`
> **Tech Stack**: Vite + React + TypeScript + shadcn/ui + Tailwind CSS
> **API Base**: `https://review-analysis-server.trynewways.com/`

---

## Table of Contents

1. [Overview](#1-overview)
2. [API Service Layer](#2-api-service-layer)
3. [TypeScript Types](#3-typescript-types)
4. [Page Architecture](#4-page-architecture)
5. [Feature 1: Response Template Library](#5-feature-1-response-template-library)
6. [Feature 2: Action Plan Generator](#6-feature-2-action-plan-generator)
7. [Feature 3: Social Media Post Generator](#7-feature-3-social-media-post-generator)
8. [Feature 4: Marketing Copy Generator](#8-feature-4-marketing-copy-generator)
9. [Feature 5: Blog Post Generator](#9-feature-5-blog-post-generator)
10. [Shared Components](#10-shared-components)
11. [Navigation & Routing](#11-navigation--routing)
12. [State Management](#12-state-management)
13. [UX Patterns](#13-ux-patterns)
14. [Responsive Design](#14-responsive-design)

---

## 1. Overview

### What This Document Covers

Frontend implementation for 5 content generation features that consume 22 backend API endpoints. The content generation features live within the **business detail view** - users select a business first, then generate content from its analysis data.

### Access Model

```
                        ┌──────────────────────┐
                        │   Business Dashboard  │
                        │   /businesses         │
                        └──────────┬───────────┘
                                   │ select business
                        ┌──────────▼───────────┐
                        │   Business Detail     │
                        │   /business/:id       │
                        │                       │
                        │  [Report] [Reviews]   │
                        │  [Content] [Replies]  │
                        └──────────┬───────────┘
                                   │ "Content" tab
                   ┌───────────────▼────────────────┐
                   │    Content Generation Hub       │
                   │    /business/:id/content        │
                   │                                 │
                   │  ┌─────────┐ ┌──────────────┐  │
                   │  │Templates│ │ Action Plans  │  │
                   │  └─────────┘ └──────────────┘  │
                   │  ┌─────────┐ ┌──────────────┐  │
                   │  │ Social  │ │  Marketing   │  │
                   │  │ Posts   │ │    Copy      │  │
                   │  └─────────┘ └──────────────┘  │
                   │  ┌──────────────────────────┐  │
                   │  │       Blog Posts          │  │
                   │  └──────────────────────────┘  │
                   └────────────────────────────────┘
```

### Credit Display Pattern

Every content generation action that costs credits must show:
1. **Before**: Credit cost prominently displayed on the generate button
2. **During**: Loading state with "Generating..." message
3. **After**: Success message with credits used and remaining balance

---

## 2. API Service Layer

### File: `src/services/contentApi.ts`

```typescript
import { apiClient } from './apiClient';

// ═══════════════════════════════════════════════════════════════
// RESPONSE TEMPLATES
// ═══════════════════════════════════════════════════════════════

export const templateApi = {
  getTemplates: (params?: {
    category?: string;
    scenario?: string;
    business_type?: string;
  }) => apiClient.post('/walker/GetResponseTemplates', params ?? {}),

  createTemplate: (data: {
    name: string;
    category: string;
    scenario: string;
    business_type?: string;
    template_text: string;
    tone?: string;
  }) => apiClient.post('/walker/CreateResponseTemplate', data),

  applyTemplate: (data: {
    template_id: string;
    business_id: string;
    review_id: string;
  }) => apiClient.post('/walker/ApplyTemplate', data),

  deleteTemplate: (template_id: string) =>
    apiClient.post('/walker/DeleteResponseTemplate', { template_id }),
};

// ═══════════════════════════════════════════════════════════════
// ACTION PLANS
// ═══════════════════════════════════════════════════════════════

export const actionPlanApi = {
  generate: (data: {
    business_id: string;
    timeframe?: '30_day' | '60_day' | '90_day';
    focus_areas?: string[];
  }) => apiClient.post('/walker/GenerateActionPlan', data),

  getPlans: (business_id: string) =>
    apiClient.post('/walker/GetActionPlans', { business_id }),

  deletePlan: (data: { business_id: string; plan_id: string }) =>
    apiClient.post('/walker/DeleteActionPlan', data),
};

// ═══════════════════════════════════════════════════════════════
// SOCIAL MEDIA POSTS
// ═══════════════════════════════════════════════════════════════

export const socialPostApi = {
  saveConfig: (data: {
    brand_name?: string;
    brand_voice?: string;
    default_hashtags?: string[];
    include_star_rating?: boolean;
    include_review_quote?: boolean;
    include_call_to_action?: boolean;
    call_to_action_text?: string;
  }) => apiClient.post('/walker/SaveSocialMediaPostConfig', data),

  getConfig: () =>
    apiClient.post('/walker/GetSocialMediaPostConfig', {}),

  generate: (data: {
    business_id: string;
    review_id?: string;
    platforms?: string[];
    count?: number;
  }) => apiClient.post('/walker/GenerateSocialMediaPosts', data),

  getPosts: (data: { business_id: string; platform?: string }) =>
    apiClient.post('/walker/GetSocialMediaPosts', data),

  deletePost: (data: { business_id: string; post_id: string }) =>
    apiClient.post('/walker/DeleteSocialMediaPost', data),
};

// ═══════════════════════════════════════════════════════════════
// MARKETING COPY
// ═══════════════════════════════════════════════════════════════

export const marketingCopyApi = {
  saveConfig: (data: {
    brand_name?: string;
    brand_tagline?: string;
    target_audience?: string;
    unique_selling_points?: string[];
    tone?: string;
  }) => apiClient.post('/walker/SaveMarketingCopyConfig', data),

  getConfig: () =>
    apiClient.post('/walker/GetMarketingCopyConfig', {}),

  generate: (data: {
    business_id: string;
    ad_format?: string;
    num_variants?: number;
  }) => apiClient.post('/walker/GenerateMarketingCopy', data),

  getCopies: (data: { business_id: string; ad_format?: string }) =>
    apiClient.post('/walker/GetMarketingCopies', data),

  deleteCopy: (data: { business_id: string; copy_id: string }) =>
    apiClient.post('/walker/DeleteMarketingCopy', data),
};

// ═══════════════════════════════════════════════════════════════
// BLOG POSTS
// ═══════════════════════════════════════════════════════════════

export const blogPostApi = {
  saveConfig: (data: {
    author_name?: string;
    brand_name?: string;
    writing_style?: string;
    target_word_count?: number;
    include_data_visualizations?: boolean;
    seo_focus?: boolean;
  }) => apiClient.post('/walker/SaveBlogPostConfig', data),

  getConfig: () =>
    apiClient.post('/walker/GetBlogPostConfig', {}),

  generate: (data: {
    business_id: string;
    content_type?: string;
    focus_theme?: string;
  }) => apiClient.post('/walker/GenerateBlogPost', data),

  getPosts: (data: { business_id: string; content_type?: string }) =>
    apiClient.post('/walker/GetBlogPosts', data),

  deletePost: (data: { business_id: string; post_id: string }) =>
    apiClient.post('/walker/DeleteBlogPost', data),
};
```

---

## 3. TypeScript Types

### File: `src/types/content.ts`

```typescript
// ═══════════════════════════════════════════════════════════════
// RESPONSE TEMPLATES
// ═══════════════════════════════════════════════════════════════

export interface ResponseTemplate {
  template_id: string;
  name: string;
  category: 'positive' | 'negative' | 'neutral' | 'mixed';
  scenario: string;
  business_type: string;
  template_text: string;
  placeholders: string[];
  tone: string;
  is_system: boolean;
  usage_count: number;
}

export interface TemplateListResponse {
  success: boolean;
  count: number;
  templates: ResponseTemplate[];
  filters_applied: {
    category: string;
    scenario: string;
    business_type: string;
  };
}

export interface ApplyTemplateResponse {
  success: boolean;
  reply_text: string;
  template_used: string;
  credits: CreditInfo;
}

// ═══════════════════════════════════════════════════════════════
// ACTION PLANS
// ═══════════════════════════════════════════════════════════════

export type Timeframe = '30_day' | '60_day' | '90_day';

export interface ActionItem {
  action: string;
  owner_role: string;
  kpi: string;
  effort: 'low' | 'medium' | 'high';
  expected_impact: string;
  source_issue: string;
  timeline_days: number;
}

export interface ActionPlanKPI {
  name: string;
  current_value: string;
  target_value: string;
  measurement_method: string;
  review_frequency: string;
}

export interface ActionPlan {
  plan_id: string;
  title: string;
  overview: string;
  timeframe: Timeframe;
  total_action_items: number;
  immediate_actions: ActionItem[];
  short_term_actions: ActionItem[];
  medium_term_actions: ActionItem[];
  kpis: ActionPlanKPI[];
  expected_outcomes: string[];
  risk_factors: string[];
  based_on: {
    health_score: number;
    reviews_analyzed: number;
    key_issues: string[];
  };
  generated_at: string;
}

export interface ActionPlanResponse {
  success: boolean;
  plan: ActionPlan;
  credits: CreditInfo;
}

// ═══════════════════════════════════════════════════════════════
// SOCIAL MEDIA POSTS
// ═══════════════════════════════════════════════════════════════

export type SocialPlatform = 'twitter' | 'facebook' | 'instagram' | 'linkedin';

export interface SocialMediaPostConfig {
  brand_name: string;
  brand_voice: 'professional' | 'casual' | 'playful' | 'authoritative';
  default_hashtags: string[];
  include_star_rating: boolean;
  include_review_quote: boolean;
  include_call_to_action: boolean;
  call_to_action_text: string;
}

export interface SocialMediaPost {
  post_id: string;
  platform: SocialPlatform;
  post_text: string;
  hashtags: string[];
  review_quote: string;
  review_author: string;
  review_rating: number;
  character_count: number;
  generated_at: string;
}

export interface SocialPostsResponse {
  success: boolean;
  business: { place_id: string; name: string };
  posts_generated: number;
  posts: SocialMediaPost[];
  credits: CreditInfo;
}

// ═══════════════════════════════════════════════════════════════
// MARKETING COPY
// ═══════════════════════════════════════════════════════════════

export type AdFormat =
  | 'google_search'
  | 'google_display'
  | 'facebook_ad'
  | 'instagram_ad'
  | 'email_subject'
  | 'email_body';

export interface MarketingCopyConfig {
  brand_name: string;
  brand_tagline: string;
  target_audience: string;
  unique_selling_points: string[];
  tone: 'persuasive' | 'informational' | 'emotional' | 'urgent';
}

export interface MarketingCopyVariant {
  copy_id: string;
  ad_format: AdFormat;
  headline: string;
  body_text: string;
  call_to_action: string;
  variant_label: string;
  character_counts: {
    headline: number;
    body: number;
    cta: number;
  };
  source_delighters: string[];
  source_quotes: string[];
  generated_at: string;
}

export interface MarketingCopyResponse {
  success: boolean;
  business: { place_id: string; name: string };
  ad_format: AdFormat;
  variants: MarketingCopyVariant[];
  source_data: {
    delighters: string[];
    quotes: string[];
  };
  credits: CreditInfo;
}

// ═══════════════════════════════════════════════════════════════
// BLOG POSTS
// ═══════════════════════════════════════════════════════════════

export type BlogContentType =
  | 'improvement_story'
  | 'customer_spotlight'
  | 'insights_listicle'
  | 'case_study'
  | 'trend_analysis';

export interface BlogPostConfig {
  author_name: string;
  brand_name: string;
  writing_style: 'informative' | 'storytelling' | 'data_driven' | 'conversational';
  target_word_count: number;
  include_data_visualizations: boolean;
  seo_focus: boolean;
}

export interface BlogSection {
  heading: string;
  content: string;
  data_points: string[];
}

export interface BlogPost {
  post_id: string;
  content_type: BlogContentType;
  title: string;
  meta_description: string;
  slug: string;
  introduction: string;
  body_sections: BlogSection[];
  conclusion: string;
  seo_keywords: string[];
  word_count: number;
  generated_at: string;
}

export interface BlogPostResponse {
  success: boolean;
  blog_post: BlogPost;
  credits: CreditInfo;
}

// ═══════════════════════════════════════════════════════════════
// SHARED
// ═══════════════════════════════════════════════════════════════

export interface CreditInfo {
  used: number;
  remaining: number;
}
```

---

## 4. Page Architecture

### File Structure

```
src/
├── pages/
│   └── business/
│       └── [id]/
│           └── content/
│               ├── ContentHub.tsx          # Main content tab with feature cards
│               ├── TemplatesPage.tsx       # Response template library
│               ├── ActionPlanPage.tsx      # Action plan generator
│               ├── SocialPostsPage.tsx     # Social media post generator
│               ├── MarketingCopyPage.tsx   # Marketing copy generator
│               └── BlogPostPage.tsx        # Blog post generator
│
├── components/
│   └── content/
│       ├── shared/
│       │   ├── CreditCostBadge.tsx        # Shows credit cost on buttons
│       │   ├── GenerateButton.tsx          # Standard generate button with cost
│       │   ├── ContentCard.tsx             # Card wrapper for generated content
│       │   ├── CopyToClipboard.tsx         # Copy text to clipboard
│       │   ├── EmptyState.tsx              # "No content yet" placeholder
│       │   └── ConfigDrawer.tsx            # Slide-out config panel
│       │
│       ├── templates/
│       │   ├── TemplateList.tsx            # Filterable template grid
│       │   ├── TemplateCard.tsx            # Single template card
│       │   ├── TemplatePreview.tsx         # Template with highlighted placeholders
│       │   ├── CreateTemplateDialog.tsx    # Modal for creating custom template
│       │   └── ApplyTemplateDialog.tsx     # Modal for AI customization
│       │
│       ├── action-plan/
│       │   ├── ActionPlanForm.tsx          # Timeframe + focus areas selector
│       │   ├── ActionPlanView.tsx          # Full plan display
│       │   ├── ActionTimeline.tsx          # Visual timeline of actions
│       │   ├── ActionItemCard.tsx          # Single action item
│       │   └── KPITable.tsx               # KPI tracking table
│       │
│       ├── social-posts/
│       │   ├── SocialPostForm.tsx          # Platform + review selector
│       │   ├── SocialPostPreview.tsx       # Platform-specific preview
│       │   ├── PlatformIcon.tsx            # Twitter/FB/IG/LinkedIn icons
│       │   └── SocialConfigForm.tsx        # Brand voice settings
│       │
│       ├── marketing-copy/
│       │   ├── AdFormatSelector.tsx        # Format picker with char limits
│       │   ├── CopyVariantCard.tsx         # A/B variant display
│       │   ├── CharacterCounter.tsx        # Live char count with limits
│       │   └── MarketingConfigForm.tsx     # Brand/audience settings
│       │
│       └── blog/
│           ├── BlogPostForm.tsx            # Content type + theme selector
│           ├── BlogPostPreview.tsx         # Full blog post renderer
│           ├── BlogSectionView.tsx         # Single section with data points
│           ├── SEOMetaPreview.tsx          # Google SERP preview
│           └── BlogConfigForm.tsx          # Writing style settings
│
├── hooks/
│   └── content/
│       ├── useTemplates.ts                # Template CRUD hooks
│       ├── useActionPlans.ts              # Action plan hooks
│       ├── useSocialPosts.ts              # Social post hooks
│       ├── useMarketingCopy.ts            # Marketing copy hooks
│       └── useBlogPosts.ts                # Blog post hooks
│
└── services/
    └── contentApi.ts                      # API service (Section 2)
```

### Route Definitions

```typescript
// src/routes/contentRoutes.tsx
import { Route } from 'react-router-dom';

const contentRoutes = (
  <>
    <Route path="/business/:id/content" element={<ContentHub />} />
    <Route path="/business/:id/content/templates" element={<TemplatesPage />} />
    <Route path="/business/:id/content/action-plans" element={<ActionPlanPage />} />
    <Route path="/business/:id/content/social-posts" element={<SocialPostsPage />} />
    <Route path="/business/:id/content/marketing-copy" element={<MarketingCopyPage />} />
    <Route path="/business/:id/content/blog-posts" element={<BlogPostPage />} />
  </>
);
```

---

## 5. Feature 1: Response Template Library

### 5.1 TemplatesPage Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Response Templates                          [+ Create New]  │
│                                                              │
│  Filters: [Category ▾] [Scenario ▾] [Business Type ▾]       │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐         │
│  │  Grateful     │ │  First Visit │ │  Sincere     │         │
│  │  Acknowledgmt │ │  Thank You   │ │  Apology     │         │
│  │              │ │              │ │              │         │
│  │  ★ positive  │ │  ★ positive  │ │  ★ negative  │         │
│  │  praise      │ │  first_visit │ │  complaint   │         │
│  │              │ │              │ │              │         │
│  │  "Thank you  │ │  "Welcome to │ │  "Dear       │         │
│  │   so much,   │ │   the {biz}  │ │   {name},    │         │
│  │   {reviewer}!"│ │   family..." │ │   we apol..."│         │
│  │              │ │              │ │              │         │
│  │ [Preview] [Apply to Review]  │ │ ...          │         │
│  │ Used 3x  │ SYSTEM          │ │              │         │
│  └──────────────┘ └──────────────┘ └──────────────┘         │
│                                                              │
│  ┌──────────────┐ ┌──────────────┐                          │
│  │  My Custom   │ │              │                          │
│  │  Template    │ │     ...      │                          │
│  │  🗑 [Delete] │ │              │                          │
│  └──────────────┘ └──────────────┘                          │
└──────────────────────────────────────────────────────────────┘
```

### 5.2 TemplateCard Component

```tsx
// src/components/content/templates/TemplateCard.tsx
interface TemplateCardProps {
  template: ResponseTemplate;
  businessId: string;
  onApply: (templateId: string) => void;
  onDelete?: (templateId: string) => void;
}

// Display:
// - Name as card title
// - Category badge (green=positive, red=negative, yellow=neutral, blue=mixed)
// - Scenario tag
// - Template text preview (truncated to 3 lines)
// - Highlighted {placeholders} in a different color (e.g., blue text)
// - Usage count ("Used 12 times")
// - "SYSTEM" or "CUSTOM" badge
// - [Apply to Review] button (opens ApplyTemplateDialog)
// - [Delete] button (only for custom templates, with confirmation)
```

### 5.3 ApplyTemplateDialog

```
┌─────────────────────────────────────────────┐
│  Apply Template: "Grateful Acknowledgment"   │
│                                             │
│  Template Preview:                          │
│  ┌─────────────────────────────────────┐    │
│  │ "Thank you so much, {reviewer_name} │    │
│  │  ! We're thrilled to hear you       │    │
│  │  enjoyed {specific_mention}..."      │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  Select Review:                             │
│  ┌─────────────────────────────────────┐    │
│  │ ★★★★★ John D. - "Amazing food..."  │    │
│  │ ★★★★☆ Sarah M. - "Great service.." │    │
│  │ ★★★☆☆ Mike T. - "Decent but..."    │    │
│  └─────────────────────────────────────┘    │
│                                             │
│  💰 Cost: 0.25 credits                      │
│  💳 Balance: 4.75 credits                   │
│                                             │
│        [Cancel]  [Apply Template ✨ 0.25cr]  │
└─────────────────────────────────────────────┘
```

**After apply** - show the generated reply text with a "Copy to Clipboard" button.

### 5.4 CreateTemplateDialog

```
┌─────────────────────────────────────────────┐
│  Create Custom Template                      │
│                                             │
│  Name: [_____________________________]      │
│                                             │
│  Category: [positive ▾]                     │
│  Scenario: [praise ▾]                       │
│  Business Type: [GENERIC ▾]                 │
│  Tone: [friendly_professional ▾]            │
│                                             │
│  Template Text:                             │
│  ┌─────────────────────────────────────┐    │
│  │ Thank you, {reviewer_name}! We're   │    │
│  │ glad you loved {specific_mention}.   │    │
│  │ Come back soon! - {sign_off}        │    │
│  └─────────────────────────────────────┘    │
│  Detected placeholders:                     │
│  reviewer_name, specific_mention, sign_off  │
│                                             │
│  ℹ️ Use {placeholder_name} syntax            │
│  Max 2000 characters (1,847 remaining)      │
│                                             │
│        [Cancel]  [Create Template]           │
└─────────────────────────────────────────────┘
```

**UX Details:**
- Auto-detect and display placeholders as user types (use regex `\{(\w+)\}`)
- Show placeholder chips below the textarea in real-time
- Character counter with max 2000
- Category dropdown options: positive, negative, neutral, mixed
- Scenario dropdown: praise, complaint_service, complaint_quality, suggestion, question, return_visit, first_visit, detailed_feedback
- Business Type: all 9 types + GENERIC

---

## 6. Feature 2: Action Plan Generator

### 6.1 ActionPlanPage Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Action Plans for "Street Burger"                            │
│                                                              │
│  ┌────────────── Generate New Plan ─────────────────┐        │
│  │                                                  │        │
│  │  Timeframe:  (●) 90 days  ( ) 60 days  ( ) 30 days │     │
│  │                                                  │        │
│  │  Focus Areas (optional):                         │        │
│  │  [Service ×] [Value ×] [+ Add Theme]             │        │
│  │                                                  │        │
│  │  ⚡ Based on: Health Score 72/100 (B-)            │        │
│  │    143 reviews analyzed                          │        │
│  │                                                  │        │
│  │  [Generate Action Plan ✨ 0.5 credits]            │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ── Existing Plans ──────────────────────────────────        │
│                                                              │
│  ┌──────────────────────────────────────────────────┐        │
│  │  📋 Service Excellence & Value Recovery Plan      │        │
│  │  90-day plan • 11 action items • Feb 7, 2026     │        │
│  │  [View Plan] [Delete]                            │        │
│  └──────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
```

### 6.2 ActionPlanView (Full Plan Display)

```
┌──────────────────────────────────────────────────────────────┐
│  ← Back to Plans                                             │
│                                                              │
│  Service Excellence & Value Recovery Plan                     │
│  ─────────────────────────────────────────                   │
│  90-day plan • 11 actions • Based on health score: 72        │
│                                                              │
│  Overview:                                                   │
│  A 90-day plan addressing service consistency and value      │
│  perception. Focus on staff training and communication       │
│  improvements that preserve the kitchen's strong reputation. │
│                                                              │
│  ════════════════════════════════════════════════════════     │
│  🔴 IMMEDIATE ACTIONS (This Week)                  3 items   │
│  ════════════════════════════════════════════════════════     │
│                                                              │
│  ┌────────────────────────────────────────────────────┐      │
│  │ 1. Conduct 30-min team meeting to review top 5     │      │
│  │    service complaints                              │      │
│  │                                                    │      │
│  │  👤 Owner: Manager    ⏱ 3 days    💪 Low effort    │      │
│  │  📊 KPI: Reduce slow service mentions 15% → 10%    │      │
│  │  📈 Impact: Immediate first impression improvement  │      │
│  │  🔗 Addresses: "Slow service and inattentive staff" │      │
│  └────────────────────────────────────────────────────┘      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐      │
│  │ 2. ...                                             │      │
│  └────────────────────────────────────────────────────┘      │
│                                                              │
│  ════════════════════════════════════════════════════════     │
│  🟡 SHORT-TERM ACTIONS (This Month)               4 items   │
│  ════════════════════════════════════════════════════════     │
│  ...                                                         │
│                                                              │
│  ════════════════════════════════════════════════════════     │
│  🟢 MEDIUM-TERM ACTIONS (Months 2-3)              4 items   │
│  ════════════════════════════════════════════════════════     │
│  ...                                                         │
│                                                              │
│  ════════════════════════════════════════════════════════     │
│  📊 KPIs TO TRACK                                  5 items   │
│  ════════════════════════════════════════════════════════     │
│                                                              │
│  ┌──────────────┬──────────┬──────────┬──────────────┐      │
│  │ KPI          │ Current  │ Target   │ Measure      │      │
│  ├──────────────┼──────────┼──────────┼──────────────┤      │
│  │ Service      │ 62%      │ 75%      │ Monthly      │      │
│  │ Satisfaction │ positive │ positive │ re-analysis  │      │
│  ├──────────────┼──────────┼──────────┼──────────────┤      │
│  │ ...          │          │          │              │      │
│  └──────────────┴──────────┴──────────┴──────────────┘      │
│                                                              │
│  ════════════════════════════════════════════════════════     │
│  ✅ EXPECTED OUTCOMES                                        │
│  ════════════════════════════════════════════════════════     │
│  • Health score improvement from 72 to 80+ within 90 days   │
│  • Service theme sentiment improvement from 0.3 to 0.5+     │
│  • ...                                                       │
│                                                              │
│  ════════════════════════════════════════════════════════     │
│  ⚠️ RISK FACTORS                                             │
│  ════════════════════════════════════════════════════════     │
│  • Staff turnover may require repeating training             │
│  • Changes to pricing perception may reduce foot traffic     │
└──────────────────────────────────────────────────────────────┘
```

### 6.3 ActionItemCard Component

```tsx
interface ActionItemCardProps {
  item: ActionItem;
  index: number;
  phase: 'immediate' | 'short_term' | 'medium_term';
}

// Color coding by effort:
// - Low effort: green border-left
// - Medium effort: yellow border-left
// - High effort: red border-left

// Owner role badges:
// manager → blue, staff → green, owner → purple, marketing → orange, operations → gray
```

---

## 7. Feature 3: Social Media Post Generator

### 7.1 SocialPostsPage Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Social Media Posts for "Street Burger"       [⚙ Settings]   │
│                                                              │
│  ┌────────────── Generate New Posts ────────────────┐        │
│  │                                                  │        │
│  │  Review Source:                                   │        │
│  │  (●) Auto-select best reviews                    │        │
│  │  ( ) Choose specific review                      │        │
│  │      [Select review ▾]                           │        │
│  │                                                  │        │
│  │  Platforms:                                       │        │
│  │  [✓] Twitter/X  [✓] Facebook                    │        │
│  │  [✓] Instagram  [✓] LinkedIn                    │        │
│  │                                                  │        │
│  │  Posts per review: [1 ▾] (max 5)                │        │
│  │                                                  │        │
│  │  [Generate Posts ✨ 0.25 credits]                 │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ── Generated Posts ─────────────────────────────────        │
│  Filter: [All Platforms ▾]                                   │
│                                                              │
│  ┌──────────────────────────────────────────────────┐        │
│  │  🐦 Twitter/X                     230/280 chars  │        │
│  │                                                  │        │
│  │  "The burgers here are incredible!"              │        │
│  │  - John D. ⭐⭐⭐⭐⭐                               │        │
│  │                                                  │        │
│  │  We're blushing! 😊 Thanks John for the love.   │        │
│  │  #StreetBurger #BurgerLove #FoodieApproved      │        │
│  │                                                  │        │
│  │  [📋 Copy] [🗑 Delete]                            │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ┌──────────────────────────────────────────────────┐        │
│  │  📘 Facebook                                      │        │
│  │  ...                                             │        │
│  └──────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
```

### 7.2 SocialPostPreview Component

Platform-specific styling:

| Platform | Style |
|----------|-------|
| **Twitter/X** | Dark card, character count prominently shown (red if >280), bird icon |
| **Facebook** | Blue header bar, white card body, longer format |
| **Instagram** | Gradient border (pink/purple), hashtag-heavy, emoji-rich |
| **LinkedIn** | Professional gray/blue, minimal emojis, business tone |

```tsx
interface SocialPostPreviewProps {
  post: SocialMediaPost;
  onCopy: () => void;
  onDelete: () => void;
}

// Each preview should show:
// - Platform icon + name
// - Character count / limit
// - Post text (formatted for that platform)
// - Hashtags as colored chips
// - Review attribution line
// - Copy and Delete buttons
```

### 7.3 SocialConfigForm (Settings Drawer)

```
┌─────────────────────────────────┐
│  Social Media Settings          │
│                                 │
│  Brand Name Override:           │
│  [_________________________]    │
│                                 │
│  Brand Voice:                   │
│  [Professional ▾]              │
│                                 │
│  Default Hashtags:              │
│  [#StreetBurger ×] [+ Add]     │
│                                 │
│  Include:                       │
│  [✓] Star rating in posts      │
│  [✓] Review quote              │
│  [✓] Call-to-action             │
│                                 │
│  CTA Text:                      │
│  [Visit us today!__________]    │
│                                 │
│  [Save Settings]                │
└─────────────────────────────────┘
```

---

## 8. Feature 4: Marketing Copy Generator

### 8.1 MarketingCopyPage Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Marketing Copy for "Street Burger"           [⚙ Settings]   │
│                                                              │
│  ┌────────────── Generate Ad Copy ─────────────────┐        │
│  │                                                  │        │
│  │  Ad Format:                                      │        │
│  │  ┌─────────────┐ ┌─────────────┐ ┌──────────┐  │        │
│  │  │ Google      │ │ Google      │ │ Facebook │  │        │
│  │  │ Search      │ │ Display     │ │ Ad       │  │        │
│  │  │ H:30 B:90   │ │ H:40 B:150  │ │ H:40    │  │        │
│  │  └──────●──────┘ └─────────────┘ │ B:250   │  │        │
│  │  ┌─────────────┐ ┌─────────────┐ └──────────┘  │        │
│  │  │ Instagram   │ │ Email       │ ┌──────────┐  │        │
│  │  │ Ad          │ │ Subject     │ │ Email    │  │        │
│  │  │ H:40 B:200  │ │ H:60       │ │ Body     │  │        │
│  │  └─────────────┘ └─────────────┘ │ H:60    │  │        │
│  │                                   │ B:500   │  │        │
│  │  Variants: [3 ▾] (2-3)          └──────────┘  │        │
│  │                                                  │        │
│  │  [Generate Copy ✨ 0.25 credits]                  │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ── Generated Copy ──────────────────────────────────        │
│  Filter: [All Formats ▾]                                     │
│                                                              │
│  ┌───────── Google Search Ad ─────────────────────────┐      │
│  │                                                    │      │
│  │  Variant A              Variant B                  │      │
│  │  ┌─────────────────┐   ┌─────────────────┐        │      │
│  │  │ H: Best Burgers  │   │ H: 5-Star Rated │        │      │
│  │  │    In Town        │   │    Burgers      │        │      │
│  │  │ B: Voted #1 by   │   │ B: "Incredible" │        │      │
│  │  │    customers...   │   │    say our fans  │        │      │
│  │  │ CTA: Order Now    │   │ CTA: Try Today  │        │      │
│  │  │                   │   │                 │        │      │
│  │  │ 28/30  85/90  8/15│   │ 26/30  80/90   │        │      │
│  │  │ [📋 Copy]         │   │ [📋 Copy]       │        │      │
│  │  └─────────────────┘   └─────────────────┘        │      │
│  │                                                    │      │
│  │  Source: "juicy burgers", "fast service"           │      │
│  │  [🗑 Delete All Variants]                          │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
```

### 8.2 CopyVariantCard Component

```tsx
interface CopyVariantCardProps {
  variant: MarketingCopyVariant;
  charLimits: { headline: number; body: number; cta: number };
  onCopy: (text: string) => void;
}

// Display:
// - Variant label badge (A, B, C) with different colors
// - Headline with character count / limit
// - Body text with character count / limit
// - CTA with character count / limit
// - Character counts colored: green (under limit), red (over limit)
// - Copy button for each field individually + "Copy All" button
```

### 8.3 AdFormatSelector Component

Visual cards for each format showing:
- Format icon (Google, Facebook, etc.)
- Format name
- Character limits (`H:30 B:90`)
- Selected state with border highlight

### 8.4 MarketingConfigForm (Settings Drawer)

```
┌─────────────────────────────────┐
│  Marketing Copy Settings        │
│                                 │
│  Brand Name:                    │
│  [Street Burger______________]  │
│                                 │
│  Tagline:                       │
│  [Best Burgers In Town_______]  │
│                                 │
│  Target Audience:               │
│  [Young professionals, foodies] │
│                                 │
│  Unique Selling Points:         │
│  [Hand-crafted burgers ×]       │
│  [Fresh ingredients ×]          │
│  [+ Add USP]                    │
│                                 │
│  Tone:                          │
│  [Persuasive ▾]                │
│                                 │
│  [Save Settings]                │
└─────────────────────────────────┘
```

---

## 9. Feature 5: Blog Post Generator

### 9.1 BlogPostPage Layout

```
┌──────────────────────────────────────────────────────────────┐
│  Blog Posts for "Street Burger"               [⚙ Settings]   │
│                                                              │
│  ┌────────────── Generate Blog Post ───────────────┐        │
│  │                                                  │        │
│  │  Content Type:                                   │        │
│  │  ┌────────────────┐ ┌────────────────┐          │        │
│  │  │ 📈 Improvement │ │ 🌟 Customer    │          │        │
│  │  │    Story       │ │    Spotlight   │          │        │
│  │  │ "How we're     │ │ "What our      │          │        │
│  │  │  improving..." │ │  customers say" │          │        │
│  │  └────────────────┘ └────────────────┘          │        │
│  │  ┌────────────────┐ ┌────────────────┐          │        │
│  │  │ 📊 Insights    │ │ 📋 Case        │          │        │
│  │  │    Listicle    │ │    Study       │          │        │
│  │  │ "X things      │ │ "Data-driven   │          │        │
│  │  │  customers love"│ │  performance"  │          │        │
│  │  └───────●────────┘ └────────────────┘          │        │
│  │  ┌────────────────┐                              │        │
│  │  │ 📉 Trend       │                              │        │
│  │  │    Analysis    │                              │        │
│  │  │ "How sentiment │                              │        │
│  │  │  has evolved"  │                              │        │
│  │  └────────────────┘                              │        │
│  │                                                  │        │
│  │  Focus Theme (optional): [Service ▾]             │        │
│  │                                                  │        │
│  │  [Generate Blog Post ✨ 1.0 credits]              │        │
│  └──────────────────────────────────────────────────┘        │
│                                                              │
│  ── Generated Blog Posts ────────────────────────────        │
│                                                              │
│  ┌──────────────────────────────────────────────────┐        │
│  │  📝 5 Things Customers Love About Street Burger   │        │
│  │  insights_listicle • 850 words • Feb 7, 2026     │        │
│  │  SEO: burger restaurant, customer reviews, ...   │        │
│  │  [Read Full Post] [📋 Copy] [🗑 Delete]           │        │
│  └──────────────────────────────────────────────────┘        │
└──────────────────────────────────────────────────────────────┘
```

### 9.2 BlogPostPreview (Full Post View)

```
┌──────────────────────────────────────────────────────────────┐
│  ← Back to Blog Posts                     [📋 Copy All]      │
│                                                              │
│  ┌────── SEO Preview ─────────────────────────────────┐      │
│  │  5 Things Customers Love About Street Burger       │      │
│  │  https://example.com/5-things-customers-love-...   │      │
│  │  Discover what makes Street Burger a local          │      │
│  │  favorite based on analysis of 143 real reviews...  │      │
│  └────────────────────────────────────────────────────┘      │
│                                                              │
│  SEO Keywords:                                               │
│  [burger restaurant] [customer reviews] [food quality] ...  │
│                                                              │
│  ── Full Post ───────────────────────────────────────        │
│                                                              │
│  # 5 Things Customers Love About Street Burger               │
│                                                              │
│  [Introduction text rendered as markdown...]                  │
│                                                              │
│  ## 1. The Burgers Are Simply Outstanding                    │
│                                                              │
│  [Section content...]                                        │
│                                                              │
│  📊 Data Points:                                              │
│  • 78% of reviews mention food quality positively            │
│  • Average food rating: 4.6/5                                │
│                                                              │
│  ## 2. Service That Makes You Feel Welcome                   │
│  [...]                                                       │
│                                                              │
│  ## Conclusion                                               │
│  [Conclusion text...]                                        │
│                                                              │
│  ── Post Stats ──                                            │
│  Word count: 850 • Content type: Insights Listicle           │
│  Generated: Feb 7, 2026                                      │
└──────────────────────────────────────────────────────────────┘
```

### 9.3 SEOMetaPreview Component

Renders a Google SERP-style preview:

```tsx
interface SEOMetaPreviewProps {
  title: string;        // max 60 chars
  slug: string;         // URL-friendly
  metaDescription: string;  // max 160 chars
  domain?: string;      // e.g., "yourbusiness.com"
}

// Renders:
// ┌──────────────────────────────────────┐
// │ Title Here - Up to 60 Characters     │  (blue, clickable style)
// │ yourbusiness.com/blog/slug-here      │  (green URL)
// │ Meta description text showing up to   │  (gray body)
// │ 160 characters of preview text...    │
// └──────────────────────────────────────┘
```

### 9.4 BlogConfigForm (Settings Drawer)

```
┌─────────────────────────────────┐
│  Blog Post Settings             │
│                                 │
│  Author Name:                   │
│  [John Smith_________________]  │
│                                 │
│  Brand Name:                    │
│  [Street Burger______________]  │
│                                 │
│  Writing Style:                 │
│  (●) Informative                │
│  ( ) Storytelling               │
│  ( ) Data-Driven                │
│  ( ) Conversational             │
│                                 │
│  Target Word Count:             │
│  [800] (600 - 2000)            │
│  ├──────●──────────────┤        │
│  600                  2000      │
│                                 │
│  [✓] Include data callouts      │
│  [✓] SEO optimization           │
│                                 │
│  [Save Settings]                │
└─────────────────────────────────┘
```

---

## 10. Shared Components

### 10.1 CreditCostBadge

```tsx
interface CreditCostBadgeProps {
  cost: number;
  label?: string;  // e.g., "per batch", "per post"
}

// Renders: "✨ 0.25 credits" as a small badge
// Variants:
//   - inline: for use inside buttons
//   - standalone: for use in cards/headers
```

### 10.2 GenerateButton

```tsx
interface GenerateButtonProps {
  cost: number;
  label: string;          // "Generate Action Plan"
  onClick: () => void;
  isLoading: boolean;
  disabled?: boolean;
  userCredits: number;    // For insufficient credit warning
}

// States:
// 1. Normal: "[Generate Action Plan ✨ 0.5cr]"
// 2. Loading: "[Generating... ⏳]" (spinner)
// 3. Insufficient: "[Insufficient Credits - Need 0.5]" (red, links to buy credits)
// 4. Disabled: grayed out (e.g., no analysis data)
```

### 10.3 CopyToClipboard

```tsx
interface CopyToClipboardProps {
  text: string;
  label?: string;  // "Copy" or "Copy All"
  onCopy?: () => void;
}

// Behavior:
// - Click copies text to clipboard
// - Shows "Copied!" toast for 2 seconds
// - Button icon changes from clipboard to checkmark briefly
```

### 10.4 ContentCard

```tsx
interface ContentCardProps {
  title: string;
  subtitle?: string;
  badges?: { label: string; color: string }[];
  timestamp?: string;
  actions: React.ReactNode;
  children: React.ReactNode;
}

// Standardized card wrapper for all generated content items
// Used by: SocialPostPreview, CopyVariantCard, BlogPostListItem, ActionPlanListItem
```

### 10.5 EmptyState

```tsx
interface EmptyStateProps {
  icon: React.ReactNode;
  title: string;          // "No action plans yet"
  description: string;    // "Generate your first action plan..."
  actionLabel?: string;   // "Generate Plan"
  onAction?: () => void;
}
```

### 10.6 ConfigDrawer

```tsx
interface ConfigDrawerProps {
  title: string;        // "Social Media Settings"
  isOpen: boolean;
  onClose: () => void;
  onSave: () => void;
  isSaving: boolean;
  children: React.ReactNode;
}

// Slide-out drawer from the right side
// Used by: Social, Marketing, and Blog config forms
// shadcn/ui Sheet component
```

---

## 11. Navigation & Routing

### Content Hub Tab

The "Content" tab appears in the business detail page alongside existing tabs (Report, Reviews, Replies).

```tsx
// Business detail tabs
<Tabs defaultValue="report">
  <TabsList>
    <TabsTrigger value="report">Report</TabsTrigger>
    <TabsTrigger value="reviews">Reviews</TabsTrigger>
    <TabsTrigger value="replies">Replies</TabsTrigger>
    <TabsTrigger value="content">Content</TabsTrigger>  {/* NEW */}
  </TabsList>
</Tabs>
```

### ContentHub Component

The content hub is a card-based grid showing all 5 features:

```
┌──────────────────────────────────────────────────────────────┐
│  Content Generation                                          │
│  Transform your review insights into actionable content      │
│                                                              │
│  ┌────────────────────┐ ┌────────────────────┐              │
│  │ 📝 Response        │ │ 📋 Action Plans    │              │
│  │    Templates       │ │                    │              │
│  │                    │ │ Generate prioritized│              │
│  │ Pre-built reply    │ │ improvement roadmaps│              │
│  │ templates for fast │ │ with KPIs          │              │
│  │ review responses   │ │                    │              │
│  │                    │ │ 💰 0.5 credits/plan │              │
│  │ 💰 FREE / 0.25cr   │ │                    │              │
│  │                    │ │ [Generate →]        │              │
│  │ [Browse Templates]  │ └────────────────────┘              │
│  └────────────────────┘                                      │
│  ┌────────────────────┐ ┌────────────────────┐              │
│  │ 📱 Social Media    │ │ 📢 Marketing Copy  │              │
│  │    Posts           │ │                    │              │
│  │                    │ │ Ad copy with A/B    │              │
│  │ Turn 5-star reviews│ │ variants from review│              │
│  │ into social proof  │ │ highlights          │              │
│  │                    │ │                    │              │
│  │ 💰 0.25 cr/batch   │ │ 💰 0.25 cr/batch   │              │
│  │                    │ │                    │              │
│  │ [Create Posts →]    │ │ [Generate Copy →]   │              │
│  └────────────────────┘ └────────────────────┘              │
│  ┌────────────────────┐                                      │
│  │ ✍️  Blog Posts      │                                      │
│  │                    │                                      │
│  │ SEO-optimized blog │                                      │
│  │ content from review│                                      │
│  │ analysis insights  │                                      │
│  │                    │                                      │
│  │ 💰 1.0 credit/post │                                      │
│  │                    │                                      │
│  │ [Write Blog Post →] │                                      │
│  └────────────────────┘                                      │
└──────────────────────────────────────────────────────────────┘
```

Each card shows:
- Feature icon
- Feature name
- 1-2 line description
- Credit cost
- Count of existing generated items (e.g., "3 posts generated")
- Link to the feature page

---

## 12. State Management

### React Query / TanStack Query Hooks

Each feature has a custom hook file wrapping the API calls with proper caching and invalidation.

#### Example: `useActionPlans.ts`

```typescript
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { actionPlanApi } from '@/services/contentApi';

export function useActionPlans(businessId: string) {
  const queryClient = useQueryClient();

  const plansQuery = useQuery({
    queryKey: ['action-plans', businessId],
    queryFn: () => actionPlanApi.getPlans(businessId),
    enabled: !!businessId,
  });

  const generateMutation = useMutation({
    mutationFn: actionPlanApi.generate,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['action-plans', businessId] });
      queryClient.invalidateQueries({ queryKey: ['user-profile'] }); // refresh credits
    },
  });

  const deleteMutation = useMutation({
    mutationFn: actionPlanApi.deletePlan,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['action-plans', businessId] });
    },
  });

  return {
    plans: plansQuery.data?.plans ?? [],
    isLoading: plansQuery.isLoading,
    generate: generateMutation.mutate,
    isGenerating: generateMutation.isPending,
    generateResult: generateMutation.data,
    deletePlan: deleteMutation.mutate,
    isDeleting: deleteMutation.isPending,
  };
}
```

### Query Key Convention

```typescript
// Query keys for content features
const QUERY_KEYS = {
  templates: ['templates'],
  actionPlans: (bizId: string) => ['action-plans', bizId],
  socialPosts: (bizId: string) => ['social-posts', bizId],
  socialConfig: ['social-config'],
  marketingCopy: (bizId: string) => ['marketing-copy', bizId],
  marketingConfig: ['marketing-config'],
  blogPosts: (bizId: string) => ['blog-posts', bizId],
  blogConfig: ['blog-config'],
};
```

### Credit Balance Refresh

After every mutation that costs credits, invalidate the `user-profile` query to refresh the credit balance displayed in the header/sidebar:

```typescript
onSuccess: () => {
  queryClient.invalidateQueries({ queryKey: ['user-profile'] });
}
```

---

## 13. UX Patterns

### 13.1 Loading States

| Action | Loading UI |
|--------|-----------|
| Generate content | Button shows spinner + "Generating..." text. Disable all other generate buttons. Show estimated time below button. |
| Fetch list | Skeleton cards (shadcn/ui Skeleton) |
| Delete item | Optimistic removal with undo toast (3s) |
| Save config | Button shows spinner, then checkmark for 1s |

**Estimated generation times** (shown during loading):

| Feature | Estimate |
|---------|----------|
| Apply Template | "~5 seconds" |
| Action Plan | "~15 seconds" |
| Social Posts | "~10 seconds" |
| Marketing Copy | "~10 seconds" |
| Blog Post | "~30 seconds" |

### 13.2 Error Handling

```typescript
// Standard error toast pattern
const handleGenerate = async () => {
  try {
    const result = await generate(params);
    if (result.success) {
      toast.success(`Generated! Used ${result.credits.used} credits.`);
    } else {
      toast.error(result.error);
    }
  } catch (error) {
    toast.error('Something went wrong. Please try again.');
  }
};
```

**Specific error messages:**

| Error | User-facing message |
|-------|-------------------|
| `Insufficient credits` | "Not enough credits. You need X credits. [Buy Credits]" (link to purchase page) |
| `Analysis not found` | "Run an analysis first to generate content. [Analyze Now]" (link to re-analyze) |
| `No suitable reviews` | "No positive reviews found. Social posts require 4+ star reviews with text." |
| `LLM failure` | "Generation failed. Your credits have been refunded. Please try again." |

### 13.3 Success Feedback

After successful generation, show:

1. **Toast notification**: "Action plan generated! 0.5 credits used, 4.5 remaining."
2. **Scroll to result**: Auto-scroll to the newly generated content
3. **Highlight new item**: Brief highlight animation (green border flash) on the new card
4. **Credit update**: Header credit display updates in real-time

### 13.4 Confirmation Dialogs

Use `AlertDialog` (shadcn/ui) for:
- Deleting any generated content
- Generating content when credits are low (< 2x the cost)

```
┌────────────────────────────────────┐
│  Delete Action Plan?                │
│                                    │
│  "Service Excellence Recovery Plan" │
│  will be permanently deleted.      │
│  This action cannot be undone.     │
│                                    │
│       [Cancel]  [Delete]            │
└────────────────────────────────────┘
```

### 13.5 Empty State Patterns

When no content has been generated yet:

```
        ┌─────────────────────────┐
        │                         │
        │    📋 (large icon)       │
        │                         │
        │  No action plans yet    │
        │                         │
        │  Generate your first    │
        │  improvement roadmap    │
        │  from your review       │
        │  analysis data.         │
        │                         │
        │  [Generate Plan ✨ 0.5cr]│
        └─────────────────────────┘
```

### 13.6 Prerequisite Check

Before showing the generate form, check if the business has analysis data. If not:

```
        ┌─────────────────────────┐
        │                         │
        │    ⚠️ Analysis Required  │
        │                         │
        │  Content generation     │
        │  requires review        │
        │  analysis data.         │
        │                         │
        │  [Run Analysis First →]  │
        └─────────────────────────┘
```

---

## 14. Responsive Design

### Breakpoints

| Breakpoint | Layout Changes |
|------------|---------------|
| **Desktop** (≥1024px) | Full layout as shown in wireframes. 2-3 column grids. Side drawers. |
| **Tablet** (768-1023px) | 2-column grids. Config forms as full-width modals instead of drawers. |
| **Mobile** (<768px) | Single column. Stacked cards. Bottom sheets for config. Collapsible sections in action plans. |

### Mobile-Specific Adaptations

1. **Content Hub**: Single column of feature cards
2. **Template Grid**: Single column cards with larger touch targets
3. **Action Plan View**: Collapsible sections (accordion) for Immediate/Short/Medium actions
4. **Social Post Previews**: Full-width, swipeable carousel between platforms
5. **Marketing Copy Variants**: Swipeable tabs (A, B, C)
6. **Blog Post**: Full-width reading view with sticky "Copy All" button
7. **Config forms**: Full-screen modals on mobile (not drawers)
8. **Generate buttons**: Sticky bottom bar on mobile

### Social Post Mobile Layout

```
┌────────────────────────┐
│ 🐦 Twitter   230/280  │
│                        │
│ Post text here...      │
│                        │
│ #tag1 #tag2            │
│                        │
│ [📋 Copy]  [🗑 Delete]  │
├────────────────────────┤
│    ● ○ ○ ○             │
│  swipe for next        │
└────────────────────────┘
```

---

## Appendix A: shadcn/ui Components Used

| Component | Usage |
|-----------|-------|
| `Card` | ContentCard, FeatureCard, VariantCard |
| `Button` | GenerateButton, CopyButton, DeleteButton |
| `Badge` | Category badges, effort tags, variant labels |
| `Tabs` | Content hub navigation, platform filtering |
| `Sheet` | ConfigDrawer (settings panels) |
| `Dialog` | CreateTemplateDialog, ApplyTemplateDialog |
| `AlertDialog` | Delete confirmations, low credit warnings |
| `Select` | Category, scenario, format, timeframe dropdowns |
| `Textarea` | Template text, custom instructions |
| `Input` | Brand name, tagline, CTA text |
| `Checkbox` | Platform selection, config toggles |
| `RadioGroup` | Timeframe selection, writing style |
| `Slider` | Word count selector |
| `Skeleton` | Loading states |
| `Toast` | Success/error notifications |
| `Separator` | Section dividers |
| `Table` | KPI display |
| `Accordion` | Mobile action plan sections |
| `Tooltip` | Placeholder explanations, char limit info |

---

## Appendix B: Feature-to-Endpoint Mapping

| Frontend Action | API Endpoint | Credits |
|----------------|-------------|---------|
| Load templates | `GetResponseTemplates` | Free |
| Create template | `CreateResponseTemplate` | Free |
| AI customize template | `ApplyTemplate` | 0.25 |
| Delete template | `DeleteResponseTemplate` | Free |
| Generate action plan | `GenerateActionPlan` | 0.5 |
| View action plans | `GetActionPlans` | Free |
| Delete action plan | `DeleteActionPlan` | Free |
| Save social config | `SaveSocialMediaPostConfig` | Free |
| Load social config | `GetSocialMediaPostConfig` | Free |
| Generate social posts | `GenerateSocialMediaPosts` | 0.25 |
| View social posts | `GetSocialMediaPosts` | Free |
| Delete social post | `DeleteSocialMediaPost` | Free |
| Save marketing config | `SaveMarketingCopyConfig` | Free |
| Load marketing config | `GetMarketingCopyConfig` | Free |
| Generate marketing copy | `GenerateMarketingCopy` | 0.25 |
| View marketing copies | `GetMarketingCopies` | Free |
| Delete marketing copy | `DeleteMarketingCopy` | Free |
| Save blog config | `SaveBlogPostConfig` | Free |
| Load blog config | `GetBlogPostConfig` | Free |
| Generate blog post | `GenerateBlogPost` | 1.0 |
| View blog posts | `GetBlogPosts` | Free |
| Delete blog post | `DeleteBlogPost` | Free |

---

## Appendix C: Implementation Priority

Build order (matches backend phases):

### Phase 1: Foundation (Week 1-2)
1. **Shared components**: CreditCostBadge, GenerateButton, CopyToClipboard, ContentCard, EmptyState, ConfigDrawer
2. **ContentHub page**: Feature card grid with navigation
3. **Response Templates**: TemplatesPage with all CRUD operations
4. **Action Plans**: ActionPlanPage with generate, view, delete

### Phase 2: Social & Marketing (Week 3-4)
5. **Social Media Posts**: Config form + generate + previews
6. **Marketing Copy**: Config form + generate + variant display

### Phase 3: Blog & Polish (Week 5-6)
7. **Blog Posts**: Config form + generate + full post preview + SEO preview
8. **Mobile responsive**: All features adapted for mobile
9. **Polish**: Loading animations, error edge cases, empty states
