# Competitor Intelligence: Complete Development Guide

## Competitor Monitoring & Competitive Benchmarking for Review Analyzer

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [SERP API: Competitor Discovery Capabilities](#2-serp-api-competitor-discovery-capabilities)
3. [Data Model: New Nodes, Edges, and Graph Structure](#3-data-model-new-nodes-edges-and-graph-structure)
4. [Competitor Monitoring System](#4-competitor-monitoring-system)
5. [Competitive Benchmarking Framework](#5-competitive-benchmarking-framework)
6. [API Endpoints & Walker Specifications](#6-api-endpoints--walker-specifications)
7. [LLM Agent Design: Competitive Intelligence Agents](#7-llm-agent-design-competitive-intelligence-agents)
8. [Credit Cost Model](#8-credit-cost-model)
9. [Implementation Roadmap](#9-implementation-roadmap)
10. [Limitations & Mitigations](#10-limitations--mitigations)

---

## 1. Executive Summary

### What We Are Building

Two interconnected features that transform Review Analyzer from a single-business analysis tool into a competitive intelligence platform:

**Competitor Monitoring** (Enterprise tier): Continuously track competitor businesses, detecting rating changes, review volume surges, sentiment shifts, and emerging themes. Users define a "competitive set" and receive ongoing intelligence.

**Competitive Benchmarking** (Premium tier): Generate side-by-side comparison reports that rank a user's business against competitors across standardized metrics. Produces competitive positioning scores, gap analyses, and strategic recommendations.

### Key Architectural Decisions

- **Competitors are regular Business nodes** analyzed through the existing 5-stage pipeline, connected to a new `CompetitorSet` grouping node via `InCompetitorSet` edges
- **Competitor discovery uses SERP API's `google_maps` engine** with `type=search`, searching by category + location using GPS coordinates from the user's own business
- **Snapshots capture point-in-time metrics** for trend tracking, stored as `CompetitorSnapshot` nodes connected to each Business
- **Benchmarking calculations are deterministic** (no LLM needed), but the competitive narrative report uses an LLM agent
- **Each competitor analyzed costs 1 credit** (same as regular analysis), with discovery search costing 0.5 credits

### Integration with Existing Architecture

```
root
  |
  +---> UserProfile
  +---> Business (user's own)
  |       +---> Review, Theme, Analysis, Report (existing)
  |       +---> CompetitorSnapshot (NEW - point-in-time metrics)
  |
  +---> Business (competitor A - analyzed)
  |       +---> Review, Theme, Analysis, Report (same pipeline)
  |       +---> CompetitorSnapshot
  |
  +---> Business (competitor B - analyzed)
  |       +---> Review, Theme, Analysis, Report (same pipeline)
  |       +---> CompetitorSnapshot
  |
  +---> CompetitorSet (NEW - grouping node)
  |       +---(HasPrimaryBusiness)---> Business (user's own)
  |       +---(InCompetitorSet)---> Business (competitor A)
  |       +---(InCompetitorSet)---> Business (competitor B)
  |       +---> MonitoringConfig (NEW - alert thresholds)
  |       +---> BenchmarkReport (NEW - comparison results)
  |       +---> CompetitorAlert (NEW - triggered alerts)
  |
  +---> ReplyPromptConfig (existing)
  +---> CreditTransaction (existing)
```

---

## 2. SERP API: Competitor Discovery Capabilities

### How to Find Nearby Competitors

The existing system already fetches business details from SERP API using `engine=google_maps` with `type=place`. For competitor discovery, we use the **search** type instead.

#### API Call: Discover Competitors Near a Business

```python
# Given: User's business at lat=6.9147, lng=79.8526, type="Restaurant"
params = {
    "engine": "google_maps",
    "type": "search",
    "q": "restaurants",                          # Search query (business category)
    "ll": "@6.9147,79.8526,14z",                # GPS coordinates + zoom level
    "api_key": os.environ.get("SERPAPI_KEY"),
    "hl": "en",
    "start": 0                                   # Pagination offset (0, 20, 40...)
}
response = requests.get("https://serpapi.com/search", params=params, timeout=30)
data = response.json()
# Returns: data["local_results"] - list of up to 20 businesses per page
```

#### What Each Competitor Result Contains

From `local_results`, each business entry provides:

| Field | Type | Example | Use For |
|-------|------|---------|---------|
| `title` | str | "Burger King" | Competitor name |
| `place_id` | str | "ChIJ..." | Unique identifier |
| `data_id` | str | "0x3ae2....:0x..." | SERP API data_id for reviews |
| `rating` | float | 4.2 | Current rating |
| `reviews` | int | 1847 | Total review count |
| `price` | str | "$$" | Price level |
| `type` | str | "Fast food restaurant" | Business category |
| `types` | list | ["Fast food", "Restaurant"] | All categories |
| `address` | str | "123 Main St..." | Location |
| `gps_coordinates` | dict | {"latitude": 6.91, "longitude": 79.85} | Distance calc |
| `phone` | str | "+94 11 234 5678" | Contact |
| `website` | str | "https://..." | Website |
| `operating_hours` | dict | {"monday": "9AM-10PM"} | Hours |
| `service_options` | dict | {"dine_in": true, "takeout": true} | Services |
| `thumbnail` | str | "https://..." | Business photo |

#### Building the Search Query

The search query should be derived from the user's business type to find relevant competitors:

```python
# Map business_type_normalized to search queries
COMPETITOR_SEARCH_QUERIES = {
    "RESTAURANT": ["restaurants", "dining", "food"],
    "HOTEL": ["hotels", "lodging", "accommodation"],
    "RETAIL": ["shops", "stores", "retail"],
    "SALON": ["salons", "beauty parlors", "spas"],
    "HEALTHCARE": ["clinics", "medical centers", "healthcare"],
    "ENTERTAINMENT": ["entertainment", "attractions", "things to do"],
    "AUTO_SERVICE": ["auto repair", "car service", "mechanic"],
    "GYM": ["gyms", "fitness centers", "workout"],
    "GENERIC": ["businesses"]
}
```

#### Zoom Level Strategy

The `ll` parameter's zoom level controls the search radius:

| Zoom | Approximate Radius | Best For |
|------|-------------------|----------|
| `21z` | ~50 meters | Same street/block |
| `17z` | ~500 meters | Walking distance |
| `15z` | ~2 km | Neighborhood |
| `14z` | ~5 km | District/area (recommended default) |
| `12z` | ~20 km | City-wide |
| `10z` | ~80 km | Metropolitan area |

**Recommendation**: Default to `14z` (5km radius), allow users to adjust with a `search_radius` parameter mapped to zoom levels.

#### Pagination for More Results

SERP API returns 20 results per page. Use the `start` parameter to paginate:

```python
# Page 1: start=0 (results 1-20)
# Page 2: start=20 (results 21-40)
# Page 3: start=40 (results 41-60)
# Max recommended: start=100 (results 101-120) - diminishing relevance beyond this
```

**Important**: Each page is a separate SERP API call (1 search credit each). For MVP, limit to 1-2 pages (20-40 candidates) per discovery.

#### Cost Per Discovery Search

- 1 SERP API search credit per page of 20 results
- Recommended: 1-2 pages = 1-2 SERP API credits per discovery
- At typical SerpAPI pricing ($0.01/search), this is $0.01-$0.02 per discovery

---

## 3. Data Model: New Nodes, Edges, and Graph Structure

### New Node Definitions

```jac
# ═══════════════════════════════════════════════════════════════════════════════
# COMPETITOR INTELLIGENCE - NODE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

node CompetitorSet {
    has set_id: str = "";
    has name: str = "";                         # "My Restaurant Competitors"
    has business_type: str = "";                 # Normalized type (RESTAURANT, HOTEL, etc.)
    has search_query: str = "";                  # Query used to find competitors
    has search_location: dict = {};              # {latitude, longitude, zoom}
    has created_at: str = "";
    has updated_at: str = "";
    has last_benchmark_at: str = "";             # When last benchmark was generated
    has competitor_count: int = 0;               # Number of competitors in set
    has status: str = "active";                  # active, paused, archived
}

sem CompetitorSet = "A group of competing businesses being tracked together";
sem CompetitorSet.set_id = "Unique UUID for this competitor set";
sem CompetitorSet.name = "User-given name for this competitive group";
sem CompetitorSet.search_location = "GPS coordinates and zoom used for competitor search";

node CompetitorSnapshot {
    has snapshot_id: str = "";
    has captured_at: str = "";                   # ISO timestamp
    has rating: float = 0.0;                     # Google rating at capture time
    has total_reviews: int = 0;                  # Total review count at capture
    has review_velocity: float = 0.0;            # New reviews per week (estimated)
    has sentiment_score: float = 0.0;            # Overall sentiment (-1 to 1)
    has health_score: int = 0;                   # Health score (0-100)
    has positive_pct: float = 0.0;               # % positive reviews
    has negative_pct: float = 0.0;               # % negative reviews
    has response_rate: float = 0.0;              # % reviews with owner response
    has top_themes: list[dict] = [];             # [{name, sentiment, mentions}]
    has theme_scores: dict = {};                 # {theme_name: avg_sentiment}
}

sem CompetitorSnapshot = "Point-in-time capture of business metrics for trend tracking";
sem CompetitorSnapshot.review_velocity = "Estimated new reviews per week based on date distribution";
sem CompetitorSnapshot.top_themes = "Top 5 themes by mention count with sentiment scores";

node MonitoringConfig {
    has config_id: str = "";
    has is_enabled: bool = True;
    has check_frequency: str = "weekly";         # daily, weekly, biweekly, monthly
    has last_checked_at: str = "";
    has next_check_at: str = "";

    # Alert thresholds
    has alert_on_rating_change: float = 0.2;     # Alert if rating changes by this much
    has alert_on_review_surge: int = 10;         # Alert if N+ new reviews since last check
    has alert_on_sentiment_shift: float = 0.15;  # Alert if sentiment score shifts
    has alert_on_new_competitor: bool = True;     # Alert when new competitor appears
    has alert_email: str = "";                   # Email for alerts (future)
    has alert_webhook: str = "";                 # Webhook URL for alerts (future)
}

sem MonitoringConfig = "Configuration for automated competitor monitoring and alerts";
sem MonitoringConfig.check_frequency = "How often to re-check competitors: daily, weekly, biweekly, monthly";
sem MonitoringConfig.alert_on_rating_change = "Minimum rating change (absolute) to trigger alert";

node CompetitorAlert {
    has alert_id: str = "";
    has alert_type: str = "";                    # rating_change, review_surge, sentiment_shift, new_theme, new_competitor
    has severity: str = "info";                  # info, warning, critical
    has business_name: str = "";                 # Which competitor triggered it
    has business_place_id: str = "";
    has message: str = "";                       # Human-readable alert message
    has details: dict = {};                      # Structured alert data
    has is_read: bool = False;
    has created_at: str = "";
}

sem CompetitorAlert = "An alert triggered by a change in competitor metrics";
sem CompetitorAlert.alert_type = "Type: rating_change, review_surge, sentiment_shift, new_theme, new_competitor";
sem CompetitorAlert.severity = "Alert severity: info (notable), warning (requires attention), critical (urgent)";

node BenchmarkReport {
    has report_id: str = "";
    has created_at: str = "";
    has primary_business_id: str = "";           # The user's business being benchmarked

    # Overall Rankings
    has overall_rank: int = 0;                   # User's rank in the set (1 = best)
    has total_in_set: int = 0;                   # Total businesses being compared
    has competitive_index: float = 0.0;          # -1 to 1 (negative = below avg, positive = above)

    # Metric Comparisons
    has rating_comparison: dict = {};            # {user, avg, best, worst, rank, percentile}
    has sentiment_comparison: dict = {};         # Same structure
    has health_score_comparison: dict = {};
    has review_volume_comparison: dict = {};
    has response_rate_comparison: dict = {};

    # Theme-Level Gap Analysis
    has theme_gaps: list[dict] = [];             # [{theme, user_score, competitor_avg, gap, verdict}]
    has strengths_vs_competitors: list[str] = [];# Themes where user outperforms
    has weaknesses_vs_competitors: list[str] = [];# Themes where user underperforms

    # Competitive Narrative (LLM-generated)
    has competitive_summary: str = "";           # Executive summary of competitive position
    has strategic_opportunities: list[dict] = [];# Opportunities based on competitor weaknesses
    has competitive_threats: list[dict] = [];    # Threats based on competitor strengths
    has recommended_actions: list[dict] = [];    # Specific actions to improve competitive position
}

sem BenchmarkReport = "Comparative analysis report ranking user's business against competitors";
sem BenchmarkReport.competitive_index = "Composite score from -1 (worst in set) to 1 (best in set)";
sem BenchmarkReport.theme_gaps = "Per-theme comparison showing where user leads or trails competitors";
```

### New Edge Definitions

```jac
# ═══════════════════════════════════════════════════════════════════════════════
# COMPETITOR INTELLIGENCE - EDGE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

edge HasPrimaryBusiness {
    has added_at: str = "";
}

edge InCompetitorSet {
    has added_at: str = "";
    has added_method: str = "";                  # "auto_discovered", "manual_url", "manual_search"
    has distance_km: float = 0.0;               # Distance from primary business
    has is_active: bool = True;                  # Can be deactivated without removing
}

edge HasMonitoringConfig {
    has version: int = 1;
}

edge HasBenchmarkReport {
    has version: int = 1;
}

edge HasSnapshot {
    has captured_at: str = "";
}

edge HasAlert {
    has created_at: str = "";
}
```

### Complete Graph Topology

```
root
  |
  +--[default edge]---> UserProfile
  |
  +--[default edge]---> Business (primary - "My Restaurant")
  |     +--[HasReview]---> Review (x100)
  |     +--[HasTheme]---> Theme (x6)
  |     +--[HasAnalysis]---> Analysis
  |     +--[HasReport]---> Report
  |     +--[HasSnapshot]---> CompetitorSnapshot (current)
  |     +--[HasSnapshot]---> CompetitorSnapshot (last week)
  |     +--[HasSnapshot]---> CompetitorSnapshot (2 weeks ago)
  |
  +--[default edge]---> Business (competitor - "Rival Restaurant A")
  |     +--[HasReview]---> Review (x80)
  |     +--[HasTheme]---> Theme (x5)
  |     +--[HasAnalysis]---> Analysis
  |     +--[HasReport]---> Report
  |     +--[HasSnapshot]---> CompetitorSnapshot
  |
  +--[default edge]---> Business (competitor - "Rival Restaurant B")
  |     +--[HasReview]---> Review (x60)
  |     +--[HasTheme]---> Theme (x4)
  |     +--[HasAnalysis]---> Analysis
  |     +--[HasReport]---> Report
  |     +--[HasSnapshot]---> CompetitorSnapshot
  |
  +--[default edge]---> CompetitorSet ("My Restaurant vs Competitors")
        +--[HasPrimaryBusiness]---> Business (primary)
        +--[InCompetitorSet]---> Business (competitor A)
        +--[InCompetitorSet]---> Business (competitor B)
        +--[HasMonitoringConfig]---> MonitoringConfig
        +--[HasBenchmarkReport]---> BenchmarkReport (latest)
        +--[HasBenchmarkReport]---> BenchmarkReport (previous)
        +--[HasAlert]---> CompetitorAlert
        +--[HasAlert]---> CompetitorAlert
```

### Why Competitors Are Regular Business Nodes

This is a critical design decision. By treating competitors as standard `Business` nodes that go through the same 5-stage pipeline:

1. **No code duplication** -- Competitors get the same deep analysis (sentiment, themes, SWOT, health scores) as the user's own business
2. **Existing API reuse** -- `GetReport`, `GetReviews`, `GetBusinesses` work for competitors with no changes
3. **Consistent data model** -- Theme-level comparisons work because both businesses have identical `Theme` node structures
4. **Cache benefits** -- If two users track the same competitor, the data is already analyzed (keyed by `place_id`)
5. **Incremental complexity** -- The new nodes (`CompetitorSet`, `CompetitorSnapshot`, `BenchmarkReport`) are purely for grouping and comparison

---

## 4. Competitor Monitoring System

### 4.1 Competitor Discovery Flow

```
User clicks "Find Competitors"
    |
    v
DiscoverCompetitors walker
    |
    +-- Read primary business: lat, lng, business_type
    |
    +-- Call SERP API: engine=google_maps, type=search
    |   q = COMPETITOR_SEARCH_QUERIES[business_type]
    |   ll = @{lat},{lng},{zoom}z
    |
    +-- Filter results:
    |   - Remove user's own business (match by place_id)
    |   - Remove already-tracked competitors
    |   - Calculate distance from primary business
    |   - Filter by minimum rating (optional)
    |   - Filter by minimum review count (optional)
    |
    +-- Return candidate list (NOT yet analyzed)
    |   Each candidate: {name, place_id, data_id, rating, reviews,
    |                     type, price, address, distance_km, thumbnail}
    |
    v
User selects competitors to track
    |
    v
AddCompetitor walker (per competitor)
    |
    +-- Create Business node (or reuse existing)
    +-- Run full 5-stage pipeline (AnalyzeUrl equivalent)
    +-- Connect to CompetitorSet via InCompetitorSet edge
    +-- Create initial CompetitorSnapshot
    +-- Deduct credits (1 per competitor analyzed)
```

### 4.2 Metrics to Track Over Time

For each competitor, at each monitoring interval, capture a `CompetitorSnapshot` with:

| Metric | Source | Calculation | Change Detection |
|--------|--------|-------------|-----------------|
| **Rating** | Business.rating | Direct from SERP API place details | Delta from previous snapshot |
| **Total Reviews** | Business.total_reviews | Direct from SERP API | New reviews = current - previous |
| **Review Velocity** | Calculated | new_reviews / days_since_last_check * 7 | Surge detection |
| **Sentiment Score** | Analysis.sentiment_score | Average from analyzed reviews (-1 to 1) | Shift detection |
| **Health Score** | Analysis.health_score | From pattern analysis (0-100) | Trend tracking |
| **Positive %** | Analysis.positive_percentage | Count of positive / total reviews | Sentiment distribution shift |
| **Negative %** | Analysis.negative_percentage | Count of negative / total reviews | Problem detection |
| **Response Rate** | Analysis.response_rate | Reviews with owner_response / total | Engagement tracking |
| **Top Themes** | Theme nodes | Top 5 by mention_count with avg_sentiment | New theme emergence |
| **Theme Scores** | Theme nodes | Dict of {theme_name: avg_sentiment} | Per-theme sentiment drift |

### 4.3 Snapshot Capture Logic

```python
# Pseudocode for creating a CompetitorSnapshot
def capture_snapshot(business: Business, analysis: Analysis, themes: list[Theme]) -> CompetitorSnapshot:
    # Calculate review velocity
    prev_snapshots = [business -->(HasSnapshot)-->(?CompetitorSnapshot)]
    if prev_snapshots:
        last = sorted(prev_snapshots, key=lambda s: s.captured_at)[-1]
        days_diff = (now - parse(last.captured_at)).days
        new_reviews = business.total_reviews - last.total_reviews
        velocity = (new_reviews / max(days_diff, 1)) * 7  # per week
    else:
        velocity = 0.0

    # Build top themes
    sorted_themes = sorted(themes, key=lambda t: t.mention_count, reverse=True)[:5]
    top_themes = [
        {"name": t.name, "sentiment": t.avg_sentiment, "mentions": t.mention_count}
        for t in sorted_themes
    ]

    # Build theme scores dict
    theme_scores = {t.name: t.avg_sentiment for t in themes}

    return CompetitorSnapshot(
        snapshot_id=str(uuid4()),
        captured_at=datetime.now().isoformat(),
        rating=business.rating,
        total_reviews=business.total_reviews,
        review_velocity=round(velocity, 1),
        sentiment_score=analysis.sentiment_score,
        health_score=analysis.health_score,
        positive_pct=analysis.positive_percentage,
        negative_pct=analysis.negative_percentage,
        response_rate=analysis.response_rate,
        top_themes=top_themes,
        theme_scores=theme_scores
    )
```

### 4.4 Change Detection & Alert System

When a new snapshot is captured, compare it with the previous snapshot to detect significant changes:

```python
def detect_changes(
    current: CompetitorSnapshot,
    previous: CompetitorSnapshot,
    config: MonitoringConfig,
    business_name: str,
    business_place_id: str
) -> list[CompetitorAlert]:

    alerts = []

    # 1. Rating Change
    rating_delta = abs(current.rating - previous.rating)
    if rating_delta >= config.alert_on_rating_change:
        direction = "increased" if current.rating > previous.rating else "decreased"
        severity = "critical" if rating_delta >= 0.5 else "warning"
        alerts.append(CompetitorAlert(
            alert_id=str(uuid4()),
            alert_type="rating_change",
            severity=severity,
            business_name=business_name,
            business_place_id=business_place_id,
            message=f"{business_name} rating {direction} from {previous.rating} to {current.rating}",
            details={
                "previous_rating": previous.rating,
                "current_rating": current.rating,
                "change": round(current.rating - previous.rating, 2)
            },
            created_at=datetime.now().isoformat()
        ))

    # 2. Review Surge
    new_reviews = current.total_reviews - previous.total_reviews
    if new_reviews >= config.alert_on_review_surge:
        severity = "warning" if new_reviews >= 20 else "info"
        alerts.append(CompetitorAlert(
            alert_id=str(uuid4()),
            alert_type="review_surge",
            severity=severity,
            business_name=business_name,
            business_place_id=business_place_id,
            message=f"{business_name} received {new_reviews} new reviews since last check",
            details={
                "new_reviews": new_reviews,
                "previous_total": previous.total_reviews,
                "current_total": current.total_reviews,
                "velocity_per_week": current.review_velocity
            },
            created_at=datetime.now().isoformat()
        ))

    # 3. Sentiment Shift
    sentiment_delta = abs(current.sentiment_score - previous.sentiment_score)
    if sentiment_delta >= config.alert_on_sentiment_shift:
        direction = "improved" if current.sentiment_score > previous.sentiment_score else "declined"
        severity = "warning" if direction == "declined" else "info"
        alerts.append(CompetitorAlert(
            alert_id=str(uuid4()),
            alert_type="sentiment_shift",
            severity=severity,
            business_name=business_name,
            business_place_id=business_place_id,
            message=f"{business_name} sentiment {direction} from {previous.sentiment_score:.2f} to {current.sentiment_score:.2f}",
            details={
                "previous_sentiment": previous.sentiment_score,
                "current_sentiment": current.sentiment_score,
                "change": round(current.sentiment_score - previous.sentiment_score, 3)
            },
            created_at=datetime.now().isoformat()
        ))

    # 4. New Theme Detection
    prev_themes = set(previous.theme_scores.keys())
    curr_themes = set(current.theme_scores.keys())
    new_themes = curr_themes - prev_themes
    if new_themes:
        alerts.append(CompetitorAlert(
            alert_id=str(uuid4()),
            alert_type="new_theme",
            severity="info",
            business_name=business_name,
            business_place_id=business_place_id,
            message=f"{business_name} has new review themes: {', '.join(new_themes)}",
            details={"new_themes": list(new_themes)},
            created_at=datetime.now().isoformat()
        ))

    return alerts
```

### 4.5 Alert Severity Classification

| Severity | Condition | Example |
|----------|-----------|---------|
| **critical** | Rating drop >= 0.5 stars, or health score drop >= 15 | Competitor drops from 4.5 to 3.9 |
| **warning** | Rating change >= 0.2, sentiment shift >= 0.15, review surge >= 20 | Competitor gains 25 reviews in a week |
| **info** | New themes detected, small sentiment shift, moderate review activity | Competitor's "Service" theme sentiment improves |

### 4.6 Monitoring Cadence & Scheduling

Since the current system does not have a built-in scheduler (JAC walkers are request-driven), automated monitoring requires one of these approaches:

**Option A: Cron-based external trigger (Recommended for MVP)**
```bash
# crontab entry: Run monitoring check every Monday at 2 AM
0 2 * * 1 curl -X POST https://review-analysis-server.trynewways.com/walker/RunMonitoringCheck \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Option B: Frontend-triggered on login**
When a user logs in, the frontend checks if any competitor sets are due for monitoring and triggers the check.

**Option C: Background worker (Phase 3)**
Implement a background task runner using Python's `asyncio` or `celery` that periodically spawns `RunMonitoringCheck` walkers.

**Cost per monitoring cycle** (per competitor set):
- 1 SERP API call for place details refresh per competitor: 1 credit each
- Optional: Re-fetch reviews for deeper analysis: 1 additional credit each
- Lightweight mode (place details only, no review re-fetch): 0.5 credits per competitor

---

## 5. Competitive Benchmarking Framework

### 5.1 Metrics & Calculations

All benchmarking metrics are derived from data that already exists on `Business`, `Analysis`, and `Theme` nodes.

#### Core Comparison Metrics

**1. Rating Comparison**
```
user_rating = user_business.rating
competitor_ratings = [c.rating for c in competitors]
avg_competitor_rating = sum(competitor_ratings) / len(competitor_ratings)
best_rating = max(competitor_ratings)
worst_rating = min(competitor_ratings)
rank = sorted_position(user_rating, competitor_ratings, descending=True)  # 1 = highest
percentile = (count_below_user / total_competitors) * 100

rating_comparison = {
    "user": user_rating,
    "competitor_avg": round(avg_competitor_rating, 2),
    "best": best_rating,
    "worst": worst_rating,
    "rank": rank,
    "total": total_competitors + 1,  # Including user
    "percentile": round(percentile, 0),
    "gap_to_leader": round(best_rating - user_rating, 2),
    "gap_to_avg": round(user_rating - avg_competitor_rating, 2)
}
```

**2. Sentiment Score Comparison**
```
user_sentiment = user_analysis.sentiment_score
competitor_sentiments = [c_analysis.sentiment_score for c in competitor_analyses]

sentiment_comparison = {
    "user": user_sentiment,
    "competitor_avg": mean(competitor_sentiments),
    "best": max(competitor_sentiments),
    "worst": min(competitor_sentiments),
    "rank": rank_position,
    "percentile": percentile,
    "competitive_sentiment_index": (user_sentiment - mean(competitor_sentiments)) / std_dev(competitor_sentiments)
}
```

The **Competitive Sentiment Index (CSI)** is a Z-score:
```
CSI = (user_sentiment - competitor_mean) / competitor_std_dev
```
- CSI > 1.0: Significantly outperforming competitors
- CSI 0 to 1.0: Above average
- CSI -1.0 to 0: Below average
- CSI < -1.0: Significantly underperforming

**3. Health Score Comparison**
```
health_score_comparison = {
    "user": user_analysis.health_score,
    "competitor_avg": mean([c.health_score for c in competitor_analyses]),
    "best": max_health,
    "worst": min_health,
    "rank": rank_position,
    "grade_distribution": {"A": 2, "B": 1, "C": 0, "D": 0, "F": 0}
}
```

**4. Review Volume Comparison**
```
review_volume_comparison = {
    "user": user_business.total_reviews,
    "competitor_avg": mean([c.total_reviews for c in competitors]),
    "most_reviewed": max_reviews,
    "least_reviewed": min_reviews,
    "rank": rank_position,
    "volume_index": user_reviews / mean(competitor_reviews)  # >1 = more reviews than avg
}
```

**5. Response Rate Comparison**
```
response_rate_comparison = {
    "user": user_analysis.response_rate,
    "competitor_avg": mean([c.response_rate for c in competitor_analyses]),
    "best": max_rate,
    "worst": min_rate,
    "rank": rank_position,
    "gap_to_best": round(max_rate - user_rate, 1)
}
```

#### Theme-Level Gap Analysis

This is the most actionable part of benchmarking. For each theme that appears in both the user's analysis and competitors' analyses:

```
For each theme T (e.g., "Food Quality", "Service", "Value"):
    user_score = user_themes[T].avg_sentiment      # -1 to 1
    competitor_scores = [c_themes[T].avg_sentiment for c in competitors if T in c_themes]

    if competitor_scores:
        competitor_avg = mean(competitor_scores)
        gap = user_score - competitor_avg

        if gap > 0.3:
            verdict = "significant_advantage"
        elif gap > 0.1:
            verdict = "slight_advantage"
        elif gap > -0.1:
            verdict = "competitive"
        elif gap > -0.3:
            verdict = "slight_disadvantage"
        else:
            verdict = "significant_disadvantage"

        theme_gap = {
            "theme": T,
            "user_score": round(user_score, 2),
            "competitor_avg": round(competitor_avg, 2),
            "best_competitor_score": round(max(competitor_scores), 2),
            "gap": round(gap, 2),
            "user_mentions": user_themes[T].mention_count,
            "verdict": verdict
        }
```

### 5.2 Composite Competitive Index

The overall competitive index combines multiple metrics into a single score:

```
Competitive Index = weighted_sum([
    (rating_percentile / 100,          weight=0.25),
    (sentiment_percentile / 100,       weight=0.25),
    (health_percentile / 100,          weight=0.20),
    (review_volume_percentile / 100,   weight=0.15),
    (response_rate_percentile / 100,   weight=0.15)
])

# Normalize to -1 to 1 scale:
competitive_index = (weighted_sum - 0.5) * 2

# Interpretation:
#  1.0 = Best in every metric
#  0.5 = Significantly above average
#  0.0 = Average performer
# -0.5 = Significantly below average
# -1.0 = Worst in every metric
```

### 5.3 Industry-Specific Benchmark Thresholds

Different business types have different "good" thresholds:

```jac
glob INDUSTRY_BENCHMARKS: dict = {
    "RESTAURANT": {
        "good_rating": 4.2,
        "excellent_rating": 4.5,
        "good_health_score": 72,
        "excellent_health_score": 85,
        "good_response_rate": 30.0,
        "excellent_response_rate": 60.0,
        "key_themes": ["Food Quality", "Service", "Value", "Ambiance"],
        "critical_theme": "Food Quality",
        "avg_reviews_active": 200
    },
    "HOTEL": {
        "good_rating": 4.0,
        "excellent_rating": 4.5,
        "good_health_score": 70,
        "excellent_health_score": 85,
        "good_response_rate": 50.0,
        "excellent_response_rate": 80.0,
        "key_themes": ["Room Quality", "Service", "Facilities", "Value"],
        "critical_theme": "Room Quality",
        "avg_reviews_active": 500
    },
    "RETAIL": {
        "good_rating": 4.0,
        "excellent_rating": 4.4,
        "good_health_score": 68,
        "excellent_health_score": 82,
        "good_response_rate": 20.0,
        "excellent_response_rate": 45.0,
        "key_themes": ["Product Quality", "Service", "Pricing", "Store Experience"],
        "critical_theme": "Product Quality",
        "avg_reviews_active": 150
    },
    "SALON": {
        "good_rating": 4.3,
        "excellent_rating": 4.7,
        "good_health_score": 75,
        "excellent_health_score": 88,
        "good_response_rate": 25.0,
        "excellent_response_rate": 50.0,
        "key_themes": ["Service Quality", "Staff", "Value", "Hygiene"],
        "critical_theme": "Service Quality",
        "avg_reviews_active": 100
    },
    "HEALTHCARE": {
        "good_rating": 3.8,
        "excellent_rating": 4.3,
        "good_health_score": 65,
        "excellent_health_score": 80,
        "good_response_rate": 15.0,
        "excellent_response_rate": 35.0,
        "key_themes": ["Care Quality", "Staff", "Wait Time", "Communication"],
        "critical_theme": "Care Quality",
        "avg_reviews_active": 100
    },
    "GENERIC": {
        "good_rating": 4.0,
        "excellent_rating": 4.4,
        "good_health_score": 70,
        "excellent_health_score": 83,
        "good_response_rate": 25.0,
        "excellent_response_rate": 50.0,
        "key_themes": ["Product/Service Quality", "Customer Service", "Value"],
        "critical_theme": "Product/Service Quality",
        "avg_reviews_active": 150
    }
};
```

### 5.4 Normalization for Fair Comparison

When comparing businesses of different sizes, raw counts are misleading. Normalize:

| Metric | Normalization | Why |
|--------|--------------|-----|
| Review count | Not normalized (absolute comparison) | Volume itself is meaningful |
| Theme mentions | Normalize to % of total reviews | Business with 500 reviews vs 50 reviews |
| Response rate | Already a percentage | Fair as-is |
| Sentiment score | Already -1 to 1 scale | Fair as-is |
| Rating | Already 1-5 scale | Fair as-is |
| Health score | Already 0-100 scale | Fair as-is |

For **theme-level comparisons**, always compare `avg_sentiment` (already normalized) and `mention_percentage` (mentions / total_reviews * 100), never raw mention_count.

### 5.5 Visualization Recommendations

**Radar Chart (Theme Comparison)**
```
Dimensions: One axis per shared theme
Values: avg_sentiment per theme, normalized to 0-100 scale
Series: User's business (highlighted), each competitor, competitor average

Example data format for frontend:
{
    "labels": ["Food Quality", "Service", "Value", "Ambiance", "Hygiene"],
    "datasets": [
        {"label": "My Restaurant", "data": [85, 72, 60, 88, 78], "highlight": true},
        {"label": "Competitor Avg", "data": [70, 75, 68, 65, 72], "dashed": true},
        {"label": "Rival A", "data": [68, 80, 72, 60, 70]},
        {"label": "Rival B", "data": [72, 70, 65, 70, 74]}
    ]
}
```

**Bar Chart (Metric Rankings)**
```
One grouped bar chart per metric (rating, sentiment, health, volume, response rate)
Bars: User (highlighted color) + each competitor
Sorted by value descending
```

**Trend Overlay (Time Series)**
```
Line chart with multiple series overlaid
X axis: Time (weekly/monthly snapshots)
Y axis: Rating or sentiment score
Lines: User's business + each competitor
Shows convergence/divergence over time
```

**Gap Analysis Table**
```
| Theme          | You  | Comp Avg | Gap   | Verdict              |
|----------------|------|----------|-------|----------------------|
| Food Quality   | 0.82 | 0.65     | +0.17 | Slight Advantage     |
| Service        | 0.55 | 0.70     | -0.15 | Slight Disadvantage  |
| Value          | 0.30 | 0.45     | -0.15 | Slight Disadvantage  |
| Ambiance       | 0.90 | 0.60     | +0.30 | Significant Advantage|
```

**Competitive Position Matrix (2x2)**
```
Y-axis: Rating (higher = better)
X-axis: Review Volume (more = higher engagement)
Quadrants: Leaders (high/high), Challengers (high/low), Niche (low/high), Laggards (low/low)
Plot each business as a bubble (size = health score)
```

---

## 6. API Endpoints & Walker Specifications

### 6.1 Complete Endpoint List

| Endpoint | Method | Credit Cost | Tier | Description |
|----------|--------|-------------|------|-------------|
| `/walker/DiscoverCompetitors` | POST | 0.5 | Premium | Search for nearby competitors |
| `/walker/AddCompetitor` | POST | 1.0 | Premium | Analyze and track a competitor |
| `/walker/AddCompetitorByUrl` | POST | 1.0 | Premium | Add competitor via Google Maps URL |
| `/walker/RemoveCompetitor` | POST | 0 | Premium | Remove competitor from set |
| `/walker/GetCompetitorSet` | POST | 0 | Premium | Get competitor set with summary |
| `/walker/GetCompetitorSets` | POST | 0 | Premium | List all competitor sets |
| `/walker/RefreshCompetitor` | POST | 1.0 | Premium | Re-fetch and re-analyze a competitor |
| `/walker/GetBenchmarkReport` | POST | 0 | Premium | Get latest benchmark comparison |
| `/walker/GenerateBenchmark` | POST | 0.5 | Premium | Generate new benchmark report |
| `/walker/GetCompetitorAlerts` | POST | 0 | Enterprise | Get triggered alerts |
| `/walker/UpdateMonitoringConfig` | POST | 0 | Enterprise | Configure alert thresholds |
| `/walker/RunMonitoringCheck` | POST | varies | Enterprise | Trigger monitoring cycle |
| `/walker/GetCompetitorTrends` | POST | 0 | Enterprise | Get historical snapshots |
| `/walker/DeleteCompetitorSet` | POST | 0 | Premium | Delete set and all data |

### 6.2 Walker Specifications

#### DiscoverCompetitors

```jac
walker:pub DiscoverCompetitors {
    has business_id: str;                        # User's business to find competitors for
    has search_radius: str = "medium";           # small (2km), medium (5km), large (20km), city (80km)
    has max_results: int = 20;                   # Maximum candidates to return
    has min_rating: float = 0.0;                 # Minimum rating filter
    has min_reviews: int = 0;                    # Minimum review count filter

    can start with `root entry {
        # 1. Validate user has Premium+ tier
        # 2. Find the primary business by business_id
        # 3. Get lat, lng, business_type from primary business
        # 4. Map search_radius to zoom level
        # 5. Build SERP API search query from business type
        # 6. Call SERP API (engine=google_maps, type=search)
        # 7. Parse local_results
        # 8. Filter: remove own business, already-tracked competitors
        # 9. Calculate distance from primary business (Haversine formula)
        # 10. Apply min_rating and min_reviews filters
        # 11. Sort by relevance (distance + rating + reviews)
        # 12. Deduct 0.5 credits
        # 13. Return candidate list (not yet analyzed)

        report {
            "success": True,
            "primary_business": { "place_id": ..., "name": ... },
            "candidates": [
                {
                    "name": "...",
                    "place_id": "...",
                    "data_id": "...",
                    "rating": 4.3,
                    "total_reviews": 245,
                    "type": "Restaurant",
                    "price": "$$",
                    "address": "...",
                    "distance_km": 1.2,
                    "thumbnail": "...",
                    "already_tracked": False
                }
            ],
            "search_params": {
                "query": "restaurants",
                "radius": "medium",
                "zoom": "14z",
                "coordinates": {"lat": 6.91, "lng": 79.85}
            },
            "credits": {"used": 0.5, "remaining": ...}
        };
    }
}
```

#### AddCompetitor

```jac
walker:pub AddCompetitor {
    has business_id: str;                        # User's primary business
    has competitor_place_id: str;                 # Competitor's place_id from discovery
    has competitor_data_id: str;                  # Competitor's data_id for review fetching
    has set_name: str = "";                      # Optional: name for the competitor set
    has max_reviews: int = 100;                  # How many competitor reviews to analyze

    can start with `root entry {
        # 1. Validate Premium+ tier and credit balance
        # 2. Find or create CompetitorSet for this primary business
        # 3. Check competitor limit (Premium: 5, Enterprise: 20)
        # 4. Check if competitor already tracked
        # 5. Run full pipeline on competitor (same as AnalyzeUrl):
        #    a. DataFetcherAgent (fetches competitor's business data + reviews)
        #    b. SentimentAnalyzerAgent
        #    c. PatternAnalyzerAgent
        #    d. ReportGeneratorAgent
        #    e. RecommendationAgent
        # 6. Connect competitor Business to CompetitorSet via InCompetitorSet edge
        # 7. Create initial CompetitorSnapshot
        # 8. Deduct 1 credit
        # 9. Return competitor summary

        report {
            "success": True,
            "competitor": {
                "place_id": "...",
                "name": "...",
                "rating": 4.3,
                "total_reviews": 245,
                "health_score": 78,
                "sentiment_score": 0.45
            },
            "competitor_set": {
                "set_id": "...",
                "name": "...",
                "total_competitors": 3
            },
            "credits": {"used": 1.0, "remaining": ...}
        };
    }
}
```

#### AddCompetitorByUrl

```jac
walker:pub AddCompetitorByUrl {
    has business_id: str;                        # User's primary business
    has competitor_url: str;                      # Google Maps URL of competitor
    has set_name: str = "";
    has max_reviews: int = 100;

    can start with `root entry {
        # 1. Parse competitor URL (same parse_google_maps_url logic)
        # 2. Extract data_id
        # 3. Delegate to AddCompetitor logic
        # (This is the same as AddCompetitor but accepts a URL instead of place_id)
    }
}
```

#### GenerateBenchmark

```jac
walker:pub GenerateBenchmark {
    has business_id: str;                        # User's primary business
    has set_id: str = "";                        # Optional: specific competitor set

    can start with `root entry {
        # 1. Find CompetitorSet (by set_id or by primary business)
        # 2. Load user's Business, Analysis, Themes
        # 3. Load all competitors' Business, Analysis, Themes
        # 4. Calculate all comparison metrics (deterministic - no LLM):
        #    - rating_comparison
        #    - sentiment_comparison
        #    - health_score_comparison
        #    - review_volume_comparison
        #    - response_rate_comparison
        #    - theme_gaps
        #    - composite competitive_index
        # 5. Generate competitive narrative (LLM call):
        #    - competitive_summary
        #    - strategic_opportunities
        #    - competitive_threats
        #    - recommended_actions
        # 6. Create BenchmarkReport node
        # 7. Connect to CompetitorSet via HasBenchmarkReport edge
        # 8. Deduct 0.5 credits (for the LLM narrative)
        # 9. Return full benchmark report
    }
}
```

#### GetCompetitorTrends

```jac
walker:pub GetCompetitorTrends {
    has business_id: str;
    has set_id: str = "";
    has metric: str = "rating";                  # rating, sentiment, health_score, reviews, response_rate
    has period: str = "3m";                      # 1m, 3m, 6m, 12m

    can start with `root entry {
        # 1. Find CompetitorSet
        # 2. For each business (primary + competitors), load CompetitorSnapshots
        # 3. Filter snapshots by period
        # 4. Build time-series data for the requested metric
        # 5. Return formatted for chart rendering

        report {
            "success": True,
            "metric": "rating",
            "period": "3m",
            "series": [
                {
                    "business_name": "My Restaurant",
                    "is_primary": True,
                    "data_points": [
                        {"date": "2026-01-06", "value": 4.3},
                        {"date": "2026-01-13", "value": 4.3},
                        {"date": "2026-01-20", "value": 4.4}
                    ]
                },
                {
                    "business_name": "Rival A",
                    "is_primary": False,
                    "data_points": [
                        {"date": "2026-01-06", "value": 4.1},
                        {"date": "2026-01-13", "value": 4.0},
                        {"date": "2026-01-20", "value": 4.0}
                    ]
                }
            ]
        };
    }
}
```

#### RunMonitoringCheck

```jac
walker:pub RunMonitoringCheck {
    has set_id: str = "";                        # Optional: check specific set, or all due sets

    can start with `root entry {
        # 1. Find all CompetitorSets with monitoring enabled
        # 2. Filter to sets that are due for check (next_check_at <= now)
        # 3. For each due set:
        #    a. For each competitor in set:
        #       - Refresh place details from SERP API (lightweight, no reviews)
        #       - Optionally re-fetch reviews if significant changes detected
        #       - Create new CompetitorSnapshot
        #       - Compare with previous snapshot
        #       - Generate alerts if thresholds exceeded
        #    b. Also refresh primary business snapshot
        #    c. Update last_checked_at, next_check_at
        # 4. Deduct credits (0.5 per competitor for lightweight refresh)
        # 5. Return summary of checks performed and alerts generated

        report {
            "success": True,
            "sets_checked": 1,
            "competitors_refreshed": 3,
            "alerts_generated": [
                {
                    "business": "Rival A",
                    "alert_type": "rating_change",
                    "severity": "warning",
                    "message": "Rival A rating decreased from 4.2 to 4.0"
                }
            ],
            "next_check": "2026-02-13T02:00:00",
            "credits": {"used": 1.5, "remaining": ...}
        };
    }
}
```

---

## 7. LLM Agent Design: Competitive Intelligence Agents

### 7.1 CompetitiveBenchmarkAnalyzer (New LLM Agent)

This agent generates the narrative portion of the BenchmarkReport. It receives pre-calculated metrics and produces strategic insights.

```jac
# LLM output object for competitive narrative
obj CompetitiveNarrativeResult {
    has competitive_summary: str;
    has competitive_position: str;               # "market_leader", "strong_contender", "competitive", "lagging"
    has strategic_opportunities: list[CompetitiveOpportunity];
    has competitive_threats: list[CompetitiveThreat];
    has recommended_actions: list[CompetitiveAction];
}

sem CompetitiveNarrativeResult = "Strategic competitive analysis narrative based on benchmarking data";
sem CompetitiveNarrativeResult.competitive_summary = "2-3 paragraph executive summary of competitive position";
sem CompetitiveNarrativeResult.competitive_position = "Overall position: market_leader, strong_contender, competitive, or lagging";

obj CompetitiveOpportunity {
    has opportunity: str;
    has based_on: str;                           # Which competitor weakness this exploits
    has potential_impact: str;
    has effort: str;
}

sem CompetitiveOpportunity = "A strategic opportunity based on competitor weakness";
sem CompetitiveOpportunity.opportunity = "Specific opportunity description";
sem CompetitiveOpportunity.based_on = "Which competitor gap or weakness creates this opportunity";

obj CompetitiveThreat {
    has threat: str;
    has source: str;                             # Which competitor's strength poses this threat
    has urgency: str;                            # high, medium, low
    has mitigation: str;
}

sem CompetitiveThreat = "A competitive threat from competitor strength or market trend";
sem CompetitiveThreat.threat = "Description of the competitive threat";
sem CompetitiveThreat.source = "Which competitor and what specific strength creates this threat";

obj CompetitiveAction {
    has action: str;
    has rationale: str;
    has expected_outcome: str;
    has priority: str;                           # immediate, short_term, long_term
}

sem CompetitiveAction = "A recommended action to improve competitive positioning";
sem CompetitiveAction.action = "Specific action to take";
sem CompetitiveAction.rationale = "Why this action improves competitive position, referencing specific competitor data";
```

#### LLM Function

```jac
"""Generate competitive intelligence narrative from benchmarking data.

Analyzes the user's competitive position against tracked competitors and produces
strategic insights including opportunities (competitor weaknesses to exploit),
threats (competitor strengths that pose risk), and recommended actions.

This is a strategic analysis task that requires synthesizing multiple data dimensions
into actionable competitive intelligence.

Args:
    business_name: Name of the user's business
    business_type: Business category
    competitive_index: Overall competitive score (-1 to 1)
    rating_comparison: Rating metrics vs competitors
    sentiment_comparison: Sentiment metrics vs competitors
    health_comparison: Health score metrics vs competitors
    theme_gaps: Per-theme advantage/disadvantage analysis
    competitor_profiles: Summary of each competitor's key metrics
    industry_benchmarks: Industry-specific benchmark thresholds

Returns:
    CompetitiveNarrativeResult with strategic summary, opportunities, threats, and actions
"""
def generate_competitive_narrative(
    business_name: str,
    business_type: str,
    competitive_index: float,
    rating_comparison: dict,
    sentiment_comparison: dict,
    health_comparison: dict,
    theme_gaps: list,
    competitor_profiles: list,
    industry_benchmarks: dict
) -> CompetitiveNarrativeResult by llm(
    temperature=0.6,
    incl_info={
        "business_name": business_name,
        "business_type": business_type,
        "competitive_index": competitive_index,
        "metrics": {
            "rating": rating_comparison,
            "sentiment": sentiment_comparison,
            "health_score": health_comparison
        },
        "theme_gap_analysis": theme_gaps,
        "competitors": competitor_profiles,
        "industry_benchmarks": industry_benchmarks,
        "instructions": """
Generate a strategic competitive intelligence report.

FOCUS ON:
1. Where this business leads vs. competitors (cite specific theme gaps)
2. Where this business trails (cite specific metrics and competitor names)
3. Exploitable competitor weaknesses (low theme scores, declining trends)
4. Threatening competitor strengths (high scores in user's weak areas)
5. Specific, actionable recommendations tied to competitive data

DO NOT:
- Make generic recommendations not tied to competitive data
- Ignore the competitive_index and percentile rankings
- Recommend actions that don't reference specific competitor gaps

TONE: Strategic, data-driven, executive-level
"""
    }
);
```

### 7.2 Integration Points

The competitive intelligence system uses LLMs at exactly two points:

1. **When analyzing each competitor** (existing pipeline): The standard SentimentAnalyzerAgent, PatternAnalyzerAgent, ReportGeneratorAgent, and RecommendationAgent run on each competitor's reviews. No new LLM code needed.

2. **When generating the benchmark narrative** (new): The CompetitiveBenchmarkAnalyzer produces the strategic narrative. This is a single LLM call per benchmark report generation.

All metric calculations (rankings, percentiles, gaps, CSI) are deterministic and require no LLM.

---

## 8. Credit Cost Model

### 8.1 Cost Structure

| Operation | SERP API Calls | LLM Calls | Credit Cost | Notes |
|-----------|---------------|-----------|-------------|-------|
| Discover Competitors | 1 (search) | 0 | 0.5 | Returns 20 candidates |
| Add Competitor (full analysis) | 1 place + N review pages | 5 (full pipeline) | 1.0 | Same as AnalyzeUrl |
| Add Competitor by URL | 1 place + N review pages | 5 (full pipeline) | 1.0 | Same as AnalyzeUrl |
| Generate Benchmark | 0 | 1 (narrative) | 0.5 | Metrics are deterministic |
| Get Benchmark Report | 0 | 0 | 0 | Reads stored data |
| Lightweight Monitoring Refresh | 1 per competitor | 0 | 0.5 per competitor | Place details only |
| Full Monitoring Refresh | 1 + N review pages per comp | 5 per comp | 1.0 per competitor | Full re-analysis |
| Get Trends/Alerts | 0 | 0 | 0 | Reads stored data |
| Delete Competitor/Set | 0 | 0 | 0 | Cleanup only |

### 8.2 Example Cost Scenarios

**Scenario 1: Small business tracking 3 competitors**
```
Setup cost:
  Discovery search:     0.5 credits
  Add 3 competitors:    3.0 credits  (1.0 each)
  Initial benchmark:    0.5 credits
  TOTAL SETUP:          4.0 credits ($20 at $5/credit bronze rate)

Monthly monitoring (weekly lightweight checks):
  4 checks x 3 competitors x 0.5 credits = 6.0 credits/month
  + 1 benchmark report:                    0.5 credits/month
  TOTAL MONTHLY:                           6.5 credits/month
```

**Scenario 2: Enterprise tracking 10 competitors**
```
Setup cost:
  Discovery search:      0.5 credits (1 page) or 1.0 (2 pages)
  Add 10 competitors:   10.0 credits
  Initial benchmark:     0.5 credits
  TOTAL SETUP:          11.0 credits

Monthly monitoring (weekly lightweight):
  4 checks x 10 competitors x 0.5 = 20.0 credits/month
  + 2 benchmark reports:              1.0 credits/month
  TOTAL MONTHLY:                     21.0 credits/month
```

### 8.3 Tier Limits

| Capability | Premium | Enterprise |
|-----------|---------|------------|
| Competitor sets | 1 | 5 |
| Competitors per set | 5 | 20 |
| Monitoring | Manual refresh only | Automated + alerts |
| Alert system | Not available | Full alerts |
| Benchmark reports | On-demand | Auto + on-demand |
| Trend history | 30 days | Unlimited |
| Snapshot retention | 4 snapshots | Unlimited |

---

## 9. Implementation Roadmap

### Phase 1: MVP -- Competitive Benchmarking (4-5 weeks)

**Goal**: Users can add competitors manually and see comparison reports.

**Scope**:
- New nodes: `CompetitorSet`, `CompetitorSnapshot`, `BenchmarkReport`
- New edges: `HasPrimaryBusiness`, `InCompetitorSet`, `HasBenchmarkReport`, `HasSnapshot`
- Walkers: `AddCompetitorByUrl`, `GetCompetitorSet`, `GetCompetitorSets`, `GenerateBenchmark`, `GetBenchmarkReport`, `RemoveCompetitor`, `DeleteCompetitorSet`
- Benchmark calculations: All 5 metric comparisons + theme gap analysis + competitive index
- LLM narrative generation for benchmark reports
- Credit deductions for add + benchmark operations

**Not in scope**: Automated monitoring, alerts, competitor discovery search, trends.

**Implementation order**:
1. Add new node and edge definitions to `services/models.jac`
2. Add `INDUSTRY_BENCHMARKS` global to `services/models.jac`
3. Create `services/competitor_walkers.jac` with:
   - `AddCompetitorByUrl` (reuses existing pipeline via FullPipelineAgent)
   - `RemoveCompetitor`
   - `GetCompetitorSet` / `GetCompetitorSets`
   - `GenerateBenchmark` (deterministic metrics + LLM narrative)
   - `GetBenchmarkReport`
   - `DeleteCompetitorSet`
4. Add LLM output objects (`CompetitiveNarrativeResult`, etc.) to `services/models.jac`
5. Add `include services.competitor_walkers;` to `main.jac`
6. Add error codes for competitor features to `services/errors.jac`
7. Test with 2 competitors manually added by URL

### Phase 2: Enhanced -- Discovery & Monitoring (3-4 weeks)

**Goal**: Users can discover competitors automatically and refresh them.

**Scope**:
- `DiscoverCompetitors` walker (SERP API local search)
- `AddCompetitor` (from discovery results, by place_id/data_id)
- `RefreshCompetitor` (re-fetch + re-analyze single competitor)
- `CompetitorSnapshot` capture on every analysis
- `GetCompetitorTrends` (historical snapshot data)
- Haversine distance calculation
- Search radius configuration

**Implementation order**:
1. Implement `DiscoverCompetitors` walker with SERP API `google_maps` search integration
2. Add `COMPETITOR_SEARCH_QUERIES` mapping to models
3. Implement `AddCompetitor` (from discovery results)
4. Add snapshot capture logic to competitor analysis flow
5. Implement `RefreshCompetitor` (calls ReanalyzePipeline equivalent)
6. Implement `GetCompetitorTrends` (reads snapshots, builds time series)
7. Test with real SERP API calls for discovery

### Phase 3: Advanced -- Automated Monitoring & Alerts (3-4 weeks)

**Goal**: Enterprise users get automated competitor tracking with alerts.

**Scope**:
- `MonitoringConfig` and `CompetitorAlert` nodes
- `UpdateMonitoringConfig` walker
- `RunMonitoringCheck` walker (lightweight refresh + change detection)
- `GetCompetitorAlerts` walker (with read/unread tracking)
- Alert generation logic (rating change, review surge, sentiment shift, new themes)
- Cron-based scheduling documentation
- Alert severity classification

**Implementation order**:
1. Add `MonitoringConfig` and `CompetitorAlert` nodes to models
2. Implement `UpdateMonitoringConfig` walker
3. Implement `RunMonitoringCheck` with lightweight place details refresh
4. Implement change detection logic (compare snapshots)
5. Implement alert generation with severity classification
6. Implement `GetCompetitorAlerts` with pagination and read status
7. Document cron setup for automated scheduling
8. Test with real data over multiple monitoring cycles

---

## 10. Limitations & Mitigations

### 10.1 Data Limitations

| Limitation | Impact | Mitigation |
|-----------|--------|-----------|
| **SERP API returns max ~120 results per search** | May miss some competitors beyond top results | Use multiple search queries per business type; allow manual URL addition |
| **Review data is public only** | Cannot see private/deleted reviews | Acknowledge in reports; focus on public sentiment patterns |
| **Google Maps rating is rounded** | 4.3 vs 4.4 may not reflect actual difference | Use sentiment_score (continuous) as primary comparison metric, not rating alone |
| **Review dates may be approximate** | Relative dates like "2 months ago" lose precision | Existing `parse_review_date` handles this; snapshots use capture timestamp |
| **No real-time data** | Data is as fresh as last fetch | Monitoring intervals + manual refresh bridge the gap |
| **Business categories vary** | "Restaurant" vs "Fine dining" vs "Casual dining" | Normalize via existing `BUSINESS_TYPE_MAP`; allow manual override |

### 10.2 Comparison Fairness

| Issue | Description | Mitigation |
|-------|-------------|-----------|
| **Size disparity** | Chain restaurant vs family restaurant | Use percentages not counts; note size difference in reports |
| **Age disparity** | 10-year-old business with 5000 reviews vs 6-month-old with 50 | Include confidence_level in comparisons; flag low-confidence competitors |
| **Category mismatch** | Fine dining vs fast food both as "RESTAURANT" | Future: add price_level filtering; current: let users curate their set |
| **Geographic differences** | Different neighborhoods have different expectations | Competitor discovery uses proximity; users can adjust search radius |

### 10.3 Cost Concerns

| Concern | Mitigation |
|---------|-----------|
| **Competitor analysis is expensive (1 credit each)** | Lightweight monitoring mode (0.5 credits) for ongoing tracking; full analysis only on initial add |
| **SERP API costs add up with monitoring** | Configurable check frequency; lightweight refresh by default (place details only, no reviews) |
| **LLM costs for competitor pipeline** | Competitors use same batch processing (5 reviews per LLM call) as regular businesses |
| **Users might add too many competitors** | Enforce tier limits: Premium 5, Enterprise 20 |

### 10.4 Technical Limitations

| Limitation | Mitigation |
|-----------|-----------|
| **No built-in scheduler in JAC** | External cron + API call for monitoring; document setup clearly |
| **Graph may grow large with many snapshots** | Implement snapshot retention limits (4 for Premium, unlimited for Enterprise); delete old snapshots via cleanup walker |
| **Competitor analysis takes time (2-3 min for 100+ reviews)** | Show progress indicator; allow background processing; consider async patterns |
| **No email/webhook infrastructure** | Phase 3; for MVP, alerts are in-app only (read via GetCompetitorAlerts) |

---

## Appendix A: Haversine Distance Formula

For calculating distance between the user's business and competitor candidates:

```python
import math

def haversine_distance(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """Calculate distance in kilometers between two GPS coordinates."""
    R = 6371  # Earth radius in kilometers

    dlat = math.radians(lat2 - lat1)
    dlon = math.radians(lon2 - lon1)

    a = (math.sin(dlat / 2) ** 2 +
         math.cos(math.radians(lat1)) * math.cos(math.radians(lat2)) *
         math.sin(dlon / 2) ** 2)

    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return round(R * c, 2)
```

## Appendix B: Zoom Level to Search Radius Mapping

```jac
glob SEARCH_RADIUS_MAP: dict = {
    "tiny": {"zoom": "17z", "radius_km": 0.5, "description": "Walking distance"},
    "small": {"zoom": "15z", "radius_km": 2.0, "description": "Neighborhood"},
    "medium": {"zoom": "14z", "radius_km": 5.0, "description": "District"},
    "large": {"zoom": "12z", "radius_km": 20.0, "description": "City-wide"},
    "metro": {"zoom": "10z", "radius_km": 80.0, "description": "Metropolitan area"}
};
```

## Appendix C: Error Codes for Competitor Features

```jac
# Add to ErrorCode enum in services/errors.jac:
COMPETITOR_SET_NOT_FOUND = "COMPETITOR_SET_NOT_FOUND",
COMPETITOR_LIMIT_EXCEEDED = "COMPETITOR_LIMIT_EXCEEDED",
COMPETITOR_ALREADY_TRACKED = "COMPETITOR_ALREADY_TRACKED",
COMPETITOR_NOT_FOUND = "COMPETITOR_NOT_FOUND",
MONITORING_NOT_ENABLED = "MONITORING_NOT_ENABLED",
FEATURE_NOT_AVAILABLE = "FEATURE_NOT_AVAILABLE"       # For tier-gated features
```

## Appendix D: Competitor Set Limits by Tier

```jac
glob COMPETITOR_LIMITS: dict = {
    "free": {"sets": 0, "competitors_per_set": 0, "monitoring": False, "alerts": False},
    "premium": {"sets": 1, "competitors_per_set": 5, "monitoring": False, "alerts": False},
    "enterprise": {"sets": 5, "competitors_per_set": 20, "monitoring": True, "alerts": True}
};
```
