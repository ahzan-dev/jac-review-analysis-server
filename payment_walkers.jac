# ══════════════════════════════════════════════════════════════════════════════
# CREDIT PACKAGE PURCHASE WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Payment processing for credit packages
# Test cards: 4242424242424242 (success), 4000000000000002 (declined)
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }
import from uuid { uuid4 }

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Get Credit Packages
# ═══════════════════════════════════════════════════════════════════════════════
# Returns available credit packages with pricing

walker :pub get_credit_packages {

    can fetch with Root entry {
        packages = [];
        for (key, pkg) in CREDIT_PACKAGES.items() {
            per_credit = round(pkg["price"] / pkg["credits"], 2);
            packages.append({
                "id": key,
                "name": pkg["name"],
                "credits": pkg["credits"],
                "price": pkg["price"],
                "currency": "USD",
                "price_per_credit": per_credit
            });
        }

        # Sort by credits ascending (bubble sort)
        n = len(packages);
        for i in range(n) {
            for j in range(0, n - i - 1) {
                if packages[j]["credits"] > packages[j + 1]["credits"] {
                    temp = packages[j];
                    packages[j] = packages[j + 1];
                    packages[j + 1] = temp;
                }
            }
        }

        report success_response({
            "packages": packages,
            "note": "1 credit = up to 100 reviews. Formula: ceil(reviews / 100)"
        }, {});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Purchase Credit Package
# ═══════════════════════════════════════════════════════════════════════════════
# Processes payment for a credit package and grants credits

walker :pub purchase_credit_package {
    has package: str;  # "bronze", "silver", "gold", "platinum"
    has payment_method: dict;  # {card_number, exp_month, exp_year, cvc}

    can purchase with Root entry {
        # Get user profile
        profiles = [-->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        profile = profiles[0];

        # Validate package
        if self.package not in CREDIT_PACKAGES.keys() {
            report error_response(
                ErrorCode.INVALID_PACKAGE,
                f"Invalid package: {self.package}",
                {"valid_packages": list(CREDIT_PACKAGES.keys())}
            );
            return;
        }

        pkg = CREDIT_PACKAGES[self.package];
        credits_to_add = pkg["credits"];
        price = pkg["price"];

        # Validate card (dummy validation)
        card = self.payment_method;
        if not card.get("card_number") or len(card.get("card_number", "")) < 15 {
            report error_response(ErrorCode.PAYMENT_FAILED, "Invalid card number", {});
            return;
        }

        card_number = card["card_number"];

        # Test card validation (Stripe-like)
        if card_number == "4000000000000002" {
            report error_response(
                ErrorCode.CARD_DECLINED,
                "Card declined",
                {"decline_code": "generic_decline"}
            );
            return;
        }

        if card_number == "4000000000009995" {
            report error_response(
                ErrorCode.INSUFFICIENT_FUNDS,
                "Insufficient funds",
                {"decline_code": "insufficient_funds"}
            );
            return;
        }

        # Payment successful - grant credits
        now = datetime.now();
        profile.credits += credits_to_add;
        profile.last_payment_date = str(now);

        # Create credit transaction
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="purchase",
            amount=credits_to_add,
            balance_after=profile.credits,
            package_name=self.package,
            description=f"Purchased {pkg['name']} package ({credits_to_add} credits) for ${price}",
            created_at=str(now)
        );
        here ++> txn;

        report success_response({
            "purchase": {
                "package": self.package,
                "package_name": pkg["name"],
                "credits_added": credits_to_add,
                "price": price,
                "currency": "USD"
            },
            "balance": {
                "credits": profile.credits
            },
            "transaction_id": txn.transaction_id
        }, {"message": f"Successfully purchased {pkg['name']} package! {credits_to_add} credits added."});
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Get Payment History
# ═══════════════════════════════════════════════════════════════════════════════
# Returns purchase history for the authenticated user

walker :pub get_payment_history {
    has limit: int = 20;
    has offset: int = 0;

    can fetch with Root entry {
        profiles = [-->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            return;
        }

        # Get all credit transactions that are purchases
        all_transactions = [-->(?:CreditTransaction)];
        purchases = [];
        for txn in all_transactions {
            if txn.transaction_type == "purchase" {
                purchases.append(txn);
            }
        }

        # Sort by created_at (most recent first) - bubble sort
        n = len(purchases);
        for i in range(n) {
            for j in range(0, n - i - 1) {
                if purchases[j].created_at < purchases[j + 1].created_at {
                    temp = purchases[j];
                    purchases[j] = purchases[j + 1];
                    purchases[j + 1] = temp;
                }
            }
        }

        # Apply pagination
        total = len(purchases);
        start_idx = min(self.offset, total);
        end_idx = min(self.offset + self.limit, total);
        paginated = purchases[start_idx:end_idx];

        # Format transactions
        history = [];
        for txn in paginated {
            history.append({
                "transaction_id": txn.transaction_id,
                "package": txn.package_name,
                "credits": txn.amount,
                "description": txn.description,
                "date": txn.created_at
            });
        }

        report success_response({
            "purchases": history,
            "pagination": {
                "total": total,
                "limit": self.limit,
                "offset": self.offset,
                "has_more": end_idx < total
            }
        }, {});
    }
}
