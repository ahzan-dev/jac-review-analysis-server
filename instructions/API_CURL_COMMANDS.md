# Review Analyzer API - cURL Command Reference

Complete reference for all API endpoints with example curl commands.

## Base URL
```
http://localhost:8000
```

---

## 1. Health Check

**Endpoint:** `/walker/health_check`
**Description:** Check if the API service is running and healthy

### Request
```bash
curl -X POST http://localhost:8000/walker/health_check \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Response
```json
{
  "ok": true,
  "type": "response",
  "data": {
    "reports": [
      {
        "status": "healthy",
        "service": "review-analyzer",
        "version": "2.0"
      }
    ]
  }
}
```

---

## 2. Diagnostics

**Endpoint:** `/walker/diagnostics`
**Description:** Check environment variables and system configuration (useful for troubleshooting)

### Request
```bash
curl -X POST http://localhost:8000/walker/diagnostics \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Response
```json
{
  "ok": true,
  "type": "response",
  "data": {
    "reports": [
      {
        "environment": {
          "LLM_MODEL": "gpt-4o-mini",
          "DEBUG": "false",
          "PORT": "8000",
          "OPENAI_API_KEY": "****************...",
          "SERPAPI_KEY": "****************..."
        },
        "system_info": {
          "python_version": "3.12.x",
          "cwd": "/app"
        }
      }
    ]
  }
}
```

**Use Case:** Verify that environment variables are properly loaded in the container. If any show "NOT_SET", they need to be configured in your deployment environment (Coolify, Docker, etc.).

---

## 3. Analyze URL (Full Pipeline)

**Endpoint:** `/walker/AnalyzeUrl`
**Description:** Run complete analysis pipeline - fetch reviews, analyze sentiment, find patterns, generate report

### Request (Mock Data - No API Keys Required)
```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/Stumptown+Coffee/@40.7457399,-73.9882272,17z/data=!4m5!3m4!1s0x89c259a61c75684f:0x79d31adb123348d2!8m2!3d40.7457399!4d-73.9882272",
    "max_reviews": 20,
    "force_mock": true
  }'
```

### Request (Real Data - Requires API Keys)
```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/Dear+burger+cafe+and+stay/@6.0598092,80.1769212,1140m/data=!3m1!1e3!4m18!1m7!2m6!1sVacation+rentals!5m3!5m1!1s2026-02-05!11e1!6e3!3m9!1s0x3ae1751065385ca5:0x932afec32ba992e7!5m3!1s2026-02-05!4m1!1i2!8m2!3d6.059021!4d80.1798299!16s%2Fg%2F11sv7f9pwq?entry=ttu&g_ep=EgoyMDI2MDExMS4wIKXMDSoASAFQAw%3D%3D",
    "max_reviews": 20,
    "analysis_depth": "deep"
  }'
```

### Request (Deep Analysis with Custom API Key)
```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/The+Golden+Ridge+Hotel/data=!4m5!3m4!1s0x3ae381ea9eabe63d:0x22a0957d93cbbcb1!8m2!3d6.9817275!4d80.7544131",
    "max_reviews": 100,
    "analysis_depth": "deep",
    "api_key": "your-serpapi-key-here"
  }'
```

### Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `url` | string | Yes | - | Google Maps URL |
| `max_reviews` | int | No | 100 | Maximum reviews to fetch (20/50/100/200) |
| `report_type` | string | No | "deep" | Analysis depth (basic/standard/deep) |
| `api_key` | string | No | env | SERP API key (overrides env variable) |
| `force_mock` | bool | No | false | Use mock data instead of real API |

### Response Structure
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "success": true,
        "data_source": "serpapi",
        "business": {
          "name": "citizenM Paris La Defense",
          "type": "Hotel",
          "rating": 4.5,
          "total_reviews": 1500,
          "reviews_analyzed": 100
        },
        "health_score": {
          "overall": 85,
          "grade": "B+",
          "confidence": "high",
          "breakdown": {
            "Service": 88,
            "Ambiance": 82,
            "Location": 90
          }
        },
        "sentiment": {
          "distribution": {
            "positive": {"count": 72, "percentage": 72.0},
            "negative": {"count": 18, "percentage": 18.0}
          }
        },
        "themes": [...],
        "critical_issues": [...],
        "recommendations": {...},
        "executive_summary": {...}
      }
    ]
  }
}
```

---

## 3. Get Businesses

**Endpoint:** `/walker/GetBusinesses`
**Description:** List all analyzed businesses in the database

### Request (All Businesses)
```bash
curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Request (Limit Results)
```bash
curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Content-Type: application/json" \
  -d '{
    "limit": 10
  }'
```

### Request (Filter by Status)
```bash
curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Content-Type: application/json" \
  -d '{
    "limit": 20,
    "status_filter": "completed"
  }'
```

### Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `limit` | int | No | 50 | Maximum number of businesses to return |
| `status_filter` | string | No | "" | Filter by status (completed/pending/failed) |

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "count": 3,
        "businesses": [
          {
            "place_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
            "name": "citizenM Paris La Defense",
            "business_type": "Hotel",
            "rating": 4.5,
            "total_reviews": 1500,
            "reviews_analyzed": 100,
            "health_score": 85,
            "health_grade": "B+",
            "fetched_at": "2026-01-15T10:30:00"
          }
        ]
      }
    ]
  }
}
```

---

## 4. Get Report

**Endpoint:** `/walker/GetReport`
**Description:** Retrieve the generated report for a specific business

### Request
```bash
curl -X POST http://localhost:8000/walker/GetReport \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `business_id` | string | Yes | Google Maps place_id of the business |

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "success": true,
        "business": {
          "place_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
          "name": "citizenM Paris La Defense",
          "rating": 4.5
        },
        "report": {
          "report_id": "uuid-here",
          "report_type": "deep",
          "created_at": "2026-01-15T18:37:11",
          "headline": "citizenM Paris La Defense - Excellent Service, Minor Noise Issues",
          "one_liner": "High guest satisfaction with premium service but needs soundproofing",
          "key_metric": "Health Score: 85 (B+)",
          "executive_summary": "Comprehensive analysis shows...",
          "key_findings": [
            "Outstanding staff professionalism (92% positive)",
            "Excellent cleanliness standards",
            "Noise complaints in 15% of reviews"
          ],
          "recommendations_immediate": [
            {"action": "Address soundproofing", "impact": "high", "effort": "medium"}
          ],
          "recommendations_short_term": [
            {"action": "Upgrade HVAC system", "impact": "medium", "effort": "high"}
          ],
          "recommendations_long_term": [
            {"action": "Renovate rooms", "impact": "high", "effort": "high"}
          ]
        }
      }
    ]
  }
}
```

---

## 5. Get Analysis

**Endpoint:** `/walker/GetAnalysis`
**Description:** Get detailed analysis with themes, SWOT, and health breakdown

### Request
```bash
curl -X POST http://localhost:8000/walker/GetAnalysis \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `business_id` | string | Yes | Google Maps place_id |

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "success": true,
        "business": {
          "place_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
          "name": "citizenM Paris La Defense",
          "rating": 4.5,
          "total_reviews": 1245
        },
        "analysis": {
          "analysis_id": "uuid-here",
          "created_at": "2026-01-15T18:37:11",
          "model_used": "gpt-4o-mini",
          "reviews_analyzed": 100,
          "date_range_start": "2024-01-15",
          "date_range_end": "2026-01-15",
          "health_score": 85,
          "health_grade": "B+",
          "health_breakdown": {
            "Service": 88,
            "Ambiance": 82,
            "Room Quality": 80,
            "Location": 90,
            "Value": 85
          },
          "overall_sentiment": "positive",
          "sentiment_score": 0.65,
          "confidence_level": "high",
          "confidence_details": {
            "sample_size": 100,
            "rating_variance": 0.5
          },
          "sentiment_breakdown": {
            "positive": 72.0,
            "negative": 18.0,
            "neutral": 8.0,
            "mixed": 2
          },
          "rating_distribution": {
            "5": 50,
            "4": 30,
            "3": 10,
            "2": 5,
            "1": 5
          },
          "strengths": [
            {"theme": "Service", "evidence": "92% positive", "priority": "maintain"}
          ],
          "weaknesses": [
            {"theme": "Noise", "evidence": "15% complaints", "priority": "high"}
          ],
          "opportunities": [
            {"area": "Soundproofing", "potential": "Reduce complaints by 50%"}
          ],
          "threats": [
            {"issue": "Competition", "impact": "medium"}
          ],
          "critical_issues": [
            {"issue": "Noise complaints", "severity": "high", "frequency": 15}
          ],
          "pain_points": ["Noise", "Parking"],
          "delighters": ["Staff", "Cleanliness", "Location"]
        },
        "themes": [
          {
            "name": "Service",
            "category": "Quality",
            "mention_count": 85,
            "positive_count": 78,
            "negative_count": 5,
            "neutral_count": 2,
            "mixed_count": 0,
            "avg_sentiment": 0.78,
            "keywords": ["staff", "friendly", "helpful"],
            "sample_quotes_positive": [
              "Staff was incredibly helpful",
              "Best service I've experienced"
            ],
            "sample_quotes_negative": [
              "Checkout was slow"
            ],
            "sub_themes": [
              {
                "name": "Staff Friendliness",
                "mentions": 65,
                "sentiment": 0.85
              }
            ]
          }
        ]
      }
    ]
  }
}
```

---

## 6. Get Reviews

**Endpoint:** `/walker/GetReviews`
**Description:** Get reviews with filtering and sorting options

### Request (All Reviews)
```bash
curl -X POST http://localhost:8000/walker/GetReviews \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

### Request (Filter by Sentiment)
```bash
curl -X POST http://localhost:8000/walker/GetReviews \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
    "sentiment_filter": "negative",
    "limit": 20
  }'
```

### Request (Filter by Rating)
```bash
curl -X POST http://localhost:8000/walker/GetReviews \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
    "min_rating": 1,
    "max_rating": 3,
    "sort_by": "date_desc"
  }'
```

### Request (Complex Filtering)
```bash
curl -X POST http://localhost:8000/walker/GetReviews \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
    "sentiment_filter": "positive",
    "min_rating": 4,
    "max_rating": 5,
    "limit": 50,
    "sort_by": "rating_desc"
  }'
```

### Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `business_id` | string | Yes | - | Google Maps place_id |
| `limit` | int | No | 100 | Maximum reviews to return |
| `sentiment_filter` | string | No | "" | Filter by sentiment (positive/negative/neutral/mixed) |
| `min_rating` | int | No | 1 | Minimum rating (1-5) |
| `max_rating` | int | No | 5 | Maximum rating (1-5) |
| `sort_by` | string | No | "date_desc" | Sort order (date_desc/date_asc/rating_desc/rating_asc) |

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "success": true,
        "count": 18,
        "reviews": [
          {
            "review_id": "abc123",
            "author": "John D.",
            "rating": 2,
            "date": "2025-12-15",
            "text": "Room was too noisy, couldn't sleep...",
            "sentiment": "negative",
            "sentiment_score": -0.65,
            "themes": ["Room Quality", "Noise Level"],
            "keywords": ["noisy", "sleep", "disappointed"],
            "owner_response": "We apologize for the inconvenience..."
          }
        ]
      }
    ]
  }
}
```

---

## 7. Reanalyze Business

**Endpoint:** `/walker/Reanalyze`
**Description:** Re-run analysis on existing data (without fetching new reviews)

### Request (Basic Reanalysis)
```bash
curl -X POST http://localhost:8000/walker/Reanalyze \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

### Request (Force Sentiment Re-analysis)
```bash
curl -X POST http://localhost:8000/walker/Reanalyze \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7",
    "force_sentiment": true,
    "analysis_depth": "deep"
  }'
```

### Parameters
| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `business_id` | string | Yes | - | Google Maps place_id |
| `report_type` | string | No | "deep" | Analysis depth (basic/standard/deep) |
| `force_sentiment` | bool | No | false | Re-run sentiment analysis on all reviews |

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "success": true,
        "message": "Re-analysis completed",
        "reviews_reanalyzed": 100,
        "new_health_score": 87,
        "previous_health_score": 85
      }
    ]
  }
}
```

---

## 8. Delete Business

**Endpoint:** `/walker/DeleteBusiness`
**Description:** Remove a business and all related data (reviews, analysis, reports)

### Request
```bash
curl -X POST http://localhost:8000/walker/DeleteBusiness \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

### Parameters
| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `business_id` | string | Yes | Google Maps place_id to delete |

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "success": true,
        "message": "Business and all related data deleted",
        "deleted_business": "citizenM Paris La Defense",
        "deleted_reviews": 100,
        "deleted_themes": 6,
        "deleted_analysis": 1,
        "deleted_reports": 1
      }
    ]
  }
}
```

---

## 9. Get Statistics

**Endpoint:** `/walker/GetStats`
**Description:** Get system-wide statistics about all analyzed businesses

### Request
```bash
curl -X POST http://localhost:8000/walker/GetStats \
  -H "Content-Type: application/json" \
  -d '{}'
```

### Response
```json
{
  "ok": true,
  "data": {
    "reports": [
      {
        "total_businesses": 12,
        "total_reviews": 1450,
        "average_health_score": 82.5,
        "average_rating": 4.3,
        "sentiment_distribution": {
          "positive": 68.5,
          "negative": 18.2,
          "neutral": 8.3,
          "mixed": 5.0
        },
        "business_types": {
          "HOTEL": 5,
          "RESTAURANT": 4,
          "RETAIL": 2,
          "GYM": 1
        },
        "most_common_issues": [
          {"issue": "Wait times", "frequency": 45},
          {"issue": "Noise levels", "frequency": 32},
          {"issue": "Parking availability", "frequency": 28}
        ]
      }
    ]
  }
}
```

---

## Common Response Format

All endpoints return responses in this format:

```json
{
  "ok": true/false,
  "type": "response",
  "data": {
    "result": {...},
    "reports": [...]
  },
  "error": null/{"message": "..."},
  "meta": {
    "extra": {
      "http_status": 200
    }
  }
}
```

---

## Error Handling

### Error Response Structure
```json
{
  "ok": false,
  "error": {
    "message": "Business not found",
    "code": "BUSINESS_NOT_FOUND"
  },
  "data": null
}
```

### Common Error Codes

| Code | HTTP | Description |
|------|------|-------------|
| `INVALID_URL` | 400 | URL is not a valid Google Maps URL |
| `BUSINESS_NOT_FOUND` | 404 | Business ID doesn't exist in database |
| `NO_REVIEWS` | 404 | Business has no reviews |
| `NO_ANALYSIS` | 404 | Analysis not yet completed |
| `API_ERROR` | 500 | SERP API or LLM API error |
| `INVALID_PARAMS` | 400 | Missing or invalid parameters |

---

## Usage Examples

### Example 1: Complete Workflow

```bash
# Step 1: Analyze a business
BUSINESS_ID=$(curl -s -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.google.com/maps/place/...", "max_reviews": 50}' \
  | jq -r '.data.reports[0].business.place_id')

# Step 2: Get detailed analysis
curl -X POST http://localhost:8000/walker/GetAnalysis \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BUSINESS_ID\"}" \
  | jq '.data.reports[0].analysis.health_score'

# Step 3: Get negative reviews
curl -X POST http://localhost:8000/walker/GetReviews \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BUSINESS_ID\", \"sentiment_filter\": \"negative\"}" \
  | jq '.data.reports[0].reviews[] | {author, rating, text}'

# Step 4: Get recommendations
curl -X POST http://localhost:8000/walker/GetReport \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BUSINESS_ID\"}" \
  | jq '.data.reports[0].report.recommendations.immediate'
```

### Example 2: Batch Analysis

```bash
# Analyze multiple businesses
for url in "url1" "url2" "url3"; do
  curl -X POST http://localhost:8000/walker/AnalyzeUrl \
    -H "Content-Type: application/json" \
    -d "{\"url\": \"$url\", \"max_reviews\": 100}" &
done
wait

# Get summary of all
curl -X POST http://localhost:8000/walker/GetStats \
  -H "Content-Type: application/json" \
  -d '{}' | jq '.'
```

### Example 3: Save Response to File

```bash
# Analyze and save full output
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/...",
    "max_reviews": 100,
    "analysis_depth": "deep"
  }' | jq '.data.reports[0]' > analysis_output.json

# Pretty print health score
cat analysis_output.json | jq '.health_score'

# Extract critical issues
cat analysis_output.json | jq '.critical_issues'

# Get top recommendations
cat analysis_output.json | jq '.recommendations.immediate[:3]'
```

---

## Rate Limiting & Best Practices

1. **SERP API Limits**: Each analysis uses 2-5 SERP API calls depending on reviews count
2. **LLM Costs**: ~3 LLM calls per analysis (sentiment batches + pattern + report)
3. **Caching**: LLM responses are cached in `.jac/cache/` to reduce costs
4. **Concurrent Requests**: API can handle multiple concurrent analysis requests
5. **Mock Mode**: Use `force_mock: true` for testing without API costs

---

## Testing Without API Keys

For testing/development without SERP API or OpenAI keys:

```bash
# Test with mock data (20 sample reviews built-in)
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/test/@0,0",
    "force_mock": true,
    "max_reviews": 20
  }'
```

---

## Production Tips

1. **Set API Keys as Environment Variables**:
   ```bash
   export SERPAPI_KEY="your-key"
   export OPENAI_API_KEY="your-key"
   ```

2. **Use jq for Response Parsing**:
   ```bash
   # Install jq
   sudo apt install jq

   # Extract specific fields
   curl ... | jq '.data.reports[0].health_score.overall'
   ```

3. **Log Analysis Requests**:
   ```bash
   curl ... | tee analysis_log_$(date +%Y%m%d_%H%M%S).json
   ```

4. **Monitor Container Logs**:
   ```bash
   docker logs -f review-analyzer
   ```


## Login

### Request
```bash
curl -X POST http://localhost:8000/user/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "sample123",
    "password": "sample123"
  }'
```

## Register

### Request
```bash
curl -X POST http://localhost:8000/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "farhan",
    "password": "farhan123"
  }'
```

## Create_User_Profile

```bash
curl -X POST http://localhost:8000/walker/create_user_profile \
  -H "Content-Type: application/json" \
  -d '{
    "username": "sample123",
    "subscription_tier": "free"
  }'
```
## get_user_profile

```bash
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Content-Type: application/json" \
  -d '{
    "username": "sample123"
  }'
```
## create_admin

```bash
curl -X POST http://localhost:8000/walker/create_admin \
  -H "Content-Type: application/json" \
  -d '{
    "username": "sample123",
    "secret_key": "secret123"
  }'
```
## update_subscription

```bash
curl -X POST http://localhost:8000/walker/update_subscription \
  -H "Content-Type: application/json" \
  -d '{
    "target_username": "sample123",
    "new_tier": "pro",
    "admin_username": "sample123"
  }'
```

curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Authorization: Bearer 12344" \
  -H "Content-Type: application/json" \
  -d '{}'


  curl -X POST http://localhost:8000/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "ahzan",
    "password": "ahzan123"
  }'

  curl -X POST http://localhost:8000/user/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "farhan",
    "password": "farhan123"
  }'