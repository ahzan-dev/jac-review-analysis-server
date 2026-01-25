# ══════════════════════════════════════════════════════════════════════════════
# CREDIT MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Walkers for managing user credits (fetch + analysis)
# Credits are the usage-based billing units for SerpAPI and OpenAI calls
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }
import from uuid { uuid4 }
import math;

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Get Credit Balance
# ═══════════════════════════════════════════════════════════════════════════════
# Returns current credit balances and usage statistics

walker:pub get_credit_balance {

    can fetch with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        profile = profiles[0];

        # Calculate estimated analyses remaining
        # Using formula: fetch = ceil(100/15)+1 = 8, analysis = ceil(100/5)+3 = 23
        # For 100 review analysis
        fetch_per_analysis = 8;  # ~100 reviews
        analysis_per_analysis = 23;  # ~100 reviews

        max_analyses_by_fetch = int(profile.fetch_credits / fetch_per_analysis) if fetch_per_analysis > 0 else 0;
        max_analyses_by_analysis = int(profile.analysis_credits / analysis_per_analysis) if analysis_per_analysis > 0 else 0;
        estimated_analyses = min(max_analyses_by_fetch, max_analyses_by_analysis);

        report success_response({
            "credits": {
                "fetch_credits": profile.fetch_credits,
                "analysis_credits": profile.analysis_credits
            },
            "usage": {
                "fetch_credits_used": profile.fetch_credits_used,
                "analysis_credits_used": profile.analysis_credits_used
            },
            "estimates": {
                "analyses_remaining": estimated_analyses,
                "note": "Estimated 100-review analyses remaining (actual varies by review count)"
            },
            "tier": profile.subscription_tier.value
        }, {});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Purchase Credits
# ═══════════════════════════════════════════════════════════════════════════════
# Allows users to purchase additional credits (overage)
# Uses dummy payment processing (same as process_payment)

walker:pub purchase_credits {
    has credit_type: str;  # "fetch" or "analysis"
    has amount: int;       # Number of credits to purchase
    has payment_method: dict;  # {card_number, exp_month, exp_year, cvc}

    can purchase with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        profile = profiles[0];

        # Validate credit type
        if self.credit_type not in ["fetch", "analysis"] {
            report validation_error("credit_type", "Must be 'fetch' or 'analysis'");
            return;
        }

        # Validate amount
        if self.amount < 10 {
            report validation_error("amount", "Minimum purchase is 10 credits");
            return;
        }

        # Get overage pricing based on tier
        tier = profile.subscription_tier.value;
        overage_pricing = CREDIT_OVERAGE_PRICING.get(tier, CREDIT_OVERAGE_PRICING["free"]);

        if self.credit_type == "fetch" {
            price_per_credit = overage_pricing["fetch_credit"];
        } else {
            price_per_credit = overage_pricing["analysis_credit"];
        }

        total_price = round(self.amount * price_per_credit, 2);

        # Validate card (dummy validation)
        card = self.payment_method;
        if not card.get("card_number") or len(card.get("card_number", "")) < 15 {
            report error_response(ErrorCode.PAYMENT_FAILED, "Invalid card number", {});
            return;
        }

        card_number = card["card_number"];

        # Test card validation (Stripe-like)
        if card_number == "4000000000000002" {
            report error_response(ErrorCode.CARD_DECLINED, "Card declined", {"decline_code": "generic_decline"});
            return;
        }

        if card_number == "4000000000009995" {
            report error_response(ErrorCode.INSUFFICIENT_FUNDS, "Insufficient funds", {"decline_code": "insufficient_funds"});
            return;
        }

        # Process payment success - grant credits
        now = datetime.now();

        if self.credit_type == "fetch" {
            profile.fetch_credits += self.amount;
            new_balance = profile.fetch_credits;
        } else {
            profile.analysis_credits += self.amount;
            new_balance = profile.analysis_credits;
        }

        # Create credit transaction
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="purchase",
            credit_type=self.credit_type,
            amount=self.amount,
            balance_after=new_balance,
            description=f"Purchased {self.amount} {self.credit_type} credits for ${total_price}",
            created_at=str(now)
        );
        here ++> txn;

        report success_response({
            "purchase": {
                "credit_type": self.credit_type,
                "amount": self.amount,
                "price_per_credit": price_per_credit,
                "total_price": total_price,
                "currency": "USD"
            },
            "new_balance": {
                "fetch_credits": profile.fetch_credits,
                "analysis_credits": profile.analysis_credits
            },
            "transaction_id": txn.transaction_id
        }, {"message": f"Successfully purchased {self.amount} {self.credit_type} credits"});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Grant Credits (Admin Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Allows admins to grant credits to users (for promotions, monthly allocations, etc.)

walker grant_credits {
    has target_username: str;
    has credit_type: str;  # "fetch" or "analysis"
    has amount: int;
    has reason: str = "Admin grant";

    can grant with `root entry {
        # Check admin permission
        my_profiles = [-->(`?UserProfile)];
        if not my_profiles or my_profiles[0].role != UserRole.ADMIN {
            report unauthorized_error("Admin access required");
            return;
        }

        # Validate inputs
        if self.credit_type not in ["fetch", "analysis"] {
            report validation_error("credit_type", "Must be 'fetch' or 'analysis'");
            return;
        }

        if self.amount <= 0 {
            report validation_error("amount", "Amount must be positive");
            return;
        }

        # Find target user - in JAC, each user has their own root
        # For admin operations, we need to search for the user
        # This is a simplified approach - in production you'd use JAC's multi-tenant features
        target_profiles = [-->(`?UserProfile)](?username == self.target_username);
        if not target_profiles {
            report not_found_error("user", self.target_username);
            return;
        }

        target = target_profiles[0];
        now = datetime.now();

        # Grant credits
        if self.credit_type == "fetch" {
            target.fetch_credits += self.amount;
            new_balance = target.fetch_credits;
        } else {
            target.analysis_credits += self.amount;
            new_balance = target.analysis_credits;
        }

        # Create transaction record
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=target.username,
            transaction_type="grant",
            credit_type=self.credit_type,
            amount=self.amount,
            balance_after=new_balance,
            description=self.reason,
            created_at=str(now)
        );
        here ++> txn;

        report success_response({
            "granted_to": self.target_username,
            "credit_type": self.credit_type,
            "amount": self.amount,
            "reason": self.reason,
            "new_balance": new_balance,
            "transaction_id": txn.transaction_id
        }, {"message": f"Granted {self.amount} {self.credit_type} credits to {self.target_username}"});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 4: Get Credit History
# ═══════════════════════════════════════════════════════════════════════════════
# Returns credit transaction history for the authenticated user

walker:pub get_credit_history {
    has limit: int = 20;
    has offset: int = 0;
    has credit_type: str = "";  # Optional filter: "fetch" or "analysis"

    can fetch with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        # Get all credit transactions
        all_transactions = [-->(`?CreditTransaction)];

        # Filter by credit type if specified
        if self.credit_type and self.credit_type in ["fetch", "analysis"] {
            filtered = [];
            for txn in all_transactions {
                if txn.credit_type == self.credit_type {
                    filtered.append(txn);
                }
            }
            all_transactions = filtered;
        }

        # Sort by created_at (most recent first)
        # Simple bubble sort since JAC doesn't have built-in sort
        n = len(all_transactions);
        for i in range(n) {
            for j in range(0, n - i - 1) {
                if all_transactions[j].created_at < all_transactions[j + 1].created_at {
                    temp = all_transactions[j];
                    all_transactions[j] = all_transactions[j + 1];
                    all_transactions[j + 1] = temp;
                }
            }
        }

        # Apply pagination
        total = len(all_transactions);
        start_idx = min(self.offset, total);
        end_idx = min(self.offset + self.limit, total);
        paginated = all_transactions[start_idx:end_idx];

        # Format transactions
        transactions = [];
        for txn in paginated {
            transactions.append({
                "transaction_id": txn.transaction_id,
                "transaction_type": txn.transaction_type,
                "credit_type": txn.credit_type,
                "amount": txn.amount,
                "balance_after": txn.balance_after,
                "description": txn.description,
                "created_at": txn.created_at
            });
        }

        report success_response({
            "transactions": transactions,
            "pagination": {
                "total": total,
                "limit": self.limit,
                "offset": self.offset,
                "has_more": end_idx < total
            }
        }, {});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 5: Estimate Credits
# ═══════════════════════════════════════════════════════════════════════════════
# Estimates credits needed for a given number of reviews

walker:pub estimate_credits {
    has review_count: int = 100;

    can estimate with `root entry {
        # Formula from plan:
        # fetch_credits = ceil(reviews / 15) + 1
        # analysis_credits = ceil(reviews / 5) + 3

        fetch_needed = int(math.ceil(self.review_count / 15.0)) + 1;
        analysis_needed = int(math.ceil(self.review_count / 5.0)) + 3;

        # Get user's current balance if authenticated
        profiles = [-->(`?UserProfile)];
        has_enough = False;
        current_balance = {};

        if profiles {
            profile = profiles[0];
            current_balance = {
                "fetch_credits": profile.fetch_credits,
                "analysis_credits": profile.analysis_credits
            };
            has_enough = (profile.fetch_credits >= fetch_needed and
                         profile.analysis_credits >= analysis_needed);
        }

        # Get pricing
        tier = profiles[0].subscription_tier.value if profiles else "free";
        overage = CREDIT_OVERAGE_PRICING.get(tier, CREDIT_OVERAGE_PRICING["free"]);

        estimated_cost = {
            "fetch_cost": round(fetch_needed * overage["fetch_credit"], 2),
            "analysis_cost": round(analysis_needed * overage["analysis_credit"], 2),
            "total_cost": round(fetch_needed * overage["fetch_credit"] + analysis_needed * overage["analysis_credit"], 2)
        };

        report success_response({
            "review_count": self.review_count,
            "credits_needed": {
                "fetch_credits": fetch_needed,
                "analysis_credits": analysis_needed
            },
            "estimated_cost_if_purchased": estimated_cost,
            "current_balance": current_balance if current_balance else None,
            "has_sufficient_credits": has_enough
        }, {"formula": "fetch = ceil(reviews/15)+1, analysis = ceil(reviews/5)+3"});
    }
}
