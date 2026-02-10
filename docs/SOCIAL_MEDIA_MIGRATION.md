# Social Media Post Generator - Frontend Migration Guide

> Backend changes to the Social Media Post Generator feature. This doc covers **only** the social media feature - all other content features are unchanged.

---

## Summary of Changes

| Area | What Changed |
|------|-------------|
| **New endpoint** | `SuggestSocialMediaConfig` - auto-generates config from business data (FREE) |
| **Config expanded** | 6 new fields on `SaveSocialMediaPostConfig` / `GetSocialMediaPostConfig` |
| **Generate expanded** | 3 new params: `post_type`, `hook_style`, `variants_count` |
| **Platforms expanded** | Added `tiktok` and `google_business_profile` (now 6 total) |
| **Post response expanded** | 5 new fields in each generated post object |
| **Get posts expanded** | New `post_type` filter param |

---

## 1. New Endpoint: `SuggestSocialMediaConfig`

**Purpose**: Auto-fill config form for lazy users. Call this when user first opens the social media settings, or when they click "Auto-fill" / "Suggest settings".

```
POST /walker/SuggestSocialMediaConfig
```

### Request

```json
{
  "business_id": "ChIJ..."
}
```

### Response

```json
{
  "success": true,
  "business": { "place_id": "ChIJ...", "name": "Street Burger" },
  "suggested_config": {
    "brand_name": "Street Burger",
    "brand_voice": "warm and approachable with a foodie edge",
    "brand_personality_traits": ["friendly", "passionate", "local favorite"],
    "target_audience": "young foodies and families in downtown area",
    "industry_keywords": ["craft burgers", "fresh ingredients", "gourmet", "hand-smashed"],
    "avoid_words": ["cheap", "fast food", "greasy"],
    "tone_examples": [
      "Nothing beats a hand-smashed patty on a Friday night. Our customers know it. 🍔",
      "When the reviews speak for themselves, you just smile and keep grilling."
    ],
    "default_hashtags": ["#streetburger", "#burgerlovers", "#craftburgers", "#foodie", "#localfood"],
    "call_to_action_text": "Come taste the difference!",
    "include_star_rating": true,
    "include_review_quote": true,
    "include_call_to_action": true,
    "language": "english"
  },
  "suggested_post_types": ["testimonial", "tips_based", "question_engagement"],
  "reasoning": "Street Burger has strong food quality reviews (4.7 rating). Customers frequently praise the craft ingredients and friendly staff. A warm, foodie-focused voice matches the brand personality. Tips-based posts work well because customers often share specific menu recommendations."
}
```

### Frontend Flow

```
User opens Social Media Settings for the first time
  → No config exists yet
  → Show "Auto-fill from your reviews" button
  → Call SuggestSocialMediaConfig
  → Pre-fill the form with suggested_config values
  → User can tweak any field
  → User clicks Save → calls SaveSocialMediaPostConfig
```

### Cost

**FREE** - no credits charged.

---

## 2. Updated Config Types

### Old `SocialMediaPostConfig`

```typescript
interface SocialMediaPostConfig {
  brand_name: string;
  brand_voice: 'professional' | 'casual' | 'playful' | 'authoritative';
  default_hashtags: string[];
  include_star_rating: boolean;
  include_review_quote: boolean;
  include_call_to_action: boolean;
  call_to_action_text: string;
}
```

### New `SocialMediaPostConfig`

```typescript
interface SocialMediaPostConfig {
  // Existing fields (unchanged)
  brand_name: string;
  brand_voice: string;                    // ← no longer a strict enum, accepts descriptive text too
  default_hashtags: string[];
  include_star_rating: boolean;
  include_review_quote: boolean;
  include_call_to_action: boolean;
  call_to_action_text: string;

  // NEW fields
  brand_personality_traits: string[];     // e.g. ["warm", "expert", "local favorite"]
  target_audience: string;                // e.g. "young families in urban areas"
  industry_keywords: string[];            // e.g. ["craft", "artisan", "handmade"]
  avoid_words: string[];                  // e.g. ["cheap", "discount"]
  tone_examples: string[];                // e.g. ["Nothing beats a Friday burger night 🍔"]
  language: string;                       // e.g. "english", "spanish", "arabic"
}
```

### Migration Notes

- `brand_voice` **still accepts** the old 4 values (`professional`, `casual`, `playful`, `authoritative`) but NOW also accepts **free-text descriptions** like `"warm and approachable with a foodie edge"`. Consider changing the UI from a dropdown to a text input with preset suggestions.
- All 6 new fields have **safe defaults** on the backend (`[]` for lists, `""` for strings, `"english"` for language). You can ship the UI update incrementally - old save calls without the new fields will still work.
- `SaveSocialMediaPostConfig` and `GetSocialMediaPostConfig` both support all new fields.

---

## 3. Updated Platforms

### Old

```typescript
type SocialPlatform = 'twitter' | 'facebook' | 'instagram' | 'linkedin';
```

### New

```typescript
type SocialPlatform =
  | 'twitter'
  | 'facebook'
  | 'instagram'
  | 'linkedin'
  | 'tiktok'                    // NEW
  | 'google_business_profile';  // NEW
```

### UI Additions

| Platform | Icon | Notes |
|----------|------|-------|
| **TikTok** | TikTok logo | Posts are generated as **video scripts** (hook text + narrative + CTA), not regular captions |
| **Google Business Profile** | Google "G" / pin icon | Posts are local SEO-focused updates, no hashtags |

### Platform Preview Styles

| Platform | Style |
|----------|-------|
| **Twitter/X** | Dark card, char count (red if >280), bird icon |
| **Facebook** | Blue header, white card, longer format |
| **Instagram** | Gradient border (pink/purple), hashtag-heavy, emoji-rich |
| **LinkedIn** | Professional gray/blue, minimal emojis |
| **TikTok** (NEW) | Black card with neon accent, show as "Video Script" with sections: Hook / Narrative / CTA |
| **Google Business Profile** (NEW) | White card with Google blue accent, show CTA button preview, no hashtags displayed |

---

## 4. Updated Generate Request

### Old

```typescript
socialPostApi.generate({
  business_id: string;
  review_id?: string;
  platforms?: string[];     // default: ["twitter","facebook","instagram","linkedin"]
  count?: number;           // default: 1
})
```

### New

```typescript
socialPostApi.generate({
  business_id: string;
  review_id?: string;
  platforms?: string[];     // default: ["twitter","facebook","instagram","linkedin"]
  count?: number;           // default: 1

  // NEW params
  post_type?: string;       // default: "testimonial"
  hook_style?: string;      // default: "auto"
  variants_count?: number;  // default: 1, max: 3
})
```

### `post_type` Options

| Value | Label | Description | Best For |
|-------|-------|-------------|----------|
| `testimonial` | Customer Quote | Directly quote the review with attribution | All businesses |
| `question_engagement` | Engagement Question | Frame around an audience question | Driving comments |
| `tips_based` | Customer Tip | Extract advice/insight from the review | Restaurants, services |
| `milestone_celebration` | Milestone | Frame around rating/review count achievement | High-rated businesses |
| `aggregate_insight` | Insight Spotlight | "Our customers love X - here's why..." | Businesses with strong themes |
| `story_narrative` | Customer Story | Mini journey narrative (problem -> discovery -> result) | Detailed reviews |
| `before_after` | Transformation | Frame as a change/transformation story | Salons, gyms, healthcare |

### `hook_style` Options

| Value | Label | Description |
|-------|-------|-------------|
| `auto` | Auto (Recommended) | LLM picks the best hook for the post type & platform |
| `bold_statement` | Bold Statement | "This is exactly why we do what we do." |
| `curiosity` | Curiosity | "Here's what nobody tells you about..." |
| `social_proof` | Social Proof | "Rated 4.8 by 500+ customers. Here's why..." |
| `question` | Question | "What makes the perfect dining experience?" |
| `quote_first` | Lead with Quote | Start directly with the customer's words |
| `data_point` | Data Point | Lead with a statistic from the business |

### `variants_count`

- `1` = One version per platform (default, current behavior)
- `2` = Two A/B variants per platform (labeled "A" and "B")
- `3` = Three A/B/C variants per platform

**Credit cost stays 0.25 per batch** regardless of variant count.

---

## 5. Updated Generate Response

### Old Post Object

```json
{
  "post_id": "uuid",
  "platform": "twitter",
  "post_text": "...",
  "hashtags": ["#tag1"],
  "review_quote": "...",
  "review_author": "John",
  "review_rating": 5,
  "character_count": 230
}
```

### New Post Object

```json
{
  "post_id": "uuid",
  "platform": "twitter",
  "post_text": "...",
  "hashtags": ["#tag1"],
  "review_quote": "...",
  "review_author": "John",
  "review_rating": 5,
  "character_count": 230,

  "post_type": "testimonial",
  "hook_style_used": "social_proof",
  "variant_label": "A",
  "visual_suggestion": "Photo of a burger with warm restaurant lighting in background",
  "graphic_type": "photo"
}
```

### New Fields

| Field | Type | Description |
|-------|------|-------------|
| `post_type` | `string` | Which post type was generated |
| `hook_style_used` | `string` | Which hook strategy was used |
| `variant_label` | `string` | `"A"`, `"B"`, `"C"` if variants > 1, empty string if single |
| `visual_suggestion` | `string` | AI-suggested image/visual description to pair with the post |
| `graphic_type` | `string` | `"photo"`, `"text_overlay"`, `"carousel"`, `"video"`, `"reel"` |

### Full Response Shape

```json
{
  "success": true,
  "business": { "place_id": "ChIJ...", "name": "Street Burger" },
  "post_type": "testimonial",
  "hook_style": "auto",
  "variants_count": 2,
  "posts_generated": 8,
  "posts": [ /* array of post objects */ ],
  "credits": { "used": 0.25, "remaining": 4.75 }
}
```

---

## 6. Updated Get Posts Request

### Old

```typescript
socialPostApi.getPosts({
  business_id: string;
  platform?: string;
})
```

### New

```typescript
socialPostApi.getPosts({
  business_id: string;
  platform?: string;
  post_type?: string;     // NEW - filter by post type
})
```

---

## 7. Updated TypeScript Types

Replace the social media section in `src/types/content.ts`:

```typescript
// ═══════════════════════════════════════════════════════════════
// SOCIAL MEDIA POSTS
// ═══════════════════════════════════════════════════════════════

export type SocialPlatform =
  | 'twitter'
  | 'facebook'
  | 'instagram'
  | 'linkedin'
  | 'tiktok'
  | 'google_business_profile';

export type SocialPostType =
  | 'testimonial'
  | 'question_engagement'
  | 'tips_based'
  | 'milestone_celebration'
  | 'aggregate_insight'
  | 'story_narrative'
  | 'before_after';

export type HookStyle =
  | 'auto'
  | 'bold_statement'
  | 'curiosity'
  | 'social_proof'
  | 'question'
  | 'quote_first'
  | 'data_point';

export type GraphicType =
  | 'photo'
  | 'text_overlay'
  | 'carousel'
  | 'video'
  | 'reel';

export interface SocialMediaPostConfig {
  brand_name: string;
  brand_voice: string;
  default_hashtags: string[];
  include_star_rating: boolean;
  include_review_quote: boolean;
  include_call_to_action: boolean;
  call_to_action_text: string;
  brand_personality_traits: string[];
  target_audience: string;
  industry_keywords: string[];
  avoid_words: string[];
  tone_examples: string[];
  language: string;
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
  post_type: SocialPostType;
  hook_style_used: HookStyle;
  variant_label: string;
  visual_suggestion: string;
  graphic_type: GraphicType;
  generated_at: string;
}

export interface SocialPostsResponse {
  success: boolean;
  business: { place_id: string; name: string };
  post_type: SocialPostType;
  hook_style: HookStyle;
  variants_count: number;
  posts_generated: number;
  posts: SocialMediaPost[];
  credits: CreditInfo;
}

export interface SuggestedConfigResponse {
  success: boolean;
  business: { place_id: string; name: string };
  suggested_config: SocialMediaPostConfig;
  suggested_post_types: SocialPostType[];
  reasoning: string;
}
```

---

## 8. Updated API Client

```typescript
export const socialPostApi = {
  // NEW - auto-suggest config from business data (FREE)
  suggestConfig: (data: { business_id: string }) =>
    apiClient.post('/walker/SuggestSocialMediaConfig', data),

  saveConfig: (data: {
    brand_name?: string;
    brand_voice?: string;
    default_hashtags?: string[];
    include_star_rating?: boolean;
    include_review_quote?: boolean;
    include_call_to_action?: boolean;
    call_to_action_text?: string;
    // NEW fields
    brand_personality_traits?: string[];
    target_audience?: string;
    industry_keywords?: string[];
    avoid_words?: string[];
    tone_examples?: string[];
    language?: string;
  }) => apiClient.post('/walker/SaveSocialMediaPostConfig', data),

  getConfig: () =>
    apiClient.post('/walker/GetSocialMediaPostConfig', {}),

  generate: (data: {
    business_id: string;
    review_id?: string;
    platforms?: string[];
    count?: number;
    // NEW params
    post_type?: SocialPostType;
    hook_style?: HookStyle;
    variants_count?: number;
  }) => apiClient.post('/walker/GenerateSocialMediaPosts', data),

  getPosts: (data: {
    business_id: string;
    platform?: string;
    post_type?: string;       // NEW filter
  }) => apiClient.post('/walker/GetSocialMediaPosts', data),

  deletePost: (data: { business_id: string; post_id: string }) =>
    apiClient.post('/walker/DeleteSocialMediaPost', data),
};
```

---

## 9. UI Changes Summary

### Settings Form (SocialConfigForm)

**Old form** had 5 fields. **New form** has 11 fields. Recommended layout:

```
┌─────────────────────────────────────────────────┐
│  Social Media Settings                          │
│                                                 │
│  ┌─ Brand Identity ──────────────────────────┐  │
│  │                                           │  │
│  │  Brand Name:  [Street Burger________]     │  │
│  │                                           │  │
│  │  Brand Voice: [warm and approachable_]    │  │
│  │  (or pick: Professional | Casual | ...)   │  │
│  │                                           │  │
│  │  Personality Traits:                      │  │
│  │  [friendly ×] [local ×] [+ Add]          │  │
│  │                                           │  │
│  │  Target Audience:                         │  │
│  │  [young foodies and families_______]      │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌─ Content Rules ───────────────────────────┐  │
│  │                                           │  │
│  │  Industry Keywords:                       │  │
│  │  [craft burgers ×] [gourmet ×] [+ Add]   │  │
│  │                                           │  │
│  │  Words to Avoid:                          │  │
│  │  [cheap ×] [fast food ×] [+ Add]         │  │
│  │                                           │  │
│  │  Tone Examples:                           │  │
│  │  "Nothing beats a Friday burger..." [×]   │  │
│  │  [+ Add example]                          │  │
│  │                                           │  │
│  │  Language: [English ▾]                    │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  ┌─ Post Defaults ───────────────────────────┐  │
│  │                                           │  │
│  │  Default Hashtags:                        │  │
│  │  [#streetburger ×] [#foodie ×] [+ Add]   │  │
│  │                                           │  │
│  │  [✓] Include star rating                 │  │
│  │  [✓] Include review quote                │  │
│  │  [✓] Include call-to-action              │  │
│  │                                           │  │
│  │  CTA Text: [Come taste the difference!]   │  │
│  └───────────────────────────────────────────┘  │
│                                                 │
│  [✨ Auto-fill from Reviews]  [Save Settings]   │
└─────────────────────────────────────────────────┘
```

The **"Auto-fill from Reviews"** button calls `SuggestSocialMediaConfig` and pre-fills all fields.

### Generate Form (Updated)

```
┌────────────────── Generate New Posts ────────────────────┐
│                                                          │
│  Review Source:                                           │
│  (●) Auto-select best reviews                            │
│  ( ) Choose specific review     [Select review ▾]        │
│                                                          │
│  Post Type:                                              │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌──────────┐  │
│  │ Customer │ │ Engagement│ │ Customer │ │Milestone │  │
│  │  Quote   │ │ Question  │ │   Tip    │ │          │  │
│  │    ●     │ │           │ │          │ │          │  │
│  └──────────┘ └───────────┘ └──────────┘ └──────────┘  │
│  ┌──────────┐ ┌───────────┐ ┌──────────┐               │
│  │ Insight  │ │ Customer  │ │Transform-│               │
│  │Spotlight │ │  Story    │ │  ation   │               │
│  └──────────┘ └───────────┘ └──────────┘               │
│                                                          │
│  Hook Style:   [Auto (Recommended) ▾]                    │
│                                                          │
│  Platforms:                                              │
│  [✓] Twitter/X   [✓] Facebook    [✓] Instagram          │
│  [✓] LinkedIn    [ ] TikTok      [ ] Google Business     │
│                                                          │
│  Posts per review: [1 ▾]    Variants: [1 ▾] (A/B test)  │
│                                                          │
│  [Generate Posts ✨ 0.25 credits]                         │
└──────────────────────────────────────────────────────────┘
```

### Post Preview Card (Updated)

```
┌──────────────────────────────────────────────────┐
│  🐦 Twitter/X              Variant A   230/280   │
│  Type: Customer Quote    Hook: Social Proof       │
│                                                   │
│  "The burgers here are incredible!"               │
│  - John D. ⭐⭐⭐⭐⭐                                │
│                                                   │
│  Rated 4.8 by 500+ customers. Here's why John    │
│  keeps coming back 🍔                             │
│  #streetburger #burgerlovers                      │
│                                                   │
│  ┌─ Visual Suggestion ────────────────────────┐   │
│  │  📷 photo: Close-up of signature burger    │   │
│  │  with warm restaurant lighting             │   │
│  └────────────────────────────────────────────┘   │
│                                                   │
│  [📋 Copy Text] [🖼 Copy Visual Prompt] [🗑 Delete]│
└──────────────────────────────────────────────────┘
```

New elements on the card:
- **Variant label** (A/B/C) badge - only show when variants > 1
- **Post type** + **hook style** tags
- **Visual suggestion** collapsible section with graphic_type icon + description
- **"Copy Visual Prompt"** button - copies `visual_suggestion` text (useful for AI image generators)

### Variant Comparison View (New)

When `variants_count > 1`, group posts by platform and show variants side-by-side:

```
── Twitter/X ──────────────────────────────────────────
┌─── Variant A ───────────┐  ┌─── Variant B ───────────┐
│ Social proof hook...     │  │ Curiosity hook...        │
│ 230/280 chars            │  │ 245/280 chars            │
│ [📋 Copy]                │  │ [📋 Copy]                │
└──────────────────────────┘  └──────────────────────────┘

── Instagram ──────────────────────────────────────────
┌─── Variant A ───────────┐  ┌─── Variant B ───────────┐
│ Visual aspirational...   │  │ Question engagement...   │
│ 450 chars                │  │ 380 chars                │
│ [📋 Copy]                │  │ [📋 Copy]                │
└──────────────────────────┘  └──────────────────────────┘
```

---

## 10. Backward Compatibility

| Concern | Status |
|---------|--------|
| Old `SaveSocialMediaPostConfig` calls without new fields | **Works** - all new fields have defaults |
| Old `GenerateSocialMediaPosts` calls without `post_type`/`hook_style` | **Works** - defaults to `testimonial` + `auto` |
| Old `GetSocialMediaPosts` calls without `post_type` filter | **Works** - returns all posts |
| Old posts missing new fields (`post_type`, `visual_suggestion`, etc.) | **Safe** - they'll have empty/default values |
| `brand_voice` as old enum value (`"professional"`) | **Works** - still accepted |

**No breaking changes.** All old API calls continue to work. New features are opt-in.

---

## 11. Quick Reference: All Social Media Endpoints

| Endpoint | Method | Cost | What's New |
|----------|--------|------|-----------|
| `SuggestSocialMediaConfig` | POST | FREE | **Entirely new** |
| `SaveSocialMediaPostConfig` | POST | FREE | +6 new fields |
| `GetSocialMediaPostConfig` | POST | FREE | Returns +6 new fields |
| `GenerateSocialMediaPosts` | POST | 0.25 | +3 new params, +2 platforms, +5 response fields |
| `GetSocialMediaPosts` | POST | FREE | +`post_type` filter, +5 fields per post |
| `DeleteSocialMediaPost` | POST | FREE | Unchanged |
