# Review Analyzer - Agent Memory

## Project Overview
JAC (Jaclang) graph-based API. Files at project root: `main.jac`, `models.jac`, `walkers.jac`, `api_walkers.jac`, `auth_walkers.jac`, `content_walkers.jac`, `credit_walkers.jac`, `payment_walkers.jac`, `errors.jac`.

## Social Media Post Generation Research (Feb 2026)
Full research notes in `.claude/agent-memory/social-media-research/`:
- `MEMORY.md` - summary of findings and gaps
- `competitor-features.md` - Birdeye, Hootsuite, Buffer, Sprout Social, Lately, SOCi, Jasper details
- `platform-benchmarks.md` - character limits, hashtag counts, ER benchmarks, posting frequencies
- `gaps-and-recommendations.md` - prioritized improvement list with code examples

**Key finding**: Current `GenerateSocialMediaPosts` is basic compared to industry leaders.
Top quick wins: (1) add post_type field (7 types), (2) add hook_style config, (3) improve platform-specific LLM instructions with emoji/hashtag guidance, (4) add variant count for A/B testing.

## Key JAC Patterns
- Walker entry: `can start with \`root entry { ... }`
- Credit check: validate profile -> check credits -> deduct before LLM -> refund on failure
- Graph traversal: `[here -->(?:\`Business)]`
- LLM calls: `def func(...) -> ReturnType by llm(temperature=X, incl_info={...})`
- Error helpers: `not_found_error()`, `validation_error()`, `insufficient_credits_error()`
