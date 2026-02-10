# Review Analyzer

AI-powered Google Maps review analysis platform built with [Jaclang (JAC)](https://github.com/Jaseci-Labs/jaseci). Analyzes business reviews using a multi-agent pipeline and generates detailed intelligence reports, AI review replies, social media posts, marketing copy, blog posts, and action plans.

**Production API**: https://review-analysis-server.trynewways.com/

## Architecture

### Multi-Agent Analysis Pipeline

```
Google Maps URL
       │
       ▼
┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
│  DataFetcher │───>│  Sentiment   │───>│   Pattern    │───>│    Report    │───>│Recommendation│
│    Agent     │    │   Analyzer   │    │   Analyzer   │    │  Generator   │    │    Agent     │
└──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘    └──────────────┘
       │                   │                   │                   │                   │
       ▼                   ▼                   ▼                   ▼                   ▼
   Business            Reviews             Themes              Analysis             Report
    Node              Analyzed          Created/Updated          Node                Node
```

1. **DataFetcherAgent** — Fetches business data and reviews from SERP API
2. **SentimentAnalyzerAgent** — Analyzes sentiment, themes, keywords, and emotions via LLM
3. **PatternAnalyzerAgent** — Identifies patterns, sub-themes, and metrics across reviews
4. **ReportGeneratorAgent** — Generates SWOT analysis, trends, and health scores
5. **RecommendationAgent** — Creates actionable recommendations

### Graph-Based Data Model

JAC uses a graph database paradigm where **nodes** are data entities, **edges** are relationships, and **walkers** are agents that traverse the graph. Nodes connected to `root` are automatically persisted. Each authenticated user has an isolated root node — all data is scoped to the user's graph.

### File Structure

```
jac-review-analysis/
├── main.jac               # Entry point, AnalyzeUrl walker, health checks
├── models.jac             # Nodes, edges, enums, LLM output objects
├── walkers.jac            # 5-stage analysis pipeline agents
├── api_walkers.jac        # Data retrieval & management API endpoints
├── auth_walkers.jac       # Authentication & user management
├── payment_walkers.jac    # Payment & subscription handling
├── credit_walkers.jac     # Credit system management
├── content_walkers.jac    # Content generation (22 walkers)
├── errors.jac             # Error helpers & validation functions
├── jac.toml               # Project configuration
├── Dockerfile             # Production container (jac-scale)
└── docker-compose.yml     # Local development environment
```

## Getting Started

### Prerequisites

- Python 3.12+
- [Jaclang](https://github.com/Jaseci-Labs/jaseci) v0.10.0+

```bash
pip install jaclang==0.10.0 jac-scale==0.1.7 byllm==0.4.18 requests python-dotenv
```

### Environment Variables

| Variable | Required | Default | Description |
|---|---|---|---|
| `SERPAPI_KEY` | Yes | — | SerpAPI key for Google Maps data |
| `OPENAI_API_KEY` | Yes | — | OpenAI API key for LLM operations |
| `LLM_MODEL` | No | `gpt-4o-mini` | OpenAI model to use |
| `JWT_SECRET` | No | `supersecretkey` | JWT signing secret |
| `JWT_EXP_DELTA_DAYS` | No | `7` | JWT token expiry in days |
| `MONGODB_URI` | No | — | MongoDB connection string |
| `REDIS_URL` | No | — | Redis connection string |
| `PORT` | No | `8000` | Server port |
| `DEBUG` | No | `false` | Enable debug mode |

### Running Locally

```bash
# Start the API server (recommended)
jac start main.jac --port 8000

# Interactive mode (for testing/debugging)
jac run main.jac

# Compile to bytecode
jac build main.jac
```

API docs are auto-generated at `http://localhost:8000/docs` (Swagger UI).

### Docker Deployment

```bash
# Build and run with docker-compose
docker-compose up --build

# Or build and run manually
docker build -t review-analyzer .
docker run -p 8000:8000 \
  -e SERPAPI_KEY=your_key \
  -e OPENAI_API_KEY=your_key \
  review-analyzer
```

## Features

### Review Analysis

Submit any Google Maps business URL and the system runs the full 5-agent pipeline: fetching reviews via SERP API, analyzing sentiment/themes/emotions per review, identifying cross-review patterns and sub-themes, generating a comprehensive report (SWOT analysis, health scores, trends), and producing prioritized recommendations. Results are cached with configurable freshness — subsequent requests for the same business skip the fetch stage and re-run analysis only. Costs **1 credit per 100 reviews**.

The system auto-detects business types from Google Maps categories (Restaurant, Hotel, Retail, Salon, Healthcare, Entertainment, Auto Service, Gym) and tailors sub-theme analysis accordingly — e.g., "Food Quality" and "Ambiance" for restaurants, "Room Quality" and "Facilities" for hotels.

### AI Review Reply Generation

Generate context-aware replies to customer reviews using LLM. Each reply considers the review text, star rating, sentiment, themes, and emotion alongside the business name, type, strengths (delighters), and known issues (pain points). Replies can be generated individually or in bulk, and regenerated with updated settings.

Configurable options:
- **Tone**: friendly, formal, casual, or friendly professional
- **Length**: short (1-2 sentences), medium (2-3), or long (3-4)
- **Personalization**: include reviewer's name, offer resolution for negative reviews, custom sign-off
- **Custom instructions**: additional LLM guidance for brand-specific phrasing

Costs **0.25 credits per reply**.

### Response Template Library

A collection of pre-built and user-created reply templates with customizable placeholders. Templates are categorized by sentiment (positive, negative, neutral, mixed) and scenario (praise, complaint, suggestion, question, etc.), and can be filtered by business type. Applying a template to a review fills placeholders using rule-based logic (reviewer name, business name, themes) — no LLM call required.

**FREE** — no credits consumed.

### Action Plan Generator

Generates a structured improvement roadmap derived from the business's review analysis data. Plans include immediate, short-term, and medium-term action items, KPIs to track, expected outcomes, and risk factors. Each plan is grounded in the business's actual health score, review count, and key issues identified during analysis.

Costs **0.5 credits per plan**.

### Social Media Post Generator

Turns customer reviews into publish-ready social media content. Every post follows a **Hook-Story-CTA** framework with platform-specific formatting (character limits, emoji counts, hashtag targets).

- **Platforms**: Twitter, Facebook, Instagram, LinkedIn, TikTok, Google Business Profile
- **Post types**: testimonial, question engagement, tips-based, milestone celebration, aggregate insight, story narrative, before/after
- **Hook styles**: auto, bold statement, curiosity, social proof, question, quote first, data point
- **A/B variants**: generate 1-3 variants per request with different hooks and angles
- **Visual suggestions**: each post includes a suggested image description and graphic type (photo, text overlay, carousel, video, reel)

Brand voice is fully configurable — brand personality traits, target audience, industry keywords, words to avoid, tone examples, and output language (supports transcreation, not just translation). A free auto-suggest endpoint analyzes existing business data to recommend smart defaults for all config fields.

Costs **0.25 credits per batch** (up to 5 posts with variants).

### Marketing Copy Generator

Generates advertising copy variants grounded in real customer review highlights. Outputs include headline, body text, and call-to-action tailored to specific ad formats: Google Search, Google Display, Facebook Ad, Instagram Ad, email subject lines, and email body. Supports up to 3 A/B variants per generation, each referencing actual customer quotes and business delighters.

Configurable brand settings: name, tagline, target audience, unique selling points, and tone (persuasive, informational, emotional, urgent).

Costs **0.25 credits per batch**.

### Blog Post Generator

Generates SEO-optimized blog posts from review analysis insights. Content types include improvement stories, customer spotlights, insights listicles, case studies, and trend analyses. Each post includes a title, meta description, slug, structured body sections with supporting data points, and SEO keywords.

Configurable writing preferences: author name, writing style (informative, storytelling, data-driven, conversational), target word count (600-2000), data visualization callouts, and SEO focus.

Costs **1.0 credits per post**.

## Credit System

Credits power all LLM-based features. They are deducted before the LLM call and automatically refunded if the operation fails.

| Feature | Cost |
|---|---|
| Full Analysis | 1 credit per 100 reviews |
| Review Reply | 0.25 credits |
| Action Plan | 0.5 credits |
| Social Media Posts | 0.25 credits per batch |
| Marketing Copy | 0.25 credits per batch |
| Blog Post | 1.0 credits |
| Response Templates | FREE |

## Credit Packages

Credits are purchased through tiered packages:

| Package | Credits | Price | Per Credit |
|---|---|---|---|
| **Bronze** | 1 | $5.00 | $5.00 |
| **Silver** | 5 | $22.00 | $4.40 |
| **Gold** | 12 | $48.00 | $4.00 |
| **Platinum** | 30 | $110.00 | $3.67 |

Higher packages offer better per-credit value. Each authenticated user has an isolated data graph — all businesses, reviews, and generated content are scoped to that user.

## Key JAC Concepts

```jac
# Nodes = Data entities (auto-persisted when connected to root)
node Business {
    has place_id: str;
    has name: str;
    has rating: float;
}

# Walkers = Agents that traverse the graph
walker SentimentAnalyzerAgent {
    can start with `root entry {
        visit [-->(`?Business)];
    }
    can analyze with Business entry {
        reviews = [here -->(`?Review)];
    }
}

# LLM integration — no prompt engineering needed
def analyze_sentiment(text: str) -> SentimentResult by llm();
```

## Tech Stack

- **Language**: [Jaclang](https://github.com/Jaseci-Labs/jaseci) v0.10.0
- **LLM**: OpenAI GPT-4o-mini (configurable)
- **Data Source**: SerpAPI (Google Maps)
- **Server**: jac-scale v0.1.7
- **Runtime**: Python 3.12

## License

Proprietary.
