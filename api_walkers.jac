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
# API 1: AnalyzeUrl - Full Pipeline from URL
# POST /walker/AnalyzeUrl
# ═══════════════════════════════════════════════════════════════════════════════

walker AnalyzeUrl {
    has url: str;
    has max_reviews: int = 100;
    has report_type: str = "executive";
    has api_key: str = "";
    has force_mock: bool = False;  # Force mock data for testing
    
    # Results stored on walker for direct access
    has success: bool = False;
    has business_id: str = "";
    has stages_completed: list = [];
    has final_report: dict = {};
    has error: str = "";
    has data_source: str = "";  # "serpapi" or "mock"
    
    can start with `root entry {
        # Run the full pipeline
        pipeline = here spawn FullPipelineAgent(
            url=self.url,
            max_reviews=self.max_reviews,
            report_type=self.report_type,
            serp_api_key=self.api_key,
            force_mock=self.force_mock
        );
        
        if pipeline.status == "completed" {
            # Store results on walker for direct access
            self.success = True;
            self.business_id = pipeline.business_id;
            self.stages_completed = pipeline.stages_completed;
            self.final_report = pipeline.final_report;
            self.data_source = pipeline.data_source;
            
            report {
                "success": True,
                "business_id": pipeline.business_id,
                "stages_completed": pipeline.stages_completed,
                "data_source": pipeline.data_source,
                "report": pipeline.final_report
            };
        } else {
            self.success = False;
            self.error = pipeline.error;
            
            report {
                "success": False,
                "error": pipeline.error,
                "status": pipeline.status
            };
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 2: GetBusinesses - List All Analyzed Businesses
# POST /walker/GetBusinesses
# ═══════════════════════════════════════════════════════════════════════════════

walker GetBusinesses {
    has limit: int = 20;
    has status_filter: str = "";  # "pending", "fetched", "analyzed", "completed"
    
    can start with `root entry {
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
                "fetched_at": biz.fetched_at
            });
            count += 1;
        }
        
        report {
            "success": True,
            "count": len(results),
            "total_in_graph": len(businesses),
            "businesses": results
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 3: GetReport - Get Report by Business ID
# POST /walker/GetReport
# ═══════════════════════════════════════════════════════════════════════════════

walker GetReport {
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
        
        report {
            "success": True,
            "business": {
                "place_id": target_biz.place_id,
                "name": target_biz.name,
                "rating": target_biz.rating
            },
            "report": {
                "report_id": r.report_id,
                "report_type": r.report_type,
                "created_at": r.created_at,
                "target_audience": r.target_audience,
                "title": r.title,
                "executive_summary": r.executive_summary,
                "key_findings": r.key_findings,
                "recommendations": r.recommendations,
                "action_items": r.action_items,
                "sections": r.sections,
                "word_count": r.word_count,
                "reading_time_minutes": r.reading_time_minutes
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 4: GetAnalysis - Get Detailed Analysis by Business ID
# POST /walker/GetAnalysis
# ═══════════════════════════════════════════════════════════════════════════════

walker GetAnalysis {
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
        theme_data = [];
        for t in themes {
            theme_data.append({
                "name": t.name,
                "category": t.category,
                "mention_count": t.mention_count,
                "positive_count": t.positive_count,
                "negative_count": t.negative_count,
                "neutral_count": t.neutral_count,
                "avg_sentiment": t.avg_sentiment,
                "sample_quotes": t.sample_quotes
            });
        }
        
        # Sort themes by mention count (manual sort since lambda may not work)
        for i in range(len(theme_data)) {
            for j in range(i + 1, len(theme_data)) {
                if theme_data[j]["mention_count"] > theme_data[i]["mention_count"] {
                    temp = theme_data[i];
                    theme_data[i] = theme_data[j];
                    theme_data[j] = temp;
                }
            }
        }
        
        report {
            "success": True,
            "business": {
                "place_id": target_biz.place_id,
                "name": target_biz.name,
                "rating": target_biz.rating,
                "total_reviews": target_biz.total_reviews
            },
            "analysis": {
                "analysis_id": a.analysis_id,
                "created_at": a.created_at,
                "overall_sentiment": a.overall_sentiment,
                "sentiment_score": a.sentiment_score,
                "confidence": a.confidence,
                "sentiment_breakdown": {
                    "positive": a.positive_percentage,
                    "negative": a.negative_percentage,
                    "neutral": a.neutral_percentage
                },
                "strengths": a.strengths,
                "weaknesses": a.weaknesses,
                "opportunities": a.opportunities,
                "pain_points": a.pain_points,
                "delighters": a.delighters
            },
            "themes": theme_data
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 5: GetReviews - Get Reviews with Filtering
# POST /walker/GetReviews
# ═══════════════════════════════════════════════════════════════════════════════

walker GetReviews {
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
            results.append({
                "review_id": r.review_id,
                "author": r.author,
                "rating": r.rating,
                "text": r.text,
                "date": r.date,
                "sentiment": r.sentiment,
                "sentiment_score": r.sentiment_score,
                "themes": r.themes,
                "keywords": r.keywords,
                "emotion": r.emotion,
                "likes": r.likes,
                "owner_response": r.owner_response
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
# API 6: Reanalyze - Re-run Analysis on Existing Data
# POST /walker/Reanalyze
# ═══════════════════════════════════════════════════════════════════════════════

walker Reanalyze {
    has business_id: str;
    has report_type: str = "executive";
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
        
        # Optionally re-run sentiment analysis
        if self.force_sentiment {
            # Clear existing sentiment data
            reviews = [target_biz -->(`?Review)];
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
        pattern_analyzer = here spawn PatternAnalyzerAgent(
            business_id=self.business_id
        );
        stages.append("patterns");
        
        # Re-generate report
        report_gen = here spawn ReportGeneratorAgent(
            business_id=self.business_id,
            report_type=self.report_type
        );
        stages.append("report");
        
        report {
            "success": True,
            "business_id": self.business_id,
            "stages_rerun": stages,
            "new_report": {
                "report_id": report_gen.report[0].report_id,
                "title": report_gen.report[0].title,
                "key_findings_count": len(report_gen.report[0].key_findings),
                "recommendations_count": len(report_gen.report[0].recommendations)
            }
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# API 7: DeleteBusiness - Remove a Business and All Related Data
# POST /walker/DeleteBusiness
# ═══════════════════════════════════════════════════════════════════════════════

walker DeleteBusiness {
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
# API 8: GetStats - Get Overall System Statistics
# POST /walker/GetStats
# ═══════════════════════════════════════════════════════════════════════════════

walker GetStats {
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