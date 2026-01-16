# ══════════════════════════════════════════════════════════════════════════════
# REVIEW ANALYZER V2 - MAIN ENTRY POINT
# ══════════════════════════════════════════════════════════════════════════════
#
# Usage:
#   Interactive:  jac run main.jac
#   API Server:   jac serve main.jac
#
# ══════════════════════════════════════════════════════════════════════════════
import os;
import from datetime { datetime }
import json;

include models;
include walkers;
include api_walkers;
include auth_walkers;

# ═══════════════════════════════════════════════════════════════════════════════
# API WALKER: AnalyzeUrl
# Main entry point for analysis - called by external services
# ═══════════════════════════════════════════════════════════════════════════════
glob SERPAPI_KEY: str = os.getenv('SERPAPI_KEY', '');
walker AnalyzeUrl {
    # Input parameters
    has url: str;
    has max_reviews: int = 100;
    has analysis_depth: str = "deep";  # "basic", "standard", "deep"
    has api_key: str = SERPAPI_KEY;
    has force_mock: bool = False;
    has owner: str = "";  # NEW: User who owns this business

    # Output
    has success: bool = False;
    has data_source: str = "";
    has output: dict = {};
    has error: str = "";

    obj __specs__ {
        static has auth: bool = True;  # NEW: Require authentication
    }

    can start with `root entry {
        # NEW: Verify user profile exists
        if not self.owner {
            report {"error": "Owner username required"};
            return;
        }

        profiles = [-->(`?UserProfile)](?username == self.owner);
        if not profiles {
            report {"error": "User profile not found. Create profile first using create_user_profile walker"};
            return;
        }

        profile = profiles[0];

        # NEW: Check if user is active
        if not profile.is_active {
            report {"error": "User account is inactive"};
            return;
        }

        # NEW: Reset daily limit if needed
        today = str(datetime.now().date());
        if profile.last_reset_date != today {
            profile.analyses_today = 0;
            profile.last_reset_date = today;
        }

        # NEW: Check daily analysis limit
        if profile.daily_analysis_limit != -1 {  # -1 means unlimited
            if profile.analyses_today >= profile.daily_analysis_limit {
                report {
                    "error": "Daily analysis limit reached",
                    "limit": profile.daily_analysis_limit,
                    "used": profile.analyses_today,
                    "reset_date": today,
                    "tier": profile.subscription_tier.value,
                    "message": "Upgrade to Pro or Enterprise for more analyses"
                };
                return;
            }
        }

        # NEW: Check business limit (only if creating new business)
        # We'll increment after confirming the business is new

        # NEW: Increment daily analysis counter BEFORE expensive operation
        profile.analyses_today += 1;

        # Run full pipeline
        pipeline = here spawn FullPipelineAgent(
            url=self.url,
            max_reviews=self.max_reviews,
            report_type=self.analysis_depth,
            serp_api_key=self.api_key,
            force_mock=self.force_mock,
            owner=self.owner  # NEW: Pass owner to pipeline
        );

        if pipeline.status == "completed" {
            self.success = True;
            self.output = pipeline.output;
            self.business_id = pipeline.business_id;
            self.stages_completed = pipeline.stages_completed;
            self.data_source = pipeline.data_source;

            # NEW: Add usage info to output
            enhanced_output = self.output;
            enhanced_output["usage"] = {
                "analyses_today": profile.analyses_today,
                "daily_limit": profile.daily_analysis_limit,
                "businesses_count": profile.current_business_count,
                "business_limit": profile.max_businesses,
                "tier": profile.subscription_tier.value
            };

            # Report for API response
            report enhanced_output;
        } else {
            self.success = False;
            self.error = pipeline.error;

            # NEW: Decrement counter if pipeline failed
            if profile.analyses_today > 0 {
                profile.analyses_today -= 1;
            }

            report {
                "success": False,
                "error": self.error
            };
        }
    }
}

# # ═══════════════════════════════════════════════════════════════════════════════
# # INTERACTIVE MODE
# # ═══════════════════════════════════════════════════════════════════════════════

# with entry {
#     print("\n" + "╔" + "═" * 63 + "╗");
#     print("║" + " " * 15 + "REVIEW ANALYZER V2 - DEEP ANALYSIS" + " " * 13 + "║");
#     print("║" + " " * 63 + "║");
#     print("║   Features:" + " " * 51 + "║");
#     print("║   • Health Score with Grade (A+ to F)" + " " * 24 + "║");
#     print("║   • Sub-theme Analysis by Business Type" + " " * 22 + "║");
#     print("║   • Trend Analysis (6 months)" + " " * 32 + "║");
#     print("║   • Statistical Confidence Indicators" + " " * 24 + "║");
#     print("║   • Prioritized Recommendations" + " " * 30 + "║");
#     print("╚" + "═" * 63 + "╝\n");
    
#     # Step 1: URL
#     print("📍 Step 1: Enter Google Maps URL");
#     print("─" * 65);
#     url_input = input("   URL (or Enter for demo): ").strip();
    
#     if not url_input {
#         url_input = "https://www.google.com/maps/place/Weligama+Bay+Marriott+Resort+%26+Spa/@5.9730503,80.4394055,1140m/data=!3m2!1e3!4b1!4m9!3m8!1s0x3ae11545eda17fd9:0xe4d7ca849dbecbbe!5m2!4m1!1i2!8m2!3d5.9730503!4d80.4394055!16s%2Fg%2F11byp5wcz4";
#         print(f"\n   Using demo URL");
#     }
    
#     # Step 2: Options
#     print("\n📋 Step 2: Analysis Options");
#     print("─" * 65);
    
#     max_input = input("   Max reviews [20/50/100/200] (default 50): ").strip();
#     max_reviews = 50;
#     if max_input in ["20", "50", "100", "200"] {
#         max_reviews = int(max_input);
#     }
    
#     depth_input = input("   Depth [basic/standard/deep] (default deep): ").strip().lower();
#     depth = "deep";
#     if depth_input in ["basic", "standard", "deep"] {
#         depth = depth_input;
#     }
    
#     # Step 3: Confirm
#     print("\n🚀 Step 3: Ready to Analyze");
#     print("─" * 65);
#     print(f"   URL: {url_input[:55]}...");
#     print(f"   Max Reviews: {max_reviews}");
#     print(f"   Depth: {depth}");
    
#     proceed = input("\n   Press Enter to start (or 'q' to quit): ").strip().lower();
    
#     if proceed == "q" {
#         print("\n👋 Goodbye!");
#     } else {
#         # Run analysis
#         result = root spawn AnalyzeUrl(
#             url=url_input,
#             max_reviews=max_reviews,
#             analysis_depth=depth,
#             api_key=""
#         );
        
#         if result.success {
#             output = result.output;
            
#             # Display summary
#             print("\n" + "╔" + "═" * 63 + "╗");
#             print("║" + " " * 20 + "ANALYSIS COMPLETE" + " " * 26 + "║");
#             print("╚" + "═" * 63 + "╝\n");
            
#             # Health Score
#             hs = output.get("health_score", {});
#             print(f"🏆 HEALTH SCORE: {hs.get('overall', 'N/A')} ({hs.get('grade', 'N/A')})");
#             print(f"   Confidence: {hs.get('confidence', 'N/A').upper()}");
#             print(f"   Trend: {hs.get('trend', 'N/A')}");
            
#             # Breakdown
#             breakdown = hs.get("breakdown", {});
#             if breakdown {
#                 print("\n   Breakdown:");
#                 for (theme, score) in breakdown.items() {
#                     bar = "█" * (score // 10) + "░" * (10 - score // 10);
#                     print(f"   {theme:20} {bar} {score}");
#                 }
#             }
            
#             # Executive Summary
#             es = output.get("executive_summary", {});
#             print(f"\n📰 {es.get('headline', 'N/A')}");
#             print(f"   {es.get('one_liner', 'N/A')}");
#             print(f"   Key Metric: {es.get('key_metric', 'N/A')}");
            
#             # Critical Issues
#             issues = output.get("critical_issues", []);
#             if issues {
#                 print(f"\n⚠️  CRITICAL ISSUES ({len(issues)}):");
#                 for issue in issues[:3] {
#                     severity = issue.get("severity", "").upper();
#                     print(f"   [{severity}] {issue.get('issue', 'N/A')}");
#                 }
#             }
            
#             # Top Recommendations
#             recs = output.get("recommendations", {});
#             immediate = recs.get("immediate", []);
#             if immediate {
#                 print(f"\n💡 TOP ACTIONS:");
#                 for (i, rec) in enumerate(immediate[:3]) {
#                     print(f"   {i+1}. {rec.get('action', 'N/A')}");
#                     print(f"      Impact: {rec.get('expected_impact', 'N/A')}");
#                 }
#             }
            
#             # Save to file
#             print("\n" + "─" * 65);
            
#             filename = output.get("business", {}).get("name", "report").replace(" ", "_").replace("/", "_");
#             filename = f"{filename}_Deep_Analysis.json";
            
#             with open(filename, "w") as f {
#                 json.dump(output, f, indent=2);
#             }
            
#             print(f"✅ Full report saved: {filename}");
#             print("\n   View with: cat " + filename + " | jq");
#             print("   Or: jq '.health_score' " + filename);
#             print("   Or: jq '.themes' " + filename);
#             print("   Or: jq '.recommendations' " + filename);
            
#         } else {
#             print(f"\n❌ Error: {result.error}");
#         }
#     }
# }

# ═══════════════════════════════════════════════════════════════════════════════
# HEALTH CHECK ENDPOINT
# ═══════════════════════════════════════════════════════════════════════════════

walker health_check {
    can check with `root entry {
        report {
            "status": "healthy",
            "service": "review-analyzer",
            "version": "2.0"
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# DIAGNOSTICS ENDPOINT - Check Environment Variables
# ═══════════════════════════════════════════════════════════════════════════════

walker diagnostics {
    has username: str = "";  # NEW: Required for authentication

    obj __specs__ {
        static has auth: bool = True;  # NEW: Require authentication
    }

    can check with `root entry {

        # NEW: Admin-only endpoint
        if not self.username {
            report {"error": "Username required"};
            return;
        }

        profiles = [-->(`?UserProfile)](?username == self.username);
        if not profiles or profiles[0].role != UserRole.ADMIN {
            report {"error": "Unauthorized. Admin access required."};
            return;
        }

        report {
            "environment": {
                "LLM_MODEL": os.getenv('LLM_MODEL', 'NOT_SET'),
                "DEBUG": os.getenv('DEBUG', 'NOT_SET'),
                "PORT": os.getenv('PORT', 'NOT_SET'),
                "OPENAI_API_KEY": os.getenv('OPENAI_API_KEY', 'NOT_SET')[:20] + "..." if os.getenv('OPENAI_API_KEY') else "NOT_SET",
                "SERPAPI_KEY": os.getenv('SERPAPI_KEY', 'NOT_SET')[:20] + "..." if os.getenv('SERPAPI_KEY') else "NOT_SET"
            },
            "system_info": {
                "python_version": os.sys.version,
                "cwd": os.getcwd()
            }
        };
    }
}
