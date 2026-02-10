# Social Media Post Generation Research - Memory

## Research Session: Feb 2026

### Current System State
- `content_walkers.jac` has `GenerateSocialMediaPosts` walker
- Config fields: brand_voice (4 options), default_hashtags, include_star_rating, include_review_quote, include_call_to_action, call_to_action_text, brand_name
- Platforms: twitter, facebook, instagram, linkedin (4 platforms only)
- LLM prompt: basic platform descriptions + quote the review + keep Twitter under 280 chars
- No scheduling, no visual suggestions, no analytics feedback, no A/B variants

### Key Gaps Identified (vs. Industry Leaders)
See `gaps-and-recommendations.md` for full detail.
1. Brand voice config is too thin (only 4 preset options; no persona, no industry jargon config)
2. No post type variety (only testimonial; missing milestone, aggregate insight, question/engagement, tips, UGC amplification)
3. No visual/media pairing suggestions
4. No scheduling/calendar output
5. No A/B variant generation
6. No hook/opening line strategies in prompts
7. No TikTok/Google Business Profile/Threads support
8. No compliance warnings about review sharing

### Competitive Intelligence
See `competitor-features.md` for detail.
- Birdeye: BrandAI (banned words, compliance guardrails, industry AI), auto-schedules weeks in advance, visual suggestions, $50/mo
- Hootsuite OwlyWriter: image+caption gen, platform algo awareness, approval workflows, hashtag generator from image/caption
- Buffer: 30+ languages, platform-specific reformatting, 9 platforms
- Sprout Social: uses past post style matching, AI Assist generates from social profile voice
- Lately.ai: learns from long-form content, atomizes into dozens of posts, Hootsuite integration
- SOCi: multi-location enterprise, review sentiment to social, brand-consistent bulk responses

### Platform Benchmarks
See `platform-benchmarks.md` for detail.
- Instagram: 3-5 posts/week, 9-11 hashtags optimal, carousels 2.9% ER, avg ER 0.45-0.6%
- LinkedIn: 3-5 posts/week, 3-3.5% ER (some data shows 6.5%), multi-image best at 6.6%
- Facebook: posts <=80 chars get 66% higher ER, avg 0.06-0.2% ER
- Twitter/X: 280 chars (free), optimal posts 70-100 chars
- TikTok: 3-5 posts/week, 15-60 second videos, UGC 2.4x more authentic

### Legal/Compliance Notes
- FTC 2024 rule: prohibits AI-generated fake reviews; sharing real reviews is OK but needs disclosure if AI-generated post
- GDPR: explicit consent needed to use review text in ads; for organic social posts, Google ToS allows sharing reviews
- Review sharing to social (organic): generally permitted by Google ToS when attributed
- Platform rules: disclose AI-generated sponsored content

### Engagement Strategies That Work
- Hook-Story-CTA framework is dominant pattern
- Emojis: +48% Instagram ER, +25% Twitter ER, +57% Facebook interactions
- ✨ most popular emoji in 2025 social posts
- Carousel posts: 44% avg engagement boost vs manual, save rates +68%
- Video testimonials: +80% conversion rate vs text
- Social proof posts: +270% purchase likelihood on products with reviews

### LLM Prompt Engineering Notes
Key improvements for GenerateSocialMediaPosts LLM function:
- Add hook type instruction (curiosity/social proof/FOMO/bold statement)
- Add emoji guidelines per platform (more on Instagram, minimal on LinkedIn)
- Add specific hashtag count targets per platform
- Add storytelling arc instruction (not just "quote the review")
- Add post type diversification instructions
- Temperature 0.8 is appropriate for creative variation
