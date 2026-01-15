# Data Fetching Process

## 📡 Overview

The **DataFetcherAgent** is responsible for:

1. Parsing Google Maps URLs
2. Fetching business place details
3. Fetching customer reviews
4. Creating Business and Review nodes in the graph

---

## 🔗 URL Parsing

### Supported URL Formats

The system supports various Google Maps URL formats:

```
Format 1: With data_id
https://www.google.com/maps/place/NAME/@LAT,LNG/data=!3m1!4b1!4m6!3m5!1s0x...:0x...

Format 2: With place_id
https://www.google.com/maps/place/?q=place_id:ChIJ...

Format 3: Shortened
https://goo.gl/maps/...

Format 4: With CID
https://www.google.com/maps?cid=1234567890
```

### Extraction Logic

```python
def parse_google_maps_url(url: str) -> dict:
    result = {
        "is_valid": False,
        "place_id": "",
        "data_id": "",      # Most important - used for SERP API
        "cid": "",
        "place_name": "",
        "error": ""
    }

    # 1. Validate it's a Google Maps URL
    valid_hosts = ["google.com", "maps.google.com", "goo.gl"]
    if not any(host in url.lower() for host in valid_hosts):
        result["error"] = "Not a Google Maps URL"
        return result

    # 2. Extract data_id (format: 0x...:0x...)
    data_id_match = re.search(r'!1s(0x[a-f0-9]+:0x[a-f0-9]+)', url, re.IGNORECASE)
    if data_id_match:
        result["data_id"] = data_id_match.group(1)
        result["is_valid"] = True

    # 3. Extract place_id
    place_id_match = re.search(r'place_id[=:]([^&\s]+)', url, re.IGNORECASE)
    if place_id_match:
        result["place_id"] = place_id_match.group(1)
        result["is_valid"] = True

    # 4. Extract CID
    cid_match = re.search(r'cid=(\d+)', url)
    if cid_match:
        result["cid"] = cid_match.group(1)
        result["is_valid"] = True

    # 5. Extract place name from URL
    name_match = re.search(r'/maps/place/([^/@]+)', url)
    if name_match:
        result["place_name"] = name_match.group(1).replace('+', ' ')

    return result
```

### Example

**Input URL**:

```
https://www.google.com/maps/place/Weligama+Bay+Marriott+Resort+%26+Spa/@5.9730503,80.4394055/data=!3m2!1e3!4b1!4m9!3m8!1s0x3ae11545eda17fd9:0xe4d7ca849dbecbbe!5m2!4m1!1i2!8m2!3d5.9730503!4d80.4394055
```

**Extracted**:

```json
{
  "is_valid": true,
  "data_id": "0x3ae11545eda17fd9:0xe4d7ca849dbecbbe",
  "place_name": "Weligama Bay Marriott Resort & Spa"
}
```

---

## 🌐 Data Source Determination

The system chooses between SERP API (real data) or Mock data:

```jac
# In DataFetcherAgent
can start with `root entry {
    if not self.serp_api_key {
        self.serp_api_key = os.environ.get("SERPAPI_KEY", "");
    }

    if self.force_mock {
        self.data_source = "mock";
    } elif self.serp_api_key and len(self.serp_api_key) > 10 {
        self.data_source = "serpapi";
    } else {
        self.data_source = "mock";
    }
}
```

**Decision Tree**:

```
force_mock = true?
  └─▶ Yes → Use Mock Data
  └─▶ No
       └─▶ SERPAPI_KEY exists and valid?
            └─▶ Yes → Use SERP API
            └─▶ No → Use Mock Data
```

---

## 📍 Fetching Place Details (Real Data)

### SERP API Endpoint

```
GET https://serpapi.com/search
```

### Parameters

```json
{
  "engine": "google_maps",
  "type": "place",
  "data": "!4m5!3m4!1s{data_id}!8m2!3d0!4d0!16s",
  "api_key": "{your_serpapi_key}",
  "hl": "en"
}
```

### Example Request

```bash
curl --get https://serpapi.com/search \
  -d engine="google_maps" \
  -d type="place" \
  -d data="!4m5!3m4!1s0x3ae11545eda17fd9:0xe4d7ca849dbecbbe!8m2!3d0!4d0!16s" \
  -d api_key="your_key_here" \
  -d hl="en"
```

### Response Structure

```json
{
  "place_results": {
    "title": "Weligama Bay Marriott Resort & Spa",
    "rating": 4.5,
    "reviews": 1250,
    "type": ["Resort hotel", "Hotel"],
    "address": "Weligama Beach, Weligama 82400, Sri Lanka",
    "phone": "+94 41 225 5000",
    "website": "https://www.marriott.com/...",
    "price": "$$$$",
    "gps_coordinates": {
      "latitude": 5.9730503,
      "longitude": 80.4394055
    },
    "hours": [
      {"Monday": "Open 24 hours"},
      {"Tuesday": "Open 24 hours"},
      ...
    ],
    "images": [
      {"thumbnail": "https://..."},
      ...
    ],
    "popular_times": {
      ...
    }
  }
}
```

### Data Extraction Code

```jac
def fetch_real_place_details(parsed: dict) {
    try {
        data_id = parsed["data_id"];
        data_param = f"!4m5!3m4!1s{data_id}!8m2!3d0!4d0!16s";

        params = {
            "engine": "google_maps",
            "type": "place",
            "data": data_param,
            "api_key": self.serp_api_key,
            "hl": "en"
        };

        response = requests.get("https://serpapi.com/search", params=params);
        data = response.json();

        if "place_results" in data {
            place = data["place_results"];

            # Basic info
            self.business[0].name = place.get("title", "");
            self.business[0].address = place.get("address", "");
            self.business[0].phone = place.get("phone", "");
            self.business[0].website = place.get("website", "");
            self.business[0].rating = float(place.get("rating", 0));
            self.business[0].total_reviews = int(place.get("reviews", 0));
            self.business[0].price_level = place.get("price", "");

            # Business type (array: ["Resort hotel", "Hotel"])
            type_list = place.get("type", []);
            if isinstance(type_list, list) and type_list {
                self.business[0].business_type = ", ".join(type_list);
            }

            # GPS coordinates
            gps = place.get("gps_coordinates", {});
            self.business[0].latitude = gps.get("latitude", 0.0);
            self.business[0].longitude = gps.get("longitude", 0.0);

            # Opening hours (convert array to dict)
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
                self.business[0].photos_count = len(place["images"]);
            }
        }
    } except Exception as e {
        print(f"Place details error: {str(e)}");
    }
}
```

---

## 📝 Fetching Reviews (Real Data)

### SERP API Endpoint

```
GET https://serpapi.com/search
```

### Parameters

```json
{
  "engine": "google_maps_reviews",
  "data_id": "{data_id}",
  "api_key": "{your_serpapi_key}",
  "sort_by": "newestFirst",
  "num": 20,
  "next_page_token": "{token}" // For pagination
}
```

### Pagination Logic

```jac
def fetch_real_reviews(parsed: dict) {
    next_page_token = None;
    total_fetched = 0;
    page = 1;

    # Loop until we reach max_reviews
    while total_fetched < self.max_reviews {
        try {
            params = {
                "engine": "google_maps_reviews",
                "data_id": parsed["data_id"],
                "api_key": self.serp_api_key,
                "sort_by": "newestFirst"
            };

            # Add pagination token if exists
            if next_page_token {
                params["num"] = 20;
                params["next_page_token"] = next_page_token;
            }

            response = requests.get("https://serpapi.com/search", params=params);
            data = response.json();

            reviews = data.get("reviews", []);
            print(f"Page {page}: {len(reviews)} reviews");

            # Process each review
            for rev in reviews {
                if total_fetched >= self.max_reviews {
                    break;
                }

                # Create Review node
                self.business[0] ++> Review(
                    review_id=rev.get("review_id", str(uuid4())),
                    author=rev.get("user", {}).get("name", "Anonymous"),
                    author_image=rev.get("user", {}).get("thumbnail", ""),
                    rating=int(rev.get("rating", 3)),
                    text=rev.get("snippet", rev.get("text", "")),
                    date=rev.get("date", ""),
                    relative_date=rev.get("relative_date", ""),
                    likes=int(rev.get("likes", 0)),
                    owner_response=rev.get("response", {}).get("snippet", "")
                );
                total_fetched += 1;
            }

            # Get next page token
            next_page_token = data.get("serpapi_pagination", {}).get("next_page_token");
            if not next_page_token {
                break;  # No more pages
            }
            page += 1;

        } except Exception as e {
            print(f"Review fetch error: {str(e)}");
            break;
        }
    }

    self.reviews_fetched = total_fetched;
}
```

### Review Response Structure

```json
{
  "reviews": [
    {
      "review_id": "ChdDSUhNMG9nS0VJQ0FnSUR...",
      "user": {
        "name": "John Doe",
        "thumbnail": "https://lh3.googleusercontent.com/..."
      },
      "rating": 5,
      "snippet": "Amazing hotel! The staff was incredibly friendly...",
      "date": "2 weeks ago",
      "relative_date": "2 weeks ago",
      "likes": 12,
      "response": {
        "snippet": "Thank you for your kind words! We look forward..."
      }
    },
    ...
  ],
  "serpapi_pagination": {
    "next_page_token": "..."
  }
}
```

---

## 📦 Mock Data (Fallback)

When SERP API is unavailable, the system uses pre-defined mock data:

### Mock Place Details

```jac
def use_mock_place_details(parsed: dict) {
    self.business[0].name = parsed["place_name"] or "Demo Business";
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
```

### Mock Reviews (20 Pre-written)

The system includes 20 diverse mock reviews covering:

- Various ratings (1-5 stars)
- Different sentiments (positive, negative, neutral, mixed)
- Multiple themes (food, service, ambiance, value)
- Different time periods (last 6 months)

Example mock reviews:

```jac
mock_reviews = [
    {
        "rating": 5,
        "text": "Absolutely amazing experience! The food was incredible...",
        "author": "Sarah M.",
        "date": "2024-12-15",
        "relative_date": "2 weeks ago"
    },
    {
        "rating": 2,
        "text": "Disappointed with the service. Waited 45 minutes...",
        "author": "Mike R.",
        "date": "2024-12-08",
        "relative_date": "3 weeks ago"
    },
    // ... 18 more reviews
];
```

---

## 🏷️ Business Type Detection

After fetching place details, the system detects the business type:

### Detection Logic

```jac
def detect_business_type(google_type: str, business_name: str) -> str {
    # 1. Try direct mapping
    google_type_lower = google_type.lower().replace(" ", "_");
    if google_type_lower in BUSINESS_TYPE_MAP {
        return BUSINESS_TYPE_MAP[google_type_lower];
    }

    # 2. Try partial matching
    for (key, value) in BUSINESS_TYPE_MAP.items() {
        if key in google_type_lower or google_type_lower in key {
            return value;
        }
    }

    # 3. Try name-based detection
    name_lower = business_name.lower();
    name_keywords = {
        "restaurant": "RESTAURANT",
        "hotel": "HOTEL",
        "resort": "HOTEL",
        "store": "RETAIL",
        "salon": "SALON",
        "spa": "SALON",
        "clinic": "HEALTHCARE",
        "gym": "GYM",
        // ... more keywords
    };

    for (keyword, btype) in name_keywords.items() {
        if keyword in name_lower {
            return btype;
        }
    }

    # 4. Default to GENERIC
    return "GENERIC";
}
```

### Business Type Mapping

```python
BUSINESS_TYPE_MAP = {
    # Restaurant types
    "restaurant": "RESTAURANT",
    "cafe": "RESTAURANT",
    "bakery": "RESTAURANT",
    "bar": "RESTAURANT",
    "ice_cream_shop": "RESTAURANT",

    # Hotel types
    "hotel": "HOTEL",
    "resort": "HOTEL",
    "lodging": "HOTEL",
    "bed_and_breakfast": "HOTEL",

    # Retail types
    "store": "RETAIL",
    "shopping_mall": "RETAIL",
    "supermarket": "RETAIL",

    # Salon types
    "salon": "SALON",
    "spa": "SALON",
    "beauty_salon": "SALON",

    # Healthcare types
    "hospital": "HEALTHCARE",
    "clinic": "HEALTHCARE",
    "doctor": "HEALTHCARE",

    # Entertainment types
    "amusement_park": "ENTERTAINMENT",
    "museum": "ENTERTAINMENT",
    "movie_theater": "ENTERTAINMENT",

    # Auto types
    "car_repair": "AUTO_SERVICE",
    "car_dealer": "AUTO_SERVICE",

    # Gym types
    "gym": "GYM",
    "fitness": "GYM"
}
```

---

## 🔗 Creating Graph Nodes

### Business Node Creation

```jac
# Parse URL first
parsed = parse_google_maps_url(self.url);

# Create Business node
business_id = parsed["data_id"] if parsed["data_id"] else str(uuid4());

self.business = here ++> Business(
    place_id=business_id,
    data_id=parsed["data_id"],
    name=parsed["place_name"] or "Unknown Business",
    original_url=self.url,
    status="fetching"
);

# Fetch details (populates business properties)
self.fetch_place_details(parsed);

# Detect and set business type
detected_type = detect_business_type(
    self.business[0].business_type,
    self.business[0].name
);
self.business[0].business_type_normalized = detected_type;

# Fetch reviews (creates Review nodes)
self.fetch_reviews(parsed);

# Mark as completed
self.business[0].status = "fetched";
self.business[0].fetched_at = datetime.now().isoformat();
```

### Review Node Creation

```jac
# For each review from API
self.business[0] ++> Review(
    review_id=rev.get("review_id", str(uuid4())),
    author=rev.get("user", {}).get("name", "Anonymous"),
    author_image=rev.get("user", {}).get("thumbnail", ""),
    rating=int(rev.get("rating", 3)),
    text=rev.get("snippet", ""),
    date=rev.get("date", ""),
    relative_date=rev.get("relative_date", ""),
    likes=int(rev.get("likes", 0)),
    owner_response=rev.get("response", {}).get("snippet", ""),

    # Analysis fields (populated later)
    sentiment="",
    sentiment_score=0.0,
    themes=[],
    sub_themes={},
    keywords=[],
    emotion="",
    analyzed=False
);
```

---

## 📊 Output Summary

After DataFetcherAgent completes:

```json
{
  "business": {
    "place_id": "0x...:0x...",
    "name": "Weligama Bay Marriott Resort & Spa",
    "business_type": "Resort hotel, Hotel",
    "business_type_normalized": "HOTEL",
    "rating": 4.5,
    "total_reviews": 1250,
    "address": "...",
    "phone": "...",
    "website": "...",
    "status": "fetched"
  },
  "reviews_fetched": 50,
  "status": "completed",
  "data_source": "serpapi"
}
```

---

## 🔧 For Node.js Implementation

### Required npm packages:

```bash
npm install axios
```

### Place Details API Call

```typescript
async function fetchPlaceDetails(dataId: string, apiKey: string) {
  const params = {
    engine: "google_maps",
    type: "place",
    data: `!4m5!3m4!1s${dataId}!8m2!3d0!4d0!16s`,
    api_key: apiKey,
    hl: "en",
  };

  const response = await axios.get("https://serpapi.com/search", { params });
  return response.data.place_results;
}
```

### Reviews API Call with Pagination

```typescript
async function fetchReviews(
  dataId: string,
  apiKey: string,
  maxReviews: number
) {
  const reviews = [];
  let nextPageToken = null;

  while (reviews.length < maxReviews) {
    const params: any = {
      engine: "google_maps_reviews",
      data_id: dataId,
      api_key: apiKey,
      sort_by: "newestFirst",
    };

    if (nextPageToken) {
      params.num = 20;
      params.next_page_token = nextPageToken;
    }

    const response = await axios.get("https://serpapi.com/search", { params });
    const data = response.data;

    reviews.push(...data.reviews.slice(0, maxReviews - reviews.length));

    nextPageToken = data.serpapi_pagination?.next_page_token;
    if (!nextPageToken) break;
  }

  return reviews;
}
```

---

**Next**: Read [03-SENTIMENT-ANALYSIS.md](./03-SENTIMENT-ANALYSIS.md) for sentiment analysis details.
