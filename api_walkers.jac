# ══════════════════════════════════════════════════════════════════════════════
# REVIEW ANALYZER - API WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# These walkers become REST endpoints when using `jac serve main.jac`
# Each walker handles a specific API operation
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }
import from uuid { uuid4 }

include models;
include walkers;

# ═══════════════════════════════════════════════════════════════════════════════
# NOTE: AnalyzeUrl walker is defined in main.jac
# ═══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# API 1: GetBusinesses - List All Analyzed Businesses
# POST /walker/GetBusinesses
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GetBusinesses {
    has limit: int = 20;
    has status_filter: str = "";  # "pending", "fetched", "analyzed", "completed"

    

    can start with `root entry {
        # SECURITY: With isolated roots, user only sees their own businesses automatically
        # No need for username parameter or owner filtering

        # Check if user is admin (from their own profile)
        profiles = [-->(`?UserProfile)];
        is_admin = profiles and profiles[0].role == UserRole.ADMIN;

        # Get businesses from authenticated user's root
        # With isolated roots, this automatically returns only the user's businesses
        businesses = [here -->(`?Business)];

        results = [];
        count = 0;

        for biz in businesses {
            # Apply status filter if provided
            if self.status_filter != "" and biz.status != self.status_filter {
                continue;
            }

            if count >= self.limit {
                break;
            }

            # Get counts
            review_count = len([biz -->(`?Review)]);
            has_analysis = len([biz -->(`?Analysis)]) > 0;
            has_report = len([biz -->(`?Report)]) > 0;

            results.append({
                "place_id": biz.place_id,
                "name": biz.name,
                "rating": biz.rating,
                "total_reviews": biz.total_reviews,
                "fetched_reviews": review_count,
                "business_type": biz.business_type,
                "address": biz.address,
                "status": biz.status,
                "has_analysis": has_analysis,
                "has_report": has_report,
                "fetched_at": biz.fetched_at,
                "created_at": biz.created_at
            });
            count += 1;
        }

        report {
            "success": True,
            "count": len(results),
            "total_in_graph": len(businesses),
            "businesses": results,
            "viewing_as": "admin" if is_admin else "user"
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 2: GetReport - Get Full Report by Business ID (No LLM Calls - Reads Stored Data)
# POST /walker/GetReport
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GetReport {
    has business_id: str;

    can start with `root entry {
        # Find the business on authenticated user's root
        businesses = [here -->(`?Business)];
        target_biz = None;

        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        # Get the report
        reports = [target_biz -->(`?Report)];
        if not reports {
            report {
                "success": False,
                "error": "No report found for this business. Run analysis first."
            };
            disengage;
        }
        r = reports[0];

        # Get the analysis
        analyses = [target_biz -->(`?Analysis)];
        if not analyses {
            report {
                "success": False,
                "error": "No analysis found for this business. Run analysis first."
            };
            disengage;
        }
        a = analyses[0];

        # Get themes
        themes = [target_biz -->(`?Theme)];

        # Build full output (same structure as AnalyzeUrl but from stored data)
        report {
            "success": True,
            "data_source": "stored",
            "from_cache": True,
            "generated_at": r.created_at,

            "business": {
                "place_id": target_biz.place_id,
                "name": target_biz.name,
                "type": target_biz.business_type,
                "type_normalized": target_biz.business_type_normalized,
                "address": target_biz.address,
                "phone": target_biz.phone,
                "website": target_biz.website,
                "google_rating": target_biz.rating,
                "total_reviews": target_biz.total_reviews,
                "reviews_analyzed": a.reviews_analyzed,
                "price_level": target_biz.price_level,
                "coordinates": {"lat": target_biz.latitude, "lng": target_biz.longitude},
                "opening_hours": target_biz.opening_hours,
                "photos_count": target_biz.photos_count
            },

            "health_score": {
                "overall": a.health_score,
                "grade": a.health_grade,
                "confidence": a.confidence_level,
                "breakdown": a.health_breakdown,
                "trend": a.trend_direction
            },

            "sentiment": {
                "distribution": {
                    "positive": {"count": a.positive_count, "percentage": a.positive_percentage},
                    "negative": {"count": a.negative_count, "percentage": a.negative_percentage},
                    "neutral": {"count": a.neutral_count, "percentage": a.neutral_percentage}
                },
                "average_score": a.sentiment_score,
                "sample_size_adequacy": a.confidence_details.get("adequacy", "")
            },

            "themes": [
                {
                    "name": t.name,
                    "mention_count": t.mention_count,
                    "sentiment_score": t.avg_sentiment,
                    "sentiment_label": "positive" if t.avg_sentiment > 0.3 else ("negative" if t.avg_sentiment < -0.3 else "mixed"),
                    "confidence": "high" if t.mention_count >= 10 else ("medium" if t.mention_count >= 5 else "low"),
                    "sub_themes": t.sub_themes,
                    "sample_quotes": {
                        "positive": t.sample_quotes_positive,
                        "negative": t.sample_quotes_negative
                    }
                }
                for t in themes
            ],

            "trends": {
                "period_analyzed": f"{len(a.monthly_breakdown)} months",
                "overall_trend": {
                    "direction": a.trend_direction,
                    "change": a.trend_change
                },
                "monthly_breakdown": a.monthly_breakdown
            },

            "critical_issues": a.critical_issues,

            "swot": {
                "strengths": a.strengths,
                "weaknesses": a.weaknesses,
                "opportunities": a.opportunities,
                "threats": a.threats
            },

            # Brand-Aware Recommendations (from stored Report node)
            "recommendations": {
                "brand_context": r.brand_context,
                "issue_severity_summary": r.issue_severity_summary,
                "immediate": r.brand_recommendations_immediate,
                "short_term": r.brand_recommendations_short_term,
                "long_term": r.brand_recommendations_long_term,
                "do_not": r.do_not_recommendations,
                "overall_risk_assessment": r.overall_risk_assessment
            },

            # Legacy recommendations (for backward compatibility)
            "recommendations_legacy": {
                "immediate": r.recommendations_immediate,
                "short_term": r.recommendations_short_term,
                "long_term": r.recommendations_long_term
            },

            "executive_summary": {
                "headline": r.headline,
                "one_liner": r.one_liner,
                "key_metric": r.key_metric,
                "full_summary": r.executive_summary
            },

            "key_findings": r.key_findings,

            "statistics": {
                "reviews_analyzed": a.reviews_analyzed,
                "date_range": {
                    "from": a.date_range_start,
                    "to": a.date_range_end
                },
                "rating_distribution": a.rating_distribution,
                "avg_review_length": a.avg_review_length,
                "reviews_with_photos": a.reviews_with_photos,
                "response_rate": f"{a.response_rate}%"
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 3: GetReviews - Get Reviews with Filtering
# POST /walker/GetReviews
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GetReviews {
    has business_id: str;
    has limit: int = 50;
    has sentiment_filter: str = "";  # "positive", "negative", "neutral", "mixed"
    has min_rating: int = 1;
    has max_rating: int = 5;
    has sort_by: str = "date";  # "date", "rating", "sentiment_score"

    

    can start with `root entry {
        # Find the business
        businesses = [here -->(`?Business)];
        target_biz = None;
        
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }
        
        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }
        
        # Get all reviews
        all_reviews = [target_biz -->(`?Review)];
        
        # Apply filters
        filtered_reviews = [];
        for r in all_reviews {
            # Sentiment filter
            if self.sentiment_filter != "" and r.sentiment != self.sentiment_filter {
                continue;
            }
            
            # Rating filter
            if r.rating < self.min_rating or r.rating > self.max_rating {
                continue;
            }
            
            filtered_reviews.append(r);
        }
        
        # Apply limit
        limited_reviews = filtered_reviews[:self.limit];
        
        # Format output
        results = [];
        for r in limited_reviews {
            # Check if review has a generated reply
            replies = [r -->(`?ReviewReply)];
            has_reply = len(replies) > 0;
            reply_data = None;
            if has_reply {
                reply_data = {
                    "reply_id": replies[0].reply_id,
                    "reply_text": replies[0].reply_text,
                    "generated_at": replies[0].generated_at
                };
            }

            results.append({
                "review_id": r.review_id,
                "author": r.author,
                "author_image": r.author_image,
                "review_link": r.review_link,
                "rating": r.rating,
                "text": r.text,
                "date": r.date,
                "sentiment": r.sentiment,
                "sentiment_score": r.sentiment_score,
                "themes": r.themes,
                "keywords": r.keywords,
                "emotion": r.emotion,
                "likes": r.likes,
                "owner_response": r.owner_response,
                "has_generated_reply": has_reply,
                "generated_reply": reply_data
            });
        }
        
        # Calculate stats
        sentiment_counts = {"positive": 0, "negative": 0, "neutral": 0, "mixed": 0};
        for r in filtered_reviews {
            if r.sentiment in sentiment_counts {
                sentiment_counts[r.sentiment] += 1;
            }
        }
        
        report {
            "success": True,
            "business": {
                "place_id": target_biz.place_id,
                "name": target_biz.name
            },
            "filters_applied": {
                "sentiment": self.sentiment_filter if self.sentiment_filter else "all",
                "rating_range": [self.min_rating, self.max_rating]
            },
            "total_reviews": len(all_reviews),
            "filtered_count": len(filtered_reviews),
            "returned_count": len(results),
            "sentiment_distribution": sentiment_counts,
            "reviews": results
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 5: Reanalyze - Re-run Analysis on Existing Data (Returns Full Output)
# POST /walker/Reanalyze
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub Reanalyze {
    has business_id: str;
    has report_type: str = "deep";
    has force_sentiment: bool = False;  # Re-run sentiment analysis too

    can start with `root entry {
        # Find the business
        businesses = [here -->(`?Business)];
        target_biz = None;

        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        stages = [];
        reviews = [target_biz -->(`?Review)];
        print(f"\n🔄 Reanalyzing business: {target_biz.name}");
        print(f"   📦 Using {len(reviews)} existing reviews");

        # Delete old analysis artifacts to prevent duplicates
        old_themes = [target_biz -->(`?Theme)];
        old_analyses = [target_biz -->(`?Analysis)];
        old_reports = [target_biz -->(`?Report)];

        for theme in old_themes {
            del theme;
        }
        for analysis in old_analyses {
            del analysis;
        }
        for report in old_reports {
            del report;
        }

        print(f"   🗑️  Cleaned up old data (themes: {len(old_themes)}, analyses: {len(old_analyses)}, reports: {len(old_reports)})");

        # Optionally re-run sentiment analysis
        if self.force_sentiment {
            # Clear existing sentiment data
            for r in reviews {
                r.sentiment = "";
                r.sentiment_score = 0.0;
                r.themes = [];
                r.keywords = [];
                r.emotion = "";
            }

            # Re-run sentiment analyzer
            analyzer = here spawn SentimentAnalyzerAgent(
                business_id=self.business_id
            );
            stages.append("sentiment");
        }

        # Re-run pattern analysis
        patterns = here spawn PatternAnalyzerAgent(
            business_id=self.business_id
        );
        stages.append("patterns");

        # Re-generate report
        reporter = here spawn ReportGeneratorAgent(
            business_id=self.business_id,
            report_type=self.report_type
        );
        stages.append("report");

        # Re-run brand-aware recommendations (Stage 5)
        recommender = here spawn RecommendationAgent(
            business_id=self.business_id
        );
        stages.append("recommendations");

        # Store brand-aware recommendations in Report node
        brand_recs = recommender.recommendations;
        report_node = reporter.report[0];

        report_node.brand_context = {
            "price_positioning": brand_recs.brand_context.price_positioning,
            "brand_positioning": brand_recs.brand_context.brand_positioning,
            "protected_strengths": brand_recs.brand_context.protected_strengths,
            "brand_risks": brand_recs.brand_context.brand_risks
        };
        report_node.issue_severity_summary = brand_recs.issue_severity_summary;
        report_node.brand_recommendations_immediate = [self.rec_to_dict(r) for r in brand_recs.recommendations_immediate];
        report_node.brand_recommendations_short_term = [self.rec_to_dict(r) for r in brand_recs.recommendations_short_term];
        report_node.brand_recommendations_long_term = [self.rec_to_dict(r) for r in brand_recs.recommendations_long_term];
        report_node.do_not_recommendations = [self.protective_to_dict(p) for p in brand_recs.do_not_recommendations];
        report_node.overall_risk_assessment = brand_recs.overall_risk_assessment;

        # Update last_analyzed_at timestamp
        target_biz.last_analyzed_at = datetime.now().isoformat();

        # Build full output (same structure as AnalyzeUrl)
        output = self.build_full_output(
            target_biz,
            patterns.analysis[0],
            [target_biz -->(`?Theme)],
            report_node,
            brand_recs,
            stages
        );

        print(f"   ✅ Reanalysis complete");
        report output;
    }

    def rec_to_dict(r: BrandAwareRecommendation) -> dict {
        return {
            "action": r.action,
            "action_type": r.action_type,
            "reason": r.reason,
            "evidence": {
                "issue": r.evidence.issue,
                "mention_count": r.evidence.mention_count,
                "mention_percentage": r.evidence.mention_percentage,
                "severity": r.evidence.severity,
                "sample_feedback": r.evidence.sample_feedback,
                "customer_segments": r.evidence.customer_segments
            },
            "expected_impact": r.expected_impact,
            "downside_risk": r.downside_risk,
            "effort": r.effort,
            "risk_level": r.risk_level,
            "confidence_level": r.confidence_level,
            "priority_score": r.priority_score,
            "caution_note": r.caution_note
        };
    }

    def protective_to_dict(p: ProtectiveRecommendation) -> dict {
        return {
            "area": p.area,
            "do_not_action": p.do_not_action,
            "rationale": p.rationale,
            "evidence_count": p.evidence_count
        };
    }

    def build_full_output(business: Business, analysis: Analysis, themes: list, report: Report, brand_recs: BrandAwareRecommendationResult, stages: list) -> dict {
        return {
            "success": True,
            "data_source": "reanalysis",
            "from_cache": True,
            "stages_rerun": stages,
            "generated_at": datetime.now().isoformat(),

            "business": {
                "place_id": business.place_id,
                "name": business.name,
                "type": business.business_type,
                "type_normalized": business.business_type_normalized,
                "address": business.address,
                "phone": business.phone,
                "website": business.website,
                "google_rating": business.rating,
                "total_reviews": business.total_reviews,
                "reviews_analyzed": analysis.reviews_analyzed,
                "price_level": business.price_level,
                "coordinates": {"lat": business.latitude, "lng": business.longitude},
                "opening_hours": business.opening_hours,
                "photos_count": business.photos_count
            },

            "health_score": {
                "overall": analysis.health_score,
                "grade": analysis.health_grade,
                "confidence": analysis.confidence_level,
                "breakdown": analysis.health_breakdown,
                "trend": analysis.trend_direction
            },

            "sentiment": {
                "distribution": {
                    "positive": {"count": analysis.positive_count, "percentage": analysis.positive_percentage},
                    "negative": {"count": analysis.negative_count, "percentage": analysis.negative_percentage},
                    "neutral": {"count": analysis.neutral_count, "percentage": analysis.neutral_percentage}
                },
                "average_score": analysis.sentiment_score,
                "sample_size_adequacy": analysis.confidence_details.get("adequacy", "")
            },

            "themes": [
                {
                    "name": t.name,
                    "mention_count": t.mention_count,
                    "sentiment_score": t.avg_sentiment,
                    "sentiment_label": "positive" if t.avg_sentiment > 0.3 else ("negative" if t.avg_sentiment < -0.3 else "mixed"),
                    "confidence": "high" if t.mention_count >= 10 else ("medium" if t.mention_count >= 5 else "low"),
                    "sub_themes": t.sub_themes,
                    "sample_quotes": {
                        "positive": t.sample_quotes_positive,
                        "negative": t.sample_quotes_negative
                    }
                }
                for t in themes
            ],

            "trends": {
                "period_analyzed": f"{len(analysis.monthly_breakdown)} months",
                "overall_trend": {
                    "direction": analysis.trend_direction,
                    "change": analysis.trend_change
                },
                "monthly_breakdown": analysis.monthly_breakdown
            },

            "critical_issues": analysis.critical_issues,

            "swot": {
                "strengths": analysis.strengths,
                "weaknesses": analysis.weaknesses,
                "opportunities": analysis.opportunities,
                "threats": analysis.threats
            },

            "recommendations": {
                "brand_context": {
                    "price_positioning": brand_recs.brand_context.price_positioning,
                    "brand_positioning": brand_recs.brand_context.brand_positioning,
                    "protected_strengths": brand_recs.brand_context.protected_strengths,
                    "brand_risks": brand_recs.brand_context.brand_risks
                },
                "issue_severity_summary": brand_recs.issue_severity_summary,
                "immediate": [self.rec_to_dict(r) for r in brand_recs.recommendations_immediate],
                "short_term": [self.rec_to_dict(r) for r in brand_recs.recommendations_short_term],
                "long_term": [self.rec_to_dict(r) for r in brand_recs.recommendations_long_term],
                "do_not": [self.protective_to_dict(p) for p in brand_recs.do_not_recommendations],
                "overall_risk_assessment": brand_recs.overall_risk_assessment
            },

            "recommendations_legacy": {
                "immediate": report.recommendations_immediate,
                "short_term": report.recommendations_short_term,
                "long_term": report.recommendations_long_term
            },

            "executive_summary": {
                "headline": report.headline,
                "one_liner": report.one_liner,
                "key_metric": report.key_metric,
                "full_summary": report.executive_summary
            },

            "key_findings": report.key_findings,

            "statistics": {
                "reviews_analyzed": analysis.reviews_analyzed,
                "date_range": {
                    "from": analysis.date_range_start,
                    "to": analysis.date_range_end
                },
                "rating_distribution": analysis.rating_distribution,
                "avg_review_length": analysis.avg_review_length,
                "reviews_with_photos": analysis.reviews_with_photos,
                "response_rate": f"{analysis.response_rate}%"
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 6: DeleteBusiness - Remove a Business and All Related Data
# POST /walker/DeleteBusiness
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub DeleteBusiness {
    has business_id: str;

    

    can start with `root entry {
        # Find the business
        businesses = [here -->(`?Business)];
        target_biz = None;
        
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }
        
        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }
        
        # Count what we're deleting
        reviews_count = len([target_biz -->(`?Review)]);
        themes_count = len([target_biz -->(`?Theme)]);
        analyses_count = len([target_biz -->(`?Analysis)]);
        reports_count = len([target_biz -->(`?Report)]);
        
        business_name = target_biz.name;
        
        # Delete connected nodes (Jac handles cascading)
        del target_biz;
        
        report {
            "success": True,
            "deleted": {
                "business": business_name,
                "business_id": self.business_id,
                "reviews": reviews_count,
                "themes": themes_count,
                "analyses": analyses_count,
                "reports": reports_count
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 7: GetStats - Get Overall System Statistics
# POST /walker/GetStats
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GetStats {
    

    can start with `root entry {
        businesses = [here -->(`?Business)];
        
        total_businesses = len(businesses);
        total_reviews = 0;
        total_themes = 0;
        completed_count = 0;
        pending_count = 0;
        
        sentiment_totals = {"positive": 0, "negative": 0, "neutral": 0, "mixed": 0};
        
        for biz in businesses {
            reviews = [biz -->(`?Review)];
            total_reviews += len(reviews);
            total_themes += len([biz -->(`?Theme)]);
            
            if biz.status == "completed" {
                completed_count += 1;
            } else {
                pending_count += 1;
            }
            
            for r in reviews {
                if r.sentiment in sentiment_totals {
                    sentiment_totals[r.sentiment] += 1;
                }
            }
        }
        
        report {
            "success": True,
            "stats": {
                "total_businesses": total_businesses,
                "completed_analyses": completed_count,
                "pending_analyses": pending_count,
                "total_reviews": total_reviews,
                "total_themes": total_themes,
                "sentiment_distribution": sentiment_totals,
                "avg_reviews_per_business": total_reviews / total_businesses if total_businesses > 0 else 0
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# REVIEW REPLY SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

# Credit cost for reply generation
glob REPLY_CREDIT_COST: float = 0.25;

# ═══════════════════════════════════════════════════════════════════════════════
# API: SaveReplyPromptConfig - Save/Update Reply Preferences
# POST /walker/SaveReplyPromptConfig
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub SaveReplyPromptConfig {
    has tone: str = "friendly_professional";
    has max_length: str = "medium";
    has include_name: bool = True;
    has offer_resolution: bool = True;
    has sign_off: str = "";
    has custom_instructions: str = "";

    can start with `root entry {
        # Check for existing config
        existing_configs = [here -->(`?ReplyPromptConfig)];

        if existing_configs {
            # Update existing config
            config = existing_configs[0];
            config.tone = self.tone;
            config.max_length = self.max_length;
            config.include_name = self.include_name;
            config.offer_resolution = self.offer_resolution;
            config.sign_off = self.sign_off;
            config.custom_instructions = self.custom_instructions;
            config.updated_at = datetime.now().isoformat();

            report {
                "success": True,
                "message": "Reply configuration updated",
                "config": {
                    "tone": config.tone,
                    "max_length": config.max_length,
                    "include_name": config.include_name,
                    "offer_resolution": config.offer_resolution,
                    "sign_off": config.sign_off,
                    "custom_instructions": config.custom_instructions
                }
            };
        } else {
            # Create new config
            new_config = ReplyPromptConfig(
                tone=self.tone,
                max_length=self.max_length,
                include_name=self.include_name,
                offer_resolution=self.offer_resolution,
                sign_off=self.sign_off,
                custom_instructions=self.custom_instructions,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            );

            here ++> new_config;

            report {
                "success": True,
                "message": "Reply configuration created",
                "config": {
                    "tone": new_config.tone,
                    "max_length": new_config.max_length,
                    "include_name": new_config.include_name,
                    "offer_resolution": new_config.offer_resolution,
                    "sign_off": new_config.sign_off,
                    "custom_instructions": new_config.custom_instructions
                }
            };
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API: GetReplyPromptConfig - Get Current Reply Configuration
# POST /walker/GetReplyPromptConfig
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GetReplyPromptConfig {
    can start with `root entry {
        configs = [here -->(`?ReplyPromptConfig)];

        if configs {
            config = configs[0];
            report {
                "success": True,
                "config": {
                    "tone": config.tone,
                    "max_length": config.max_length,
                    "include_name": config.include_name,
                    "offer_resolution": config.offer_resolution,
                    "sign_off": config.sign_off,
                    "custom_instructions": config.custom_instructions,
                    "created_at": config.created_at,
                    "updated_at": config.updated_at
                }
            };
        } else {
            # Return default config
            report {
                "success": True,
                "config": {
                    "tone": "friendly_professional",
                    "max_length": "medium",
                    "include_name": True,
                    "offer_resolution": True,
                    "sign_off": "",
                    "custom_instructions": "",
                    "created_at": None,
                    "updated_at": None
                },
                "is_default": True,
                "message": "Using default configuration. Use SaveReplyPromptConfig to customize."
            };
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API: GenerateReviewReply - Generate Reply for Single Review
# POST /walker/GenerateReviewReply
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GenerateReviewReply {
    has business_id: str;
    has review_id: str;

    can start with `root entry {
        # Get user profile for credit check
        profiles = [here -->(`?UserProfile)];
        if not profiles {
            report {
                "success": False,
                "error": "User profile not found"
            };
            disengage;
        }
        profile = profiles[0];

        # Check credits
        if profile.credits < REPLY_CREDIT_COST {
            report {
                "success": False,
                "error": f"Insufficient credits. Required: {REPLY_CREDIT_COST}, Available: {profile.credits}"
            };
            disengage;
        }

        # Find business
        businesses = [here -->(`?Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        # Find review
        reviews = [target_biz -->(`?Review)];
        target_review = None;
        for r in reviews {
            if r.review_id == self.review_id {
                target_review = r;
                break;
            }
        }

        if target_review is None {
            report {
                "success": False,
                "error": f"Review not found: {self.review_id}"
            };
            disengage;
        }

        # Check if reply already exists
        existing_replies = [target_review -->(`?ReviewReply)];
        if existing_replies {
            report {
                "success": False,
                "error": "Reply already exists for this review",
                "existing_reply": {
                    "reply_id": existing_replies[0].reply_id,
                    "reply_text": existing_replies[0].reply_text,
                    "generated_at": existing_replies[0].generated_at
                }
            };
            disengage;
        }

        # Get reply config (or use defaults)
        configs = [here -->(`?ReplyPromptConfig)];
        config = configs[0] if configs else None;

        # Get business analysis for context
        analyses = [target_biz -->(`?Analysis)];
        analysis = analyses[0] if analyses else None;

        # Build context for LLM
        business_context = {
            "name": target_biz.name,
            "type": target_biz.business_type,
            "rating": target_biz.rating,
            "strengths": analysis.delighters if analysis else [],
            "known_issues": analysis.pain_points if analysis else []
        };

        review_data = {
            "author": target_review.author,
            "rating": target_review.rating,
            "text": target_review.text,
            "sentiment": target_review.sentiment,
            "themes": target_review.themes,
            "emotion": target_review.emotion
        };

        reply_config = {
            "tone": config.tone if config else "friendly_professional",
            "max_length": config.max_length if config else "medium",
            "include_name": config.include_name if config else True,
            "offer_resolution": config.offer_resolution if config else True,
            "sign_off": config.sign_off if config else target_biz.name,
            "custom_instructions": config.custom_instructions if config else ""
        };

        # Generate reply using LLM
        result = self.generate_reply(
            business_context=business_context,
            review_data=review_data,
            reply_config=reply_config
        );

        # Deduct credits
        profile.credits -= REPLY_CREDIT_COST;
        profile.credits_used += REPLY_CREDIT_COST;

        # Create and save reply node
        reply_node = ReviewReply(
            reply_id=str(uuid4()),
            reply_text=result.reply_text,
            generated_at=datetime.now().isoformat(),
            credits_used=REPLY_CREDIT_COST,
            tone_used=reply_config["tone"],
            review_sentiment=target_review.sentiment,
            review_rating=target_review.rating
        );

        target_review ++> reply_node;

        # Create credit transaction record
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="reply",
            amount=-REPLY_CREDIT_COST,
            balance_after=profile.credits,
            description=f"Reply to review by {target_review.author}",
            related_business_id=target_biz.place_id,
            related_review_id=target_review.review_id,
            created_at=datetime.now().isoformat()
        );
        here ++> txn;

        report {
            "success": True,
            "reply": {
                "reply_id": reply_node.reply_id,
                "reply_text": reply_node.reply_text,
                "generated_at": reply_node.generated_at
            },
            "review": {
                "review_id": target_review.review_id,
                "author": target_review.author,
                "rating": target_review.rating,
                "sentiment": target_review.sentiment
            },
            "credits": {
                "used": REPLY_CREDIT_COST,
                "remaining": profile.credits
            }
        };
    }

    """Generate a professional reply to a customer review.

    Create a thoughtful, personalized response based on the review content,
    business context, and configured reply style. The reply should:
    - Address specific points mentioned in the review
    - Match the configured tone (friendly, formal, casual, friendly_professional)
    - Be appropriate length based on max_length setting
    - For negative reviews: acknowledge concerns, apologize if warranted, offer resolution
    - For positive reviews: express gratitude, highlight mentioned positives, invite return
    - Include reviewer name if configured
    - End with configured sign-off

    Args:
        business_context: Business name, type, strengths, and known issues
        review_data: Review author, rating, text, sentiment, themes, emotion
        reply_config: Tone, length, name inclusion, resolution offer, sign-off, custom instructions

    Returns:
        GeneratedReplyResult with the reply text
    """
    def generate_reply(
        business_context: dict,
        review_data: dict,
        reply_config: dict
    ) -> GeneratedReplyResult by llm(
        temperature=0.7,
        incl_info={
            "business": business_context,
            "review": review_data,
            "config": reply_config,
            "guidelines": """
                - Be genuine and specific, not generic
                - Reference specific details from the review
                - For negative reviews (1-2 stars): Apologize sincerely, acknowledge specific issues, offer to make it right
                - For neutral reviews (3 stars): Thank them, address any concerns, highlight positives
                - For positive reviews (4-5 stars): Express genuine gratitude, reinforce what they loved, invite them back
                - Never be defensive or dismissive
                - Keep the response professional but warm
                - If custom_instructions provided, incorporate them
            """
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# API: BulkGenerateReviewReplies - Generate Replies for Multiple Reviews
# POST /walker/BulkGenerateReviewReplies
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub BulkGenerateReviewReplies {
    has business_id: str;
    has review_ids: list[str] = [];           # Specific review IDs to reply to
    has filter_sentiment: str = "";            # Filter: "positive", "negative", "neutral", "mixed"
    has filter_no_reply: bool = True;          # Only reviews without existing replies
    has max_replies: int = 10;                 # Maximum replies to generate

    can start with `root entry {
        # Get user profile for credit check
        profiles = [here -->(`?UserProfile)];
        if not profiles {
            report {
                "success": False,
                "error": "User profile not found"
            };
            disengage;
        }
        profile = profiles[0];

        # Find business
        businesses = [here -->(`?Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        # Get all reviews
        all_reviews = [target_biz -->(`?Review)];

        # Filter reviews
        reviews_to_process = [];

        if self.review_ids {
            # Use specific review IDs
            for r in all_reviews {
                if r.review_id in self.review_ids {
                    # Check if already has reply
                    if self.filter_no_reply {
                        existing = [r -->(`?ReviewReply)];
                        if existing {
                            continue;
                        }
                    }
                    reviews_to_process.append(r);
            }
        } else {
            # Apply filters
            for r in all_reviews {
                # Sentiment filter
                if self.filter_sentiment and r.sentiment != self.filter_sentiment {
                    continue;
                }

                # No reply filter
                if self.filter_no_reply {
                    existing = [r -->(`?ReviewReply)];
                    if existing {
                        continue;
                    }
                }

                reviews_to_process.append(r);

                if len(reviews_to_process) >= self.max_replies {
                    break;
                }
            }
        }

        if not reviews_to_process {
            report {
                "success": True,
                "message": "No reviews found matching criteria",
                "replies_generated": 0
            };
            disengage;
        }

        # Calculate total credits needed
        total_credits_needed = len(reviews_to_process) * REPLY_CREDIT_COST;

        if profile.credits < total_credits_needed {
            # Calculate how many we can afford
            affordable_count = int(profile.credits / REPLY_CREDIT_COST);
            if affordable_count == 0 {
                report {
                    "success": False,
                    "error": f"Insufficient credits. Required: {total_credits_needed}, Available: {profile.credits}",
                    "reviews_requested": len(reviews_to_process)
                };
                disengage;
            }
            # Limit to what we can afford
            reviews_to_process = reviews_to_process[:affordable_count];
            total_credits_needed = affordable_count * REPLY_CREDIT_COST;
        }

        # Get reply config
        configs = [here -->(`?ReplyPromptConfig)];
        config = configs[0] if configs else None;

        # Get business analysis for context
        analyses = [target_biz -->(`?Analysis)];
        analysis = analyses[0] if analyses else None;

        business_context = {
            "name": target_biz.name,
            "type": target_biz.business_type,
            "rating": target_biz.rating,
            "strengths": analysis.delighters if analysis else [],
            "known_issues": analysis.pain_points if analysis else []
        };

        reply_config = {
            "tone": config.tone if config else "friendly_professional",
            "max_length": config.max_length if config else "medium",
            "include_name": config.include_name if config else True,
            "offer_resolution": config.offer_resolution if config else True,
            "sign_off": config.sign_off if config else target_biz.name,
            "custom_instructions": config.custom_instructions if config else ""
        };

        # Generate replies
        generated_replies = [];
        failed_replies = [];

        for r in reviews_to_process {
            review_data = {
                "review_id": r.review_id,
                "author": r.author,
                "rating": r.rating,
                "text": r.text,
                "sentiment": r.sentiment,
                "themes": r.themes,
                "emotion": r.emotion
            };

            try {
                result = self.generate_single_reply(
                    business_context=business_context,
                    review_data=review_data,
                    reply_config=reply_config
                );

                # Deduct credits
                profile.credits -= REPLY_CREDIT_COST;
                profile.credits_used += REPLY_CREDIT_COST;

                # Create reply node
                reply_node = ReviewReply(
                    reply_id=str(uuid4()),
                    reply_text=result.reply_text,
                    generated_at=datetime.now().isoformat(),
                    credits_used=REPLY_CREDIT_COST,
                    tone_used=reply_config["tone"],
                    review_sentiment=r.sentiment,
                    review_rating=r.rating
                );

                r ++> reply_node;

                # Create credit transaction record
                txn = CreditTransaction(
                    transaction_id=str(uuid4()),
                    user_id=profile.username,
                    transaction_type="reply",
                    amount=-REPLY_CREDIT_COST,
                    balance_after=profile.credits,
                    description=f"Bulk reply to review by {r.author}",
                    related_business_id=target_biz.place_id,
                    related_review_id=r.review_id,
                    created_at=datetime.now().isoformat()
                );
                here ++> txn;

                generated_replies.append({
                    "review_id": r.review_id,
                    "reply_id": reply_node.reply_id,
                    "reply_text": reply_node.reply_text,
                    "author": r.author,
                    "rating": r.rating,
                    "sentiment": r.sentiment
                });
            } except Exception as e {
                failed_replies.append({
                    "review_id": r.review_id,
                    "error": str(e)
                });
            }
        }

        report {
            "success": True,
            "business": {
                "place_id": target_biz.place_id,
                "name": target_biz.name
            },
            "summary": {
                "total_requested": len(reviews_to_process),
                "generated": len(generated_replies),
                "failed": len(failed_replies)
            },
            "credits": {
                "used": len(generated_replies) * REPLY_CREDIT_COST,
                "remaining": profile.credits
            },
            "replies": generated_replies,
            "failures": failed_replies if failed_replies else None
        };
    }

    """Generate a reply for a single review in bulk processing."""
    def generate_single_reply(
        business_context: dict,
        review_data: dict,
        reply_config: dict
    ) -> GeneratedReplyResult by llm(
        temperature=0.7,
        incl_info={
            "business": business_context,
            "review": review_data,
            "config": reply_config,
            "guidelines": """
                - Be genuine and specific, not generic
                - Reference specific details from the review
                - For negative reviews (1-2 stars): Apologize sincerely, acknowledge specific issues, offer to make it right
                - For neutral reviews (3 stars): Thank them, address any concerns, highlight positives
                - For positive reviews (4-5 stars): Express genuine gratitude, reinforce what they loved, invite them back
                - Never be defensive or dismissive
                - Keep the response professional but warm
            """
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# API: GetReviewReplies - Get Generated Replies for a Business
# POST /walker/GetReviewReplies
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub GetReviewReplies {
    has business_id: str;
    has limit: int = 50;

    can start with `root entry {
        # Find business
        businesses = [here -->(`?Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        # Get all reviews with replies
        reviews = [target_biz -->(`?Review)];
        results = [];
        count = 0;

        for r in reviews {
            if count >= self.limit {
                break;
            }

            replies = [r -->(`?ReviewReply)];
            if replies {
                reply = replies[0];
                results.append({
                    "review": {
                        "review_id": r.review_id,
                        "author": r.author,
                        "rating": r.rating,
                        "text": r.text[:200] + "..." if len(r.text) > 200 else r.text,
                        "sentiment": r.sentiment,
                        "date": r.date
                    },
                    "reply": {
                        "reply_id": reply.reply_id,
                        "reply_text": reply.reply_text,
                        "generated_at": reply.generated_at,
                        "tone_used": reply.tone_used,
                        "credits_used": reply.credits_used
                    }
                });
                count += 1;
            }
        }

        # Count stats
        total_reviews = len(reviews);
        reviews_with_replies = len(results);

        report {
            "success": True,
            "business": {
                "place_id": target_biz.place_id,
                "name": target_biz.name
            },
            "stats": {
                "total_reviews": total_reviews,
                "reviews_with_replies": reviews_with_replies,
                "reply_coverage": f"{(reviews_with_replies / total_reviews * 100):.1f}%" if total_reviews > 0 else "0%"
            },
            "replies": results
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API: RegenerateReviewReply - Regenerate Reply for a Review (Replaces Existing)
# POST /walker/RegenerateReviewReply
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub RegenerateReviewReply {
    has business_id: str;
    has review_id: str;

    can start with `root entry {
        # Get user profile for credit check
        profiles = [here -->(`?UserProfile)];
        if not profiles {
            report {
                "success": False,
                "error": "User profile not found"
            };
            disengage;
        }
        profile = profiles[0];

        # Check credits
        if profile.credits < REPLY_CREDIT_COST {
            report {
                "success": False,
                "error": f"Insufficient credits. Required: {REPLY_CREDIT_COST}, Available: {profile.credits}"
            };
            disengage;
        }

        # Find business
        businesses = [here -->(`?Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        # Find review
        reviews = [target_biz -->(`?Review)];
        target_review = None;
        for r in reviews {
            if r.review_id == self.review_id {
                target_review = r;
                break;
            }
        }

        if target_review is None {
            report {
                "success": False,
                "error": f"Review not found: {self.review_id}"
            };
            disengage;
        }

        # Delete existing reply if any
        existing_replies = [target_review -->(`?ReviewReply)];
        old_reply_text = "";
        for old_reply in existing_replies {
            old_reply_text = old_reply.reply_text;
            del old_reply;
        }

        # Get reply config (or use defaults)
        configs = [here -->(`?ReplyPromptConfig)];
        config = configs[0] if configs else None;

        # Get business analysis for context
        analyses = [target_biz -->(`?Analysis)];
        analysis = analyses[0] if analyses else None;

        # Build context for LLM
        business_context = {
            "name": target_biz.name,
            "type": target_biz.business_type,
            "rating": target_biz.rating,
            "strengths": analysis.delighters if analysis else [],
            "known_issues": analysis.pain_points if analysis else []
        };

        review_data = {
            "author": target_review.author,
            "rating": target_review.rating,
            "text": target_review.text,
            "sentiment": target_review.sentiment,
            "themes": target_review.themes,
            "emotion": target_review.emotion
        };

        reply_config = {
            "tone": config.tone if config else "friendly_professional",
            "max_length": config.max_length if config else "medium",
            "include_name": config.include_name if config else True,
            "offer_resolution": config.offer_resolution if config else True,
            "sign_off": config.sign_off if config else target_biz.name,
            "custom_instructions": config.custom_instructions if config else ""
        };

        # Generate new reply using LLM
        result = self.generate_reply(
            business_context=business_context,
            review_data=review_data,
            reply_config=reply_config
        );

        # Deduct credits
        profile.credits -= REPLY_CREDIT_COST;
        profile.credits_used += REPLY_CREDIT_COST;

        # Create and save new reply node
        reply_node = ReviewReply(
            reply_id=str(uuid4()),
            reply_text=result.reply_text,
            generated_at=datetime.now().isoformat(),
            credits_used=REPLY_CREDIT_COST,
            tone_used=reply_config["tone"],
            review_sentiment=target_review.sentiment,
            review_rating=target_review.rating
        );

        target_review ++> reply_node;

        # Create credit transaction record
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="reply",
            amount=-REPLY_CREDIT_COST,
            balance_after=profile.credits,
            description=f"Regenerate reply to review by {target_review.author}",
            related_business_id=target_biz.place_id,
            related_review_id=target_review.review_id,
            created_at=datetime.now().isoformat()
        );
        here ++> txn;

        report {
            "success": True,
            "regenerated": True,
            "reply": {
                "reply_id": reply_node.reply_id,
                "reply_text": reply_node.reply_text,
                "generated_at": reply_node.generated_at
            },
            "previous_reply": old_reply_text if old_reply_text else None,
            "review": {
                "review_id": target_review.review_id,
                "author": target_review.author,
                "rating": target_review.rating,
                "sentiment": target_review.sentiment
            },
            "credits": {
                "used": REPLY_CREDIT_COST,
                "remaining": profile.credits
            }
        };
    }

    """Generate a professional reply to a customer review."""
    def generate_reply(
        business_context: dict,
        review_data: dict,
        reply_config: dict
    ) -> GeneratedReplyResult by llm(
        temperature=0.7,
        incl_info={
            "business": business_context,
            "review": review_data,
            "config": reply_config,
            "guidelines": """
                - Be genuine and specific, not generic
                - Reference specific details from the review
                - For negative reviews (1-2 stars): Apologize sincerely, acknowledge specific issues, offer to make it right
                - For neutral reviews (3 stars): Thank them, address any concerns, highlight positives
                - For positive reviews (4-5 stars): Express genuine gratitude, reinforce what they loved, invite them back
                - Never be defensive or dismissive
                - Keep the response professional but warm
            """
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# API: DeleteReviewReply - Delete a Generated Reply
# POST /walker/DeleteReviewReply
# ═══════════════════════════════════════════════════════════════════════════════

walker:pub DeleteReviewReply {
    has business_id: str;
    has review_id: str;

    can start with `root entry {
        # Find business
        businesses = [here -->(`?Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report {
                "success": False,
                "error": f"Business not found: {self.business_id}"
            };
            disengage;
        }

        # Find review
        reviews = [target_biz -->(`?Review)];
        target_review = None;
        for r in reviews {
            if r.review_id == self.review_id {
                target_review = r;
                break;
            }
        }

        if target_review is None {
            report {
                "success": False,
                "error": f"Review not found: {self.review_id}"
            };
            disengage;
        }

        # Find and delete reply
        replies = [target_review -->(`?ReviewReply)];
        if not replies {
            report {
                "success": False,
                "error": "No reply found for this review"
            };
            disengage;
        }

        deleted_reply_id = replies[0].reply_id;
        deleted_reply_text = replies[0].reply_text;
        del replies[0];

        report {
            "success": True,
            "deleted": {
                "reply_id": deleted_reply_id,
                "reply_text": deleted_reply_text[:100] + "..." if len(deleted_reply_text) > 100 else deleted_reply_text
            },
            "review": {
                "review_id": target_review.review_id,
                "author": target_review.author
            }
        };
    }
}