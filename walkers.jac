# ══════════════════════════════════════════════════════════════════════════════
# REVIEW ANALYZER V2 - WALKER AGENTS
# ══════════════════════════════════════════════════════════════════════════════
# Major improvements:
# - Batch sentiment analysis (5 reviews per LLM call)
# - Business type detection with sub-themes
# - Health score calculation
# - Trend analysis
# - Statistical confidence
# - Deep pattern analysis
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }
import from uuid { uuid4 }
import re, json, os, requests;

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

# ═══════════════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

def parse_google_maps_url(url: str) -> dict {
    result = {
        "is_valid": False,
        "place_id": "",
        "data_id": "",
        "cid": "",
        "place_name": "",
        "error": ""
    };
    
    try {
        valid_hosts = ["google.com", "maps.google.com", "goo.gl"];
        is_google = False;
        for host in valid_hosts {
            if host in url.lower() {
                is_google = True;
                break;
            }
        }
        
        if not is_google {
            result["error"] = "Not a Google Maps URL";
            return result;
        }
        
        # Extract data_id
        data_id_match = re.search(r'!1s(0x[a-f0-9]+:0x[a-f0-9]+)', url, re.IGNORECASE);
        if data_id_match {
            result["data_id"] = data_id_match.group(1);
            result["is_valid"] = True;
        }
        
        # Extract place_id
        place_id_match = re.search(r'place_id[=:]([^&\s]+)', url, re.IGNORECASE);
        if place_id_match {
            result["place_id"] = place_id_match.group(1);
            result["is_valid"] = True;
        }
        
        # Extract CID
        cid_match = re.search(r'cid=(\d+)', url);
        if cid_match {
            result["cid"] = cid_match.group(1);
            result["is_valid"] = True;
        }
        
        # Extract place name
        name_match = re.search(r'/maps/place/([^/@]+)', url);
        if name_match {
            result["place_name"] = name_match.group(1).replace('+', ' ').replace('%20', ' ').replace('%26', '&');
        }
        
        if not result["is_valid"] and ('/maps/place/' in url or '/maps?' in url) {
            result["is_valid"] = True;
        }
        
        if not result["is_valid"] {
            result["error"] = "Could not extract place identifier";
        }
        
    } except Exception as e {
        result["error"] = f"Parse error: {str(e)}";
    }
    
    return result;
}

def detect_business_type(google_type: str, business_name: str) -> str {
    # Try direct mapping first
    google_type_lower = google_type.lower().replace(" ", "_");
    
    if google_type_lower in BUSINESS_TYPE_MAP {
        return BUSINESS_TYPE_MAP[google_type_lower];
    }
    
    # Try partial matching
    for (key, value) in BUSINESS_TYPE_MAP.items() {
        if key in google_type_lower or google_type_lower in key {
            return value;
        }
    }
    
    # Try name-based detection
    name_lower = business_name.lower();
    name_keywords = {
        "restaurant": "RESTAURANT",
        "cafe": "RESTAURANT",
        "coffee": "RESTAURANT",
        "pizza": "RESTAURANT",
        "burger": "RESTAURANT",
        "bakery": "RESTAURANT",
        "hotel": "HOTEL",
        "resort": "HOTEL",
        "inn": "HOTEL",
        "lodge": "HOTEL",
        "hostel": "HOTEL",
        "store": "RETAIL",
        "shop": "RETAIL",
        "mart": "RETAIL",
        "salon": "SALON",
        "spa": "SALON",
        "beauty": "SALON",
        "barber": "SALON",
        "clinic": "HEALTHCARE",
        "hospital": "HEALTHCARE",
        "dental": "HEALTHCARE",
        "medical": "HEALTHCARE",
        "gym": "GYM",
        "fitness": "GYM"
    };
    
    for (keyword, btype) in name_keywords.items() {
        if keyword in name_lower {
            return btype;
        }
    }
    
    return "GENERIC";
}

def get_confidence_level(review_count: int) -> str {
    if review_count < CONFIDENCE_THRESHOLDS["low_max"] {
        return "low";
    } elif review_count < CONFIDENCE_THRESHOLDS["medium_max"] {
        return "medium";
    } else {
        return "high";
    }
}

def calculate_health_grade(score: int) -> str {
    if score >= 95 { return "A+"; }
    elif score >= 90 { return "A"; }
    elif score >= 87 { return "A-"; }
    elif score >= 83 { return "B+"; }
    elif score >= 80 { return "B"; }
    elif score >= 77 { return "B-"; }
    elif score >= 73 { return "C+"; }
    elif score >= 70 { return "C"; }
    elif score >= 67 { return "C-"; }
    elif score >= 60 { return "D"; }
    else { return "F"; }
}

def parse_review_date(date_str: str, relative_date: str) -> str {
    # Try to extract year-month from various formats
    # Returns YYYY-MM format or empty string
    
    if not date_str and not relative_date {
        return "";
    }
    
    # Try parsing date_str first (formats like "2024-01-15", "January 15, 2024", etc.)
    if date_str {
        # ISO format
        iso_match = re.search(r'(\d{4})-(\d{2})', date_str);
        if iso_match {
            return f"{iso_match.group(1)}-{iso_match.group(2)}";
        }
        
        # Month name format
        months = {
            "january": "01", "february": "02", "march": "03", "april": "04",
            "may": "05", "june": "06", "july": "07", "august": "08",
            "september": "09", "october": "10", "november": "11", "december": "12",
            "jan": "01", "feb": "02", "mar": "03", "apr": "04",
            "jun": "06", "jul": "07", "aug": "08", "sep": "09",
            "oct": "10", "nov": "11", "dec": "12"
        };
        
        date_lower = date_str.lower();
        for (month_name, month_num) in months.items() {
            if month_name in date_lower {
                year_match = re.search(r'(\d{4})', date_str);
                if year_match {
                    return f"{year_match.group(1)}-{month_num}";
                }
            }
        }
    }
    
    # Fallback: use relative_date to estimate
    if relative_date {
        now = datetime.now();
        relative_lower = relative_date.lower();
        
        if "day" in relative_lower or "hour" in relative_lower or "minute" in relative_lower {
            return now.strftime("%Y-%m");
        } elif "week" in relative_lower {
            return now.strftime("%Y-%m");
        } elif "month" in relative_lower {
            num_match = re.search(r'(\d+)', relative_lower);
            if num_match {
                months_ago = int(num_match.group(1));
                month = now.month - months_ago;
                year = now.year;
                while month <= 0 {
                    month += 12;
                    year -= 1;
                }
                return f"{year}-{month:02d}";
            }
            return now.strftime("%Y-%m");
        } elif "year" in relative_lower {
            num_match = re.search(r'(\d+)', relative_lower);
            if num_match {
                years_ago = int(num_match.group(1));
                return f"{now.year - years_ago}-{now.month:02d}";
            }
        }
    }
    
    return "";
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 1: DATA FETCHER (Enhanced)
# ═══════════════════════════════════════════════════════════════════════════════

walker DataFetcherAgent {
    has url: str;
    has max_reviews: int = 100;
    has existing_business_id: str = "";  # Pass existing business_id for refresh mode

    # Results
    has business: Business = None;
    has reviews_fetched: int = 0;
    has status: str = "pending";
    has error: str = "";
    has data_source: str = "";
    has is_refresh: bool = False;

    can start with `root entry {
        print(f"\n🚀 DataFetcherAgent starting...");

        # Get API key from environment (not stored as property to avoid exposure)
        serp_api_key = os.environ.get("SERPAPI_KEY", "");

        # Determine data source
        if serp_api_key and len(serp_api_key) > 10 {
            self.data_source = "serpapi";
            masked = serp_api_key[:6] + "..." + serp_api_key[-4:];
            print(f"   🌐 DATA SOURCE: SERP API (key: {masked})");
        } else {
            self.data_source = "mock";
            print("   📦 DATA SOURCE: MOCK (no API key)");
        }

        # Parse URL
        parsed = parse_google_maps_url(self.url);

        if not parsed["is_valid"] {
            self.error = f"Invalid URL: {parsed['error']}";
            self.status = "failed";
            print(f"   ❌ {self.error}");
            disengage;
        }

        print(f"   ✓ URL parsed - data_id: {parsed['data_id']}");

        # Check for existing business (refresh mode)
        business_id = parsed["data_id"] if parsed["data_id"] else str(uuid4());
        existing_biz = None;

        if self.existing_business_id {
            # Explicit refresh mode - find the business
            businesses = [here -->(`?Business)];
            for biz in businesses {
                if biz.place_id == self.existing_business_id {
                    existing_biz = biz;
                    break;
                }
            }
        } else {
            # Check if business already exists by place_id
            businesses = [here -->(`?Business)];
            for biz in businesses {
                if biz.place_id == business_id {
                    existing_biz = biz;
                    break;
                }
            }
        }

        if existing_biz {
            # Refresh mode: update existing business
            self.is_refresh = True;
            self.business = [existing_biz];
            self.business[0].status = "refreshing";
            print(f"   🔄 REFRESH MODE: Updating existing business: {existing_biz.name}");

            # Clear old reviews, themes, analysis, and reports
            old_reviews = [existing_biz -->(`?Review)];
            old_themes = [existing_biz -->(`?Theme)];
            old_analyses = [existing_biz -->(`?Analysis)];
            old_reports = [existing_biz -->(`?Report)];

            print(f"   🗑️  Clearing {len(old_reviews)} old reviews, {len(old_themes)} themes, {len(old_analyses)} analyses, {len(old_reports)} reports");

            for r in old_reviews {
                del r;
            }
            for t in old_themes {
                del t;
            }
            for a in old_analyses {
                del a;
            }
            for rep in old_reports {
                del rep;
            }
        } else {
            # Create new Business node
            self.business = here ++> Business(
                place_id=business_id,
                data_id=parsed["data_id"],
                name=parsed["place_name"] if parsed["place_name"] else "Unknown Business",
                original_url=self.url,
                status="fetching"
            );
            print(f"   ➕ Creating new business node");
        }

        # Fetch place details
        print("   📍 Fetching place details...");
        self.fetch_place_details(parsed);
        
        # Detect business type
        detected_type = detect_business_type(
            self.business[0].business_type,
            self.business[0].name
        );
        self.business[0].business_type_normalized = detected_type;
        print(f"   🏷️  Business type: {detected_type}");
        
        # Fetch reviews
        print(f"   📝 Fetching up to {self.max_reviews} reviews...");
        self.fetch_reviews(parsed);
        
        # Update status
        self.business[0].status = "fetched";
        self.business[0].fetched_at = datetime.now().isoformat();
        self.status = "completed";
        
        print(f"   ✅ Fetched {self.reviews_fetched} reviews for {self.business[0].name}");
    }
    
    def fetch_place_details(parsed: dict) {
        if self.data_source == "serpapi" {
            self.fetch_real_place_details(parsed);
        } else {
            self.use_mock_place_details(parsed);
        }
    }
    
    def fetch_real_place_details(parsed: dict) {
        try {
            # Construct the 'data' parameter in the format Google Maps API expects
            # Format: !4m5!3m4!1s{data_id}!8m2!3d{lat}!4d{lng}
            data_id = parsed["data_id"];
            data_param = f"!4m5!3m4!1s{data_id}!8m2!3d0!4d0!16s";

            # Get API key from environment
            api_key = os.environ.get("SERPAPI_KEY", "");

            params = {
                "engine": "google_maps",
                "type": "place",
                "data": data_param,
                "api_key": api_key,
                "hl": "en"
            };

            response = requests.get("https://serpapi.com/search", params=params, timeout=30);
            data = response.json();

            if "place_results" in data {
                place = data["place_results"];

                # Basic info
                self.business[0].name = place.get("title", self.business[0].name);
                self.business[0].address = place.get("address", "");
                self.business[0].phone = place.get("phone", "");
                self.business[0].website = place.get("website", "");
                self.business[0].rating = float(place.get("rating", 0));
                self.business[0].total_reviews = int(place.get("reviews", 0));
                self.business[0].price_level = place.get("price", "");

                # Business type - API returns array like ["Coffee shop", "Cafe", ...]
                type_list = place.get("type", []);
                if isinstance(type_list, list) and type_list {
                    self.business[0].business_type = ", ".join(type_list);
                } elif isinstance(type_list, str) {
                    self.business[0].business_type = type_list;
                }

                # GPS coordinates
                gps = place.get("gps_coordinates", {});
                self.business[0].latitude = gps.get("latitude", 0.0);
                self.business[0].longitude = gps.get("longitude", 0.0);

                # Opening hours - API uses "hours" key with array of day objects
                if "hours" in place {
                    hours_dict = {};
                    for day_obj in place["hours"] {
                        for (day, time) in day_obj.items() {
                            hours_dict[day] = time;
                        }
                    }
                    self.business[0].opening_hours = hours_dict;
                }

                # Photos count
                if "images" in place {
                    self.business[0].photos_count = len(place.get("images", []));
                }

                # Popular times (if available)
                if "popular_times" in place {
                    self.business[0].popular_times = place["popular_times"];
                }
            }
        } except Exception as e {
            print(f"      ⚠️ Place details warning: {str(e)}");
        }
    }
    
    def use_mock_place_details(parsed: dict) {
        self.business[0].name = parsed["place_name"] if parsed["place_name"] else "Demo Business";
        self.business[0].address = "123 Main Street, City Center";
        self.business[0].rating = 4.2;
        self.business[0].total_reviews = 150;
        self.business[0].business_type = "Restaurant";
        self.business[0].phone = "+1 (555) 123-4567";
        self.business[0].price_level = "$$";
        self.business[0].opening_hours = {
            "monday": "9:00 AM - 10:00 PM",
            "tuesday": "9:00 AM - 10:00 PM",
            "wednesday": "9:00 AM - 10:00 PM",
            "thursday": "9:00 AM - 10:00 PM",
            "friday": "9:00 AM - 11:00 PM",
            "saturday": "10:00 AM - 11:00 PM",
            "sunday": "10:00 AM - 9:00 PM"
        };
        self.business[0].photos_count = 45;
    }
    
    def fetch_reviews(parsed: dict) {
        if self.data_source == "serpapi" {
            self.fetch_real_reviews(parsed);
        } else {
            self.use_mock_reviews();
        }
    }
    
    def fetch_real_reviews(parsed: dict) {
        next_page_token = None;
        total_fetched = 0;
        page = 1;

        # Get API key from environment
        api_key = os.environ.get("SERPAPI_KEY", "");

        while total_fetched < self.max_reviews {
            try {
                params = {
                    "engine": "google_maps_reviews",
                    "data_id": parsed["data_id"],
                    "api_key": api_key,
                    "sort_by": "newestFirst"
                };
                
                if next_page_token {
                    params["num"] = 20;
                    params["next_page_token"] = next_page_token;
                }
                
                response = requests.get("https://serpapi.com/search", params=params, timeout=30);
                data = response.json();
                
                reviews = data.get("reviews", []);
                print(f"      Page {page}: {len(reviews)} reviews");
                
                for rev in reviews {
                    if total_fetched >= self.max_reviews {
                        break;
                    }
                    
                    self.business[0] ++> Review(
                        review_id=rev.get("review_id", str(uuid4())),
                        author=rev.get("user", {}).get("name", "Anonymous"),
                        author_image=rev.get("user", {}).get("thumbnail", ""),
                        review_link=rev.get("link", ""),
                        rating=int(rev.get("rating", 3)),
                        text=rev.get("extracted_snippet", {}).get("original", rev.get("snippet", "")),
                        date=rev.get("iso_date", rev.get("date", "")),
                        relative_date=rev.get("date", ""),
                        likes=int(rev.get("likes", 0)),
                        owner_response=rev.get("response", {}).get("extracted_snippet", {}).get("original", rev.get("response", {}).get("snippet", "")) if rev.get("response") else ""

                    );
                    total_fetched += 1;
                }
                
                next_page_token = data.get("serpapi_pagination", {}).get("next_page_token");
                if not next_page_token {
                    break;
                }
                page += 1;
                
            } except Exception as e {
                print(f"      ⚠️ Review fetch error: {str(e)}");
                break;
            }
        }
        
        self.reviews_fetched = total_fetched;
    }
    
    def use_mock_reviews() {
        mock_reviews = [
            {"rating": 5, "text": "Absolutely amazing experience! The food was incredible, especially the seafood pasta. Staff were very attentive and friendly. The ambiance was perfect for our anniversary dinner. Will definitely come back!", "author": "Sarah M.", "date": "2024-12-15", "relative_date": "2 weeks ago"},
            {"rating": 4, "text": "Great location and beautiful atmosphere. The service was good but a bit slow during peak hours. Food quality was excellent though. The desserts are a must-try!", "author": "John D.", "date": "2024-12-10", "relative_date": "3 weeks ago"},
            {"rating": 2, "text": "Disappointed with the service. Waited 45 minutes for our food. When it arrived, my steak was overcooked. The manager did apologize and offered a discount, but it ruined our evening.", "author": "Mike R.", "date": "2024-12-08", "relative_date": "3 weeks ago"},
            {"rating": 5, "text": "Best restaurant in the city! Clean, amazing food, and the staff remembered our names from last visit. The chef's special was divine. Worth every penny.", "author": "Emma L.", "date": "2024-11-25", "relative_date": "1 month ago"},
            {"rating": 3, "text": "Average experience. Food was okay but nothing special. Prices are a bit high for what you get. Location is convenient though. Might try again.", "author": "David K.", "date": "2024-11-20", "relative_date": "2 months ago"},
            {"rating": 1, "text": "Terrible experience. Food was cold, service was rude, and they got our order wrong twice. The restroom was dirty. Will not be returning.", "author": "Lisa T.", "date": "2024-11-15", "relative_date": "2 months ago"},
            {"rating": 5, "text": "The atmosphere is unbeatable! Perfect for date night. Wine selection is impressive and the waiter gave excellent recommendations. Food presentation was Instagram-worthy.", "author": "Chris P.", "date": "2024-11-10", "relative_date": "2 months ago"},
            {"rating": 4, "text": "Good food and nice ambiance. The wait time was reasonable. Parking can be tricky but overall a pleasant dining experience. Will recommend to friends.", "author": "Amanda S.", "date": "2024-10-28", "relative_date": "2 months ago"},
            {"rating": 2, "text": "Overpriced for the portion sizes. The appetizers were good but main course was disappointing. Service was friendly but slow. Expected more.", "author": "Robert J.", "date": "2024-10-20", "relative_date": "3 months ago"},
            {"rating": 5, "text": "Fantastic family dinner! Kids menu was actually healthy and tasty. Staff were patient with our children. Clean high chairs and quick service. A+ for families!", "author": "Jennifer W.", "date": "2024-10-15", "relative_date": "3 months ago"},
            {"rating": 3, "text": "Decent food but noise level was too high. Hard to have a conversation. The cocktails were creative though. Maybe better for younger crowd.", "author": "Thomas H.", "date": "2024-10-08", "relative_date": "3 months ago"},
            {"rating": 4, "text": "Excellent dinner experience. The seafood was fresh and well-prepared. Only downside was limited vegetarian options. Would love to see more variety.", "author": "Michelle G.", "date": "2024-09-25", "relative_date": "4 months ago"},
            {"rating": 5, "text": "Hidden gem! The homemade pasta is to die for. Cozy atmosphere and reasonable prices. The owner even came to check on us. Real Italian hospitality!", "author": "Frank B.", "date": "2024-09-18", "relative_date": "4 months ago"},
            {"rating": 4, "text": "Great brunch spot. Eggs Benedict was perfect. Coffee could be better but food makes up for it. Gets busy on weekends so reservations recommended.", "author": "Nancy K.", "date": "2024-09-10", "relative_date": "4 months ago"},
            {"rating": 2, "text": "Not worth the hype. Food was mediocre and overpriced. The trendy decor doesn't make up for lackluster menu. Service was okay but not memorable.", "author": "Steve M.", "date": "2024-08-28", "relative_date": "5 months ago"},
            {"rating": 5, "text": "Celebrated my birthday here and it was perfect! They surprised me with a dessert and candle. Food was exceptional and staff made us feel special.", "author": "Rachel L.", "date": "2024-08-20", "relative_date": "5 months ago"},
            {"rating": 3, "text": "Mixed feelings. Appetizers were great, main course was just okay. The view is nice but tables are too close together. Service was attentive.", "author": "Kevin O.", "date": "2024-08-12", "relative_date": "5 months ago"},
            {"rating": 4, "text": "Solid choice for business lunch. Professional atmosphere, good food, quick service. Prices are reasonable for the quality. Will bring clients here.", "author": "Diana P.", "date": "2024-07-30", "relative_date": "6 months ago"},
            {"rating": 1, "text": "Found a hair in my food. When I complained, staff was dismissive. Manager eventually offered 10% off which was insulting. Health standards questionable.", "author": "Gary S.", "date": "2024-07-22", "relative_date": "6 months ago"},
            {"rating": 5, "text": "Every dish was a masterpiece. The tasting menu with wine pairing was an incredible journey. Definitely a special occasion restaurant. Save up and go!", "author": "Victoria H.", "date": "2024-07-15", "relative_date": "6 months ago"}
        ];
        
        for (i, rev) in enumerate(mock_reviews) {
            if i >= self.max_reviews {
                break;
            }
            
            self.business[0] ++> Review(
                review_id=str(uuid4()),
                author=rev["author"],
                rating=rev["rating"],
                text=rev["text"],
                date=rev.get("date", ""),
                relative_date=rev.get("relative_date", "")
            );
            self.reviews_fetched += 1;
        }
    }
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 2: SENTIMENT ANALYZER (Batch Processing)
# ═══════════════════════════════════════════════════════════════════════════════

walker SentimentAnalyzerAgent {
    has business_id: str = "";
    has batch_size: int = 5;
    
    # Results
    has analyzed_count: int = 0;
    has sentiment_counts: dict = {"positive": 0, "negative": 0, "neutral": 0, "mixed": 0};
    has all_themes: dict = {};
    has status: str = "pending";
    
    can start with `root entry {
        print("\n🔍 SentimentAnalyzerAgent starting...");
        visit [-->(`?Business)];
    }
    
    can analyze with Business entry {
        if self.business_id and here.place_id != self.business_id {
            visit [-->];
            return;
        }
        
        print(f"   Analyzing reviews for: {here.name}");
        business_type = here.business_type_normalized;
        theme_defs = THEME_DEFINITIONS.get(business_type, THEME_DEFINITIONS["GENERIC"]);
        allowed_themes = list(theme_defs.keys());
        
        # Get unanalyzed reviews
        reviews = [here -->(`?Review)];
        unanalyzed = [];
        for r in reviews {
            if not r.analyzed {
                unanalyzed.append(r);
            }
        }
        
        print(f"   Found {len(unanalyzed)} reviews to analyze");
        
        # Process in batches
        batch_num = 1;
        for i in range(0, len(unanalyzed), self.batch_size) {
            batch = unanalyzed[i:i + self.batch_size];
            print(f"   Processing batch {batch_num} ({len(batch)} reviews)...");
            
            self.analyze_batch(batch, allowed_themes, theme_defs, business_type);
            batch_num += 1;
        }
        
        self.status = "completed";
        print(f"   ✅ Analyzed {self.analyzed_count} reviews");
        print(f"      Sentiments: {self.sentiment_counts}");
    }
    
    def analyze_batch(
        reviews: list,
        allowed_themes: list,
        theme_defs: dict,
        business_type: str
    ) {
        # Build batch input for LLM
        review_texts = [];
        for (idx, r) in enumerate(reviews) {
            review_texts.append({
                "index": idx,
                "rating": r.rating,
                "text": r.text[:500]  # Limit text length
            });
        }
        
        # Call LLM for batch analysis
        result = self.analyze_reviews_batch(
            reviews=review_texts,
            business_type=business_type,
            allowed_themes=allowed_themes,
            allowed_sub_themes=theme_defs
        );
        
        # Apply results to review nodes
        for analysis in result.reviews {
            idx = analysis.review_index;
            if idx < len(reviews) {
                r = reviews[idx];
                r.sentiment = analysis.sentiment;
                r.sentiment_score = analysis.sentiment_score;
                r.themes = analysis.themes;
                # Convert list[SubThemeMapping] to dict[str, list[str]]
                sub_themes_dict = {};
                for mapping in analysis.sub_themes {
                    sub_themes_dict[mapping.theme] = mapping.sub_themes;
                }
                r.sub_themes = sub_themes_dict;
                r.keywords = analysis.keywords;
                r.emotion = analysis.emotion;
                r.analyzed = True;
                
                # Update counts
                if analysis.sentiment in self.sentiment_counts {
                    self.sentiment_counts[analysis.sentiment] += 1;
                }
                
                # Track themes
                for theme in analysis.themes {
                    if theme not in self.all_themes {
                        self.all_themes[theme] = {"count": 0, "positive": 0, "negative": 0, "neutral": 0, "mixed": 0};
                    }
                    self.all_themes[theme]["count"] += 1;
                    self.all_themes[theme][analysis.sentiment] += 1;
                }
                
                self.analyzed_count += 1;
            }
        }
    }
    
    """Analyze sentiment and themes for a batch of reviews.

    Given reviews from a {business_type} business, classify each review's sentiment
    (positive/negative/neutral/mixed) with a score from -1.0 to 1.0, detect themes
    from the allowed theme list, identify sub-themes under each main theme, extract
    up to 5 key keywords, and determine the primary emotion.

    All analysis must be based on actual review content, not assumptions. For short
    reviews with insufficient context, mark sentiment as 'neutral' and limit themes
    to what's explicitly mentioned.

    Args:
        reviews: List of review texts to analyze
        business_type: Type of business (RESTAURANT, HOTEL, etc.)
        allowed_themes: List of valid themes for this business type
        allowed_sub_themes: Mapping of themes to valid sub-themes

    Returns:
        BatchReviewAnalysis with sentiment, themes, keywords, and emotions for each review
    """
    def analyze_reviews_batch(
        reviews: list,
        business_type: str,
        allowed_themes: list,
        allowed_sub_themes: dict
    ) -> BatchReviewAnalysis by llm(
        temperature=0.0,  # Factual classification requires low randomness
        incl_info={
            "reviews": reviews,
            "business_type": business_type,
            "allowed_themes": allowed_themes,
            "allowed_sub_themes": allowed_sub_themes,
            "instructions": "Analyze each review. Use ONLY themes from allowed_themes list. For sub_themes, map main theme to relevant sub-themes from allowed_sub_themes. Return analysis for each review by index."
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 3: PATTERN ANALYZER (Deep Analysis)
# ═══════════════════════════════════════════════════════════════════════════════

walker PatternAnalyzerAgent {
    has business_id: str = "";
    
    # Results
    has analysis: Analysis = None;
    has themes_created: int = 0;
    has status: str = "pending";
    
    can start with `root entry {
        print("\n🎯 PatternAnalyzerAgent starting...");
        visit [-->(`?Business)];
    }
    
    can analyze with Business entry {
        if self.business_id and here.place_id != self.business_id {
            visit [-->];
            return;
        }
        
        print(f"   Finding patterns for: {here.name}");
        
        reviews = [here -->(`?Review)];
        if not reviews {
            print("   ❌ No reviews found");
            self.status = "failed";
            disengage;
        }
        
        # Calculate statistics
        stats = self.calculate_statistics(reviews);
        print(f"   Calculated stats for {len(reviews)} reviews");
        
        # Build theme analysis
        themes_data = self.build_theme_analysis(reviews, here.business_type_normalized);
        print(f"   Built {len(themes_data)} theme analyses");
        
        # Calculate trends
        trends = self.calculate_trends(reviews);
        print(f"   Calculated trends ({len(trends['monthly_breakdown'])} months)");
        
        # Get LLM pattern analysis
        llm_analysis = self.generate_pattern_analysis(
            business_name=here.name,
            business_type=here.business_type_normalized,
            review_count=len(reviews),
            stats=stats,
            themes=themes_data,
            trends=trends
        );
        
        # Convert LLM result objects to dicts for storage
        health_breakdown_dict = {};
        for item in llm_analysis.health_breakdown {
            health_breakdown_dict[item.theme] = item.score;
        }

        strengths_list = [{"point": s.point, "evidence_count": s.evidence_count} for s in llm_analysis.strengths];
        weaknesses_list = [{"point": w.point, "evidence_count": w.evidence_count} for w in llm_analysis.weaknesses];
        opportunities_list = [{"point": o.point, "evidence_count": o.evidence_count} for o in llm_analysis.opportunities];
        threats_list = [{"point": t.point, "evidence_count": t.evidence_count} for t in llm_analysis.threats];
        critical_issues_list = [{"issue": c.issue, "severity": c.severity, "mention_count": c.mention_count, "suggested_action": c.suggested_action} for c in llm_analysis.critical_issues];

        # Create Analysis node
        self.analysis = here ++> Analysis(
            analysis_id=str(uuid4()),
            created_at=datetime.now().isoformat(),
            reviews_analyzed=len(reviews),
            date_range_start=trends.get("date_range_start", ""),
            date_range_end=trends.get("date_range_end", ""),

            # Health Score
            health_score=llm_analysis.health_score,
            health_grade=llm_analysis.health_grade,
            health_breakdown=health_breakdown_dict,
            
            # Confidence
            confidence_level=get_confidence_level(len(reviews)),
            confidence_details={
                "sample_size": len(reviews),
                "adequacy": "sufficient" if len(reviews) >= 50 else ("limited" if len(reviews) >= 20 else "minimal")
            },
            
            # Sentiment
            overall_sentiment=llm_analysis.overall_sentiment,
            sentiment_score=stats["avg_sentiment"],
            positive_count=stats["positive_count"],
            negative_count=stats["negative_count"],
            neutral_count=stats["neutral_count"],
            mixed_count=stats["mixed_count"],
            positive_percentage=stats["positive_pct"],
            negative_percentage=stats["negative_pct"],
            neutral_percentage=stats["neutral_pct"],
            
            # Rating distribution
            rating_distribution=stats["rating_distribution"],
            
            # SWOT
            strengths=strengths_list,
            weaknesses=weaknesses_list,
            opportunities=opportunities_list,
            threats=threats_list,

            # Issues
            critical_issues=critical_issues_list,
            pain_points=llm_analysis.pain_points,
            delighters=llm_analysis.delighters,
            
            # Trends
            trend_direction=llm_analysis.trend_direction,
            trend_change=trends.get("change", ""),
            monthly_breakdown=trends.get("monthly_breakdown", []),
            theme_trends=trends.get("theme_trends", []),
            seasonal_patterns=[],
            
            # Statistics
            avg_review_length=stats["avg_review_length"],
            reviews_with_photos=stats["reviews_with_photos"],
            reviews_with_owner_response=stats["reviews_with_response"],
            response_rate=stats["response_rate"],
            languages=stats.get("languages", {})
        );
        
        # Create Theme nodes
        for theme_data in themes_data {
            if theme_data["mention_count"] >= CONFIDENCE_THRESHOLDS["sub_theme_min_mentions"] {
                here ++> Theme(
                    name=theme_data["name"],
                    category=theme_data.get("category", ""),
                    mention_count=theme_data["mention_count"],
                    positive_count=theme_data["positive_count"],
                    negative_count=theme_data["negative_count"],
                    neutral_count=theme_data["neutral_count"],
                    mixed_count=theme_data.get("mixed_count", 0),
                    avg_sentiment=theme_data["avg_sentiment"],
                    sub_themes=theme_data.get("sub_themes", []),
                    sample_quotes_positive=theme_data.get("positive_quotes", [])[:5],
                    sample_quotes_negative=theme_data.get("negative_quotes", [])[:5]
                );
                self.themes_created += 1;
            }
        }
        
        self.status = "completed";
        print(f"   ✅ Pattern analysis complete");
        print(f"      Health Score: {llm_analysis.health_score} ({llm_analysis.health_grade})");
        print(f"      Created {self.themes_created} theme nodes");
    }
    
    def calculate_statistics(reviews: list) -> dict {
        total = len(reviews);
        if total == 0 {
            return {};
        }
        
        positive_count = 0;
        negative_count = 0;
        neutral_count = 0;
        mixed_count = 0;
        total_sentiment = 0.0;
        total_length = 0;
        with_photos = 0;
        with_response = 0;
        rating_dist = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        
        for r in reviews {
            # Sentiment counts
            if r.sentiment == "positive" { positive_count += 1; }
            elif r.sentiment == "negative" { negative_count += 1; }
            elif r.sentiment == "neutral" { neutral_count += 1; }
            elif r.sentiment == "mixed" { mixed_count += 1; }
            
            total_sentiment += r.sentiment_score;
            total_length += len(r.text.split());
            
            if r.photos { with_photos += 1; }
            if r.owner_response { with_response += 1; }
            
            if r.rating in rating_dist {
                rating_dist[r.rating] += 1;
            }
        }
        
        return {
            "positive_count": positive_count,
            "negative_count": negative_count,
            "neutral_count": neutral_count,
            "mixed_count": mixed_count,
            "positive_pct": round(positive_count / total * 100, 1),
            "negative_pct": round(negative_count / total * 100, 1),
            "neutral_pct": round(neutral_count / total * 100, 1),
            "avg_sentiment": round(total_sentiment / total, 3) if total > 0 else 0,
            "avg_review_length": round(total_length / total) if total > 0 else 0,
            "reviews_with_photos": with_photos,
            "reviews_with_response": with_response,
            "response_rate": round(with_response / total * 100, 1) if total > 0 else 0,
            "rating_distribution": rating_dist
        };
    }
    
    def build_theme_analysis(reviews: list, business_type: str) -> list {
        theme_defs = THEME_DEFINITIONS.get(business_type, THEME_DEFINITIONS["GENERIC"]);
        theme_data = {};
        
        for r in reviews {
            for theme in r.themes {
                if theme not in theme_data {
                    theme_data[theme] = {
                        "name": theme,
                        "mention_count": 0,
                        "positive_count": 0,
                        "negative_count": 0,
                        "neutral_count": 0,
                        "mixed_count": 0,
                        "total_sentiment": 0.0,
                        "sub_themes_raw": {},
                        "positive_quotes": [],
                        "negative_quotes": []
                    };
                }
                
                theme_data[theme]["mention_count"] += 1;
                theme_data[theme]["total_sentiment"] += r.sentiment_score;
                
                if r.sentiment == "positive" {
                    theme_data[theme]["positive_count"] += 1;
                    if len(theme_data[theme]["positive_quotes"]) < 5 {
                        theme_data[theme]["positive_quotes"].append(r.text[:150]);
                    }
                } elif r.sentiment == "negative" {
                    theme_data[theme]["negative_count"] += 1;
                    if len(theme_data[theme]["negative_quotes"]) < 5 {
                        theme_data[theme]["negative_quotes"].append(r.text[:150]);
                    }
                } elif r.sentiment == "neutral" {
                    theme_data[theme]["neutral_count"] += 1;
                } else {
                    theme_data[theme]["mixed_count"] += 1;
                }
                
                # Track sub-themes (r.sub_themes is dict[str, list[str]])
                if theme in r.sub_themes {
                    for sub in r.sub_themes[theme] {
                        if sub not in theme_data[theme]["sub_themes_raw"] {
                            theme_data[theme]["sub_themes_raw"][sub] = {
                                "mentions": 0,
                                "total_sentiment": 0.0,
                                "positive": 0,
                                "negative": 0
                            };
                        }
                        theme_data[theme]["sub_themes_raw"][sub]["mentions"] += 1;
                        theme_data[theme]["sub_themes_raw"][sub]["total_sentiment"] += r.sentiment_score;
                        if r.sentiment == "positive" {
                            theme_data[theme]["sub_themes_raw"][sub]["positive"] += 1;
                        } elif r.sentiment == "negative" {
                            theme_data[theme]["sub_themes_raw"][sub]["negative"] += 1;
                        }
                    }
                }
            }
        }
        
        # Finalize theme data
        result = [];
        for (name, data) in theme_data.items() {
            if data["mention_count"] > 0 {
                avg_sent = data["total_sentiment"] / data["mention_count"];
                
                # Build sub-themes list
                sub_themes = [];
                for (sub_name, sub_data) in data["sub_themes_raw"].items() {
                    if sub_data["mentions"] >= CONFIDENCE_THRESHOLDS["sub_theme_min_mentions"] {
                        sub_avg = sub_data["total_sentiment"] / sub_data["mentions"];
                        verdict = "excellent" if sub_avg > 0.7 else ("good" if sub_avg > 0.3 else ("needs_attention" if sub_avg > -0.3 else "poor"));
                        sub_themes.append({
                            "name": sub_name,
                            "mentions": sub_data["mentions"],
                            "sentiment": round(sub_avg, 2),
                            "positive_pct": round(sub_data["positive"] / sub_data["mentions"] * 100) if sub_data["mentions"] > 0 else 0,
                            "verdict": verdict
                        });
                    }
                }

                # Sort sub-themes by mentions
                sub_themes = sorted(sub_themes, key=lambda x: dict: x["mentions"], reverse=True);
                
                result.append({
                    "name": name,
                    "mention_count": data["mention_count"],
                    "mention_percentage": round(data["mention_count"] / len(reviews) * 100, 1),
                    "positive_count": data["positive_count"],
                    "negative_count": data["negative_count"],
                    "neutral_count": data["neutral_count"],
                    "mixed_count": data["mixed_count"],
                    "avg_sentiment": round(avg_sent, 2),
                    "sub_themes": sub_themes,
                    "positive_quotes": data["positive_quotes"],
                    "negative_quotes": data["negative_quotes"]
                });
            }
        }
        
        # Sort by mention count
        result = sorted(result, key=lambda x: dict: x["mention_count"], reverse=True);
        return result;
    }
    
    def calculate_trends(reviews: list) -> dict {
        # Group reviews by month
        monthly = {};
        
        for r in reviews {
            month = parse_review_date(r.date, r.relative_date);
            if month {
                if month not in monthly {
                    monthly[month] = {"count": 0, "total_sentiment": 0.0, "ratings": []};
                }
                monthly[month]["count"] += 1;
                monthly[month]["total_sentiment"] += r.sentiment_score;
                monthly[month]["ratings"].append(r.rating);
            }
        }
        
        # Build monthly breakdown
        months_sorted = sorted(monthly.keys());
        breakdown = [];
        
        for month in months_sorted {
            data = monthly[month];
            avg_sent = data["total_sentiment"] / data["count"] if data["count"] > 0 else 0;
            avg_rating = sum(data["ratings"]) / len(data["ratings"]) if data["ratings"] else 0;
            breakdown.append({
                "month": month,
                "review_count": data["count"],
                "sentiment": round(avg_sent, 2),
                "avg_rating": round(avg_rating, 1)
            });
        }
        
        # Calculate trend direction
        trend_direction = "stable";
        change = "0%";
        
        if len(breakdown) >= CONFIDENCE_THRESHOLDS["trend_min_months"] {
            first_half = breakdown[:len(breakdown)//2];
            second_half = breakdown[len(breakdown)//2:];
            
            first_avg = sum(m["sentiment"] for m in first_half) / len(first_half) if first_half else 0;
            second_avg = sum(m["sentiment"] for m in second_half) / len(second_half) if second_half else 0;
            
            diff = second_avg - first_avg;
            if diff > 0.1 {
                trend_direction = "improving";
                change = f"+{round(diff * 100)}%";
            } elif diff < -0.1 {
                trend_direction = "declining";
                change = f"{round(diff * 100)}%";
            } else {
                change = f"{round(diff * 100)}%";
            }
        }
        
        return {
            "monthly_breakdown": breakdown,
            "trend_direction": trend_direction,
            "change": change,
            "date_range_start": months_sorted[0] if months_sorted else "",
            "date_range_end": months_sorted[-1] if months_sorted else "",
            "theme_trends": []  # Could be expanded
        };
    }
    
    """Generate comprehensive pattern analysis from review data.

    Analyzes aggregated review statistics, themes, and trends to produce a health
    score (0-100), letter grade, theme-by-theme breakdown, SWOT analysis, and
    critical issues identification. This is an interpretive task that requires
    balanced reasoning between data and insights.

    Args:
        business_name: Name of the business being analyzed
        business_type: Business category (RESTAURANT, HOTEL, etc.)
        review_count: Total number of reviews analyzed
        stats: Sentiment statistics (positive/negative/neutral percentages)
        themes: List of detected themes with scores and sentiment breakdowns
        trends: Trend analysis data (direction, monthly breakdown)

    Returns:
        PatternAnalysisResult with health metrics, SWOT, critical issues, and recommendations
    """
    def generate_pattern_analysis(
        business_name: str,
        business_type: str,
        review_count: int,
        stats: dict,
        themes: list,
        trends: dict
    ) -> PatternAnalysisResult by llm(
        temperature=0.5,  # Balanced - interpretive but grounded in data
        incl_info={
            "business_name": business_name,
            "business_type": business_type,
            "review_count": review_count,
            "sentiment_stats": stats,
            "theme_analysis": themes,
            "trend_data": trends,
            "instructions": "Generate health score (0-100), grade, and breakdown by theme. Identify SWOT, critical issues with severity. Be specific and actionable."
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 4: REPORT GENERATOR
# ═══════════════════════════════════════════════════════════════════════════════

walker ReportGeneratorAgent {
    has business_id: str = "";
    has report_type: str = "deep";
    
    # Results
    has report: Report = None;
    has status: str = "pending";
    
    can start with `root entry {
        print("\n📝 ReportGeneratorAgent starting...");
        visit [-->(`?Business)];
    }
    
    can generate with Business entry {
        if self.business_id and here.place_id != self.business_id {
            visit [-->];
            return;
        }
        
        print(f"   Generating report for: {here.name}");
        
        # Get analysis
        analyses = [here -->(`?Analysis)];
        if not analyses {
            print("   ❌ No analysis found");
            self.status = "failed";
            disengage;
        }
        
        analysis = analyses[0];
        themes = [here -->(`?Theme)];
        
        # Generate report content
        content = self.generate_report_content(
            business_name=here.name,
            business_type=here.business_type_normalized,
            rating=here.rating,
            total_reviews=here.total_reviews,
            reviews_analyzed=analysis.reviews_analyzed,
            health_score=analysis.health_score,
            health_grade=analysis.health_grade,
            confidence_level=analysis.confidence_level,
            sentiment_score=analysis.sentiment_score,
            positive_pct=analysis.positive_percentage,
            negative_pct=analysis.negative_percentage,
            strengths=analysis.strengths,
            weaknesses=analysis.weaknesses,
            opportunities=analysis.opportunities,
            critical_issues=analysis.critical_issues,
            themes=[{"name": t.name, "sentiment": t.avg_sentiment, "mentions": t.mention_count, "sub_themes": t.sub_themes} for t in themes],
            trend_direction=analysis.trend_direction,
            monthly_data=analysis.monthly_breakdown
        );
        
        # Convert RecommendationItem objects to dicts
        immediate_list = [{"action": r.action, "reason": r.reason, "expected_impact": r.expected_impact, "effort": r.effort, "priority_score": r.priority_score} for r in content.recommendations_immediate];
        short_term_list = [{"action": r.action, "reason": r.reason, "expected_impact": r.expected_impact, "effort": r.effort, "priority_score": r.priority_score} for r in content.recommendations_short_term];
        long_term_list = [{"action": r.action, "reason": r.reason, "expected_impact": r.expected_impact, "effort": r.effort, "priority_score": r.priority_score} for r in content.recommendations_long_term];

        # Create Report node
        self.report = here ++> Report(
            report_id=str(uuid4()),
            report_type=self.report_type,
            created_at=datetime.now().isoformat(),
            headline=content.headline,
            one_liner=content.one_liner,
            key_metric=content.key_metric,
            executive_summary=content.executive_summary,
            key_findings=content.key_findings,
            recommendations_immediate=immediate_list,
            recommendations_short_term=short_term_list,
            recommendations_long_term=long_term_list
        );
        
        self.status = "completed";
        print(f"   ✅ Report generated: {content.headline}");
    }
    
    """Generate executive-level business report from analysis data.

    Creates a comprehensive business intelligence report with headline, executive summary,
    key findings, and actionable recommendations. This is a creative task that requires
    synthesizing data into clear, compelling narratives for business decision-makers.

    The report should scale to the review count - more reviews warrant more detailed
    findings and recommendations. All recommendations must be specific, measurable,
    and prioritized by expected business impact.

    Args:
        business_name: Name of the business
        business_type: Business category
        rating: Google Maps rating
        total_reviews: Total reviews on Google
        reviews_analyzed: Number of reviews we analyzed
        health_score: Overall health score (0-100)
        health_grade: Letter grade (A+, A, B+, etc.)
        confidence_level: Analysis confidence (high/medium/low)
        sentiment_score: Average sentiment (-1.0 to 1.0)
        positive_pct: Percentage of positive reviews
        negative_pct: Percentage of negative reviews
        strengths: SWOT strengths
        weaknesses: SWOT weaknesses
        opportunities: SWOT opportunities
        critical_issues: Urgent issues requiring attention
        themes: Theme analysis with scores
        trend_direction: Trend (improving/stable/declining)
        monthly_data: Monthly sentiment breakdown

    Returns:
        ReportGenerationResult with headline, summary, findings, and tiered recommendations
    """
    def generate_report_content(
        business_name: str,
        business_type: str,
        rating: float,
        total_reviews: int,
        reviews_analyzed: int,
        health_score: int,
        health_grade: str,
        confidence_level: str,
        sentiment_score: float,
        positive_pct: float,
        negative_pct: float,
        strengths: list,
        weaknesses: list,
        opportunities: list,
        critical_issues: list,
        themes: list,
        trend_direction: str,
        monthly_data: list
    ) -> ReportGenerationResult by llm(
        temperature=0.7,  # Creative - requires narrative synthesis and compelling communication
        incl_info={
            "business_name": business_name,
            "business_type": business_type,
            "google_rating": rating,
            "total_reviews": total_reviews,
            "reviews_analyzed": reviews_analyzed,
            "health_score": health_score,
            "health_grade": health_grade,
            "confidence": confidence_level,
            "sentiment_score": sentiment_score,
            "positive_percentage": positive_pct,
            "negative_percentage": negative_pct,
            "strengths": strengths,
            "weaknesses": weaknesses,
            "opportunities": opportunities,
            "critical_issues": critical_issues,
            "themes": themes,
            "trend": trend_direction,
            "monthly_breakdown": monthly_data,
            "instructions": "Create actionable business report. Scale findings/recommendations to review count (more reviews = more findings). Prioritize by impact. Be specific with numbers."
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# AGENT 5: BRAND-AWARE RECOMMENDATION AGENT
# ═══════════════════════════════════════════════════════════════════════════════

walker RecommendationAgent {
    has business_id: str = "";

    # Results
    has recommendations: BrandAwareRecommendationResult = None;
    has status: str = "pending";

    can start with `root entry {
        print("\n💡 RecommendationAgent starting...");
        visit [-->(`?Business)];
    }

    can generate with Business entry {
        if self.business_id and here.place_id != self.business_id {
            visit [-->];
            return;
        }

        print(f"   Generating brand-aware recommendations for: {here.name}");

        # Get analysis and themes
        analyses = [here -->(`?Analysis)];
        if not analyses {
            print("   ❌ No analysis found");
            self.status = "failed";
            disengage;
        }

        analysis = analyses[0];
        themes = [here -->(`?Theme)];
        reviews = [here -->(`?Review)];

        # Calculate severity metrics
        severity_data = self.calculate_severity_metrics(analysis, themes, len(reviews));

        # Detect brand positioning
        brand_positioning = self.detect_brand_positioning(here, analysis, themes);

        print(f"   Brand positioning: {brand_positioning['price_positioning']}");
        print(f"   Protected strengths: {brand_positioning['protected_strengths']}");

        # Generate brand-aware recommendations
        self.recommendations = self.generate_brand_aware_recommendations(
            business_name=here.name,
            business_type=here.business_type_normalized,
            price_level=here.price_level,
            rating=here.rating,
            total_reviews=here.total_reviews,
            reviews_analyzed=analysis.reviews_analyzed,
            health_score=analysis.health_score,
            health_grade=analysis.health_grade,
            brand_positioning=brand_positioning,
            severity_data=severity_data,
            strengths=analysis.strengths,
            weaknesses=analysis.weaknesses,
            opportunities=analysis.opportunities,
            critical_issues=analysis.critical_issues,
            themes=[{
                "name": t.name,
                "sentiment": t.avg_sentiment,
                "mentions": t.mention_count,
                "mention_pct": round(t.mention_count / analysis.reviews_analyzed * 100, 1) if analysis.reviews_analyzed > 0 else 0,
                "sub_themes": t.sub_themes
            } for t in themes],
            trend_direction=analysis.trend_direction
        );

        self.status = "completed";
        print(f"   ✅ Generated {len(self.recommendations.recommendations_immediate)} immediate, "
              f"{len(self.recommendations.recommendations_short_term)} short-term, "
              f"{len(self.recommendations.recommendations_long_term)} long-term recommendations");
        print(f"   🛡️ Generated {len(self.recommendations.do_not_recommendations)} protective recommendations");
    }

    def calculate_severity_metrics(analysis: Analysis, themes: list, total_reviews: int) -> dict {
        # """Calculate severity levels for each issue based on mention percentage."""
        severity_data = {
            "issues": [],
            "overall_severity": "low"
        };

        # Analyze each weakness/critical issue
        for issue in analysis.critical_issues {
            mention_count = issue.get("mention_count", 0);
            mention_pct = (mention_count / total_reviews * 100) if total_reviews > 0 else 0;

            if mention_pct < 5 {
                severity = "low";
            } elif mention_pct < 15 {
                severity = "moderate";
            } else {
                severity = "high";
            }

            severity_data["issues"].append({
                "issue": issue.get("issue", ""),
                "mention_count": mention_count,
                "mention_pct": round(mention_pct, 1),
                "severity": severity
            });
        }

        # Analyze theme-level issues (negative sentiment themes)
        for t in themes {
            if t.avg_sentiment < -0.2 {
                mention_pct = (t.mention_count / total_reviews * 100) if total_reviews > 0 else 0;
                if mention_pct < 5 {
                    severity = "low";
                } elif mention_pct < 15 {
                    severity = "moderate";
                } else {
                    severity = "high";
                }

                severity_data["issues"].append({
                    "issue": f"Negative sentiment on {t.name}",
                    "mention_count": t.mention_count,
                    "mention_pct": round(mention_pct, 1),
                    "severity": severity
                });
            }
        }

        # Calculate overall severity
        high_count = sum(1 for i in severity_data["issues"] if i["severity"] == "high");
        moderate_count = sum(1 for i in severity_data["issues"] if i["severity"] == "moderate");

        if high_count > 0 {
            severity_data["overall_severity"] = "high";
        } elif moderate_count > 0 {
            severity_data["overall_severity"] = "moderate";
        } else {
            severity_data["overall_severity"] = "low";
        }

        return severity_data;
    }

    def detect_brand_positioning(business: Business, analysis: Analysis, themes: list) -> dict {
        # """Detect brand positioning from price level and theme performance."""

        # Detect price positioning from price_level
        price_level = business.price_level.lower() if business.price_level else "";

        if "10,000" in price_level or "$$$$" in price_level or "expensive" in price_level {
            price_positioning = "premium";
        } elif "$$$" in price_level or "5,000" in price_level {
            price_positioning = "mid-range";
        } else {
            price_positioning = "standard";
        }

        # High rating + high health score = premium brand
        if analysis.health_score >= 80 and business.rating >= 4.5 {
            brand_positioning = "premium";
        } elif analysis.health_score >= 70 and business.rating >= 4.0 {
            brand_positioning = "quality";
        } else {
            brand_positioning = "standard";
        }

        # Identify protected strengths (themes with >0.7 sentiment and >10 mentions)
        protected_strengths = [];
        for t in themes {
            if t.avg_sentiment > 0.7 and t.mention_count >= 10 {
                protected_strengths.append(t.name);
            }
        }

        # Identify brand risks based on positioning
        brand_risks = [];
        if price_positioning == "premium" {
            brand_risks = [
                "Discounting core offerings",
                "Reducing quality to cut costs",
                "Mass-market promotions that dilute exclusivity"
            ];
        }

        return {
            "price_positioning": price_positioning,
            "brand_positioning": brand_positioning,
            "protected_strengths": protected_strengths,
            "brand_risks": brand_risks
        };
    }

    """Generate brand-aware strategic recommendations with protective guardrails.

    Creates actionable recommendations that respect brand positioning, price level, and
    business strengths. Uses severity calibration to ensure recommendations are proportional
    to evidence. Includes protective "do-not" recommendations to guard against brand dilution.

    This is a strategic task requiring balanced creativity (finding solutions) with analytical
    rigor (matching actions to evidence severity).

    Key principles:
    - Scale action intensity to problem severity (monitor/communicate/experiment/change)
    - Protect high-performing areas from misguided changes
    - Prioritize perception fixes over operational changes for low-severity issues
    - Every recommendation must link to specific evidence with mention counts

    Args:
        business_name: Name of the business
        business_type: Business category
        price_level: Price positioning ($$, $$$, $$$$)
        rating: Google Maps rating
        total_reviews: Total reviews on Google
        reviews_analyzed: Number of reviews analyzed
        health_score: Overall health score (0-100)
        health_grade: Letter grade
        brand_positioning: Dict with price_positioning, brand_positioning, protected_strengths, brand_risks
        severity_data: Issue severity calibration with mention percentages
        strengths: SWOT strengths
        weaknesses: SWOT weaknesses
        opportunities: SWOT opportunities
        critical_issues: Urgent issues requiring attention
        themes: Theme analysis with scores and sentiment
        trend_direction: Trend (improving/stable/declining)

    Returns:
        BrandAwareRecommendationResult with immediate/short/long-term recommendations and protective do-not list
    """
    def generate_brand_aware_recommendations(
        business_name: str,
        business_type: str,
        price_level: str,
        rating: float,
        total_reviews: int,
        reviews_analyzed: int,
        health_score: int,
        health_grade: str,
        brand_positioning: dict,
        severity_data: dict,
        strengths: list,
        weaknesses: list,
        opportunities: list,
        critical_issues: list,
        themes: list,
        trend_direction: str
    ) -> BrandAwareRecommendationResult by llm(
        temperature=0.6,  # Strategic - balanced between creative problem-solving and analytical precision
        incl_info={
            # Business Context
            "business_name": business_name,
            "business_type": business_type,
            "price_level": price_level,
            "google_rating": rating,
            "total_reviews": total_reviews,
            "reviews_analyzed": reviews_analyzed,
            "health_score": health_score,
            "health_grade": health_grade,
            "trend": trend_direction,

            # Brand Context (CRITICAL)
            "brand_context": brand_positioning,

            # Severity Data (CRITICAL)
            "severity_analysis": severity_data,

            # Strategic Analysis
            "strengths": strengths,
            "weaknesses": weaknesses,
            "opportunities": opportunities,
            "critical_issues": critical_issues,
            "themes": themes,

            # COMPREHENSIVE INSTRUCTIONS
            "instructions": """
You are a senior business consultant generating BRAND-AWARE recommendations.

## BRAND GUARDRAILS
- Price positioning: Use brand_context.price_positioning
- Brand positioning: Use brand_context.brand_positioning
- Protected strengths: DO NOT compromise areas in brand_context.protected_strengths
- Brand risks: AVOID actions in brand_context.brand_risks

CRITICAL RULES:
1. Do NOT recommend discounting core offerings unless evidence is overwhelming (>15% negative mentions)
2. Do NOT suggest actions that dilute brand positioning
3. Prefer perception/communication fixes over price cuts
4. Scale recommendation strength to problem severity

## SEVERITY CALIBRATION
Check severity_analysis for each issue:
- LOW severity (<5% mentions): ONLY use action_type="monitor" or action_type="communicate"
- MODERATE severity (5-15% mentions): Can use action_type="experiment"
- HIGH severity (>15% mentions): Can use action_type="change"

CRITICAL: Do NOT recommend major operational or pricing changes for LOW severity issues.

## EVIDENCE REQUIREMENT
Every recommendation MUST include evidence with:
- Exact issue it addresses (from critical_issues or themes)
- Mention count AND percentage (calculate from data provided)
- Customer segment affected (infer from feedback patterns: tourists, regulars, first-timers, families)
- Sample feedback (paraphrase from themes.sample_quotes)

If a recommendation cannot be linked to evidence, DO NOT include it.

## BRAND-SAFE PREFERENCE
When addressing value or pricing concerns:
1. FIRST: Consider perception fixes (menu explanation, staff scripts, expectation setting)
2. SECOND: Consider limited experiments (bundles, tasting menus, special occasions)
3. LAST: Consider price changes (only if evidence is overwhelming >15%)

## PROTECTIVE RECOMMENDATIONS (MANDATORY)
You MUST generate 2-4 do_not_recommendations that:
- Protect areas with high positive sentiment (>0.7 avg_sentiment)
- Warn against actions that could damage brand
- Are based on evidence from positive reviews

## OUTPUT REQUIREMENTS
- Generate 2-3 recommendations_immediate (this week)
- Generate 2-4 recommendations_short_term (this month)
- Generate 1-3 recommendations_long_term (this quarter)
- Generate 2-4 do_not_recommendations (protective)

For each recommendation:
- action: Specific verb-driven action
- action_type: Must match severity ("monitor"/"communicate" for low, "experiment" for moderate, "change" for high)
- evidence: Must link to actual data with mention counts
- expected_impact: Quantified where possible
- downside_risk: What could go wrong
- risk_level: "low", "medium", or "high"
- confidence_level: Based on data strength
- caution_note: Required for medium/high risk actions, empty string for low risk

issue_severity_summary: Summarize overall problem scale (e.g., "Most issues are LOW severity (<5% of reviews). No major operational changes required.")
overall_risk_assessment: Summarize risk profile of all recommendations
"""
        }
    );
}

# ═══════════════════════════════════════════════════════════════════════════════
# ORCHESTRATOR: FULL PIPELINE
# ═══════════════════════════════════════════════════════════════════════════════

walker FullPipelineAgent {
    has url: str;
    has max_reviews: int = 100;
    has report_type: str = "deep";

    # Results
    has business_id: str = "";
    has status: str = "pending";
    has stages_completed: list = [];
    has data_source: str = "";
    has output: dict = {};
    has error: str = "";
    
    can start with `root entry {
        print("\n" + "═" * 65);
        print("   REVIEW ANALYZER V2 - DEEP ANALYSIS PIPELINE");
        print("═" * 65);
        print(f"   URL: {self.url[:60]}...");
        print(f"   Max Reviews: {self.max_reviews}");
        print("═" * 65);
        
        # Stage 1: Fetch
        print("\n📥 STAGE 1: Fetching Data");
        print("─" * 65);
        
        fetcher = here spawn DataFetcherAgent(
            url=self.url,
            max_reviews=self.max_reviews
        );
        
        if fetcher.status == "failed" {
            self.error = fetcher.error;
            self.status = "failed";
            disengage;
        }
        
        self.business_id = fetcher.business[0].place_id;
        self.data_source = fetcher.data_source;
        self.stages_completed.append("fetch");
        
        # Stage 2: Sentiment Analysis
        print("\n🔍 STAGE 2: Sentiment Analysis (Batch Processing)");
        print("─" * 65);
        
        analyzer = here spawn SentimentAnalyzerAgent(
            business_id=self.business_id
        );
        self.stages_completed.append("sentiment");
        
        # Stage 3: Pattern Analysis
        print("\n🎯 STAGE 3: Pattern Analysis");
        print("─" * 65);
        
        patterns = here spawn PatternAnalyzerAgent(
            business_id=self.business_id
        );
        self.stages_completed.append("patterns");
        
        # Stage 4: Report Generation
        print("\n📝 STAGE 4: Report Generation");
        print("─" * 65);
        
        reporter = here spawn ReportGeneratorAgent(
            business_id=self.business_id,
            report_type=self.report_type
        );
        self.stages_completed.append("report");

        # Stage 5: Brand-Aware Recommendations
        print("\n💡 STAGE 5: Brand-Aware Recommendations");
        print("─" * 65);

        recommender = here spawn RecommendationAgent(
            business_id=self.business_id
        );
        self.stages_completed.append("recommendations");

        # Store brand-aware recommendations in Report node (to avoid re-generating)
        brand_recs = recommender.recommendations;
        report_node = reporter.report[0];

        # Convert and store brand-aware recommendations
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

        print(f"   💾 Stored brand-aware recommendations in Report node");

        # Build output
        self.output = self.build_output(
            fetcher.business[0],
            patterns.analysis[0],
            [fetcher.business[0] -->(`?Theme)],
            report_node,
            brand_recs
        );

        self.status = "completed";

        print("\n" + "═" * 65);
        print("   ✅ PIPELINE COMPLETE");
        print("═" * 65);
        print(f"   Business: {fetcher.business[0].name}");
        print(f"   Reviews: {fetcher.reviews_fetched}");
        print(f"   Health: {patterns.analysis[0].health_score} ({patterns.analysis[0].health_grade})");
        print(f"   Data Source: {self.data_source.upper()}");
        print("═" * 65 + "\n");
    }

    def rec_to_dict(r: BrandAwareRecommendation) -> dict {
        # """Convert BrandAwareRecommendation to dict for storage/output."""
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
        # """Convert ProtectiveRecommendation to dict for storage/output."""
        return {
            "area": p.area,
            "do_not_action": p.do_not_action,
            "rationale": p.rationale,
            "evidence_count": p.evidence_count
        };
    }

    def build_output(business: Business, analysis: Analysis, themes: list, report: Report, brand_recs: BrandAwareRecommendationResult) -> dict {
        return {
            "success": True,
            "data_source": self.data_source,
            "generated_at": datetime.now().isoformat(),

            "business": {
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

            # Brand-Aware Recommendations (NEW)
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

            # Legacy recommendations (for backward compatibility)
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
# REANALYZE PIPELINE - Runs Stages 2-5 on Existing Data (Cache Mode)
# ═══════════════════════════════════════════════════════════════════════════════

walker ReanalyzePipeline {
    has business_id: str;
    has report_type: str = "deep";

    # Results
    has status: str = "pending";
    has stages_completed: list = [];
    has data_source: str = "cache";
    has output: dict = {};
    has error: str = "";

    can start with `root entry {
        print("\n" + "═" * 65);
        print("   🔄 REANALYZE PIPELINE (Using Cached Data)");
        print("═" * 65);
        print(f"   Business ID: {self.business_id}");
        print("═" * 65);

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
            self.error = f"Business not found: {self.business_id}";
            self.status = "failed";
            print(f"   ❌ {self.error}");
            disengage;
        }

        reviews = [target_biz -->(`?Review)];
        print(f"   📦 Using {len(reviews)} cached reviews for: {target_biz.name}");

        # Stage 2: Sentiment Analysis
        print("\n🔍 STAGE 2: Sentiment Analysis (Batch Processing)");
        print("─" * 65);
        analyzer = here spawn SentimentAnalyzerAgent(business_id=self.business_id);
        self.stages_completed.append("sentiment");

        # Stage 3: Pattern Analysis
        print("\n🎯 STAGE 3: Pattern Analysis");
        print("─" * 65);
        patterns = here spawn PatternAnalyzerAgent(business_id=self.business_id);
        self.stages_completed.append("patterns");

        # Stage 4: Report Generation
        print("\n📝 STAGE 4: Report Generation");
        print("─" * 65);
        reporter = here spawn ReportGeneratorAgent(
            business_id=self.business_id,
            report_type=self.report_type
        );
        self.stages_completed.append("report");

        # Stage 5: Brand-Aware Recommendations
        print("\n💡 STAGE 5: Brand-Aware Recommendations");
        print("─" * 65);
        recommender = here spawn RecommendationAgent(business_id=self.business_id);
        self.stages_completed.append("recommendations");

        # Store brand-aware recommendations in Report node (to avoid re-generating)
        brand_recs = recommender.recommendations;
        report_node = reporter.report[0];

        # Convert and store brand-aware recommendations
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

        print(f"   💾 Stored brand-aware recommendations in Report node");

        # Update timestamp
        target_biz.last_analyzed_at = datetime.now().isoformat();

        # Build output
        self.output = self.build_output(
            target_biz,
            patterns.analysis[0],
            [target_biz -->(`?Theme)],
            report_node,
            brand_recs
        );

        self.status = "completed";

        print("\n" + "═" * 65);
        print("   ✅ REANALYZE PIPELINE COMPLETE (from cache)");
        print("═" * 65);
        print(f"   Business: {target_biz.name}");
        print(f"   Reviews: {len(reviews)}");
        print(f"   Health: {patterns.analysis[0].health_score} ({patterns.analysis[0].health_grade})");
        print(f"   Data Source: CACHE");
        print("═" * 65 + "\n");
    }

    def rec_to_dict(r: BrandAwareRecommendation) -> dict {
        # """Convert BrandAwareRecommendation to dict for storage/output."""
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
        # """Convert ProtectiveRecommendation to dict for storage/output."""
        return {
            "area": p.area,
            "do_not_action": p.do_not_action,
            "rationale": p.rationale,
            "evidence_count": p.evidence_count
        };
    }

    def build_output(business: Business, analysis: Analysis, themes: list, report: Report, brand_recs: BrandAwareRecommendationResult) -> dict {
        return {
            "success": True,
            "data_source": "cache",
            "from_cache": True,
            "generated_at": datetime.now().isoformat(),

            "business": {
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

            # Brand-Aware Recommendations
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

            # Legacy recommendations (for backward compatibility)
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
