# Review Analyzer POC - Jac/OSP vs NestJS Comparison

## 🎯 What This POC Demonstrates

This proof-of-concept shows how **Jac/OSP dramatically simplifies** a multi-agent review analysis system compared to the traditional NestJS + n8n approach.

### The Pipeline: URL → Fetch → Analyze → Report

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  DataFetch  │────►│  Sentiment  │────►│   Pattern   │────►│   Report    │
│   Agent     │     │   Analyzer  │     │   Analyzer  │     │  Generator  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                   │
      ▼                   ▼                   ▼                   ▼
   Business            Reviews             Analysis             Report
    Node              Analyzed              Node                 Node
                      (themes,            (SWOT,              (findings,
                     sentiment)          insights)           recommendations)
```

---

## 📊 Side-by-Side Comparison

### File Count & Lines of Code

| Metric             | NestJS + n8n | Jac/OSP    | Reduction           |
| ------------------ | ------------ | ---------- | ------------------- |
| **Files**          | 7+ files     | 3 files    | **57% fewer**       |
| **Lines of Code**  | ~400+ lines  | ~400 lines | Similar LOC but...  |
| **Boilerplate**    | ~200 lines   | ~0 lines   | **100% eliminated** |
| **Business Logic** | ~200 lines   | ~400 lines | **2x more logic**   |

### What's Eliminated in Jac

| NestJS Boilerplate                                       | Jac Equivalent                         |
| -------------------------------------------------------- | -------------------------------------- |
| `@Module()`, `@Controller()`, `@Injectable()` decorators | Not needed                             |
| DTOs with validation decorators                          | `obj` types with auto-validation       |
| BullMQ queue setup & job processors                      | Walker traversal handles orchestration |
| Supabase client setup & queries                          | Auto-persistence to root graph         |
| UUID generation, timestamps                              | Built-in, automatic                    |
| Error handling boilerplate                               | Standard try/catch, simpler            |
| Service injection & DI                                   | Direct includes                        |

### LLM Integration Comparison

**NestJS (typical pattern):**

```typescript
@Injectable()
export class AnalysisService {
  constructor(private openai: OpenAIService) {}

  async analyzeSentiment(review: string): Promise<SentimentResult> {
    const prompt = `Analyze the sentiment of this review...
    
    Review: ${review}
    
    Return JSON with:
    - sentiment: "positive" | "negative" | "neutral"
    - score: number between -1 and 1
    - themes: array of themes
    ...`;

    const response = await this.openai.chat.completions.create({
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
      response_format: { type: "json_object" },
    });

    try {
      return JSON.parse(response.choices[0].message.content);
    } catch (e) {
      throw new Error("Failed to parse LLM response");
    }
  }
}
```

**~25-30 lines per LLM call**

**Jac (with `by llm`):**

```jac
def analyze_review_sentiment(
    review_text: str,
    star_rating: int
) -> ReviewSentiment by llm();
```

**3 lines per LLM call!**

The `by llm` operator:

- Automatically extracts function name, parameters, and return type
- Generates optimal prompts from semantic information
- Handles JSON parsing and type validation
- No prompt engineering required!

---

## 🗂️ File Structure Comparison

### NestJS Structure

```
scrape-module/
├── index.ts                    # Exports
├── scrape.constants.ts         # Constants & types
├── scrape.controller.ts        # HTTP endpoints
├── scrape.dto.ts               # Data transfer objects
├── scrape.module.ts            # Module definition
├── scrape.service.ts           # Business logic
├── url-parser.service.ts       # URL parsing
├── [bull processor]            # Job processor
├── [supabase config]           # Database setup
└── [analysis service]          # AI analysis
```

**7-10 files, complex dependencies**

### Jac Structure

```
review-analyzer-poc/
├── main.jac                    # Entry point + API walkers
├── models.jac                  # Nodes, edges, types
└── walkers.jac                 # Agent walkers
```

**3 files, self-contained**

---

## 🚀 Running the POC

### Prerequisites

```bash
pip install jaclang
```

### Demo Mode (Mock Data)

```bash
cd review-analyzer-poc
jac run main.jac
```

### With Real SERP API

```bash
export SERPAPI_KEY="your_serpapi_key_here"
export OPENAI_API_KEY="your_openai_key_here"
jac run main.jac
```

```bash
curl --get https://serpapi.com/search \
 -d engine="google_maps" \
 -d type="place" \
 -d data_id="0x3ae37fae838233f3:0xf8ef06b31a14819e" \
 -d api_key="your_serpapi_key_here"
```

### As REST API

```bash
jac serve main.jac

# Then call endpoints:
# POST /walker/AnalyzeUrl
# GET /walker/GetBusinesses
# GET /walker/GetReport
# GET /walker/GetAnalysis
# POST /walker/Reanalyze
```

---

## 🔧 API Endpoints (when served)

### 1. Analyze URL (Full Pipeline)

```bash
POST /walker/AnalyzeUrl
{
    "url": "https://www.google.com/maps/place/...",
    "max_reviews": 100,
    "report_type": "executive",
    "api_key": "YOUR_SERPAPI_KEY_HERE"
}
```

### 2. List Businesses

```bash
POST /walker/GetBusinesses
{
    "limit": 10
}
```

### 3. Get Report

```bash
POST /walker/GetReport
{
    "business_id": "0x89c25a197c06b7af:0x40a06c78f79e5de6"
}
```

### 4. Get Analysis Details

```bash
POST /walker/GetAnalysis
{
    "business_id": "0x89c25a197c06b7af:0x40a06c78f79e5de6"
}
```

### 5. Get Reviews

```bash
POST /walker/GetReviews
{
    "business_id": "...",
    "limit": 20,
    "sentiment_filter": "negative"
}
```

### 6. Reanalyze Existing Data

```bash
POST /walker/Reanalyze
{
    "business_id": "...",
    "report_type": "detailed"
}
```

---

## 🧠 Key Jac/OSP Concepts Used

### 1. Nodes = Data Entities

```jac
node Business {
    has place_id: str;
    has name: str;
    has rating: float;
    # ... auto-persisted when connected to root!
}
```

### 2. Edges = Relationships

```jac
edge HasReview {}
edge HasAnalysis {}

# Creating relationship:
business ++> review;  # Simple connection
business +>:HasReview:+> review;  # Typed connection
```

### 3. Walkers = Agents

```jac
walker SentimentAnalyzerAgent {
    has business_id: str;
    has results: dict = {};

    can start with `root entry {
        visit [-->(`?Business)];  # Navigate to all businesses
    }

    can analyze with Business entry {
        reviews = [here -->(`?Review)];  # Get connected reviews
        # ... process reviews
    }
}
```

### 4. `by llm` = AI Magic

```jac
# The compiler extracts semantics to auto-generate prompts!
def analyze_sentiment(text: str) -> SentimentResult by llm();
```

### 5. Automatic Persistence

```jac
# Connect to root = auto-saved
business = root ++> Business(name="Hotel", rating=4.5);

# Data persists across runs when using `jac serve`
```

---

## 📈 What's Next?

This POC covers the core pipeline. Easy to extend:

### Add Content Generation Agent

```jac
walker ContentCreatorAgent {
    can generate with Analysis entry {
        blog = self.create_blog_post(here) by llm();
        social = self.create_social_posts(blog) by llm();
    }
}
```

### Add Competitor Analysis

```jac
walker CompetitorAnalyzer {
    has competitor_urls: list;

    can compare with Business entry {
        # Analyze multiple businesses
        # Compare metrics
    }
}
```

### Add Response Drafting

```jac
walker ResponseDrafter {
    can draft_response with Review entry {
        if here.sentiment == "negative" {
            response = self.draft_apology(here.text) by llm();
        }
    }
}
```

---

## 🎯 Summary: Why Jac/OSP for This Use Case?

| Aspect             | Benefit                                               |
| ------------------ | ----------------------------------------------------- |
| **Multi-Agent**    | Walkers naturally represent agents traversing data    |
| **AI Integration** | `by llm` eliminates prompt engineering boilerplate    |
| **Persistence**    | Auto-save to graph, no database code                  |
| **Relationships**  | Reviews, themes, analyses linked as first-class edges |
| **Orchestration**  | Walker spawning replaces job queues                   |
| **Extensibility**  | Add new agents in ~20 lines each                      |

**Bottom Line**: For AI-powered, relationship-rich applications like review analysis, Jac/OSP provides a dramatically simpler development experience while maintaining full capability.
