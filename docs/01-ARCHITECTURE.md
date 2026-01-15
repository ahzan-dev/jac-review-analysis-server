# System Architecture

## 🏗️ High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         USER INPUT                                  │
│  Google Maps URL + max_reviews + analysis_depth                    │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    ENTRY POINT: AnalyzeUrl Walker                   │
│  - Receives parameters                                              │
│  - Spawns FullPipelineAgent                                         │
│  - Returns success + output JSON                                    │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────────┐
│               ORCHESTRATOR: FullPipelineAgent                       │
│  - Coordinates 4 agents sequentially                                │
│  - Builds final output JSON                                         │
│  - Handles errors                                                   │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┬─────────────────┐
        │                   │                   │                 │
        ▼                   ▼                   ▼                 ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐  ┌──────────────┐
│ AGENT 1:     │    │ AGENT 2:     │    │ AGENT 3:     │  │ AGENT 4:     │
│ DataFetcher  │───▶│ Sentiment    │───▶│ Pattern      │─▶│ Report       │
│              │    │ Analyzer     │    │ Analyzer     │  │ Generator    │
└──────────────┘    └──────────────┘    └──────────────┘  └──────────────┘
        │                   │                   │                 │
        ▼                   ▼                   ▼                 ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐  ┌──────────────┐
│   Business   │    │   Reviews    │    │   Analysis   │  │    Report    │
│     Node     │    │   Analyzed   │    │     Node     │  │     Node     │
└──────────────┘    └──────────────┘    └──────────────┘  └──────────────┘
```

---

## 📦 Component Breakdown

### 1. Entry Point Layer

#### **AnalyzeUrl Walker** (`main.jac`)

**Purpose**: Main API endpoint for the system

**Inputs**:

```typescript
{
  url: string; // Google Maps URL
  max_reviews: number; // Max reviews to fetch (default: 100)
  analysis_depth: string; // "basic" | "standard" | "deep"
  api_key: string; // SERP API key (optional)
  force_mock: boolean; // Use mock data (default: false)
}
```

**Outputs**:

```typescript
{
  success: boolean;
  data_source: string; // "mock" or "serpapi"
  output: {
    // Complete analysis JSON (see 06-JSON-OUTPUT-STRUCTURE.md)
  }
  error: string; // If success = false
}
```

**Responsibilities**:

- Validate input parameters
- Spawn FullPipelineAgent
- Handle success/error responses
- Report final output

---

### 2. Orchestration Layer

#### **FullPipelineAgent Walker** (`walkers.jac`)

**Purpose**: Coordinates all 4 agents and builds final output

**Data Flow**:

```
START
  │
  ├─▶ Parse URL
  │
  ├─▶ STAGE 1: DataFetcherAgent
  │   └─▶ Creates: Business node + Review nodes
  │
  ├─▶ STAGE 2: SentimentAnalyzerAgent
  │   └─▶ Updates: Review nodes with sentiment data
  │
  ├─▶ STAGE 3: PatternAnalyzerAgent
  │   └─▶ Creates: Analysis node + Theme nodes
  │
  ├─▶ STAGE 4: ReportGeneratorAgent
  │   └─▶ Creates: Report node
  │
  ├─▶ Build output JSON
  │
END
```

**Error Handling**:

- Each stage checks if previous stage succeeded
- If any stage fails, pipeline stops
- Error message propagated to user

**State Management**:

```jac
has business_id: str = "";
has status: str = "pending";  // "pending" | "completed" | "failed"
has stages_completed: list = [];
has data_source: str = "";
has output: dict = {};
has error: str = "";
```

---

### 3. Agent Layer

#### **Agent 1: DataFetcherAgent**

**Purpose**: Fetch business and review data

**Process**:

```
1. Parse Google Maps URL
   ├─ Extract data_id (0x...:0x...)
   ├─ Extract place_name
   └─ Validate URL

2. Determine data source
   ├─ If SERPAPI_KEY exists → use SERP API
   └─ Else → use mock data

3. Fetch place details
   ├─ Call: https://serpapi.com/search (place)
   └─ Create Business node with:
       - name, address, phone, website
       - rating, total_reviews
       - business_type (from Google)
       - coordinates, opening_hours
       - photos_count

4. Detect business type
   ├─ Map Google type → normalized type
   └─ RESTAURANT | HOTEL | RETAIL | etc.

5. Fetch reviews
   ├─ Call: https://serpapi.com/search (reviews)
   ├─ Paginate until max_reviews reached
   └─ Create Review nodes with:
       - author, rating, text
       - date, relative_date
       - likes, owner_response

6. Connect nodes
   ├─ Business ++> Review (HasReview edge)
   └─ Update Business.status = "fetched"
```

**Output**:

- `business: Business` - Business node reference
- `reviews_fetched: int` - Count of reviews fetched
- `status: str` - "completed" | "failed"
- `data_source: str` - "serpapi" | "mock"

---

#### **Agent 2: SentimentAnalyzerAgent**

**Purpose**: Analyze reviews for sentiment, themes, emotions

**Process**:

```
1. Find target Business node
   └─ Navigate graph: root --> Business

2. Get business type and theme definitions
   ├─ business_type_normalized (e.g., "RESTAURANT")
   └─ Get allowed themes from THEME_DEFINITIONS

3. Get unanalyzed reviews
   ├─ Business --> Review (where analyzed = false)
   └─ Group into batches of 5

4. Process each batch
   ├─ Build batch input:
   │   {index: 0, rating: 5, text: "..."}
   │   {index: 1, rating: 4, text: "..."}
   │   ...
   │
   ├─ Call LLM: analyze_reviews_batch()
   │   └─ Returns: BatchReviewAnalysis
   │       └─ reviews: [SingleReviewAnalysis]
   │
   └─ Update Review nodes:
       - sentiment ("positive" | "negative" | "neutral" | "mixed")
       - sentiment_score (-1.0 to 1.0)
       - themes (list of main themes)
       - sub_themes (dict: theme → [sub-theme names])
       - keywords (list of key phrases)
       - emotion (primary emotion)
       - analyzed = true

5. Track statistics
   ├─ sentiment_counts: {positive, negative, neutral, mixed}
   └─ all_themes: {theme: {count, positive, negative, ...}}
```

**LLM Call**: `analyze_reviews_batch()`

**Output**:

- `analyzed_count: int` - Total reviews analyzed
- `sentiment_counts: dict` - Sentiment distribution
- `all_themes: dict` - Theme statistics
- `status: str` - "completed"

---

#### **Agent 3: PatternAnalyzerAgent**

**Purpose**: Identify patterns, calculate health score, generate SWOT

**Process**:

```
1. Find target Business node
   └─ Get all analyzed reviews

2. Calculate statistics
   ├─ Sentiment distribution (counts, percentages)
   ├─ Average sentiment score
   ├─ Rating distribution {1: n, 2: n, ...}
   ├─ Average review length
   ├─ Photos count, response rate
   └─ Store in stats dict

3. Build theme analysis
   ├─ For each review's themes:
   │   ├─ Count mentions
   │   ├─ Track sentiment per theme
   │   ├─ Collect sub-theme data
   │   └─ Save positive/negative quotes
   │
   └─ For each sub-theme:
       ├─ Calculate sentiment average
       ├─ Determine verdict (excellent, good, needs_attention, poor)
       └─ Sort by mention count

4. Calculate trends
   ├─ Group reviews by month (parse dates)
   ├─ For each month:
   │   ├─ Count reviews
   │   ├─ Average sentiment
   │   └─ Average rating
   │
   └─ Compare first half vs second half:
       ├─ If diff > 0.1 → "improving"
       ├─ If diff < -0.1 → "declining"
       └─ Else → "stable"

5. Call LLM: generate_pattern_analysis()
   ├─ Input: business info, stats, themes, trends
   └─ Output: PatternAnalysisResult
       ├─ health_score (0-100)
       ├─ health_grade (A+ to F)
       ├─ health_breakdown (by theme)
       ├─ overall_sentiment
       ├─ trend_direction
       ├─ SWOT (strengths, weaknesses, opportunities, threats)
       ├─ critical_issues (with severity, suggested actions)
       ├─ delighters (exceeds expectations)
       └─ pain_points (frustrations)

6. Create Analysis node
   └─ Store all analysis data

7. Create Theme nodes
   ├─ For each theme with >= 3 mentions:
   │   └─ Create Theme node with:
   │       - name, category
   │       - mention_count
   │       - sentiment breakdown
   │       - sub_themes
   │       - sample quotes
   │
   └─ Connect: Business ++> Theme
```

**LLM Call**: `generate_pattern_analysis()`

**Output**:

- `analysis: Analysis` - Analysis node reference
- `themes_created: int` - Number of Theme nodes created
- `status: str` - "completed"

---

#### **Agent 4: ReportGeneratorAgent**

**Purpose**: Generate executive report with recommendations

**Process**:

```
1. Find target Business node
   └─ Get Analysis node

2. Get themes
   └─ Business --> Theme nodes

3. Call LLM: generate_report_content()
   ├─ Input:
   │   - Business details
   │   - Health score, grade
   │   - Sentiment data
   │   - SWOT analysis
   │   - Critical issues
   │   - Theme analysis
   │   - Trend data
   │
   └─ Output: ReportGenerationResult
       ├─ headline (5-10 words)
       ├─ one_liner (single sentence)
       ├─ key_metric (most important metric)
       ├─ executive_summary (2-3 paragraphs)
       ├─ key_findings (5-15 findings)
       ├─ recommendations_immediate (this week)
       ├─ recommendations_short_term (this month)
       └─ recommendations_long_term (this quarter)

4. Create Report node
   ├─ Store all report content
   └─ Connect: Business ++> Report
```

**LLM Call**: `generate_report_content()`

**Output**:

- `report: Report` - Report node reference
- `status: str` - "completed"

---

## 🗄️ Data Model (Graph Structure)

### Node Types

```
Root
 │
 └── Business
      ├── Review (multiple)
      ├── Theme (multiple)
      ├── Analysis (one)
      └── Report (one)
```

### Node Details

#### **Business Node**

```jac
node Business {
    has place_id: str;
    has data_id: str;
    has name: str;
    has business_type: str;                # From Google
    has business_type_normalized: str;     # Our mapping
    has address: str;
    has phone: str;
    has website: str;
    has rating: float;
    has total_reviews: int;
    has price_level: str;
    has latitude: float;
    has longitude: float;
    has opening_hours: dict;
    has photos_count: int;
    has status: str;                       # "pending" | "fetching" | "fetched"
}
```

#### **Review Node**

```jac
node Review {
    has review_id: str;
    has author: str;
    has rating: int;
    has text: str;
    has date: str;
    has relative_date: str;

    # Analysis results (populated by SentimentAnalyzer)
    has sentiment: str;              # "positive" | "negative" | "neutral" | "mixed"
    has sentiment_score: float;      # -1.0 to 1.0
    has themes: list[str];           # Main themes
    has sub_themes: dict;            # {theme: [sub-themes]}
    has keywords: list[str];         # Key phrases
    has emotion: str;                # Primary emotion
    has analyzed: bool;
}
```

#### **Theme Node**

```jac
node Theme {
    has name: str;
    has mention_count: int;
    has positive_count: int;
    has negative_count: int;
    has neutral_count: int;
    has avg_sentiment: float;
    has sub_themes: list[dict];      # [{name, mentions, sentiment, verdict}]
    has sample_quotes_positive: list[str];
    has sample_quotes_negative: list[str];
}
```

#### **Analysis Node**

```jac
node Analysis {
    has analysis_id: str;
    has created_at: str;
    has reviews_analyzed: int;

    # Health Score
    has health_score: int;           # 0-100
    has health_grade: str;           # A+ to F
    has health_breakdown: dict;      # {theme: score}

    # Confidence
    has confidence_level: str;       # "low" | "medium" | "high"

    # Sentiment
    has overall_sentiment: str;
    has sentiment_score: float;
    has positive_count: int;
    has negative_count: int;
    has neutral_count: int;
    has positive_percentage: float;
    has negative_percentage: float;

    # SWOT
    has strengths: list[dict];
    has weaknesses: list[dict];
    has opportunities: list[dict];
    has threats: list[dict];

    # Issues
    has critical_issues: list[dict];
    has pain_points: list[str];
    has delighters: list[str];

    # Trends
    has trend_direction: str;        # "improving" | "stable" | "declining"
    has monthly_breakdown: list[dict];
    has theme_trends: list[dict];

    # Statistics
    has rating_distribution: dict;
    has avg_review_length: int;
    has response_rate: float;
}
```

#### **Report Node**

```jac
node Report {
    has report_id: str;
    has report_type: str;
    has created_at: str;

    # Executive Summary
    has headline: str;
    has one_liner: str;
    has key_metric: str;
    has executive_summary: str;

    # Findings & Recommendations
    has key_findings: list[str];
    has recommendations_immediate: list[dict];
    has recommendations_short_term: list[dict];
    has recommendations_long_term: list[dict];
}
```

### Edge Types

```jac
edge HasReview {
    has fetched_at: str;
}

edge HasTheme {
    has relevance_score: float;
}

edge HasAnalysis {
    has version: int;
}

edge HasReport {
    has version: int;
}
```

---

## 🔄 Data Flow Summary

```
1. User Input
   └─▶ AnalyzeUrl Walker

2. URL Parsing
   └─▶ data_id extracted

3. Data Fetching (SERP API or Mock)
   └─▶ Business + Reviews created

4. Business Type Detection
   └─▶ Mapped to normalized type

5. Batch Sentiment Analysis (5 at a time)
   └─▶ Reviews updated with sentiment, themes

6. Statistical Calculations
   └─▶ Stats dict built

7. Theme Analysis
   └─▶ Themes + sub-themes with sentiment

8. Trend Calculation
   └─▶ Monthly breakdown, trend direction

9. LLM Pattern Analysis
   └─▶ Health score, SWOT, critical issues

10. Theme Nodes Created
    └─▶ Connected to Business

11. LLM Report Generation
    └─▶ Executive summary, recommendations

12. Report Node Created
    └─▶ Connected to Business

13. Output JSON Built
    └─▶ Returned to user
```

---

## 🎯 Key Design Decisions

### 1. Batch Processing

- **Why**: Reduce LLM API calls (20 reviews = 4 calls instead of 20)
- **Trade-off**: Slightly more complex prompt management

### 2. Business Type Detection

- **Why**: Enables business-specific theme analysis
- **Example**: Hotels analyze "Room Quality", Restaurants analyze "Food Quality"

### 3. Sub-themes

- **Why**: Granular insights (e.g., "Service" → "Speed", "Friendliness")
- **Benefit**: Actionable recommendations

### 4. Health Score

- **Why**: Simple metric for executives
- **Calculation**: Based on theme sentiments + overall sentiment

### 5. Trend Analysis

- **Why**: Identify if business is improving or declining
- **Method**: Compare first half vs second half of review period

### 6. Confidence Levels

- **Why**: Indicate reliability of insights
- **Thresholds**:
  - Low: < 20 reviews
  - Medium: 20-50 reviews
  - High: > 50 reviews

---

## 🚀 Scalability Considerations

### Current System (Jac)

- **In-memory graph**: Fast but not persistent across runs
- **Sequential agents**: Simple but not parallel

### For Production (Node.js)

- **Database**: PostgreSQL with proper indexes
- **Caching**: Redis for API responses
- **Queue**: BullMQ for async processing
- **Parallel**: Process batches in parallel
- **Rate limiting**: Handle API rate limits

---

**Next**: Read [02-DATA-FETCHING.md](./02-DATA-FETCHING.md) for detailed data fetching process.
