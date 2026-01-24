# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a **Review Analyzer** API built with **Jaclang (JAC)** - a graph-based programming language with native AI integration. The system analyzes Google Maps reviews using a multi-agent pipeline and provides detailed business intelligence reports.

**Production API**: https://review-analysis-server.trynewways.com/

## Core Architecture

### Graph-Based Data Model

The application uses JAC's graph database paradigm:
- **Nodes** = Data entities (Business, Review, Theme, Analysis, Report, UserProfile)
- **Edges** = Relationships between nodes
- **Walkers** = Agents that traverse the graph and perform operations
- **Automatic Persistence** = Nodes connected to `root` are auto-saved

### Multi-Agent Analysis Pipeline

```
DataFetcherAgent → SentimentAnalyzerAgent → PatternAnalyzerAgent → ReportGeneratorAgent → RecommendationAgent
       │                    │                        │                      │                     │
       ▼                    ▼                        ▼                      ▼                     ▼
   Business              Reviews                 Themes               Analysis              Report
    Node               Analyzed               Created/Updated           Node                 Node
```

**Pipeline Stages:**
1. **DataFetcherAgent** (`walkers.jac:253`) - Fetches business data and reviews from SERP API
2. **SentimentAnalyzerAgent** (`walkers.jac:599`) - Analyzes sentiment, themes, keywords, emotions using LLM
3. **PatternAnalyzerAgent** (`walkers.jac:732`) - Identifies patterns, sub-themes, and metrics across reviews
4. **ReportGeneratorAgent** (`walkers.jac:1129`) - Generates comprehensive analysis report with SWOT, trends, health scores
5. **RecommendationAgent** (`walkers.jac:1255`) - Creates actionable recommendations based on analysis

### File Structure

```
jac-review-analysis/
├── main.jac              # Entry point, AnalyzeUrl walker, module imports
├── models.jac            # Node definitions, edges, enums, type mappings
├── walkers.jac           # Agent walkers (the 5-stage pipeline)
├── api_walkers.jac       # API endpoints (GetBusinesses, GetReport, GetReviews, Reanalyze, DeleteBusiness, GetStats)
├── auth_walkers.jac      # Authentication (create_user_profile, get_user_profile, update_subscription, admin operations)
├── Dockerfile            # Production deployment with jac-scale
├── docker-compose.yml    # Local development environment
└── requirements.txt      # Python dependencies (jaseci, jac, jac-byllm, jac-scale)
```

## Development Commands

### Running the Application

```bash
# Interactive mode (for testing/debugging)
jac run main.jac

# Development API server (deprecated - use jac start instead)
jac serve main.jac

# Production API server with jac-scale (recommended)
jac start main.jac --port 8000

# Compile to bytecode (required before production deployment)
jac build main.jac
```

### Docker Deployment

```bash
# Build and run with docker-compose
docker-compose up --build

# Build Docker image
docker build -t review-analyzer .

# Run container
docker run -p 8000:8000 \
  -e SERPAPI_KEY=your_key \
  -e OPENAI_API_KEY=your_key \
  -e LLM_MODEL=gpt-4o-mini \
  review-analyzer
```

### Environment Variables

Required:
- `SERPAPI_KEY` - SerpAPI key for fetching Google Maps data
- `OPENAI_API_KEY` - OpenAI API key for LLM operations
- `LLM_MODEL` - Default: `gpt-4o-mini` (can use gpt-4, gpt-4-turbo, etc.)

Optional:
- `PORT` - Server port (default: 8000)
- `DEBUG` - Enable debug mode (default: false)

## Key JAC Concepts

### Graph Traversal Syntax

```jac
# Get all connected nodes of a specific type
businesses = [root -->(`?Business)];              # All businesses from root
reviews = [business -->(`?Review)];               # All reviews from business
themes = [business -->(`?Theme)];                 # All themes from business

# Connect nodes (creates edge)
root ++> business;                                # Connect and create edge
business ++> review;                              # Connect review to business
```

### Walker Invocation

```jac
# Spawn walker on a node
spawn DataFetcherAgent(url=url, max_reviews=100) on business;

# Walker navigates to specific node types
can start with `root entry { ... }               # Entry point at root
can analyze with Business entry { ... }          # Entry point at Business nodes
```

### LLM Integration (`by llm`)

```jac
# Define LLM-powered function (no prompt engineering needed!)
obj ReviewSentiment {
    has sentiment: str;          # "positive", "negative", "neutral"
    has sentiment_score: float;  # -1.0 to 1.0
    has themes: list[str];
    has keywords: list[str];
    has emotion: str;
}

def analyze_review_sentiment(
    review_text: str,
    star_rating: int
) -> ReviewSentiment by llm();

# The `by llm` operator:
# - Automatically generates prompts from function signature
# - Handles JSON parsing and type validation
# - Returns structured output matching the return type
```

## Critical Fixes & Known Issues

### Theme Duplication on Reanalysis

**Issue**: The `Reanalyze` walker (`api_walkers.jac:367`) was creating duplicate themes.

**Fix**: Added cleanup phase at lines 395-410 to delete old Theme, Analysis, and Report nodes before re-running the analysis pipeline:

```jac
# Delete old analysis artifacts to prevent duplicates
old_themes = [target_biz -->(`?Theme)];
old_analyses = [target_biz -->(`?Analysis)];
old_reports = [target_biz -->(`?Report)];

for theme in old_themes { del theme; }
for analysis in old_analyses { del analysis; }
for report in old_reports { del report; }
```

### Review Metadata Fields

**Fields**: Each Review node stores:
- `review_link` - Direct Google Maps review URL (from SERP API `link` field)
- `author_image` - Reviewer profile image URL (from SERP API `user.thumbnail` field)

These fields are captured in `DataFetcherAgent` (`walkers.jac:526`) and returned by `GetReviews` API (`api_walkers.jac:320-321`).

## Authentication & User Management

### User Isolation

- Each authenticated user has an **isolated root node**
- UserProfile is connected to the user's root (`root --> UserProfile`)
- All businesses, reviews, analyses are scoped to that user's graph
- No username parameters needed - authentication context provides isolation

### Subscription Tiers

Defined in `models.jac:12-16`:
- **FREE**: 5 businesses, 10 analyses/day
- **PRO**: 50 businesses, 100 analyses/day
- **ENTERPRISE**: Unlimited businesses and analyses

Limits are enforced in `AnalyzeUrl` walker before running the pipeline.

## API Endpoints

When running `jac start main.jac`, the API is available at `http://localhost:8000`:

### Core Analysis
- `POST /walker/AnalyzeUrl` - Analyze a Google Maps URL (runs full pipeline)
- `POST /walker/Reanalyze` - Re-run analysis on existing business data

### Data Retrieval
- `POST /walker/GetBusinesses` - List analyzed businesses with pagination
- `POST /walker/GetReport` - Get full report for a business
- `POST /walker/GetReviews` - Get reviews with filters (sentiment, rating, date)
- `POST /walker/GetStats` - Get user statistics (total businesses, analyses today)

### User Management
- `POST /walker/create_user_profile` - Create user profile after registration
- `POST /walker/get_user_profile` - Get current user profile and limits
- `POST /walker/update_subscription` - Update subscription tier (admin)

### Utilities
- `POST /walker/DeleteBusiness` - Delete a business and all related data
- `POST /walker/health_check` - Health check endpoint

API documentation is auto-generated at `http://localhost:8000/docs` (FastAPI/Swagger UI).

## Business Type Detection

The system auto-detects business types from Google Maps categories using `BUSINESS_TYPE_MAP` (`models.jac:29-110`):

- **RESTAURANT** - Restaurants, cafes, bakeries, bars
- **HOTEL** - Hotels, resorts, lodging
- **RETAIL** - Stores, shops, supermarkets
- **SALON** - Beauty salons, spas, barber shops
- **HEALTHCARE** - Hospitals, clinics, dentists
- **ENTERTAINMENT** - Museums, theaters, amusement parks
- **AUTO_SERVICE** - Car repair, dealerships, gas stations
- **GYM** - Gyms, fitness centers
- **GENERIC** - Fallback for unmatched types

Business type determines which sub-themes are analyzed (e.g., "Food Quality" for restaurants, "Room Quality" for hotels).

## Important Notes

### Security

- **Never expose API keys in walker properties** - They get serialized in responses
- API keys should only be in environment variables or passed as walker parameters that are not part of output
- UserProfile nodes handle authentication context - no manual username passing needed

### Performance

- Reviews are cached after first fetch - use `force_refresh=True` to re-fetch
- `freshness_days` parameter controls cache validity (default: 7 days)
- Large businesses (500+ reviews) may take 2-3 minutes for full analysis due to LLM calls
- Consider pagination for `GetReviews` when dealing with businesses that have 100+ reviews

### Data Cleanup

When deleting a business (`DeleteBusiness` walker), all related nodes are deleted:
- All Review nodes
- All Theme nodes
- All Analysis nodes
- All Report nodes
- The Business node itself

This prevents orphaned data in the graph.

## PRD Documentation

Frontend PRD documents are available in `/prd-docs/`:
- 01-OVERVIEW.md - Product goals, target users
- 02-TECH-STACK.md - Vite, React, shadcn/ui stack
- 03-ARCHITECTURE.md - Frontend folder structure
- 04-API-SERVICE.md - API client implementation
- 05-AUTHENTICATION.md - JWT handling, login flows
- 06-PAGES.md - All page specifications
- 07-COMPONENTS.md - Reusable component library
- 08-REPORT-DISPLAY.md - Report visualization strategy
- 09-ADMIN-PANEL.md - Admin features
- 10-BRANDING.md - Theming and white-labeling
- 11-RESPONSIVE.md - Mobile/tablet responsive design
- 12-DEPLOYMENT.md - Build and deployment guide

The backend API is production-ready and hosted at `https://review-analysis-server.trynewways.com/`.
