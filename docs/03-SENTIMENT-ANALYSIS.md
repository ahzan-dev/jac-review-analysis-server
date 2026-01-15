# Sentiment Analysis Agent

## 🎯 Overview

The **SentimentAnalyzerAgent** processes reviews in batches to extract:

- Sentiment (positive/negative/neutral/mixed)
- Sentiment score (-1.0 to 1.0)
- Main themes (business-type-specific)
- Sub-themes (granular details)
- Keywords (key phrases)
- Emotions (happy, frustrated, angry, etc.)

### Key Innovation: Batch Processing

Instead of analyzing reviews one by one, the system processes **5 reviews per LLM call**, reducing API costs by 80%.

---

## 🔄 Process Flow

```
1. Find Business node
   └─▶ Get business_type_normalized (e.g., "HOTEL")

2. Get theme definitions for business type
   └─▶ THEME_DEFINITIONS["HOTEL"] → allowed themes

3. Get unanalyzed reviews
   └─▶ Business --> Review (where analyzed = false)

4. Group reviews into batches of 5
   └─▶ [R1, R2, R3, R4, R5], [R6, R7, R8, R9, R10], ...

5. For each batch:
   ├─▶ Build batch input
   ├─▶ Call LLM: analyze_reviews_batch()
   ├─▶ Parse LLM output
   └─▶ Update Review nodes

6. Track statistics
   └─▶ sentiment_counts, theme_counts
```

---

## 📝 Input Preparation

### Allowed Themes by Business Type

The system uses business-type-specific themes:

```python
# For HOTEL
allowed_themes = [
    "Room Quality",
    "Service",
    "Facilities",
    "Food & Dining",
    "Value",
    "Location",
    "Check-in/out"
]

# For RESTAURANT
allowed_themes = [
    "Food Quality",
    "Service",
    "Ambiance",
    "Value",
    "Hygiene",
    "Location"
]
```

### Sub-theme Definitions

Each main theme has sub-themes:

```python
THEME_DEFINITIONS = {
    "HOTEL": {
        "Room Quality": [
            "Cleanliness",
            "Bed Comfort",
            "Size",
            "View",
            "Amenities",
            "Maintenance"
        ],
        "Service": [
            "Front Desk",
            "Housekeeping",
            "Concierge",
            "Response Time",
            "Staff Attitude"
        ],
        // ... more themes
    }
}
```

### Batch Input Structure

```jac
// Build batch input for LLM
review_texts = [];
for (idx, r) in enumerate(reviews) {
    review_texts.append({
        "index": idx,
        "rating": r.rating,
        "text": r.text[:500]  // Limit to 500 chars
    });
}

// Example batch:
[
    {index: 0, rating: 5, text: "Amazing hotel! Room was spacious..."},
    {index: 1, rating: 4, text: "Good experience overall..."},
    {index: 2, rating: 2, text: "Room was dirty, disappointed..."},
    {index: 3, rating: 5, text: "Best hotel ever! Staff was friendly..."},
    {index: 4, rating: 3, text: "Average stay, nothing special..."}
]
```

---

## 🤖 LLM Call

### Function Signature

```jac
def analyze_reviews_batch(
    reviews: list,              // Batch of reviews
    business_type: str,         // e.g., "HOTEL"
    allowed_themes: list,       // Main themes
    allowed_sub_themes: dict    // Theme → sub-themes mapping
) -> BatchReviewAnalysis by llm(
    incl_info={
        "reviews": reviews,
        "business_type": business_type,
        "allowed_themes": allowed_themes,
        "allowed_sub_themes": allowed_sub_themes,
        "instructions": "Analyze each review. Use ONLY themes from allowed_themes list. For sub_themes, map main theme to relevant sub-themes from allowed_sub_themes. Return analysis for each review by index."
    }
);
```

### Output Structure (LLM Response)

```jac
obj BatchReviewAnalysis {
    has reviews: list[SingleReviewAnalysis];
}

obj SingleReviewAnalysis {
    has review_index: int;
    has sentiment: str;              // "positive" | "negative" | "neutral" | "mixed"
    has sentiment_score: float;      // -1.0 to 1.0
    has themes: list[str];           // Main themes
    has sub_themes: list[SubThemeMapping];
    has keywords: list[str];         // Max 5
    has emotion: str;                // Primary emotion
}

obj SubThemeMapping {
    has theme: str;                  // Main theme name
    has sub_themes: list[str];       // Sub-theme names
}
```

---

## 📊 Reconstructed LLM Prompt

Since Jac's `by llm` operator auto-generates prompts, here's the **reconstructed prompt** for Node.js:

```text
# Role
You are an expert sentiment analyzer for customer reviews of a {business_type} business.

# Task
Analyze the following {len(reviews)} customer reviews and extract structured insights.

# Business Type
{business_type}

# Allowed Main Themes
You MUST use only these themes:
{allowed_themes}

# Allowed Sub-themes
For each main theme, you can use these sub-themes:
{allowed_sub_themes}

# Reviews to Analyze
{reviews}

# Output Format
Return a JSON object with this structure:
{
  "reviews": [
    {
      "review_index": 0,
      "sentiment": "positive",  // positive | negative | neutral | mixed
      "sentiment_score": 0.8,    // -1.0 (very negative) to 1.0 (very positive)
      "themes": ["Room Quality", "Service"],
      "sub_themes": [
        {
          "theme": "Room Quality",
          "sub_themes": ["Cleanliness", "Bed Comfort"]
        },
        {
          "theme": "Service",
          "sub_themes": ["Front Desk", "Staff Attitude"]
        }
      ],
      "keywords": ["spacious room", "friendly staff", "comfortable bed"],
      "emotion": "happy"  // happy | satisfied | impressed | disappointed | frustrated | angry | neutral
    },
    // ... for each review in batch
  ]
}

# Guidelines
1. **Sentiment Classification**:
   - "positive": Overall positive experience (score: 0.3 to 1.0)
   - "negative": Overall negative experience (score: -1.0 to -0.3)
   - "neutral": Neither positive nor negative (score: -0.3 to 0.3)
   - "mixed": Both positive and negative aspects (score: -0.3 to 0.3)

2. **Sentiment Score**:
   - Consider star rating as baseline
   - Adjust based on review text tone
   - 5 stars + positive text = 0.8 to 1.0
   - 1 star + negative text = -1.0 to -0.8
   - Mixed reviews = -0.2 to 0.2

3. **Theme Detection**:
   - Only use themes from allowed_themes list
   - A review can have multiple themes
   - Include a theme if it's mentioned or implied

4. **Sub-theme Detection**:
   - For each detected main theme, identify relevant sub-themes
   - Only use sub-themes from allowed_sub_themes for that theme
   - Be specific (e.g., "Cleanliness" not just "Room Quality")

5. **Keywords**:
   - Extract 3-5 key phrases that stand out
   - Use customer's actual words when possible
   - Focus on specific mentions (e.g., "pool was clean" not "good")

6. **Emotion Detection**:
   - happy: Delighted, excited, love it
   - satisfied: Content, pleased, met expectations
   - impressed: Surprised positively, exceeded expectations
   - disappointed: Unmet expectations, let down
   - frustrated: Annoyed, inconvenienced
   - angry: Very upset, demanding refund
   - neutral: No strong emotion

# Important
- Analyze ALL reviews in the batch (indices 0-{len(reviews)-1})
- Return results in the same order
- Use ONLY the allowed themes and sub-themes provided
```

---

## 🔄 Processing LLM Response

### Parsing and Applying Results

```jac
def analyze_batch(reviews, allowed_themes, theme_defs, business_type) {
    // Build input
    review_texts = [];
    for (idx, r) in enumerate(reviews) {
        review_texts.append({
            "index": idx,
            "rating": r.rating,
            "text": r.text[:500]
        });
    }

    // Call LLM
    result = self.analyze_reviews_batch(
        reviews=review_texts,
        business_type=business_type,
        allowed_themes=allowed_themes,
        allowed_sub_themes=theme_defs
    );

    // Apply results to Review nodes
    for analysis in result.reviews {
        idx = analysis.review_index;
        if idx < len(reviews) {
            r = reviews[idx];

            // Update review properties
            r.sentiment = analysis.sentiment;
            r.sentiment_score = analysis.sentiment_score;
            r.themes = analysis.themes;

            // Convert sub_themes list to dict
            sub_themes_dict = {};
            for mapping in analysis.sub_themes {
                sub_themes_dict[mapping.theme] = mapping.sub_themes;
            }
            r.sub_themes = sub_themes_dict;

            r.keywords = analysis.keywords;
            r.emotion = analysis.emotion;
            r.analyzed = True;

            // Update statistics
            self.sentiment_counts[analysis.sentiment] += 1;

            // Track themes
            for theme in analysis.themes {
                if theme not in self.all_themes {
                    self.all_themes[theme] = {
                        "count": 0,
                        "positive": 0,
                        "negative": 0,
                        "neutral": 0,
                        "mixed": 0
                    };
                }
                self.all_themes[theme]["count"] += 1;
                self.all_themes[theme][analysis.sentiment] += 1;
            }

            self.analyzed_count += 1;
        }
    }
}
```

---

## 📋 Example: Hotel Review Analysis

### Input (Batch of 2)

```json
{
  "reviews": [
    {
      "index": 0,
      "rating": 5,
      "text": "Amazing hotel! The room was spotless and the bed was incredibly comfortable. Staff at the front desk were so friendly and helpful. Breakfast buffet had great variety."
    },
    {
      "index": 1,
      "rating": 2,
      "text": "Disappointed with this stay. Room was not clean when we arrived - bathroom had hair in the sink. AC was broken and they took 2 days to fix it. Front desk was unhelpful."
    }
  ],
  "business_type": "HOTEL",
  "allowed_themes": ["Room Quality", "Service", "Food & Dining", "Value"],
  "allowed_sub_themes": {
    "Room Quality": ["Cleanliness", "Bed Comfort", "Amenities", "Maintenance"],
    "Service": ["Front Desk", "Housekeeping", "Response Time"],
    "Food & Dining": ["Breakfast", "Variety"]
  }
}
```

### Output (LLM Response)

```json
{
  "reviews": [
    {
      "review_index": 0,
      "sentiment": "positive",
      "sentiment_score": 0.9,
      "themes": ["Room Quality", "Service", "Food & Dining"],
      "sub_themes": [
        {
          "theme": "Room Quality",
          "sub_themes": ["Cleanliness", "Bed Comfort"]
        },
        {
          "theme": "Service",
          "sub_themes": ["Front Desk"]
        },
        {
          "theme": "Food & Dining",
          "sub_themes": ["Breakfast", "Variety"]
        }
      ],
      "keywords": [
        "spotless room",
        "comfortable bed",
        "friendly staff",
        "great variety"
      ],
      "emotion": "happy"
    },
    {
      "review_index": 1,
      "sentiment": "negative",
      "sentiment_score": -0.8,
      "themes": ["Room Quality", "Service"],
      "sub_themes": [
        {
          "theme": "Room Quality",
          "sub_themes": ["Cleanliness", "Maintenance"]
        },
        {
          "theme": "Service",
          "sub_themes": ["Front Desk", "Response Time"]
        }
      ],
      "keywords": [
        "room not clean",
        "bathroom hair",
        "AC broken",
        "unhelpful staff"
      ],
      "emotion": "disappointed"
    }
  ]
}
```

### Review Nodes After Update

**Review 1**:

```json
{
  "review_id": "...",
  "author": "John D.",
  "rating": 5,
  "text": "Amazing hotel! The room was spotless...",
  "date": "2024-12-15",

  // Analysis results
  "sentiment": "positive",
  "sentiment_score": 0.9,
  "themes": ["Room Quality", "Service", "Food & Dining"],
  "sub_themes": {
    "Room Quality": ["Cleanliness", "Bed Comfort"],
    "Service": ["Front Desk"],
    "Food & Dining": ["Breakfast", "Variety"]
  },
  "keywords": [
    "spotless room",
    "comfortable bed",
    "friendly staff",
    "great variety"
  ],
  "emotion": "happy",
  "analyzed": true
}
```

**Review 2**:

```json
{
  "review_id": "...",
  "author": "Sarah M.",
  "rating": 2,
  "text": "Disappointed with this stay. Room was not clean...",
  "date": "2024-12-10",

  // Analysis results
  "sentiment": "negative",
  "sentiment_score": -0.8,
  "themes": ["Room Quality", "Service"],
  "sub_themes": {
    "Room Quality": ["Cleanliness", "Maintenance"],
    "Service": ["Front Desk", "Response Time"]
  },
  "keywords": [
    "room not clean",
    "bathroom hair",
    "AC broken",
    "unhelpful staff"
  ],
  "emotion": "disappointed",
  "analyzed": true
}
```

---

## 📊 Statistics Tracking

After all batches are processed:

```json
{
  "analyzed_count": 50,
  "sentiment_counts": {
    "positive": 32,
    "negative": 10,
    "neutral": 5,
    "mixed": 3
  },
  "all_themes": {
    "Room Quality": {
      "count": 45,
      "positive": 30,
      "negative": 12,
      "neutral": 2,
      "mixed": 1
    },
    "Service": {
      "count": 38,
      "positive": 28,
      "negative": 8,
      "neutral": 1,
      "mixed": 1
    },
    "Food & Dining": {
      "count": 25,
      "positive": 20,
      "negative": 3,
      "neutral": 2,
      "mixed": 0
    }
  }
}
```

---

## 🔧 For Node.js Implementation

### OpenAI API Call

```typescript
import OpenAI from "openai";

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

async function analyzeBatch(
  reviews: Array<{ index: number; rating: number; text: string }>,
  businessType: string,
  allowedThemes: string[],
  allowedSubThemes: Record<string, string[]>
) {
  const prompt = buildPrompt(
    reviews,
    businessType,
    allowedThemes,
    allowedSubThemes
  );

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content: "You are an expert sentiment analyzer for customer reviews.",
      },
      {
        role: "user",
        content: prompt,
      },
    ],
    response_format: { type: "json_object" },
    temperature: 0.3,
  });

  const result = JSON.parse(response.choices[0].message.content);
  return result.reviews;
}

function buildPrompt(reviews, businessType, allowedThemes, allowedSubThemes) {
  return `
# Task
Analyze ${reviews.length} customer reviews for a ${businessType}.

# Allowed Main Themes
${JSON.stringify(allowedThemes, null, 2)}

# Allowed Sub-themes
${JSON.stringify(allowedSubThemes, null, 2)}

# Reviews
${JSON.stringify(reviews, null, 2)}

# Output Format
Return JSON with structure:
{
  "reviews": [
    {
      "review_index": 0,
      "sentiment": "positive",
      "sentiment_score": 0.8,
      "themes": ["Room Quality", "Service"],
      "sub_themes": [
        {"theme": "Room Quality", "sub_themes": ["Cleanliness", "Bed Comfort"]},
        {"theme": "Service", "sub_themes": ["Front Desk"]}
      ],
      "keywords": ["clean room", "friendly staff"],
      "emotion": "happy"
    }
  ]
}

# Guidelines
[Include full guidelines from reconstructed prompt above]
  `;
}
```

### Batch Processing Loop

```typescript
async function analyzeBatchesForBusiness(
  businessId: string,
  reviews: Review[],
  businessType: string,
  batchSize: number = 5
) {
  const results = [];
  const themeDefinitions = THEME_DEFINITIONS[businessType];
  const allowedThemes = Object.keys(themeDefinitions);

  // Process in batches
  for (let i = 0; i < reviews.length; i += batchSize) {
    const batch = reviews.slice(i, i + batchSize);

    const batchInput = batch.map((review, idx) => ({
      index: idx,
      rating: review.rating,
      text: review.text.substring(0, 500),
    }));

    console.log(`Processing batch ${Math.floor(i / batchSize) + 1}...`);

    const analyses = await analyzeBatch(
      batchInput,
      businessType,
      allowedThemes,
      themeDefinitions
    );

    // Update reviews with analysis
    for (const analysis of analyses) {
      const review = batch[analysis.review_index];

      await updateReview(review.id, {
        sentiment: analysis.sentiment,
        sentiment_score: analysis.sentiment_score,
        themes: analysis.themes,
        sub_themes: convertSubThemesToDict(analysis.sub_themes),
        keywords: analysis.keywords,
        emotion: analysis.emotion,
        analyzed: true,
      });
    }

    results.push(...analyses);
  }

  return results;
}

function convertSubThemesToDict(subThemeList) {
  const dict = {};
  for (const mapping of subThemeList) {
    dict[mapping.theme] = mapping.sub_themes;
  }
  return dict;
}
```

---

## ✅ Output Summary

After SentimentAnalyzerAgent completes:

```json
{
  "status": "completed",
  "analyzed_count": 50,
  "sentiment_counts": {
    "positive": 32,
    "negative": 10,
    "neutral": 5,
    "mixed": 3
  },
  "all_themes": {
    "Room Quality": {...},
    "Service": {...},
    "Food & Dining": {...}
  }
}
```

All Review nodes are now updated with:

- `sentiment`, `sentiment_score`
- `themes`, `sub_themes`
- `keywords`, `emotion`
- `analyzed = true`

---

**Next**: Read [04-PATTERN-ANALYSIS.md](./04-PATTERN-ANALYSIS.md) for deep pattern analysis.
