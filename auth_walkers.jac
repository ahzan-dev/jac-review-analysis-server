# ══════════════════════════════════════════════════════════════════════════════
# AUTHENTICATION & USER MANAGEMENT WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Simplified walkers for user profile management
# Credit-based system: Users purchase credit packages for analyses
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }

import os;

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 1: Create Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Creates a UserProfile node with 0 credits (users purchase packages)

walker:pub create_profile {

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

        # Create profile with 0 credits
        new_profile = UserProfile(
            username="",  # Populated by JAC auth context
            created_at=str(datetime.now())
        );

        here ++> new_profile;

        report {
            "success": True,
            "credits": 0,
            "message": "Profile created. Purchase a credit package to start analyzing."
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 2: Get User Profile
# ═══════════════════════════════════════════════════════════════════════════════
# Retrieves the authenticated user's profile and credit balance

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

        report {
            "success": True,
            "role": profile.role.value,
            "credits": {
                "available": profile.credits,
                "used": profile.credits_used
            },
            "businesses_count": profile.current_business_count,
            "is_active": profile.is_active
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# WALKER 3: Create Admin (Setup Only)
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
            profile.credits = 9999;  # Admin gets generous credits

            report {
                "success": True,
                "message": "Your account has been upgraded to admin"
            };
        } else {
            # Create new admin profile
            admin_profile = UserProfile(
                username="",
                role=UserRole.ADMIN,
                credits=9999,
                created_at=str(datetime.now()),
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
