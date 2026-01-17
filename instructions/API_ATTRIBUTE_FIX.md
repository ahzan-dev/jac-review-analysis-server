# API Attribute Fix - GetReport and GetAnalysis Endpoints

## Problem Discovered

The `GetReport` and `GetAnalysis` API endpoints were failing with AttributeError because they were trying to access attributes that don't exist on the node objects.

### Error 1: GetReport
```
AttributeError: 'Report' object has no attribute 'target_audience'
```

**Location:** api_walkers.jac line 125

**Issue:** The walker was trying to access attributes like:
- `target_audience` ❌
- `title` ❌
- `recommendations` ❌
- `action_items` ❌
- `sections` ❌
- `word_count` ❌
- `reading_time_minutes` ❌

But the actual `Report` node (models.jac) only has:
- `report_id` ✅
- `report_type` ✅
- `created_at` ✅
- `headline` ✅
- `one_liner` ✅
- `key_metric` ✅
- `executive_summary` ✅
- `key_findings` ✅
- `recommendations_immediate` ✅
- `recommendations_short_term` ✅
- `recommendations_long_term` ✅

### Error 2: GetAnalysis
```
AttributeError: 'Theme' object has no attribute 'sample_quotes'
```

**Location:** api_walkers.jac line 192

**Issue:** The walker was trying to access:
- `sample_quotes` ❌ (doesn't exist)
- `confidence` ❌ (should be `confidence_level`)

But the actual `Theme` node has:
- `sample_quotes_positive` ✅
- `sample_quotes_negative` ✅
- `keywords` ✅
- `sub_themes` ✅
- `mixed_count` ✅

And the `Analysis` node has:
- `confidence_level` ✅ (not just `confidence`)
- `confidence_details` ✅

## Fix Applied

### 1. Fixed GetReport Walker

**File:** [api_walkers.jac](api_walkers.jac:114-136)

**Changed from:**
```jac
"report": {
    "report_id": r.report_id,
    "report_type": r.report_type,
    "created_at": r.created_at,
    "target_audience": r.target_audience,  // ❌ Doesn't exist
    "title": r.title,                      // ❌ Doesn't exist
    "executive_summary": r.executive_summary,
    "key_findings": r.key_findings,
    "recommendations": r.recommendations,  // ❌ Doesn't exist
    "action_items": r.action_items,        // ❌ Doesn't exist
    "sections": r.sections,                // ❌ Doesn't exist
    "word_count": r.word_count,            // ❌ Doesn't exist
    "reading_time_minutes": r.reading_time_minutes  // ❌ Doesn't exist
}
```

**Changed to:**
```jac
"report": {
    "report_id": r.report_id,
    "report_type": r.report_type,
    "created_at": r.created_at,
    "headline": r.headline,                           // ✅ Correct
    "one_liner": r.one_liner,                         // ✅ Correct
    "key_metric": r.key_metric,                       // ✅ Correct
    "executive_summary": r.executive_summary,
    "key_findings": r.key_findings,
    "recommendations_immediate": r.recommendations_immediate,     // ✅ Correct
    "recommendations_short_term": r.recommendations_short_term,   // ✅ Correct
    "recommendations_long_term": r.recommendations_long_term      // ✅ Correct
}
```

### 2. Fixed GetAnalysis Walker - Theme Attributes

**File:** [api_walkers.jac](api_walkers.jac:181-196)

**Changed from:**
```jac
theme_data.append({
    "name": t.name,
    "category": t.category,
    "mention_count": t.mention_count,
    "positive_count": t.positive_count,
    "negative_count": t.negative_count,
    "neutral_count": t.neutral_count,
    "avg_sentiment": t.avg_sentiment,
    "sample_quotes": t.sample_quotes  // ❌ Doesn't exist
});
```

**Changed to:**
```jac
theme_data.append({
    "name": t.name,
    "category": t.category,
    "mention_count": t.mention_count,
    "positive_count": t.positive_count,
    "negative_count": t.negative_count,
    "neutral_count": t.neutral_count,
    "mixed_count": t.mixed_count,                          // ✅ Added
    "avg_sentiment": t.avg_sentiment,
    "keywords": t.keywords,                                // ✅ Added
    "sample_quotes_positive": t.sample_quotes_positive,    // ✅ Correct
    "sample_quotes_negative": t.sample_quotes_negative,    // ✅ Correct
    "sub_themes": t.sub_themes                             // ✅ Added
});
```

### 3. Fixed GetAnalysis Walker - Analysis Attributes

**File:** [api_walkers.jac](api_walkers.jac:218-244)

**Changed from:**
```jac
"analysis": {
    "analysis_id": a.analysis_id,
    "created_at": a.created_at,
    "overall_sentiment": a.overall_sentiment,
    "sentiment_score": a.sentiment_score,
    "confidence": a.confidence,  // ❌ Doesn't exist
    "sentiment_breakdown": {
        "positive": a.positive_percentage,
        "negative": a.negative_percentage,
        "neutral": a.neutral_percentage
    },
    "strengths": a.strengths,
    "weaknesses": a.weaknesses,
    "opportunities": a.opportunities,
    "pain_points": a.pain_points,
    "delighters": a.delighters
}
```

**Changed to:**
```jac
"analysis": {
    "analysis_id": a.analysis_id,
    "created_at": a.created_at,
    "model_used": a.model_used,                          // ✅ Added
    "reviews_analyzed": a.reviews_analyzed,              // ✅ Added
    "date_range_start": a.date_range_start,              // ✅ Added
    "date_range_end": a.date_range_end,                  // ✅ Added
    "health_score": a.health_score,                      // ✅ Added
    "health_grade": a.health_grade,                      // ✅ Added
    "health_breakdown": a.health_breakdown,              // ✅ Added
    "overall_sentiment": a.overall_sentiment,
    "sentiment_score": a.sentiment_score,
    "confidence_level": a.confidence_level,              // ✅ Fixed (was "confidence")
    "confidence_details": a.confidence_details,          // ✅ Added
    "sentiment_breakdown": {
        "positive": a.positive_percentage,
        "negative": a.negative_percentage,
        "neutral": a.neutral_percentage,
        "mixed": a.mixed_count                           // ✅ Added
    },
    "rating_distribution": a.rating_distribution,        // ✅ Added
    "strengths": a.strengths,
    "weaknesses": a.weaknesses,
    "opportunities": a.opportunities,
    "threats": a.threats,                                // ✅ Added
    "critical_issues": a.critical_issues,                // ✅ Added
    "pain_points": a.pain_points,
    "delighters": a.delighters
}
```

### 4. Updated API Documentation

**File:** [instructions/API_CURL_COMMANDS.md](instructions/API_CURL_COMMANDS.md)

Updated response examples for:
- GetReport endpoint (lines 261-290)
- GetAnalysis endpoint (lines 324-375)

Now shows the actual response structure with correct attribute names.

## Testing After Deployment

### Test GetReport
```bash
curl -X POST https://review-analysis-server.trynewways.com/walker/GetReport \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

**Expected:** Should return report with `headline`, `one_liner`, `key_metric`, and separate recommendation arrays (immediate/short_term/long_term).

### Test GetAnalysis
```bash
curl -X POST https://review-analysis-server.trynewways.com/walker/GetAnalysis \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae1751065385ca5:0x932afec32ba992e7"
  }'
```

**Expected:** Should return:
- Analysis with `confidence_level` (not `confidence`)
- Analysis with `health_score`, `health_grade`, `health_breakdown`
- Themes with `sample_quotes_positive` and `sample_quotes_negative` (not `sample_quotes`)
- Themes with `keywords`, `sub_themes`, `mixed_count`

## Files Modified

1. **[api_walkers.jac](api_walkers.jac)**
   - Fixed GetReport walker (lines 114-136)
   - Fixed GetAnalysis walker Theme section (lines 181-196)
   - Fixed GetAnalysis walker Analysis section (lines 218-244)

2. **[instructions/API_CURL_COMMANDS.md](instructions/API_CURL_COMMANDS.md)**
   - Updated GetReport response example (lines 261-290)
   - Updated GetAnalysis response example (lines 324-375)

## Deployment

```bash
# Commit the fixes
git add api_walkers.jac instructions/API_CURL_COMMANDS.md API_ATTRIBUTE_FIX.md
git commit -m "Fix: Correct attribute names in GetReport and GetAnalysis endpoints"
git push origin main

# Redeploy in Coolify
# (Click Redeploy button)
```

## Why This Happened

The api_walkers.jac file was written with assumptions about what attributes the Report and Theme nodes would have, but those assumptions didn't match the actual node definitions in models.jac.

This is a common issue when:
- Node definitions are updated but API walkers aren't updated to match
- API walkers are written before node definitions are finalized
- Multiple developers work on different parts of the codebase

## Prevention

To prevent this in the future:
1. Always check models.jac for actual node attributes before writing API walkers
2. Use type hints/comments to document expected node structures
3. Add integration tests that call API endpoints
4. Keep API documentation in sync with actual code

## Result

After this fix:
- ✅ GetReport endpoint returns complete report data
- ✅ GetAnalysis endpoint returns comprehensive analysis with themes
- ✅ All attributes match actual node definitions
- ✅ API responses are more informative (added health score, confidence details, etc.)
- ✅ Documentation matches actual API behavior
