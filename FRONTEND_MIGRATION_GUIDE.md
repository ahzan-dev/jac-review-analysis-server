# Frontend Migration Guide: Credit Package System

This guide documents the changes needed to migrate the frontend from a subscription-based model to the new credit package system.

## Overview of Changes

| Aspect | Before | After |
|--------|--------|-------|
| Pricing Model | Subscription tiers (FREE/PRO/ENTERPRISE) | Credit packages (Bronze/Silver/Gold/Platinum) |
| Credit Types | 2 (fetch_credits + analysis_credits) | 1 (unified credits) |
| Monthly Fees | $0/$29/$99 | None |
| Daily Limits | 10/100/unlimited | None |
| Business Limits | 5/50/unlimited | None |
| Cost per Analysis | Complex formula | Fixed (1 credit) |

---

## API Endpoint Changes

### Removed Endpoints

Remove all calls to these endpoints:

```
POST /walker/initiate_payment      # Subscription payment intent
POST /walker/process_payment       # Subscription payment processing
POST /walker/get_subscription_details
POST /walker/schedule_downgrade
POST /walker/cancel_subscription
```

### New Endpoints

#### 1. Get Credit Packages

```http
POST /walker/get_credit_packages
```

**Request:** No body required

**Response:**
```json
{
  "success": true,
  "data": {
    "packages": [
      {
        "id": "bronze",
        "name": "Bronze",
        "credits": 1,
        "price": 5.0,
        "currency": "USD",
        "price_per_credit": 5.0
      },
      {
        "id": "silver",
        "name": "Silver",
        "credits": 5,
        "price": 22.0,
        "currency": "USD",
        "price_per_credit": 4.4
      },
      {
        "id": "gold",
        "name": "Gold",
        "credits": 12,
        "price": 48.0,
        "currency": "USD",
        "price_per_credit": 4.0
      },
      {
        "id": "platinum",
        "name": "Platinum",
        "credits": 30,
        "price": 110.0,
        "currency": "USD",
        "price_per_credit": 3.67
      }
    ],
    "note": "1 credit = 1 complete analysis (any review count)"
  }
}
```

#### 2. Purchase Credit Package

```http
POST /walker/purchase_credit_package
```

**Request:**
```json
{
  "package": "gold",
  "payment_method": {
    "card_number": "4242424242424242",
    "exp_month": 12,
    "exp_year": 2025,
    "cvc": "123"
  }
}
```

**Success Response:**
```json
{
  "success": true,
  "data": {
    "purchase": {
      "package": "gold",
      "package_name": "Gold",
      "credits_added": 12,
      "price": 48.0,
      "currency": "USD"
    },
    "balance": {
      "credits": 15
    },
    "transaction_id": "uuid-here"
  },
  "metadata": {
    "message": "Successfully purchased Gold package! 12 credits added."
  }
}
```

**Error Responses:**

```json
// Invalid package
{
  "success": false,
  "error": {
    "code": "INVALID_PACKAGE",
    "message": "Invalid package: diamond",
    "details": {
      "valid_packages": ["bronze", "silver", "gold", "platinum"]
    }
  }
}

// Card declined
{
  "success": false,
  "error": {
    "code": "CARD_DECLINED",
    "message": "Card declined",
    "details": {
      "decline_code": "generic_decline"
    }
  }
}

// Insufficient funds
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_FUNDS",
    "message": "Insufficient funds",
    "details": {
      "decline_code": "insufficient_funds"
    }
  }
}
```

#### 3. Get Payment History

```http
POST /walker/get_payment_history
```

**Request:**
```json
{
  "limit": 20,
  "offset": 0
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "purchases": [
      {
        "transaction_id": "uuid-here",
        "package": "gold",
        "credits": 12,
        "description": "Purchased Gold package (12 credits) for $48.0",
        "date": "2024-01-15T10:30:00"
      }
    ],
    "pagination": {
      "total": 5,
      "limit": 20,
      "offset": 0,
      "has_more": false
    }
  }
}
```

### Modified Endpoints

#### 1. Get User Profile

```http
POST /walker/get_user_profile
```

**Old Response (REMOVE):**
```json
{
  "success": true,
  "role": "user",
  "subscription": {
    "tier": "pro",
    "status": "active",
    "pending_upgrade": ""
  },
  "limits": {
    "max_businesses": 50,
    "current_businesses": 3,
    "remaining_businesses": 47,
    "daily_analysis_limit": 100,
    "analyses_today": 5,
    "remaining_today": 95
  },
  "credits": {
    "fetch_credits": 450,
    "analysis_credits": 1800,
    "fetch_credits_used": 50,
    "analysis_credits_used": 200
  }
}
```

**New Response:**
```json
{
  "success": true,
  "role": "user",
  "credits": {
    "available": 15,
    "used": 7
  },
  "businesses_count": 3,
  "is_active": true
}
```

#### 2. Get Credit Balance

```http
POST /walker/get_credit_balance
```

**Old Response (REMOVE):**
```json
{
  "credits": {
    "fetch_credits": 450,
    "analysis_credits": 1800
  },
  "usage": {
    "fetch_credits_used": 50,
    "analysis_credits_used": 200
  },
  "estimates": {
    "analyses_remaining": 64,
    "note": "Estimated 100-review analyses remaining"
  },
  "tier": "pro"
}
```

**New Response:**
```json
{
  "success": true,
  "data": {
    "credits": {
      "available": 15,
      "used": 7
    },
    "note": "1 credit = 1 complete analysis"
  }
}
```

#### 3. AnalyzeUrl Response

**Old Response Fields (REMOVE):**
```json
{
  "usage": {
    "analyses_today": 5,
    "daily_limit": 100,
    "businesses_count": 3,
    "business_limit": 50,
    "tier": "pro"
  },
  "credits_used": {
    "fetch_credits": 7,
    "analysis_credits": 23
  },
  "credits_remaining": {
    "fetch_credits": 443,
    "analysis_credits": 1777
  }
}
```

**New Response Fields:**
```json
{
  "credits": {
    "used": 1,
    "remaining": 14
  },
  "cache_info": {
    "from_cache": false,
    "message": "Fresh data fetched from API"
  }
}
```

#### 4. Insufficient Credits Error

**Old Error:**
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_CREDITS",
    "message": "Insufficient fetch credits: need 7, have 3",
    "details": {
      "credit_type": "fetch",
      "required": 7,
      "available": 3,
      "shortage": 4,
      "action": "Purchase more credits or upgrade your plan"
    }
  }
}
```

**New Error:**
```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_CREDITS",
    "message": "Insufficient credits: need 1, have 0",
    "details": {
      "required": 1,
      "available": 0,
      "shortage": 1,
      "action": "Purchase a credit package to continue"
    }
  }
}
```

---

## UI Component Changes

### 1. Remove These Components/Pages

- `SubscriptionTierSelector` - Tier selection (FREE/PRO/ENTERPRISE)
- `BillingIntervalToggle` - Monthly/Annual toggle
- `SubscriptionUpgradeModal` - Upgrade flow
- `SubscriptionDowngradeModal` - Downgrade flow
- `CancelSubscriptionModal` - Cancellation flow
- `DailyLimitDisplay` - Analyses remaining today
- `BusinessLimitDisplay` - Businesses remaining
- `TierBadge` - PRO/ENTERPRISE badge
- `FetchCreditsDisplay` - Separate fetch credits
- `AnalysisCreditsDisplay` - Separate analysis credits

### 2. Add These Components

#### CreditPackageSelector

```tsx
interface CreditPackage {
  id: string;
  name: string;
  credits: number;
  price: number;
  currency: string;
  price_per_credit: number;
}

const CreditPackageSelector = () => {
  const [packages, setPackages] = useState<CreditPackage[]>([]);
  const [selectedPackage, setSelectedPackage] = useState<string | null>(null);

  useEffect(() => {
    // Fetch packages from API
    api.post('/walker/get_credit_packages').then(res => {
      setPackages(res.data.data.packages);
    });
  }, []);

  return (
    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
      {packages.map(pkg => (
        <PackageCard
          key={pkg.id}
          package={pkg}
          selected={selectedPackage === pkg.id}
          onSelect={() => setSelectedPackage(pkg.id)}
          savings={pkg.id !== 'bronze' ?
            `Save $${(5 - pkg.price_per_credit).toFixed(2)}/analysis` : null}
        />
      ))}
    </div>
  );
};
```

#### CreditBalanceDisplay

```tsx
interface CreditBalance {
  available: number;
  used: number;
}

const CreditBalanceDisplay = ({ credits }: { credits: CreditBalance }) => {
  return (
    <div className="flex items-center gap-4">
      <div className="text-center">
        <div className="text-3xl font-bold">{credits.available}</div>
        <div className="text-sm text-muted-foreground">Credits Available</div>
      </div>
      <div className="text-center">
        <div className="text-xl text-muted-foreground">{credits.used}</div>
        <div className="text-sm text-muted-foreground">Total Used</div>
      </div>
    </div>
  );
};
```

#### PurchaseModal

```tsx
const PurchaseModal = ({
  package: pkg,
  onSuccess,
  onClose
}: {
  package: CreditPackage;
  onSuccess: (credits: number) => void;
  onClose: () => void;
}) => {
  const [cardNumber, setCardNumber] = useState('');
  const [expMonth, setExpMonth] = useState('');
  const [expYear, setExpYear] = useState('');
  const [cvc, setCvc] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handlePurchase = async () => {
    setLoading(true);
    setError(null);

    try {
      const res = await api.post('/walker/purchase_credit_package', {
        package: pkg.id,
        payment_method: {
          card_number: cardNumber,
          exp_month: parseInt(expMonth),
          exp_year: parseInt(expYear),
          cvc
        }
      });

      if (res.data.success) {
        onSuccess(res.data.data.balance.credits);
        onClose();
      } else {
        setError(res.data.error.message);
      }
    } catch (err) {
      setError('Payment failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Dialog open onOpenChange={onClose}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Purchase {pkg.name} Package</DialogTitle>
          <DialogDescription>
            {pkg.credits} credits for ${pkg.price}
          </DialogDescription>
        </DialogHeader>

        {/* Payment form fields */}
        <div className="space-y-4">
          <Input
            placeholder="Card Number"
            value={cardNumber}
            onChange={e => setCardNumber(e.target.value)}
          />
          <div className="grid grid-cols-3 gap-2">
            <Input placeholder="MM" value={expMonth} onChange={e => setExpMonth(e.target.value)} />
            <Input placeholder="YYYY" value={expYear} onChange={e => setExpYear(e.target.value)} />
            <Input placeholder="CVC" value={cvc} onChange={e => setCvc(e.target.value)} />
          </div>

          {error && <Alert variant="destructive">{error}</Alert>}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={onClose}>Cancel</Button>
          <Button onClick={handlePurchase} disabled={loading}>
            {loading ? 'Processing...' : `Pay $${pkg.price}`}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
};
```

### 3. Modify These Components

#### Dashboard/Profile Page

**Before:**
```tsx
<div>
  <TierBadge tier={profile.subscription.tier} />
  <div>Daily Analyses: {profile.limits.remaining_today} / {profile.limits.daily_analysis_limit}</div>
  <div>Businesses: {profile.limits.current_businesses} / {profile.limits.max_businesses}</div>
  <div>Fetch Credits: {profile.credits.fetch_credits}</div>
  <div>Analysis Credits: {profile.credits.analysis_credits}</div>
</div>
```

**After:**
```tsx
<div>
  <CreditBalanceDisplay credits={profile.credits} />
  <div>Businesses Analyzed: {profile.businesses_count}</div>
  <Button onClick={() => setShowPurchaseModal(true)}>
    Buy Credits
  </Button>
</div>
```

#### Analysis Result Display

**Before:**
```tsx
<div className="credits-used">
  <div>Fetch Credits Used: {result.credits_used.fetch_credits}</div>
  <div>Analysis Credits Used: {result.credits_used.analysis_credits}</div>
  <div>Remaining: {result.credits_remaining.fetch_credits} fetch, {result.credits_remaining.analysis_credits} analysis</div>
</div>
```

**After:**
```tsx
<div className="credits-used">
  <div>Credits Used: {result.credits.used}</div>
  <div>Credits Remaining: {result.credits.remaining}</div>
</div>
```

#### Insufficient Credits Handler

**Before:**
```tsx
if (error.code === 'INSUFFICIENT_CREDITS') {
  if (error.details.credit_type === 'fetch') {
    showModal('You need more fetch credits. Upgrade your plan.');
  } else {
    showModal('You need more analysis credits. Upgrade your plan.');
  }
}
```

**After:**
```tsx
if (error.code === 'INSUFFICIENT_CREDITS') {
  showModal(
    'Not enough credits',
    `You need ${error.details.required} credit(s) but have ${error.details.available}. Purchase a credit package to continue.`,
    <Button onClick={() => navigate('/pricing')}>Buy Credits</Button>
  );
}
```

---

## State Management Changes

### Remove from Global State

```typescript
// Remove these from your auth/user store
interface OldUserState {
  subscription: {
    tier: 'free' | 'pro' | 'enterprise';
    status: string;
    pending_upgrade: string;
    billing_interval: string;
  };
  limits: {
    max_businesses: number;
    daily_analysis_limit: number;
    analyses_today: number;
  };
  credits: {
    fetch_credits: number;
    analysis_credits: number;
    fetch_credits_used: number;
    analysis_credits_used: number;
  };
}
```

### New User State

```typescript
interface UserState {
  role: 'user' | 'admin';
  credits: {
    available: number;
    used: number;
  };
  businesses_count: number;
  is_active: boolean;
}
```

---

## Routing Changes

### Remove Routes

```
/pricing           # Old tier comparison page
/upgrade           # Upgrade flow
/downgrade         # Downgrade flow
/subscription      # Subscription management
/billing           # Monthly billing page
```

### Add/Modify Routes

```
/pricing           # Credit package selection (repurpose)
/purchase          # Purchase flow
/credits           # Credit balance & history
```

---

## Test Cards (Development)

| Card Number | Result |
|-------------|--------|
| 4242424242424242 | Success |
| 4000000000000002 | Card declined |
| 4000000000009995 | Insufficient funds |

---

## Migration Checklist

- [ ] Remove subscription tier UI components
- [ ] Remove daily/business limit displays
- [ ] Remove fetch_credits/analysis_credits displays
- [ ] Add credit package selector component
- [ ] Add single credit balance display
- [ ] Update API service layer for new endpoints
- [ ] Update user state management
- [ ] Update error handling for new error format
- [ ] Update analysis result display
- [ ] Add purchase history page
- [ ] Update pricing page with packages
- [ ] Remove upgrade/downgrade flows
- [ ] Test purchase flow with test cards
- [ ] Update insufficient credits error handling
