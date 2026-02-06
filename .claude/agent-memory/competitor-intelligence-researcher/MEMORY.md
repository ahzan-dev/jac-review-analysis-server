# Competitor Intelligence Researcher - Agent Memory

## Project Context
- Review Analyzer SaaS built with Jaclang (JAC), graph-based architecture
- Files moved to `services/` directory: models.jac, walkers.jac, api_walkers.jac, auth_walkers.jac, credit_walkers.jac, payment_walkers.jac, errors.jac
- Main entry: `main.jac` includes via `include services.models;` etc.
- Production API: https://review-analysis-server.trynewways.com/

## Architecture Findings
- Competitors should be standard Business nodes using the existing 5-stage pipeline (no code duplication)
- New grouping via CompetitorSet node connected to Business nodes via InCompetitorSet edges
- CompetitorSnapshot nodes capture point-in-time metrics for trend tracking
- BenchmarkReport stores deterministic metrics + LLM-generated narrative
- See: [docs/COMPETITOR_INTELLIGENCE_GUIDE.md](../../docs/COMPETITOR_INTELLIGENCE_GUIDE.md)

## SERP API for Competitor Discovery
- Engine: `google_maps`, type: `search` (not `place`)
- GPS coordinates via `ll` parameter: `@{lat},{lng},{zoom}z`
- Returns `local_results` array with place_id, data_id, rating, reviews, type, price, address, gps_coordinates
- 20 results per page, paginate with `start` parameter (0, 20, 40...)
- Zoom levels: 14z=5km (recommended default), 12z=20km, 17z=500m
- Each page = 1 SERP API credit (~$0.01)

## Key Metrics for Benchmarking
- Competitive Sentiment Index (CSI) = (user_sentiment - competitor_mean) / competitor_std_dev
- Composite Competitive Index: weighted sum of percentiles (rating 25%, sentiment 25%, health 20%, volume 15%, response rate 15%)
- Theme gap analysis: compare avg_sentiment per shared theme, classify as significant_advantage/slight_advantage/competitive/slight_disadvantage/significant_disadvantage
- Industry-specific benchmarks defined per business type (RESTAURANT, HOTEL, etc.)

## Credit Cost Model
- Discover competitors: 0.5 credits
- Add competitor (full analysis): 1.0 credit
- Generate benchmark report: 0.5 credits
- Lightweight monitoring refresh: 0.5 credits per competitor
- Read operations (get report/trends/alerts): 0 credits

## Tier Limits
- Premium: 1 competitor set, 5 competitors, manual refresh only
- Enterprise: 5 sets, 20 competitors, automated monitoring + alerts

## Implementation Phases
- Phase 1 (MVP): Manual add by URL, benchmarking, comparison reports (4-5 weeks)
- Phase 2: SERP API discovery, snapshots, trends, refresh (3-4 weeks)
- Phase 3: Automated monitoring, alerts, cron scheduling (3-4 weeks)

## Key Patterns
- Haversine formula for distance calculation between businesses
- Snapshot comparison for change detection (rating delta, review surge, sentiment shift)
- Alert severity: critical (rating drop >=0.5), warning (>=0.2), info (new themes)
- No built-in scheduler in JAC - use external cron + API call
