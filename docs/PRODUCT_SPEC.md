# Review Analyzer - Complete Product Specification

> **Purpose**: This document provides comprehensive context about the Review Analyzer SaaS product for AI agents, developers, and marketing teams. It reflects the ACTUAL implemented features as of the codebase state.

---

## 1. Product Overview

**Review Analyzer** is a B2B SaaS platform that transforms Google Maps reviews into actionable business intelligence using AI-powered analysis. Built with Jaclang (a graph-based programming language), it uses a multi-agent pipeline to analyze customer reviews and generate strategic recommendations.

**Production API**: https://review-analysis-server.trynewways.com/

### Target Users
- Restaurant/cafe owners
- Hotel/hospitality managers
- Retail store operators
- Salon/spa owners
- Healthcare practice managers
- Multi-location franchise operators
- Marketing agencies managing client reputation

### Core Value Proposition
"Stop manually reading hundreds of reviews. Get AI-powered insights in under 2 minutes that tell you exactly what customers love, what frustrates them, and what to fix first."

---

## 2. Technical Architecture

### Graph-Based Data Model
The application uses JAC's graph database paradigm:
- **Nodes** = Data entities (Business, Review, Theme, Analysis, Report, UserProfile, etc.)
- **Edges** = Relationships between nodes (HasReview, HasTheme, HasAnalysis, HasReport, HasReply)
- **Walkers** = AI agents that traverse the graph and perform operations
- **Automatic Persistence** = Nodes connected to `root` are auto-saved

### 5-Stage AI Analysis Pipeline

```
Stage 1: DataFetcherAgent
    └── Fetches business data + reviews from SERP API (Google Maps)
    └── Creates Business and Review nodes
    └── Detects business type automatically

Stage 2: SentimentAnalyzerAgent
    └── Batch processes reviews (5 at a time for efficiency)
    └── Determines sentiment: positive/negative/neutral/mixed
    └── Calculates sentiment_score: -1.0 to 1.0
    └── Extracts themes based on business type
    └── Identifies sub-themes within each theme
    └── Detects keywords and emotional tone
    └── Emotions: happy, satisfied, impressed, disappointed, frustrated, angry, neutral

Stage 3: PatternAnalyzerAgent
    └── Aggregates sentiment across all reviews
    └── Creates/updates Theme nodes with statistics
    └── Calculates Business Health Score (0-100)
    └── Assigns letter grade (A+ through F)
    └── Identifies SWOT: Strengths, Weaknesses, Opportunities, Threats
    └── Detects critical issues requiring attention
    └── Finds delighters (what customers love)
    └── Finds pain points (common frustrations)
    └── Analyzes monthly trends

Stage 4: ReportGeneratorAgent
    └── Creates executive summary with headline
    └── Generates key findings list
    └── Creates basic recommendations
    └── Builds comprehensive Report node

Stage 5: RecommendationAgent
    └── Generates brand-aware recommendations
    └── Detects brand positioning (premium/mid-range/standard/budget)
    └── Creates evidence-linked recommendations
    └── Includes risk assessment for each recommendation
    └── Generates "Do NOT" recommendations to protect strengths
```

---

## 3. Supported Business Types

The system auto-detects business type from Google Maps categories and applies industry-specific theme analysis:

| Business Type | Theme Categories |
|--------------|------------------|
| **RESTAURANT** | Food Quality, Service, Ambiance, Value, Hygiene, Location |
| **HOTEL** | Room Quality, Service, Facilities, Food & Dining, Value, Location, Check-in/out |
| **RETAIL** | Product Quality, Service, Pricing, Store Experience, Checkout, Location |
| **SALON** | Service Quality, Staff, Ambiance, Value, Booking, Hygiene |
| **HEALTHCARE** | Care Quality, Staff, Wait Time, Facilities, Communication, Value |
| **ENTERTAINMENT** | Experience, Service, Facilities, Value, Crowds, Accessibility |
| **AUTO_SERVICE** | Work Quality, Service, Pricing, Timeliness, Trust, Facility |
| **GYM** | Equipment, Cleanliness, Staff, Classes, Atmosphere, Value |
| **GENERIC** | Product/Service Quality, Customer Service, Value, Experience, Communication, Reliability |

Each theme has defined sub-themes. For example, Restaurant's "Food Quality" includes: Taste, Freshness, Portion Size, Presentation, Menu Variety, Specific Items.

---

## 4. Credit System (ACTUAL PRICING MODEL)

### How Credits Work
- **1 credit = analysis of up to 100 reviews**
- Formula: `credits_required = CEILING(total_reviews / 100)`
- **0.25 credits = 1 AI-generated review reply**

### Credit Packages (Current Pricing)

| Package | Credits | Price | Per Credit | Best For |
|---------|---------|-------|------------|----------|
| **Bronze** | 1 | $5.00 | $5.00 | Single analysis, testing |
| **Silver** | 5 | $22.00 | $4.40 | Regular analysis + replies |
| **Gold** | 12 | $48.00 | $4.00 | Multi-location, frequent use |
| **Platinum** | 30 | $110.00 | $3.67 | Enterprise, high volume |

### Credit Usage Examples
- 50 reviews = 1 credit
- 150 reviews = 2 credits
- 500 reviews = 5 credits
- 4 AI replies = 1 credit

### Important Notes
- Credits are purchased once (NOT a subscription)
- No automatic recurring billing
- Users can buy more credits anytime

---

## 5. User Management

### UserProfile Node
```
- username: Primary identifier (matches JAC auth)
- role: USER or ADMIN
- credits: Available credit balance (float for 0.25 increments)
- credits_used: Lifetime credits consumed
- current_business_count: Number of businesses added
- is_active: Account status
- payment_customer_id: For payment integration
```

### Authentication
- JWT-based authentication via jac-scale
- Each user has an **isolated root node** (graph-based user isolation)
- All businesses/analyses are scoped to the user's graph

### What DOES NOT Exist (yet)
- Team accounts / multi-user access
- Free tier (new users start with 0 credits)
- Trial period
- Role-based permissions beyond USER/ADMIN

---

## 6. Core Features (IMPLEMENTED)

### 6.1 Business Health Score
- **Score**: 0-100 numeric value
- **Grade**: A+, A, A-, B+, B, B-, C+, C, C-, D+, D, F
- **Breakdown**: Score per theme (e.g., Service: 85, Food Quality: 72)
- **Trend**: "improving", "stable", or "declining"
- **Confidence Level**: "high" (100+ reviews), "medium" (20-99), "low" (<20)

### 6.2 Sentiment Analysis
- **Per Review**:
  - sentiment: "positive" | "negative" | "neutral" | "mixed"
  - sentiment_score: -1.0 to 1.0
  - themes: list of detected themes
  - sub_themes: detailed breakdown within themes
  - keywords: key phrases (max 5)
  - emotion: primary emotional tone

- **Aggregated**:
  - positive_percentage, negative_percentage, neutral_percentage
  - overall_sentiment: "very_positive" | "positive" | "mixed" | "negative" | "very_negative"
  - average sentiment score

### 6.3 Theme Analysis
For each theme detected:
- mention_count: how many reviews mention it
- positive_count, negative_count, neutral_count, mixed_count
- avg_sentiment: average sentiment score for this theme
- keywords: common words associated with theme
- sample_quotes_positive: example positive quotes
- sample_quotes_negative: example negative quotes
- sub_themes: detailed breakdown

### 6.4 SWOT Analysis
- **Strengths**: What customers consistently praise (with evidence count)
- **Weaknesses**: Recurring complaints and pain points
- **Opportunities**: Gaps and improvement areas
- **Threats**: Emerging problems, competitive disadvantages

### 6.5 Trend Analysis
- monthly_breakdown: sentiment metrics per month
- trend_direction: "improving" | "stable" | "declining"
- trend_change: description of change
- date_range_start, date_range_end: analysis period
- seasonal_patterns: detected patterns (if any)

### 6.6 Critical Issues Detection
For each critical issue:
- issue: description
- severity: "high" | "medium" | "low"
- mention_count: frequency
- suggested_action: what to do

### 6.7 Brand-Aware Recommendations
- **brand_context**: price_positioning, brand_positioning, protected_strengths, brand_risks
- **Recommendations with**:
  - action: specific action to take
  - action_type: "monitor" | "communicate" | "experiment" | "change"
  - evidence: linked to actual review data
  - expected_impact, downside_risk
  - effort, risk_level, confidence_level
  - priority_score: 0-100
  - caution_note: for medium/high risk actions
- **Timeframes**: immediate (this week), short_term (this month), long_term (this quarter)
- **Do NOT Recommendations**: protective guidance on what to avoid

### 6.8 AI Review Reply Generation
**Configuration Options** (ReplyPromptConfig):
- tone: "friendly" | "formal" | "casual" | "friendly_professional"
- max_length: "short" (1-2 sentences) | "medium" (2-3) | "long" (3-4)
- include_name: boolean - address reviewer by name
- offer_resolution: boolean - offer resolution for negative reviews
- sign_off: custom sign-off text
- custom_instructions: additional guidance for LLM

**Reply Features**:
- Single reply generation (0.25 credits)
- Bulk reply generation (0.25 credits each)
- Regenerate reply with new settings
- Context-aware: uses business strengths/issues, review sentiment
- Replies stored as ReviewReply nodes linked to Review

---

## 7. API Endpoints (IMPLEMENTED)

### Analysis
| Endpoint | Description | Cost |
|----------|-------------|------|
| `POST /walker/AnalyzeUrl` | Full analysis from Google Maps URL | 1+ credits |
| `POST /walker/Reanalyze` | Re-run analysis on cached data | No cost |

### Data Retrieval
| Endpoint | Description |
|----------|-------------|
| `POST /walker/GetBusinesses` | List user's businesses with pagination |
| `POST /walker/GetReport` | Get full report for a business |
| `POST /walker/GetReviews` | Get reviews with filters (sentiment, rating) |
| `POST /walker/GetStats` | Get user statistics |
| `POST /walker/DeleteBusiness` | Delete business and all data |

### User Management
| Endpoint | Description |
|----------|-------------|
| `POST /walker/create_user_profile` | Create user profile |
| `POST /walker/get_user_profile` | Get profile and credit balance |

### Credit Management
| Endpoint | Description |
|----------|-------------|
| `POST /walker/GetCreditBalance` | Check available credits |
| `POST /walker/GetCreditHistory` | Transaction history |
| `POST /walker/PurchaseCredits` | Buy credit package |
| `POST /walker/GrantCredits` | Admin: grant credits to user |

### Review Replies
| Endpoint | Description | Cost |
|----------|-------------|------|
| `POST /walker/SaveReplyPromptConfig` | Save reply preferences | Free |
| `POST /walker/GetReplyPromptConfig` | Get current config | Free |
| `POST /walker/GenerateReviewReply` | Generate single reply | 0.25 credits |
| `POST /walker/BulkGenerateReviewReplies` | Bulk reply generation | 0.25 each |
| `POST /walker/RegenerateReviewReply` | Regenerate a reply | 0.25 credits |
| `POST /walker/GetReviewReplies` | Get generated replies | Free |
| `POST /walker/DeleteReviewReply` | Delete a reply | Free |

### Utilities
| Endpoint | Description |
|----------|-------------|
| `POST /walker/health_check` | Service health |
| `POST /walker/ready` | Readiness probe |

---

## 8. What DOES NOT Exist (Yet)

These features are mentioned in marketing but NOT implemented:

| Feature | Status |
|---------|--------|
| PDF/CSV export | NOT IMPLEMENTED |
| Team accounts | NOT IMPLEMENTED |
| Whitelabel option | NOT IMPLEMENTED |
| Competitive benchmarking | NOT IMPLEMENTED |
| Custom report scheduling | NOT IMPLEMENTED |
| API access tiers | NOT IMPLEMENTED |
| Dedicated account manager | NOT IMPLEMENTED |
| Free trial | NOT IMPLEMENTED |
| Batch processing UI | NOT IMPLEMENTED |

---

## 9. Data Model Summary

### Nodes
```
UserProfile - User account and credits
Business - Analyzed business entity
Review - Individual customer review
Theme - Aggregated theme with statistics
Analysis - Analysis results and metrics
Report - Generated report with recommendations
ReplyPromptConfig - User's reply generation settings
ReviewReply - Generated reply to a review
CreditTransaction - Credit purchase/usage record
```

### Edges
```
root --> UserProfile (user's profile)
root --> Business (user's businesses)
Business --> Review (business has reviews)
Business --> Theme (business has themes)
Business --> Analysis (business has analysis)
Business --> Report (business has report)
Review --> ReviewReply (review has reply)
root --> ReplyPromptConfig (user's reply config)
root --> CreditTransaction (user's transactions)
```

---

## 10. Analysis Output Structure

When an analysis completes, the output includes:

```json
{
  "success": true,
  "data_source": "fresh | cache | reanalysis",
  "from_cache": boolean,
  "generated_at": "ISO timestamp",

  "business": {
    "place_id": "...",
    "name": "Business Name",
    "type": "Restaurant",
    "type_normalized": "RESTAURANT",
    "address": "...",
    "google_rating": 4.5,
    "total_reviews": 150,
    "reviews_analyzed": 100
  },

  "health_score": {
    "overall": 78,
    "grade": "B+",
    "confidence": "high",
    "breakdown": {"Service": 85, "Food Quality": 72},
    "trend": "improving"
  },

  "sentiment": {
    "distribution": {
      "positive": {"count": 65, "percentage": 65.0},
      "negative": {"count": 20, "percentage": 20.0},
      "neutral": {"count": 15, "percentage": 15.0}
    },
    "average_score": 0.45
  },

  "themes": [
    {
      "name": "Service",
      "mention_count": 45,
      "sentiment_score": 0.6,
      "sub_themes": [],
      "sample_quotes": {}
    }
  ],

  "trends": {
    "period_analyzed": "6 months",
    "overall_trend": {"direction": "improving", "change": "..."},
    "monthly_breakdown": []
  },

  "critical_issues": [],

  "swot": {
    "strengths": [],
    "weaknesses": [],
    "opportunities": [],
    "threats": []
  },

  "recommendations": {
    "brand_context": {},
    "immediate": [],
    "short_term": [],
    "long_term": [],
    "do_not": []
  },

  "executive_summary": {
    "headline": "...",
    "one_liner": "...",
    "key_metric": "...",
    "full_summary": "..."
  },

  "key_findings": [],

  "credits": {
    "used": 1,
    "remaining": 4,
    "calculation": "100 reviews = 1 credit"
  }
}
```

---

## 11. Key Differentiators (For Marketing)

### What Makes Review Analyzer Unique

1. **5-Stage AI Pipeline**: Not just sentiment - comprehensive multi-agent analysis
2. **Business-Type Intelligence**: Themes and sub-themes specific to your industry
3. **Brand-Aware Recommendations**: Risk-assessed, evidence-linked suggestions
4. **"Do NOT" Guidance**: Tells you what to protect, not just what to fix
5. **Health Score System**: Single metric to track over time (0-100 + letter grade)
6. **Credit-Based Pricing**: Pay for what you use, no wasteful subscriptions
7. **AI Reply Generation**: Professional, context-aware responses to reviews

### Speed Claims (Actual)
- Analysis typically completes in 30-90 seconds
- Depends on review count and API response times
- First analysis may be slower (data fetching); re-analysis is faster (cached data)

---

## 12. Honest Limitations

1. **Only Google Maps**: Currently only analyzes Google Maps reviews (not Yelp, TripAdvisor, etc.)
2. **No Real-Time Monitoring**: Manual re-analysis required to see new reviews
3. **LLM Dependency**: Analysis quality depends on OpenAI API (gpt-4o-mini by default)
4. **No Export**: Cannot export reports to PDF/CSV (view in app only)
5. **Single User**: No team collaboration features
6. **No Scheduling**: Cannot schedule automatic re-analysis

---

## 13. Technology Stack

- **Backend**: Jaclang (JAC) with jac-scale for API serving
- **LLM**: OpenAI GPT-4o-mini (configurable)
- **Data Source**: SerpAPI for Google Maps data
- **Database**: Graph-based (JAC native persistence)
- **Authentication**: JWT via jac-scale
- **Deployment**: Docker with uvicorn

---

## 14. Quick Reference for Content Writers

### Accurate Claims You CAN Make
- "AI-powered analysis in under 2 minutes"
- "5-stage analysis pipeline"
- "Business health score 0-100 with letter grades"
- "Industry-specific theme analysis"
- "SWOT analysis from real customer data"
- "Brand-aware recommendations with risk assessment"
- "AI-generated review replies"
- "Credit-based pricing starting at $5"
- "No subscription required - buy credits as needed"
- "Supports 9 business types with specialized themes"

### Claims to AVOID (Not Implemented)
- "Free trial" or "Try free"
- "Team accounts"
- "PDF/CSV export"
- "Whitelabel"
- "Competitive benchmarking"
- "Dedicated account manager"
- "API access tiers"
- Any specific customer numbers (unless verified)
- Any specific testimonials (unless real)
- "60+ page report" (it's structured data, not pages)

---

*Last Updated: Based on codebase analysis*
*This document should be updated as new features are implemented.*
