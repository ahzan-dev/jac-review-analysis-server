# Frontend Changes - Credit Calculation Update

## Overview

The credit system has been updated from a flat rate (1 credit = 1 analysis) to a review-count based system (1 credit = up to 100 reviews).

---

## Credit Calculation Formula

```typescript
credits_required = Math.ceil(max_reviews / 100)
```

### Examples

| max_reviews | Credits Required |
|-------------|------------------|
| 50          | 1                |
| 100         | 1                |
| 101         | 2                |
| 200         | 2                |
| 250         | 3                |
| 500         | 5                |
| 1000        | 10               |

---

## Affected Walkers

| Walker | Impact | Action Required |
|--------|--------|-----------------|
| `AnalyzeUrl` | **HIGH** | Update response handling, add credit preview |
| `get_credit_balance` | LOW | Update note display |
| `get_credit_packages` | LOW | Update note display |

---

## 1. AnalyzeUrl Response Changes

### New Response Structure

```typescript
interface AnalyzeResponse {
  success: boolean;
  business: { ... };
  health_score: { ... };
  credits: {
    used: number;           // Variable based on reviews
    remaining: number;
    calculation: string;    // NEW FIELD - e.g., "200 reviews = 2 credit(s)"
  };
  cache_info: { ... };
}
```

### Before (Old)
```json
"credits": {
  "used": 1,
  "remaining": 11
}
```

### After (New)
```json
"credits": {
  "used": 2,
  "remaining": 10,
  "calculation": "200 reviews = 2 credit(s)"
}
```

---

## 2. Required Frontend Changes

### 2.1 Add Credit Calculator Utility

```typescript
// utils/creditCalculator.ts

/**
 * Calculate credits required for an analysis
 * @param maxReviews - Number of reviews to analyze
 * @returns Number of credits required
 */
export function calculateCreditsRequired(maxReviews: number): number {
  return Math.ceil(maxReviews / 100);
}

/**
 * Calculate cost in dollars
 * @param credits - Number of credits
 * @param pricePerCredit - Price per credit (default $5 for Bronze rate)
 * @returns Cost in dollars
 */
export function calculateCost(credits: number, pricePerCredit: number = 5): number {
  return credits * pricePerCredit;
}

/**
 * Get credit breakdown for display
 */
export function getCreditBreakdown(maxReviews: number): {
  reviews: number;
  credits: number;
  cost: number;
  description: string;
} {
  const credits = calculateCreditsRequired(maxReviews);
  return {
    reviews: maxReviews,
    credits,
    cost: calculateCost(credits),
    description: `${maxReviews} reviews = ${credits} credit${credits > 1 ? 's' : ''}`
  };
}
```

### 2.2 Update TypeScript Interfaces

```typescript
// types/api.ts

// Update CreditsInfo interface
interface CreditsInfo {
  used: number;
  remaining: number;
  calculation: string;  // NEW - add this field
}

// Update AnalyzeResponse
interface AnalyzeResponse {
  success: boolean;
  business: BusinessInfo;
  health_score: HealthScore;
  themes: Theme[];
  executive_summary: ExecutiveSummary;
  recommendations: Recommendations;
  credits: CreditsInfo;  // Updated interface
  cache_info: CacheInfo;
}

// Credit balance response (note text changed)
interface CreditBalanceResponse {
  success: boolean;
  data: {
    credits: {
      available: number;
      used: number;
    };
    note: string;  // Now: "1 credit = up to 100 reviews. Formula: ceil(reviews / 100)"
  };
  timestamp: string;
}
```

### 2.3 Analysis Form - Add Credit Preview

```tsx
// components/AnalysisForm.tsx

import { calculateCreditsRequired } from '@/utils/creditCalculator';

function AnalysisForm({ userCredits }: { userCredits: number }) {
  const [maxReviews, setMaxReviews] = useState(100);

  const creditsRequired = calculateCreditsRequired(maxReviews);
  const hasEnoughCredits = userCredits >= creditsRequired;

  return (
    <form>
      {/* URL Input */}
      <input type="url" name="url" placeholder="Google Maps URL" required />

      {/* Review Count Selector */}
      <div>
        <label>Reviews to Analyze</label>
        <select
          value={maxReviews}
          onChange={(e) => setMaxReviews(Number(e.target.value))}
        >
          <option value={50}>50 reviews (1 credit)</option>
          <option value={100}>100 reviews (1 credit)</option>
          <option value={200}>200 reviews (2 credits)</option>
          <option value={500}>500 reviews (5 credits)</option>
          <option value={1000}>1000 reviews (10 credits)</option>
        </select>
      </div>

      {/* Credit Cost Preview */}
      <div className="credit-preview">
        <p>
          <strong>Cost:</strong> {creditsRequired} credit{creditsRequired > 1 ? 's' : ''}
        </p>
        <p>
          <strong>Your Balance:</strong> {userCredits} credits
        </p>
        {!hasEnoughCredits && (
          <p className="error">
            Insufficient credits. You need {creditsRequired - userCredits} more credit(s).
          </p>
        )}
      </div>

      <button type="submit" disabled={!hasEnoughCredits}>
        Analyze ({creditsRequired} credit{creditsRequired > 1 ? 's' : ''})
      </button>
    </form>
  );
}
```

### 2.4 Update Analysis Result Display

```tsx
// components/AnalysisResult.tsx

function AnalysisResult({ result }: { result: AnalyzeResponse }) {
  return (
    <div>
      {/* ... other result sections ... */}

      {/* Credits Used Section */}
      <div className="credits-used">
        <h4>Credits</h4>
        <p><strong>Used:</strong> {result.credits.used}</p>
        <p><strong>Remaining:</strong> {result.credits.remaining}</p>
        <p className="calculation">{result.credits.calculation}</p>
      </div>
    </div>
  );
}
```

### 2.5 Update Pricing Page

```tsx
// pages/Pricing.tsx

function PricingPage() {
  return (
    <div>
      <h1>Credit Packages</h1>

      {/* Credit Explanation */}
      <div className="credit-explanation">
        <h3>How Credits Work</h3>
        <p><strong>1 credit = up to 100 reviews analyzed</strong></p>
        <p>Formula: credits = ceil(reviews / 100)</p>

        <table>
          <thead>
            <tr>
              <th>Reviews</th>
              <th>Credits Needed</th>
            </tr>
          </thead>
          <tbody>
            <tr><td>1-100</td><td>1 credit</td></tr>
            <tr><td>101-200</td><td>2 credits</td></tr>
            <tr><td>201-300</td><td>3 credits</td></tr>
            <tr><td>500</td><td>5 credits</td></tr>
            <tr><td>1000</td><td>10 credits</td></tr>
          </tbody>
        </table>
      </div>

      {/* Package Cards */}
      <div className="packages">
        {/* Bronze, Silver, Gold, Platinum packages */}
      </div>
    </div>
  );
}
```

### 2.6 Credit Balance Component Update

```tsx
// components/CreditBalance.tsx

function CreditBalance({ balance }: { balance: CreditBalanceResponse }) {
  return (
    <div className="credit-balance">
      <div className="credits">
        <span className="available">{balance.data.credits.available}</span>
        <span className="label">credits available</span>
      </div>

      <div className="used">
        <span>{balance.data.credits.used} used lifetime</span>
      </div>

      {/* Display the note from API */}
      <p className="note">{balance.data.note}</p>
    </div>
  );
}
```

---

## 3. Insufficient Credits Error Handling

### Error Response Format

```json
{
  "success": false,
  "error": {
    "code": "INSUFFICIENT_CREDITS",
    "message": "Insufficient credits: need 5, have 2",
    "details": {
      "required": 5,
      "available": 2,
      "shortage": 3,
      "action": "Purchase a credit package to continue"
    }
  }
}
```

### Error Handler Update

```tsx
// hooks/useAnalysis.ts

function handleAnalysisError(error: ApiError) {
  if (error.code === 'INSUFFICIENT_CREDITS') {
    const { required, available, shortage } = error.details;

    // Show modal with purchase prompt
    showInsufficientCreditsModal({
      required,
      available,
      shortage,
      suggestedPackage: getSuggestedPackage(shortage)
    });
  }
}

function getSuggestedPackage(creditsNeeded: number): string {
  if (creditsNeeded <= 1) return 'bronze';
  if (creditsNeeded <= 5) return 'silver';
  if (creditsNeeded <= 12) return 'gold';
  return 'platinum';
}
```

---

## 4. Review Count Selector Options

```tsx
// Recommended review count options with credit costs

const REVIEW_OPTIONS = [
  { value: 50, label: '50 reviews', credits: 1 },
  { value: 100, label: '100 reviews', credits: 1 },
  { value: 200, label: '200 reviews', credits: 2 },
  { value: 300, label: '300 reviews', credits: 3 },
  { value: 500, label: '500 reviews', credits: 5 },
  { value: 1000, label: '1000 reviews', credits: 10 },
];

// Usage in select
<select>
  {REVIEW_OPTIONS.map(opt => (
    <option key={opt.value} value={opt.value}>
      {opt.label} ({opt.credits} credit{opt.credits > 1 ? 's' : ''})
    </option>
  ))}
</select>
```

---

## 5. API Service Updates

```typescript
// services/api.ts

// No changes needed to API calls themselves
// Just update response type handling

export async function analyzeUrl(
  token: string,
  url: string,
  maxReviews: number = 100
): Promise<AnalyzeResponse> {
  const response = await fetch(`${BASE_URL}/walker/AnalyzeUrl`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      url,
      max_reviews: maxReviews,
      analysis_depth: 'deep',
    }),
  });

  const json = await response.json();
  return json.data.reports[0];  // Extract from reports[0]
}
```

---

## 6. State Management Updates (if using Redux/Zustand)

```typescript
// store/creditSlice.ts

interface CreditState {
  available: number;
  used: number;
  note: string;
}

// Action to update after analysis
function updateCreditsAfterAnalysis(
  state: CreditState,
  creditsUsed: number
): CreditState {
  return {
    ...state,
    available: state.available - creditsUsed,
    used: state.used + creditsUsed,
  };
}
```

---

## 7. Testing Checklist

- [ ] Credit calculator returns correct values for all review counts
- [ ] Analysis form shows correct credit preview
- [ ] Submit button disabled when insufficient credits
- [ ] Analysis result displays `calculation` field
- [ ] Insufficient credits error shows correct shortage amount
- [ ] Pricing page shows correct credit-to-review mapping
- [ ] Credit balance updates correctly after analysis

---

## 8. UI/UX Recommendations

1. **Always show credit cost before analysis** - Users should know the cost upfront
2. **Disable analyze button if insufficient credits** - Prevent failed API calls
3. **Show credit calculation breakdown** - Display the formula result
4. **Suggest appropriate package** - When user has insufficient credits
5. **Update balance immediately** - Reflect credit deduction in UI right away

---

## Summary of Changes

| Component | Change |
|-----------|--------|
| Credit calculator utility | **NEW** - Add `calculateCreditsRequired()` |
| TypeScript interfaces | Update `CreditsInfo` to include `calculation` |
| Analysis form | Add credit cost preview based on review count |
| Analysis result | Display `credits.calculation` field |
| Pricing page | Add credit-to-review mapping table |
| Error handling | Handle variable credit requirements in errors |
| State management | Update credit tracking after analysis |
