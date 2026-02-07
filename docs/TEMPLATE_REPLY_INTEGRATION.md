# Review Reply Feature - Complete API Reference

## Overview

The Review Reply feature lets users generate replies to customer reviews. There are **two pathways**:

| Pathway | Endpoint | Cost | How it works |
|---------|----------|------|-------------|
| **AI Reply** | `GenerateReviewReply` | 0.25 credits | LLM generates a unique reply using review context + user config |
| **Template Reply** | `ApplyTemplate` | FREE | User picks a template, system fills `{placeholders}` with rule-based mapping |

Both pathways store the result as a `ReviewReply` node connected to the review via a `HasReply` edge. Every reply has a `source` field (`"ai"` or `"template"`) so the frontend can distinguish them.

---

## Graph Structure

```
root ──> ReplyPromptConfig          (user's AI reply preferences - one per user)
root ──> ResponseTemplate           (system + user-created templates)

Business ──(HasReview)──> Review ──(HasReply)──> ReviewReply
                                                    ├── reply_id: str
                                                    ├── reply_text: str
                                                    ├── generated_at: str (ISO)
                                                    ├── credits_used: float (0.25 for AI, 0.0 for template)
                                                    ├── tone_used: str
                                                    ├── review_sentiment: str
                                                    ├── review_rating: int
                                                    ├── source: str ("ai" | "template")
                                                    └── template_id: str (empty if source="ai")
```

**Constraint**: Each review can have at most **one** `ReviewReply`. Both `GenerateReviewReply` and `ApplyTemplate` check for duplicates and reject if a reply already exists. Use `DeleteReviewReply` first to replace.

---

## Endpoints

### 1. Configuration

#### `POST /walker/SaveReplyPromptConfig`

Save/update the user's AI reply generation preferences. These settings apply to all AI-generated replies.

**Request:**
```json
{
  "tone": "friendly_professional",
  "max_length": "medium",
  "include_name": true,
  "offer_resolution": true,
  "sign_off": "The Acme Team",
  "custom_instructions": "Always mention our loyalty program"
}
```

| Field | Type | Default | Options |
|-------|------|---------|---------|
| `tone` | string | `"friendly_professional"` | `friendly`, `formal`, `casual`, `friendly_professional` |
| `max_length` | string | `"medium"` | `short` (1-2 sentences), `medium` (2-3), `long` (3-4) |
| `include_name` | bool | `true` | Include reviewer's name in reply |
| `offer_resolution` | bool | `true` | Offer resolution for negative reviews |
| `sign_off` | string | `""` | Custom sign-off text |
| `custom_instructions` | string | `""` | Additional instructions for the LLM |

**Response:**
```json
{
  "success": true,
  "message": "Reply configuration updated",
  "config": {
    "tone": "friendly_professional",
    "max_length": "medium",
    "include_name": true,
    "offer_resolution": true,
    "sign_off": "The Acme Team",
    "custom_instructions": "Always mention our loyalty program"
  }
}
```

#### `POST /walker/GetReplyPromptConfig`

Get the current AI reply configuration. Returns defaults if none saved.

**Request:** `{}` (no parameters)

**Response:**
```json
{
  "success": true,
  "config": {
    "tone": "friendly_professional",
    "max_length": "medium",
    "include_name": true,
    "offer_resolution": true,
    "sign_off": "",
    "custom_instructions": "",
    "created_at": "2026-02-01T10:00:00",
    "updated_at": "2026-02-08T12:00:00"
  }
}
```

If no config saved yet, response includes `"is_default": true`.

---

### 2. AI Reply (0.25 credits)

#### `POST /walker/GenerateReviewReply`

Generate an AI-powered reply for a single review. Uses the user's `ReplyPromptConfig` settings.

**Request:**
```json
{
  "business_id": "ChIJ...",
  "review_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "reply": {
    "reply_id": "550e8400-...",
    "reply_text": "Dear John, thank you so much for your wonderful review! We're thrilled...",
    "generated_at": "2026-02-08T12:00:00"
  },
  "review": {
    "review_id": "uuid",
    "author": "John",
    "rating": 5,
    "sentiment": "positive"
  },
  "credits": {
    "used": 0.25,
    "remaining": 4.75
  }
}
```

**Errors:**
- `"Insufficient credits"` - Not enough credits (need 0.25)
- `"Business not found"` - Invalid business_id
- `"Review not found"` - Invalid review_id
- `"Reply already exists for this review"` - Duplicate; includes `existing_reply` object

#### `POST /walker/BulkGenerateReviewReplies`

Generate AI replies for multiple reviews at once. Credits are deducted per successful reply.

**Request:**
```json
{
  "business_id": "ChIJ...",
  "review_ids": ["uuid1", "uuid2"],
  "filter_sentiment": "negative",
  "filter_no_reply": true,
  "max_replies": 10
}
```

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `business_id` | string | required | Target business |
| `review_ids` | list[str] | `[]` | Specific reviews (empty = use filters) |
| `filter_sentiment` | string | `""` | Filter by sentiment: `positive`, `negative`, `neutral`, `mixed` |
| `filter_no_reply` | bool | `true` | Only process reviews without existing replies |
| `max_replies` | int | `10` | Maximum replies to generate |

**Response:**
```json
{
  "success": true,
  "business": { "place_id": "ChIJ...", "name": "Acme Restaurant" },
  "summary": {
    "total_requested": 5,
    "generated": 4,
    "failed": 1
  },
  "credits": { "used": 1.0, "remaining": 3.75 },
  "replies": [
    {
      "review_id": "uuid1",
      "reply_id": "uuid",
      "reply_text": "Thank you...",
      "author": "John",
      "rating": 5,
      "sentiment": "positive"
    }
  ],
  "failures": [
    { "review_id": "uuid5", "error": "LLM timeout" }
  ]
}
```

If user can't afford all requested replies, it generates as many as credits allow.

#### `POST /walker/RegenerateReviewReply`

Delete existing reply and generate a fresh AI reply. Costs 0.25 credits.

**Request:**
```json
{
  "business_id": "ChIJ...",
  "review_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "regenerated": true,
  "reply": {
    "reply_id": "new-uuid",
    "reply_text": "Dear John, we truly appreciate...",
    "generated_at": "2026-02-08T14:00:00"
  },
  "previous_reply": "Dear John, thank you so much...",
  "review": {
    "review_id": "uuid",
    "author": "John",
    "rating": 5,
    "sentiment": "positive"
  },
  "credits": { "used": 0.25, "remaining": 4.5 }
}
```

---

### 3. Template Reply (FREE)

#### `POST /walker/GetResponseTemplates`

Browse all available templates. System templates are auto-seeded on first call.

**Request:**
```json
{
  "category": "positive",
  "scenario": "praise",
  "business_type": "RESTAURANT"
}
```

All parameters are optional filters. Empty string = no filter.

**Response:**
```json
{
  "success": true,
  "count": 3,
  "templates": [
    {
      "template_id": "uuid",
      "name": "Grateful Acknowledgment",
      "category": "positive",
      "scenario": "praise",
      "business_type": "GENERIC",
      "template_text": "Dear {reviewer_name}, thank you for your kind words about {specific_mention}...",
      "placeholders": ["reviewer_name", "specific_mention", "business_name", "sign_off"],
      "tone": "friendly_professional",
      "is_system": true,
      "usage_count": 42
    }
  ],
  "filters_applied": {
    "category": "positive",
    "scenario": "praise",
    "business_type": "RESTAURANT"
  }
}
```

#### `POST /walker/CreateResponseTemplate`

Create a custom template. Use `{placeholder_name}` syntax in template_text.

**Request:**
```json
{
  "name": "My Custom Thank You",
  "category": "positive",
  "scenario": "praise",
  "business_type": "RESTAURANT",
  "template_text": "Hi {reviewer_name}! Thanks for dining at {business_name}. We're glad you loved {specific_mention}! - {sign_off}",
  "tone": "casual"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Template created",
  "template": {
    "template_id": "uuid",
    "name": "My Custom Thank You",
    "category": "positive",
    "scenario": "praise",
    "business_type": "RESTAURANT",
    "placeholders": ["reviewer_name", "business_name", "specific_mention", "sign_off"]
  }
}
```

Placeholders are auto-extracted from `{...}` patterns in template_text. Max 2000 characters.

#### `POST /walker/GetSuggestedTemplates`

Get templates matching a specific review's sentiment/rating. Useful for showing relevant templates in the reply dialog.

**Request:**
```json
{
  "business_id": "ChIJ...",
  "review_id": "uuid"
}
```

**Matching logic:**
- Rating 4-5 -> category `"positive"`
- Rating 1-2 -> category `"negative"`
- Rating 3 -> category `"neutral"`
- Also matches `"mixed"` category templates
- Filters by business type (includes matching type + `GENERIC`)
- Sorted by `usage_count` descending (most popular first)

**Response:**
```json
{
  "success": true,
  "review": {
    "review_id": "uuid",
    "author": "John",
    "rating": 5,
    "sentiment": "positive"
  },
  "matched_category": "positive",
  "templates": [
    {
      "template_id": "uuid",
      "name": "Grateful Acknowledgment",
      "category": "positive",
      "scenario": "praise",
      "business_type": "GENERIC",
      "template_text": "Dear {reviewer_name}, ...",
      "placeholders": ["reviewer_name", "business_name"],
      "tone": "friendly_professional",
      "is_system": true,
      "usage_count": 42
    }
  ],
  "total": 5
}
```

#### `POST /walker/ApplyTemplate`

Apply a template to a review. Fills placeholders using rule-based mapping, creates a `ReviewReply` node. **FREE** (no credits deducted).

**Request:**
```json
{
  "template_id": "uuid",
  "business_id": "ChIJ...",
  "review_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "reply": {
    "reply_id": "550e8400-...",
    "reply_text": "Dear John, thank you for your kind words about the food quality...",
    "generated_at": "2026-02-08T12:00:00",
    "source": "template",
    "template_id": "uuid"
  },
  "template_used": "Grateful Acknowledgment",
  "review": {
    "review_id": "uuid",
    "author": "John",
    "rating": 5,
    "sentiment": "positive"
  },
  "credits": {
    "used": 0,
    "remaining": 5.0
  }
}
```

**Errors:**
- `"Template not found"` - Invalid template_id
- `"Business not found"` - Invalid business_id
- `"Review not found"` - Invalid review_id
- `"Review already has a reply. Delete the existing reply first."` - Duplicate check

**Placeholder mapping rules:**

| Placeholder | Filled with | Fallback |
|---|---|---|
| `{reviewer_name}` | `review.author` | `"valued customer"` |
| `{business_name}` | `business.name` | `"our business"` |
| `{specific_mention}` | First item from `review.themes` | `"your experience"` |
| `{business_strength}` | First item from `analysis.delighters` | `"our service"` |
| `{specific_issue}` | First theme (if negative review) | `"your concern"` |
| `{area_for_improvement}` | First item from `analysis.pain_points` | `"the areas you mentioned"` |
| `{positive_aspect}` | First theme (if positive review) | `"the things you enjoyed"` |
| `{sign_off}` | `business.name + " Team"` | `"The Team"` |
| `{contact_info}` | (static) | `"our customer service team"` |

#### `POST /walker/DeleteResponseTemplate`

Delete a user-created template. System templates cannot be deleted.

**Request:**
```json
{ "template_id": "uuid" }
```

**Response:**
```json
{
  "success": true,
  "deleted": { "template_id": "uuid", "name": "My Custom Template" }
}
```

---

### 4. Reply Management

#### `POST /walker/GetReviewReplies`

Get all reviews that have replies for a business.

**Request:**
```json
{
  "business_id": "ChIJ...",
  "limit": 50
}
```

**Response:**
```json
{
  "success": true,
  "business": { "place_id": "ChIJ...", "name": "Acme Restaurant" },
  "stats": {
    "total_reviews": 150,
    "reviews_with_replies": 42,
    "reply_coverage": "28.0%"
  },
  "replies": [
    {
      "review": {
        "review_id": "uuid",
        "author": "John",
        "rating": 5,
        "text": "Great food and amazing service!",
        "sentiment": "positive",
        "date": "2026-01-15"
      },
      "reply": {
        "reply_id": "uuid",
        "reply_text": "Dear John, thank you...",
        "generated_at": "2026-02-08T12:00:00",
        "tone_used": "friendly_professional",
        "credits_used": 0.25,
        "source": "ai",
        "template_id": ""
      }
    },
    {
      "review": {
        "review_id": "uuid2",
        "author": "Jane",
        "rating": 4,
        "text": "Nice place, will come back",
        "sentiment": "positive",
        "date": "2026-01-20"
      },
      "reply": {
        "reply_id": "uuid2",
        "reply_text": "Dear Jane, thank you for your kind words...",
        "generated_at": "2026-02-08T12:30:00",
        "tone_used": "friendly_professional",
        "credits_used": 0.0,
        "source": "template",
        "template_id": "tmpl-uuid"
      }
    }
  ]
}
```

#### `POST /walker/GetReviews` (reply data within)

When fetching reviews via `GetReviews`, each review includes reply info:

```json
{
  "review_id": "uuid",
  "author": "John",
  "rating": 5,
  "text": "Great food!",
  "has_generated_reply": true,
  "generated_reply": {
    "reply_id": "uuid",
    "reply_text": "Dear John, thank you...",
    "generated_at": "2026-02-08T12:00:00",
    "source": "ai",
    "template_id": ""
  }
}
```

The `source` and `template_id` fields tell the frontend whether this was AI-generated or template-based.

#### `POST /walker/DeleteReviewReply`

Delete a reply (AI or template) from a review.

**Request:**
```json
{
  "business_id": "ChIJ...",
  "review_id": "uuid"
}
```

**Response:**
```json
{
  "success": true,
  "deleted": {
    "reply_id": "uuid",
    "reply_text": "Dear John, thank you..."
  },
  "review": {
    "review_id": "uuid",
    "author": "John"
  }
}
```

---

## TypeScript Types

```typescript
// ── Core Types ──

interface ReviewReply {
  reply_id: string;
  reply_text: string;
  generated_at: string;
  tone_used: string;
  credits_used: number;           // 0.25 for AI, 0.0 for template
  source: "ai" | "template";
  template_id: string;            // empty string if source="ai"
}

interface ReplyPromptConfig {
  tone: "friendly" | "formal" | "casual" | "friendly_professional";
  max_length: "short" | "medium" | "long";
  include_name: boolean;
  offer_resolution: boolean;
  sign_off: string;
  custom_instructions: string;
  created_at: string | null;
  updated_at: string | null;
}

interface ResponseTemplate {
  template_id: string;
  name: string;
  category: "positive" | "negative" | "neutral" | "mixed";
  scenario: string;
  business_type: string;
  template_text: string;
  placeholders: string[];
  tone: string;
  is_system: boolean;
  usage_count: number;
}

// ── Response Types ──

interface GenerateReplyResponse {
  success: boolean;
  reply: {
    reply_id: string;
    reply_text: string;
    generated_at: string;
  };
  review: {
    review_id: string;
    author: string;
    rating: number;
    sentiment: string;
  };
  credits: {
    used: number;             // 0.25
    remaining: number;
  };
}

interface ApplyTemplateResponse {
  success: boolean;
  reply: {
    reply_id: string;
    reply_text: string;
    generated_at: string;
    source: "template";
    template_id: string;
  };
  template_used: string;
  review: {
    review_id: string;
    author: string;
    rating: number;
    sentiment: string;
  };
  credits: {
    used: 0;                  // always 0 (free)
    remaining: number;
  };
}

interface SuggestedTemplatesResponse {
  success: boolean;
  review: {
    review_id: string;
    author: string;
    rating: number;
    sentiment: string;
  };
  matched_category: "positive" | "negative" | "neutral";
  templates: ResponseTemplate[];
  total: number;
}

interface BulkReplyResponse {
  success: boolean;
  business: { place_id: string; name: string };
  summary: {
    total_requested: number;
    generated: number;
    failed: number;
  };
  credits: { used: number; remaining: number };
  replies: Array<{
    review_id: string;
    reply_id: string;
    reply_text: string;
    author: string;
    rating: number;
    sentiment: string;
  }>;
  failures: Array<{ review_id: string; error: string }> | null;
}

interface GetReviewRepliesResponse {
  success: boolean;
  business: { place_id: string; name: string };
  stats: {
    total_reviews: number;
    reviews_with_replies: number;
    reply_coverage: string;
  };
  replies: Array<{
    review: {
      review_id: string;
      author: string;
      rating: number;
      text: string;
      sentiment: string;
      date: string;
    };
    reply: ReviewReply;
  }>;
}

interface RegenerateReplyResponse {
  success: boolean;
  regenerated: true;
  reply: {
    reply_id: string;
    reply_text: string;
    generated_at: string;
  };
  previous_reply: string | null;
  review: {
    review_id: string;
    author: string;
    rating: number;
    sentiment: string;
  };
  credits: { used: number; remaining: number };
}
```

---

## UI Integration Guide

### Reply Dialog: Two Pathways

When a user clicks "Reply" on a review that has no existing reply:

```
+----------------------------------------------------+
|  Reply to "Great food and service!"                |
|  by John (5 stars, positive)                       |
|                                                    |
|  Choose a method:                                  |
|                                                    |
|  [AI Reply]           [Template Reply]             |
|   0.25 credits         Free                        |
|   Unique LLM-          Pick a template,            |
|   generated reply      auto-fill placeholders      |
+----------------------------------------------------+
```

### AI Reply Flow

1. User clicks "AI Reply"
2. (Optional) Show current `ReplyPromptConfig` with edit option
3. Call `GenerateReviewReply` with `business_id` + `review_id`
4. Show generated reply text
5. Done - reply is saved

### Template Reply Flow

1. User clicks "Template Reply"
2. Call `GetSuggestedTemplates` with `business_id` + `review_id`
3. Display matched templates sorted by popularity (usage_count)
4. User previews a template - show `template_text` with `{placeholders}` highlighted
5. User clicks "Apply"
6. Call `ApplyTemplate` - reply is filled and saved instantly (no LLM, no credits)
7. Show the filled reply text

### Reply Already Exists

If review already has a reply, show the existing reply with options:
- **View** - Read the current reply
- **Regenerate (AI)** - Call `RegenerateReviewReply` (costs 0.25 credits, replaces current)
- **Delete** - Call `DeleteReviewReply`, then user can create a new reply via either pathway

### Reply List View

Show all replies for a business with source badges:

```
+-----------------------------------------------------------+
| Reviews with Replies (42/150 - 28.0% coverage)           |
|-----------------------------------------------------------|
| John - 5 stars                    [AI] 0.25cr            |
| "Great food and service!"                                 |
| Reply: "Dear John, thank you..."                         |
|-----------------------------------------------------------|
| Jane - 4 stars                    [Template] Free         |
| "Nice ambiance, loved the pasta"                         |
| Reply: "Dear Jane, thank you for your kind words..."    |
+-----------------------------------------------------------+
```

Use `reply.source` to render the badge:
- `source === "ai"` -> show `[AI]` badge + credits_used
- `source === "template"` -> show `[Template]` badge + "Free"

---

## Migration Notes

- Existing `ReviewReply` nodes automatically get `source="ai"` and `template_id=""` (field defaults)
- No data migration script needed
- `ApplyTemplate` response structure changed (see Breaking Changes below)
- `GetReviewReplies` and `GetReviews` responses now include `source` and `template_id` (additive, non-breaking)

### Breaking Changes in `ApplyTemplate`

| Before | After |
|--------|-------|
| Cost 0.25 credits | FREE (0 credits) |
| Used LLM to fill placeholders | Rule-based placeholder mapping |
| Response: `{ reply_text, template_used, credits }` | Response: `{ reply, template_used, review, credits }` |
| `reply_text` was a top-level string | `reply_text` is nested inside `reply` object |
| Did not store a `ReviewReply` node | Creates and stores a `ReviewReply` node |
| No duplicate check | Returns error if review already has a reply |
| Created a `CreditTransaction` | No transaction created (free) |

### New Endpoint

`GetSuggestedTemplates` - did not exist before. Suggests templates matching a review.

---

## Endpoint Summary Table

| Endpoint | Method | Cost | Description |
|----------|--------|------|-------------|
| `SaveReplyPromptConfig` | POST | Free | Save AI reply preferences |
| `GetReplyPromptConfig` | POST | Free | Get AI reply preferences |
| `GenerateReviewReply` | POST | 0.25 cr | AI-generate reply for one review |
| `BulkGenerateReviewReplies` | POST | 0.25 cr each | AI-generate replies for multiple reviews |
| `RegenerateReviewReply` | POST | 0.25 cr | Replace existing reply with new AI reply |
| `GetResponseTemplates` | POST | Free | Browse/filter templates |
| `CreateResponseTemplate` | POST | Free | Create custom template |
| `GetSuggestedTemplates` | POST | Free | Get templates matching a review |
| `ApplyTemplate` | POST | Free | Apply template to review (stores reply) |
| `DeleteResponseTemplate` | POST | Free | Delete user-created template |
| `GetReviewReplies` | POST | Free | Get all replies for a business |
| `DeleteReviewReply` | POST | Free | Delete a reply |
