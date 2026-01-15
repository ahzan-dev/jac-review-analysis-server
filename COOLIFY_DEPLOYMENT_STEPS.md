# Coolify Deployment Steps - Quick Reference

## Current Issue

Your logs show:
- ✅ Server starts successfully
- ✅ SERP API works (fetches reviews)
- ❌ Sentiment analysis fails with "Provider List" error
- ❌ LLM model not properly configured

## Root Cause

**Environment variables are not being passed from Coolify to the container.**

The `.env` file is only for local development. When deploying with Coolify, you must set environment variables in Coolify's dashboard.

## Fix Steps

### 1. Commit and Push Updated Code

```bash
git add main.jac docker-compose.yml API_CURL_COMMANDS.md COOLIFY_FIX.md COOLIFY_DEPLOYMENT_STEPS.md
git commit -m "Add diagnostics endpoint and fix cache persistence"
git push origin main
```

### 2. Set Environment Variables in Coolify

1. **Open Coolify Dashboard**
2. **Navigate to your `review-analyzer` service**
3. **Go to "Environment" or "Environment Variables" section**
4. **Add ALL these variables:**

```
OPENAI_API_KEY=**************
SERPAPI_KEY=************************
LLM_MODEL=gpt-4o-mini
DEBUG=false
PORT=8000
```

5. **Click "Save" or "Update"**

### 3. Redeploy in Coolify

1. **Click "Redeploy" or "Deploy" button**
2. **Wait for deployment to complete** (~2-3 minutes)
3. **Check logs** to ensure server starts without errors

### 4. Verify Environment Variables

Test the new diagnostics endpoint:

```bash
curl -X POST https://review-analysis-server.trynewways.com/walker/diagnostics \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected output:**
```json
{
  "environment": {
    "LLM_MODEL": "gpt-4o-mini",
    "DEBUG": "false",
    "PORT": "8000",
    "OPENAI_API_KEY": "**************...",
    "SERPAPI_KEY": "******************************..."
  }
}
```

**If you see "NOT_SET"** → Environment variables are missing in Coolify. Go back to Step 2.

### 5. Test the Analysis API

Once diagnostics confirm env vars are loaded:

```bash
curl -X POST https://review-analysis-server.trynewways.com/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/Dear+burger+cafe+and+stay/@6.0590263,80.177255,1140m/data=!3m2!1e3!4b1!4m6!3m5!1s0x3ae1751065385ca5:0x932afec32ba992e7!8m2!3d6.059021!4d80.1798299!16s%2Fg%2F11sv7f9pwq",
    "max_reviews": 20,
    "analysis_depth": "deep"
  }'
```

**Expected:** Should complete full analysis without "Provider List" error.

## Troubleshooting

### Still seeing "Provider List" error?

1. **Check Coolify logs:**
   - Look for environment variable values during startup
   - Should NOT see "NOT_SET" or "false" for LLM_MODEL

2. **Verify environment variables in Coolify:**
   - Make sure they're set in the **service settings**, not just in a file
   - Some Coolify versions require variables in specific sections

3. **Check for typos:**
   - `LLM_MODEL` not `LLM-MODEL` or `LLMMODEL`
   - Exact case matters

4. **Clear any persistent volumes:**
   - In Coolify, check if there are any persistent volumes
   - Delete `.jac` volume if it exists

### Health check works but analysis fails?

This means:
- ✅ Server is running
- ✅ Container is healthy
- ❌ Environment variables not loaded for LLM

→ Go back to Step 2 and verify environment variables in Coolify

## Key Points

1. **`.env` file is NOT used in Docker/Coolify** - it's for local development only
2. **Environment variables MUST be set in Coolify's dashboard**
3. **The diagnostics endpoint will confirm if env vars are loaded**
4. **After setting env vars, you MUST redeploy** (restart is not enough)

## Files Changed

1. **main.jac** - Added `diagnostics` walker
2. **docker-compose.yml** - Removed `.jac` cache persistence
3. **API_CURL_COMMANDS.md** - Added diagnostics endpoint documentation
4. **COOLIFY_FIX.md** - Detailed fix explanation
5. **COOLIFY_DEPLOYMENT_STEPS.md** - This file (quick reference)

## Next Steps After Fix

Once the API is working:

1. Test with a real Google Maps URL
2. Check the full analysis output
3. Verify health score calculation
4. Test other API endpoints (GetBusinesses, GetReport, etc.)

## Support

If you still encounter issues after following these steps:

1. Share the output of the diagnostics endpoint
2. Share relevant Coolify logs
3. Verify your Coolify version supports environment variables

The diagnostics endpoint will immediately show if environment variables are the problem.
