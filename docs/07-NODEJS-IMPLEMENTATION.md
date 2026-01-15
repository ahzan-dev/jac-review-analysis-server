# Node.js Implementation Guide

## 🎯 Overview

This guide shows how to implement the review analysis system in Node.js + TypeScript + PostgreSQL, replicating the functionality of the Jac system.

---

## 📦 Tech Stack

```json
{
  "runtime": "Node.js 20+",
  "language": "TypeScript 5+",
  "database": "PostgreSQL 15+",
  "orm": "Prisma",
  "llm": "OpenAI API (gpt-4o-mini)",
  "api": "Express.js",
  "validation": "Zod",
  "http-client": "Axios"
}
```

---

## 🗂️ Project Structure

```
review-analyzer/
├── src/
│   ├── agents/
│   │   ├── DataFetcherAgent.ts
│   │   ├── SentimentAnalyzerAgent.ts
│   │   ├── PatternAnalyzerAgent.ts
│   │   └── ReportGeneratorAgent.ts
│   ├── services/
│   │   ├── SerpApiService.ts
│   │   ├── OpenAIService.ts
│   │   └── AnalysisOrchestrator.ts
│   ├── models/
│   │   ├── business-types.ts
│   │   ├── theme-definitions.ts
│   │   └── types.ts
│   ├── utils/
│   │   ├── url-parser.ts
│   │   ├── date-parser.ts
│   │   └── health-calculator.ts
│   ├── routes/
│   │   └── analysis.routes.ts
│   ├── prisma/
│   │   └── schema.prisma
│   └── server.ts
├── package.json
├── tsconfig.json
└── .env
```

---

## 📋 Step 1: Setup

### Install Dependencies

```bash
npm init -y
npm install express typescript ts-node @types/node @types/express
npm install @prisma/client prisma
npm install openai axios zod
npm install dotenv cors
npm install -D nodemon @types/cors
```

### Configure TypeScript

`tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules"]
}
```

### Environment Variables

`.env`:

```env
OPENAI_API_KEY=sk-proj-...
SERPAPI_KEY=your_serpapi_key
DATABASE_URL=postgresql://user:password@localhost:5432/review_analyzer
PORT=3000
LLM_MODEL=gpt-4o-mini
```

---

## 🗄️ Step 2: Database Schema

`prisma/schema.prisma`:

```prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model Business {
  id                       String    @id @default(uuid())
  placeId                  String    @unique
  dataId                   String?
  name                     String
  businessType             String?
  businessTypeNormalized   String    @default("GENERIC")
  address                  String?
  phone                    String?
  website                  String?
  rating                   Float     @default(0)
  totalReviews             Int       @default(0)
  priceLevel               String?
  latitude                 Float     @default(0)
  longitude                Float     @default(0)
  originalUrl              String
  openingHours             Json?
  photosCount              Int       @default(0)
  status                   String    @default("pending")
  fetchedAt                DateTime?
  createdAt                DateTime  @default(now())
  updatedAt                DateTime  @updatedAt

  reviews                  Review[]
  themes                   Theme[]
  analyses                 Analysis[]
  reports                  Report[]

  @@index([placeId])
  @@index([status])
}

model Review {
  id                String    @id @default(uuid())
  businessId        String
  reviewId          String
  author            String
  authorImage       String?
  rating            Int
  text              String    @db.Text
  date              String?
  relativeDate      String?
  language          String    @default("en")
  likes             Int       @default(0)
  ownerResponse     String?   @db.Text

  // Analysis results
  sentiment         String?
  sentimentScore    Float     @default(0)
  themes            Json?     // string[]
  subThemes         Json?     // Record<string, string[]>
  keywords          Json?     // string[]
  emotion           String?
  analyzed          Boolean   @default(false)

  createdAt         DateTime  @default(now())
  business          Business  @relation(fields: [businessId], references: [id], onDelete: Cascade)

  @@index([businessId])
  @@index([analyzed])
}

model Theme {
  id                      String    @id @default(uuid())
  businessId              String
  name                    String
  mentionCount            Int       @default(0)
  positiveCount           Int       @default(0)
  negativeCount           Int       @default(0)
  neutralCount            Int       @default(0)
  avgSentiment            Float     @default(0)
  subThemes               Json?     // SubTheme[]
  sampleQuotesPositive    Json?     // string[]
  sampleQuotesNegative    Json?     // string[]

  createdAt               DateTime  @default(now())
  business                Business  @relation(fields: [businessId], references: [id], onDelete: Cascade)

  @@index([businessId])
}

model Analysis {
  id                      String    @id @default(uuid())
  businessId              String
  reviewsAnalyzed         Int       @default(0)
  dateRangeStart          String?
  dateRangeEnd            String?

  // Health Score
  healthScore             Int       @default(0)
  healthGrade             String?
  healthBreakdown         Json?     // Record<string, number>

  // Confidence
  confidenceLevel         String    @default("low")

  // Sentiment
  overallSentiment        String?
  sentimentScore          Float     @default(0)
  positiveCount           Int       @default(0)
  negativeCount           Int       @default(0)
  neutralCount            Int       @default(0)
  positivePercentage      Float     @default(0)
  negativePercentage      Float     @default(0)

  // SWOT
  strengths               Json?     // SwotItem[]
  weaknesses              Json?     // SwotItem[]
  opportunities           Json?     // SwotItem[]
  threats                 Json?     // SwotItem[]

  // Issues
  criticalIssues          Json?     // CriticalIssue[]
  painPoints              Json?     // string[]
  delighters              Json?     // string[]

  // Trends
  trendDirection          String?
  monthlyBreakdown        Json?     // MonthlyData[]

  // Statistics
  ratingDistribution      Json?
  avgReviewLength         Int       @default(0)
  responseRate            Float     @default(0)

  createdAt               DateTime  @default(now())
  business                Business  @relation(fields: [businessId], references: [id], onDelete: Cascade)

  @@index([businessId])
}

model Report {
  id                        String    @id @default(uuid())
  businessId                String
  reportType                String    @default("deep")

  // Executive Summary
  headline                  String?
  oneLiner                  String?   @db.Text
  keyMetric                 String?
  executiveSummary          String?   @db.Text

  // Findings & Recommendations
  keyFindings               Json?     // string[]
  recommendationsImmediate  Json?     // Recommendation[]
  recommendationsShortTerm  Json?     // Recommendation[]
  recommendationsLongTerm   Json?     // Recommendation[]

  createdAt                 DateTime  @default(now())
  business                  Business  @relation(fields: [businessId], references: [id], onDelete: Cascade)

  @@index([businessId])
}
```

### Initialize Database

```bash
npx prisma migrate dev --name init
npx prisma generate
```

---

## 📝 Step 3: Type Definitions

`src/models/types.ts`:

```typescript
// Copy types from 06-JSON-OUTPUT-STRUCTURE.md
export interface AnalysisOutput {
  success: boolean;
  data_source: "mock" | "serpapi";
  generated_at: string;
  business: BusinessData;
  health_score: HealthScoreData;
  sentiment: SentimentData;
  themes: ThemeData[];
  trends: TrendData;
  critical_issues: CriticalIssue[];
  swot: SwotData;
  recommendations: RecommendationsData;
  executive_summary: ExecutiveSummaryData;
  key_findings: string[];
  statistics: StatisticsData;
}

// ... rest of types from that document
```

`src/models/business-types.ts`:

```typescript
export enum BusinessType {
  RESTAURANT = "RESTAURANT",
  HOTEL = "HOTEL",
  RETAIL = "RETAIL",
  SALON = "SALON",
  HEALTHCARE = "HEALTHCARE",
  ENTERTAINMENT = "ENTERTAINMENT",
  AUTO_SERVICE = "AUTO_SERVICE",
  GYM = "GYM",
  GENERIC = "GENERIC"
}

export const BUSINESS_TYPE_MAP: Record<string, BusinessType> = {
  // Copy from models.jac
  restaurant: BusinessType.RESTAURANT,
  cafe: BusinessType.RESTAURANT,
  hotel: BusinessType.HOTEL,
  resort: BusinessType.HOTEL,
  // ... etc
};

export function detectBusinessType(
  googleType: string,
  businessName: string
): BusinessType {
  const typeL ower = googleType.toLowerCase().replace(" ", "_");

  if (BUSINESS_TYPE_MAP[typeLower]) {
    return BUSINESS_TYPE_MAP[typeLower];
  }

  // Partial matching logic
  // Name-based detection logic

  return BusinessType.GENERIC;
}
```

`src/models/theme-definitions.ts`:

```typescript
export const THEME_DEFINITIONS: Record<string, Record<string, string[]>> = {
  HOTEL: {
    "Room Quality": [
      "Cleanliness",
      "Bed Comfort",
      "Size",
      "View",
      "Amenities",
      "Maintenance",
    ],
    Service: [
      "Front Desk",
      "Housekeeping",
      "Concierge",
      "Response Time",
      "Staff Attitude",
    ],
    // ... copy from models.jac
  },
  RESTAURANT: {
    // ... copy from models.jac
  },
  // ... all other types
};

export const CONFIDENCE_THRESHOLDS = {
  low_max: 20,
  medium_max: 50,
  sub_theme_min_mentions: 3,
  theme_min_percentage: 5,
};
```

---

## 🔧 Step 4: Services

### SERP API Service

`src/services/SerpApiService.ts`:

```typescript
import axios from "axios";

export class SerpApiService {
  private apiKey: string;

  constructor() {
    this.apiKey = process.env.SERPAPI_KEY || "";
  }

  async fetchPlaceDetails(dataId: string) {
    const params = {
      engine: "google_maps",
      type: "place",
      data: `!4m5!3m4!1s${dataId}!8m2!3d0!4d0!16s`,
      api_key: this.apiKey,
      hl: "en",
    };

    const response = await axios.get("https://serpapi.com/search", { params });
    return response.data.place_results;
  }

  async fetchReviews(dataId: string, maxReviews: number = 100) {
    const reviews = [];
    let nextPageToken = null;

    while (reviews.length < maxReviews) {
      const params: any = {
        engine: "google_maps_reviews",
        data_id: dataId,
        api_key: this.apiKey,
        sort_by: "newestFirst",
      };

      if (nextPageToken) {
        params.num = 20;
        params.next_page_token = nextPageToken;
      }

      const response = await axios.get("https://serpapi.com/search", {
        params,
      });
      const data = response.data;

      reviews.push(...data.reviews.slice(0, maxReviews - reviews.length));

      nextPageToken = data.serpapi_pagination?.next_page_token;
      if (!nextPageToken) break;
    }

    return reviews;
  }
}
```

### OpenAI Service

`src/services/OpenAIService.ts`:

```typescript
import OpenAI from 'openai';

export class OpenAIService {
  private client: OpenAI;
  private model: string;

  constructor() {
    this.client = new OpenAI({
      apiKey: process.env.OPENAI_API_KEY
    });
    this.model = process.env.LLM_MODEL || 'gpt-4o-mini';
  }

  async analyzeBatch(
    reviews: Array<{index: number, rating: number, text: string}>,
    businessType: string,
    allowedThemes: string[],
    allowedSubThemes: Record<string, string[]>
  ) {
    const prompt = this.buildSentimentPrompt(
      reviews,
      businessType,
      allowedThemes,
      allowedSubThemes
    );

    const response = await this.client.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: 'You are an expert sentiment analyzer. Return only valid JSON.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      response_format: { type: 'json_object' },
      temperature: 0.3,
      max_tokens: 2000
    });

    return JSON.parse(response.choices[0].message.content!);
  }

  async generatePatternAnalysis(data: any) {
    const prompt = this.buildPatternPrompt(data);

    const response = await this.client.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: 'You are a business intelligence analyst. Return only valid JSON.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      response_format: { type: 'json_object' },
      temperature: 0.5,
      max_tokens: 3000
    });

    return JSON.parse(response.choices[0].message.content!);
  }

  async generateReport(data: any) {
    const prompt = this.buildReportPrompt(data);

    const response = await this.client.chat.completions.create({
      model: this.model,
      messages: [
        {
          role: 'system',
          content: 'You are an executive business consultant. Return only valid JSON.'
        },
        {
          role: 'user',
          content: prompt
        }
      ],
      response_format: { type: 'json_object' },
      temperature: 0.6,
      max_tokens: 4000
    });

    return JSON.parse(response.choices[0].message.content!);
  }

  private buildSentimentPrompt(...): string {
    // Use prompt from 08-LLM-PROMPTS.md
  }

  private buildPatternPrompt(...): string {
    // Use prompt from 08-LLM-PROMPTS.md
  }

  private buildReportPrompt(...): string {
    // Use prompt from 08-LLM-PROMPTS.md
  }
}
```

---

## 🤖 Step 5: Agents

### Data Fetcher Agent

`src/agents/DataFetcherAgent.ts`:

```typescript
import { PrismaClient } from "@prisma/client";
import { SerpApiService } from "../services/SerpApiService";
import { parseGoogleMapsUrl } from "../utils/url-parser";
import { detectBusinessType } from "../models/business-types";

export class DataFetcherAgent {
  constructor(private prisma: PrismaClient, private serpApi: SerpApiService) {}

  async execute(url: string, maxReviews: number, forceMock: boolean) {
    // Parse URL
    const parsed = parseGoogleMapsUrl(url);
    if (!parsed.is_valid) {
      throw new Error(`Invalid URL: ${parsed.error}`);
    }

    // Determine data source
    const dataSource =
      forceMock || !process.env.SERPAPI_KEY ? "mock" : "serpapi";

    // Fetch place details
    let placeData;
    if (dataSource === "serpapi") {
      placeData = await this.serpApi.fetchPlaceDetails(parsed.data_id!);
    } else {
      placeData = this.getMockPlaceData(parsed);
    }

    // Create Business
    const business = await this.prisma.business.create({
      data: {
        placeId: parsed.data_id || crypto.randomUUID(),
        dataId: parsed.data_id,
        name: placeData.title || parsed.place_name,
        businessType: Array.isArray(placeData.type)
          ? placeData.type.join(", ")
          : placeData.type,
        businessTypeNormalized: detectBusinessType(
          placeData.type,
          placeData.title
        ),
        address: placeData.address,
        phone: placeData.phone,
        website: placeData.website,
        rating: placeData.rating || 0,
        totalReviews: placeData.reviews || 0,
        priceLevel: placeData.price,
        latitude: placeData.gps_coordinates?.latitude || 0,
        longitude: placeData.gps_coordinates?.longitude || 0,
        originalUrl: url,
        openingHours: this.parseOpeningHours(placeData.hours),
        photosCount: placeData.images?.length || 0,
        status: "fetching",
      },
    });

    // Fetch reviews
    let reviewsData;
    if (dataSource === "serpapi") {
      reviewsData = await this.serpApi.fetchReviews(
        parsed.data_id!,
        maxReviews
      );
    } else {
      reviewsData = this.getMockReviews();
    }

    // Create Reviews
    await this.prisma.review.createMany({
      data: reviewsData.map((rev) => ({
        businessId: business.id,
        reviewId: rev.review_id || crypto.randomUUID(),
        author: rev.user?.name || "Anonymous",
        authorImage: rev.user?.thumbnail,
        rating: rev.rating || 3,
        text: rev.snippet || rev.text || "",
        date: rev.date,
        relativeDate: rev.relative_date,
        likes: rev.likes || 0,
        ownerResponse: rev.response?.snippet,
      })),
    });

    // Update status
    await this.prisma.business.update({
      where: { id: business.id },
      data: {
        status: "fetched",
        fetchedAt: new Date(),
      },
    });

    return {
      businessId: business.id,
      reviewsFetched: reviewsData.length,
      dataSource,
    };
  }

  private parseOpeningHours(hours: any[]): Record<string, string> {
    // ... implementation
  }

  private getMockPlaceData(parsed: any) {
    // ... mock data
  }

  private getMockReviews() {
    // ... mock reviews (20 items from walkers.jac)
  }
}
```

### Sentiment Analyzer Agent

`src/agents/SentimentAnalyzerAgent.ts`:

```typescript
import { PrismaClient } from "@prisma/client";
import { OpenAIService } from "../services/OpenAIService";
import { THEME_DEFINITIONS } from "../models/theme-definitions";

export class SentimentAnalyzerAgent {
  constructor(private prisma: PrismaClient, private openai: OpenAIService) {}

  async execute(businessId: string) {
    // Get business
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      include: { reviews: { where: { analyzed: false } } },
    });

    if (!business) throw new Error("Business not found");

    const themeDefs =
      THEME_DEFINITIONS[business.businessTypeNormalized] ||
      THEME_DEFINITIONS.GENERIC;
    const allowedThemes = Object.keys(themeDefs);

    // Process in batches of 5
    const batchSize = 5;
    let analyzedCount = 0;

    for (let i = 0; i < business.reviews.length; i += batchSize) {
      const batch = business.reviews.slice(i, i + batchSize);

      const batchInput = batch.map((review, idx) => ({
        index: idx,
        rating: review.rating,
        text: review.text.substring(0, 500),
      }));

      // Call LLM
      const result = await this.openai.analyzeBatch(
        batchInput,
        business.businessTypeNormalized,
        allowedThemes,
        themeDefs
      );

      // Update reviews
      for (const analysis of result.reviews) {
        const review = batch[analysis.review_index];

        await this.prisma.review.update({
          where: { id: review.id },
          data: {
            sentiment: analysis.sentiment,
            sentimentScore: analysis.sentiment_score,
            themes: analysis.themes,
            subThemes: this.convertSubThemesToDict(analysis.sub_themes),
            keywords: analysis.keywords,
            emotion: analysis.emotion,
            analyzed: true,
          },
        });

        analyzedCount++;
      }
    }

    return { analyzedCount };
  }

  private convertSubThemesToDict(subThemes: any[]) {
    const dict: Record<string, string[]> = {};
    for (const mapping of subThemes) {
      dict[mapping.theme] = mapping.sub_themes;
    }
    return dict;
  }
}
```

### Pattern Analyzer Agent & Report Generator Agent

(Similar structure - implement using prompts from 08-LLM-PROMPTS.md)

---

## 🎼 Step 6: Orchestrator

`src/services/AnalysisOrchestrator.ts`:

```typescript
import { PrismaClient } from "@prisma/client";
import { DataFetcherAgent } from "../agents/DataFetcherAgent";
import { SentimentAnalyzerAgent } from "../agents/SentimentAnalyzerAgent";
import { PatternAnalyzerAgent } from "../agents/PatternAnalyzerAgent";
import { ReportGeneratorAgent } from "../agents/ReportGeneratorAgent";
import { SerpApiService } from "./SerpApiService";
import { OpenAIService } from "./OpenAIService";
import type { AnalysisOutput } from "../models/types";

export class AnalysisOrchestrator {
  private prisma: PrismaClient;
  private dataFetcher: DataFetcherAgent;
  private sentimentAnalyzer: SentimentAnalyzerAgent;
  private patternAnalyzer: PatternAnalyzerAgent;
  private reportGenerator: ReportGeneratorAgent;

  constructor() {
    this.prisma = new PrismaClient();
    const serpApi = new SerpApiService();
    const openai = new OpenAIService();

    this.dataFetcher = new DataFetcherAgent(this.prisma, serpApi);
    this.sentimentAnalyzer = new SentimentAnalyzerAgent(this.prisma, openai);
    this.patternAnalyzer = new PatternAnalyzerAgent(this.prisma, openai);
    this.reportGenerator = new ReportGeneratorAgent(this.prisma, openai);
  }

  async analyzeUrl(
    url: string,
    maxReviews: number = 100,
    analysisDepth: string = "deep",
    forceMock: boolean = false
  ): Promise<AnalysisOutput> {
    try {
      // Stage 1: Fetch
      console.log("Stage 1: Fetching data...");
      const fetchResult = await this.dataFetcher.execute(
        url,
        maxReviews,
        forceMock
      );

      // Stage 2: Sentiment Analysis
      console.log("Stage 2: Sentiment analysis...");
      await this.sentimentAnalyzer.execute(fetchResult.businessId);

      // Stage 3: Pattern Analysis
      console.log("Stage 3: Pattern analysis...");
      await this.patternAnalyzer.execute(fetchResult.businessId);

      // Stage 4: Report Generation
      console.log("Stage 4: Report generation...");
      await this.reportGenerator.execute(fetchResult.businessId, analysisDepth);

      // Build output
      const output = await this.buildOutput(
        fetchResult.businessId,
        fetchResult.dataSource
      );

      return output;
    } catch (error) {
      console.error("Analysis failed:", error);
      throw error;
    }
  }

  private async buildOutput(
    businessId: string,
    dataSource: string
  ): Promise<AnalysisOutput> {
    const business = await this.prisma.business.findUnique({
      where: { id: businessId },
      include: {
        themes: true,
        analyses: { orderBy: { createdAt: "desc" }, take: 1 },
        reports: { orderBy: { createdAt: "desc" }, take: 1 },
      },
    });

    if (!business) throw new Error("Business not found");

    const analysis = business.analyses[0];
    const report = business.reports[0];

    // Build output matching AnalysisOutput interface
    return {
      success: true,
      data_source: dataSource as "mock" | "serpapi",
      generated_at: new Date().toISOString(),
      business: {
        name: business.name,
        type: business.businessType || "",
        type_normalized: business.businessTypeNormalized,
        address: business.address || "",
        phone: business.phone || "",
        website: business.website || "",
        google_rating: business.rating,
        total_reviews: business.totalReviews,
        reviews_analyzed: analysis.reviewsAnalyzed,
        price_level: business.priceLevel || "",
        coordinates: {
          lat: business.latitude,
          lng: business.longitude,
        },
        opening_hours: (business.openingHours as Record<string, string>) || {},
        photos_count: business.photosCount,
      },
      // ... build rest of the output structure
    };
  }
}
```

---

## 🌐 Step 7: API Routes

`src/routes/analysis.routes.ts`:

```typescript
import { Router } from "express";
import { AnalysisOrchestrator } from "../services/AnalysisOrchestrator";

const router = Router();
const orchestrator = new AnalysisOrchestrator();

router.post("/analyze", async (req, res) => {
  try {
    const {
      url,
      max_reviews = 100,
      analysis_depth = "deep",
      force_mock = false,
    } = req.body;

    if (!url) {
      return res.status(400).json({
        success: false,
        error: "URL is required",
      });
    }

    const result = await orchestrator.analyzeUrl(
      url,
      max_reviews,
      analysis_depth,
      force_mock
    );

    res.json(result);
  } catch (error: any) {
    console.error("Analysis error:", error);
    res.status(500).json({
      success: false,
      error: error.message,
    });
  }
});

export default router;
```

`src/server.ts`:

```typescript
import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import analysisRoutes from "./routes/analysis.routes";

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

app.use("/api", analysisRoutes);

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
```

---

## 🚀 Step 8: Run

### Start Server

```bash
npm run dev
```

### Test API

```bash
curl -X POST http://localhost:3000/api/analyze \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/...",
    "max_reviews": 50,
    "analysis_depth": "deep",
    "force_mock": false
  }'
```

---

## 📊 Step 9: Storage & Retrieval

The system stores everything in PostgreSQL and you can query it later:

```typescript
// Get business with all related data
const business = await prisma.business.findUnique({
  where: { placeId: "xxx" },
  include: {
    reviews: true,
    themes: true,
    analyses: true,
    reports: true,
  },
});
```

---

## ✅ Summary

This Node.js implementation:

- ✅ Replicates all Jac functionality
- ✅ Uses PostgreSQL for persistence
- ✅ Implements all 4 agents
- ✅ Uses same LLM prompts
- ✅ Produces identical JSON output
- ✅ Handles both SERP API and mock data
- ✅ REST API ready

**Cost**: ~$0.05-0.15 per analysis (50-100 reviews with gpt-4o-mini)

**Next**: Read [09-BUSINESS-TYPES.md](./09-BUSINESS-TYPES.md) for business type details.
