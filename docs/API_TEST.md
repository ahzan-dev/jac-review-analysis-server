# API Test Commands

Base URL: `http://localhost:8000` (local) or `https://review-analysis-server.trynewways.com` (production)

```bash
export API="http://localhost:8000"
```

---

## 1. Register

```bash
curl -X POST "$API/user/register" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example.com", "password": "test123"}'
```

---

## 2. Login

```bash
curl -X POST "$API/user/login" \
  -H "Content-Type: application/json" \
  -d '{"username": "test@example.com", "password": "test123"}'
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
    "url": "https://www.google.com/maps/place/ARCADIA+Cafe+%26+Restaurant/@6.8867309,79.882027,18211m/data=!3m1!1e3!4m6!3m5!1s0x3ae251deb488530d:0xdf3d65a2ccd0d047!8m2!3d6.880648!4d79.9345356!16s%2Fg%2F11rd2z6bnz?entry=ttu&g_ep=EgoyMDI2MDEyOC4wIKXMDSoASAFQAw%3D%3D",
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
