# All LLM Prompts Reconstructed

## 🎯 Overview

Jac's `by llm` operator automatically generates prompts from function signatures and semantic annotations. This document reconstructs those prompts for use in Node.js/Python with OpenAI/Anthropic APIs.

The system makes **3 LLM calls** in total:

1. **Sentiment Analysis** (Batch - 5 reviews at a time)
2. **Pattern Analysis** (Once per business)
3. **Report Generation** (Once per business)

---

## 🔄 LLM Call 1: Batch Sentiment Analysis

### Function Signature (Jac)

```jac
def analyze_reviews_batch(
    reviews: list,
    business_type: str,
    allowed_themes: list,
    allowed_sub_themes: dict
) -> BatchReviewAnalysis by llm(incl_info={...});
```

### Reconstructed Prompt

````markdown
# Role

You are an expert sentiment analyzer specializing in customer reviews for {business_type} businesses.

# Task

Analyze the following batch of customer reviews and extract structured insights for each review.

# Business Context

- **Business Type**: {business_type}
- **Reviews to Analyze**: {len(reviews)}

# Allowed Main Themes

You MUST use ONLY these main themes (do not invent new themes):
{allowed_themes}

# Allowed Sub-themes

For each main theme, you can ONLY use these specific sub-themes:
{allowed_sub_themes}

# Reviews

```json
{reviews}
```

# Output Format

Return a JSON object with this EXACT structure:

```json
{
  "reviews": [
    {
      "review_index": 0,
      "sentiment": "positive",
      "sentiment_score": 0.85,
      "themes": ["Room Quality", "Service"],
      "sub_themes": [
        {
          "theme": "Room Quality",
          "sub_themes": ["Cleanliness", "Bed Comfort", "Size"]
        },
        {
          "theme": "Service",
          "sub_themes": ["Front Desk", "Staff Attitude"]
        }
      ],
      "keywords": [
        "clean room",
        "comfortable bed",
        "friendly staff",
        "quick check-in"
      ],
      "emotion": "happy"
    }
  ]
}
```

# Detailed Guidelines

## 1. Sentiment Classification

- **positive**: Overall positive experience, satisfied customer
  - Score range: 0.3 to 1.0
  - Examples: "Great!", "Loved it", "Highly recommend"
- **negative**: Overall negative experience, dissatisfied customer
  - Score range: -1.0 to -0.3
  - Examples: "Terrible", "Disappointed", "Never again"
- **neutral**: Neither strongly positive nor negative
  - Score range: -0.3 to 0.3
  - Examples: "It was okay", "Average experience", "Nothing special"
- **mixed**: Contains both significant positive and negative aspects
  - Score range: -0.3 to 0.3
  - Examples: "Food was great but service was slow"

## 2. Sentiment Score Calculation

- Start with star rating as baseline:

  - 5 stars → 0.8 to 1.0
  - 4 stars → 0.4 to 0.7
  - 3 stars → -0.2 to 0.2
  - 2 stars → -0.7 to -0.4
  - 1 star → -1.0 to -0.8

- Adjust based on review text tone:
  - Very enthusiastic language → +0.1 to +0.2
  - Complaints or frustration → -0.1 to -0.2
  - Specific problems mentioned → additional -0.1 per serious issue

## 3. Theme Detection Rules

- **Only use themes from the allowed_themes list**
- A review can have 1-5 themes
- Include a theme if it's:
  - Explicitly mentioned (e.g., "The food was delicious")
  - Strongly implied (e.g., "We waited 45 minutes" → Service theme)
- Order themes by prominence in the review

## 4. Sub-theme Detection Rules

- **Only use sub-themes from allowed_sub_themes for each main theme**
- Be as specific as possible
- For "Room Quality" → use "Cleanliness", "Bed Comfort", not just generic terms
- A main theme can have 1-5 sub-themes
- Example:
  - Review mentions "dirty bathroom" →
    - Theme: "Room Quality"
    - Sub-themes: ["Cleanliness", "Maintenance"]

## 5. Keyword Extraction

- Extract 3-5 meaningful phrases from the review
- Use customer's actual words when possible
- Focus on specific details, not generic terms
- Good examples:
  - "ocean view room"
  - "breakfast buffet variety"
  - "broken AC for 2 days"
- Bad examples:
  - "good"
  - "nice"
  - "pleasant"

## 6. Emotion Detection

Choose the PRIMARY emotion:

- **happy**: Delighted, excited, thrilled, love
  - "I loved this place!", "Can't wait to return!"
- **satisfied**: Content, pleased, expectations met
  - "Good experience", "Met our expectations"
- **impressed**: Positively surprised, exceeded expectations
  - "Wow!", "Exceeded expectations", "Blown away"
- **disappointed**: Unmet expectations, let down
  - "Expected more", "Not what we hoped for"
- **frustrated**: Annoyed, inconvenienced, hassled
  - "So many problems", "Constant issues"
- **angry**: Very upset, demanding refund, furious
  - "Unacceptable!", "Worst experience ever"
- **neutral**: No strong emotion expressed
  - "It was fine", "Nothing to complain about"

# Important Notes

1. Analyze ALL reviews in the batch (indices 0 to {len(reviews)-1})
2. Return results in the EXACT order provided
3. Do NOT skip any reviews
4. Do NOT add reviews that weren't in the input
5. Use ONLY the allowed themes and sub-themes - do not create new ones
6. Be consistent with theme naming (exact match to allowed list)

# Quality Checks

Before returning your response, verify:

- [ ] Number of results matches number of input reviews
- [ ] All review_index values are present (0, 1, 2, ...)
- [ ] All themes used are from allowed_themes list
- [ ] All sub-themes used are from allowed_sub_themes for that theme
- [ ] Sentiment scores are between -1.0 and 1.0
- [ ] Each review has 3-5 keywords
````

### Node.js/TypeScript Implementation

```typescript
async function analyzeBatch(
  reviews: Array<{ index: number; rating: number; text: string }>,
  businessType: string,
  allowedThemes: string[],
  allowedSubThemes: Record<string, string[]>
) {
  const prompt = `
# Role
You are an expert sentiment analyzer specializing in customer reviews for ${businessType} businesses.

# Task
Analyze the following ${
    reviews.length
  } customer reviews and extract structured insights for each review.

# Allowed Main Themes
${JSON.stringify(allowedThemes, null, 2)}

# Allowed Sub-themes
${JSON.stringify(allowedSubThemes, null, 2)}

# Reviews
${JSON.stringify(reviews, null, 2)}

# Output Format
[Include full format and guidelines from above]
`;

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content:
          "You are an expert sentiment analyzer for customer reviews. Return only valid JSON.",
      },
      {
        role: "user",
        content: prompt,
      },
    ],
    response_format: { type: "json_object" },
    temperature: 0.3,
    max_tokens: 2000,
  });

  return JSON.parse(response.choices[0].message.content);
}
```

---

## 🎯 LLM Call 2: Pattern Analysis

### Function Signature (Jac)

```jac
def generate_pattern_analysis(
    business_name: str,
    business_type: str,
    review_count: int,
    stats: dict,
    themes: list,
    trends: dict
) -> PatternAnalysisResult by llm(incl_info={...});
```

### Reconstructed Prompt

````markdown
# Role

You are a business intelligence analyst specializing in customer experience analysis for {business_type} businesses.

# Task

Analyze review patterns and generate a comprehensive health assessment with actionable insights.

# Business Information

- **Name**: {business_name}
- **Type**: {business_type}
- **Reviews Analyzed**: {review_count}

# Sentiment Statistics

```json
{stats}
```

# Theme Analysis

```json
{themes}
```

# Trend Data

```json
{trends}
```

# Output Format

Return a JSON object with this structure:

```json
{
  "health_score": 85,
  "health_grade": "B+",
  "health_breakdown": [
    { "theme": "Room Quality", "score": 88 },
    { "theme": "Service", "score": 82 }
  ],
  "overall_sentiment": "positive",
  "trend_direction": "improving",
  "strengths": [
    { "point": "Exceptional beachfront location", "evidence_count": 42 }
  ],
  "weaknesses": [
    { "point": "Slow maintenance response", "evidence_count": 18 }
  ],
  "opportunities": [{ "point": "Expand spa services", "evidence_count": 22 }],
  "threats": [
    { "point": "Rising guest expectations for technology", "evidence_count": 8 }
  ],
  "critical_issues": [
    {
      "issue": "Maintenance delays causing dissatisfaction",
      "severity": "high",
      "mention_count": 18,
      "suggested_action": "Implement 24-hour maintenance hotline"
    }
  ],
  "delighters": [
    "Exceptional beachfront access",
    "High-quality breakfast buffet"
  ],
  "pain_points": ["Slow maintenance response", "Inconsistent housekeeping"]
}
```

# Detailed Guidelines

## 1. Health Score Calculation (0-100)

Base score on:

- **Overall sentiment** (40% weight)
  - Positive % × 0.4 × 100
- **Theme sentiment averages** (40% weight)
  - Average all theme sentiment scores
  - Convert to 0-100 scale
- **Trend direction** (20% weight)
  - Improving: +10 points
  - Stable: 0 points
  - Declining: -10 points

Formula example:

```
health_score = (positive_pct * 0.4) + (avg_theme_sentiment * 20 + 50) * 0.4 + trend_bonus
```

Round to nearest integer.

## 2. Health Grade Assignment

- **A+**: 95-100
- **A**: 90-94
- **A-**: 87-89
- **B+**: 83-86
- **B**: 80-82
- **B-**: 77-79
- **C+**: 73-76
- **C**: 70-72
- **C-**: 67-69
- **D**: 60-66
- **F**: Below 60

## 3. Health Breakdown by Theme

For each theme with 5+ mentions:

- Calculate theme score:
  - positive_count / mention_count × 100 × 0.7
  - (avg_sentiment + 1) / 2 × 100 × 0.3
- Round to nearest integer
- Include in breakdown

## 4. Overall Sentiment

Based on positive percentage:

- **very_positive**: 80-100%
- **positive**: 60-79%
- **mixed**: 40-59%
- **negative**: 20-39%
- **very_negative**: 0-19%

## 5. Trend Direction

- Use provided trend data
- If improving: mention % change
- If declining: flag as concern

## 6. SWOT Analysis

### Strengths (3-7 items)

- Themes with >0.5 sentiment AND >20% mention rate
- Specific positive aspects mentioned 10+ times
- Consistency in positive feedback
- Each strength needs:
  - Clear description
  - Evidence count (number of reviews)

### Weaknesses (3-7 items)

- Themes with <-0.2 sentiment
- Recurring negative mentions (5+ times)
- Inconsistency issues
- Each weakness needs:
  - Clear description
  - Evidence count

### Opportunities (2-5 items)

- Positive themes with room for expansion
- Services mentioned as desired but not offered
- Competitor gaps mentioned
- Market trends from reviews

### Threats (1-3 items)

- Emerging negative patterns
- Competitor advantages mentioned
- Changing customer expectations
- External factors affecting business

## 7. Critical Issues

Identify issues requiring immediate attention:

**High Severity** (mention_count ≥ 10 OR <-0.6 sentiment):

- Safety concerns
- Service failures affecting multiple guests
- Facility problems

**Medium Severity** (mention_count ≥ 5 OR <-0.4 sentiment):

- Inconsistency issues
- Minor facility problems
- Process inefficiencies

**Low Severity** (mention_count ≥ 3 OR <-0.2 sentiment):

- Minor inconveniences
- Limited options/choices
- Enhancement requests

For each issue:

- **issue**: Clear description of the problem
- **severity**: "high", "medium", or "low"
- **mention_count**: Number of reviews mentioning it
- **suggested_action**: Specific, actionable solution

## 8. Delighters (3-7 items)

Things that EXCEED expectations:

- Mentioned with strong positive language
- Surprise and delight moments
- "Wow" factors
- Specific features praised repeatedly

## 9. Pain Points (3-7 items)

Common frustrations:

- Recurring complaints
- Process friction
- Unmet expectations
- Consistency issues

# Quality Checks

- [ ] Health score is between 0-100
- [ ] Health grade matches score range
- [ ] All themes in breakdown have valid scores
- [ ] SWOT items have evidence counts
- [ ] Critical issues have severity and actions
- [ ] All lists have reasonable lengths (not too short/long)
````

### Node.js/TypeScript Implementation

```typescript
async function generatePatternAnalysis(
  businessName: string,
  businessType: string,
  reviewCount: number,
  stats: any,
  themes: any[],
  trends: any
) {
  const prompt = `
# Role
You are a business intelligence analyst for ${businessType} businesses.

# Business: ${businessName}
# Reviews Analyzed: ${reviewCount}

# Sentiment Statistics
${JSON.stringify(stats, null, 2)}

# Theme Analysis
${JSON.stringify(themes, null, 2)}

# Trends
${JSON.stringify(trends, null, 2)}

[Include full guidelines from above]
`;

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content:
          "You are a business intelligence analyst. Return only valid JSON.",
      },
      {
        role: "user",
        content: prompt,
      },
    ],
    response_format: { type: "json_object" },
    temperature: 0.5,
    max_tokens: 3000,
  });

  return JSON.parse(response.choices[0].message.content);
}
```

---

## 📝 LLM Call 3: Report Generation

### Function Signature (Jac)

```jac
def generate_report_content(
    business_name: str,
    business_type: str,
    rating: float,
    total_reviews: int,
    reviews_analyzed: int,
    health_score: int,
    health_grade: str,
    confidence_level: str,
    sentiment_score: float,
    positive_pct: float,
    negative_pct: float,
    strengths: list,
    weaknesses: list,
    opportunities: list,
    critical_issues: list,
    themes: list,
    trend: str,
    monthly_breakdown: list
) -> ReportGenerationResult by llm(incl_info={...});
```

### Reconstructed Prompt

````markdown
# Role

You are an executive business consultant writing a strategic report for a {business_type} business owner.

# Task

Create an actionable executive report with specific, prioritized recommendations.

# Business Profile

- **Name**: {business_name}
- **Type**: {business_type}
- **Google Rating**: {rating}/5 ({total_reviews} total reviews)
- **Reviews Analyzed**: {reviews_analyzed}

# Performance Metrics

- **Health Score**: {health_score}/100 ({health_grade})
- **Confidence**: {confidence_level}
- **Sentiment Score**: {sentiment_score} ({positive_pct}% positive, {negative_pct}% negative)
- **Trend**: {trend}

# SWOT Analysis

```json
{
  "strengths": {strengths},
  "weaknesses": {weaknesses},
  "opportunities": {opportunities}
}
```

# Critical Issues

```json
{critical_issues}
```

# Theme Performance

```json
{themes}
```

# Monthly Breakdown

```json
{monthly_breakdown}
```

# Output Format

```json
{
  "headline": "5-10 word impactful headline",
  "one_liner": "Single sentence summary",
  "key_metric": "The ONE most important metric or action",
  "executive_summary": "2-3 paragraph strategic overview",
  "key_findings": [
    "Finding 1 with specific data",
    "Finding 2 with specific data"
  ],
  "recommendations_immediate": [
    {
      "action": "Specific action to take",
      "reason": "Why this matters",
      "expected_impact": "Measurable outcome",
      "effort": "low",
      "priority_score": 95
    }
  ],
  "recommendations_short_term": [],
  "recommendations_long_term": []
}
```

# Detailed Guidelines

## 1. Headline (5-10 words)

- Capture the essence in under 10 words
- Balance positive and negative
- Action-oriented or insight-driven
- Examples:
  - "Strong Foundation, Service Excellence Needs Focus"
  - "Location Excellence, Operational Gaps Holding Back Growth"
  - "Rising Star with Fixable Service Inconsistencies"

## 2. One-Liner (Single Sentence)

- Expand on headline with key insight
- 15-25 words
- Include both strength and challenge
- Examples:
  - "Exceptional beachfront experience marred by maintenance delays and service inconsistencies."
  - "Outstanding food quality driving high satisfaction, but value perception limiting growth potential."

## 3. Key Metric

- The ONE number or action that matters most
- Specific and actionable
- Examples:
  - "85/100 Health Score - Fix maintenance response to reach A-grade"
  - "76% positive rate - Address service consistency to reach 85%+"
  - "Implement 24h maintenance hotline to eliminate #1 complaint"

## 4. Executive Summary (2-3 paragraphs)

**Paragraph 1**: Current State & Strengths

- Lead with health score and grade
- Highlight 2-3 key strengths with data
- Mention positive sentiment percentage
- Example start: "{business_name} maintains a strong B+ health score (85/100) driven primarily by..."

**Paragraph 2**: Challenges & Opportunities

- Identify 2-3 specific pain points with data
- Frame as addressable challenges, not failures
- Connect to evidence (review counts, sentiment scores)
- Example: "However, operational inconsistencies in maintenance response times (18 complaints) and..."

**Paragraph 3**: Path Forward & Impact

- Reference trend direction
- State potential for improvement
- Connect recommendations to score improvement
- Example: "The property shows positive momentum... Implementing the immediate recommendations could elevate the health score to 90+ (A-grade) within 60 days."

## 5. Key Findings (5-15 items)

Scale based on review count:

- **20-30 reviews**: 5-7 findings
- **30-75 reviews**: 8-12 findings
- **75+ reviews**: 12-15 findings

Each finding should:

- Include specific data (scores, counts, percentages)
- Be actionable or insightful
- Reference actual themes/issues from data
- Use concrete numbers

Format: "{Theme/Topic} {performance descriptor} ({score/count}) - {specific detail}"

Examples:

- "Location is the #1 driver of positive reviews (92/100) - beachfront access consistently praised"
- "Service inconsistency affecting 15 reviews - front desk experience varies significantly"
- "Positive momentum: sentiment improved 15% over past 6 months from 0.45 to 0.75"

## 6. Immediate Recommendations (This Week)

**Criteria**:

- Can be implemented within 7 days
- High-impact problems (mention_count ≥ 10 OR severity = "high")
- Low to medium effort
- Priority score: 80-100

**Count**: 2-4 recommendations

Each recommendation needs:

- **action**: Specific, concrete action (start with verb)
  - Good: "Establish 24/7 maintenance hotline with <30min guaranteed response"
  - Bad: "Improve maintenance"
- **reason**: Why this matters NOW (reference data)
  - Include mention counts or sentiment scores
  - Connect to critical issues
  - Example: "18 reviews cite slow maintenance response causing significant dissatisfaction"
- **expected_impact**: Quantifiable outcome (be specific)
  - Good: "Reduce negative maintenance reviews by 60-70% within 2 weeks"
  - Bad: "Improve satisfaction"
- **effort**: "low" | "medium" | "high"
  - low: Process change, training, checklist
  - medium: New hire, software, minor renovation
  - high: Major renovation, system overhaul
- **priority_score**: 80-100
  - 95-100: Critical, affecting many guests
  - 85-94: Important, significant impact
  - 80-84: Necessary, moderate impact

## 7. Short-term Recommendations (This Month)

**Criteria**:

- Implementable within 30 days
- Medium-impact improvements
- Medium effort acceptable
- Priority score: 65-85

**Count**: 3-5 recommendations

Follow same format as immediate, but:

- Can involve more planning/coordination
- May require budget approval
- Could need vendor/supplier engagement

## 8. Long-term Recommendations (This Quarter)

**Criteria**:

- Strategic improvements (60-90 days)
- Opportunities from SWOT
- High effort projects acceptable
- Priority score: 60-80

**Count**: 2-4 recommendations

Focus on:

- Service expansion (spa, tours, dining)
- Facility upgrades
- Technology implementation
- New programs/packages

## Priority Score Calculation

```
priority_score =
  (mention_count / total_reviews * 40) +
  (abs(sentiment_score) * 30) +
  (impact_potential * 20) +
  (urgency * 10)
```

Round to nearest integer.

# Writing Guidelines

## Tone

- Professional but accessible
- Data-driven, not opinionated
- Action-oriented
- Constructive, not critical
- Confident in recommendations

## Language

- Use active voice
- Be specific with numbers
- Avoid jargon
- Short, clear sentences
- Bullet points for clarity

## Data Usage

- Always cite evidence (counts, percentages, scores)
- Compare to benchmarks when relevant
- Show trends with before/after numbers
- Use percentages for impact projections

# Quality Checks

- [ ] Headline is 5-10 words
- [ ] One-liner is a single sentence (15-25 words)
- [ ] Key metric is specific and measurable
- [ ] Executive summary is 2-3 paragraphs
- [ ] Key findings count matches review count scale
- [ ] All recommendations have all 5 required fields
- [ ] Priority scores are appropriate (immediate > short > long)
- [ ] Expected impacts are quantifiable
- [ ] All data points reference actual analysis data
- [ ] Recommendations are specific (not generic)
````

### Node.js/TypeScript Implementation

```typescript
async function generateReport(data: ReportData) {
  const prompt = `
# Role
You are an executive business consultant for ${data.businessType} businesses.

# Business: ${data.businessName}
# Health Score: ${data.healthScore}/100 (${data.healthGrade})
# Sentiment: ${data.positivePct}% positive, ${data.negativePct}% negative
# Trend: ${data.trend}

# SWOT Analysis
${JSON.stringify(
  {
    strengths: data.strengths,
    weaknesses: data.weaknesses,
    opportunities: data.opportunities,
  },
  null,
  2
)}

# Critical Issues
${JSON.stringify(data.criticalIssues, null, 2)}

# Theme Performance
${JSON.stringify(data.themes, null, 2)}

[Include full guidelines from above]
`;

  const response = await openai.chat.completions.create({
    model: "gpt-4o-mini",
    messages: [
      {
        role: "system",
        content:
          "You are an executive business consultant. Return only valid JSON with actionable recommendations.",
      },
      {
        role: "user",
        content: prompt,
      },
    ],
    response_format: { type: "json_object" },
    temperature: 0.6,
    max_tokens: 4000,
  });

  return JSON.parse(response.choices[0].message.content);
}
```

---

## 🔧 General Best Practices

### Temperature Settings

- **Sentiment Analysis**: 0.3 (need consistency)
- **Pattern Analysis**: 0.5 (some creativity OK)
- **Report Generation**: 0.6 (need creative writing)

### Token Limits

- **Sentiment (batch of 5)**: ~2,000 tokens
- **Pattern Analysis**: ~3,000 tokens
- **Report Generation**: ~4,000 tokens

### Error Handling

```typescript
try {
  const result = await llm_call();
  // Validate structure
  if (!result.reviews || !Array.isArray(result.reviews)) {
    throw new Error("Invalid LLM response structure");
  }
  return result;
} catch (error) {
  console.error("LLM call failed:", error);
  // Implement retry logic or fallback
  throw error;
}
```

### Cost Optimization

- Use **gpt-4o-mini** for all calls (~10x cheaper than GPT-4)
- Batch reviews (5 per call reduces costs 80%)
- Cache business type definitions
- Reuse pattern analysis when regenerating reports

---

**Next**: Read [07-NODEJS-IMPLEMENTATION.md](./07-NODEJS-IMPLEMENTATION.md) for complete implementation guide.
