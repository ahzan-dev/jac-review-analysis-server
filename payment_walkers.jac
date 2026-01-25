# ══════════════════════════════════════════════════════════════════════════════
# PAYMENT & SUBSCRIPTION MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Payment processing with Stripe-like test card validation
# Subscription lifecycle: upgrades, downgrades, cancellations
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Initiate Payment
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a payment intent for subscription purchase or upgrade
# Supports monthly and annual billing with 15% discount on annual

walker:pub initiate_payment {
    has tier: str;  # "pro" or "enterprise"
    has billing_interval: str = "monthly";  # "monthly" or "annual"
    has upgrade_from: str = "";  # For prorated upgrades (optional)

    can create_intent with `root entry {
        # Get user profile
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report unauthorized_error("Profile not found");
            return;
        }

        profile = profiles[0];

        # Validate billing_interval
        if self.billing_interval not in ["monthly", "annual"] {
            report validation_error("billing_interval", "Must be 'monthly' or 'annual'");
            return;
        }

        # Validate tier
        if self.tier not in ["pro", "enterprise"] {
            report validation_error("tier", "Must be 'pro' or 'enterprise'");
            return;
        }

        # Get pricing from global TIER_PRICING
        amount = TIER_PRICING[self.tier][self.billing_interval];

        # Calculate proration if upgrade (only for monthly billing)
        proration_credit = 0.0;
        if self.upgrade_from and self.upgrade_from != "" and self.billing_interval == "monthly" {
            # Simple proration logic: assume mid-month upgrade (15 days remaining)
            days_remaining = 15;
            old_tier_price = TIER_PRICING.get(self.upgrade_from, {}).get("monthly", 0.0);
            proration_credit = (old_tier_price / 30.0) * days_remaining;
            amount = max(0.0, amount - proration_credit);
        }

        # Create PaymentIntent node
        payment_id = str(uuid4());
        payment_intent = PaymentIntent(
            payment_id=payment_id,
            user_id=profile.username,
            tier=self.tier,
            amount=amount,
            status="requires_payment_method",
            created_at=str(datetime.now()),
            metadata={
                "billing_interval": self.billing_interval,
                "upgrade_from": self.upgrade_from,
                "proration_applied": proration_credit > 0.0,
                "proration_credit": proration_credit
            }
        );

        here ++> payment_intent;

        report {
            "payment_id": payment_id,
            "amount": round(amount, 2),
            "currency": "USD",
            "tier": self.tier,
            "billing_interval": self.billing_interval,
            "proration_credit": round(proration_credit, 2) if proration_credit > 0.0 else 0.0,
            "status": "requires_payment_method",
            "client_secret": f"dummy_secret_{payment_id}",  # Stripe-like client secret
            "message": "Payment intent created. Submit payment to complete."
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Process Payment
# ═══════════════════════════════════════════════════════════════════════════════
# Processes payment with test card validation (Stripe-like)
# Test cards: 4242424242424242 (success), 4000000000000002 (declined), 4000000000009995 (insufficient funds)

walker:pub process_payment {
    has payment_id: str;
    has payment_method: dict;  # {card_number, exp_month, exp_year, cvc}

    can process with `root entry {
        # Find PaymentIntent
        payment_intents = [here -->(`?PaymentIntent)];
        payment = None;
        for pi in payment_intents {
            if pi.payment_id == self.payment_id {
                payment = pi;
                break;
            }
        }

        if not payment {
            report {
                "success": False,
                "error": "Payment intent not found",
                "payment_id": self.payment_id
            };
            return;
        }

        # Validate payment already processed
        if payment.status == "succeeded" {
            report {
                "success": False,
                "error": "Payment already processed",
                "payment_id": self.payment_id
            };
            return;
        }

        # Validate card (dummy validation with Stripe-like test cards)
        card = self.payment_method;
        if not card.get("card_number") or len(card.get("card_number", "")) < 15 {
            payment.status = "failed";
            report {
                "success": False,
                "error": "Invalid card number",
                "payment_id": self.payment_id
            };
            return;
        }

        card_number = card["card_number"];

        # Test card validation (Stripe-like)
        if card_number == "4000000000000002" {
            payment.status = "failed";
            payment.updated_at = str(datetime.now());
            report {
                "success": False,
                "error": "Card declined",
                "payment_id": self.payment_id,
                "decline_code": "generic_decline"
            };
            return;
        }

        if card_number == "4000000000009995" {
            payment.status = "failed";
            payment.updated_at = str(datetime.now());
            report {
                "success": False,
                "error": "Insufficient funds",
                "payment_id": self.payment_id,
                "decline_code": "insufficient_funds"
            };
            return;
        }

        # If we reach here, payment is successful
        payment.status = "succeeded";
        payment.payment_method = {
            "last4": card_number[-4:],
            "brand": "visa",  # Dummy brand detection
            "exp_month": card.get("exp_month"),
            "exp_year": card.get("exp_year")
        };
        payment.updated_at = str(datetime.now());

        # Activate subscription on user profile
        profiles = [here -->(`?UserProfile)];
        profile = profiles[0];

        # Determine subscription duration
        billing_interval = payment.metadata.get("billing_interval", "monthly");
        if billing_interval == "annual" {
            days_until_renewal = 365;
        } else {
            days_until_renewal = 30;
        }

        now = datetime.now();
        end_date = now + timedelta(days=days_until_renewal);

        # Upgrade tier and update profile
        if payment.tier == "pro" {
            profile.subscription_tier = SubscriptionTier.PRO;
            profile.max_businesses = 50;
            profile.daily_analysis_limit = 100;
        } else {  # enterprise
            profile.subscription_tier = SubscriptionTier.ENTERPRISE;
            profile.max_businesses = -1;  # unlimited
            profile.daily_analysis_limit = -1;  # unlimited
        }

        profile.subscription_status = "active";
        profile.pending_upgrade_tier = "";  # Clear pending upgrade
        profile.billing_interval = billing_interval;
        profile.subscription_start_date = str(now);
        profile.subscription_end_date = str(end_date);
        profile.last_payment_date = str(now);
        profile.next_billing_date = str(end_date);

        # Reset usage counters
        profile.analyses_today = 0;
        profile.last_reset_date = str(now.date());

        # Create transaction record for audit trail
        transaction = Transaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="upgrade" if payment.metadata.get("upgrade_from") else "subscription_start",
            tier_from=payment.metadata.get("upgrade_from", "free"),
            tier_to=payment.tier,
            amount=payment.amount,
            payment_id=payment.payment_id,
            status="completed",
            created_at=str(now),
            metadata=payment.metadata
        );

        here ++> transaction;

        report {
            "success": True,
            "payment_id": payment.payment_id,
            "status": "succeeded",
            "subscription": {
                "tier": payment.tier,
                "status": "active",
                "billing_interval": billing_interval,
                "start_date": profile.subscription_start_date,
                "end_date": profile.subscription_end_date,
                "next_billing_date": profile.next_billing_date,
                "limits": {
                    "max_businesses": profile.max_businesses,
                    "daily_analyses": profile.daily_analysis_limit
                }
            },
            "transaction_id": transaction.transaction_id,
            "message": f"Payment successful! Upgraded to {payment.tier.upper()} tier."
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Get Subscription Details
# ═══════════════════════════════════════════════════════════════════════════════
# Retrieves current subscription information and usage limits

walker:pub get_subscription_details {
    can fetch with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {"error": "Profile not found"};
            return;
        }

        profile = profiles[0];

        # Calculate days until renewal
        days_until_renewal = 0;
        if profile.subscription_end_date {
            try {
                end_date = datetime.fromisoformat(profile.subscription_end_date);
                now = datetime.now();
                delta = end_date - now;
                days_until_renewal = max(0, delta.days);
            } except Exception as e {
                days_until_renewal = 0;
            }
        }

        # Get current price
        current_price = TIER_PRICING.get(profile.subscription_tier.value, {}).get(profile.billing_interval, 0.0);

        # Calculate annual savings if applicable
        annual_savings = 0.0;
        if profile.billing_interval == "annual" and profile.subscription_tier.value != "free" {
            monthly_equivalent = TIER_PRICING[profile.subscription_tier.value]["monthly"] * 12;
            annual_price = TIER_PRICING[profile.subscription_tier.value]["annual"];
            annual_savings = monthly_equivalent - annual_price;
        }

        report {
            "subscription": {
                "tier": profile.subscription_tier.value,
                "status": profile.subscription_status,
                "price": round(current_price, 2),
                "currency": "USD",
                "billing_interval": profile.billing_interval,
                "annual_savings": round(annual_savings, 2) if annual_savings > 0.0 else 0.0,
                "start_date": profile.subscription_start_date,
                "end_date": profile.subscription_end_date,
                "next_billing_date": profile.next_billing_date,
                "days_until_renewal": days_until_renewal,
                "pending_upgrade": profile.pending_upgrade_tier,
                "pending_downgrade": profile.pending_downgrade_tier
            },
            "limits": {
                "max_businesses": profile.max_businesses,
                "current_businesses": profile.current_business_count,
                "remaining_businesses": profile.max_businesses - profile.current_business_count if profile.max_businesses != -1 else -1,
                "daily_analysis_limit": profile.daily_analysis_limit,
                "analyses_today": profile.analyses_today,
                "remaining_today": profile.daily_analysis_limit - profile.analyses_today if profile.daily_analysis_limit != -1 else -1
            },
            "can_upgrade": profile.subscription_tier.value != "enterprise",
            "can_downgrade": profile.subscription_tier.value != "free"
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 4: Schedule Downgrade
# ═══════════════════════════════════════════════════════════════════════════════
# Schedules a tier downgrade at the end of the current billing period

walker:pub schedule_downgrade {
    has target_tier: str = "free";

    can schedule with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {"error": "Profile not found"};
            return;
        }

        profile = profiles[0];

        # Validate downgrade
        current_tier = profile.subscription_tier.value;
        if current_tier == "free" {
            report {
                "error": "Already on Free tier. Cannot downgrade further."
            };
            return;
        }

        if self.target_tier == current_tier {
            report {
                "error": f"Target tier ({self.target_tier}) is the same as current tier"
            };
            return;
        }

        # Validate target tier is lower than current
        tier_order = {"free": 0, "pro": 1, "enterprise": 2};
        if tier_order.get(self.target_tier, -1) >= tier_order.get(current_tier, -1) {
            report {
                "error": f"Target tier must be lower than current tier. Use upgrade flow instead."
            };
            return;
        }

        # Schedule downgrade
        profile.pending_downgrade_tier = self.target_tier;

        report {
            "downgrade_scheduled": True,
            "current_tier": current_tier,
            "target_tier": self.target_tier,
            "effective_date": profile.subscription_end_date,
            "days_until_downgrade": self.calculate_days_until(profile.subscription_end_date),
            "message": f"Your subscription will downgrade to {self.target_tier} on {profile.subscription_end_date}. You'll retain {current_tier} access until then."
        };
    }

    def calculate_days_until(end_date_str: str) -> int {
        if not end_date_str {
            return 0;
        }
        try {
            end_date = datetime.fromisoformat(end_date_str);
            now = datetime.now();
            delta = end_date - now;
            return max(0, delta.days);
        } except Exception as e {
            return 0;
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 5: Cancel Subscription
# ═══════════════════════════════════════════════════════════════════════════════
# Cancels subscription with optional grace period

walker:pub cancel_subscription {
    has immediate: bool = False;

    can cancel with `root entry {
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {"error": "Profile not found"};
            return;
        }

        profile = profiles[0];

        if profile.subscription_tier.value == "free" {
            report {
                "error": "No active subscription to cancel"
            };
            return;
        }

        now = datetime.now();

        if self.immediate {
            # Immediate cancellation - downgrade now
            old_tier = profile.subscription_tier.value;
            profile.subscription_tier = SubscriptionTier.FREE;
            profile.subscription_status = "cancelled";
            profile.max_businesses = 5;
            profile.daily_analysis_limit = 10;
            profile.subscription_end_date = str(now);
            profile.pending_downgrade_tier = "";
            message = f"Subscription cancelled immediately. Downgraded to Free tier.";

            # Create transaction
            transaction = Transaction(
                transaction_id=str(uuid4()),
                user_id=profile.username,
                transaction_type="cancellation",
                tier_from=old_tier,
                tier_to="free",
                amount=0.0,
                status="completed",
                created_at=str(now),
                metadata={"immediate": True}
            );
            here ++> transaction;

            report {
                "cancelled": True,
                "immediate": True,
                "new_tier": "free",
                "message": message,
                "transaction_id": transaction.transaction_id
            };
        } else {
            # Cancel at period end - retain access until subscription_end_date
            old_tier = profile.subscription_tier.value;
            profile.subscription_status = "cancelled";
            profile.pending_downgrade_tier = "free";
            message = f"Subscription cancelled. You'll retain {old_tier.upper()} access until {profile.subscription_end_date}";

            # Create transaction
            transaction = Transaction(
                transaction_id=str(uuid4()),
                user_id=profile.username,
                transaction_type="cancellation",
                tier_from=old_tier,
                tier_to="free",
                amount=0.0,
                status="completed",
                created_at=str(now),
                metadata={"immediate": False, "effective_date": profile.subscription_end_date}
            );
            here ++> transaction;

            report {
                "cancelled": True,
                "immediate": False,
                "current_tier": old_tier,
                "access_until": profile.subscription_end_date,
                "message": message,
                "transaction_id": transaction.transaction_id
            };
        }
    }
}
