# Authentication Implementation Test Guide

## Test Users

```bash
# User 1: ahzan
AHZAN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4"

# User 2: farhan
FARHAN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE"
```

## Test Places

- **Sasha Food Court** (for ahzan): `https://www.google.com/maps/place/Sasha+Food+Court/@7.1630848,79.9304625,9100m/data=!3m1!1e3!4m6!3m5!1s0x3ae2e504abeae36b:0x35743bd849a861!8m2!3d7.1733194!4d79.9344347!16s%2Fg%2F11j2fkq284?entry=ttu`

- **Tamarind Tree Garden Resort** (for farhan): `https://www.google.com/maps/place/Tamarind+Tree+Garden+Resort/@7.1630848,79.9304625,9100m/data=!3m1!1e3!4m9!3m8!1s0x3afca7ceaf6334a7:0xb1397998b6bcfc37!5m2!4m1!1i2!8m2!3d7.1811592!4d79.9169383!16s%2Fg%2F1tjdk55k?entry=ttu`

---

## PHASE 1: Profile Creation

### Test 1.1: Create Profile WITHOUT Token (SHOULD FAIL)

```bash
curl -X POST http://localhost:8000/walker/create_user_profile \
  -H "Content-Type: application/json" \
  -d '{"subscription_tier": "free"}'
```

**Expected**: `401 Unauthorized` - No token provided

---

### Test 1.2: Create Profile for AHZAN (SHOULD WORK)

```bash
curl -X POST http://localhost:8000/walker/create_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{"subscription_tier": "free"}'
```

**Expected**: `200 OK` with `{"status": "created", "tier": "free", ...}`

---

### Test 1.3: Create Profile for FARHAN (SHOULD WORK)

```bash
curl -X POST http://localhost:8000/walker/create_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{"subscription_tier": "pro"}'
```

**Expected**: `200 OK` with `{"status": "created", "tier": "free", ...}`

---

### Test 1.4: Create Duplicate Profile (SHOULD RETURN EXISTS)

```bash
curl -X POST http://localhost:8000/walker/create_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{"subscription_tier": "pro"}'
```

**Expected**: `200 OK` with `{"status": "exists", "message": "User profile already exists"}`

---

## PHASE 2: Get Profile

### Test 2.1: Get Profile WITHOUT Token (SHOULD FAIL)

```bash
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `401 Unauthorized`

---

### Test 2.2: Get AHZAN's Profile with AHZAN's Token (SHOULD WORK)

```bash
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `200 OK` with ahzan's profile data (role, subscription, limits)

---

### Test 2.3: Get FARHAN's Profile with FARHAN's Token (SHOULD WORK)

```bash
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `200 OK` with farhan's profile data

---

## PHASE 3: Analyze URLs (User Isolation Test)

### Test 3.1: AHZAN Analyzes Sasha Food Court (SHOULD WORK)

```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/Sasha+Food+Court/@7.1630848,79.9304625,9100m/data=!3m1!1e3!4m6!3m5!1s0x3ae2e504abeae36b:0x35743bd849a861!8m2!3d7.1733194!4d79.9344347!16s%2Fg%2F11j2fkq284?entry=ttu",
    "max_reviews": 20
  }'
```

**Expected**: `200 OK` with analysis results, business created on ahzan's root

---

### Test 3.2: FARHAN Analyzes Tamarind Tree Resort (SHOULD WORK)

```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/Tamarind+Tree+Garden+Resort/@7.1630848,79.9304625,9100m/data=!3m1!1e3!4m9!3m8!1s0x3afca7ceaf6334a7:0xb1397998b6bcfc37!5m2!4m1!1i2!8m2!3d7.1811592!4d79.9169383!16s%2Fg%2F1tjdk55k?entry=ttu",
    "max_reviews": 20
  }'
```

**Expected**: `200 OK` with analysis results, business created on farhan's root

---

### Test 3.3: Analyze WITHOUT Token (SHOULD FAIL)

```bash
curl -X POST http://localhost:8000/walker/AnalyzeUrl \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.google.com/maps/place/Sasha+Food+Court/...",
    "force_mock": true
  }'
```

**Expected**: `401 Unauthorized`

---

## PHASE 4: List Businesses (User Isolation Test)

### Test 4.1: AHZAN Lists Businesses (SHOULD ONLY SEE AHZAN's)

```bash
curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `200 OK` with ONLY "Sasha Food Court" (ahzan's business)
- Should NOT see "Tamarind Tree Garden Resort" (farhan's business)

---

### Test 4.2: FARHAN Lists Businesses (SHOULD ONLY SEE FARHAN's)

```bash
curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `200 OK` with ONLY "Tamarind Tree Garden Resort" (farhan's business)
- Should NOT see "Sasha Food Court" (ahzan's business)

---

### Test 4.3: List Businesses WITHOUT Token (SHOULD FAIL)

```bash
curl -X POST http://localhost:8000/walker/GetBusinesses \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `401 Unauthorized`

---

## PHASE 5: Cross-User Access Tests (ALL SHOULD FAIL)

### Test 5.1: AHZAN Tries to Get FARHAN's Business Report

First, note the business_id from farhan's analysis (e.g., `0x3afca7ceaf6334a7:0xb1397998b6bcfc37`)

```bash
curl -X POST http://localhost:8000/walker/GetReport \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{"business_id": "FARHAN_BUSINESS_ID_HERE"}'
```

**Expected**: `Business not found` - ahzan cannot see farhan's business

---

### Test 5.2: FARHAN Tries to Get AHZAN's Business Analysis

```bash
curl -X POST http://localhost:8000/walker/GetAnalysis \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{"business_id": "0x3afca7ceaf6334a7:0xb1397998b6bcfc37"}'
```

**Expected**: `Business not found` - farhan cannot see ahzan's business

---

### Test 5.3: AHZAN Tries to Delete FARHAN's Business

```bash
curl -X POST http://localhost:8000/walker/DeleteBusiness \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{"business_id": "FARHAN_BUSINESS_ID_HERE"}'
```

**Expected**: `Business not found` - ahzan cannot delete farhan's business

---

## PHASE 6: Stats (Each User Sees Own Stats)

### Test 6.1: AHZAN Gets Stats

```bash
curl -X POST http://localhost:8000/walker/GetStats \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: Stats for ahzan's businesses only (1 business)

---

### Test 6.2: FARHAN Gets Stats

```bash
curl -X POST http://localhost:8000/walker/GetStats \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: Stats for farhan's businesses only (1 business)

---

## PHASE 7: Admin Tests

### Test 7.1: Create Admin WITHOUT Token (SHOULD FAIL)

```bash
curl -X POST http://localhost:8000/walker/create_admin \
  -H "Content-Type: application/json" \
  -d '{"secret_key": "secret123"}'
```

**Expected**: `401 Unauthorized`

---

### Test 7.2: Create Admin with WRONG Secret (SHOULD FAIL)

```bash
curl -X POST http://localhost:8000/walker/create_admin \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{"secret_key": "wrong_secret"}'
```

**Expected**: `Invalid admin setup secret`

---

### Test 7.3: Make AHZAN Admin with Correct Secret (SHOULD WORK)

```bash
# Make sure ADMIN_SETUP_SECRET is set on server
# export ADMIN_SETUP_SECRET=secret123

curl -X POST http://localhost:8000/walker/create_admin \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{"secret_key": "secret123"}'
```

**Expected**: `200 OK` with `{"status": "upgraded", "message": "Your account has been upgraded to admin"}`

---

### Test 7.4: Verify AHZAN is Now Admin

```bash
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `role: "admin"` in response

---

### Test 7.5: FARHAN (Non-Admin) Cannot Access Diagnostics

```bash
curl -X POST http://localhost:8000/walker/diagnostics \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `Unauthorized. Admin access required.`

---

### Test 7.6: AHZAN (Admin) Can Access Diagnostics

```bash
curl -X POST http://localhost:8000/walker/diagnostics \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{}'
```

**Expected**: `200 OK` with environment variables info

---

## PHASE 8: Admin Subscription Management

### Test 8.1: Non-Admin Cannot Update Subscriptions

```bash
curl -X POST http://localhost:8000/walker/update_subscription \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE" \
  -H "Content-Type: application/json" \
  -d '{
    "target_username": "ahzan",
    "new_tier": "pro"
  }'
```

**Expected**: `Unauthorized. Admin access required.`

---

### Test 8.2: Admin (AHZAN) Updates FARHAN's Subscription

```bash
curl -X POST http://localhost:8000/walker/update_subscription \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4" \
  -H "Content-Type: application/json" \
  -d '{
    "target_username": "farhan",
    "new_tier": "pro"
  }'
```

**Expected**: `200 OK` with subscription updated
> Note: This may fail with isolated roots - requires AdminRoot pattern for cross-user access

---

## Summary: Expected Results

| Test | Action | Expected Result |
|------|--------|-----------------|
| 1.1 | Create profile without token | 401 Unauthorized |
| 1.2 | Ahzan creates profile | 200 Created |
| 1.3 | Farhan creates profile | 200 Created |
| 2.1 | Get profile without token | 401 Unauthorized |
| 3.1 | Ahzan analyzes Sasha Food Court | 200 Success |
| 3.2 | Farhan analyzes Tamarind Resort | 200 Success |
| 4.1 | Ahzan lists businesses | Only sees Sasha Food Court |
| 4.2 | Farhan lists businesses | Only sees Tamarind Resort |
| 5.1 | Ahzan access Farhan's report | Business not found |
| 5.2 | Farhan access Ahzan's analysis | Business not found |
| 5.3 | Ahzan delete Farhan's business | Business not found |
| 7.3 | Make Ahzan admin | 200 Upgraded |
| 7.5 | Farhan access diagnostics | Unauthorized |
| 7.6 | Ahzan access diagnostics | 200 Success |
| 8.1 | Farhan update subscription | Unauthorized |

---

## Quick Test Script

```bash
#!/bin/bash

AHZAN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImFoemFuIiwiZXhwIjoxNzY5MjUxNjM5LCJpYXQiOjE3Njg2NDY4MzkuNjAzMjA2fQ.ogh_hh3sKXM95b88hEpvwiHFvG4-xmQpld59A3p4PQ4"
FARHAN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImZhcmhhbiIsImV4cCI6MTc2OTI1MTY2NCwiaWF0IjoxNzY4NjQ2ODY0LjE0NzU0M30.nMdeWcSgjCU2fa66u2cDgU8aQYMjHBLmBEEvmhpTnHE"
BASE_URL="http://localhost:8000"

echo "=== Phase 1: Profile Creation ==="
echo "Creating ahzan's profile..."
curl -s -X POST $BASE_URL/walker/create_user_profile \
  -H "Authorization: Bearer $AHZAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subscription_tier": "free"}' | jq '.'

echo -e "\nCreating farhan's profile..."
curl -s -X POST $BASE_URL/walker/create_user_profile \
  -H "Authorization: Bearer $FARHAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subscription_tier": "free"}' | jq '.'

echo -e "\n=== Phase 2: Check Profiles ==="
echo "Ahzan's profile..."
curl -s -X POST $BASE_URL/walker/get_user_profile \
  -H "Authorization: Bearer $AHZAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq '.'

echo -e "\n=== Phase 3: List Businesses (should be empty initially) ==="
echo "Ahzan's businesses..."
curl -s -X POST $BASE_URL/walker/GetBusinesses \
  -H "Authorization: Bearer $AHZAN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{}' | jq '.'

echo -e "\n=== Done! ==="
```
