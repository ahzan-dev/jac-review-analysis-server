# Gaps Analysis & Actionable Recommendations

## Current GenerateSocialMediaPosts Config Fields
- brand_name: str
- brand_voice: str (professional/casual/playful/authoritative)
- default_hashtags: list[str]
- include_star_rating: bool
- include_review_quote: bool
- include_call_to_action: bool
- call_to_action_text: str

## Priority Improvements (Ranked by Impact vs. Effort)

### HIGH IMPACT, LOW EFFORT (Prompt Engineering Only)

**1. Add Post Type Selection**
New field: `post_type: str` with options:
- "testimonial" (current default - just quote the review)
- "question_engagement" (end with a question to drive comments)
- "tips_based" (extract tip/insight from review, frame as advice)
- "milestone_celebration" (frame around review count/rating milestone)
- "aggregate_insight" ("Our customers love X - here's why...")
- "story_narrative" (turn review into 3-act customer journey story)
- "before_after" (frame as transformation story from review themes)

**2. Add Hook Strategy Config**
New field: `hook_style: str` with options:
- "bold_statement" (contrarian/surprising opening)
- "curiosity" (information gap / tease)
- "social_proof" (lead with authority/numbers)
- "question" (rhetorical question to draw reader in)
- "quote_first" (start directly with customer quote)
- "data_point" (start with a statistic)

**3. Improve Platform-Specific LLM Instructions**
Current prompt only has basic character limits. Should add:
- Emoji count targets: Instagram 2-4, LinkedIn 0-2, Twitter 1-2, Facebook 2-3
- Hashtag count targets per platform
- Hook placement instruction (first 70 chars for Twitter, first 125 for Instagram, first 210 for LinkedIn)
- Storytelling arc: Hook → Value/Story → CTA
- Platform personality: Instagram=visual+aspirational, LinkedIn=professional+personal, Twitter=punchy+conversational

**4. Add Variant Generation (A/B Testing)**
New field: `generate_variants: int = 1` (1-3 variants)
The LLM already at temperature 0.8 - just call generate_posts N times or modify prompt to return N versions

### HIGH IMPACT, MEDIUM EFFORT (New Config Fields + Data)

**5. Enhanced Brand Voice Config**
Replace simple `brand_voice` string with richer config:
- `brand_personality_traits: list[str]` (e.g., ["warm", "expert", "local", "trustworthy"])
- `industry_keywords: list[str]` (terms your business commonly uses)
- `avoid_words: list[str]` (words/phrases to never use)
- `tone_examples: list[str]` (example sentences in the brand voice)
- `target_audience: str` (e.g., "young families", "business professionals", "health-conscious adults")

**6. Add TikTok Script Generation**
New platform option: "tiktok"
LLM output: not a caption but a video script with:
- Hook (first 2 seconds - on-screen text)
- Core narrative (what to say/show)
- CTA at end
- Suggested audio type (trending, voiceover, background music)

**7. Add Google Business Profile Post Type**
New platform option: "google_business_profile"
Post types: update, offer, event
Include local SEO keywords naturally

**8. Add Visual/Media Suggestions**
New field in SocialMediaPostGenerated:
- `visual_suggestion: str` (text description of ideal image/video)
- `graphic_type: str` (photo, graphic/text overlay, carousel, video, reel)
- `image_search_query: str` (query to find matching stock photo)

### MEDIUM IMPACT, LOW EFFORT

**9. Add Compliance Note in Response**
For testimonial posts, add to response:
- `compliance_note: str` field noting FTC disclosure requirements
- Warning if review author's full name is being used

**10. Improve Hashtag Intelligence**
Instead of static `default_hashtags`, generate contextual hashtags using:
- Business type → industry hashtags
- Review themes → topic hashtags
- Business location (if available) → local hashtags
- Mix of broad (high volume) and niche (highly targeted)

### MEDIUM IMPACT, MEDIUM EFFORT

**11. Content Calendar Output**
Add `generate_calendar: bool` flag
Return a content_plan array with:
- Suggested posting schedule (day of week, time)
- Platform sequence (which to post first)
- Mix of post types across the calendar

**12. Multi-Language Support**
New field: `language: str = "english"`
Pass to LLM with instruction to generate in target language
Note: transcreation (not just translation) is preferred

## Post Type Templates (For Prompt Engineering)

### Testimonial Post (Current)
"[Business] customer [Author] says: '[Quote]' - [CTA]"

### Question/Engagement Post
"What makes the perfect [business type] experience? [Author] found theirs at [Business]: '[Quote]'. What matters most to you? [Hashtags]"

### Tips-Based Post (from positive review)
"Pro tip from one of our customers: [insight extracted from review]. Thank you [Author] for sharing! [CTA] [Hashtags]"

### Milestone Celebration Post
"[X]+ customers have shared their experiences - and reviews like [Author]'s keep us going: '[Quote]'. Thank you for being part of our story. [Hashtags]"

### Aggregate Insight Post
"Our customers tell us [Theme from analysis] is what they love most. Here's what [Author] had to say: '[Quote]'. [CTA] [Hashtags]"

### Story Narrative Post
"[Author] came to [Business] looking for [problem implied in review]. What happened next: '[Quote]'. Every visit is a story. Book yours: [CTA]"

## Hook Formula Library (For LLM Instruction)

### Curiosity Hooks
- "Here's what nobody tells you about [topic]..."
- "This [customer/guest/client] said something we'll never forget..."
- "We asked. They answered. And the response surprised us."

### Social Proof Hooks
- "When customers speak, we listen. Here's what they're saying..."
- "Rated [X]/5 by [N]+ customers. Here's why..."
- "[Author] tried [Business] for the first time. Here's what happened."

### Bold Statement Hooks
- "Some reviews stop you in your tracks."
- "This is exactly why we do what we do."
- "Not all [business type] experiences are created equal."

### Question Hooks
- "What does the perfect [service] look like?"
- "Wondering if [Business] is worth it? [Author] has an answer."
- "What keeps our customers coming back?"

## LLM Prompt Enhancement Recommendations

Current incl_info structure should be expanded with:
```python
{
    "post_type": post_type,  # NEW
    "hook_style": hook_style,  # NEW
    "platform_guidelines": {  # NEW - platform-specific rules
        "instagram": {"emoji_count": "2-4", "hashtag_count": "9-11", "hook_window": "125 chars"},
        "twitter": {"emoji_count": "1-2", "hashtag_count": "1-2", "hook_window": "70 chars"},
        "linkedin": {"emoji_count": "0-2", "hashtag_count": "3-5", "hook_window": "210 chars"},
        "facebook": {"emoji_count": "2-3", "hashtag_count": "1-2", "hook_window": "80 chars"},
    },
    "brand_personality": brand_personality_traits,  # NEW
    "target_audience": target_audience,  # NEW
    "avoid_words": avoid_words,  # NEW
    "content_strategy": "Hook (1-2 lines) → Value/Story (2-4 lines) → CTA (1 line)"  # NEW
}
```
