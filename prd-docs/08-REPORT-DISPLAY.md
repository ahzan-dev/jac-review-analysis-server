# 08 - Report Display Specification

## 1. Report Display Strategy

Based on user requirements, we implement **Option D: Structured UI + Raw JSON Toggle**

### Features:
- Default: Beautiful structured UI with cards and charts
- Toggle: "View Raw JSON" for technical users
- Sections: Collapsible/expandable
- Export: PDF generation for sharing

---

## 2. Report Page Layout

```
┌─────────────────────────────────────────────────────────────────────────┐
│  ← Back to Businesses    Anantara Peace Haven Resort    [JSON] [PDF]    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  EXECUTIVE SUMMARY                                                 │ │
│  │  ┌─────────────────────────────────────────────────────────────┐  │ │
│  │  │  Health Score                                               │  │ │
│  │  │     91                    Grade: A+     Trend: ↗ Stable     │  │ │
│  │  │  ▓▓▓▓▓▓▓▓▓░                                                 │  │ │
│  │  └─────────────────────────────────────────────────────────────┘  │ │
│  │                                                                    │ │
│  │  "Enhancing Guest Experience at Anantara Resort"                   │ │
│  │  Focus on improving response times and pricing strategies.         │ │
│  │                                                                    │ │
│  │  Key Findings:                                                     │ │
│  │  • 83% of reviews are positive                                     │ │
│  │  • Staff attitude received highest praise (0.93 sentiment)         │ │
│  │  • Response times flagged as area for improvement                  │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌─────────────────────────────┐  ┌─────────────────────────────────┐  │
│  │  BUSINESS INFO              │  │  SENTIMENT DISTRIBUTION         │  │
│  │  ─────────────────────────  │  │  ─────────────────────────────  │  │
│  │  ⭐ 4.8 / 5.0               │  │  [Donut Chart]                  │  │
│  │  1,970 total reviews        │  │  ● Positive: 83%                │  │
│  │  100 analyzed               │  │  ● Neutral: 10%                 │  │
│  │                             │  │  ● Negative: 3%                 │  │
│  │  📍 Tangalle, Sri Lanka     │  │                                 │  │
│  │  🏨 Hotel, Resort hotel     │  │  Avg Score: 0.762               │  │
│  │  📞 +94 477 670 700         │  │  Confidence: High               │  │
│  └─────────────────────────────┘  └─────────────────────────────────┘  │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  THEME ANALYSIS                                      [Expand All] │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  [Service]  [Facilities]  [Room Quality]  [Food]  [Location]      │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │                                                                    │ │
│  │  Service                                             87/100       │ │
│  │  ▓▓▓▓▓▓▓▓▓░  74 mentions                                         │ │
│  │                                                                    │ │
│  │  Sub-themes:                                                       │ │
│  │  ┌─────────────────┬──────────┬───────────┬──────────────────┐   │ │
│  │  │ Staff Attitude  │ 71 ment. │ 0.93 sent │ 97% positive ✓   │   │ │
│  │  │ Response Time   │ 9 ment.  │ 0.45 sent │ 67% positive ⚠   │   │ │
│  │  └─────────────────┴──────────┴───────────┴──────────────────┘   │ │
│  │                                                                    │ │
│  │  Sample Quotes:                                                    │ │
│  │  ✓ "The staff was incredibly friendly and helpful..."             │ │
│  │  ✗ "Service took longer than expected on several occasions"       │ │
│  │                                                                    │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  RECOMMENDATIONS                                                   │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  [Immediate]  [Short-term]  [Long-term]  [Do Not]                 │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │                                                                    │ │
│  │  ┌─────────────────────────────────────────────────────────────┐  │ │
│  │  │  🔍 Monitor response times from staff                       │  │ │
│  │  │                                                             │  │ │
│  │  │  Type: Monitor  │  Risk: Low  │  Effort: Low                │  │ │
│  │  │                                                             │  │ │
│  │  │  Evidence: 2 mentions (2%) - Response times flagged         │  │ │
│  │  │  Impact: Maintain current service quality levels            │  │ │
│  │  │  Downside: Ignoring could lead to rising dissatisfaction    │  │ │
│  │  └─────────────────────────────────────────────────────────────┘  │ │
│  │                                                                    │ │
│  │  ┌─────────────────────────────────────────────────────────────┐  │ │
│  │  │  💬 Communicate dining value to guests                      │  │ │
│  │  │  ...                                                        │  │ │
│  │  └─────────────────────────────────────────────────────────────┘  │ │
│  │                                                                    │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  SWOT ANALYSIS                                                     │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  ┌──────────────────────┐  ┌──────────────────────┐               │ │
│  │  │  STRENGTHS           │  │  WEAKNESSES          │               │ │
│  │  │  • High quality      │  │  • Inefficient       │               │ │
│  │  │    service (69)      │  │    response times (2)│               │ │
│  │  │  • Outstanding       │  │  • Perceived high    │               │ │
│  │  │    food (28)         │  │    prices (1)        │               │ │
│  │  └──────────────────────┘  └──────────────────────┘               │ │
│  │  ┌──────────────────────┐  ┌──────────────────────┐               │ │
│  │  │  OPPORTUNITIES       │  │  THREATS             │               │ │
│  │  │  • Enhance response  │  │  • Competitive       │               │ │
│  │  │    time training (2) │  │    decline if issues │               │ │
│  │  │  • Adjust pricing    │  │    persist (2)       │               │ │
│  │  │    strategies (1)    │  │                      │               │ │
│  │  └──────────────────────┘  └──────────────────────┘               │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  TRENDS                                                            │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  Period: 5 months  │  Direction: Stable  │  Change: -8%           │ │
│  │                                                                    │ │
│  │  [Line Chart: Sentiment & Rating over time]                       │ │
│  │                                                                    │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  CRITICAL ISSUES                                                   │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  ⚠️ Medium: Response times from staff need improvement (2 ment.)  │ │
│  │  ⚠️ Medium: Pricing perceived as high (1 ment.)                   │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  REVIEWS                                           [View All →]   │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  Showing 5 of 100 reviews                                         │ │
│  │  [Review cards with sentiment badges]                             │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  STATISTICS                                                        │ │
│  │  ─────────────────────────────────────────────────────────────────│ │
│  │  Reviews analyzed: 100  │  Date range: Dec 2024 - Jan 2026        │ │
│  │  Avg length: 63 words   │  Response rate: 71%                     │ │
│  │                                                                    │ │
│  │  Rating Distribution:                                              │ │
│  │  ⭐⭐⭐⭐⭐  91  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓           │ │
│  │  ⭐⭐⭐⭐     4  ▓▓                                                │ │
│  │  ⭐⭐⭐       2  ▓                                                 │ │
│  │  ⭐⭐         0                                                    │ │
│  │  ⭐           3  ▓                                                 │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Report Components

### 3.1 ReportContainer
```typescript
// src/components/report/ReportContainer.tsx
import { useState } from 'react';
import { FullReport } from '@/types/report.types';
import { ExecutiveSummary } from './ExecutiveSummary';
import { BusinessInfoCard } from './BusinessInfoCard';
import { SentimentCard } from './SentimentCard';
import { ThemeAnalysis } from './ThemeAnalysis';
import { RecommendationsList } from './RecommendationsList';
import { SwotAnalysis } from './SwotAnalysis';
import { TrendsSection } from './TrendsSection';
import { CriticalIssues } from './CriticalIssues';
import { ReviewBrowser } from './ReviewBrowser';
import { StatisticsSection } from './StatisticsSection';
import { JsonViewer } from './JsonViewer';
import { Button } from '@/components/ui/button';
import { Code, FileDown } from 'lucide-react';

interface ReportContainerProps {
  report: FullReport;
  businessId: string;
}

export const ReportContainer = ({ report, businessId }: ReportContainerProps) => {
  const [showJson, setShowJson] = useState(false);

  const handleExportPdf = () => {
    // PDF export logic
  };

  if (showJson) {
    return (
      <div className="space-y-4">
        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={() => setShowJson(false)}>
            <Code className="mr-2 h-4 w-4" />
            View UI
          </Button>
          <Button onClick={handleExportPdf}>
            <FileDown className="mr-2 h-4 w-4" />
            Export PDF
          </Button>
        </div>
        <JsonViewer data={report} />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Action buttons */}
      <div className="flex justify-end gap-2">
        <Button variant="outline" onClick={() => setShowJson(true)}>
          <Code className="mr-2 h-4 w-4" />
          View JSON
        </Button>
        <Button onClick={handleExportPdf}>
          <FileDown className="mr-2 h-4 w-4" />
          Export PDF
        </Button>
      </div>

      {/* Executive Summary */}
      <ExecutiveSummary
        healthScore={report.health_score}
        summary={report.executive_summary}
        keyFindings={report.key_findings}
      />

      {/* Business Info & Sentiment */}
      <div className="grid gap-6 md:grid-cols-2">
        <BusinessInfoCard business={report.business} />
        <SentimentCard sentiment={report.sentiment} />
      </div>

      {/* Theme Analysis */}
      <ThemeAnalysis themes={report.themes} />

      {/* Recommendations */}
      <RecommendationsList recommendations={report.recommendations} />

      {/* SWOT Analysis */}
      <SwotAnalysis swot={report.swot} />

      {/* Trends */}
      <TrendsSection trends={report.trends} />

      {/* Critical Issues */}
      {report.critical_issues.length > 0 && (
        <CriticalIssues issues={report.critical_issues} />
      )}

      {/* Review Browser */}
      <ReviewBrowser businessId={businessId} limit={5} />

      {/* Statistics */}
      <StatisticsSection statistics={report.statistics} />
    </div>
  );
};
```

### 3.2 ExecutiveSummary
```typescript
// src/components/report/ExecutiveSummary.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { HealthScore, ExecutiveSummary as ExecutiveSummaryType } from '@/types/report.types';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface ExecutiveSummaryProps {
  healthScore: HealthScore;
  summary: ExecutiveSummaryType;
  keyFindings: string[];
}

const gradeColors: Record<string, string> = {
  'A+': 'bg-green-100 text-green-800',
  'A': 'bg-green-100 text-green-800',
  'A-': 'bg-green-100 text-green-800',
  'B+': 'bg-blue-100 text-blue-800',
  'B': 'bg-blue-100 text-blue-800',
  'B-': 'bg-blue-100 text-blue-800',
  'C+': 'bg-yellow-100 text-yellow-800',
  'C': 'bg-yellow-100 text-yellow-800',
  'C-': 'bg-yellow-100 text-yellow-800',
  'D': 'bg-orange-100 text-orange-800',
  'F': 'bg-red-100 text-red-800',
};

const TrendIcon = ({ trend }: { trend: string }) => {
  switch (trend) {
    case 'improving':
      return <TrendingUp className="h-5 w-5 text-green-500" />;
    case 'declining':
      return <TrendingDown className="h-5 w-5 text-red-500" />;
    default:
      return <Minus className="h-5 w-5 text-gray-400" />;
  }
};

export const ExecutiveSummary = ({
  healthScore,
  summary,
  keyFindings,
}: ExecutiveSummaryProps) => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Executive Summary</CardTitle>
      </CardHeader>
      <CardContent className="space-y-6">
        {/* Health Score */}
        <div className="flex items-center gap-6 rounded-lg bg-gray-50 p-6">
          <div className="text-center">
            <div className="text-5xl font-bold text-gray-900">
              {healthScore.overall}
            </div>
            <div className="mt-1 text-sm text-gray-500">Health Score</div>
          </div>
          <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
              <Badge className={gradeColors[healthScore.grade]}>
                Grade: {healthScore.grade}
              </Badge>
              <Badge variant="outline">
                {healthScore.confidence} confidence
              </Badge>
            </div>
            <div className="flex items-center gap-1 text-sm text-gray-600">
              <TrendIcon trend={healthScore.trend} />
              <span className="capitalize">{healthScore.trend}</span>
            </div>
          </div>

          {/* Score breakdown mini bars */}
          <div className="ml-auto hidden flex-col gap-1 lg:flex">
            {Object.entries(healthScore.breakdown).slice(0, 4).map(([key, value]) => (
              <div key={key} className="flex items-center gap-2 text-xs">
                <span className="w-20 truncate text-gray-600">{key}</span>
                <div className="h-2 w-24 rounded-full bg-gray-200">
                  <div
                    className="h-2 rounded-full bg-gray-800"
                    style={{ width: `${value}%` }}
                  />
                </div>
                <span className="w-6 text-right text-gray-600">{value}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Headline & One-liner */}
        <div>
          <h3 className="text-xl font-semibold text-gray-900">
            {summary.headline}
          </h3>
          <p className="mt-1 text-gray-600">{summary.one_liner}</p>
        </div>

        {/* Key Findings */}
        <div>
          <h4 className="mb-2 text-sm font-medium text-gray-700">Key Findings</h4>
          <ul className="space-y-1">
            {keyFindings.map((finding, index) => (
              <li key={index} className="flex items-start gap-2 text-sm text-gray-600">
                <span className="mt-1.5 h-1.5 w-1.5 flex-shrink-0 rounded-full bg-gray-400" />
                {finding}
              </li>
            ))}
          </ul>
        </div>
      </CardContent>
    </Card>
  );
};
```

### 3.3 ThemeAnalysis
```typescript
// src/components/report/ThemeAnalysis.tsx
import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import {
  Collapsible,
  CollapsibleContent,
  CollapsibleTrigger,
} from '@/components/ui/collapsible';
import { Theme } from '@/types/report.types';
import { ChevronDown, ChevronUp, Quote } from 'lucide-react';

interface ThemeAnalysisProps {
  themes: Theme[];
}

export const ThemeAnalysis = ({ themes }: ThemeAnalysisProps) => {
  const [expandedThemes, setExpandedThemes] = useState<string[]>([themes[0]?.name]);

  const toggleTheme = (themeName: string) => {
    setExpandedThemes((prev) =>
      prev.includes(themeName)
        ? prev.filter((t) => t !== themeName)
        : [...prev, themeName]
    );
  };

  const getSentimentColor = (score: number) => {
    if (score >= 0.7) return 'text-green-600';
    if (score >= 0.4) return 'text-yellow-600';
    return 'text-red-600';
  };

  const getVerdictBadge = (verdict: string) => {
    const variants: Record<string, string> = {
      excellent: 'bg-green-100 text-green-800',
      good: 'bg-blue-100 text-blue-800',
      average: 'bg-yellow-100 text-yellow-800',
      poor: 'bg-orange-100 text-orange-800',
      critical: 'bg-red-100 text-red-800',
    };
    return variants[verdict] || 'bg-gray-100 text-gray-800';
  };

  return (
    <Card>
      <CardHeader>
        <CardTitle>Theme Analysis</CardTitle>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue={themes[0]?.name}>
          <TabsList className="mb-4 flex-wrap">
            {themes.map((theme) => (
              <TabsTrigger key={theme.name} value={theme.name}>
                {theme.name}
                <span className="ml-1 text-xs text-gray-400">
                  {theme.mention_count}
                </span>
              </TabsTrigger>
            ))}
          </TabsList>

          {themes.map((theme) => (
            <TabsContent key={theme.name} value={theme.name}>
              <div className="space-y-4">
                {/* Theme header */}
                <div className="flex items-center justify-between">
                  <div>
                    <h4 className="text-lg font-medium">{theme.name}</h4>
                    <p className="text-sm text-gray-500">
                      {theme.mention_count} mentions •{' '}
                      <span className={getSentimentColor(theme.sentiment_score)}>
                        {(theme.sentiment_score * 100).toFixed(0)}% positive
                      </span>
                    </p>
                  </div>
                  <div className="text-right">
                    <div className="text-2xl font-bold">
                      {Math.round(theme.sentiment_score * 100)}
                    </div>
                    <div className="text-xs text-gray-500">score</div>
                  </div>
                </div>

                {/* Sub-themes table */}
                <div className="rounded-lg border">
                  <table className="w-full text-sm">
                    <thead className="bg-gray-50">
                      <tr>
                        <th className="px-4 py-2 text-left font-medium">Sub-theme</th>
                        <th className="px-4 py-2 text-left font-medium">Mentions</th>
                        <th className="px-4 py-2 text-left font-medium">Sentiment</th>
                        <th className="px-4 py-2 text-left font-medium">Verdict</th>
                      </tr>
                    </thead>
                    <tbody>
                      {theme.sub_themes.map((sub) => (
                        <tr key={sub.name} className="border-t">
                          <td className="px-4 py-2">{sub.name}</td>
                          <td className="px-4 py-2">{sub.mentions}</td>
                          <td className="px-4 py-2">
                            <span className={getSentimentColor(sub.sentiment)}>
                              {(sub.sentiment * 100).toFixed(0)}%
                            </span>
                          </td>
                          <td className="px-4 py-2">
                            <Badge className={getVerdictBadge(sub.verdict)}>
                              {sub.verdict}
                            </Badge>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Sample quotes */}
                <Collapsible>
                  <CollapsibleTrigger className="flex w-full items-center justify-between rounded-lg bg-gray-50 px-4 py-2 text-sm font-medium">
                    <span className="flex items-center gap-2">
                      <Quote className="h-4 w-4" />
                      Sample Quotes
                    </span>
                    <ChevronDown className="h-4 w-4" />
                  </CollapsibleTrigger>
                  <CollapsibleContent className="mt-2 space-y-2">
                    {theme.sample_quotes.positive.filter(Boolean).slice(0, 2).map((quote, i) => (
                      <div
                        key={i}
                        className="rounded-lg border-l-4 border-green-400 bg-green-50 p-3 text-sm"
                      >
                        "{quote.slice(0, 200)}..."
                      </div>
                    ))}
                    {theme.sample_quotes.negative.filter(Boolean).slice(0, 1).map((quote, i) => (
                      <div
                        key={i}
                        className="rounded-lg border-l-4 border-red-400 bg-red-50 p-3 text-sm"
                      >
                        "{quote.slice(0, 200)}..."
                      </div>
                    ))}
                  </CollapsibleContent>
                </Collapsible>
              </div>
            </TabsContent>
          ))}
        </Tabs>
      </CardContent>
    </Card>
  );
};
```

### 3.4 RecommendationsList
```typescript
// src/components/report/RecommendationsList.tsx
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Badge } from '@/components/ui/badge';
import { BrandAwareRecommendations, Recommendation } from '@/types/report.types';
import { AlertTriangle, Eye, MessageSquare, FlaskConical, Wrench, Ban } from 'lucide-react';

interface RecommendationsListProps {
  recommendations: BrandAwareRecommendations;
}

const actionTypeIcons: Record<string, React.ReactNode> = {
  monitor: <Eye className="h-4 w-4" />,
  communicate: <MessageSquare className="h-4 w-4" />,
  experiment: <FlaskConical className="h-4 w-4" />,
  change: <Wrench className="h-4 w-4" />,
};

const riskColors: Record<string, string> = {
  low: 'bg-green-100 text-green-800',
  medium: 'bg-yellow-100 text-yellow-800',
  high: 'bg-red-100 text-red-800',
};

const RecommendationCard = ({ rec }: { rec: Recommendation }) => (
  <div className="rounded-lg border p-4">
    <div className="flex items-start gap-3">
      <div className="mt-1 rounded-full bg-gray-100 p-2">
        {actionTypeIcons[rec.action_type]}
      </div>
      <div className="flex-1">
        <h4 className="font-medium text-gray-900">{rec.action}</h4>
        <p className="mt-1 text-sm text-gray-600">{rec.reason}</p>

        <div className="mt-3 flex flex-wrap gap-2">
          <Badge variant="outline" className="text-xs">
            {rec.action_type}
          </Badge>
          <Badge className={`text-xs ${riskColors[rec.risk_level]}`}>
            Risk: {rec.risk_level}
          </Badge>
          <Badge variant="outline" className="text-xs">
            Effort: {rec.effort}
          </Badge>
        </div>

        <div className="mt-3 space-y-2 text-sm">
          <div>
            <span className="font-medium text-gray-700">Evidence: </span>
            <span className="text-gray-600">
              {rec.evidence.mention_count} mentions ({rec.evidence.mention_percentage}%)
            </span>
          </div>
          <div>
            <span className="font-medium text-gray-700">Expected Impact: </span>
            <span className="text-gray-600">{rec.expected_impact}</span>
          </div>
          {rec.caution_note && (
            <div className="flex items-start gap-1 text-yellow-700">
              <AlertTriangle className="mt-0.5 h-4 w-4 flex-shrink-0" />
              <span>{rec.caution_note}</span>
            </div>
          )}
        </div>
      </div>
    </div>
  </div>
);

export const RecommendationsList = ({ recommendations }: RecommendationsListProps) => {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Recommendations</CardTitle>
        <p className="text-sm text-gray-500">
          {recommendations.issue_severity_summary}
        </p>
      </CardHeader>
      <CardContent>
        <Tabs defaultValue="immediate">
          <TabsList>
            <TabsTrigger value="immediate">
              Immediate ({recommendations.immediate.length})
            </TabsTrigger>
            <TabsTrigger value="short_term">
              Short-term ({recommendations.short_term.length})
            </TabsTrigger>
            <TabsTrigger value="long_term">
              Long-term ({recommendations.long_term.length})
            </TabsTrigger>
            <TabsTrigger value="do_not">
              Do Not ({recommendations.do_not.length})
            </TabsTrigger>
          </TabsList>

          <TabsContent value="immediate" className="mt-4 space-y-4">
            {recommendations.immediate.map((rec, i) => (
              <RecommendationCard key={i} rec={rec} />
            ))}
          </TabsContent>

          <TabsContent value="short_term" className="mt-4 space-y-4">
            {recommendations.short_term.map((rec, i) => (
              <RecommendationCard key={i} rec={rec} />
            ))}
          </TabsContent>

          <TabsContent value="long_term" className="mt-4 space-y-4">
            {recommendations.long_term.map((rec, i) => (
              <RecommendationCard key={i} rec={rec} />
            ))}
          </TabsContent>

          <TabsContent value="do_not" className="mt-4 space-y-4">
            {recommendations.do_not.map((item, i) => (
              <div key={i} className="rounded-lg border border-red-200 bg-red-50 p-4">
                <div className="flex items-start gap-3">
                  <Ban className="mt-1 h-5 w-5 text-red-500" />
                  <div>
                    <h4 className="font-medium text-gray-900">
                      {item.do_not_action}
                    </h4>
                    <p className="mt-1 text-sm text-gray-600">
                      <span className="font-medium">Area:</span> {item.area}
                    </p>
                    <p className="mt-1 text-sm text-gray-600">
                      <span className="font-medium">Why:</span> {item.rationale}
                    </p>
                    <p className="mt-1 text-sm text-gray-500">
                      Based on {item.evidence_count} reviews
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </TabsContent>
        </Tabs>

        <div className="mt-4 rounded-lg bg-gray-50 p-4">
          <h4 className="text-sm font-medium text-gray-700">
            Overall Risk Assessment
          </h4>
          <p className="mt-1 text-sm text-gray-600">
            {recommendations.overall_risk_assessment}
          </p>
        </div>
      </CardContent>
    </Card>
  );
};
```

### 3.5 JsonViewer
```typescript
// src/components/report/JsonViewer.tsx
import { useState } from 'react';
import { Card, CardContent } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Copy, Check } from 'lucide-react';

interface JsonViewerProps {
  data: unknown;
}

export const JsonViewer = ({ data }: JsonViewerProps) => {
  const [copied, setCopied] = useState(false);

  const jsonString = JSON.stringify(data, null, 2);

  const handleCopy = async () => {
    await navigator.clipboard.writeText(jsonString);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <Card>
      <CardContent className="relative p-0">
        <Button
          variant="ghost"
          size="sm"
          className="absolute right-2 top-2"
          onClick={handleCopy}
        >
          {copied ? (
            <Check className="h-4 w-4 text-green-500" />
          ) : (
            <Copy className="h-4 w-4" />
          )}
        </Button>
        <pre className="max-h-[600px] overflow-auto rounded-lg bg-gray-900 p-4 text-sm text-gray-100">
          <code>{jsonString}</code>
        </pre>
      </CardContent>
    </Card>
  );
};
```

---

## 4. PDF Export

```typescript
// src/utils/pdf-export.ts
import html2pdf from 'html2pdf.js';

export const exportReportToPdf = (elementId: string, businessName: string) => {
  const element = document.getElementById(elementId);
  if (!element) return;

  const options = {
    margin: 10,
    filename: `${businessName.replace(/\s+/g, '_')}_Report.pdf`,
    image: { type: 'jpeg', quality: 0.98 },
    html2canvas: { scale: 2 },
    jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' },
  };

  html2pdf().set(options).from(element).save();
};
```

---

## 5. Responsive Considerations

- On mobile, stack cards vertically
- Theme tabs become scrollable horizontal list
- SWOT grid becomes 2x2 on tablet, 1 column on mobile
- Collapsible sections default to collapsed on mobile
- JSON viewer shows download button instead of inline view on mobile
