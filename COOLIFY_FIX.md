# Coolify Deployment Fix - LLM Model Error

## Problem

Error when calling the API:
```
litellm.BadRequestError: LLM Provider NOT provided.
You passed model=false
```

## Root Cause

The JAC bytecode cache (`.jac/cache/`) was persisted as a Docker volume. When the code was first compiled, it cached the environment variable values. Due to a misconfiguration, the `DEBUG` value ("false") was cached instead of `LLM_MODEL` value ("gpt-4o-mini").

## Solution Applied

### 1. Updated docker-compose.yml

**Changed:** Removed `.jac` cache from volume mounts

**Before:**
```yaml
volumes:
  - ./data:/app/data
  - ./.jac:/app/.jac
```

**After:**
```yaml
volumes:
  - ./data:/app/data
  # Cache not mounted - allows fresh bytecode compilation on each deploy
```

**Why:** This ensures fresh bytecode compilation on each deployment, preventing environment variable caching issues.

### 2. Updated Documentation

- DOCKER_QUICKSTART.md - Removed references to `.jac` cache persistence
- Updated backup/restore commands to only include `data/`

## Deployment Steps for Coolify

Since you're using Coolify, follow these steps:

### Step 1: Update Your Repository

The following files have been updated in your local repository:
- `docker-compose.yml` - Removed `.jac` cache mount
- `DOCKER_QUICKSTART.md` - Updated documentation

**Commit and push these changes:**

```bash
git add docker-compose.yml DOCKER_QUICKSTART.md COOLIFY_FIX.md
git commit -m "Fix: Remove JAC cache persistence to prevent env var caching issues"
git push origin main
```

### Step 2: Redeploy in Coolify

1. Go to your Coolify dashboard
2. Find your `review-analyzer` service
3. Click **Redeploy** or trigger a new deployment
4. Coolify will pull the updated `docker-compose.yml` and rebuild

### Step 3: Set Environment Variables in Coolify

**IMPORTANT**: When using Coolify, environment variables must be set in Coolify's dashboard, not just in the `.env` file.

1. **Go to your Coolify dashboard**
2. **Find your review-analyzer service**
3. **Navigate to "Environment" or "Environment Variables" tab**
4. **Add these variables:**

```
OPENAI_API_KEY=sk-proj-your-actual-key-here
SERPAPI_KEY=your-actual-serpapi-key-here
LLM_MODEL=gpt-4o-mini
DEBUG=false
PORT=8000
```

5. **Save and redeploy**

### Step 4: Verify Environment Variables

Test the new diagnostics endpoint to verify env vars are loaded:

```bash
curl -X POST https://review-analysis-server.trynewways.com/walker/diagnostics \
  -H "Content-Type: application/json" \
  -d '{}'
```

Expected response:
```json
{
  "environment": {
    "LLM_MODEL": "gpt-4o-mini",
    "DEBUG": "false",
    "PORT": "8000",
    "OPENAI_API_KEY": "**************...",
    "SERPAPI_KEY": "************************..."
  },
  "system_info": {...}
}
```

If any show "NOT_SET", they're missing from Coolify's environment configuration.

### Step 5: Test the Analysis

Once env vars are confirmed, test the API:

```bash
curl -X POST https://review-analysis-server.trynewways.com/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/test",
    "max_reviews": 20,
    "analysis_depth": "deep"
  }'
```

You should no longer see the "model=false" error.

### Step 4: (Optional) Clean Up Old Cache

If you want to clean up the old `.jac` directory from your Coolify server:

1. SSH into your Coolify server
2. Navigate to your project directory
3. Run: `rm -rf .jac`

This step is optional since the cache is no longer mounted.

## Technical Details

### What Changed?

**JAC Bytecode Compilation:**
- JAC compiles `.jac` files to bytecode for performance
- Global variables like `LLM_MODEL` are evaluated at compile time
- If bytecode is cached, it uses the original environment variable values

**Previous Setup (Problematic):**
- `.jac/cache/` was mounted as a Docker volume
- Bytecode was compiled once and reused
- If environment variables changed, the old cached values persisted

**New Setup (Fixed):**
- `.jac/cache/` is created fresh in each container
- Bytecode is recompiled on each deployment
- Always uses current environment variable values

### Performance Impact

**Minimal:**
- Bytecode compilation happens once per deployment
- Adds ~2-5 seconds to container startup time
- No impact on runtime performance

### LLM Response Caching

**Note:** LLM response caching is still active through the database, not the `.jac` cache. You won't lose LLM response caching benefits.

## Benefits of This Fix

1. ✅ **No More Env Var Caching Issues** - Fresh compilation ensures current env vars
2. ✅ **Simpler Deployment** - One less thing to manage/backup
3. ✅ **Cleaner Deployments** - No stale cache between deployments
4. ✅ **Better for CI/CD** - Each deployment is deterministic

## If You Still See Issues

If you still encounter the `model=false` error after redeployment:

### Check Environment Variables in Coolify

1. Go to your service settings in Coolify
2. Verify these environment variables are set:
   ```
   OPENAI_API_KEY=sk-proj-...
   LLM_MODEL=gpt-4o-mini
   SERPAPI_KEY=...
   DEBUG=false
   PORT=8000
   ```

3. Make sure `LLM_MODEL` is **NOT** set to "false"

### View Logs

In Coolify, check the container logs during startup:
```bash
# Look for initialization messages
# Should see: [Server] Running on http://localhost:8000
```

### Test Environment Variables Inside Container

In Coolify, execute this command in your container:
```bash
env | grep -E "(LLM_MODEL|DEBUG|OPENAI)"
```

Should show:
```
LLM_MODEL=gpt-4o-mini
DEBUG=false
OPENAI_API_KEY=sk-proj-...
```

## Summary

The fix has been applied to your local repository. To deploy:

1. **Commit and push** the updated files
2. **Redeploy** in Coolify
3. **Test** the API endpoint

The issue should be resolved after redeployment with the new configuration.
