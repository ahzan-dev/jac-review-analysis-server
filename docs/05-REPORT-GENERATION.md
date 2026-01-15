# Report Generation Stage

## 🎯 Overview

**Agent**: `ReportGeneratorAgent`  
**Purpose**: Generate executive-level insights, key findings, and prioritized actionable recommendations.

**Input**:

- Business data
- Analysis results (health score, SWOT, themes)
- Review data
- Analysis depth ('deep' or 'quick')

**Output**:

- Executive summary (headline, one-liner, key metric)
- Key findings (top 5-7 insights)
- Prioritized recommendations (immediate, short-term, long-term)

---

## 🔍 Processing Steps

### Step 1: Prepare Analysis Context

```jac
walker ReportGeneratorAgent {
    has business_name: str;
    has business_type: str;
    has analysis_depth: str = "deep";
    has total_reviews: int;
    has avg_rating: float;

    can generate with Business entry {
        // Get related analysis
        analysis_node = [-->(`?Analysis)][0];

        if not analysis_node {
            report "No analysis found for this business";
            disengage;
        }

        // Prepare context for LLM
        context = {
            business_name: here.name,
            business_type: here.business_type_normalized,
            total_reviews: here.total_reviews,
            avg_rating: here.rating,
            health_score: analysis_node.health_score,
            health_grade: analysis_node.health_grade,
            overall_sentiment: analysis_node.overall_sentiment,
            sentiment_score: analysis_node.sentiment_score,
            confidence_level: analysis_node.confidence_level,
            theme_analysis: self.prepare_theme_summary(here),
            swot: {
                strengths: analysis_node.strengths,
                weaknesses: analysis_node.weaknesses,
                opportunities: analysis_node.opportunities,
                threats: analysis_node.threats
            },
            critical_issues: analysis_node.critical_issues,
            pain_points: analysis_node.pain_points,
            delighters: analysis_node.delighters,
            trend_direction: analysis_node.trend_direction,
            rating_distribution: analysis_node.rating_distribution
        };

        // Call LLM
        report_result = generate_report_content(
            context=context,
            analysis_depth=self.analysis_depth
        );

        // Create Report node
        report_node ++> here Report(
            report_type=self.analysis_depth,
            headline=report_result.headline,
            one_liner=report_result.one_liner,
            key_metric=report_result.key_metric,
            executive_summary=report_result.executive_summary,
            key_findings=report_result.key_findings,
            recommendations_immediate=report_result.recommendations_immediate,
            recommendations_short_term=report_result.recommendations_short_term,
            recommendations_long_term=report_result.recommendations_long_term
        );
        here ++> report_node :HasReport;

        report "Report generated successfully";
    }

    can prepare_theme_summary(business: Business) -> list[dict] {
        themes = [-->(`?Theme)];
        summary = [];

        for theme in themes {
            summary.append({
                name: theme.name,
                mention_count: theme.mention_count,
                avg_sentiment: theme.avg_sentiment,
                positive_count: theme.positive_count,
                negative_count: theme.negative_count
            });
        }

        return sorted(summary, key=lambda x: x.mention_count, reverse=True)[:10];
    }
}
```

---

### Step 2: LLM Report Generation Call

**Function Signature**:

```jac
can generate_report_content(
    context: dict,
    analysis_depth: str
) -> ReportGenerationResult by llm(...);
```

**LLM Object**:

```jac
obj ReportGenerationResult {
    has headline: str;
    has one_liner: str;
    has key_metric: str;
    has executive_summary: str;
    has key_findings: list[str];
    has recommendations_immediate: list[Recommendation];
    has recommendations_short_term: list[Recommendation];
    has recommendations_long_term: list[Recommendation];
}

obj Recommendation {
    has title: str;
    has description: str;
    has rationale: str;
    has expected_impact: str;
    has priority_score: int;
    has effort: str;
    has timeframe: str;
}
```

**Semantic Annotations**:

```jac
sem "Generate an executive business intelligence report"
sem "Create actionable, prioritized recommendations"
sem "Headline should be attention-grabbing and data-driven"
sem "One-liner should summarize overall business health in one sentence"
sem "Key metric should highlight the most important single number"
sem "Executive summary should be 3-4 sentences maximum"
sem "Key findings should be specific, quantified insights (5-7 items)"
sem "Recommendations must have clear priority scores and expected impact"
sem "Immediate actions: can be done in 1-2 weeks"
sem "Short-term actions: 1-3 months"
sem "Long-term actions: 3-12 months"
sem "Effort levels: Low (< 1 week), Medium (1-4 weeks), High (1-3 months)"
```

**Full Prompt** available in [08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md)

---

### Step 3: Priority Score Calculation

Recommendations are scored 0-100 based on:

```python
priority_score = (
    impact_weight * 0.5 +
    urgency_weight * 0.3 +
    feasibility_weight * 0.2
) * 100
```

**Impact Weights**:

- High impact: 1.0
- Medium impact: 0.6
- Low impact: 0.3

**Urgency Weights**:

- Critical: 1.0
- High: 0.7
- Medium: 0.4
- Low: 0.2

**Feasibility Weights**:

- Low effort: 1.0
- Medium effort: 0.6
- High effort: 0.3

**Example**:

```json
{
  "title": "Implement Mobile Check-in",
  "impact": "high",
  "urgency": "high",
  "effort": "medium",
  "priority_score": 83
}
```

Calculation: `(1.0 * 0.5 + 0.7 * 0.3 + 0.6 * 0.2) * 100 = 83`

---

### Step 4: Timeframe Classification

**Immediate Actions** (1-2 weeks):

- Quick wins with high impact
- Critical issues requiring urgent attention
- Low-effort improvements
- Examples:
  - Update website hours
  - Train staff on common complaints
  - Post responses to negative reviews

**Short-Term Actions** (1-3 months):

- Process improvements
- Staff training programs
- Menu/offering adjustments
- Examples:
  - Revise menu based on feedback
  - Implement new booking system
  - Launch customer loyalty program

**Long-Term Actions** (3-12 months):

- Strategic initiatives
- Major renovations
- Market positioning changes
- Examples:
  - Complete facility renovation
  - Expand service offerings
  - Rebrand for different market segment

---

## 📊 Output Structure

The Report Generator creates a **Report** node with:

```json
{
  "report_type": "deep",
  "headline": "87% Positive Reviews Signal Strong Performance, But Value Perception Needs Attention",
  "one_liner": "citizenM Paris La Defense excels in modern design and location but faces pricing pressure from competitor comparisons.",
  "key_metric": "Health Score: 87/100 (B+) - Above industry average with room for improvement in value perception",
  "executive_summary": "Based on analysis of 100 recent reviews, the business demonstrates strong performance across most key areas with an overall health score of 87/100 (B+). Room quality and location are standout strengths, while value for money presents the primary opportunity for improvement. The business is trending positively with recent ratings showing 15% improvement over 6 months.",
  "key_findings": [
    "92% of reviewers praise room quality, with cleanliness and modern amenities most frequently mentioned",
    "Location scores 4.8/5 average, with 78% highlighting proximity to La Defense business district",
    "Value for money concerns appear in 35% of critical reviews, driven by competitor price comparisons",
    "Response rate of 45% is below industry standard of 60%, indicating engagement opportunity",
    "Service quality shows improvement trend with 20% increase in positive mentions over last quarter",
    "Parking availability mentioned as pain point in 28% of reviews, particularly by business travelers",
    "Breakfast offering rated 4.6/5 and identified as key differentiator and 'delighter'"
  ],
  "recommendations_immediate": [
    {
      "title": "Respond to All Reviews from Last 30 Days",
      "description": "Immediately respond to all unanswered reviews from the past month, prioritizing negative and neutral reviews. Use personalized, specific responses that address reviewer concerns.",
      "rationale": "Current 45% response rate is significantly below 60% industry standard. Active engagement signals commitment to customer experience and can improve ratings by up to 0.3 points.",
      "expected_impact": "Boost response rate to 80%, improve customer perception, potentially convert neutral reviewers to promoters",
      "priority_score": 92,
      "effort": "Low",
      "timeframe": "1-2 weeks"
    },
    {
      "title": "Create Value Communication Package",
      "description": "Develop clear messaging highlighting unique value propositions (location, modern design, breakfast quality) for website, booking confirmations, and in-room materials.",
      "rationale": "35% of price concerns stem from unclear value differentiation versus competitors. Better communication of unique benefits can shift perception without price changes.",
      "expected_impact": "Reduce value complaints by 20%, improve booking conversion rate, strengthen brand positioning",
      "priority_score": 85,
      "effort": "Low",
      "timeframe": "1-2 weeks"
    }
  ],
  "recommendations_short_term": [
    {
      "title": "Implement Dynamic Parking Solution",
      "description": "Partner with nearby parking facilities to offer discounted rates or shuttle service. Provide clear parking information at booking and check-in.",
      "rationale": "28% of negative reviews mention parking difficulty. Business travelers represent 60% of clientele and rank parking as top-3 decision factor.",
      "expected_impact": "Eliminate primary pain point, increase business traveler satisfaction by 25%, reduce related negative reviews by 70%",
      "priority_score": 78,
      "effort": "Medium",
      "timeframe": "1-3 months"
    },
    {
      "title": "Launch Mobile Check-in with Room Selection",
      "description": "Implement mobile app check-in allowing guests to select rooms, view floor plans, and bypass front desk during peak hours.",
      "rationale": "Check-in wait times mentioned in 15% of reviews. Mobile check-in reduces wait times by 60% and improves overall experience scores by 0.4 points on average.",
      "expected_impact": "Reduce front desk congestion by 40%, improve check-in satisfaction scores by 35%, enhance tech-forward brand image",
      "priority_score": 82,
      "effort": "Medium",
      "timeframe": "2-3 months"
    }
  ],
  "recommendations_long_term": [
    {
      "title": "Develop Tiered Room Product Strategy",
      "description": "Create distinct room tiers (Standard, Premium, Suite) with clear value differentiation and pricing structure. Enhance premium offerings with additional amenities.",
      "rationale": "Current single-tier approach limits revenue optimization and creates value perception issues. Tiered pricing allows capturing different market segments while maintaining accessible entry point.",
      "expected_impact": "Increase revenue per available room by 15-20%, improve value perception scores by 30%, capture premium segment willing to pay more",
      "priority_score": 73,
      "effort": "High",
      "timeframe": "6-9 months"
    }
  ]
}
```

---

## 🎯 Report Quality Guidelines

### Headline Requirements:

- ✅ Data-driven (include specific percentages or scores)
- ✅ Attention-grabbing but professional
- ✅ Balanced (mention both strengths and opportunities)
- ✅ Action-oriented tone
- ❌ Avoid generic phrases like "Good but needs improvement"

### Key Findings Requirements:

- ✅ Each finding must include quantifiable data
- ✅ Specific rather than vague (✅ "92% praise room quality" vs. ❌ "Most like the rooms")
- ✅ Mix of positive insights and improvement areas
- ✅ Provide context (industry benchmarks, trends)
- ✅ 5-7 findings total

### Recommendation Requirements:

- ✅ Clear title (action verb + specific target)
- ✅ Detailed description (how to implement)
- ✅ Evidence-based rationale
- ✅ Quantified expected impact
- ✅ Realistic timeframe and effort estimate
- ✅ Priority score calculated consistently

---

## 📈 Node.js Implementation

```typescript
export class ReportGeneratorAgent {
  constructor(private prisma: PrismaClient, private openai: OpenAIService) {}

  async execute(businessId: string, analysisDepth: string = "deep") {
    // Get business with all related data
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      include: {
        themes: true,
        analyses: {
          orderBy: { createdAt: "desc" },
          take: 1,
        },
      },
    });

    if (!business || !business.analyses[0]) {
      throw new Error("Business or analysis not found");
    }

    const analysis = business.analyses[0];

    // Prepare context
    const context = {
      business_name: business.name,
      business_type: business.businessTypeNormalized,
      total_reviews: business.totalReviews,
      avg_rating: business.rating,
      health_score: analysis.healthScore,
      health_grade: analysis.healthGrade,
      overall_sentiment: analysis.overallSentiment,
      sentiment_score: analysis.sentimentScore,
      confidence_level: analysis.confidenceLevel,
      theme_analysis: this.prepareThemeSummary(business.themes),
      swot: {
        strengths: analysis.strengths,
        weaknesses: analysis.weaknesses,
        opportunities: analysis.opportunities,
        threats: analysis.threats,
      },
      critical_issues: analysis.criticalIssues,
      pain_points: analysis.painPoints,
      delighters: analysis.delighters,
      trend_direction: analysis.trendDirection,
      rating_distribution: analysis.ratingDistribution,
    };

    // Call LLM
    const reportResult = await this.openai.generateReport({
      context,
      analysis_depth: analysisDepth,
    });

    // Calculate priority scores for recommendations
    this.calculatePriorityScores(reportResult.recommendations_immediate);
    this.calculatePriorityScores(reportResult.recommendations_short_term);
    this.calculatePriorityScores(reportResult.recommendations_long_term);

    // Save Report
    await this.prisma.report.create({
      data: {
        businessId: business.id,
        reportType: analysisDepth,
        headline: reportResult.headline,
        oneLiner: reportResult.one_liner,
        keyMetric: reportResult.key_metric,
        executiveSummary: reportResult.executive_summary,
        keyFindings: reportResult.key_findings,
        recommendationsImmediate: reportResult.recommendations_immediate,
        recommendationsShortTerm: reportResult.recommendations_short_term,
        recommendationsLongTerm: reportResult.recommendations_long_term,
      },
    });
  }

  private prepareThemeSummary(themes: Theme[]) {
    return themes
      .map((theme) => ({
        name: theme.name,
        mention_count: theme.mentionCount,
        avg_sentiment: theme.avgSentiment,
        positive_count: theme.positiveCount,
        negative_count: theme.negativeCount,
      }))
      .sort((a, b) => b.mention_count - a.mention_count)
      .slice(0, 10);
  }

  private calculatePriorityScores(recommendations: any[]) {
    for (const rec of recommendations) {
      const impactWeight = this.getImpactWeight(rec.expected_impact);
      const urgencyWeight = this.getUrgencyWeight(rec);
      const effortWeight = this.getEffortWeight(rec.effort);

      rec.priority_score = Math.round(
        (impactWeight * 0.5 + urgencyWeight * 0.3 + effortWeight * 0.2) * 100
      );
    }

    // Sort by priority score descending
    recommendations.sort((a, b) => b.priority_score - a.priority_score);
  }

  private getImpactWeight(impactText: string): number {
    if (
      impactText.toLowerCase().includes("high") ||
      impactText.toLowerCase().includes("significant")
    ) {
      return 1.0;
    }
    if (
      impactText.toLowerCase().includes("medium") ||
      impactText.toLowerCase().includes("moderate")
    ) {
      return 0.6;
    }
    return 0.3;
  }

  private getUrgencyWeight(rec: any): number {
    if (
      rec.timeframe.includes("1-2 weeks") ||
      rec.rationale.toLowerCase().includes("critical")
    ) {
      return 1.0;
    }
    if (rec.timeframe.includes("1-3 months")) {
      return 0.7;
    }
    return 0.4;
  }

  private getEffortWeight(effort: string): number {
    if (effort.toLowerCase() === "low") return 1.0;
    if (effort.toLowerCase() === "medium") return 0.6;
    return 0.3;
  }
}
```

---

## ✅ Summary

Report generation:

- ✅ Creates executive-level summary
- ✅ Generates data-driven headline and key metric
- ✅ Produces 5-7 quantified key findings
- ✅ Prioritizes recommendations by impact/urgency/effort
- ✅ Classifies actions into immediate/short-term/long-term
- ✅ Calculates priority scores (0-100)
- ✅ Provides implementation guidance for each recommendation
- ✅ Stores everything in Report node

**Next**: Read [09-BUSINESS-TYPES.md](./09-BUSINESS-TYPES.md) for complete business type mappings.
