# Review Analyzer System - Complete Documentation

## 📋 Table of Contents

1. **[00-OVERVIEW.md](./00-OVERVIEW.md)** - This file - System overview
2. **[01-ARCHITECTURE.md](./01-ARCHITECTURE.md)** - System architecture and data flow
3. **[02-DATA-FETCHING.md](./02-DATA-FETCHING.md)** - How data is fetched from Google Maps
4. **[03-SENTIMENT-ANALYSIS.md](./03-SENTIMENT-ANALYSIS.md)** - Sentiment analysis agent and prompts
5. **[04-PATTERN-ANALYSIS.md](./04-PATTERN-ANALYSIS.md)** - Pattern analysis agent and prompts
6. **[05-REPORT-GENERATION.md](./05-REPORT-GENERATION.md)** - Report generation agent and prompts
7. **[06-JSON-OUTPUT-STRUCTURE.md](./06-JSON-OUTPUT-STRUCTURE.md)** - Complete JSON output structure
8. **[07-NODEJS-IMPLEMENTATION.md](./07-NODEJS-IMPLEMENTATION.md)** - How to implement in Node.js
9. **[08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md)** - All LLM prompts reconstructed
10. **[09-BUSINESS-TYPES.md](./09-BUSINESS-TYPES.md)** - Business type detection and themes

---

## 🎯 What This System Does

The Review Analyzer is an AI-powered system that:

1. **Fetches** Google Maps business data and reviews
2. **Analyzes** reviews in batches using LLM (sentiment, themes, emotions)
3. **Identifies patterns** (SWOT, health score, trends, critical issues)
4. **Generates reports** with actionable recommendations

---

## 🏗️ System Components

### Core Files

```
jac-review-analysis/
├── main.jac              # Entry point, AnalyzeUrl walker
├── models.jac            # Data models, nodes, LLM objects
├── walkers.jac           # 4 agents + helper functions
└── api_walkers.jac       # API endpoints (optional)
```

### 4 Main Agents

1. **DataFetcherAgent** - Fetches place details and reviews
2. **SentimentAnalyzerAgent** - Analyzes reviews in batches of 5
3. **PatternAnalyzerAgent** - Identifies patterns, calculates health score
4. **ReportGeneratorAgent** - Creates executive report with recommendations

### Orchestrator

- **FullPipelineAgent** - Coordinates all 4 agents sequentially

---

## 🔄 Complete Data Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    1. AnalyzeUrl Walker                         │
│  Input: url, max_reviews, analysis_depth, api_key, force_mock  │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              2. FullPipelineAgent (Orchestrator)                │
│  Spawns 4 agents sequentially, collects results                │
└────────────────────────┬────────────────────────────────────────┘
                         │
     ┌───────────────────┼───────────────────┬─────────────────┐
     │                   │                   │                 │
     ▼                   ▼                   ▼                 ▼
┌─────────┐       ┌─────────────┐    ┌──────────────┐  ┌──────────────┐
│  Data   │──────▶│  Sentiment  │───▶│   Pattern    │─▶│    Report    │
│ Fetcher │       │  Analyzer   │    │   Analyzer   │  │  Generator   │
└─────────┘       └─────────────┘    └──────────────┘  └──────────────┘
     │                   │                   │                 │
     ▼                   ▼                   ▼                 ▼
  Business            Reviews            Analysis          Report
   Node              Analyzed             Node              Node
                   (sentiment,         (health,          (findings,
                    themes)             SWOT)          recommendations)
```

---

## 📊 Graph Structure

The system builds a graph of interconnected nodes:

```
Root
 │
 └── Business (place_id, name, rating, type, etc.)
      ├── Review (text, rating, sentiment, themes)
      ├── Review
      ├── Review...
      ├── Theme (name, sentiment, sub_themes)
      ├── Theme...
      ├── Analysis (health_score, SWOT, trends)
      └── Report (headline, findings, recommendations)
```

---

## 🤖 LLM Integration

The system uses **`by llm`** operator in Jac, which:

1. Automatically extracts function signature
2. Generates prompts from semantic annotations
3. Validates LLM output against defined objects
4. Handles JSON parsing and type conversion

### LLM Calls in the System

| Agent             | Function                      | LLM Call | Purpose                     |
| ----------------- | ----------------------------- | -------- | --------------------------- |
| SentimentAnalyzer | `analyze_reviews_batch()`     | Yes      | Analyze 5 reviews at once   |
| PatternAnalyzer   | `generate_pattern_analysis()` | Yes      | Generate health score, SWOT |
| ReportGenerator   | `generate_report_content()`   | Yes      | Generate executive report   |

---

## 📈 Key Features

### 1. Business Type Detection

- Detects business type from Google Maps categories
- Maps to 9 types: RESTAURANT, HOTEL, RETAIL, SALON, HEALTHCARE, ENTERTAINMENT, AUTO_SERVICE, GYM, GENERIC
- Each type has custom themes and sub-themes

### 2. Batch Sentiment Analysis

- Processes 5 reviews per LLM call (efficient)
- Extracts: sentiment, themes, sub-themes, keywords, emotion
- Uses business-type-specific theme lists

### 3. Health Score

- Overall score: 0-100
- Grade: A+ to F
- Breakdown by theme (e.g., Food Quality: 85, Service: 72)
- Confidence level based on review count

### 4. Trend Analysis

- Groups reviews by month
- Calculates sentiment trends over time
- Identifies: improving, stable, or declining

### 5. SWOT Analysis

- Strengths, Weaknesses, Opportunities, Threats
- Each with evidence count from reviews
- Generated by LLM based on pattern analysis

### 6. Critical Issues

- High/medium/low severity
- Mention count
- Suggested action for each issue

### 7. Recommendations

- Immediate (this week)
- Short-term (this month)
- Long-term (this quarter)
- Each with action, reason, impact, effort, priority score

---

## 🎨 Output JSON Structure

The final output is a comprehensive JSON with:

```json
{
  "success": true,
  "data_source": "mock" | "serpapi",
  "generated_at": "2026-01-15T...",
  "business": { ... },
  "health_score": { ... },
  "sentiment": { ... },
  "themes": [ ... ],
  "trends": { ... },
  "critical_issues": [ ... ],
  "swot": { ... },
  "recommendations": { ... },
  "executive_summary": { ... },
  "key_findings": [ ... ],
  "statistics": { ... }
}
```

See [06-JSON-OUTPUT-STRUCTURE.md](./06-JSON-OUTPUT-STRUCTURE.md) for complete structure.

---

## 🚀 Running the System

### Interactive Mode

```bash
cd jac-review-analysis
jac run main.jac
```

### API Server

```bash
jac serve main.jac
```

Then call:

```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/...",
    "max_reviews": 50,
    "analysis_depth": "deep",
    "api_key": "your_serpapi_key",
    "force_mock": false
  }'
```

---

## 🔧 Environment Variables

```bash
export SERPAPI_KEY="your_serpapi_key_here"
export OPENAI_API_KEY="your_openai_key_here"
export LLM_MODEL="gpt-4o-mini"  # or gpt-4, claude-3, etc.
```

---

## 📝 Data Sources

### Real Data (SERP API)

- **Place Details**: `https://serpapi.com/search?engine=google_maps&type=place&data_id=...`
- **Reviews**: `https://serpapi.com/search?engine=google_maps_reviews&data_id=...`

### Mock Data

- Used when no API key provided or `force_mock=true`
- 20 pre-written sample reviews with varied sentiments
- Demo business details

---

## 🎓 Key Concepts for Node.js Implementation

To replicate this in Node.js:

1. **Use OpenAI/Anthropic SDK** instead of `by llm`
2. **Build explicit prompts** using the reconstructed prompts in [08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md)
3. **Structure LLM responses** using JSON Schema or TypeScript types
4. **Store data** in PostgreSQL/MongoDB with similar node structure
5. **Implement agents** as service classes or async functions

See [07-NODEJS-IMPLEMENTATION.md](./07-NODEJS-IMPLEMENTATION.md) for detailed implementation guide.

---

## 📌 Next Steps

1. Read each documentation file in order
2. Understand the data flow and agent responsibilities
3. Study the LLM prompts to replicate behavior
4. Use the JSON structure to design your database schema
5. Follow the Node.js implementation guide

---

## 🤝 Support

For questions about:

- **Jac syntax**: See Jac documentation
- **System design**: Read architecture docs
- **Node.js implementation**: Follow implementation guide
- **LLM prompts**: Study the prompt reconstruction docs

---

**Generated**: January 15, 2026  
**Version**: 2.0 (Deep Analysis)
