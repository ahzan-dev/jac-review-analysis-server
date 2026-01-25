# API Flow Testing - Simple Guide

Simple guide to testing the authentication and payment flows.

---

## Quick Start: Simple Flow

```
1. Register         → POST /user/register (JAC built-in)
2. Create Profile   → POST /walker/create_profile (pick tier)
3. Payment          → POST /walker/initiate_payment + POST /walker/process_payment (if paid tier)
4. Done!            → User has active subscription
```

---

## 1. Registration & Authentication

### 1.1 Register New User
```bash
curl -X POST http://localhost:8000/user/register \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "test123"}'
```

**Response:**
```json
{"token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."}
```

**Save the token:**
```bash
export TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

---

### 1.2 Login (Existing User)
```bash
curl -X POST http://localhost:8000/user/login \
  -H "Content-Type: application/json" \
  -d '{"username": "testuser", "password": "test123"}'
```

---

## 2. Profile Creation

### 2.1 Create Profile - FREE Tier
```bash
curl -X POST http://localhost:8000/walker/create_profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_requested": "free"}' | jq .
```

**Response:**
```json
{
  "success": true,
  "tier": "free",
  "subscription_status": "active",
  "limits": {
    "max_businesses": 5,
    "daily_analyses": 10
  }
}
```

---

### 2.2 Create Profile - PRO Tier (Pending Payment)
```bash
curl -X POST http://localhost:8000/walker/create_profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_requested": "pro"}' | jq .
```

**Response:**
```json
{
  "success": true,
  "tier": "free",
  "subscription_status": "pending_payment",
  "pending_upgrade": "pro",
  "limits": {
    "max_businesses": 5,
    "daily_analyses": 10
  },
  "next_step": "Call initiate_payment to start payment process"
}
```

---

### 2.3 Create Profile - ENTERPRISE Tier (Pending Payment)
```bash
curl -X POST http://localhost:8000/walker/create_profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_requested": "enterprise"}' | jq .
```

---

### 2.4 Get User Profile
```bash
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Authorization: Bearer $TOKEN" | jq .
```

**Response:**
```json
{
  "success": true,
  "role": "user",
  "subscription": {
    "tier": "free",
    "status": "pending_payment",
    "pending_upgrade": "pro"
  },
  "limits": {
    "max_businesses": 5,
    "current_businesses": 0,
    "remaining_businesses": 5,
    "daily_analysis_limit": 10,
    "analyses_today": 0,
    "remaining_today": 10
  },
  "is_active": true
}
```

---

## 3. Payment Flow

### 3.1 Initiate Payment
```bash
curl -X POST http://localhost:8000/walker/initiate_payment \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "tier": "pro",
    "billing_interval": "monthly"
  }' | jq .
```

**Response:**
```json
{
  "payment_id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "amount": 29.0,
  "currency": "USD",
  "tier": "pro",
  "billing_interval": "monthly",
  "status": "requires_payment_method",
  "client_secret": "dummy_secret_a1b2c3d4...",
  "message": "Payment intent created. Submit payment to complete."
}
```

**Save payment_id:**
```bash
export PAYMENT_ID="a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

---

### 3.2 Process Payment - SUCCESS
```bash
curl -X POST http://localhost:8000/walker/process_payment \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "'$PAYMENT_ID'",
    "payment_method": {
      "card_number": "4242424242424242",
      "exp_month": 12,
      "exp_year": 2025,
      "cvc": "123"
    }
  }' | jq .
```

**Response:**
```json
{
  "success": true,
  "payment_id": "a1b2c3d4...",
  "status": "succeeded",
  "subscription": {
    "tier": "pro",
    "status": "active",
    "billing_interval": "monthly",
    "start_date": "2026-01-25T10:30:00",
    "end_date": "2026-02-25T10:30:00",
    "limits": {
      "max_businesses": 50,
      "daily_analyses": 100
    }
  },
  "message": "Payment successful! Upgraded to PRO tier."
}
```

---

### 3.3 Process Payment - DECLINED
```bash
curl -X POST http://localhost:8000/walker/process_payment \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "'$PAYMENT_ID'",
    "payment_method": {
      "card_number": "4000000000000002",
      "exp_month": 12,
      "exp_year": 2025,
      "cvc": "123"
    }
  }' | jq .
```

**Response:**
```json
{
  "success": false,
  "error": "Card declined",
  "payment_id": "a1b2c3d4...",
  "decline_code": "generic_decline"
}
```

---

## 4. Subscription Management

### 4.1 Get Subscription Details
```bash
curl -X POST http://localhost:8000/walker/get_subscription_details \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

### 4.2 Schedule Downgrade
```bash
curl -X POST http://localhost:8000/walker/schedule_downgrade \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target_tier": "free"}' | jq .
```

---

### 4.3 Cancel Subscription
```bash
# Cancel at period end (keep access until billing period ends)
curl -X POST http://localhost:8000/walker/cancel_subscription \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"immediate": false}' | jq .

# Cancel immediately (downgrade now)
curl -X POST http://localhost:8000/walker/cancel_subscription \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"immediate": true}' | jq .
```

---

## 5. Admin Operations

### 5.1 Create Admin
```bash
curl -X POST http://localhost:8000/walker/create_admin \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"secret_key": "your_admin_secret_key"}' | jq .
```

**Note:** Set `ADMIN_SETUP_SECRET` environment variable first.

---

### 5.2 Update User Subscription (Admin Only)
```bash
curl -X POST http://localhost:8000/walker/update_subscription \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "target_username": "testuser",
    "new_tier": "pro"
  }' | jq .
```

---

## Test Cards

| Card Number | Result |
|-------------|--------|
| `4242424242424242` | Success |
| `4000000000000002` | Declined |
| `4000000000009995` | Insufficient funds |

---

## Pricing

| Tier | Monthly | Annual (15% off) |
|------|---------|------------------|
| Free | $0 | $0 |
| Pro | $29 | $295 |
| Enterprise | $99 | $1,009 |

---

## Tier Limits

| Tier | Businesses | Daily Analyses |
|------|------------|----------------|
| Free | 5 | 10 |
| Pro | 50 | 100 |
| Enterprise | Unlimited | Unlimited |

---

## Complete End-to-End Example

```bash
# 1. Register
TOKEN=$(curl -s -X POST http://localhost:8000/user/register \
  -H "Content-Type: application/json" \
  -d '{"username": "newuser", "password": "Pass123!"}' | jq -r '.token')

# 2. Create profile with PRO tier intent
curl -X POST http://localhost:8000/walker/create_profile \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier_requested": "pro"}' | jq .

# 3. Initiate payment
PAYMENT_ID=$(curl -s -X POST http://localhost:8000/walker/initiate_payment \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"tier": "pro", "billing_interval": "monthly"}' | jq -r '.payment_id')

# 4. Process payment
curl -X POST http://localhost:8000/walker/process_payment \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "'$PAYMENT_ID'",
    "payment_method": {
      "card_number": "4242424242424242",
      "exp_month": 12,
      "exp_year": 2025,
      "cvc": "123"
    }
  }' | jq .

# 5. Verify profile
curl -X POST http://localhost:8000/walker/get_user_profile \
  -H "Authorization: Bearer $TOKEN" | jq .
```

---

## API Endpoints Summary

### Core Flow (4 endpoints)
| Endpoint | Description |
|----------|-------------|
| `POST /user/register` | Register new user (JAC built-in) |
| `POST /walker/create_profile` | Create profile with tier selection |
| `POST /walker/initiate_payment` | Start payment process |
| `POST /walker/process_payment` | Complete payment |

### Profile & Subscription (3 endpoints)
| Endpoint | Description |
|----------|-------------|
| `POST /walker/get_user_profile` | Get profile and limits |
| `POST /walker/get_subscription_details` | Get full subscription info |
| `POST /walker/schedule_downgrade` | Schedule tier downgrade |
| `POST /walker/cancel_subscription` | Cancel subscription |

### Admin (2 endpoints)
| Endpoint | Description |
|----------|-------------|
| `POST /walker/create_admin` | Setup admin account |
| `POST /walker/update_subscription` | Update user tier (admin only) |
