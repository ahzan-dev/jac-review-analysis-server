# API Test Commands

Base URL: `http://localhost:8000` (local) or `https://review-analysis-server.trynewways.com` (production)

```bash
export API="http://localhost:8002"
```

---

## 1. Register

```bash
curl -X POST "$API/user/register" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example1.com", "password": "test123"}'
```

---

## 2. Login

```bash
curl -X POST "$API/user/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example1.com", "password": "test123"}'
```

Save the token:

```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6InRlc3RAZXhhbXBsZS5jb20iLCJleHAiOjE3NzA5OTg3OTksImlhdCI6MTc3MDM5Mzk5OS41NTQ2Mjh9.88qkyoTWw2Om5Ly3ao4XL_w9QPrClrZZI6NhnmhpU8U"
```

---

## 3. Create Profile

```bash
curl -X POST "$API/walker/create_profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 4. Get User Profile

```bash
curl -X POST "$API/walker/get_user_profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 5. Get Credit Balance

```bash
curl -X POST "$API/walker/get_credit_balance" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 6. Get Credit Packages

```bash
curl -X POST "$API/walker/get_credit_packages" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

Packages:

- `bronze`: 1 credit - $5
- `silver`: 5 credits - $22
- `gold`: 12 credits - $48
- `platinum`: 30 credits - $110

---

## 7. Purchase Credits

Test card: `4242424242424242` (success)

```bash
curl -X POST "$API/walker/purchase_credit_package" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "package": "silver",
    "payment_method": {
      "card_number": "4242424242424242",
      "exp_month": "12",
      "exp_year": "2028",
      "cvc": "123"
    }
  }'
```

---

## 8. Get Payment History

```bash
curl -X POST "$API/walker/get_payment_history" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"limit": 20}'
```

---

## 9. Analyze URL

```bash
curl -X POST "$API/walker/AnalyzeUrl" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/JOLLYBEEZ/@8.0143405,79.8239798,4541m/data=!3m1!1e3!4m9!1m2!2m1!1sice+talk+family+restaurant!3m5!1s0x3afd1725d93fd7dd:0xbbae942ddf90ad44!8m2!3d8.0263214!4d79.8357705!16s%2Fg%2F11s17kwkzc?hl=en-US&entry=ttu&g_ep=EgoyMDI2MDIwNC4wIKXMDSoASAFQAw%3D%3D",
    "max_reviews": 100
  }'
```

---

## 10. Get Businesses

```bash
curl -X POST "$API/walker/GetBusinesses" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"limit": 20}'
```

---

## 11. Get Report

```bash
curl -X POST "$API/walker/GetReport" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac"}'
```

---

## 12. Get Reviews

```bash
curl -X POST "$API/walker/GetReviews" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "limit": 50
  }'
```

With filters:

```bash
curl -X POST "$API/walker/GetReviews" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "sentiment_filter": "negative",
    "min_rating": 1,
    "max_rating": 3,
    "limit": 20
  }'
```

---

## 13. Save Reply Config

```bash
curl -X POST "$API/walker/SaveReplyPromptConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tone": "friendly_professional",
    "max_length": "medium",
    "include_name": true,
    "offer_resolution": true,
    "sign_off": "The Management Team",
    "custom_instructions": ""
  }'
```

---

## 14. Get Reply Config

```bash
curl -X POST "$API/walker/GetReplyPromptConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 15. Generate Single Reply

```bash
curl -X POST "$API/walker/GenerateReviewReply" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "review_id": "Ci9DQUlRQUNvZENodHljRjlvT2xkWWFEZGFjemxyVEVwS1UxOWZOblpSZW5FelpGRRAB"
  }'
```

---

## 16. Bulk Generate Replies

All negative reviews:

```bash
curl -X POST "$API/walker/BulkGenerateReviewReplies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "filter_sentiment": "positive",
    "max_replies": 10
  }'
```

Specific reviews:

```bash
curl -X POST "$API/walker/BulkGenerateReviewReplies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "review_ids": ["review_id_1", "review_id_2", "review_id_3"]
  }'
```

---

## 17. Regenerate Reply

```bash
curl -X POST "$API/walker/RegenerateReviewReply" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "review_id": "Ci9DQUlRQUNvZENodHljRjlvT2xkWWFEZGFjemxyVEVwS1UxOWZOblpSZW5FelpGRRAB"
  }'
```

---

## 18. Get All Replies

```bash
curl -X POST "$API/walker/GetReviewReplies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "limit": 50
  }'
```

---

## 19. Delete Reply

```bash
curl -X POST "$API/walker/DeleteReviewReply" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac",
    "review_id": "YOUR_REVIEW_ID"
  }'
```

---

## 20. Delete Business

```bash
curl -X POST "$API/walker/DeleteBusiness" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"business_id": "0x3ae25b007fa6f3a7:0x7f68ef54a05e12ac"}'
```

---

## Quick Test Script

```bash
#!/bin/bash
API="http://localhost:8000"

# Register
curl -s -X POST "$API/user/register" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example.com", "password": "test123"}' | jq

# Login and get token
TOKEN=$(curl -s -X POST "$API/user/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example.com", "password": "test123"}' | jq -r '.token')

echo "Token: $TOKEN"

# Create profile
curl -s -X POST "$API/walker/create_profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq

# Purchase credits (bronze package)
curl -s -X POST "$API/walker/purchase_credit_package" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "package": "bronze",
    "payment_method": {
      "card_number": "4242424242424242",
      "exp_month": "12",
      "exp_year": "2028",
      "cvc": "123"
    }
  }' | jq

# Get profile (check credits)
curl -s -X POST "$API/walker/get_user_profile" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq
```

---

# Content Generation Endpoints

> **Prerequisites**: You must have an analyzed business first (run step 9 - Analyze URL).
> Replace `YOUR_BUSINESS_ID` with the actual `place_id` from GetBusinesses.
> Replace `YOUR_REVIEW_ID` with an actual `review_id` from GetReviews.

```bash
export BIZ_ID="0x3ae251deb488530d:0xdf3d65a2ccd0d047"
```

---

## 21. Get Response Templates

Browse all templates (first call seeds system templates automatically):

```bash
curl -X POST "$API/walker/GetResponseTemplates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

With filters:

```bash
curl -X POST "$API/walker/GetResponseTemplates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "negative",
    "business_type": "RESTAURANT"
  }'
```

Filter by scenario:

```bash
curl -X POST "$API/walker/GetResponseTemplates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "category": "positive",
    "scenario": "praise"
  }'
```

---

## 22. Create Custom Response Template

```bash
curl -X POST "$API/walker/CreateResponseTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "My Custom Thank You",
    "category": "positive",
    "scenario": "praise",
    "business_type": "RESTAURANT",
    "template_text": "Hi {reviewer_name}! Thanks for the amazing review. We are so happy you loved {specific_mention}. Our team at {business_name} looks forward to serving you again! - {sign_off}",
    "tone": "friendly"
  }'
```

Save the template_id:

```bash
export TEMPLATE_ID="bd93c9f4-cad4-4daa-b0af-e8e92cb13e69"
```

---

## 23. Apply Template (AI Customization) - 0.25 credits

```bash
curl -X POST "$API/walker/ApplyTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "'$TEMPLATE_ID'",
    "business_id": "'$BIZ_ID'",
    "review_id": "'$YOUR_REVIEW_ID'"
  }'
```

---

## 24. Delete Custom Template

```bash
curl -X POST "$API/walker/DeleteResponseTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "'$TEMPLATE_ID'"
  }'
```

Trying to delete a system template (should fail):

```bash
curl -X POST "$API/walker/DeleteResponseTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "SYSTEM_TEMPLATE_ID"
  }'
```

---

## 25. Generate Action Plan - 0.5 credits

90-day full plan:

```bash
curl -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "timeframe": "30_day"
  }'
```

30-day focused plan:

```bash
curl -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "timeframe": "30_day",
    "focus_areas": ["Service", "Value"]
  }'
```

Save the plan_id:

```bash
export PLAN_ID="YOUR_PLAN_ID"
```

---

## 26. Get Action Plans

```bash
curl -X POST "$API/walker/GetActionPlans" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'"
  }'
```

---

## 27. Delete Action Plan

```bash
curl -X POST "$API/walker/DeleteActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "plan_id": "'$PLAN_ID'"
  }'
```

---

## 28. Save Social Media Post Config

```bash
curl -X POST "$API/walker/SaveSocialMediaPostConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "Street Burger",
    "brand_voice": "casual",
    "default_hashtags": ["#StreetBurger", "#BurgerLove", "#Foodie"],
    "include_star_rating": true,
    "include_review_quote": true,
    "include_call_to_action": true,
    "call_to_action_text": "Visit us today!"
  }'
```

---

## 29. Get Social Media Post Config

```bash
curl -X POST "$API/walker/GetSocialMediaPostConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 30. Generate Social Media Posts - 0.25 credits

Auto-select best reviews, all platforms:

```bash
curl -X POST "$API/walker/GenerateSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "platforms": ["twitter", "facebook", "instagram", "linkedin"],
    "count": 1
  }'
```

From a specific review, selected platforms:

```bash
curl -X POST "$API/walker/GenerateSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "review_id": "YOUR_REVIEW_ID",
    "platforms": ["twitter", "instagram"]
  }'
```

Save a post_id:

```bash
export POST_ID="YOUR_POST_ID"
```

---

## 31. Get Social Media Posts

All posts:

```bash
curl -X POST "$API/walker/GetSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'"
  }'
```

Filter by platform:

```bash
curl -X POST "$API/walker/GetSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "platform": "twitter"
  }'
```

---

## 32. Delete Social Media Post

```bash
curl -X POST "$API/walker/DeleteSocialMediaPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "post_id": "'$POST_ID'"
  }'
```

---

## 33. Save Marketing Copy Config

```bash
curl -X POST "$API/walker/SaveMarketingCopyConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "Street Burger",
    "brand_tagline": "Best Burgers In Town",
    "target_audience": "Young professionals, foodies, families",
    "unique_selling_points": ["Hand-crafted burgers", "Fresh local ingredients", "Award-winning sauce"],
    "tone": "persuasive"
  }'
```

---

## 34. Get Marketing Copy Config

```bash
curl -X POST "$API/walker/GetMarketingCopyConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 35. Generate Marketing Copy - 0.25 credits

Google Search Ads (3 variants):

```bash
curl -X POST "$API/walker/GenerateMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "ad_format": "google_search",
    "num_variants": 3
  }'
```

Facebook Ad:

```bash
curl -X POST "$API/walker/GenerateMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "ad_format": "facebook_ad",
    "num_variants": 2
  }'
```

Instagram Ad:

```bash
curl -X POST "$API/walker/GenerateMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "ad_format": "instagram_ad",
    "num_variants": 3
  }'
```

Email Subject Lines:

```bash
curl -X POST "$API/walker/GenerateMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "ad_format": "email_subject",
    "num_variants": 3
  }'
```

Save a copy_id:

```bash
export COPY_ID="YOUR_COPY_ID"
```

---

## 36. Get Marketing Copies

All copies:

```bash
curl -X POST "$API/walker/GetMarketingCopies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'"
  }'
```

Filter by ad format:

```bash
curl -X POST "$API/walker/GetMarketingCopies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "ad_format": "google_search"
  }'
```

---

## 37. Delete Marketing Copy

```bash
curl -X POST "$API/walker/DeleteMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "copy_id": "'$COPY_ID'"
  }'
```

---

## 38. Save Blog Post Config

```bash
curl -X POST "$API/walker/SaveBlogPostConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "author_name": "John Smith",
    "brand_name": "Street Burger",
    "writing_style": "informative",
    "target_word_count": 800,
    "include_data_visualizations": true,
    "seo_focus": true
  }'
```

---

## 39. Get Blog Post Config

```bash
curl -X POST "$API/walker/GetBlogPostConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}'
```

---

## 40. Generate Blog Post - 1.0 credits

Insights Listicle:

```bash
curl -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "insights_listicle"
  }'
```

Improvement Story:

```bash
curl -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "improvement_story"
  }'
```

Customer Spotlight:

```bash
curl -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "customer_spotlight"
  }'
```

Case Study:

```bash
curl -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "case_study"
  }'
```

Trend Analysis with focused theme:

```bash
curl -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "trend_analysis",
    "focus_theme": "Service"
  }'
```

Save a blog post_id:

```bash
export BLOG_ID="YOUR_BLOG_POST_ID"
```

---

## 41. Get Blog Posts

All posts:

```bash
curl -X POST "$API/walker/GetBlogPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'"
  }'
```

Filter by content type:

```bash
curl -X POST "$API/walker/GetBlogPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "insights_listicle"
  }'
```

---

## 42. Delete Blog Post

```bash
curl -X POST "$API/walker/DeleteBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "post_id": "'$BLOG_ID'"
  }'
```

---

## Error Case Tests

### Insufficient Credits

```bash
# Should fail if user has < 0.5 credits
curl -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "timeframe": "90_day"
  }'
```

### Invalid Timeframe

```bash
curl -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "timeframe": "120_day"
  }'
```

### Invalid Ad Format

```bash
curl -X POST "$API/walker/GenerateMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "ad_format": "tiktok_ad"
  }'
```

### Invalid Content Type

```bash
curl -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "content_type": "poem"
  }'
```

### Invalid Platform

```bash
curl -X POST "$API/walker/GenerateSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "'$BIZ_ID'",
    "platforms": ["tiktok"]
  }'
```

### Business Not Found

```bash
curl -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "nonexistent_id",
    "timeframe": "90_day"
  }'
```

### No Analysis Data

```bash
# Should fail if business hasn't been analyzed yet
curl -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "business_id": "UNANALYZED_BUSINESS_ID",
    "timeframe": "90_day"
  }'
```

### Delete System Template (Should Fail)

```bash
# Get a system template_id first from GetResponseTemplates
curl -X POST "$API/walker/DeleteResponseTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "template_id": "SYSTEM_TEMPLATE_ID"
  }'
```

---

## Content Generation Full Test Script

```bash
#!/bin/bash
API="http://localhost:8000"

# Assumes TOKEN and BIZ_ID are already set
# export TOKEN="your_jwt_token"
# export BIZ_ID="your_business_place_id"

echo "=== Content Generation Tests ==="
echo ""

# 1. Response Templates
echo "--- Response Templates ---"
echo "1. Get all templates:"
curl -s -X POST "$API/walker/GetResponseTemplates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq '.count, .filters_applied'

echo ""
echo "2. Filter negative templates:"
curl -s -X POST "$API/walker/GetResponseTemplates" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"category": "negative"}' | jq '.count'

echo ""
echo "3. Create custom template:"
TMPL_RESULT=$(curl -s -X POST "$API/walker/CreateResponseTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Template",
    "category": "positive",
    "scenario": "praise",
    "template_text": "Thanks {reviewer_name}! Glad you loved {specific_mention}. - {sign_off}"
  }')
echo "$TMPL_RESULT" | jq '.success, .template.template_id'
TEMPLATE_ID=$(echo "$TMPL_RESULT" | jq -r '.template.template_id')

echo ""
echo "4. Delete custom template:"
curl -s -X POST "$API/walker/DeleteResponseTemplate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"template_id\": \"$TEMPLATE_ID\"}" | jq '.success'

# 2. Action Plans
echo ""
echo "--- Action Plans ---"
echo "5. Generate 90-day action plan (0.5 credits):"
AP_RESULT=$(curl -s -X POST "$API/walker/GenerateActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\", \"timeframe\": \"90_day\"}")
echo "$AP_RESULT" | jq '.success, .plan.title, .plan.total_action_items, .credits'
PLAN_ID=$(echo "$AP_RESULT" | jq -r '.plan.plan_id')

echo ""
echo "6. Get action plans:"
curl -s -X POST "$API/walker/GetActionPlans" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\"}" | jq '.count'

echo ""
echo "7. Delete action plan:"
curl -s -X POST "$API/walker/DeleteActionPlan" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\", \"plan_id\": \"$PLAN_ID\"}" | jq '.success'

# 3. Social Media Posts
echo ""
echo "--- Social Media Posts ---"
echo "8. Save social config:"
curl -s -X POST "$API/walker/SaveSocialMediaPostConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_voice": "casual",
    "default_hashtags": ["#TestBrand"],
    "include_star_rating": true,
    "include_call_to_action": true
  }' | jq '.success'

echo ""
echo "9. Generate social posts (0.25 credits):"
SP_RESULT=$(curl -s -X POST "$API/walker/GenerateSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\", \"platforms\": [\"twitter\", \"facebook\"], \"count\": 1}")
echo "$SP_RESULT" | jq '.success, .posts_generated, .credits'

echo ""
echo "10. Get social posts:"
curl -s -X POST "$API/walker/GetSocialMediaPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\"}" | jq '.count'

# 4. Marketing Copy
echo ""
echo "--- Marketing Copy ---"
echo "11. Save marketing config:"
curl -s -X POST "$API/walker/SaveMarketingCopyConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "brand_name": "Test Brand",
    "target_audience": "Young professionals",
    "tone": "persuasive"
  }' | jq '.success'

echo ""
echo "12. Generate google search ads (0.25 credits):"
MC_RESULT=$(curl -s -X POST "$API/walker/GenerateMarketingCopy" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\", \"ad_format\": \"google_search\", \"num_variants\": 3}")
echo "$MC_RESULT" | jq '.success, .ad_format, (.variants | length), .credits'

echo ""
echo "13. Get marketing copies:"
curl -s -X POST "$API/walker/GetMarketingCopies" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\"}" | jq '.count'

# 5. Blog Posts
echo ""
echo "--- Blog Posts ---"
echo "14. Save blog config:"
curl -s -X POST "$API/walker/SaveBlogPostConfig" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "author_name": "Test Author",
    "writing_style": "informative",
    "target_word_count": 800
  }' | jq '.success'

echo ""
echo "15. Generate blog post (1.0 credits):"
BP_RESULT=$(curl -s -X POST "$API/walker/GenerateBlogPost" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\", \"content_type\": \"insights_listicle\"}")
echo "$BP_RESULT" | jq '.success, .blog_post.title, .blog_post.word_count, .credits'

echo ""
echo "16. Get blog posts:"
curl -s -X POST "$API/walker/GetBlogPosts" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"business_id\": \"$BIZ_ID\"}" | jq '.count'

# Final credit check
echo ""
echo "=== Final Credit Balance ==="
curl -s -X POST "$API/walker/get_credit_balance" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq
```
