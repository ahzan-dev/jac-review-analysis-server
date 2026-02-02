# Frontend Integration: Review Reply System

## API Endpoints Summary

| Endpoint | Purpose | Credits |
|----------|---------|---------|
| `SaveReplyPromptConfig` | Save reply preferences | - |
| `GetReplyPromptConfig` | Get current config | - |
| `GenerateReviewReply` | Single reply | 0.25 |
| `BulkGenerateReviewReplies` | Multiple replies | 0.25 each |
| `RegenerateReviewReply` | Regenerate reply | 0.25 |
| `GetReviewReplies` | List all replies | - |
| `DeleteReviewReply` | Delete a reply | - |

---

## UI Components

### 1. Reply Settings Modal

**Location:** Settings page or modal accessible from review list

```tsx
// ReplySettingsForm.tsx
interface ReplyConfig {
  tone: "friendly" | "formal" | "casual" | "friendly_professional";
  max_length: "short" | "medium" | "long";
  include_name: boolean;
  offer_resolution: boolean;
  sign_off: string;
  custom_instructions: string;
}
```

**UI Elements:**
- Dropdown: Tone selection
- Dropdown: Reply length
- Toggle: Include reviewer name
- Toggle: Offer resolution for negative reviews
- Input: Custom sign-off text
- Textarea: Custom instructions

**API Call:**
```ts
POST /walker/SaveReplyPromptConfig
Body: { tone, max_length, include_name, offer_resolution, sign_off, custom_instructions }
```

---

### 2. Review List with Reply Actions

**Location:** Business detail page → Reviews tab

**For each review card, show:**

```
┌─────────────────────────────────────────────────────────┐
│ ★★★★☆  John Doe                           2 days ago   │
│ "Great food but slow service..."                        │
│                                                         │
│ Sentiment: Mixed  │  Themes: Service, Food Quality     │
│                                                         │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 💬 Generated Reply                                  │ │
│ │ "Thank you John for your feedback..."              │ │
│ │                                     [Copy] [Regen] │ │
│ └─────────────────────────────────────────────────────┘ │
│                                                         │
│ [Generate Reply]  (if no reply exists)                  │
└─────────────────────────────────────────────────────────┘
```

**States:**
1. **No reply** → Show "Generate Reply" button
2. **Has reply** → Show reply text + Copy/Regenerate buttons
3. **Loading** → Show spinner

---

### 3. Single Reply Generation

**Trigger:** Click "Generate Reply" button on review card

```ts
// API Call
POST /walker/GenerateReviewReply
Body: { business_id, review_id }

// Response
{
  "success": true,
  "reply": {
    "reply_id": "uuid",
    "reply_text": "Thank you for...",
    "generated_at": "2024-01-15T10:30:00"
  },
  "credits": {
    "used": 0.25,
    "remaining": 4.75
  }
}
```

**UI Flow:**
1. User clicks "Generate Reply"
2. Show loading spinner
3. On success → Display reply with Copy/Regenerate buttons
4. Update credit balance in header

---

### 4. Bulk Reply Generation

**Location:** Reviews page toolbar or floating action button

**UI Options:**

```
┌─────────────────────────────────────────┐
│ Bulk Generate Replies                   │
├─────────────────────────────────────────┤
│ Filter by:                              │
│ ○ All reviews without replies           │
│ ○ Negative reviews only                 │
│ ○ Positive reviews only                 │
│ ○ Selected reviews (3 selected)         │
│                                         │
│ Max replies: [10 ▼]                     │
│                                         │
│ Estimated cost: 2.5 credits             │
│ Your balance: 5.0 credits               │
│                                         │
│ [Cancel]              [Generate 10]     │
└─────────────────────────────────────────┘
```

**API Call:**
```ts
POST /walker/BulkGenerateReviewReplies
Body: {
  business_id: "xxx",
  filter_sentiment: "negative",  // or "" for all
  max_replies: 10,
  // OR specific reviews:
  review_ids: ["id1", "id2", "id3"]
}
```

**Response:**
```json
{
  "success": true,
  "summary": {
    "total_requested": 10,
    "generated": 10,
    "failed": 0
  },
  "credits": {
    "used": 2.5,
    "remaining": 2.5
  },
  "replies": [
    { "review_id": "xxx", "reply_id": "yyy", "reply_text": "..." }
  ]
}
```

---

### 5. Reply Actions

#### Copy to Clipboard
```ts
const copyReply = (text: string) => {
  navigator.clipboard.writeText(text);
  toast.success("Reply copied!");
};
```

#### Regenerate Reply
```ts
POST /walker/RegenerateReviewReply
Body: { business_id, review_id }
// Replaces existing reply, costs 0.25 credits
```

#### Delete Reply
```ts
POST /walker/DeleteReviewReply
Body: { business_id, review_id }
```

---

## Page Structure

### Reviews Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Business Name - Reviews                    [⚙️ Reply Settings]│
├─────────────────────────────────────────────────────────────┤
│ Filters: [All ▼] [Rating ▼] [Sentiment ▼]                   │
│                                                             │
│ [□ Select All]  [Bulk Generate Replies]  Showing 50 reviews │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ ┌─ Review Card ──────────────────────────────────────────┐  │
│ │ [□] ★★☆☆☆  Jane Smith                     1 week ago  │  │
│ │     "Terrible experience..."                           │  │
│ │     Sentiment: Negative                                │  │
│ │                                                        │  │
│ │     [Generate Reply 0.25💳]                            │  │
│ └────────────────────────────────────────────────────────┘  │
│                                                             │
│ ┌─ Review Card ──────────────────────────────────────────┐  │
│ │ [□] ★★★★★  Bob Wilson                     3 days ago  │  │
│ │     "Amazing service!"                                 │  │
│ │     Sentiment: Positive                                │  │
│ │                                                        │  │
│ │     ┌─ Reply ────────────────────────────────────────┐ │  │
│ │     │ "Thank you Bob! We're thrilled..."             │ │  │
│ │     │                            [📋 Copy] [🔄 Regen] │ │  │
│ │     └────────────────────────────────────────────────┘ │  │
│ └────────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## State Management

### Zustand Store Example

```ts
interface ReviewReplyState {
  replyConfig: ReplyConfig | null;
  replies: Map<string, ReviewReply>;  // review_id -> reply
  loading: Set<string>;  // review_ids currently generating

  // Actions
  fetchConfig: () => Promise<void>;
  saveConfig: (config: ReplyConfig) => Promise<void>;
  generateReply: (businessId: string, reviewId: string) => Promise<void>;
  bulkGenerate: (businessId: string, options: BulkOptions) => Promise<void>;
  regenerateReply: (businessId: string, reviewId: string) => Promise<void>;
  deleteReply: (businessId: string, reviewId: string) => Promise<void>;
}
```

---

## API Service

```ts
// api/replyService.ts

export const replyService = {
  getConfig: () =>
    api.post('/walker/GetReplyPromptConfig', {}),

  saveConfig: (config: ReplyConfig) =>
    api.post('/walker/SaveReplyPromptConfig', config),

  generateSingle: (businessId: string, reviewId: string) =>
    api.post('/walker/GenerateReviewReply', { business_id: businessId, review_id: reviewId }),

  generateBulk: (businessId: string, options: BulkOptions) =>
    api.post('/walker/BulkGenerateReviewReplies', { business_id: businessId, ...options }),

  regenerate: (businessId: string, reviewId: string) =>
    api.post('/walker/RegenerateReviewReply', { business_id: businessId, review_id: reviewId }),

  getAll: (businessId: string) =>
    api.post('/walker/GetReviewReplies', { business_id: businessId }),

  delete: (businessId: string, reviewId: string) =>
    api.post('/walker/DeleteReviewReply', { business_id: businessId, review_id: reviewId }),
};
```

---

## Credit Display

Show credit cost before actions:

```tsx
<Button onClick={generateReply} disabled={credits < 0.25}>
  Generate Reply (0.25 💳)
</Button>

// For bulk
<div>
  Estimated cost: {selectedCount * 0.25} credits
  Your balance: {credits} credits
</div>
```

---

## Error Handling

```ts
// Common errors
{
  "success": false,
  "error": "Insufficient credits. Required: 0.25, Available: 0"
}

{
  "success": false,
  "error": "Reply already exists for this review",
  "existing_reply": { ... }
}

{
  "success": false,
  "error": "Review not found: xxx"
}
```

---

## Toast Notifications

```ts
// Success
toast.success("Reply generated! (0.25 credits used)");
toast.success("10 replies generated! (2.5 credits used)");
toast.success("Reply copied to clipboard");

// Error
toast.error("Insufficient credits");
toast.error("Failed to generate reply");

// Info
toast.info("Reply already exists. Use regenerate to create a new one.");
```

---

## Recommended Component Library

Using shadcn/ui:
- `Dialog` - Reply settings modal
- `Button` - Actions
- `Select` - Dropdowns
- `Switch` - Toggles
- `Textarea` - Custom instructions
- `Card` - Review cards
- `Badge` - Sentiment labels
- `Skeleton` - Loading states
