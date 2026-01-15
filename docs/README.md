# Review Analysis System Documentation

## 📚 Complete Documentation Set

This folder contains comprehensive documentation for the **Review Analyzer V2** system - a JAC/OSP-based review analysis system that uses AI to analyze Google Maps reviews and generate actionable business intelligence.

---

## 📖 Documentation Files

### Core Documentation

1. **[00-OVERVIEW.md](./00-OVERVIEW.md)** - Start Here!

   - System overview and architecture
   - High-level data flow
   - Key features and capabilities
   - Technology stack

2. **[01-ARCHITECTURE.md](./01-ARCHITECTURE.md)** - System Design

   - 4-agent architecture breakdown
   - Node and edge definitions
   - Graph database structure
   - Design decisions and rationale

3. **[02-DATA-FETCHING.md](./02-DATA-FETCHING.md)** - Data Collection
   - Google Maps URL parsing
   - SERP API integration
   - Business type detection
   - Mock data fallback

### AI Analysis Pipeline

4. **[03-SENTIMENT-ANALYSIS.md](./03-SENTIMENT-ANALYSIS.md)** - Sentiment Processing

   - Batch processing (5 reviews at a time)
   - Theme and sub-theme detection
   - Keyword extraction
   - Emotion analysis

5. **[04-PATTERN-ANALYSIS.md](./04-PATTERN-ANALYSIS.md)** - Pattern Detection

   - Health score calculation
   - SWOT analysis generation
   - Trend analysis
   - Critical issue identification

6. **[05-REPORT-GENERATION.md](./05-REPORT-GENERATION.md)** - Executive Reporting
   - Executive summary creation
   - Key findings extraction
   - Prioritized recommendations
   - Impact assessment

### Reference Materials

7. **[06-JSON-OUTPUT-STRUCTURE.md](./06-JSON-OUTPUT-STRUCTURE.md)** - Output Format

   - Complete TypeScript interfaces
   - All output sections documented
   - Sample JSON examples
   - Data type definitions

8. **[08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md)** - AI Prompts

   - All 3 LLM prompts reconstructed
   - Sentiment analysis prompt
   - Pattern analysis prompt
   - Report generation prompt
   - Complete guidelines and instructions

9. **[09-BUSINESS-TYPES.md](./09-BUSINESS-TYPES.md)** - Business Type System
   - 9 normalized business types
   - 97 Google Maps type mappings
   - Complete theme definitions (66 themes, 250+ sub-themes)
   - Detection logic

### Implementation Guide

10. **[07-NODEJS-IMPLEMENTATION.md](./07-NODEJS-IMPLEMENTATION.md)** - Node.js Port
    - Complete implementation guide
    - Project structure
    - Database schema (Prisma + PostgreSQL)
    - All 4 agents implemented in TypeScript
    - API endpoints
    - Step-by-step setup instructions

---

## 🎯 Purpose

This documentation enables:

✅ **Understanding** - Learn how the Jac system works  
✅ **Replication** - Build an identical system in Node.js  
✅ **Modification** - Extend or customize the system  
✅ **Integration** - Connect to the API endpoints

---

## 🚀 Quick Start Paths

### For Understanding the System

1. Read [00-OVERVIEW.md](./00-OVERVIEW.md)
2. Read [01-ARCHITECTURE.md](./01-ARCHITECTURE.md)
3. Review [08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md)

### For Building Node.js Version

1. Read [00-OVERVIEW.md](./00-OVERVIEW.md)
2. Follow [07-NODEJS-IMPLEMENTATION.md](./07-NODEJS-IMPLEMENTATION.md)
3. Reference [08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md) for prompts
4. Use [06-JSON-OUTPUT-STRUCTURE.md](./06-JSON-OUTPUT-STRUCTURE.md) for types

### For Understanding AI Processing

1. Read [03-SENTIMENT-ANALYSIS.md](./03-SENTIMENT-ANALYSIS.md)
2. Read [04-PATTERN-ANALYSIS.md](./04-PATTERN-ANALYSIS.md)
3. Read [05-REPORT-GENERATION.md](./05-REPORT-GENERATION.md)
4. Review [08-LLM-PROMPTS.md](./08-LLM-PROMPTS.md)

### For Business Type Analysis

1. Read [09-BUSINESS-TYPES.md](./09-BUSINESS-TYPES.md)
2. Review theme definitions for your business type
3. Understand sub-theme structure

---

## 📊 System at a Glance

### Input

```
Google Maps URL → System
```

### Process

```
1. DataFetcherAgent    → Fetch place details + reviews
2. SentimentAnalyzer   → Analyze sentiment (batches of 5)
3. PatternAnalyzer     → Calculate health scores + SWOT
4. ReportGenerator     → Create executive summary
```

### Output

```json
{
  "success": true,
  "business": {...},
  "health_score": {...},
  "sentiment": {...},
  "themes": [...],
  "swot": {...},
  "recommendations": {...},
  "executive_summary": {...}
}
```

---

## 🛠️ Technology Stack

### Original (Jac)

- **Language**: Jac/OSP
- **Database**: In-memory graph
- **LLM**: gpt-4o-mini via `by llm` operator
- **API**: SERP API for Google Maps data

### Node.js Implementation

- **Language**: TypeScript + Node.js
- **Database**: PostgreSQL + Prisma ORM
- **LLM**: OpenAI API (gpt-4o-mini)
- **API**: SERP API + Express.js REST API

---

## 💰 Cost Estimates

### Per Analysis (50-100 reviews)

- **SERP API**: ~$0.005 per search
- **OpenAI (gpt-4o-mini)**: ~$0.05-0.15 total
  - Sentiment batches: ~$0.02-0.05
  - Pattern analysis: ~$0.02-0.04
  - Report generation: ~$0.01-0.06

**Total**: $0.055-0.205 per business analysis

---

## 🔑 Key Features

- ✅ **Batch Processing**: 5 reviews per LLM call (80% cost reduction)
- ✅ **Business-Specific Themes**: 9 business types with specialized themes
- ✅ **Health Scoring**: 0-100 score with letter grades (A+ to F)
- ✅ **SWOT Analysis**: AI-generated strengths, weaknesses, opportunities, threats
- ✅ **Trend Detection**: Improving/declining/stable based on time series
- ✅ **Prioritized Recommendations**: Scored 0-100 by impact/urgency/effort
- ✅ **Confidence Levels**: Low/medium/high based on sample size
- ✅ **Mock Data**: Development mode without API costs

---

## 📈 Output Highlights

### Health Score

- **Range**: 0-100
- **Grade**: A+ to F
- **Breakdown**: Per-theme health scores

### Sentiment Analysis

- **Categories**: Positive, Negative, Neutral, Mixed
- **Themes**: Business-specific (e.g., "Room Quality" for hotels)
- **Sub-themes**: Detailed breakdowns (e.g., "Bed Comfort", "Cleanliness")
- **Emotions**: Joy, Anger, Frustration, Delight, etc.

### SWOT Analysis

- **Strengths**: What's working well (with evidence)
- **Weaknesses**: Areas for improvement
- **Opportunities**: Growth potential
- **Threats**: Competitive/market risks

### Recommendations

- **Immediate**: 1-2 weeks (quick wins)
- **Short-term**: 1-3 months (process improvements)
- **Long-term**: 3-12 months (strategic initiatives)
- **Prioritized**: Scored by impact, urgency, feasibility

---

## 🔍 Example Business Types

| Type          | Themes                               | Example Businesses          |
| ------------- | ------------------------------------ | --------------------------- |
| HOTEL         | Room Quality, Service, Location      | Grand Plaza Hotel, Marriott |
| RESTAURANT    | Food Quality, Service, Ambiance      | Mario's Pizzeria, Cafe 82   |
| RETAIL        | Product Quality, Customer Service    | Apple Store, Target         |
| SALON         | Service Quality, Staff, Cleanliness  | Hair & Beauty Studio        |
| HEALTHCARE    | Doctor Quality, Wait Time, Facility  | Medical Clinic, Dentist     |
| GYM           | Equipment, Classes, Cleanliness      | LA Fitness, Yoga Studio     |
| ENTERTAINMENT | Experience, Facilities, Value        | Movie Theater, Bowling      |
| AUTO_SERVICE  | Service Quality, Pricing, Timeliness | Auto Repair Shop            |
| GENERIC       | Service, Quality, Value              | Any other business          |

---

## 📞 Support & Questions

### Common Questions

**Q: Can I use this without SERP API?**  
A: Yes, set `force_mock=true` to use mock data for development.

**Q: How accurate is the business type detection?**  
A: 97 Google Maps types are mapped. Falls back to GENERIC if unknown.

**Q: What LLM models are supported?**  
A: gpt-4o-mini (default), gpt-4o, gpt-4-turbo, or any OpenAI model.

**Q: How long does analysis take?**  
A: ~30-60 seconds for 50-100 reviews (depends on LLM response time).

**Q: Can I analyze non-English reviews?**  
A: Yes, but performance may vary. Sentiment analysis works best in English.

---

## 🎓 Learning Resources

### Jac/OSP

- [Jac Documentation](https://www.jac-lang.org/)
- [OSP Documentation](https://docs.jac-lang.org/)

### Related Technologies

- [OpenAI API](https://platform.openai.com/docs)
- [SERP API](https://serpapi.com/google-maps-reviews-api)
- [Prisma ORM](https://www.prisma.io/)
- [PostgreSQL](https://www.postgresql.org/)

---

## ✅ Checklist for Node.js Implementation

Use this checklist when building the Node.js version:

- [ ] Setup Node.js + TypeScript project
- [ ] Install dependencies (Express, Prisma, OpenAI, Axios)
- [ ] Create PostgreSQL database
- [ ] Setup Prisma schema and run migrations
- [ ] Implement URL parser utility
- [ ] Create SerpApiService for data fetching
- [ ] Create OpenAIService with 3 LLM methods
- [ ] Implement DataFetcherAgent
- [ ] Implement SentimentAnalyzerAgent (batch processing)
- [ ] Implement PatternAnalyzerAgent (health score)
- [ ] Implement ReportGeneratorAgent
- [ ] Create AnalysisOrchestrator to coordinate agents
- [ ] Setup Express API routes
- [ ] Add error handling and logging
- [ ] Test with mock data
- [ ] Test with real SERP API data
- [ ] Verify JSON output matches specification
- [ ] Add database queries for retrieval
- [ ] Deploy and test end-to-end

---

## 📄 License

This documentation set is created for understanding and replicating the Review Analyzer V2 system. Refer to the original project for licensing information.

---

## 🎉 Ready to Start?

Begin with [00-OVERVIEW.md](./00-OVERVIEW.md) and follow the learning path that matches your goals!
