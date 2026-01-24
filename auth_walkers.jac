# ══════════════════════════════════════════════════════════════════════════════
# AUTHENTICATION & USER MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Walkers for user profile management, subscription control, and admin operations
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime, timedelta }
import from uuid { uuid4 }

import os;

include models;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Create User Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a UserProfile node on the authenticated user's root
# Called after /user/register - requires JWT token in Authorization header

walker create_user_profile {
    has subscription_tier: str = "free";

    

    can create_profile with `root entry {
        # Check if profile already exists on this user's root
        existing = [-->(`?UserProfile)];

        if existing {
            report {
                "status": "exists",
                "message": "User profile already exists"
            };
            return;
        }

        # Determine limits based on tier
        if self.subscription_tier == "free" {
            max_biz = 5;
            daily_limit = 10;
        } elif self.subscription_tier == "pro" {
            max_biz = 50;
            daily_limit = 100;
        } else {  # enterprise
            max_biz = -1;  # unlimited
            daily_limit = -1;  # unlimited
        }

        # Create profile on authenticated user's root
        # Note: Username is not needed - profile is on user's isolated root
        new_profile = UserProfile(
            username="",  # Will be set if needed, but root isolation handles identity
            subscription_tier=SubscriptionTier(self.subscription_tier),
            max_businesses=max_biz,
            daily_analysis_limit=daily_limit,
            created_at=str(datetime.now()),
            last_reset_date=str(datetime.now().date())
        );

        here ++> new_profile;

        report {
            "status": "created",
            "tier": self.subscription_tier,
            "limits": {
                "businesses": max_biz,
                "daily_analyses": daily_limit
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Get User Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Retrieves the authenticated user's profile and current usage/limits

walker get_user_profile {
    

    can fetch_profile with `root entry {
        # Get profile from authenticated user's root (no username filter needed)
        profiles = [-->(`?UserProfile)];

        if not profiles {
            report {
                "status": "not_found",
                "message": "User profile not found. Create profile first using create_user_profile."
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
            "status": "found",
            "role": profile.role.value,
            "subscription": profile.subscription_tier.value,
            "limits": {
                "max_businesses": profile.max_businesses,
                "current_businesses": profile.current_business_count,
                "remaining_businesses": profile.max_businesses - profile.current_business_count if profile.max_businesses != -1 else -1,
                "daily_analysis_limit": profile.daily_analysis_limit,
                "analyses_today": profile.analyses_today,
                "remaining_today": profile.daily_analysis_limit - profile.analyses_today if profile.daily_analysis_limit != -1 else -1
            },
            "is_active": profile.is_active
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Update Subscription (Admin Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Allows admins to upgrade/downgrade user subscriptions
# SECURITY: Admin status verified from authenticated user's own profile

walker update_subscription {
    has target_username: str;  # Username of user to update
    has new_tier: str;

    

    can upgrade_user with `root entry {
        # SECURITY: Verify admin from OWN profile (on authenticated user's root)
        # This prevents impersonation - admin status comes from JWT context, not body
        my_profiles = [-->(`?UserProfile)];
        if not my_profiles or my_profiles[0].role != UserRole.ADMIN {
            report {"error": "Unauthorized. Admin access required."};
            return;
        }

        # Find target user profile
        # NOTE: With full isolated roots, this requires AdminRoot pattern
        # For now, searching from root which may have shared access
        target_profiles = [-->(`?UserProfile)](?username == self.target_username);
        if not target_profiles {
            report {"error": "Target user not found"};
            return;
        }

        profile = target_profiles[0];

        # Update tier and limits
        if self.new_tier == "free" {
            profile.max_businesses = 5;
            profile.daily_analysis_limit = 10;
        } elif self.new_tier == "pro" {
            profile.max_businesses = 50;
            profile.daily_analysis_limit = 100;
        } else {  # enterprise
            profile.max_businesses = -1;
            profile.daily_analysis_limit = -1;
        }

        profile.subscription_tier = SubscriptionTier(self.new_tier);

        report {
            "status": "updated",
            "target_username": self.target_username,
            "new_tier": self.new_tier,
            "new_limits": {
                "businesses": profile.max_businesses,
                "daily_analyses": profile.daily_analysis_limit
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 4: Create Admin (Setup Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Upgrades the authenticated user to admin role
# SECURITY: Requires authentication + secret key, upgrades the caller's own profile

walker create_admin {
    has secret_key: str = "";  # Required: must match ADMIN_SETUP_SECRET env var

    

    can setup_admin with `root entry {
        # SECURITY: Check secret key from environment
        admin_secret = os.getenv('ADMIN_SETUP_SECRET', '');
        if not admin_secret {
            report {"error": "ADMIN_SETUP_SECRET environment variable not configured"};
            return;
        }
        if self.secret_key != admin_secret {
            report {"error": "Invalid admin setup secret"};
            return;
        }

        # Get the authenticated user's profile (on their own root)
        existing = [-->(`?UserProfile)];

        if existing {
            # Upgrade existing profile to admin
            profile = existing[0];
            profile.role = UserRole.ADMIN;
            profile.subscription_tier = SubscriptionTier.ENTERPRISE;
            profile.max_businesses = -1;
            profile.daily_analysis_limit = -1;

            report {
                "status": "upgraded",
                "message": "Your account has been upgraded to admin"
            };
        } else {
            # Create new admin profile on the authenticated user's root
            admin_profile = UserProfile(
                username="",  # Not needed with isolated roots
                role=UserRole.ADMIN,
                subscription_tier=SubscriptionTier.ENTERPRISE,
                max_businesses=-1,
                daily_analysis_limit=-1,
                created_at=str(datetime.now()),
                last_reset_date=str(datetime.now().date()),
                is_active=True
            );

            here ++> admin_profile;

            report {
                "status": "created",
                "message": "Admin profile created for your account"
            };
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# TOKEN MANAGEMENT WALKERS
# ═══════════════════════════════════════════════════════════════════════════════
# Session token management with expiration support
# Note: These are separate from JWT tokens - used for additional session control

walker generate_session_token {
    has expiry_days: int = 7;

    can generate with `root entry {
        # Get user profile
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {"error": "User profile not found"};
            return;
        }

        profile = profiles[0];

        # Generate token with expiration
        profile.token = str(uuid4());
        expires_at = datetime.now() + timedelta(days=self.expiry_days);
        profile.token_expires = expires_at.isoformat();

        report {
            "token": profile.token,
            "expires_at": profile.token_expires,
            "expires_in_days": self.expiry_days
        };
    }
}

walker validate_session_token {
    has token: str;

    can validate with `root entry {
        # Get user profile
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {"valid": False, "reason": "Profile not found"};
            return;
        }

        profile = profiles[0];

        # Check if token matches
        if not profile.token or profile.token != self.token {
            report {"valid": False, "reason": "Invalid token"};
            return;
        }

        # Check if token has expired
        if not profile.token_expires {
            report {"valid": False, "reason": "Token has no expiration set"};
            return;
        }

        try {
            expires_at = datetime.fromisoformat(profile.token_expires);
            now = datetime.now();

            if now > expires_at {
                report {"valid": False, "reason": "Token expired", "expired_at": profile.token_expires};
                return;
            }

            report {
                "valid": True,
                "expires_at": profile.token_expires,
                "username": profile.username
            };
        } except Exception as e {
            report {"valid": False, "reason": f"Token validation error: {str(e)}"};
        }
    }
}

walker revoke_session_token {
    can revoke with `root entry {
        # Get user profile
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {"error": "User profile not found"};
            return;
        }

        profile = profiles[0];

        # Clear token and expiration
        profile.token = "";
        profile.token_expires = "";

        report {"status": "revoked", "message": "Session token has been revoked"};
    }
}

