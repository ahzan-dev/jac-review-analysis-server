# Business Types & Theme Mappings

## 🎯 Overview

The system supports 9 normalized business types, each with specific themes and sub-themes for targeted analysis. Google Maps provides 100+ business type labels that are mapped to these 9 normalized types.

---

## 📊 Normalized Business Types

```typescript
enum BusinessType {
  RESTAURANT = "RESTAURANT",
  HOTEL = "HOTEL",
  RETAIL = "RETAIL",
  SALON = "SALON",
  HEALTHCARE = "HEALTHCARE",
  ENTERTAINMENT = "ENTERTAINMENT",
  AUTO_SERVICE = "AUTO_SERVICE",
  GYM = "GYM",
  GENERIC = "GENERIC",
}
```

---

## 🗺️ Business Type Mapping (BUSINESS_TYPE_MAP)

### Complete 97-Type Mapping Dictionary

```python
BUSINESS_TYPE_MAP = {
    # RESTAURANT (31 types)
    "restaurant": "RESTAURANT",
    "cafe": "RESTAURANT",
    "bar": "RESTAURANT",
    "bakery": "RESTAURANT",
    "meal_takeaway": "RESTAURANT",
    "meal_delivery": "RESTAURANT",
    "food": "RESTAURANT",
    "coffee_shop": "RESTAURANT",
    "fast_food_restaurant": "RESTAURANT",
    "brunch_restaurant": "RESTAURANT",
    "fine_dining_restaurant": "RESTAURANT",
    "pizza_restaurant": "RESTAURANT",
    "italian_restaurant": "RESTAURANT",
    "chinese_restaurant": "RESTAURANT",
    "japanese_restaurant": "RESTAURANT",
    "mexican_restaurant": "RESTAURANT",
    "indian_restaurant": "RESTAURANT",
    "american_restaurant": "RESTAURANT",
    "seafood_restaurant": "RESTAURANT",
    "steakhouse": "RESTAURANT",
    "vegan_restaurant": "RESTAURANT",
    "vegetarian_restaurant": "RESTAURANT",
    "breakfast_restaurant": "RESTAURANT",
    "lunch_restaurant": "RESTAURANT",
    "dinner_restaurant": "RESTAURANT",
    "sandwich_shop": "RESTAURANT",
    "hamburger_restaurant": "RESTAURANT",
    "ice_cream_shop": "RESTAURANT",
    "dessert_shop": "RESTAURANT",
    "tea_house": "RESTAURANT",
    "juice_bar": "RESTAURANT",

    # HOTEL (16 types)
    "lodging": "HOTEL",
    "hotel": "HOTEL",
    "resort": "HOTEL",
    "motel": "HOTEL",
    "bed_and_breakfast": "HOTEL",
    "hostel": "HOTEL",
    "inn": "HOTEL",
    "guest_house": "HOTEL",
    "extended_stay_hotel": "HOTEL",
    "serviced_apartment": "HOTEL",
    "vacation_rental": "HOTEL",
    "apartment_hotel": "HOTEL",
    "boutique_hotel": "HOTEL",
    "capsule_hotel": "HOTEL",
    "love_hotel": "HOTEL",
    "ryokan": "HOTEL",

    # RETAIL (18 types)
    "store": "RETAIL",
    "shopping_mall": "RETAIL",
    "clothing_store": "RETAIL",
    "shoe_store": "RETAIL",
    "jewelry_store": "RETAIL",
    "electronics_store": "RETAIL",
    "furniture_store": "RETAIL",
    "home_goods_store": "RETAIL",
    "book_store": "RETAIL",
    "toy_store": "RETAIL",
    "pet_store": "RETAIL",
    "florist": "RETAIL",
    "gift_shop": "RETAIL",
    "convenience_store": "RETAIL",
    "supermarket": "RETAIL",
    "grocery_store": "RETAIL",
    "department_store": "RETAIL",
    "hardware_store": "RETAIL",

    # SALON (9 types)
    "hair_salon": "SALON",
    "hair_care": "SALON",
    "beauty_salon": "SALON",
    "barber_shop": "SALON",
    "nail_salon": "SALON",
    "spa": "SALON",
    "day_spa": "SALON",
    "massage": "SALON",
    "waxing_hair_removal": "SALON",

    # HEALTHCARE (10 types)
    "doctor": "HEALTHCARE",
    "dentist": "HEALTHCARE",
    "hospital": "HEALTHCARE",
    "pharmacy": "HEALTHCARE",
    "physiotherapist": "HEALTHCARE",
    "health": "HEALTHCARE",
    "medical_clinic": "HEALTHCARE",
    "veterinary_care": "HEALTHCARE",
    "optometrist": "HEALTHCARE",
    "chiropractor": "HEALTHCARE",

    # ENTERTAINMENT (7 types)
    "movie_theater": "ENTERTAINMENT",
    "night_club": "ENTERTAINMENT",
    "amusement_park": "ENTERTAINMENT",
    "bowling_alley": "ENTERTAINMENT",
    "casino": "ENTERTAINMENT",
    "museum": "ENTERTAINMENT",
    "aquarium": "ENTERTAINMENT",

    # AUTO_SERVICE (3 types)
    "car_repair": "AUTO_SERVICE",
    "car_wash": "AUTO_SERVICE",
    "car_dealer": "AUTO_SERVICE",

    # GYM (3 types)
    "gym": "GYM",
    "fitness_center": "GYM",
    "yoga_studio": "GYM"
}
```

---

## 🎨 Theme Definitions by Business Type

### 1. HOTEL

```python
THEME_DEFINITIONS["HOTEL"] = {
    "Room Quality": [
        "Cleanliness",
        "Bed Comfort",
        "Size",
        "View",
        "Amenities",
        "Maintenance"
    ],
    "Service": [
        "Front Desk",
        "Housekeeping",
        "Concierge",
        "Response Time",
        "Staff Attitude"
    ],
    "Location": [
        "Accessibility",
        "Nearby Attractions",
        "Safety",
        "Noise Level",
        "Transportation"
    ],
    "Facilities": [
        "Pool",
        "Gym",
        "Restaurant",
        "Bar",
        "Parking",
        "WiFi"
    ],
    "Value for Money": [
        "Price Point",
        "Quality vs Cost",
        "Hidden Fees",
        "Promotions",
        "Cancellation Policy"
    ],
    "Cleanliness": [
        "Room Cleanliness",
        "Bathroom Cleanliness",
        "Common Areas",
        "Pool/Spa Cleanliness"
    ],
    "Check-in/Check-out": [
        "Process Speed",
        "Ease",
        "Flexibility",
        "Early/Late Options"
    ]
}
```

### 2. RESTAURANT

```python
THEME_DEFINITIONS["RESTAURANT"] = {
    "Food Quality": [
        "Taste",
        "Freshness",
        "Presentation",
        "Portion Size",
        "Temperature",
        "Ingredients"
    ],
    "Service": [
        "Attentiveness",
        "Friendliness",
        "Speed",
        "Knowledge",
        "Professionalism"
    ],
    "Ambiance": [
        "Decor",
        "Lighting",
        "Music",
        "Cleanliness",
        "Seating Comfort",
        "Noise Level"
    ],
    "Value for Money": [
        "Price Point",
        "Portion vs Price",
        "Quality vs Cost",
        "Specials/Deals"
    ],
    "Menu Variety": [
        "Selection",
        "Dietary Options",
        "Specials",
        "Drinks Menu",
        "Desserts"
    ],
    "Wait Time": [
        "Seating Wait",
        "Order Time",
        "Food Delivery",
        "Bill Wait"
    ],
    "Location": [
        "Accessibility",
        "Parking",
        "Atmosphere",
        "Views"
    ],
    "Hygiene": [
        "Kitchen Cleanliness",
        "Table Cleanliness",
        "Restroom Cleanliness",
        "Staff Hygiene"
    ]
}
```

### 3. RETAIL

```python
THEME_DEFINITIONS["RETAIL"] = {
    "Product Quality": [
        "Durability",
        "Brand Selection",
        "Authenticity",
        "Condition",
        "Variety"
    ],
    "Customer Service": [
        "Helpfulness",
        "Knowledge",
        "Friendliness",
        "Attentiveness",
        "Problem Resolution"
    ],
    "Price": [
        "Competitiveness",
        "Value",
        "Discounts",
        "Sales",
        "Hidden Costs"
    ],
    "Store Layout": [
        "Organization",
        "Ease of Navigation",
        "Cleanliness",
        "Displays",
        "Signage"
    ],
    "Stock Availability": [
        "In-stock Items",
        "Size Range",
        "Color Options",
        "Restock Speed"
    ],
    "Return Policy": [
        "Ease",
        "Timeframe",
        "Refund Process",
        "Exchange Options"
    ],
    "Checkout Experience": [
        "Wait Time",
        "Process Speed",
        "Payment Options",
        "Staff Efficiency"
    ],
    "Location": [
        "Accessibility",
        "Parking",
        "Public Transport",
        "Nearby Amenities"
    ]
}
```

### 4. SALON

```python
THEME_DEFINITIONS["SALON"] = {
    "Service Quality": [
        "Skill Level",
        "Technique",
        "Precision",
        "Consistency",
        "Results"
    ],
    "Staff": [
        "Friendliness",
        "Professionalism",
        "Expertise",
        "Listening Skills",
        "Recommendations"
    ],
    "Cleanliness": [
        "Equipment Hygiene",
        "Facility Cleanliness",
        "Product Quality",
        "Sterilization"
    ],
    "Atmosphere": [
        "Ambiance",
        "Music",
        "Decor",
        "Comfort",
        "Privacy"
    ],
    "Booking": [
        "Ease of Booking",
        "Availability",
        "Wait Time",
        "Punctuality",
        "Reminder System"
    ],
    "Pricing": [
        "Value",
        "Transparency",
        "Packages",
        "Extras Cost"
    ],
    "Products Used": [
        "Quality",
        "Brand",
        "Suitability",
        "Variety"
    ]
}
```

### 5. HEALTHCARE

```python
THEME_DEFINITIONS["HEALTHCARE"] = {
    "Doctor Quality": [
        "Expertise",
        "Diagnosis Accuracy",
        "Bedside Manner",
        "Communication",
        "Care Quality"
    ],
    "Staff": [
        "Receptionist",
        "Nurses",
        "Professionalism",
        "Helpfulness",
        "Courtesy"
    ],
    "Wait Time": [
        "Appointment Availability",
        "Waiting Room Time",
        "On-time Performance",
        "Emergency Response"
    ],
    "Facility": [
        "Cleanliness",
        "Modern Equipment",
        "Comfort",
        "Accessibility",
        "Parking"
    ],
    "Billing": [
        "Transparency",
        "Insurance Handling",
        "Payment Options",
        "Billing Accuracy"
    ],
    "Appointment Process": [
        "Booking Ease",
        "Reminder System",
        "Rescheduling",
        "Cancellation Policy"
    ],
    "Treatment Results": [
        "Effectiveness",
        "Follow-up Care",
        "Recovery Time",
        "Complications"
    ]
}
```

### 6. ENTERTAINMENT

```python
THEME_DEFINITIONS["ENTERTAINMENT"] = {
    "Experience Quality": [
        "Enjoyment",
        "Variety",
        "Excitement",
        "Uniqueness",
        "Age Appropriateness"
    ],
    "Facilities": [
        "Cleanliness",
        "Maintenance",
        "Safety",
        "Accessibility",
        "Comfort"
    ],
    "Staff": [
        "Helpfulness",
        "Friendliness",
        "Knowledge",
        "Efficiency"
    ],
    "Value for Money": [
        "Ticket Price",
        "Package Deals",
        "Concessions Cost",
        "Duration vs Price"
    ],
    "Crowds": [
        "Wait Times",
        "Capacity Management",
        "Line Organization",
        "Peak Hours"
    ],
    "Food & Beverage": [
        "Quality",
        "Variety",
        "Price",
        "Availability"
    ],
    "Location": [
        "Accessibility",
        "Parking",
        "Public Transport",
        "Nearby Amenities"
    ]
}
```

### 7. AUTO_SERVICE

```python
THEME_DEFINITIONS["AUTO_SERVICE"] = {
    "Service Quality": [
        "Workmanship",
        "Problem Diagnosis",
        "Completion Quality",
        "Attention to Detail"
    ],
    "Staff": [
        "Honesty",
        "Communication",
        "Expertise",
        "Customer Service",
        "Transparency"
    ],
    "Pricing": [
        "Fair Pricing",
        "Estimate Accuracy",
        "Hidden Costs",
        "Value for Money"
    ],
    "Timeliness": [
        "Appointment Availability",
        "On-time Completion",
        "Wait Time",
        "Turnaround Speed"
    ],
    "Facility": [
        "Cleanliness",
        "Equipment Quality",
        "Waiting Area",
        "Convenience"
    ],
    "Parts": [
        "Quality",
        "Availability",
        "OEM vs Aftermarket",
        "Warranty"
    ],
    "Communication": [
        "Status Updates",
        "Explanation of Work",
        "Recommendations",
        "Documentation"
    ]
}
```

### 8. GYM

```python
THEME_DEFINITIONS["GYM"] = {
    "Equipment": [
        "Variety",
        "Quality",
        "Maintenance",
        "Availability",
        "Modern Technology"
    ],
    "Cleanliness": [
        "Equipment Cleaning",
        "Locker Rooms",
        "Showers",
        "Overall Facility"
    ],
    "Staff": [
        "Trainer Quality",
        "Helpfulness",
        "Knowledge",
        "Motivation",
        "Availability"
    ],
    "Classes": [
        "Variety",
        "Schedule",
        "Instructor Quality",
        "Availability",
        "Level Range"
    ],
    "Facilities": [
        "Locker Rooms",
        "Showers",
        "Parking",
        "Childcare",
        "Amenities"
    ],
    "Membership": [
        "Value",
        "Flexibility",
        "Contract Terms",
        "Cancellation Policy",
        "Guest Policy"
    ],
    "Atmosphere": [
        "Crowding",
        "Music",
        "Temperature",
        "Vibe",
        "Community"
    ],
    "Hours": [
        "Operating Hours",
        "24/7 Access",
        "Holiday Hours",
        "Peak Times"
    ]
}
```

### 9. GENERIC

```python
THEME_DEFINITIONS["GENERIC"] = {
    "Service": [
        "Quality",
        "Speed",
        "Professionalism",
        "Friendliness",
        "Efficiency"
    ],
    "Staff": [
        "Helpfulness",
        "Knowledge",
        "Attitude",
        "Communication"
    ],
    "Quality": [
        "Product/Service Quality",
        "Consistency",
        "Standards",
        "Results"
    ],
    "Value": [
        "Price",
        "Worth",
        "Competitiveness",
        "Deals"
    ],
    "Facility": [
        "Cleanliness",
        "Maintenance",
        "Comfort",
        "Accessibility"
    ],
    "Location": [
        "Convenience",
        "Parking",
        "Accessibility",
        "Surroundings"
    ],
    "Experience": [
        "Overall Satisfaction",
        "Atmosphere",
        "Convenience",
        "Uniqueness"
    ]
}
```

---

## 🔍 Business Type Detection Logic

```python
def detect_business_type(google_type: str, business_name: str) -> BusinessType:
    """
    Detect normalized business type from Google Maps type

    Args:
        google_type: Google Maps business type (e.g., "restaurant", "lodging")
        business_name: Name of the business for fallback detection

    Returns:
        BusinessType enum value
    """

    # Normalize input
    type_lower = google_type.lower().replace(" ", "_")

    # Direct mapping
    if type_lower in BUSINESS_TYPE_MAP:
        return BUSINESS_TYPE_MAP[type_lower]

    # Partial matching for compound types
    # (e.g., "italian_restaurant" contains "restaurant")
    for key in BUSINESS_TYPE_MAP:
        if key in type_lower or type_lower in key:
            return BUSINESS_TYPE_MAP[key]

    # Name-based detection (fallback)
    name_lower = business_name.lower()

    if any(word in name_lower for word in ["hotel", "inn", "resort", "lodge"]):
        return BusinessType.HOTEL

    if any(word in name_lower for word in ["restaurant", "cafe", "bistro", "grill"]):
        return BusinessType.RESTAURANT

    if any(word in name_lower for word in ["salon", "spa", "beauty", "barber"]):
        return BusinessType.SALON

    if any(word in name_lower for word in ["gym", "fitness", "workout"]):
        return BusinessType.GYM

    if any(word in name_lower for word in ["clinic", "hospital", "medical", "dental"]):
        return BusinessType.HEALTHCARE

    if any(word in name_lower for word in ["shop", "store", "boutique", "market"]):
        return BusinessType.RETAIL

    if any(word in name_lower for word in ["theater", "cinema", "club", "entertainment"]):
        return BusinessType.ENTERTAINMENT

    if any(word in name_lower for word in ["auto", "repair", "garage", "mechanic"]):
        return BusinessType.AUTO_SERVICE

    # Default to GENERIC
    return BusinessType.GENERIC
```

---

## 📋 Confidence Thresholds

```python
CONFIDENCE_THRESHOLDS = {
    "low_max": 20,           # <= 20 reviews = low confidence
    "medium_max": 50,        # 21-50 reviews = medium confidence
                             # > 50 reviews = high confidence
    "sub_theme_min_mentions": 3,  # Sub-theme needs >= 3 mentions to be included
    "theme_min_percentage": 5     # Theme needs >= 5% mention rate to be significant
}
```

---

## 🎯 Usage Examples

### Example 1: Hotel Detection

```python
google_type = "lodging"
business_name = "Grand Plaza Hotel"

detected = detect_business_type(google_type, business_name)
# Result: BusinessType.HOTEL

themes = THEME_DEFINITIONS[detected]
# Result: {
#   "Room Quality": ["Cleanliness", "Bed Comfort", ...],
#   "Service": ["Front Desk", "Housekeeping", ...],
#   ...
# }
```

### Example 2: Restaurant Detection

```python
google_type = "italian_restaurant"
business_name = "Mario's Pizzeria"

detected = detect_business_type(google_type, business_name)
# Result: BusinessType.RESTAURANT

themes = THEME_DEFINITIONS[detected]
# Result: {
#   "Food Quality": ["Taste", "Freshness", ...],
#   "Service": ["Attentiveness", "Friendliness", ...],
#   ...
# }
```

### Example 3: Generic Fallback

```python
google_type = "point_of_interest"
business_name = "Downtown Community Center"

detected = detect_business_type(google_type, business_name)
# Result: BusinessType.GENERIC

themes = THEME_DEFINITIONS[detected]
# Result: {
#   "Service": ["Quality", "Speed", ...],
#   "Staff": ["Helpfulness", "Knowledge", ...],
#   ...
# }
```

---

## 📊 Theme Statistics

### Total Themes by Business Type

| Business Type | Main Themes | Total Sub-themes |
| ------------- | ----------- | ---------------- |
| HOTEL         | 7           | 28               |
| RESTAURANT    | 8           | 31               |
| RETAIL        | 8           | 29               |
| SALON         | 7           | 27               |
| HEALTHCARE    | 7           | 26               |
| ENTERTAINMENT | 7           | 26               |
| AUTO_SERVICE  | 7           | 26               |
| GYM           | 8           | 32               |
| GENERIC       | 7           | 25               |

**Total**: 66 main themes, 250+ sub-themes across all business types

---

## ✅ Summary

Business type system:

- ✅ 9 normalized business types
- ✅ 97 Google Maps types mapped
- ✅ 66 main themes defined
- ✅ 250+ sub-themes for detailed analysis
- ✅ Intelligent detection with fallback logic
- ✅ Confidence thresholds for data quality
- ✅ Business-specific analysis patterns

**Complete**: All documentation files created! See [00-OVERVIEW.md](./00-OVERVIEW.md) for navigation.
