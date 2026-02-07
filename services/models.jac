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
# CREDIT PACKAGE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════
# Credit Calculation Rule:
#   1 credit = analysis of UP TO 100 reviews
#   Formula: credits_required = CEILING(total_reviews / 100)
#
# Examples:
#   1-100 reviews   → 1 credit
#   101-200 reviews → 2 credits
#   250 reviews     → 3 credits
#   500 reviews     → 5 credits
#   1000 reviews    → 10 credits

glob CREDIT_PACKAGES: dict = {
    "bronze": {"credits": 1, "price": 5.0, "name": "Bronze"},
    "silver": {"credits": 5, "price": 22.0, "name": "Silver"},
    "gold": {"credits": 12, "price": 48.0, "name": "Gold"},
    "platinum": {"credits": 30, "price": 110.0, "name": "Platinum"}
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
    has review_link: str = "";
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

# Semantic hints for Analysis node
sem Analysis.health_score = "Overall business health score from 0-100 based on review analysis";
sem Analysis.health_grade = "Letter grade: A+, A, A-, B+, B, B-, C+, C, C-, D+, D, F";
sem Analysis.confidence_level = "Analysis confidence: 'high' (100+ reviews), 'medium' (20-99 reviews), 'low' (<20 reviews)";
sem Analysis.overall_sentiment = "Dominant sentiment: 'very_positive', 'positive', 'mixed', 'negative', 'very_negative'";
sem Analysis.sentiment_score = "Average sentiment score from -1.0 (very negative) to 1.0 (very positive)";
sem Analysis.positive_percentage = "Percentage of positive reviews (0-100)";
sem Analysis.negative_percentage = "Percentage of negative reviews (0-100)";
sem Analysis.trend_direction = "Sentiment trend over time: 'improving', 'stable', or 'declining'";
sem Analysis.critical_issues = "List of urgent issues requiring immediate attention with severity ratings";
sem Analysis.pain_points = "Customer pain points mentioned repeatedly in reviews";
sem Analysis.delighters = "Aspects that customers love and mention frequently";

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

# Semantic hints for Report node
sem Report.headline = "Compelling executive summary headline (10-15 words)";
sem Report.one_liner = "Single-sentence key takeaway for quick scanning";
sem Report.key_metric = "Primary metric highlight (e.g., '91% customer satisfaction')";
sem Report.executive_summary = "2-3 paragraph executive summary for decision makers";
sem Report.key_findings = "List of 3-7 key findings ordered by importance";
sem Report.recommendations_immediate = "Actions to take this week (2-3 items)";
sem Report.recommendations_short_term = "Actions to take this month (2-4 items)";
sem Report.recommendations_long_term = "Actions to take this quarter (1-3 items)";
sem Report.brand_context = "Brand positioning context with price level, protected strengths, and risks";
sem Report.do_not_recommendations = "CRITICAL: List of what NOT to do to protect brand (2-4 items)";
sem Report.overall_risk_assessment = "Summary of risk profile across all recommendations";

# ═══════════════════════════════════════════════════════════════════════════════
# USER MANAGEMENT & AUTHENTICATION
# ═══════════════════════════════════════════════════════════════════════════════

enum UserRole {
    USER = "user",
    ADMIN = "admin"
}

node UserProfile {
    has username: str = "";  # Primary key - matches JAC user registration
    has role: UserRole = UserRole.USER;
    has created_at: str = "";

    # Simple Credit System (1 credit = 1 complete analysis, 0.25 = 1 reply)
    has credits: float = 0.0;           # Available credits
    has credits_used: float = 0.0;      # Lifetime credits used

    # Usage Tracking
    has current_business_count: int = 0;

    # Audit
    has last_login: str = "";
    has is_active: bool = True;

    # Token Management (for session control beyond JWT)
    has token: str = "";
    has token_expires: str = "";

    # Payment tracking
    has payment_customer_id: str = "";  # Stripe customer ID (dummy)
    has last_payment_date: str = "";
}

# ═══════════════════════════════════════════════════════════════════════════════
# CREDIT SYSTEM NODES
# ═══════════════════════════════════════════════════════════════════════════════

node CreditTransaction {
    has transaction_id: str = "";
    has user_id: str = "";
    has transaction_type: str = "";           # "purchase", "usage", "grant", "refund", "reply"
    has amount: float = 0.0;                  # Positive for add, negative for deduct
    has balance_after: float = 0.0;           # Balance after this transaction
    has package_name: str = "";               # "bronze", "silver", "gold", "platinum" (for purchases)
    has description: str = "";                # "Analysis of Street Burger", "Reply to review"
    has related_business_id: str = "";        # Link to business place_id if usage type
    has related_review_id: str = "";          # Link to review_id if reply type
    has created_at: str = "";
}

# Semantic hints for UserProfile
sem UserProfile.credits = "Available credits (1 credit = up to 100 reviews analyzed, 0.25 = 1 reply)";
sem UserProfile.credits_used = "Lifetime total credits consumed";
sem UserProfile.payment_customer_id = "Stripe customer ID for payment processing (dummy in this implementation)";
sem UserProfile.last_payment_date = "ISO timestamp of most recent successful payment";

# Semantic hints for CreditTransaction node
sem CreditTransaction.transaction_id = "Unique UUID for this credit transaction";
sem CreditTransaction.user_id = "Username of the user";
sem CreditTransaction.transaction_type = "Type: 'purchase' (buy package), 'usage' (analysis), 'grant' (admin), 'refund'";
sem CreditTransaction.amount = "Amount changed: positive for add, negative for deduct";
sem CreditTransaction.balance_after = "Credit balance after this transaction";
sem CreditTransaction.package_name = "Package name if purchase: 'bronze', 'silver', 'gold', 'platinum'";
sem CreditTransaction.description = "Human-readable description of the transaction";
sem CreditTransaction.related_business_id = "Link to business place_id if this was a usage transaction";

# ═══════════════════════════════════════════════════════════════════════════════
# REVIEW REPLY SYSTEM
# ═══════════════════════════════════════════════════════════════════════════════

node ReplyPromptConfig {
    has tone: str = "friendly_professional";  # friendly, formal, casual, friendly_professional
    has max_length: str = "medium";           # short, medium, long
    has include_name: bool = True;            # Include reviewer's name in reply
    has offer_resolution: bool = True;        # Offer resolution for negative reviews
    has sign_off: str = "";                   # Custom sign-off (e.g., "The [Business] Team")
    has custom_instructions: str = "";        # User's custom prompt additions
    has created_at: str = "";
    has updated_at: str = "";
}

sem ReplyPromptConfig = "User's configuration for AI-generated review replies";
sem ReplyPromptConfig.tone = "Reply tone: 'friendly', 'formal', 'casual', or 'friendly_professional'";
sem ReplyPromptConfig.max_length = "Reply length: 'short' (1-2 sentences), 'medium' (2-3 sentences), 'long' (3-4 sentences)";
sem ReplyPromptConfig.include_name = "Whether to address the reviewer by name";
sem ReplyPromptConfig.offer_resolution = "Whether to offer resolution/contact for negative reviews";
sem ReplyPromptConfig.sign_off = "Custom sign-off text, leave empty to use business name";
sem ReplyPromptConfig.custom_instructions = "Additional instructions for reply generation";

node ReviewReply {
    has reply_id: str = "";
    has reply_text: str = "";
    has generated_at: str = "";
    has credits_used: float = 0.25;
    has tone_used: str = "";                  # Tone setting when generated
    has review_sentiment: str = "";           # Sentiment of the original review
    has review_rating: int = 0;               # Rating of the original review
    has source: str = "ai";                   # "ai" or "template"
    has template_id: str = "";                # template_id if source="template"
}

sem ReviewReply = "AI-generated or template-based reply to a customer review";
sem ReviewReply.reply_id = "Unique identifier for this reply";
sem ReviewReply.reply_text = "The generated reply text";
sem ReviewReply.generated_at = "ISO timestamp when reply was generated";
sem ReviewReply.credits_used = "Credits consumed for this reply (0.25 for AI, 0 for template)";
sem ReviewReply.tone_used = "Tone setting used for generation";
sem ReviewReply.review_sentiment = "Sentiment of the original review";
sem ReviewReply.review_rating = "Star rating of the original review";
sem ReviewReply.source = "Source of the reply: 'ai' for LLM-generated, 'template' for template-based";
sem ReviewReply.template_id = "Template ID if source is 'template', empty string otherwise";

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

edge HasReply {
    has generated_at: str = "";
}

edge HasReplyConfig {
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

# ═══════════════════════════════════════════════════════════════════════════════
# REVIEW REPLY LLM OUTPUT OBJECTS
# ═══════════════════════════════════════════════════════════════════════════════

obj GeneratedReplyResult {
    has reply_text: str;
}

sem GeneratedReplyResult = "AI-generated reply to a customer review";
sem GeneratedReplyResult.reply_text = "The professional, contextual reply text";

obj BulkReplyResult {
    has replies: list[SingleReplyResult];
}

obj SingleReplyResult {
    has review_id: str;
    has reply_text: str;
}

sem BulkReplyResult = "Batch of generated replies for multiple reviews";
sem BulkReplyResult.replies = "List of individual reply results, one per input review";
sem SingleReplyResult = "Generated reply for a single review in a batch";
sem SingleReplyResult.review_id = "ID of the review this reply is for";
sem SingleReplyResult.reply_text = "The generated reply text";

# ═══════════════════════════════════════════════════════════════════════════════
# CONTENT GENERATION EDGES
# ═══════════════════════════════════════════════════════════════════════════════

edge HasSocialMediaPost {
    has created_at: str = "";
}

edge HasActionPlan {
    has version: int = 1;
}

edge HasMarketingCopy {
    has created_at: str = "";
}

edge HasBlogPost {
    has created_at: str = "";
}

edge HasResponseTemplate {
    has category: str = "";
}

edge HasSocialMediaPostConfig {
    has version: int = 1;
}

edge HasMarketingCopyConfig {
    has version: int = 1;
}

edge HasBlogPostConfig {
    has version: int = 1;
}

# ═══════════════════════════════════════════════════════════════════════════════
# RESPONSE TEMPLATE LIBRARY
# ═══════════════════════════════════════════════════════════════════════════════

node ResponseTemplate {
    has template_id: str = "";
    has name: str = "";
    has category: str = "";
    has scenario: str = "";
    has business_type: str = "GENERIC";
    has template_text: str = "";
    has placeholders: list[str] = [];
    has tone: str = "friendly_professional";
    has is_system: bool = False;
    has usage_count: int = 0;
    has created_at: str = "";
    has updated_at: str = "";
}

sem ResponseTemplate = "Pre-built or user-created reply template with customizable placeholders";
sem ResponseTemplate.template_id = "Unique identifier for this template";
sem ResponseTemplate.name = "Human-readable template name (e.g., 'Thank You - General Positive')";
sem ResponseTemplate.category = "Sentiment category: 'positive', 'negative', 'neutral', 'mixed'";
sem ResponseTemplate.scenario = "Specific scenario: 'praise', 'complaint_service', 'complaint_quality', 'suggestion', 'question', 'return_visit', 'first_visit', 'detailed_feedback'";
sem ResponseTemplate.business_type = "Business type: 'RESTAURANT', 'HOTEL', 'RETAIL', etc. or 'GENERIC'";
sem ResponseTemplate.template_text = "Template text with {placeholder} markers for customization";
sem ResponseTemplate.placeholders = "List of placeholder names used in template_text";
sem ResponseTemplate.is_system = "Whether this is a system-provided template (true) or user-created (false)";
sem ResponseTemplate.usage_count = "Number of times this template has been used";

# ═══════════════════════════════════════════════════════════════════════════════
# SOCIAL MEDIA POST GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

node SocialMediaPostConfig {
    has brand_name: str = "";
    has brand_voice: str = "professional";
    has default_hashtags: list[str] = [];
    has include_star_rating: bool = True;
    has include_review_quote: bool = True;
    has include_call_to_action: bool = True;
    has call_to_action_text: str = "";
    has created_at: str = "";
    has updated_at: str = "";
}

sem SocialMediaPostConfig = "User's branding preferences for social media post generation";
sem SocialMediaPostConfig.brand_voice = "Brand voice: 'professional', 'casual', 'playful', 'authoritative'";
sem SocialMediaPostConfig.default_hashtags = "Default hashtags to append to posts";
sem SocialMediaPostConfig.include_star_rating = "Whether to include star rating emoji/text";
sem SocialMediaPostConfig.include_call_to_action = "Whether to include a call-to-action at the end";

node SocialMediaPost {
    has post_id: str = "";
    has platform: str = "";
    has post_text: str = "";
    has hashtags: list[str] = [];
    has review_quote: str = "";
    has review_author: str = "";
    has review_rating: int = 0;
    has character_count: int = 0;
    has credits_used: float = 0.0;
    has generated_at: str = "";
}

sem SocialMediaPost = "Generated social media post featuring customer review highlights";
sem SocialMediaPost.platform = "Target platform: 'twitter' (280 chars), 'facebook' (longer), 'instagram' (visual-ready), 'linkedin' (professional)";
sem SocialMediaPost.post_text = "The complete post text ready for publishing";
sem SocialMediaPost.hashtags = "Relevant hashtags for the post";
sem SocialMediaPost.review_quote = "Excerpt from the customer review used in the post";

# ═══════════════════════════════════════════════════════════════════════════════
# ACTION PLAN GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

node ActionPlan {
    has plan_id: str = "";
    has title: str = "";
    has overview: str = "";
    has timeframe: str = "";
    has total_action_items: int = 0;
    has immediate_actions: list[dict] = [];
    has short_term_actions: list[dict] = [];
    has medium_term_actions: list[dict] = [];
    has kpis: list[dict] = [];
    has expected_outcomes: list[str] = [];
    has risk_factors: list[str] = [];
    has based_on_health_score: int = 0;
    has based_on_review_count: int = 0;
    has key_issues_addressed: list[str] = [];
    has credits_used: float = 0.0;
    has generated_at: str = "";
}

sem ActionPlan = "Structured improvement roadmap derived from review analysis data";
sem ActionPlan.title = "Descriptive plan title (e.g., 'Service Excellence Recovery Plan')";
sem ActionPlan.overview = "2-3 sentence executive summary of the plan's goals and approach";
sem ActionPlan.timeframe = "Plan duration: '30_day', '60_day', or '90_day'";
sem ActionPlan.immediate_actions = "Actions for days 1-7 with action, owner_role, kpi, effort, expected_impact, source_issue";
sem ActionPlan.short_term_actions = "Actions for days 8-30 with same structure";
sem ActionPlan.medium_term_actions = "Actions for days 31-90 with same structure";
sem ActionPlan.kpis = "Measurable KPIs with name, current_value, target_value, measurement_method";

# ═══════════════════════════════════════════════════════════════════════════════
# MARKETING COPY GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

node MarketingCopyConfig {
    has brand_name: str = "";
    has brand_tagline: str = "";
    has target_audience: str = "";
    has unique_selling_points: list[str] = [];
    has tone: str = "persuasive";
    has created_at: str = "";
    has updated_at: str = "";
}

sem MarketingCopyConfig = "User's branding preferences for marketing copy generation";
sem MarketingCopyConfig.target_audience = "Primary target audience for ads";
sem MarketingCopyConfig.unique_selling_points = "Key USPs to highlight in copy";
sem MarketingCopyConfig.tone = "Ad tone: 'persuasive', 'informational', 'emotional', 'urgent'";

node MarketingCopy {
    has copy_id: str = "";
    has ad_format: str = "";
    has headline: str = "";
    has body_text: str = "";
    has call_to_action: str = "";
    has variant_label: str = "";
    has character_counts: dict = {};
    has source_delighters: list[str] = [];
    has source_quotes: list[str] = [];
    has credits_used: float = 0.0;
    has generated_at: str = "";
}

sem MarketingCopy = "Generated advertising copy based on customer review highlights";
sem MarketingCopy.ad_format = "Ad format: 'google_search', 'google_display', 'facebook_ad', 'instagram_ad', 'email_subject', 'email_body'";
sem MarketingCopy.headline = "Ad headline text";
sem MarketingCopy.body_text = "Ad body/description text";
sem MarketingCopy.call_to_action = "Call-to-action text";
sem MarketingCopy.variant_label = "A/B variant label for testing (A, B, or C)";

# ═══════════════════════════════════════════════════════════════════════════════
# BLOG POST GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

node BlogPostConfig {
    has author_name: str = "";
    has brand_name: str = "";
    has writing_style: str = "informative";
    has target_word_count: int = 800;
    has include_data_visualizations: bool = True;
    has seo_focus: bool = True;
    has created_at: str = "";
    has updated_at: str = "";
}

sem BlogPostConfig = "User's preferences for blog content generation";
sem BlogPostConfig.writing_style = "Style: 'informative', 'storytelling', 'data_driven', 'conversational'";
sem BlogPostConfig.target_word_count = "Target word count for generated posts (600-2000)";
sem BlogPostConfig.include_data_visualizations = "Whether to include data callout suggestions";

node BlogPost {
    has post_id: str = "";
    has content_type: str = "";
    has title: str = "";
    has meta_description: str = "";
    has slug: str = "";
    has introduction: str = "";
    has body_sections: list[dict] = [];
    has conclusion: str = "";
    has seo_keywords: list[str] = [];
    has word_count: int = 0;
    has data_points_referenced: list[dict] = [];
    has credits_used: float = 0.0;
    has generated_at: str = "";
}

sem BlogPost = "AI-generated blog post derived from review analysis insights";
sem BlogPost.content_type = "Content format: 'improvement_story', 'customer_spotlight', 'insights_listicle', 'case_study', 'trend_analysis'";
sem BlogPost.title = "SEO-optimized blog post title";
sem BlogPost.meta_description = "SEO meta description (150-160 characters)";
sem BlogPost.body_sections = "List of sections with heading, content, and supporting data_points";
sem BlogPost.seo_keywords = "Target SEO keywords for the post";

# ═══════════════════════════════════════════════════════════════════════════════
# CONTENT GENERATION LLM OUTPUT OBJECTS
# ═══════════════════════════════════════════════════════════════════════════════

# --- Social Media Post Generation ---

obj SocialMediaPostResult {
    has posts: list[SingleSocialPost];
}

obj SingleSocialPost {
    has platform: str;
    has post_text: str;
    has hashtags: list[str];
    has review_quote: str;
    has character_count: int;
}

sem SocialMediaPostResult = "Batch of generated social media posts for multiple platforms";
sem SocialMediaPostResult.posts = "List of platform-specific posts";
sem SingleSocialPost = "A single social media post for a specific platform";
sem SingleSocialPost.platform = "Target platform: 'twitter', 'facebook', 'instagram', 'linkedin'";
sem SingleSocialPost.post_text = "Complete post text optimized for the platform's character limits and style";
sem SingleSocialPost.hashtags = "Relevant hashtags (3-5 for Twitter/Instagram, 1-3 for LinkedIn/Facebook)";
sem SingleSocialPost.review_quote = "The exact customer quote excerpt used in the post";
sem SingleSocialPost.character_count = "Total character count of the post text";

# --- Action Plan Generation ---

obj ActionPlanItem {
    has action: str;
    has owner_role: str;
    has kpi: str;
    has effort: str;
    has expected_impact: str;
    has source_issue: str;
    has timeline_days: int;
}

sem ActionPlanItem = "A single action item in the improvement plan";
sem ActionPlanItem.action = "Specific, verb-driven action to take";
sem ActionPlanItem.owner_role = "Role responsible: 'manager', 'staff', 'owner', 'marketing', 'operations'";
sem ActionPlanItem.kpi = "Measurable KPI to track success of this action";
sem ActionPlanItem.effort = "Effort level: 'low', 'medium', 'high'";
sem ActionPlanItem.expected_impact = "Expected business impact of completing this action";
sem ActionPlanItem.source_issue = "The specific review issue/pain point this addresses";
sem ActionPlanItem.timeline_days = "Number of days to complete this action";

obj ActionPlanKPI {
    has name: str;
    has current_value: str;
    has target_value: str;
    has measurement_method: str;
    has review_frequency: str;
}

sem ActionPlanKPI = "Key Performance Indicator for tracking plan progress";
sem ActionPlanKPI.name = "KPI name (e.g., 'Average response time', 'Customer satisfaction score')";
sem ActionPlanKPI.current_value = "Current baseline value derived from review data";
sem ActionPlanKPI.target_value = "Target value to achieve within the plan timeframe";
sem ActionPlanKPI.measurement_method = "How to measure this KPI";
sem ActionPlanKPI.review_frequency = "How often to check: 'daily', 'weekly', 'monthly'";

obj ActionPlanResult {
    has title: str;
    has overview: str;
    has immediate_actions: list[ActionPlanItem];
    has short_term_actions: list[ActionPlanItem];
    has medium_term_actions: list[ActionPlanItem];
    has kpis: list[ActionPlanKPI];
    has expected_outcomes: list[str];
    has risk_factors: list[str];
}

sem ActionPlanResult = "Complete improvement action plan with prioritized items and KPIs";
sem ActionPlanResult.title = "Plan title that captures the primary improvement objective";
sem ActionPlanResult.overview = "2-3 sentence executive summary of the plan";
sem ActionPlanResult.immediate_actions = "3-5 actions for this week (days 1-7)";
sem ActionPlanResult.short_term_actions = "3-5 actions for this month (days 8-30)";
sem ActionPlanResult.medium_term_actions = "2-4 actions for months 2-3 (days 31-90)";
sem ActionPlanResult.kpis = "4-6 measurable KPIs to track plan success";
sem ActionPlanResult.expected_outcomes = "3-5 expected outcomes if the plan is executed";
sem ActionPlanResult.risk_factors = "2-3 risk factors that could derail the plan";

# --- Marketing Copy Generation ---

obj MarketingCopyVariant {
    has headline: str;
    has body_text: str;
    has call_to_action: str;
    has variant_label: str;
}

sem MarketingCopyVariant = "A single ad copy variant for A/B testing";
sem MarketingCopyVariant.headline = "Ad headline optimized for the format's character limits";
sem MarketingCopyVariant.body_text = "Ad body text with persuasive messaging based on review data";
sem MarketingCopyVariant.call_to_action = "Compelling call-to-action text";
sem MarketingCopyVariant.variant_label = "Variant label: 'A', 'B', or 'C'";

obj MarketingCopyResult {
    has variants: list[MarketingCopyVariant];
    has source_delighters: list[str];
    has source_quotes: list[str];
}

sem MarketingCopyResult = "Set of ad copy variants generated from review highlights";
sem MarketingCopyResult.variants = "2-3 variants for A/B testing";
sem MarketingCopyResult.source_delighters = "Customer delighters used as the basis for copy";
sem MarketingCopyResult.source_quotes = "Paraphrased customer quotes referenced in copy";

# --- Blog Post Generation ---

obj BlogSection {
    has heading: str;
    has content: str;
    has data_points: list[str];
}

sem BlogSection = "A single section of a blog post";
sem BlogSection.heading = "Section heading (H2 level)";
sem BlogSection.content = "Section body text (2-4 paragraphs)";
sem BlogSection.data_points = "Supporting data points or statistics cited in this section";

obj BlogPostResult {
    has title: str;
    has meta_description: str;
    has slug: str;
    has introduction: str;
    has body_sections: list[BlogSection];
    has conclusion: str;
    has seo_keywords: list[str];
    has word_count: int;
}

sem BlogPostResult = "Complete blog post with SEO optimization";
sem BlogPostResult.title = "SEO-optimized blog title (50-60 characters)";
sem BlogPostResult.meta_description = "Meta description for search engines (150-160 characters)";
sem BlogPostResult.slug = "URL-friendly slug derived from title";
sem BlogPostResult.introduction = "Engaging introduction paragraph (100-150 words)";
sem BlogPostResult.body_sections = "3-5 structured body sections with headings and data";
sem BlogPostResult.conclusion = "Conclusion with summary and call-to-action (100-150 words)";
sem BlogPostResult.seo_keywords = "5-10 target SEO keywords";
sem BlogPostResult.word_count = "Total word count of the generated post";

