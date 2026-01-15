# Pattern Analysis Stage

## 🎯 Overview

**Agent**: `PatternAnalyzerAgent`  
**Purpose**: Aggregate sentiment results, calculate statistics, generate health scores, identify patterns, and produce SWOT analysis.

**Input**:

- Business with analyzed reviews
- Theme analysis data
- Sentiment scores

**Output**:

- Health score (0-100 with letter grade)
- SWOT analysis (strengths, weaknesses, opportunities, threats)
- Critical issues list
- Trend analysis
- Detailed statistics

---

## 🔍 Processing Steps

### Step 1: Calculate Statistics

```jac
can calculate_statistics(reviews: list[Review]) -> dict {
    stats = {
        rating_distribution: {1: 0, 2: 0, 3: 0, 4: 0, 5: 0},
        avg_review_length: 0,
        total_with_owner_response: 0,
        response_rate: 0.0
    };

    total_length = 0;

    for review in reviews {
        rating = review.rating;
        stats.rating_distribution[rating] += 1;
        total_length += len(review.text);
        if review.owner_response {
            stats.total_with_owner_response += 1;
        }
    }

    if len(reviews) > 0 {
        stats.avg_review_length = total_length / len(reviews);
        stats.response_rate = (stats.total_with_owner_response / len(reviews)) * 100;
    }

    return stats;
}
```

**Output Structure**:

```json
{
  "rating_distribution": {
    "1": 5,
    "2": 3,
    "3": 10,
    "4": 20,
    "5": 62
  },
  "avg_review_length": 142,
  "total_with_owner_response": 45,
  "response_rate": 45.0
}
```

---

### Step 2: Build Theme Analysis

```jac
can build_theme_analysis(
    themes: dict[str, Theme],
    reviews: list[Review],
    business_type: str
) -> list[dict] {
    theme_analysis = [];
    total_reviews = len(reviews);

    for theme_name in themes.keys() {
        theme_node = themes[theme_name];

        // Calculate percentages
        positive_pct = 0.0;
        negative_pct = 0.0;
        neutral_pct = 0.0;

        total = theme_node.positive_count + theme_node.negative_count + theme_node.neutral_count;

        if total > 0 {
            positive_pct = (theme_node.positive_count / total) * 100;
            negative_pct = (theme_node.negative_count / total) * 100;
            neutral_pct = (theme_node.neutral_count / total) * 100;
        }

        // Build sub-theme stats
        sub_theme_stats = [];
        for sub_theme in theme_node.sub_themes {
            sub_theme_stats.append({
                name: sub_theme.name,
                mentions: sub_theme.mention_count,
                sentiment: sub_theme.avg_sentiment
            });
        }

        theme_analysis.append({
            name: theme_name,
            mention_count: theme_node.mention_count,
            mention_percentage: (theme_node.mention_count / total_reviews) * 100,
            avg_sentiment: theme_node.avg_sentiment,
            positive_count: theme_node.positive_count,
            negative_count: theme_node.negative_count,
            neutral_count: theme_node.neutral_count,
            positive_percentage: positive_pct,
            negative_percentage: negative_pct,
            neutral_percentage: neutral_pct,
            sub_themes: sub_theme_stats,
            sample_quotes_positive: theme_node.sample_quotes_positive,
            sample_quotes_negative: theme_node.sample_quotes_negative
        });
    }

    // Sort by mention count descending
    theme_analysis = sorted(theme_analysis, key=lambda x: x.mention_count, reverse=True);

    return theme_analysis;
}
```

---

### Step 3: Calculate Trends

```jac
can calculate_trends(reviews: list[Review]) -> dict {
    monthly_breakdown = {};

    for review in reviews {
        // Parse date to get month
        month = parse_review_date(review.date);

        if month not in monthly_breakdown {
            monthly_breakdown[month] = {
                total: 0,
                avg_rating: 0.0,
                ratings_sum: 0,
                sentiments: {positive: 0, negative: 0, neutral: 0}
            };
        }

        monthly_breakdown[month].total += 1;
        monthly_breakdown[month].ratings_sum += review.rating;

        if review.sentiment == "POSITIVE" {
            monthly_breakdown[month].sentiments.positive += 1;
        } elif review.sentiment == "NEGATIVE" {
            monthly_breakdown[month].sentiments.negative += 1;
        } else {
            monthly_breakdown[month].sentiments.neutral += 1;
        }
    }

    // Calculate averages
    monthly_data = [];
    for month in sorted(monthly_breakdown.keys()) {
        data = monthly_breakdown[month];
        avg_rating = data.ratings_sum / data.total if data.total > 0 else 0.0;

        monthly_data.append({
            month: month,
            total_reviews: data.total,
            avg_rating: avg_rating,
            positive: data.sentiments.positive,
            negative: data.sentiments.negative,
            neutral: data.sentiments.neutral
        });
    }

    // Determine trend direction
    trend_direction = "stable";
    if len(monthly_data) >= 2 {
        recent_avg = monthly_data[-1].avg_rating;
        older_avg = monthly_data[-2].avg_rating;

        if recent_avg > older_avg + 0.3 {
            trend_direction = "improving";
        } elif recent_avg < older_avg - 0.3 {
            trend_direction = "declining";
        }
    }

    return {
        direction: trend_direction,
        monthly_breakdown: monthly_data
    };
}
```

---

### Step 4: Health Score Calculation

The health score is calculated using **weighted theme sentiment**:

```jac
can calculate_health_score(
    theme_analysis: list[dict],
    overall_sentiment_score: float,
    total_reviews: int
) -> dict {
    // Base score from overall sentiment (0-100 scale)
    base_score = overall_sentiment_score * 100;

    // Adjust based on theme performance
    theme_adjustment = 0;
    total_weight = 0;

    for theme in theme_analysis {
        weight = theme.mention_percentage / 100.0;
        sentiment = theme.avg_sentiment;

        // Positive themes boost, negative themes reduce
        theme_contribution = sentiment * weight * 20; // Scale factor
        theme_adjustment += theme_contribution;
        total_weight += weight;
    }

    // Combine base and theme adjustment
    health_score = base_score + (theme_adjustment / total_weight if total_weight > 0 else 0);

    // Clamp to 0-100
    health_score = max(0, min(100, health_score));

    // Calculate grade
    grade = calculate_health_grade(health_score);

    // Per-theme breakdown
    health_breakdown = {};
    for theme in theme_analysis {
        theme_health = 50 + (theme.avg_sentiment * 50); // Convert -1 to 1 => 0 to 100
        health_breakdown[theme.name] = round(theme_health);
    }

    return {
        score: round(health_score),
        grade: grade,
        breakdown: health_breakdown
    };
}

can calculate_health_grade(score: float) -> str {
    if score >= 97 { return "A+"; }
    elif score >= 93 { return "A"; }
    elif score >= 90 { return "A-"; }
    elif score >= 87 { return "B+"; }
    elif score >= 83 { return "B"; }
    elif score >= 80 { return "B-"; }
    elif score >= 77 { return "C+"; }
    elif score >= 73 { return "C"; }
    elif score >= 70 { return "C-"; }
    elif score >= 67 { return "D+"; }
    elif score >= 63 { return "D"; }
    elif score >= 60 { return "D-"; }
    else { return "F"; }
}
```

**Health Score Formula**:

```
health_score = base_sentiment_score + weighted_theme_adjustments

Where:
- base_sentiment_score: Overall sentiment (-1 to 1) * 100
- weighted_theme_adjustments: Sum of (theme_sentiment * mention_percentage * 20)
- Final score clamped to [0, 100]
```

---

### Step 5: LLM Pattern Analysis Call

After calculating statistics, the agent calls the LLM to generate:

- SWOT analysis
- Critical issues
- Pain points
- Delighters

**Function Signature**:

```jac
can generate_pattern_analysis(
    business_name: str,
    business_type: str,
    theme_analysis: list[dict],
    statistics: dict,
    trends: dict,
    health_score: int
) -> PatternAnalysisResult by llm(...);
```

**LLM Object**:

```jac
obj PatternAnalysisResult {
    has strengths: list[SwotItem];
    has weaknesses: list[SwotItem];
    has opportunities: list[SwotItem];
    has threats: list[SwotItem];
    has critical_issues: list[CriticalIssue];
    has pain_points: list[str];
    has delighters: list[str];
}

obj SwotItem {
    has category: str;
    has description: str;
    has impact: str;
    has evidence: list[str];
}

obj CriticalIssue {
    has issue: str;
    has severity: str;
    has affected_percentage: float;
    has recommendation: str;
}
```

**Prompt** (see [08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md) for full prompt)

---

## 📊 Output Structure

The Pattern Analyzer creates an **Analysis** node with:

```json
{
  "reviews_analyzed": 100,
  "date_range_start": "2023-01-15",
  "date_range_end": "2024-01-15",
  "health_score": 87,
  "health_grade": "B+",
  "health_breakdown": {
    "Room Quality": 92,
    "Service": 85,
    "Location": 90,
    "Value for Money": 78
  },
  "confidence_level": "high",
  "overall_sentiment": "POSITIVE",
  "sentiment_score": 0.72,
  "positive_count": 72,
  "negative_count": 18,
  "neutral_count": 10,
  "positive_percentage": 72.0,
  "negative_percentage": 18.0,
  "strengths": [
    {
      "category": "Room Quality",
      "description": "Exceptional cleanliness and modern amenities",
      "impact": "high",
      "evidence": [
        "92% positive mentions",
        "Cleanliness sub-theme rated 4.8/5",
        "Recent renovations highly praised"
      ]
    }
  ],
  "weaknesses": [
    {
      "category": "Value for Money",
      "description": "Pricing perceived as high relative to offerings",
      "impact": "medium",
      "evidence": [
        "35% of negative reviews mention price",
        "Avg sentiment -0.3 for value theme",
        "Comparisons to competitors frequent"
      ]
    }
  ],
  "opportunities": [...],
  "threats": [...],
  "critical_issues": [
    {
      "issue": "Slow check-in process during peak hours",
      "severity": "high",
      "affected_percentage": 28.0,
      "recommendation": "Implement mobile check-in and add staff during peak times"
    }
  ],
  "pain_points": [
    "Long wait times at front desk",
    "Limited parking availability",
    "Noisy air conditioning units"
  ],
  "delighters": [
    "Complimentary breakfast quality",
    "Rooftop pool with city views",
    "Personalized welcome amenities"
  ],
  "trend_direction": "improving",
  "monthly_breakdown": [...],
  "rating_distribution": {...},
  "avg_review_length": 142,
  "response_rate": 45.0
}
```

---

## 🔧 Implementation Notes

### Confidence Level Determination

```jac
can determine_confidence(total_reviews: int) -> str {
    if total_reviews <= CONFIDENCE_THRESHOLDS.low_max {
        return "low";
    } elif total_reviews <= CONFIDENCE_THRESHOLDS.medium_max {
        return "medium";
    } else {
        return "high";
    }
}
```

### Date Range Extraction

```jac
can extract_date_range(reviews: list[Review]) -> dict {
    dates = [parse_review_date(r.date) for r in reviews if r.date];

    if len(dates) == 0 {
        return {start: "Unknown", end: "Unknown"};
    }

    sorted_dates = sorted(dates);
    return {
        start: sorted_dates[0],
        end: sorted_dates[-1]
    };
}
```

### Sub-theme Filtering

Only include sub-themes with **minimum 3 mentions** and parent theme has **>5% mention rate**:

```python
if sub_theme.mention_count >= 3 and theme.mention_percentage >= 5:
    include_sub_theme()
```

---

## 📈 Node.js Implementation

```typescript
export class PatternAnalyzerAgent {
  constructor(private prisma: PrismaClient, private openai: OpenAIService) {}

  async execute(businessId: string) {
    // Get business with analyzed reviews
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      include: {
        reviews: { where: { analyzed: true } },
        themes: { include: { subThemes: true } },
      },
    });

    if (!business) throw new Error("Business not found");

    // Calculate statistics
    const stats = this.calculateStatistics(business.reviews);

    // Build theme analysis
    const themeAnalysis = this.buildThemeAnalysis(
      business.themes,
      business.reviews
    );

    // Calculate trends
    const trends = this.calculateTrends(business.reviews);

    // Calculate sentiment summary
    const sentimentSummary = this.calculateSentimentSummary(business.reviews);

    // Calculate health score
    const healthScore = this.calculateHealthScore(
      themeAnalysis,
      sentimentSummary.overall_score,
      business.reviews.length
    );

    // Call LLM for pattern analysis
    const llmResult = await this.openai.generatePatternAnalysis({
      business_name: business.name,
      business_type: business.businessTypeNormalized,
      theme_analysis: themeAnalysis,
      statistics: stats,
      trends: trends,
      health_score: healthScore.score,
    });

    // Save Analysis
    await this.prisma.analysis.create({
      data: {
        businessId: business.id,
        reviewsAnalyzed: business.reviews.length,
        dateRangeStart: this.extractDateRange(business.reviews).start,
        dateRangeEnd: this.extractDateRange(business.reviews).end,
        healthScore: healthScore.score,
        healthGrade: healthScore.grade,
        healthBreakdown: healthScore.breakdown,
        confidenceLevel: this.determineConfidence(business.reviews.length),
        overallSentiment: sentimentSummary.overall_sentiment,
        sentimentScore: sentimentSummary.overall_score,
        positiveCount: sentimentSummary.positive_count,
        negativeCount: sentimentSummary.negative_count,
        neutralCount: sentimentSummary.neutral_count,
        positivePercentage: sentimentSummary.positive_percentage,
        negativePercentage: sentimentSummary.negative_percentage,
        strengths: llmResult.strengths,
        weaknesses: llmResult.weaknesses,
        opportunities: llmResult.opportunities,
        threats: llmResult.threats,
        criticalIssues: llmResult.critical_issues,
        painPoints: llmResult.pain_points,
        delighters: llmResult.delighters,
        trendDirection: trends.direction,
        monthlyBreakdown: trends.monthly_breakdown,
        ratingDistribution: stats.rating_distribution,
        avgReviewLength: stats.avg_review_length,
        responseRate: stats.response_rate,
      },
    });
  }

  private calculateStatistics(reviews: Review[]) {
    // Implementation from above
  }

  private buildThemeAnalysis(themes: Theme[], reviews: Review[]) {
    // Implementation from above
  }

  private calculateTrends(reviews: Review[]) {
    // Implementation from above
  }

  private calculateHealthScore(
    themeAnalysis: any[],
    overallScore: number,
    totalReviews: number
  ) {
    // Implementation from above
  }

  private determineConfidence(totalReviews: number): string {
    if (totalReviews <= 20) return "low";
    if (totalReviews <= 50) return "medium";
    return "high";
  }
}
```

---

## ✅ Summary

Pattern analysis:

- ✅ Calculates comprehensive statistics
- ✅ Builds theme analysis with sub-themes
- ✅ Computes health score (0-100 + grade)
- ✅ Identifies trends (improving/declining/stable)
- ✅ Generates SWOT with LLM
- ✅ Lists critical issues with severity
- ✅ Extracts pain points and delighters
- ✅ Stores everything in Analysis node

**Next**: Read [05-REPORT-GENERATION.md](./05-REPORT-GENERATION.md) for the final agent.
