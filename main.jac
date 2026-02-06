# ══════════════════════════════════════════════════════════════════════════════
# REVIEW ANALYZER V2 - MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage:
#   Interactive:  jac run main.jac
#   API Server:   jac start main.jac
#
# ══════════════════════════════════════════════════════════════════════════════
import from datetime {
    datetime,
    timedelta
}
import from math { ceil }
import json, os;

include services.models;
include services.walkers;
include services.api_walkers;
include services.auth_walkers;
include services.payment_walkers;
include services.credit_walkers;
include services.errors;

# ═══════════════════════════════════════════════════════════════════════════════
# API WALKER: AnalyzeUrl
# Main entry point for analysis - called by external services
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub AnalyzeUrl {
    # Input parameters
    has url: str;
    has max_reviews: int = 100;
    has analysis_depth: str = "deep";  # "basic", "standard", "deep"
    has force_refresh: bool = False;    # Force re-fetch even if cached data is fresh
    has freshness_days: int = 7;        # Configurable freshness window (days)

    # Output
    has success: bool = False;
    has data_source: str = "";
    has from_cache: bool = False;       # Indicates if using cached data
    has output: dict = {};
    has error: str = "";

    can start with `root entry {

        # SECURITY: Get user profile from authenticated user's root
        profiles = [-->(`?UserProfile)];
        if not profiles {
            report {
                "error": "User profile not found. Create profile first using create_profile walker"
            };
            return;
        }

        profile = profiles[0];

        # Check if user is active
        if not profile.is_active {
            report unauthorized_error("User account is inactive");
            return;
        }

        # ═══════════════════════════════════════════════════════════════════
        # CREDIT CHECK: 1 credit = up to 100 reviews
        # Formula: credits_required = CEILING(total_reviews / 100)
        # ═══════════════════════════════════════════════════════════════════
        credits_required = ceil(self.max_reviews / 100);
        if credits_required < 1 {
            credits_required = 1;
        }

        if profile.credits < credits_required {
            report insufficient_credits_error(credits_required, profile.credits);
            return;
        }

        # Parse URL and extract business_id for cache check
        parsed = parse_google_maps_url(self.url);
        if not parsed["is_valid"] {
            report validation_error("url", parsed["error"]);
            return;
        }

        business_id = parsed["data_id"] if parsed["data_id"] else "";

        # Check for existing fresh business (cache check)
        if business_id and not self.force_refresh {
            existing = self.find_existing_business(here, business_id);
            if existing {
                freshness = self.check_freshness(existing, self.freshness_days);
                if freshness["is_fresh"] {
                    # Use cached data - run only analysis stages (no fetch)
                    print(f"   📦 Using cached data for business: {existing.name}");
                    print(f"   📅 Data age: {freshness['age_days']} days (threshold: {self.freshness_days} days)");

                    # Deduct credits based on review count (1 credit per 100 reviews)
                    profile.credits -= credits_required;
                    profile.credits_used += credits_required;

                    # Run reanalysis pipeline on existing data
                    pipeline = here spawn ReanalyzePipeline(
                        business_id=business_id,
                        report_type=self.analysis_depth
                    );

                    if pipeline.status == "completed" {
                        self.success = True;
                        self.output = pipeline.output;
                        self.business_id = business_id;
                        self.stages_completed = pipeline.stages_completed;
                        self.data_source = "cache";
                        self.from_cache = True;

                        # Add usage and cache info to output
                        enhanced_output = self.output;
                        enhanced_output["credits"] = {
                            "used": credits_required,
                            "remaining": profile.credits,
                            "calculation": f"{self.max_reviews} reviews = {credits_required} credit(s)"
                        };
                        enhanced_output["cache_info"] = {
                            "from_cache": True,
                            "data_age_days": freshness["age_days"],
                            "freshness_threshold_days": self.freshness_days,
                            "fetched_at": existing.fetched_at,
                            "message": "Using cached reviews. Use force_refresh=true to re-fetch."
                        };
                        report enhanced_output;
                    } else {
                        self.success = False;
                        self.error = pipeline.error;
                        # Refund credits on pipeline failure
                        profile.credits += credits_required;
                        profile.credits_used -= credits_required;
                        report error_response(ErrorCode.INTERNAL_ERROR, self.error, {});
                    }
                    return;
                } else {
                    # Data is stale - will refresh
                    print(f"   ⏰ Cached data is stale ({freshness['age_days']} days old). Refreshing...");
                }
            }
        }

        # Deduct credits BEFORE expensive operation (1 credit per 100 reviews)
        profile.credits -= credits_required;
        profile.credits_used += credits_required;

        # Run full pipeline (fresh fetch)
        # SECURITY: Business will be created on authenticated user's root automatically
        pipeline = here spawn FullPipelineAgent(
            url=self.url,
            max_reviews=self.max_reviews,
            report_type=self.analysis_depth
        );

        if pipeline.status == "completed" {
            self.success = True;
            self.output = pipeline.output;
            self.business_id = pipeline.business_id;
            self.stages_completed = pipeline.stages_completed;
            self.data_source = pipeline.data_source;
            self.from_cache = False;

            # Add credits info to output
            enhanced_output = self.output;
            enhanced_output["credits"] = {
                "used": credits_required,
                "remaining": profile.credits,
                "calculation": f"{self.max_reviews} reviews = {credits_required} credit(s)"
            };
            enhanced_output["cache_info"] = {
                "from_cache": False,
                "message": "Fresh data fetched from API"
            };
            # Report for API response
            report enhanced_output;
        } else {
            self.success = False;
            self.error = pipeline.error;
            # Refund credits if pipeline failed
            profile.credits += credits_required;
            profile.credits_used -= credits_required;
            report error_response(ErrorCode.INTERNAL_ERROR, self.error, {});
        }
    }

    def find_existing_business(root_node: `root, business_id: str) -> Business | None {
        # """Find existing business by place_id in user's root."""
        businesses = [root_node -->(`?Business)];
        for biz in businesses {
            if biz.place_id == business_id {
                return biz;
            }
        }
        return None;
    }

    def check_freshness(business: Business | None, max_days: int) -> dict {
        # """Check if business data is still fresh based on fetched_at timestamp."""
        if not business or not business.fetched_at {
            return {"is_fresh": False, "age_days": -1, "reason": "No fetch timestamp"};
        }

        try {
            fetched = datetime.fromisoformat(business.fetched_at);
            now = datetime.now();
            # Calculate days difference using timestamps to avoid type checker issues
            now_ts = int(now.timestamp());
            fetched_ts = int(fetched.timestamp());
            diff_seconds = now_ts - fetched_ts;
            age_days = int(diff_seconds / 86400);  # 86400 seconds in a day

            if age_days <= max_days {
                return {
                    "is_fresh": True,
                    "age_days": age_days,
                    "max_days": max_days
                };
            } else {
                return {
                    "is_fresh": False,
                    "age_days": age_days,
                    "max_days": max_days,
                    "reason": f"Data is {age_days} days old (max: {max_days})"
                };
            }
        } except Exception as e {
            return {"is_fresh": False, "age_days": -1, "reason": f"Invalid fetch timestamp: {str(e)}"};
        }
    }
}


# ═══════════════════════════════════════════════════════════════════════════════
# HEALTH CHECK ENDPOINT
# ═══════════════════════════════════════════════════════════════════════════════
walker:pub health_check {
    can check with `root entry {
        report {"status": "healthy", "service": "review-analyzer", "version": "2.0"} ;
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# READINESS PROBE - Check if service is ready to accept traffic
# ═══════════════════════════════════════════════════════════════════════════════
# Verifies that all dependencies are configured and accessible
# Used by Docker/Kubernetes to determine when service can receive requests

walker:pub ready {
    # """Readiness probe - checks if service is ready to accept traffic."""

    can check with `root entry {
        # Check critical environment variables
        openai_key = os.getenv("OPENAI_API_KEY");
        serpapi_key = os.getenv("SERPAPI_KEY");

        # Dependency checks
        checks = {
            "openai_configured": bool(openai_key and openai_key != ""),
            "serpapi_configured": bool(serpapi_key and serpapi_key != ""),
            "graph_accessible": True  # If we reach here, graph database is accessible
        };

        # Determine overall readiness
        all_ready = all(checks.values());

        report {
            "ready": all_ready,
            "status": "ready" if all_ready else "not_ready",
            "checks": checks,
            "service": "review-analyzer",
            "timestamp": str(datetime.now())
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DIAGNOSTICS ENDPOINT - Check Environment Variables (Admin Only)
# ═══════════════════════════════════════════════════════════════════════════════
walker diagnostics {
    

    can check with `root entry {
        # SECURITY: Admin-only endpoint - check from authenticated user's own profile
        profiles = [-->(`?UserProfile)];
        if not profiles or profiles[0].role != UserRole.ADMIN {
            report error_response(ErrorCode.INSUFFICIENT_PERMISSIONS, "Admin access required", {});
            return;
        }

        # Get API keys with safe string handling
        openai_key = os.getenv('OPENAI_API_KEY');
        serpapi_key = os.getenv('SERPAPI_KEY');

        openai_display = str(openai_key)[:20] + "..." if openai_key else "NOT_SET";
        serpapi_display = str(serpapi_key)[:20] + "..." if serpapi_key else "NOT_SET";

        report {
            "environment": {
                "LLM_MODEL": os.getenv('LLM_MODEL', 'NOT_SET'),
                "DEBUG": os.getenv('DEBUG', 'NOT_SET'),
                "PORT": os.getenv('PORT', 'NOT_SET'),
                "OPENAI_API_KEY": openai_display,
                "SERPAPI_KEY": serpapi_display
            },
            "system_info": {"python_version": os.sys.version, "cwd": os.getcwd()}
        } ;
    }
}
