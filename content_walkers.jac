# ══════════════════════════════════════════════════════════════════════════════
# CONTENT GENERATION WALKERS
# ══════════════════════════════════════════════════════════════════════════════
# Features:
#   1. Response Template Library (FREE tier)
#   2. Action Plan Generator (Premium - 0.5 credits)
#   3. Social Media Post Generator (Premium - 0.25 credits/batch)
#   4. Marketing Copy Generator (Premium - 0.25 credits/batch)
#   5. Blog Post Generator (Premium - 1.0 credits)
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }
import from uuid { uuid4 }
import re, os;

# LLM Setup
import from byllm.lib { Model }
glob OPENAI_API_KEY: str = os.getenv('OPENAI_API_KEY', '');
glob LLM_MODEL: str = os.getenv('LLM_MODEL', 'gpt-4o-mini');

glob llm = Model(
    model_name=LLM_MODEL,
    config={"verbose": False},
    api_key=OPENAI_API_KEY
);

include models;
include errors;

# ═══════════════════════════════════════════════════════════════════════════════
# CREDIT COST GLOBALS
# ═══════════════════════════════════════════════════════════════════════════════

glob ACTION_PLAN_CREDIT_COST: float = 0.5;
glob SOCIAL_POST_CREDIT_COST: float = 0.25;
glob MARKETING_COPY_CREDIT_COST: float = 0.25;
glob BLOG_POST_CREDIT_COST: float = 1.0;

# ═══════════════════════════════════════════════════════════════════════════════
# SYSTEM TEMPLATE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

glob SYSTEM_TEMPLATES: list[dict] = [
    # ── Positive Review Templates (rating 4-5) ──
    {
        "name": "Grateful Acknowledgment",
        "category": "positive",
        "scenario": "praise",
        "business_type": "GENERIC",
        "template_text": "Thank you so much, {reviewer_name}! We're thrilled to hear you enjoyed {specific_mention}. Our team works hard to deliver {business_strength}, and your kind words mean the world. We look forward to welcoming you back! - {sign_off}",
        "tone": "friendly_professional"
    },
    {
        "name": "First Visit Thank You",
        "category": "positive",
        "scenario": "first_visit",
        "business_type": "GENERIC",
        "template_text": "Welcome to the {business_name} family, {reviewer_name}! We're so glad your first visit was a great experience. We'd love to have you back soon - there's always something new to discover! - {sign_off}",
        "tone": "friendly"
    },
    {
        "name": "Return Visit Appreciation",
        "category": "positive",
        "scenario": "return_visit",
        "business_type": "GENERIC",
        "template_text": "Thank you for being a loyal supporter, {reviewer_name}! It means so much that you keep coming back. We're always striving to make each visit even better. See you again soon! - {sign_off}",
        "tone": "friendly"
    },
    {
        "name": "Detailed Praise Response",
        "category": "positive",
        "scenario": "detailed_feedback",
        "business_type": "GENERIC",
        "template_text": "Wow, {reviewer_name}, thank you for such a detailed and thoughtful review! We're especially glad you noticed {specific_mention}. It's feedback like yours that motivates our team to keep raising the bar. - {sign_off}",
        "tone": "friendly_professional"
    },
    {
        "name": "Restaurant - Food Praise",
        "category": "positive",
        "scenario": "praise",
        "business_type": "RESTAURANT",
        "template_text": "Thank you, {reviewer_name}! We're delighted you loved {specific_mention}. Our chefs put their heart into every dish, and it's wonderful to hear it shows. Can't wait to serve you again! - {sign_off}",
        "tone": "friendly"
    },
    {
        "name": "Hotel - Stay Appreciation",
        "category": "positive",
        "scenario": "praise",
        "business_type": "HOTEL",
        "template_text": "Thank you for choosing to stay with us, {reviewer_name}! We're so pleased that {specific_mention} made your stay memorable. We hope to welcome you back for another wonderful experience. - {sign_off}",
        "tone": "friendly_professional"
    },
    # ── Negative Review Templates (rating 1-2) ──
    {
        "name": "Sincere Apology with Resolution",
        "category": "negative",
        "scenario": "complaint_service",
        "business_type": "GENERIC",
        "template_text": "Dear {reviewer_name}, thank you for sharing your experience. We sincerely apologize for {specific_issue}. This is not the standard we strive for. We'd like to make this right - please reach out to us at {contact_info} so we can address your concerns personally. - {sign_off}",
        "tone": "formal"
    },
    {
        "name": "Quality Complaint Response",
        "category": "negative",
        "scenario": "complaint_quality",
        "business_type": "GENERIC",
        "template_text": "Dear {reviewer_name}, we're sorry to hear about your experience with {specific_issue}. Quality is extremely important to us, and we take your feedback seriously. We've shared your comments with our team and are taking steps to address this. Please contact us at {contact_info} - we'd love the chance to make it up to you. - {sign_off}",
        "tone": "formal"
    },
    {
        "name": "Restaurant - Bad Experience",
        "category": "negative",
        "scenario": "complaint_service",
        "business_type": "RESTAURANT",
        "template_text": "Dear {reviewer_name}, we're truly sorry about {specific_issue}. Your dining experience should have been much better, and we take full responsibility. We've addressed this with our team. We'd love a chance to show you the experience we're known for - please reach out to us at {contact_info}. - {sign_off}",
        "tone": "formal"
    },
    {
        "name": "Hotel - Stay Complaint",
        "category": "negative",
        "scenario": "complaint_quality",
        "business_type": "HOTEL",
        "template_text": "Dear {reviewer_name}, we sincerely apologize that your stay did not meet expectations. {specific_issue} is unacceptable, and we've addressed this with our housekeeping/maintenance team immediately. We'd appreciate the opportunity to make it right - please contact us at {contact_info}. - {sign_off}",
        "tone": "formal"
    },
    # ── Neutral / Mixed Review Templates (rating 3) ──
    {
        "name": "Balanced Acknowledgment",
        "category": "neutral",
        "scenario": "detailed_feedback",
        "business_type": "GENERIC",
        "template_text": "Thank you for your honest feedback, {reviewer_name}. We're glad you enjoyed {positive_aspect}, and we appreciate your input about {area_for_improvement}. We're always working to improve, and your feedback helps us do that. - {sign_off}",
        "tone": "friendly_professional"
    },
    {
        "name": "Suggestion Acknowledgment",
        "category": "neutral",
        "scenario": "suggestion",
        "business_type": "GENERIC",
        "template_text": "Thank you for your thoughtful suggestion, {reviewer_name}. We really appreciate you taking the time to share your ideas about {area_for_improvement}. We'll definitely consider this as we continue to improve. - {sign_off}",
        "tone": "friendly_professional"
    },
    {
        "name": "Question Response",
        "category": "neutral",
        "scenario": "question",
        "business_type": "GENERIC",
        "template_text": "Hi {reviewer_name}, thank you for reaching out! Regarding your question about {specific_mention} - {answer_or_redirect}. Feel free to contact us at {contact_info} for more details. - {sign_off}",
        "tone": "friendly"
    },
    # ── Mixed Review Templates ──
    {
        "name": "Mixed Review - Appreciate & Address",
        "category": "mixed",
        "scenario": "detailed_feedback",
        "business_type": "GENERIC",
        "template_text": "Thank you for your balanced feedback, {reviewer_name}. We're happy to hear you enjoyed {positive_aspect}! We also take note of your thoughts on {area_for_improvement} and are actively working to improve in that area. We hope to earn a 5-star experience next time! - {sign_off}",
        "tone": "friendly_professional"
    },
    {
        "name": "Restaurant - Mixed Feedback",
        "category": "mixed",
        "scenario": "detailed_feedback",
        "business_type": "RESTAURANT",
        "template_text": "Thank you for dining with us, {reviewer_name}! We're thrilled you enjoyed {positive_aspect}. We hear your feedback about {area_for_improvement} and have shared it with our team. We're committed to making every aspect of your visit outstanding. - {sign_off}",
        "tone": "friendly_professional"
    }
];

# ═══════════════════════════════════════════════════════════════════════════════
# FEATURE 1: RESPONSE TEMPLATE LIBRARY
# ═══════════════════════════════════════════════════════════════════════════════

# ── GetResponseTemplates ─────────────────────────────────────────────────────

walker :pub GetResponseTemplates {
    has category: str = "";
    has scenario: str = "";
    has business_type: str = "";

    can start with Root entry {
        # Get all templates from user's root
        all_templates = [here -->(?:ResponseTemplate)];

        # If no templates exist, seed system templates
        if not all_templates {
            self.seed_system_templates(here);
            all_templates = [here -->(?:ResponseTemplate)];
        }

        # Apply filters
        filtered = [];
        for t in all_templates {
            if self.category and t.category != self.category {
                continue;
            }
            if self.scenario and t.scenario != self.scenario {
                continue;
            }
            if self.business_type and t.business_type != self.business_type and t.business_type != "GENERIC" {
                continue;
            }
            filtered.append(t);
        }

        # Format output
        results = [];
        for t in filtered {
            results.append({
                "template_id": t.template_id,
                "name": t.name,
                "category": t.category,
                "scenario": t.scenario,
                "business_type": t.business_type,
                "template_text": t.template_text,
                "placeholders": t.placeholders,
                "tone": t.tone,
                "is_system": t.is_system,
                "usage_count": t.usage_count
            });
        }

        report {
            "success": True,
            "count": len(results),
            "templates": results,
            "filters_applied": {
                "category": self.category if self.category else "all",
                "scenario": self.scenario if self.scenario else "all",
                "business_type": self.business_type if self.business_type else "all"
            }
        };
    }

    def seed_system_templates(root_node: any) {
        for tmpl_data in SYSTEM_TEMPLATES {
            placeholders = re.findall(r'\{(\w+)\}', tmpl_data["template_text"]);
            template = ResponseTemplate(
                template_id=str(uuid4()),
                name=tmpl_data["name"],
                category=tmpl_data["category"],
                scenario=tmpl_data["scenario"],
                business_type=tmpl_data["business_type"],
                template_text=tmpl_data["template_text"],
                placeholders=placeholders,
                tone=tmpl_data["tone"],
                is_system=True,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            );
            root_node ++> template;
        }
    }
}

# ── CreateResponseTemplate ───────────────────────────────────────────────────

walker :pub CreateResponseTemplate {
    has name: str;
    has category: str;
    has scenario: str;
    has business_type: str = "GENERIC";
    has template_text: str="";
    has tone: str = "friendly_professional";

    can start with Root entry {
        # Validate template text length
        if len(self.template_text) > 2000 {
            report validation_error("template_text", "Template text must be under 2000 characters");
            return;
        }

        # Extract placeholders from template text
        placeholders = re.findall(r'\{(\w+)\}', self.template_text);

        template = ResponseTemplate(
            template_id=str(uuid4()),
            name=self.name,
            category=self.category,
            scenario=self.scenario,
            business_type=self.business_type,
            template_text=self.template_text,
            placeholders=placeholders,
            tone=self.tone,
            is_system=False,
            created_at=datetime.now().isoformat(),
            updated_at=datetime.now().isoformat()
        );

        here ++> template;

        report {
            "success": True,
            "message": "Template created",
            "template": {
                "template_id": template.template_id,
                "name": template.name,
                "category": template.category,
                "scenario": template.scenario,
                "business_type": template.business_type,
                "placeholders": template.placeholders
            }
        };
    }
}

# ── ApplyTemplate (FREE, rule-based placeholder filling, stores ReviewReply) ──

walker :pub ApplyTemplate {
    has template_id: str;
    has business_id: str;
    has review_id: str;

    can start with Root entry {
        # 1. Validate profile
        profiles = [here -->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            disengage;
        }
        profile = profiles[0];

        # 2. Find template
        templates = [here -->(?:ResponseTemplate)];
        target_template = None;
        for t in templates {
            if t.template_id == self.template_id {
                target_template = t;
                break;
            }
        }

        if target_template is None {
            report {"success": False, "error": "Template not found"};
            disengage;
        }

        # 3. Find business
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        # 4. Find review
        reviews = [target_biz -->(?:Review)];
        target_review = None;
        for r in reviews {
            if r.review_id == self.review_id {
                target_review = r;
                break;
            }
        }

        if target_review is None {
            report {"success": False, "error": f"Review not found: {self.review_id}"};
            disengage;
        }

        # 5. Check if review already has a reply
        existing_replies = [target_review -->(?:ReviewReply)];
        if existing_replies {
            report {
                "success": False,
                "error": "Review already has a reply. Delete the existing reply first."
            };
            disengage;
        }

        # 6. Get analysis context for placeholder filling
        analyses = [target_biz -->(?:Analysis)];
        analysis = analyses[0] if analyses else None;

        # 7. Rule-based placeholder filling
        placeholder_map = {
            "reviewer_name": target_review.author if target_review.author else "valued customer",
            "business_name": target_biz.name if target_biz.name else "our business",
            "specific_mention": target_review.themes[0] if target_review.themes else "your experience",
            "business_strength": analysis.delighters[0] if (analysis and analysis.delighters) else "our service",
            "specific_issue": target_review.themes[0] if (target_review.sentiment == "negative" and target_review.themes) else "your concern",
            "area_for_improvement": analysis.pain_points[0] if (analysis and analysis.pain_points) else "the areas you mentioned",
            "positive_aspect": target_review.themes[0] if (target_review.sentiment == "positive" and target_review.themes) else "the things you enjoyed",
            "sign_off": (target_biz.name + " Team") if target_biz.name else "The Team",
            "contact_info": "our customer service team"
        };

        filled_text = target_template.template_text;
        for key in placeholder_map.keys() {
            filled_text = filled_text.replace("{" + key + "}", str(placeholder_map[key]));
        }

        # 8. Create ReviewReply node (FREE - no credit deduction)
        now_ts = datetime.now().isoformat();
        reply_node = ReviewReply(
            reply_id=str(uuid4()),
            reply_text=filled_text,
            generated_at=now_ts,
            credits_used=0.0,
            tone_used=target_template.tone,
            review_sentiment=target_review.sentiment,
            review_rating=target_review.rating,
            source="template",
            template_id=target_template.template_id
        );
        target_review ++> reply_node;

        # 9. Track template usage
        target_template.usage_count += 1;

        report {
            "success": True,
            "reply": {
                "reply_id": reply_node.reply_id,
                "reply_text": reply_node.reply_text,
                "generated_at": reply_node.generated_at,
                "source": "template",
                "template_id": target_template.template_id
            },
            "template_used": target_template.name,
            "review": {
                "review_id": target_review.review_id,
                "author": target_review.author,
                "rating": target_review.rating,
                "sentiment": target_review.sentiment
            },
            "credits": {
                "used": 0,
                "remaining": profile.credits
            }
        };
    }
}

# ── DeleteResponseTemplate ───────────────────────────────────────────────────

walker :pub DeleteResponseTemplate {
    has template_id: str;

    can start with Root entry {
        templates = [here -->(?:ResponseTemplate)];
        target = None;
        for t in templates {
            if t.template_id == self.template_id {
                target = t;
                break;
            }
        }

        if target is None {
            report {"success": False, "error": "Template not found"};
            disengage;
        }

        if target.is_system {
            report {"success": False, "error": "Cannot delete system templates"};
            disengage;
        }

        deleted_name = target.name;
        del target;

        report {
            "success": True,
            "deleted": {"template_id": self.template_id, "name": deleted_name}
        };
    }
}

# ── GetSuggestedTemplates (FREE, suggests templates matching a review) ────────

walker :pub GetSuggestedTemplates {
    has business_id: str;
    has review_id: str;

    can start with Root entry {
        # 1. Find business
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        # 2. Find review
        reviews = [target_biz -->(?:Review)];
        target_review = None;
        for r in reviews {
            if r.review_id == self.review_id {
                target_review = r;
                break;
            }
        }

        if target_review is None {
            report {"success": False, "error": f"Review not found: {self.review_id}"};
            disengage;
        }

        # 3. Map rating/sentiment to template category
        if target_review.rating >= 4 {
            target_category = "positive";
        } elif target_review.rating <= 2 {
            target_category = "negative";
        } else {
            target_category = "neutral";
        }

        # 4. Get all templates and filter by category + business_type
        templates = [here -->(?:ResponseTemplate)];
        biz_type = target_biz.business_type if target_biz.business_type else "GENERIC";
        matched = [];

        for t in templates {
            category_match = (t.category == target_category or t.category == "mixed");
            type_match = (t.business_type == biz_type or t.business_type == "GENERIC");
            if category_match and type_match {
                matched.append(t);
            }
        }

        # 5. Sort by usage_count descending (most popular first) - bubble sort
        for i in range(len(matched)) {
            for j in range(i + 1, len(matched)) {
                if matched[j].usage_count > matched[i].usage_count {
                    temp = matched[i];
                    matched[i] = matched[j];
                    matched[j] = temp;
                }
            }
        }

        # 6. Build response
        suggestions = [];
        for t in matched {
            suggestions.append({
                "template_id": t.template_id,
                "name": t.name,
                "category": t.category,
                "scenario": t.scenario,
                "business_type": t.business_type,
                "template_text": t.template_text,
                "placeholders": t.placeholders,
                "tone": t.tone,
                "is_system": t.is_system,
                "usage_count": t.usage_count
            });
        }

        report {
            "success": True,
            "review": {
                "review_id": target_review.review_id,
                "author": target_review.author,
                "rating": target_review.rating,
                "sentiment": target_review.sentiment
            },
            "matched_category": target_category,
            "templates": suggestions,
            "total": len(suggestions)
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FEATURE 2: ACTION PLAN GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

# ── GenerateActionPlan ───────────────────────────────────────────────────────

walker :pub GenerateActionPlan {
    has business_id: str;
    has timeframe: str = "90_day";
    has focus_areas: list[str] = [];

    can start with Root entry {
        # Validate timeframe
        if not validate_timeframe(self.timeframe) {
            report validation_error("timeframe", "Must be '30_day', '60_day', or '90_day'");
            return;
        }

        # Validate focus_areas count
        if len(self.focus_areas) > 5 {
            report validation_error("focus_areas", "Maximum 5 focus areas allowed");
            return;
        }

        # 1. Validate profile and credits
        profiles = [here -->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            disengage;
        }
        profile = profiles[0];

        if profile.credits < ACTION_PLAN_CREDIT_COST {
            report insufficient_credits_error(ACTION_PLAN_CREDIT_COST, profile.credits);
            disengage;
        }

        # 2. Find business
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        # 3. Gather analysis data
        analyses = [target_biz -->(?:Analysis)];
        reports = [target_biz -->(?:Report)];
        themes = [target_biz -->(?:Theme)];

        if not analyses or not reports {
            report {"success": False, "error": "Analysis or report not found. Run analysis first."};
            disengage;
        }

        analysis = analyses[0];
        rpt = reports[0];

        # 4. Build theme data
        theme_data = [];
        for t in themes {
            theme_data.append({
                "name": t.name,
                "sentiment": t.avg_sentiment,
                "mentions": t.mention_count,
                "positive_quotes": t.sample_quotes_positive[:3],
                "negative_quotes": t.sample_quotes_negative[:3],
                "sub_themes": t.sub_themes
            });
        }

        # 5. Deduct credits before LLM call
        profile.credits -= ACTION_PLAN_CREDIT_COST;
        profile.credits_used += ACTION_PLAN_CREDIT_COST;

        # 6. Generate action plan via LLM
        try {
            result = self.generate_action_plan(
                business_name=target_biz.name,
                business_type=target_biz.business_type_normalized,
                rating=target_biz.rating,
                total_reviews=target_biz.total_reviews,
                reviews_analyzed=analysis.reviews_analyzed,
                health_score=analysis.health_score,
                health_grade=analysis.health_grade,
                trend_direction=analysis.trend_direction,
                positive_percentage=analysis.positive_percentage,
                negative_percentage=analysis.negative_percentage,
                strengths=analysis.strengths,
                weaknesses=analysis.weaknesses,
                opportunities=analysis.opportunities,
                threats=analysis.threats,
                critical_issues=analysis.critical_issues,
                pain_points=analysis.pain_points,
                delighters=analysis.delighters,
                brand_context=rpt.brand_context,
                recommendations_immediate=rpt.brand_recommendations_immediate,
                recommendations_short_term=rpt.brand_recommendations_short_term,
                recommendations_long_term=rpt.brand_recommendations_long_term,
                do_not_recommendations=rpt.do_not_recommendations,
                key_findings=rpt.key_findings,
                themes=theme_data,
                timeframe=self.timeframe,
                focus_areas=self.focus_areas
            );
        } except Exception as e {
            # Refund credits on failure
            profile.credits += ACTION_PLAN_CREDIT_COST;
            profile.credits_used -= ACTION_PLAN_CREDIT_COST;
            report {"success": False, "error": f"Action plan generation failed: {str(e)}"};
            disengage;
        }

        # 7. Convert and store ActionPlan node
        immediate_list = [
            {"action": a.action, "owner_role": a.owner_role, "kpi": a.kpi,
             "effort": a.effort, "expected_impact": a.expected_impact,
             "source_issue": a.source_issue, "timeline_days": a.timeline_days}
            for a in result.immediate_actions
        ];
        short_term_list = [
            {"action": a.action, "owner_role": a.owner_role, "kpi": a.kpi,
             "effort": a.effort, "expected_impact": a.expected_impact,
             "source_issue": a.source_issue, "timeline_days": a.timeline_days}
            for a in result.short_term_actions
        ];
        medium_term_list = [
            {"action": a.action, "owner_role": a.owner_role, "kpi": a.kpi,
             "effort": a.effort, "expected_impact": a.expected_impact,
             "source_issue": a.source_issue, "timeline_days": a.timeline_days}
            for a in result.medium_term_actions
        ];
        kpi_list = [
            {"name": k.name, "current_value": k.current_value,
             "target_value": k.target_value, "measurement_method": k.measurement_method,
             "review_frequency": k.review_frequency}
            for k in result.kpis
        ];

        plan_node = ActionPlan(
            plan_id=str(uuid4()),
            title=result.title,
            overview=result.overview,
            timeframe=self.timeframe,
            total_action_items=len(immediate_list) + len(short_term_list) + len(medium_term_list),
            immediate_actions=immediate_list,
            short_term_actions=short_term_list,
            medium_term_actions=medium_term_list,
            kpis=kpi_list,
            expected_outcomes=result.expected_outcomes,
            risk_factors=result.risk_factors,
            based_on_health_score=analysis.health_score,
            based_on_review_count=analysis.reviews_analyzed,
            key_issues_addressed=analysis.pain_points[:5],
            credits_used=ACTION_PLAN_CREDIT_COST,
            generated_at=datetime.now().isoformat()
        );

        target_biz ++> plan_node;

        # 8. Create CreditTransaction
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="content_generation",
            amount=-ACTION_PLAN_CREDIT_COST,
            balance_after=profile.credits,
            description=f"Action plan for {target_biz.name} ({self.timeframe})",
            related_business_id=target_biz.place_id,
            created_at=datetime.now().isoformat()
        );
        here ++> txn;

        # 9. Return result
        report {
            "success": True,
            "plan": {
                "plan_id": plan_node.plan_id,
                "title": plan_node.title,
                "overview": plan_node.overview,
                "timeframe": plan_node.timeframe,
                "total_action_items": plan_node.total_action_items,
                "immediate_actions": plan_node.immediate_actions,
                "short_term_actions": plan_node.short_term_actions,
                "medium_term_actions": plan_node.medium_term_actions,
                "kpis": plan_node.kpis,
                "expected_outcomes": plan_node.expected_outcomes,
                "risk_factors": plan_node.risk_factors,
                "based_on": {
                    "health_score": plan_node.based_on_health_score,
                    "reviews_analyzed": plan_node.based_on_review_count,
                    "key_issues": plan_node.key_issues_addressed
                }
            },
            "credits": {
                "used": ACTION_PLAN_CREDIT_COST,
                "remaining": profile.credits
            }
        };
    }

    """Generate a comprehensive, prioritized improvement action plan from review analysis.

    Create a structured improvement roadmap with specific, actionable items organized
    by timeline. Each action must link to specific review data (pain points, critical
    issues, weaknesses) and include measurable KPIs for tracking progress.

    The plan should respect brand positioning (do not recommend actions that damage
    the brand's strengths) and scale action intensity to problem severity.

    Timeframe options:
    - 30_day: Focus only on immediate and short-term actions (urgent fixes)
    - 60_day: Include immediate, short-term, and initial medium-term actions
    - 90_day: Full plan with all three tiers of actions

    Args:
        business_name: Name of the business
        business_type: Business category (RESTAURANT, HOTEL, etc.)
        rating: Current Google rating
        total_reviews: Total reviews on Google
        reviews_analyzed: Number of reviews analyzed
        health_score: Business health score (0-100)
        health_grade: Letter grade (A+, A, B+, etc.)
        trend_direction: Trend (improving/stable/declining)
        positive_percentage: Percentage of positive reviews
        negative_percentage: Percentage of negative reviews
        strengths: SWOT strengths with evidence counts
        weaknesses: SWOT weaknesses with evidence counts
        opportunities: SWOT opportunities
        threats: SWOT threats
        critical_issues: List of critical issues with severity
        pain_points: Common customer frustrations
        delighters: What customers love (DO NOT compromise these)
        brand_context: Brand positioning, protected strengths, risks
        recommendations_immediate: Existing brand-aware immediate recommendations
        recommendations_short_term: Existing brand-aware short-term recommendations
        recommendations_long_term: Existing brand-aware long-term recommendations
        do_not_recommendations: Protective recommendations (what NOT to do)
        key_findings: Key analysis findings
        themes: Theme analysis with sentiment and quotes
        timeframe: Plan duration (30_day, 60_day, 90_day)
        focus_areas: Optional list of themes to prioritize

    Returns:
        ActionPlanResult with timeline-based actions, KPIs, and risk factors
    """
    def generate_action_plan(
        business_name: str,
        business_type: str,
        rating: float,
        total_reviews: int,
        reviews_analyzed: int,
        health_score: int,
        health_grade: str,
        trend_direction: str,
        positive_percentage: float,
        negative_percentage: float,
        strengths: list,
        weaknesses: list,
        opportunities: list,
        threats: list,
        critical_issues: list,
        pain_points: list,
        delighters: list,
        brand_context: dict,
        recommendations_immediate: list,
        recommendations_short_term: list,
        recommendations_long_term: list,
        do_not_recommendations: list,
        key_findings: list,
        themes: list,
        timeframe: str,
        focus_areas: list
    ) -> ActionPlanResult by llm(
        temperature=0.6,
        incl_info={
            "business": {
                "name": business_name, "type": business_type,
                "rating": rating, "total_reviews": total_reviews,
                "reviews_analyzed": reviews_analyzed
            },
            "health": {
                "score": health_score, "grade": health_grade,
                "trend": trend_direction,
                "positive_pct": positive_percentage, "negative_pct": negative_percentage
            },
            "swot": {
                "strengths": strengths, "weaknesses": weaknesses,
                "opportunities": opportunities, "threats": threats
            },
            "issues": {
                "critical": critical_issues, "pain_points": pain_points,
                "delighters_to_protect": delighters
            },
            "brand": brand_context,
            "existing_recommendations": {
                "immediate": recommendations_immediate,
                "short_term": recommendations_short_term,
                "long_term": recommendations_long_term,
                "do_not": do_not_recommendations
            },
            "key_findings": key_findings,
            "themes": themes,
            "plan_config": {
                "timeframe": timeframe,
                "focus_areas": focus_areas
            },
            "instructions": """
Create a practical improvement action plan that a business owner/manager can execute.

RULES:
1. Every action MUST link to a specific issue from the review data (source_issue)
2. Actions must be specific and measurable (not vague like "improve service")
3. Assign owner_role for each action (manager, staff, owner, marketing, operations)
4. Include realistic timeline_days for each action
5. KPIs must have measurable current and target values derived from the data
6. DO NOT recommend actions that compromise delighters or protected strengths
7. Scale plan scope to the timeframe (30-day = urgent fixes only)
8. Risk factors should be practical (staff resistance, cost, time)
"""
        }
    );
}

# ── GetActionPlans ───────────────────────────────────────────────────────────

walker :pub GetActionPlans {
    has business_id: str;

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        plans = [target_biz -->(?:ActionPlan)];
        results = [];
        for p in plans {
            results.append({
                "plan_id": p.plan_id,
                "title": p.title,
                "overview": p.overview,
                "timeframe": p.timeframe,
                "total_action_items": p.total_action_items,
                "immediate_actions": p.immediate_actions,
                "short_term_actions": p.short_term_actions,
                "medium_term_actions": p.medium_term_actions,
                "kpis": p.kpis,
                "expected_outcomes": p.expected_outcomes,
                "risk_factors": p.risk_factors,
                "based_on": {
                    "health_score": p.based_on_health_score,
                    "reviews_analyzed": p.based_on_review_count,
                    "key_issues": p.key_issues_addressed
                },
                "generated_at": p.generated_at
            });
        }

        report {
            "success": True,
            "business": {"place_id": target_biz.place_id, "name": target_biz.name},
            "count": len(results),
            "plans": results
        };
    }
}

# ── DeleteActionPlan ─────────────────────────────────────────────────────────

walker :pub DeleteActionPlan {
    has business_id: str;
    has plan_id: str;

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        plans = [target_biz -->(?:ActionPlan)];
        target_plan = None;
        for p in plans {
            if p.plan_id == self.plan_id {
                target_plan = p;
                break;
            }
        }

        if target_plan is None {
            report {"success": False, "error": f"Action plan not found: {self.plan_id}"};
            disengage;
        }

        deleted_title = target_plan.title;
        del target_plan;

        report {
            "success": True,
            "deleted": {"plan_id": self.plan_id, "title": deleted_title}
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FEATURE 3: SOCIAL MEDIA POST GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

# ── SaveSocialMediaPostConfig ────────────────────────────────────────────────

walker :pub SaveSocialMediaPostConfig {
    has brand_name: str = "";
    has brand_voice: str = "professional";
    has default_hashtags: list[str] = [];
    has include_star_rating: bool = True;
    has include_review_quote: bool = True;
    has include_call_to_action: bool = True;
    has call_to_action_text: str = "";

    can start with Root entry {
        configs = [here -->(?:SocialMediaPostConfig)];

        if configs {
            # Update existing config
            config = configs[0];
            config.brand_name = self.brand_name;
            config.brand_voice = self.brand_voice;
            config.default_hashtags = self.default_hashtags;
            config.include_star_rating = self.include_star_rating;
            config.include_review_quote = self.include_review_quote;
            config.include_call_to_action = self.include_call_to_action;
            config.call_to_action_text = self.call_to_action_text;
            config.updated_at = datetime.now().isoformat();
        } else {
            # Create new config
            config = SocialMediaPostConfig(
                brand_name=self.brand_name,
                brand_voice=self.brand_voice,
                default_hashtags=self.default_hashtags,
                include_star_rating=self.include_star_rating,
                include_review_quote=self.include_review_quote,
                include_call_to_action=self.include_call_to_action,
                call_to_action_text=self.call_to_action_text,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            );
            here ++> config;
        }

        report {
            "success": True,
            "message": "Social media post config saved",
            "config": {
                "brand_name": config.brand_name,
                "brand_voice": config.brand_voice,
                "default_hashtags": config.default_hashtags,
                "include_star_rating": config.include_star_rating,
                "include_review_quote": config.include_review_quote,
                "include_call_to_action": config.include_call_to_action,
                "call_to_action_text": config.call_to_action_text
            }
        };
    }
}

# ── GetSocialMediaPostConfig ─────────────────────────────────────────────────

walker :pub GetSocialMediaPostConfig {

    can start with Root entry {
        configs = [here -->(?:SocialMediaPostConfig)];

        if not configs {
            report {
                "success": True,
                "config": None,
                "message": "No social media config found. Using defaults."
            };
            return;
        }

        config = configs[0];
        report {
            "success": True,
            "config": {
                "brand_name": config.brand_name,
                "brand_voice": config.brand_voice,
                "default_hashtags": config.default_hashtags,
                "include_star_rating": config.include_star_rating,
                "include_review_quote": config.include_review_quote,
                "include_call_to_action": config.include_call_to_action,
                "call_to_action_text": config.call_to_action_text
            }
        };
    }
}

# ── GenerateSocialMediaPosts ─────────────────────────────────────────────────

walker :pub GenerateSocialMediaPosts {
    has business_id: str;
    has review_id: str = "";
    has platforms: list[str] = ["twitter", "facebook", "instagram", "linkedin"];
    has count: int = 1;

    can start with Root entry {
        # Validate platforms
        for p in self.platforms {
            if not validate_platform(p) {
                report validation_error("platforms", f"Invalid platform: {p}. Must be twitter, facebook, instagram, or linkedin");
                return;
            }
        }

        # 1. Validate credits
        profiles = [here -->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            disengage;
        }
        profile = profiles[0];

        if profile.credits < SOCIAL_POST_CREDIT_COST {
            report insufficient_credits_error(SOCIAL_POST_CREDIT_COST, profile.credits);
            disengage;
        }

        # 2. Find business
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        # 3. Select reviews to feature
        reviews = [target_biz -->(?:Review)];
        selected = [];

        if self.review_id {
            for r in reviews {
                if r.review_id == self.review_id {
                    selected.append(r);
                    break;
                }
            }
        } else {
            # Auto-select best positive reviews
            positive_reviews = [];
            for r in reviews {
                if r.rating >= 4 and r.sentiment == "positive" and len(r.text) > 30 {
                    positive_reviews.append(r);
                }
            }
            max_count = min(self.count, 5);
            selected = positive_reviews[:max_count];
        }

        if not selected {
            report {"success": False, "error": "No suitable positive reviews found for social media posts"};
            disengage;
        }

        # 4. Get config
        configs = [here -->(?:SocialMediaPostConfig)];
        config = configs[0] if configs else None;

        # 5. Get analysis for context
        analyses = [target_biz -->(?:Analysis)];
        analysis = analyses[0] if analyses else None;

        # 6. Deduct credits before LLM call
        profile.credits -= SOCIAL_POST_CREDIT_COST;
        profile.credits_used += SOCIAL_POST_CREDIT_COST;

        # 7. Generate posts for each selected review
        all_posts = [];
        for review in selected {
            try {
                result = self.generate_posts(
                    business_name=target_biz.name,
                    business_type=target_biz.business_type,
                    review_text=review.text,
                    review_author=review.author,
                    review_rating=review.rating,
                    platforms=self.platforms,
                    brand_voice=config.brand_voice if config else "professional",
                    default_hashtags=config.default_hashtags if config else [],
                    include_star_rating=config.include_star_rating if config else True,
                    include_cta=config.include_call_to_action if config else True,
                    cta_text=config.call_to_action_text if config else "",
                    delighters=analysis.delighters if analysis else [],
                    google_rating=target_biz.rating
                );

                for post in result.posts {
                    post_node = SocialMediaPost(
                        post_id=str(uuid4()),
                        platform=post.platform,
                        post_text=post.post_text,
                        hashtags=post.hashtags,
                        review_quote=post.review_quote,
                        review_author=review.author,
                        review_rating=review.rating,
                        character_count=post.character_count,
                        credits_used=SOCIAL_POST_CREDIT_COST / len(result.posts),
                        generated_at=datetime.now().isoformat()
                    );
                    target_biz ++> post_node;

                    all_posts.append({
                        "post_id": post_node.post_id,
                        "platform": post_node.platform,
                        "post_text": post_node.post_text,
                        "hashtags": post_node.hashtags,
                        "review_quote": post_node.review_quote,
                        "review_author": post_node.review_author,
                        "review_rating": post_node.review_rating,
                        "character_count": post_node.character_count
                    });
                }
            } except Exception as e {
                # Refund credits on failure
                profile.credits += SOCIAL_POST_CREDIT_COST;
                profile.credits_used -= SOCIAL_POST_CREDIT_COST;
                report {"success": False, "error": f"Social media post generation failed: {str(e)}"};
                disengage;
            }
        }

        # 8. CreditTransaction
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="content_generation",
            amount=-SOCIAL_POST_CREDIT_COST,
            balance_after=profile.credits,
            description=f"Social media posts for {target_biz.name} ({len(all_posts)} posts)",
            related_business_id=target_biz.place_id,
            created_at=datetime.now().isoformat()
        );
        here ++> txn;

        report {
            "success": True,
            "business": {"place_id": target_biz.place_id, "name": target_biz.name},
            "posts_generated": len(all_posts),
            "posts": all_posts,
            "credits": {"used": SOCIAL_POST_CREDIT_COST, "remaining": profile.credits}
        };
    }

    """Generate social media posts featuring a customer review across multiple platforms.

    Create platform-optimized posts that showcase a positive customer review:
    - Twitter/X: Max 280 characters, concise, punchy, with hashtags
    - Facebook: Longer narrative, can include more context, 1-3 hashtags
    - Instagram: Visual-ready caption, emoji-friendly, 5-10 hashtags
    - LinkedIn: Professional tone, business insights angle, 1-3 hashtags

    Each post should:
    - Include a compelling excerpt from the customer review (quoted)
    - Attribute to the reviewer (first name only for privacy)
    - Incorporate star rating if configured
    - End with call-to-action if configured
    - Match the brand voice setting
    - Feel authentic and not overly promotional

    Args:
        business_name: Name of the business
        business_type: Type of business
        review_text: Full review text to excerpt from
        review_author: Reviewer's name
        review_rating: Star rating (1-5)
        platforms: List of platforms to generate for
        brand_voice: Voice style (professional, casual, playful, authoritative)
        default_hashtags: Hashtags to always include
        include_star_rating: Whether to show star rating
        include_cta: Whether to include call-to-action
        cta_text: Custom CTA text (empty = auto-generate)
        delighters: Known business strengths to highlight
        google_rating: Overall Google rating

    Returns:
        SocialMediaPostResult with posts for each requested platform
    """
    def generate_posts(
        business_name: str,
        business_type: str,
        review_text: str,
        review_author: str,
        review_rating: int,
        platforms: list,
        brand_voice: str,
        default_hashtags: list,
        include_star_rating: bool,
        include_cta: bool,
        cta_text: str,
        delighters: list,
        google_rating: float
    ) -> SocialMediaPostResult by llm(
        temperature=0.8,
        incl_info={
            "business": {"name": business_name, "type": business_type, "google_rating": google_rating},
            "review": {"text": review_text, "author": review_author, "rating": review_rating},
            "platforms": platforms,
            "config": {
                "brand_voice": brand_voice,
                "default_hashtags": default_hashtags,
                "include_star_rating": include_star_rating,
                "include_cta": include_cta,
                "cta_text": cta_text
            },
            "delighters": delighters,
            "instructions": "Create engaging, authentic social media posts. Quote the review directly (use quotation marks). Keep Twitter under 280 chars. Make each platform's post unique in style, not just length."
        }
    );
}

# ── GetSocialMediaPosts ──────────────────────────────────────────────────────

walker :pub GetSocialMediaPosts {
    has business_id: str;
    has platform: str = "";

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        posts = [target_biz -->(?:SocialMediaPost)];
        results = [];
        for post in posts {
            if self.platform and post.platform != self.platform {
                continue;
            }
            results.append({
                "post_id": post.post_id,
                "platform": post.platform,
                "post_text": post.post_text,
                "hashtags": post.hashtags,
                "review_quote": post.review_quote,
                "review_author": post.review_author,
                "review_rating": post.review_rating,
                "character_count": post.character_count,
                "generated_at": post.generated_at
            });
        }

        report {
            "success": True,
            "business": {"place_id": target_biz.place_id, "name": target_biz.name},
            "count": len(results),
            "posts": results
        };
    }
}

# ── DeleteSocialMediaPost ────────────────────────────────────────────────────

walker :pub DeleteSocialMediaPost {
    has business_id: str;
    has post_id: str;

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        posts = [target_biz -->(?:SocialMediaPost)];
        target_post = None;
        for p in posts {
            if p.post_id == self.post_id {
                target_post = p;
                break;
            }
        }

        if target_post is None {
            report {"success": False, "error": f"Social media post not found: {self.post_id}"};
            disengage;
        }

        del target_post;

        report {
            "success": True,
            "deleted": {"post_id": self.post_id}
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FEATURE 4: MARKETING COPY GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

# ── SaveMarketingCopyConfig ──────────────────────────────────────────────────

walker :pub SaveMarketingCopyConfig {
    has brand_name: str = "";
    has brand_tagline: str = "";
    has target_audience: str = "";
    has unique_selling_points: list[str] = [];
    has tone: str = "persuasive";

    can start with Root entry {
        configs = [here -->(?:MarketingCopyConfig)];

        if configs {
            config = configs[0];
            config.brand_name = self.brand_name;
            config.brand_tagline = self.brand_tagline;
            config.target_audience = self.target_audience;
            config.unique_selling_points = self.unique_selling_points;
            config.tone = self.tone;
            config.updated_at = datetime.now().isoformat();
        } else {
            config = MarketingCopyConfig(
                brand_name=self.brand_name,
                brand_tagline=self.brand_tagline,
                target_audience=self.target_audience,
                unique_selling_points=self.unique_selling_points,
                tone=self.tone,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            );
            here ++> config;
        }

        report {
            "success": True,
            "message": "Marketing copy config saved",
            "config": {
                "brand_name": config.brand_name,
                "brand_tagline": config.brand_tagline,
                "target_audience": config.target_audience,
                "unique_selling_points": config.unique_selling_points,
                "tone": config.tone
            }
        };
    }
}

# ── GetMarketingCopyConfig ───────────────────────────────────────────────────

walker :pub GetMarketingCopyConfig {

    can start with Root entry {
        configs = [here -->(?:MarketingCopyConfig)];

        if not configs {
            report {
                "success": True,
                "config": None,
                "message": "No marketing copy config found. Using defaults."
            };
            return;
        }

        config = configs[0];
        report {
            "success": True,
            "config": {
                "brand_name": config.brand_name,
                "brand_tagline": config.brand_tagline,
                "target_audience": config.target_audience,
                "unique_selling_points": config.unique_selling_points,
                "tone": config.tone
            }
        };
    }
}

# ── GenerateMarketingCopy ────────────────────────────────────────────────────

walker :pub GenerateMarketingCopy {
    has business_id: str;
    has ad_format: str = "google_search";
    has num_variants: int = 3;

    can start with Root entry {
        # Validate ad_format
        if not validate_ad_format(self.ad_format) {
            report validation_error("ad_format", f"Invalid format: {self.ad_format}. Must be google_search, google_display, facebook_ad, instagram_ad, email_subject, or email_body");
            return;
        }

        # Cap variants at 3
        if self.num_variants > 3 {
            self.num_variants = 3;
        }
        if self.num_variants < 2 {
            self.num_variants = 2;
        }

        # 1. Validate credits
        profiles = [here -->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            disengage;
        }
        profile = profiles[0];

        if profile.credits < MARKETING_COPY_CREDIT_COST {
            report insufficient_credits_error(MARKETING_COPY_CREDIT_COST, profile.credits);
            disengage;
        }

        # 2. Find business + gather data
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        analyses = [target_biz -->(?:Analysis)];
        reports = [target_biz -->(?:Report)];
        themes = [target_biz -->(?:Theme)];

        if not analyses {
            report {"success": False, "error": "Analysis not found. Run analysis first."};
            disengage;
        }

        analysis = analyses[0];
        rpt = reports[0] if reports else None;

        # Gather positive quotes from themes
        positive_quotes = [];
        for t in themes {
            if t.avg_sentiment > 0.3 {
                for q in t.sample_quotes_positive[:2] {
                    positive_quotes.append(q);
                }
            }
        }

        # Get config
        configs = [here -->(?:MarketingCopyConfig)];
        config = configs[0] if configs else None;

        # Character limits by format
        char_limits = {
            "google_search": {"headline": 30, "body": 90, "cta": 15},
            "google_display": {"headline": 40, "body": 150, "cta": 20},
            "facebook_ad": {"headline": 40, "body": 250, "cta": 30},
            "instagram_ad": {"headline": 40, "body": 200, "cta": 30},
            "email_subject": {"headline": 60, "body": 0, "cta": 0},
            "email_body": {"headline": 60, "body": 500, "cta": 40}
        };

        # 3. Deduct credits before LLM call
        profile.credits -= MARKETING_COPY_CREDIT_COST;
        profile.credits_used += MARKETING_COPY_CREDIT_COST;

        # 4. Generate copy
        try {
            result = self.generate_copy(
                business_name=config.brand_name if config and config.brand_name else target_biz.name,
                business_type=target_biz.business_type,
                rating=target_biz.rating,
                delighters=analysis.delighters,
                strengths=[s.get("point", "") for s in analysis.strengths] if analysis.strengths else [],
                positive_quotes=positive_quotes[:5],
                positive_percentage=analysis.positive_percentage,
                health_score=analysis.health_score,
                key_metric=rpt.key_metric if rpt else "",
                target_audience=config.target_audience if config else "",
                usps=config.unique_selling_points if config else [],
                tone=config.tone if config else "persuasive",
                tagline=config.brand_tagline if config else "",
                ad_format=self.ad_format,
                char_limits=char_limits.get(self.ad_format, char_limits["facebook_ad"]),
                num_variants=self.num_variants
            );
        } except Exception as e {
            # Refund credits on failure
            profile.credits += MARKETING_COPY_CREDIT_COST;
            profile.credits_used -= MARKETING_COPY_CREDIT_COST;
            report {"success": False, "error": f"Marketing copy generation failed: {str(e)}"};
            disengage;
        }

        # 5. Store variants
        variant_labels = ["A", "B", "C"];
        stored_variants = [];
        for i in range(len(result.variants)) {
            v = result.variants[i];
            label = variant_labels[i] if i < len(variant_labels) else str(i);
            copy_node = MarketingCopy(
                copy_id=str(uuid4()),
                ad_format=self.ad_format,
                headline=v.headline,
                body_text=v.body_text,
                call_to_action=v.call_to_action,
                variant_label=label,
                character_counts={
                    "headline": len(v.headline),
                    "body": len(v.body_text),
                    "cta": len(v.call_to_action)
                },
                source_delighters=result.source_delighters,
                source_quotes=result.source_quotes,
                credits_used=MARKETING_COPY_CREDIT_COST / len(result.variants),
                generated_at=datetime.now().isoformat()
            );
            target_biz ++> copy_node;

            stored_variants.append({
                "copy_id": copy_node.copy_id,
                "variant": label,
                "headline": copy_node.headline,
                "body_text": copy_node.body_text,
                "call_to_action": copy_node.call_to_action,
                "character_counts": copy_node.character_counts
            });
        }

        # 6. CreditTransaction
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="content_generation",
            amount=-MARKETING_COPY_CREDIT_COST,
            balance_after=profile.credits,
            description=f"Marketing copy ({self.ad_format}) for {target_biz.name}",
            related_business_id=target_biz.place_id,
            created_at=datetime.now().isoformat()
        );
        here ++> txn;

        report {
            "success": True,
            "business": {"place_id": target_biz.place_id, "name": target_biz.name},
            "ad_format": self.ad_format,
            "variants": stored_variants,
            "source_data": {
                "delighters": result.source_delighters,
                "quotes": result.source_quotes
            },
            "credits": {"used": MARKETING_COPY_CREDIT_COST, "remaining": profile.credits}
        };
    }

    """Generate advertising copy variants from customer review highlights.

    Create compelling ad copy based on real customer feedback and business strengths.
    Each variant should take a different creative angle while staying rooted in
    actual review data. Respect character limits for the specified ad format.

    Ad format character limits:
    - Google Search: headline 30 chars, description 90 chars
    - Google Display: headline 40 chars, body 150 chars
    - Facebook/Instagram Ad: headline 40 chars, body 200-250 chars
    - Email Subject: headline 60 chars
    - Email Body: headline 60 chars, body 500 chars

    Args:
        business_name: Business name (or brand name override)
        business_type: Type of business
        rating: Google Maps rating
        delighters: What customers love
        strengths: Key business strengths
        positive_quotes: Real positive customer quotes
        positive_percentage: Percentage of positive reviews
        health_score: Business health score
        key_metric: Key business metric
        target_audience: Target audience description
        usps: Unique selling points
        tone: Ad tone (persuasive, informational, emotional, urgent)
        tagline: Brand tagline
        ad_format: Target ad format
        char_limits: Character limits for the format
        num_variants: Number of variants to generate (2-3)

    Returns:
        MarketingCopyResult with variants and source data references
    """
    def generate_copy(
        business_name: str,
        business_type: str,
        rating: float,
        delighters: list,
        strengths: list,
        positive_quotes: list,
        positive_percentage: float,
        health_score: int,
        key_metric: str,
        target_audience: str,
        usps: list,
        tone: str,
        tagline: str,
        ad_format: str,
        char_limits: dict,
        num_variants: int
    ) -> MarketingCopyResult by llm(
        temperature=0.8,
        incl_info={
            "business": {"name": business_name, "type": business_type, "rating": rating},
            "review_data": {
                "delighters": delighters,
                "strengths": strengths,
                "positive_quotes": positive_quotes,
                "positive_percentage": positive_percentage,
                "key_metric": key_metric
            },
            "brand": {"target_audience": target_audience, "usps": usps, "tone": tone, "tagline": tagline},
            "format": {"ad_format": ad_format, "char_limits": char_limits, "num_variants": num_variants},
            "instructions": "Create ad copy rooted in real customer feedback. Each variant should use a different creative angle. Strictly respect character limits. Include source_delighters and source_quotes showing which data points you used."
        }
    );
}

# ── GetMarketingCopies ───────────────────────────────────────────────────────

walker :pub GetMarketingCopies {
    has business_id: str;
    has ad_format: str = "";

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        copies = [target_biz -->(?:MarketingCopy)];
        results = [];
        for c in copies {
            if self.ad_format and c.ad_format != self.ad_format {
                continue;
            }
            results.append({
                "copy_id": c.copy_id,
                "ad_format": c.ad_format,
                "headline": c.headline,
                "body_text": c.body_text,
                "call_to_action": c.call_to_action,
                "variant_label": c.variant_label,
                "character_counts": c.character_counts,
                "source_delighters": c.source_delighters,
                "source_quotes": c.source_quotes,
                "generated_at": c.generated_at
            });
        }

        report {
            "success": True,
            "business": {"place_id": target_biz.place_id, "name": target_biz.name},
            "count": len(results),
            "copies": results
        };
    }
}

# ── DeleteMarketingCopy ──────────────────────────────────────────────────────

walker :pub DeleteMarketingCopy {
    has business_id: str;
    has copy_id: str;

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        copies = [target_biz -->(?:MarketingCopy)];
        target_copy = None;
        for c in copies {
            if c.copy_id == self.copy_id {
                target_copy = c;
                break;
            }
        }

        if target_copy is None {
            report {"success": False, "error": f"Marketing copy not found: {self.copy_id}"};
            disengage;
        }

        del target_copy;

        report {
            "success": True,
            "deleted": {"copy_id": self.copy_id}
        };
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# FEATURE 5: BLOG POST GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

# ── SaveBlogPostConfig ───────────────────────────────────────────────────────

walker :pub SaveBlogPostConfig {
    has author_name: str = "";
    has brand_name: str = "";
    has writing_style: str = "informative";
    has target_word_count: int = 800;
    has include_data_visualizations: bool = True;
    has seo_focus: bool = True;

    can start with Root entry {
        # Validate word count
        if self.target_word_count < 600 {
            self.target_word_count = 600;
        }
        if self.target_word_count > 2000 {
            self.target_word_count = 2000;
        }

        configs = [here -->(?:BlogPostConfig)];

        if configs {
            config = configs[0];
            config.author_name = self.author_name;
            config.brand_name = self.brand_name;
            config.writing_style = self.writing_style;
            config.target_word_count = self.target_word_count;
            config.include_data_visualizations = self.include_data_visualizations;
            config.seo_focus = self.seo_focus;
            config.updated_at = datetime.now().isoformat();
        } else {
            config = BlogPostConfig(
                author_name=self.author_name,
                brand_name=self.brand_name,
                writing_style=self.writing_style,
                target_word_count=self.target_word_count,
                include_data_visualizations=self.include_data_visualizations,
                seo_focus=self.seo_focus,
                created_at=datetime.now().isoformat(),
                updated_at=datetime.now().isoformat()
            );
            here ++> config;
        }

        report {
            "success": True,
            "message": "Blog post config saved",
            "config": {
                "author_name": config.author_name,
                "brand_name": config.brand_name,
                "writing_style": config.writing_style,
                "target_word_count": config.target_word_count,
                "include_data_visualizations": config.include_data_visualizations,
                "seo_focus": config.seo_focus
            }
        };
    }
}

# ── GetBlogPostConfig ────────────────────────────────────────────────────────

walker :pub GetBlogPostConfig {

    can start with Root entry {
        configs = [here -->(?:BlogPostConfig)];

        if not configs {
            report {
                "success": True,
                "config": None,
                "message": "No blog post config found. Using defaults."
            };
            return;
        }

        config = configs[0];
        report {
            "success": True,
            "config": {
                "author_name": config.author_name,
                "brand_name": config.brand_name,
                "writing_style": config.writing_style,
                "target_word_count": config.target_word_count,
                "include_data_visualizations": config.include_data_visualizations,
                "seo_focus": config.seo_focus
            }
        };
    }
}

# ── GenerateBlogPost ─────────────────────────────────────────────────────────

walker :pub GenerateBlogPost {
    has business_id: str;
    has content_type: str = "insights_listicle";
    has focus_theme: str = "";

    can start with Root entry {
        # Validate content_type
        if not validate_content_type(self.content_type) {
            report validation_error("content_type", f"Invalid type: {self.content_type}. Must be improvement_story, customer_spotlight, insights_listicle, case_study, or trend_analysis");
            return;
        }

        # 1. Validate credits
        profiles = [here -->(?:UserProfile)];
        if not profiles {
            report not_found_error("profile", "user");
            disengage;
        }
        profile = profiles[0];

        if profile.credits < BLOG_POST_CREDIT_COST {
            report insufficient_credits_error(BLOG_POST_CREDIT_COST, profile.credits);
            disengage;
        }

        # 2. Find business + gather comprehensive data
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        analyses = [target_biz -->(?:Analysis)];
        reports = [target_biz -->(?:Report)];
        themes = [target_biz -->(?:Theme)];

        if not analyses or not reports {
            report {"success": False, "error": "Analysis or report not found. Run analysis first."};
            disengage;
        }

        analysis = analyses[0];
        rpt = reports[0];

        # Gather theme data with quotes
        theme_data = [];
        for t in themes {
            theme_data.append({
                "name": t.name,
                "sentiment": t.avg_sentiment,
                "mentions": t.mention_count,
                "positive_quotes": t.sample_quotes_positive,
                "negative_quotes": t.sample_quotes_negative,
                "sub_themes": t.sub_themes
            });
        }

        # Get config
        configs = [here -->(?:BlogPostConfig)];
        config = configs[0] if configs else None;

        # 3. Deduct credits before LLM call
        profile.credits -= BLOG_POST_CREDIT_COST;
        profile.credits_used += BLOG_POST_CREDIT_COST;

        # 4. Generate blog post
        try {
            result = self.generate_blog_post(
                business_name=target_biz.name,
                business_type=target_biz.business_type_normalized,
                rating=target_biz.rating,
                total_reviews=target_biz.total_reviews,
                reviews_analyzed=analysis.reviews_analyzed,
                health_score=analysis.health_score,
                health_grade=analysis.health_grade,
                trend_direction=analysis.trend_direction,
                positive_percentage=analysis.positive_percentage,
                negative_percentage=analysis.negative_percentage,
                executive_summary=rpt.executive_summary,
                key_findings=rpt.key_findings,
                key_metric=rpt.key_metric,
                headline=rpt.headline,
                strengths=analysis.strengths,
                weaknesses=analysis.weaknesses,
                delighters=analysis.delighters,
                pain_points=analysis.pain_points,
                themes=theme_data,
                monthly_breakdown=analysis.monthly_breakdown,
                content_type=self.content_type,
                focus_theme=self.focus_theme,
                writing_style=config.writing_style if config else "informative",
                target_word_count=config.target_word_count if config else 800,
                author_name=config.author_name if config else "",
                brand_name=config.brand_name if config else target_biz.name
            );
        } except Exception as e {
            # Refund credits on failure
            profile.credits += BLOG_POST_CREDIT_COST;
            profile.credits_used -= BLOG_POST_CREDIT_COST;
            report {"success": False, "error": f"Blog post generation failed: {str(e)}"};
            disengage;
        }

        # 5. Store blog post
        body_sections_list = [
            {"heading": s.heading, "content": s.content, "data_points": s.data_points}
            for s in result.body_sections
        ];

        post_node = BlogPost(
            post_id=str(uuid4()),
            content_type=self.content_type,
            title=result.title,
            meta_description=result.meta_description,
            slug=result.slug,
            introduction=result.introduction,
            body_sections=body_sections_list,
            conclusion=result.conclusion,
            seo_keywords=result.seo_keywords,
            word_count=result.word_count,
            data_points_referenced=[],
            credits_used=BLOG_POST_CREDIT_COST,
            generated_at=datetime.now().isoformat()
        );

        target_biz ++> post_node;

        # 6. CreditTransaction
        txn = CreditTransaction(
            transaction_id=str(uuid4()),
            user_id=profile.username,
            transaction_type="content_generation",
            amount=-BLOG_POST_CREDIT_COST,
            balance_after=profile.credits,
            description=f"Blog post ({self.content_type}) for {target_biz.name}",
            related_business_id=target_biz.place_id,
            created_at=datetime.now().isoformat()
        );
        here ++> txn;

        report {
            "success": True,
            "blog_post": {
                "post_id": post_node.post_id,
                "content_type": post_node.content_type,
                "title": post_node.title,
                "meta_description": post_node.meta_description,
                "slug": post_node.slug,
                "introduction": post_node.introduction,
                "body_sections": post_node.body_sections,
                "conclusion": post_node.conclusion,
                "seo_keywords": post_node.seo_keywords,
                "word_count": post_node.word_count
            },
            "credits": {"used": BLOG_POST_CREDIT_COST, "remaining": profile.credits}
        };
    }

    """Generate an SEO-optimized blog post from review analysis insights.

    Create a structured, engaging blog post based on the specified content_type:
    - improvement_story: "How We're Improving Based on Your Feedback" narrative
    - customer_spotlight: Highlights positive customer experiences and quotes
    - insights_listicle: "X Things Customers Love About [Business]" format
    - case_study: Data-driven analysis of business performance
    - trend_analysis: How customer sentiment has evolved over time

    Requirements:
    - SEO-optimized title (50-60 characters)
    - Meta description (150-160 characters)
    - URL-friendly slug
    - Engaging introduction (100-150 words)
    - 3-5 body sections with H2 headings and supporting data points
    - Conclusion with summary and call-to-action
    - 5-10 target SEO keywords
    - Reference actual data (percentages, scores, quotes) throughout

    Args:
        business_name: Business name
        business_type: Business category
        rating: Google rating
        total_reviews: Total review count
        reviews_analyzed: Reviews analyzed
        health_score: Health score (0-100)
        health_grade: Letter grade
        trend_direction: Trend direction
        positive_percentage: Positive review percentage
        negative_percentage: Negative review percentage
        executive_summary: Executive summary text
        key_findings: Key analysis findings
        key_metric: Key business metric
        headline: Analysis headline
        strengths: SWOT strengths
        weaknesses: SWOT weaknesses
        delighters: Customer delighters
        pain_points: Customer pain points
        themes: Theme analysis with quotes
        monthly_breakdown: Monthly trend data
        content_type: Blog post format
        focus_theme: Optional theme to focus on
        writing_style: Writing style preference
        target_word_count: Target word count
        author_name: Author name for the post
        brand_name: Brand name to use

    Returns:
        BlogPostResult with complete blog post content
    """
    def generate_blog_post(
        business_name: str,
        business_type: str,
        rating: float,
        total_reviews: int,
        reviews_analyzed: int,
        health_score: int,
        health_grade: str,
        trend_direction: str,
        positive_percentage: float,
        negative_percentage: float,
        executive_summary: str,
        key_findings: list,
        key_metric: str,
        headline: str,
        strengths: list,
        weaknesses: list,
        delighters: list,
        pain_points: list,
        themes: list,
        monthly_breakdown: list,
        content_type: str,
        focus_theme: str,
        writing_style: str,
        target_word_count: int,
        author_name: str,
        brand_name: str
    ) -> BlogPostResult by llm(
        temperature=0.8,
        incl_info={
            "business": {
                "name": business_name, "brand_name": brand_name,
                "type": business_type, "rating": rating,
                "total_reviews": total_reviews, "reviews_analyzed": reviews_analyzed
            },
            "analysis": {
                "health_score": health_score, "health_grade": health_grade,
                "trend": trend_direction,
                "positive_pct": positive_percentage, "negative_pct": negative_percentage,
                "executive_summary": executive_summary,
                "key_findings": key_findings, "key_metric": key_metric, "headline": headline
            },
            "insights": {
                "strengths": strengths, "weaknesses": weaknesses,
                "delighters": delighters, "pain_points": pain_points
            },
            "themes": themes,
            "trends": monthly_breakdown,
            "config": {
                "content_type": content_type, "focus_theme": focus_theme,
                "writing_style": writing_style, "target_word_count": target_word_count,
                "author_name": author_name
            },
            "instructions": "Write an engaging, data-backed blog post. Use real statistics and paraphrased customer quotes. Include data_points in each section showing which numbers you referenced. SEO-optimize with natural keyword usage."
        }
    );
}

# ── GetBlogPosts ─────────────────────────────────────────────────────────────

walker :pub GetBlogPosts {
    has business_id: str;
    has content_type: str = "";

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        posts = [target_biz -->(?:BlogPost)];
        results = [];
        for p in posts {
            if self.content_type and p.content_type != self.content_type {
                continue;
            }
            results.append({
                "post_id": p.post_id,
                "content_type": p.content_type,
                "title": p.title,
                "meta_description": p.meta_description,
                "slug": p.slug,
                "introduction": p.introduction,
                "body_sections": p.body_sections,
                "conclusion": p.conclusion,
                "seo_keywords": p.seo_keywords,
                "word_count": p.word_count,
                "generated_at": p.generated_at
            });
        }

        report {
            "success": True,
            "business": {"place_id": target_biz.place_id, "name": target_biz.name},
            "count": len(results),
            "blog_posts": results
        };
    }
}

# ── DeleteBlogPost ───────────────────────────────────────────────────────────

walker :pub DeleteBlogPost {
    has business_id: str;
    has post_id: str;

    can start with Root entry {
        businesses = [here -->(?:Business)];
        target_biz = None;
        for biz in businesses {
            if biz.place_id == self.business_id {
                target_biz = biz;
                break;
            }
        }

        if target_biz is None {
            report not_found_error("business", self.business_id);
            disengage;
        }

        posts = [target_biz -->(?:BlogPost)];
        target_post = None;
        for p in posts {
            if p.post_id == self.post_id {
                target_post = p;
                break;
            }
        }

        if target_post is None {
            report {"success": False, "error": f"Blog post not found: {self.post_id}"};
            disengage;
        }

        deleted_title = target_post.title;
        del target_post;

        report {
            "success": True,
            "deleted": {"post_id": self.post_id, "title": deleted_title}
        };
    }
}
