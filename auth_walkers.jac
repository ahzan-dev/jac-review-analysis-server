# ══════════════════════════════════════════════════════════════════════════════
# AUTHENTICATION & USER MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Walkers for user profile management, subscription control, and admin operations
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }

import os;

include models;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Create User Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a UserProfile node for a registered user
# Call this after /user/register to set up subscription limits

walker create_user_profile {
    has username: str;
    has subscription_tier: str = "free";

    obj __specs__ {
        static has auth: bool = False;  # No auth needed for profile creation
    }

    can create_profile with `root entry {
        # Check if profile already exists
        existing = [-->(`?UserProfile)](?username == self.username);

        if existing {
            report {
                "status": "exists",
                "message": "User profile already exists",
                "username": self.username
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

        # Create profile
        new_profile = UserProfile(
            username=self.username,
            subscription_tier=SubscriptionTier(self.subscription_tier),
            max_businesses=max_biz,
            daily_analysis_limit=daily_limit,
            created_at=str(datetime.now()),
            last_reset_date=str(datetime.now().date())
        );

        here ++> new_profile;

        report {
            "status": "created",
            "username": self.username,
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
# Retrieves user profile and current usage/limits

walker get_user_profile {
    has username: str;

    obj __specs__ {
        static has auth: bool = False;
    }

    can fetch_profile with `root entry {
        profiles = [-->(`?UserProfile)](?username == self.username);

        if not profiles {
            report {
                "status": "not_found",
                "message": "User profile not found. Create profile first."
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
            "username": profile.username,
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

walker update_subscription {
    has target_username: str;
    has new_tier: str;
    has admin_username: str;

    obj __specs__ {
        static has auth: bool = True;  # Requires authentication
    }

    can upgrade_user with `root entry {
        # Verify admin permissions
        admin_profiles = [-->(`?UserProfile)](?username == self.admin_username);
        if not admin_profiles or admin_profiles[0].role != UserRole.ADMIN {
            report {"error": "Unauthorized. Admin access required."};
            return;
        }

        # Find target user
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
            "username": profile.username,
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
# Creates or upgrades a user to admin role

walker create_admin {
    has username: str;
    has secret_key: str = "";  # Optional: require secret for first admin

    obj __specs__ {
        static has auth: bool = False;  # Special case for setup
    }

    can setup_admin with `root entry {
        # Optional: Check secret key from environment
        admin_secret = os.getenv('ADMIN_SETUP_SECRET', '');
        if admin_secret and self.secret_key != admin_secret {
            report {"error": "Invalid admin setup secret"};
            return;
        }

        # Check if profile exists
        existing = [-->(`?UserProfile)](?username == self.username);

        if existing {
            # Upgrade existing user to admin
            profile = existing[0];
            profile.role = UserRole.ADMIN;
            profile.subscription_tier = SubscriptionTier.ENTERPRISE;
            profile.max_businesses = -1;
            profile.daily_analysis_limit = -1;

            report {
                "status": "upgraded",
                "message": "User upgraded to admin",
                "username": self.username
            };
        } else {
            # Create new admin profile
            admin_profile = UserProfile(
                username=self.username,
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
                "message": "Admin profile created",
                "username": self.username,
                "note": "Make sure to register this user via /user/register endpoint"
            };
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 5: Reset Database (Admin Only)
# ═══════════════════════════════════════════════════════════════════════════════
# Deletes all businesses and resets user counts (for migration)

# walker reset_database {
#     has admin_username: str;
#     has confirm_reset: bool = False;

#     obj __specs__ {
#         static has auth: bool = False;  # Special case for setup
#     }

#     can clean_database with `root entry {
#         if not self.confirm_reset {
#             report {
#                 "error": "Confirmation required",
#                 "message": "Set 'confirm_reset: true' to delete all businesses"
#             };
#             return;
#         }

#         # Verify admin
#         profiles = [-->(`?UserProfile)](?username == self.admin_username);
#         if not profiles or profiles[0].role != UserRole.ADMIN {
#             report {"error": "Admin access required"};
#             return;
#         }

#         # Delete all businesses and related nodes
#         businesses = [-->(`?Business)];
#         business_count = len(businesses);

#         for biz in businesses {
#             # Delete connected review nodes
#             reviews = biz [-->(`?Review)];
#             for r in reviews {
#                 del r;
#             }

#             # Delete connected analysis nodes
#             analyses = biz [-->(`?Analysis)];
#             for a in analyses {
#                 # Also delete themes connected to analysis
#                 themes = a [-->(`?Theme)];
#                 for t in themes {
#                     del t;
#                 }
#                 del a;
#             }

#             # Delete connected report nodes
#             reports = biz [-->(`?Report)];
#             for rpt in reports {
#                 del rpt;
#             }

#             del biz;
#         }

#         # Reset all user business counts
#         all_profiles = [-->(`?UserProfile)];
#         for p in all_profiles {
#             p.current_business_count = 0;
#         }

#         report {
#             "success": True,
#             "message": "Database reset complete",
#             "deleted_businesses": business_count,
#             "reset_by": self.admin_username
#         };
#     }
# }
