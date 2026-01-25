# ══════════════════════════════════════════════════════════════════════════════
# CREDIT MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Walkers for managing user credits
# 1 credit = 1 complete analysis (any review count)
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }
import from uuid { uuid4 }

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Get Credit Balance
# ═══════════════════════════════════════════════════════════════════════════════
# Returns current credit balance and usage statistics

walker:pub get_credit_balance {

    can fetch with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        profile = profiles[0];

        report success_response({
            "credits": {
                "available": profile.credits,
                "used": profile.credits_used
            },
            "note": "1 credit = 1 complete analysis"
        }, {});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Grant Credits (Admin Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Allows admins to grant credits to users (for promotions, compensation, etc.)

walker grant_credits {
    has target_username: str;
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
        if self.amount <= 0 {
            report validation_error("amount", "Amount must be positive");
            return;
        }

        # Find target user
        target_profiles = [-->(`?UserProfile)](?username == self.target_username);
        if not target_profiles {
            report not_found_error("user", self.target_username);
            return;
        }

        target = target_profiles[0];
        now = datetime.now();

        # Grant credits
        target.credits += self.amount;

        # Create transaction record
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=target.username,
            transaction_type="grant",
            amount=self.amount,
            balance_after=target.credits,
            description=self.reason,
            created_at=str(now)
        );
        here ++> txn;

        report success_response({
            "granted_to": self.target_username,
            "amount": self.amount,
            "reason": self.reason,
            "new_balance": target.credits,
            "transaction_id": txn.transaction_id
        }, {"message": f"Granted {self.amount} credits to {self.target_username}"});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Get Credit History
# ═══════════════════════════════════════════════════════════════════════════════
# Returns credit transaction history for the authenticated user

walker:pub get_credit_history {
    has limit: int = 20;
    has offset: int = 0;
    has transaction_type: str = "";  # Optional filter: "purchase", "usage", "grant", "refund"

    can fetch with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        # Get all credit transactions
        all_transactions = [-->(`?CreditTransaction)];

        # Filter by transaction type if specified
        if self.transaction_type and self.transaction_type in ["purchase", "usage", "grant", "refund"] {
            filtered = [];
            for txn in all_transactions {
                if txn.transaction_type == self.transaction_type {
                    filtered.append(txn);
                }
            }
            all_transactions = filtered;
        }

        # Sort by created_at (most recent first) - bubble sort
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
                "type": txn.transaction_type,
                "amount": txn.amount,
                "balance_after": txn.balance_after,
                "package": txn.package_name if txn.package_name else None,
                "description": txn.description,
                "date": txn.created_at
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
