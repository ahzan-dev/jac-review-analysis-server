# ══════════════════════════════════════════════════════════════════════════════
# AUTHENTICATION & USER MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Simplified walkers for user profile management and subscription control
# Flow: Register -> Create Profile -> Payment (if needed) -> Done!
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

import os;

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Create Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a UserProfile node with selected tier
# - FREE tier: active immediately
# - PRO/ENTERPRISE: pending_payment status until payment completes

walker:pub create_profile {
    has tier_requested: str = "free";

    can create with `root entry {
        # Check if profile already exists
        existing = [-->(`?UserProfile)];
        if existing {
            report {
                "success": False,
                "error": "User profile already exists"
            };
            return;
        }

        # Validate tier
        if self.tier_requested not in ["free", "pro", "enterprise"] {
            report validation_error("tier_requested", "Must be 'free', 'pro', or 'enterprise'");
            return;
        }

        # Determine status and limits based on requested tier
        if self.tier_requested == "free" {
            status = "active";
            tier = SubscriptionTier.FREE;
            pending = "";
            max_biz = 5;
            daily_limit = 10;
        } elif self.tier_requested == "pro" {
            status = "pending_payment";
            tier = SubscriptionTier.FREE;  # Start with free until payment succeeds
            pending = "pro";
            max_biz = 5;  # Free limits until upgraded
            daily_limit = 10;
        } else {  # enterprise
            status = "pending_payment";
            tier = SubscriptionTier.FREE;
            pending = "enterprise";
            max_biz = 5;
            daily_limit = 10;
        }

        # Create profile
        new_profile = UserProfile(
            username="",  # Populated by JAC auth context
            subscription_tier=tier,
            subscription_status=status,
            pending_upgrade_tier=pending,
            max_businesses=max_biz,
            daily_analysis_limit=daily_limit,
            created_at=str(datetime.now()),
            last_reset_date=str(datetime.now().date())
        );

        here ++> new_profile;

        # Build response
        response = {
            "success": True,
            "tier": tier.value,
            "subscription_status": status,
            "limits": {
                "max_businesses": max_biz,
                "daily_analyses": daily_limit
            }
        };

        # Add payment info if paid tier requested
        if pending != "" {
            response["pending_upgrade"] = pending;
            response["next_step"] = "Call initiate_payment to start payment process";
        }

        report response;
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Get User Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Retrieves the authenticated user's profile and current usage/limits

walker:pub get_user_profile {

    can fetch_profile with `root entry {
        # Get profile from authenticated user's root
        profiles = [-->(`?UserProfile)];

        if not profiles {
            report {
                "success": False,
                "error": "Profile not found. Create profile first using create_profile."
            };
            return;
        }

        profile = profiles[0];

        # Check if daily limit needs reset
        today = str(datetime.now().date());
        if profile.last_reset_date != today {
            profile.analyses_today = 0;
            profile.last_reset_date = today;
        }

        report {
            "success": True,
            "role": profile.role.value,
            "subscription": {
                "tier": profile.subscription_tier.value,
                "status": profile.subscription_status,
                "pending_upgrade": profile.pending_upgrade_tier
            },
            "limits": {
                "max_businesses": profile.max_businesses,
                "current_businesses": profile.current_business_count,
                "remaining_businesses": int(profile.max_businesses) - int(profile.current_business_count) if profile.max_businesses != -1 else -1,
                "daily_analysis_limit": profile.daily_analysis_limit,
                "analyses_today": profile.analyses_today,
                "remaining_today": int(profile.daily_analysis_limit) - int(profile.analyses_today) if profile.daily_analysis_limit != -1 else -1
            },
            "is_active": profile.is_active
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Update Subscription (Admin Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Allows admins to upgrade/downgrade user subscriptions

walker update_subscription {
    has target_username: str;
    has new_tier: str;

    can upgrade_user with `root entry {
        # Verify admin from OWN profile
        my_profiles = [-->(`?UserProfile)];
        if not my_profiles or my_profiles[0].role != UserRole.ADMIN {
            report unauthorized_error("Admin access required");
            return;
        }

        # Find target user profile
        target_profiles = [-->(`?UserProfile)](?username == self.target_username);
        if not target_profiles {
            report not_found_error("Target user not found");
            return;
        }

        profile = target_profiles[0];

        # Validate tier
        if self.new_tier not in ["free", "pro", "enterprise"] {
            report validation_error("new_tier", "Must be 'free', 'pro', or 'enterprise'");
            return;
        }

        # Update tier and limits
        if self.new_tier == "free" {
            profile.max_businesses = 5;
            profile.daily_analysis_limit = 10;
            tier_enum = SubscriptionTier.FREE;
        } elif self.new_tier == "pro" {
            profile.max_businesses = 50;
            profile.daily_analysis_limit = 100;
            tier_enum = SubscriptionTier.PRO;
        } else {  # enterprise
            profile.max_businesses = -1;
            profile.daily_analysis_limit = -1;
            tier_enum = SubscriptionTier.ENTERPRISE;
        }

        profile.subscription_tier = tier_enum;
        profile.subscription_status = "active";
        profile.pending_upgrade_tier = "";

        report {
            "success": True,
            "target_username": self.target_username,
            "new_tier": self.new_tier,
            "limits": {
                "max_businesses": profile.max_businesses,
                "daily_analyses": profile.daily_analysis_limit
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 4: Create Admin (Setup Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Upgrades the authenticated user to admin role
# Requires ADMIN_SETUP_SECRET environment variable

walker create_admin {
    has secret_key: str = "";

    can setup_admin with `root entry {
        # Check secret key from environment
        admin_secret = os.getenv('ADMIN_SETUP_SECRET', '');
        if not admin_secret {
            report {
                "success": False,
                "error": "ADMIN_SETUP_SECRET environment variable not configured"
            };
            return;
        }
        if self.secret_key != admin_secret {
            report unauthorized_error("Invalid admin setup secret");
            return;
        }

        # Get the authenticated user's profile
        existing = [-->(`?UserProfile)];

        if existing {
            # Upgrade existing profile to admin
            profile = existing[0];
            profile.role = UserRole.ADMIN;
            profile.subscription_tier = SubscriptionTier.ENTERPRISE;
            profile.max_businesses = -1;
            profile.daily_analysis_limit = -1;
            profile.subscription_status = "active";

            report {
                "success": True,
                "message": "Your account has been upgraded to admin"
            };
        } else {
            # Create new admin profile
            admin_profile = UserProfile(
                username="",
                role=UserRole.ADMIN,
                subscription_tier=SubscriptionTier.ENTERPRISE,
                subscription_status="active",
                max_businesses=-1,
                daily_analysis_limit=-1,
                created_at=str(datetime.now()),
                last_reset_date=str(datetime.now().date()),
                is_active=True
            );

            here ++> admin_profile;

            report {
                "success": True,
                "message": "Admin profile created for your account"
            };
        }
    }
}
