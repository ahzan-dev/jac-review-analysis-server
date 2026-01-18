# ══════════════════════════════════════════════════════════════════════════════
# REVIEW ANALYZER V2 - MODELS & TYPE DEFINITIONS
# ══════════════════════════════════════════════════════════════════════════════
# Complete restructure for deep analysis with:
# - Business type detection
# - Sub-theme categorization
# - Health scores
# - Trend analysis
# - Statistical confidence
# ══════════════════════════════════════════════════════════════════════════════

# ═══════════════════════════════════════════════════════════════════════════════
# BUSINESS TYPE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

enum BusinessType {
    RESTAURANT,
    HOTEL,
    RETAIL,
    SALON,
    HEALTHCARE,
    ENTERTAINMENT,
    AUTO_SERVICE,
    GYM,
    GENERIC
}

# Google Maps type to our BusinessType mapping
glob BUSINESS_TYPE_MAP: dict = {
    # Restaurant types
    "restaurant": "RESTAURANT",
    "cafe": "RESTAURANT",
    "bakery": "RESTAURANT",
    "bar": "RESTAURANT",
    "food": "RESTAURANT",
    "ice_cream_shop": "RESTAURANT",
    "pizza_restaurant": "RESTAURANT",
    "coffee_shop": "RESTAURANT",
    "fast_food_restaurant": "RESTAURANT",
    "meal_takeaway": "RESTAURANT",
    "meal_delivery": "RESTAURANT",
    
    # Hotel types
    "hotel": "HOTEL",
    "resort": "HOTEL",
    "lodging": "HOTEL",
    "motel": "HOTEL",
    "guest_house": "HOTEL",
    "hostel": "HOTEL",
    "bed_and_breakfast": "HOTEL",
    "campground": "HOTEL",
    
    # Retail types
    "store": "RETAIL",
    "shop": "RETAIL",
    "shopping_mall": "RETAIL",
    "supermarket": "RETAIL",
    "clothing_store": "RETAIL",
    "electronics_store": "RETAIL",
    "furniture_store": "RETAIL",
    "grocery_store": "RETAIL",
    "department_store": "RETAIL",
    "convenience_store": "RETAIL",
    
    # Salon types
    "salon": "SALON",
    "spa": "SALON",
    "beauty_salon": "SALON",
    "hair_care": "SALON",
    "nail_salon": "SALON",
    "barber_shop": "SALON",
    
    # Healthcare types
    "hospital": "HEALTHCARE",
    "clinic": "HEALTHCARE",
    "doctor": "HEALTHCARE",
    "dentist": "HEALTHCARE",
    "pharmacy": "HEALTHCARE",
    "medical": "HEALTHCARE",
    "health": "HEALTHCARE",
    
    # Entertainment types
    "amusement_park": "ENTERTAINMENT",
    "aquarium": "ENTERTAINMENT",
    "zoo": "ENTERTAINMENT",
    "museum": "ENTERTAINMENT",
    "movie_theater": "ENTERTAINMENT",
    "bowling_alley": "ENTERTAINMENT",
    "casino": "ENTERTAINMENT",
    "night_club": "ENTERTAINMENT",
    "tourist_attraction": "ENTERTAINMENT",
    
    # Auto types
    "car_repair": "AUTO_SERVICE",
    "car_dealer": "AUTO_SERVICE",
    "car_wash": "AUTO_SERVICE",
    "gas_station": "AUTO_SERVICE",
    
    # Gym types
    "gym": "GYM",
    "fitness": "GYM"
};

# ═══════════════════════════════════════════════════════════════════════════════
# SUB-THEME DEFINITIONS BY BUSINESS TYPE
# ═══════════════════════════════════════════════════════════════════════════════

glob THEME_DEFINITIONS: dict = {
    "RESTAURANT": {
        "Food Quality": ["Taste", "Freshness", "Portion Size", "Presentation", "Menu Variety", "Specific Items"],
        "Service": ["Staff Friendliness", "Speed/Wait Time", "Attentiveness", "Knowledge", "Professionalism"],
        "Ambiance": ["Atmosphere", "Decor", "Noise Level", "Seating Comfort", "Cleanliness", "Music"],
        "Value": ["Price vs Quality", "Portion Value", "Worth the Money", "Hidden Costs"],
        "Hygiene": ["Cleanliness", "Restrooms", "Kitchen Cleanliness", "Food Safety"],
        "Location": ["Accessibility", "Parking", "Visibility", "Neighborhood"]
    },
    "HOTEL": {
        "Room Quality": ["Cleanliness", "Bed Comfort", "Size", "View", "Amenities", "Maintenance"],
        "Service": ["Front Desk", "Housekeeping", "Concierge", "Response Time", "Staff Attitude"],
        "Facilities": ["Pool", "Gym", "Spa", "Restaurant", "Bar", "WiFi", "Parking"],
        "Food & Dining": ["Breakfast", "Room Service", "Restaurant Quality", "Variety"],
        "Value": ["Price vs Quality", "Hidden Fees", "Worth the Money"],
        "Location": ["Accessibility", "Nearby Attractions", "Safety", "Transport"],
        "Check-in/out": ["Speed", "Efficiency", "Flexibility", "Process"]
    },
    "RETAIL": {
        "Product Quality": ["Durability", "Authenticity", "As Described", "Selection"],
        "Service": ["Staff Helpfulness", "Knowledge", "Availability", "Friendliness"],
        "Pricing": ["Value", "Competitiveness", "Discounts", "Hidden Costs"],
        "Store Experience": ["Layout", "Cleanliness", "Organization", "Ambiance"],
        "Checkout": ["Speed", "Payment Options", "Ease"],
        "Location": ["Accessibility", "Parking", "Convenience"]
    },
    "SALON": {
        "Service Quality": ["Skill", "Results", "Technique", "Attention to Detail"],
        "Staff": ["Friendliness", "Professionalism", "Listening", "Expertise"],
        "Ambiance": ["Relaxation", "Cleanliness", "Music", "Comfort"],
        "Value": ["Price vs Quality", "Worth It"],
        "Booking": ["Ease", "Availability", "Wait Time", "Punctuality"],
        "Hygiene": ["Cleanliness", "Sanitization", "Safety"]
    },
    "HEALTHCARE": {
        "Care Quality": ["Diagnosis Accuracy", "Treatment Effectiveness", "Thoroughness"],
        "Staff": ["Doctor Manner", "Nurse Care", "Reception", "Empathy"],
        "Wait Time": ["Appointment Availability", "In-Clinic Wait", "Punctuality"],
        "Facilities": ["Cleanliness", "Equipment", "Comfort", "Accessibility"],
        "Communication": ["Explanation", "Follow-up", "Clarity", "Listening"],
        "Value": ["Pricing", "Insurance", "Transparency"]
    },
    "ENTERTAINMENT": {
        "Experience": ["Fun Factor", "Uniqueness", "Met Expectations", "Activities"],
        "Service": ["Staff Helpfulness", "Organization", "Safety"],
        "Facilities": ["Cleanliness", "Maintenance", "Amenities", "Restrooms"],
        "Value": ["Ticket Price", "Worth It", "Hidden Costs"],
        "Crowds": ["Wait Times", "Crowding", "Capacity Management"],
        "Accessibility": ["Parking", "Location", "Signage", "Disability Access"]
    },
    "AUTO_SERVICE": {
        "Work Quality": ["Repair Quality", "Thoroughness", "Lasting Fix"],
        "Service": ["Communication", "Honesty", "Explanation", "Updates"],
        "Pricing": ["Fair Price", "Transparency", "No Surprise Charges", "Estimates"],
        "Timeliness": ["Speed", "Met Deadline", "Appointment Availability"],
        "Trust": ["Honesty", "No Upselling", "Reliability"],
        "Facility": ["Cleanliness", "Waiting Area", "Convenience"]
    },
    "GYM": {
        "Equipment": ["Variety", "Quality", "Maintenance", "Availability"],
        "Cleanliness": ["Equipment", "Restrooms", "Overall", "Locker Rooms"],
        "Staff": ["Trainers", "Front Desk", "Helpfulness", "Knowledge"],
        "Classes": ["Variety", "Quality", "Schedule", "Instructors"],
        "Atmosphere": ["Crowding", "Music", "Temperature", "Vibe"],
        "Value": ["Membership Price", "Contract", "Hidden Fees"]
    },
    "GENERIC": {
        "Product/Service Quality": ["As Expected", "Quality", "Reliability"],
        "Customer Service": ["Responsiveness", "Helpfulness", "Professionalism"],
        "Value": ["Price", "Worth It", "Competitiveness"],
        "Experience": ["Ease of Use", "Convenience", "Overall Satisfaction"],
        "Communication": ["Clarity", "Follow-up", "Responsiveness"],
        "Reliability": ["Consistency", "Trustworthiness", "Delivery"]
    }
};

# ═══════════════════════════════════════════════════════════════════════════════
# CONFIDENCE THRESHOLDS
# ═══════════════════════════════════════════════════════════════════════════════

glob CONFIDENCE_THRESHOLDS: dict = {
    "low_max": 20,
    "medium_max": 50,
    "sub_theme_min_mentions": 3,
    "trend_min_months": 3,
    "theme_min_percentage": 5,
    "theme_min_absolute": 5
};

# ═══════════════════════════════════════════════════════════════════════════════
# NODE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

node Business {
    has place_id: str;
    has data_id: str = "";
    has name: str = "";
    has business_type: str = "";
    has business_type_normalized: str = "GENERIC";
    has address: str = "";
    has phone: str = "";
    has website: str = "";
    has rating: float = 0.0;
    has total_reviews: int = 0;
    has price_level: str = "";
    has latitude: float = 0.0;
    has longitude: float = 0.0;
    has original_url: str = "";
    has fetched_at: str = "";
    has status: str = "pending";
    
    # Extended place details
    has opening_hours: dict = {};
    has photos_count: int = 0;
    has popular_times: dict = {};

    # Authentication & Audit
    has owner: str = "";  # Username of who created this business
    has created_at: str = "";  # When business was added
    has last_analyzed_at: str = "";  # Track analysis frequency
}

node Review {
    has review_id: str;
    has author: str;
    has author_image: str = "";
    has rating: int = 0;
    has text: str = "";
    has date: str = "";
    has relative_date: str = "";
    has language: str = "en";
    has likes: int = 0;
    has owner_response: str = "";
    has photos: list[str] = [];
    
    # Analysis results
    has sentiment: str = "";
    has sentiment_score: float = 0.0;
    has themes: list[str] = [];
    has sub_themes: dict = {};
    has keywords: list[str] = [];
    has emotion: str = "";
    has analyzed: bool = False;
}

node Theme {
    has name: str;
    has category: str = "";
    has mention_count: int = 0;
    has positive_count: int = 0;
    has negative_count: int = 0;
    has neutral_count: int = 0;
    has mixed_count: int = 0;
    has avg_sentiment: float = 0.0;
    has keywords: list[str] = [];
    has sample_quotes_positive: list[str] = [];
    has sample_quotes_negative: list[str] = [];
    
    # Sub-theme breakdown
    has sub_themes: list[dict] = [];
}

node Analysis {
    has analysis_id: str = "";
    has created_at: str = "";
    has model_used: str = "gpt-4o-mini";
    has reviews_analyzed: int = 0;
    has date_range_start: str = "";
    has date_range_end: str = "";
    
    # Health Score
    has health_score: int = 0;
    has health_grade: str = "";
    has health_breakdown: dict = {};
    
    # Confidence
    has confidence_level: str = "";
    has confidence_details: dict = {};
    
    # Sentiment
    has overall_sentiment: str = "";
    has sentiment_score: float = 0.0;
    has positive_count: int = 0;
    has negative_count: int = 0;
    has neutral_count: int = 0;
    has mixed_count: int = 0;
    has positive_percentage: float = 0.0;
    has negative_percentage: float = 0.0;
    has neutral_percentage: float = 0.0;
    
    # Rating distribution
    has rating_distribution: dict = {};
    
    # SWOT
    has strengths: list[dict] = [];
    has weaknesses: list[dict] = [];
    has opportunities: list[dict] = [];
    has threats: list[dict] = [];
    
    # Issues and insights
    has critical_issues: list[dict] = [];
    has pain_points: list[str] = [];
    has delighters: list[str] = [];
    
    # Trends
    has trend_direction: str = "";
    has trend_change: str = "";
    has monthly_breakdown: list[dict] = [];
    has theme_trends: list[dict] = [];
    has seasonal_patterns: list[str] = [];
    
    # Statistics
    has avg_review_length: int = 0;
    has reviews_with_photos: int = 0;
    has reviews_with_owner_response: int = 0;
    has response_rate: float = 0.0;
    has languages: dict = {};
}

node Report {
    has report_id: str = "";
    has report_type: str = "";
    has created_at: str = "";

    # Executive Summary
    has headline: str = "";
    has one_liner: str = "";
    has key_metric: str = "";
    has executive_summary: str = "";

    # Findings
    has key_findings: list[str] = [];

    # Legacy Recommendations (kept for backward compatibility)
    has recommendations_immediate: list[dict] = [];
    has recommendations_short_term: list[dict] = [];
    has recommendations_long_term: list[dict] = [];

    # Brand-Aware Recommendations (NEW - stored to avoid re-generating)
    has brand_context: dict = {};                      # {price_positioning, brand_positioning, protected_strengths, brand_risks}
    has issue_severity_summary: str = "";
    has brand_recommendations_immediate: list[dict] = [];
    has brand_recommendations_short_term: list[dict] = [];
    has brand_recommendations_long_term: list[dict] = [];
    has do_not_recommendations: list[dict] = [];
    has overall_risk_assessment: str = "";
}

# ═══════════════════════════════════════════════════════════════════════════════
# USER MANAGEMENT & AUTHENTICATION
# ═══════════════════════════════════════════════════════════════════════════════

enum SubscriptionTier {
    FREE = "free",
    PRO = "pro",
    ENTERPRISE = "enterprise"
}

enum UserRole {
    USER = "user",
    ADMIN = "admin"
}

node UserProfile {
    has username: str;  # Primary key - matches JAC user registration
    has role: UserRole = UserRole.USER;
    has subscription_tier: SubscriptionTier = SubscriptionTier.FREE;
    has created_at: str = "";

    # Subscription Limits
    has max_businesses: int = 5;  # Free: 5, Pro: 50, Enterprise: unlimited (-1)
    has daily_analysis_limit: int = 10;  # Free: 10, Pro: 100, Enterprise: unlimited (-1)

    # Usage Tracking
    has current_business_count: int = 0;
    has analyses_today: int = 0;
    has last_reset_date: str = "";  # For daily limit reset

    # Audit
    has last_login: str = "";
    has is_active: bool = True;
}

# ═══════════════════════════════════════════════════════════════════════════════
# EDGE DEFINITIONS
# ═══════════════════════════════════════════════════════════════════════════════

edge HasReview {
    has fetched_at: str = "";
}

edge HasTheme {
    has relevance_score: float = 0.0;
}

edge HasAnalysis {
    has version: int = 1;
}

edge HasReport {
    has version: int = 1;
}

# ═══════════════════════════════════════════════════════════════════════════════
# LLM OUTPUT OBJECTS
# ═══════════════════════════════════════════════════════════════════════════════

# Batch sentiment analysis (5 reviews at once)
obj SubThemeMapping {
    has theme: str;
    has sub_themes: list[str];
}

sem SubThemeMapping = "Mapping of a main theme to its sub-themes";
sem SubThemeMapping.theme = "The main theme name from the allowed themes list";
sem SubThemeMapping.sub_themes = "List of sub-themes detected for this main theme";

obj BatchReviewAnalysis {
    has reviews: list[SingleReviewAnalysis];
}

obj SingleReviewAnalysis {
    has review_index: int;
    has sentiment: str;
    has sentiment_score: float;
    has themes: list[str];
    has sub_themes: list[SubThemeMapping];
    has keywords: list[str];
    has emotion: str;
}

sem BatchReviewAnalysis = "Analysis results for a batch of customer reviews";
sem BatchReviewAnalysis.reviews = "List of individual review analysis results, one per input review";

sem SingleReviewAnalysis = "Sentiment and theme analysis for a single review";
sem SingleReviewAnalysis.review_index = "Index of the review in the batch (0, 1, 2, 3, or 4)";
sem SingleReviewAnalysis.sentiment = "Overall sentiment: 'positive', 'negative', 'neutral', or 'mixed'";
sem SingleReviewAnalysis.sentiment_score = "Score from -1.0 (very negative) to 1.0 (very positive)";
sem SingleReviewAnalysis.themes = "Main themes mentioned from the allowed list for this business type";
sem SingleReviewAnalysis.sub_themes = "List of theme-to-sub-themes mappings for detected themes";
sem SingleReviewAnalysis.keywords = "Key phrases that stand out (max 5)";
sem SingleReviewAnalysis.emotion = "Primary emotion: 'happy', 'satisfied', 'impressed', 'disappointed', 'frustrated', 'angry', 'neutral'";

# SWOT item structure
obj SwotItem {
    has point: str;
    has evidence_count: int;
}

sem SwotItem = "A single SWOT analysis point";
sem SwotItem.point = "The strength, weakness, opportunity, or threat description";
sem SwotItem.evidence_count = "Number of reviews supporting this point";

# Critical issue structure
obj CriticalIssueItem {
    has issue: str;
    has severity: str;
    has mention_count: int;
    has suggested_action: str;
}

sem CriticalIssueItem = "A critical issue requiring attention";
sem CriticalIssueItem.issue = "Description of the critical issue";
sem CriticalIssueItem.severity = "Severity level: 'high', 'medium', or 'low'";
sem CriticalIssueItem.mention_count = "Number of reviews mentioning this issue";
sem CriticalIssueItem.suggested_action = "Recommended action to address the issue";

# Health breakdown item
obj HealthBreakdownItem {
    has theme: str;
    has score: int;
}

sem HealthBreakdownItem = "Health score breakdown by theme";
sem HealthBreakdownItem.theme = "Theme name";
sem HealthBreakdownItem.score = "Score from 0 to 100";

# Pattern analysis output
obj PatternAnalysisResult {
    has health_score: int;
    has health_grade: str;
    has health_breakdown: list[HealthBreakdownItem];
    has overall_sentiment: str;
    has trend_direction: str;
    has strengths: list[SwotItem];
    has weaknesses: list[SwotItem];
    has opportunities: list[SwotItem];
    has threats: list[SwotItem];
    has critical_issues: list[CriticalIssueItem];
    has delighters: list[str];
    has pain_points: list[str];
}

sem PatternAnalysisResult = "Comprehensive pattern analysis across all reviews";
sem PatternAnalysisResult.health_score = "Overall health score 0-100";
sem PatternAnalysisResult.health_grade = "Letter grade: A+, A, A-, B+, B, B-, C+, C, C-, D, F";
sem PatternAnalysisResult.health_breakdown = "List of theme scores";
sem PatternAnalysisResult.overall_sentiment = "Overall: 'very_positive', 'positive', 'mixed', 'negative', 'very_negative'";
sem PatternAnalysisResult.trend_direction = "Trend: 'improving', 'stable', 'declining'";
sem PatternAnalysisResult.strengths = "Key business strengths from reviews";
sem PatternAnalysisResult.weaknesses = "Key business weaknesses from reviews";
sem PatternAnalysisResult.opportunities = "Potential opportunities identified";
sem PatternAnalysisResult.threats = "Potential threats identified";
sem PatternAnalysisResult.critical_issues = "Critical issues requiring immediate attention";
sem PatternAnalysisResult.delighters = "Things that exceed customer expectations";
sem PatternAnalysisResult.pain_points = "Common customer frustrations";

# Recommendation item structure
obj RecommendationItem {
    has action: str;
    has reason: str;
    has expected_impact: str;
    has effort: str;
    has priority_score: int;
}

sem RecommendationItem = "A single recommendation for improvement";
sem RecommendationItem.action = "The specific action to take";
sem RecommendationItem.reason = "Why this action is recommended";
sem RecommendationItem.expected_impact = "Expected outcome of this action";
sem RecommendationItem.effort = "Effort level: 'low', 'medium', or 'high'";
sem RecommendationItem.priority_score = "Priority score from 0-100";

# Report generation output
obj ReportGenerationResult {
    has headline: str;
    has one_liner: str;
    has key_metric: str;
    has executive_summary: str;
    has key_findings: list[str];
    has recommendations_immediate: list[RecommendationItem];
    has recommendations_short_term: list[RecommendationItem];
    has recommendations_long_term: list[RecommendationItem];
}

sem ReportGenerationResult = "Generated business intelligence report content";
sem ReportGenerationResult.headline = "Short impactful headline (5-10 words)";
sem ReportGenerationResult.one_liner = "Single sentence summary of the most important insight";
sem ReportGenerationResult.key_metric = "The one metric/action that matters most";
sem ReportGenerationResult.executive_summary = "2-3 paragraph executive summary";
sem ReportGenerationResult.key_findings = "List of 5-15 key findings based on review count";
sem ReportGenerationResult.recommendations_immediate = "Immediate actions to take this week";
sem ReportGenerationResult.recommendations_short_term = "Actions for this month";
sem ReportGenerationResult.recommendations_long_term = "Actions for this quarter";

# ═══════════════════════════════════════════════════════════════════════════════
# ANALYSIS INPUT/OUTPUT STRUCTURES
# ═══════════════════════════════════════════════════════════════════════════════

obj AnalysisInput {
    has url: str;
    has max_reviews: int = 100;
    has analysis_depth: str = "deep";
    has include_features: dict = {};
    has date_range: dict = {};
}

obj AnalysisOutput {
    has success: bool;
    has data_source: str;
    has generated_at: str;
    has error: str = "";

    # All sections
    has business: dict = {};
    has health_score: dict = {};
    has sentiment: dict = {};
    has themes: list[dict] = [];
    has trends: dict = {};
    has critical_issues: list[dict] = [];
    has swot: dict = {};
    has recommendations: dict = {};
    has executive_summary: dict = {};
    has statistics: dict = {};
}

# ═══════════════════════════════════════════════════════════════════════════════
# BRAND-AWARE RECOMMENDATION MODELS
# ═══════════════════════════════════════════════════════════════════════════════

obj BrandContext {
    has price_positioning: str;
    has brand_positioning: str;
    has protected_strengths: list[str];
    has brand_risks: list[str];
}

sem BrandContext = "Brand positioning context for recommendation calibration";
sem BrandContext.price_positioning = "Price tier: 'premium', 'mid-range', 'standard', or 'budget'";
sem BrandContext.brand_positioning = "Brand tier: 'luxury', 'premium', 'quality', 'standard', or 'value'";
sem BrandContext.protected_strengths = "List of high-performing areas that must NOT be compromised";
sem BrandContext.brand_risks = "List of actions that could damage brand positioning";

obj EvidenceLink {
    has issue: str;
    has mention_count: int;
    has mention_percentage: float;
    has severity: str;
    has sample_feedback: list[str];
    has customer_segments: list[str];
}

sem EvidenceLink = "Data evidence backing a recommendation";
sem EvidenceLink.issue = "The specific issue this recommendation addresses";
sem EvidenceLink.mention_count = "Number of reviews mentioning this issue";
sem EvidenceLink.mention_percentage = "Percentage of total reviews mentioning this issue";
sem EvidenceLink.severity = "Severity level based on mention percentage: 'low' (<5%), 'moderate' (5-15%), 'high' (>15%)";
sem EvidenceLink.sample_feedback = "Example customer feedback phrases (paraphrased, 2-3 examples)";
sem EvidenceLink.customer_segments = "Customer segments affected (e.g., 'tourists', 'regulars', 'first-timers', 'families')";

obj BrandAwareRecommendation {
    has action: str;
    has action_type: str;
    has reason: str;
    has evidence: EvidenceLink;
    has expected_impact: str;
    has downside_risk: str;
    has effort: str;
    has risk_level: str;
    has confidence_level: str;
    has priority_score: int;
    has caution_note: str = "";
}

sem BrandAwareRecommendation = "A brand-aware, evidence-based recommendation with risk assessment";
sem BrandAwareRecommendation.action = "Specific verb-driven action to take";
sem BrandAwareRecommendation.action_type = "Action type: 'monitor' (watch/track), 'communicate' (messaging/training), 'experiment' (limited test), or 'change' (structural change)";
sem BrandAwareRecommendation.reason = "Why this action is recommended based on data";
sem BrandAwareRecommendation.evidence = "Data evidence linking this recommendation to actual customer feedback";
sem BrandAwareRecommendation.expected_impact = "Quantified expected outcome with realistic estimates";
sem BrandAwareRecommendation.downside_risk = "What could go wrong if this recommendation is implemented poorly";
sem BrandAwareRecommendation.effort = "Effort level: 'low', 'medium', or 'high'";
sem BrandAwareRecommendation.risk_level = "Risk to brand/operations: 'low', 'medium', or 'high'";
sem BrandAwareRecommendation.confidence_level = "Confidence in recommendation based on data strength: 'low', 'medium', or 'high'";
sem BrandAwareRecommendation.priority_score = "Priority score from 0-100 considering severity, impact, and risk";
sem BrandAwareRecommendation.caution_note = "Warning note for medium/high risk actions (empty for low risk)";

obj ProtectiveRecommendation {
    has area: str;
    has do_not_action: str;
    has rationale: str;
    has evidence_count: int;
}

sem ProtectiveRecommendation = "A protective DO NOT recommendation to preserve strong areas";
sem ProtectiveRecommendation.area = "The area/theme that is performing strongly";
sem ProtectiveRecommendation.do_not_action = "Specific action that should NOT be taken";
sem ProtectiveRecommendation.rationale = "Why this action would be harmful based on positive sentiment data";
sem ProtectiveRecommendation.evidence_count = "Number of positive reviews supporting this protection";

obj BrandAwareRecommendationResult {
    has brand_context: BrandContext;
    has issue_severity_summary: str;
    has recommendations_immediate: list[BrandAwareRecommendation];
    has recommendations_short_term: list[BrandAwareRecommendation];
    has recommendations_long_term: list[BrandAwareRecommendation];
    has do_not_recommendations: list[ProtectiveRecommendation];
    has overall_risk_assessment: str;
}

sem BrandAwareRecommendationResult = "Complete brand-aware recommendation output with protective guidance";
sem BrandAwareRecommendationResult.brand_context = "Detected brand positioning context";
sem BrandAwareRecommendationResult.issue_severity_summary = "Overall assessment of problem scale relative to review volume";
sem BrandAwareRecommendationResult.recommendations_immediate = "Immediate actions (this week) - typically 2-3 items";
sem BrandAwareRecommendationResult.recommendations_short_term = "Short-term actions (this month) - typically 2-4 items";
sem BrandAwareRecommendationResult.recommendations_long_term = "Long-term actions (this quarter) - typically 1-3 items";
sem BrandAwareRecommendationResult.do_not_recommendations = "CRITICAL: Protective recommendations listing what NOT to do - typically 2-4 items";
sem BrandAwareRecommendationResult.overall_risk_assessment = "Summary of overall risk profile of all recommendations";
