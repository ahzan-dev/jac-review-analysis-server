# ══════════════════════════════════════════════════════════════════════════════
# STANDARDIZED ERROR HANDLING MODULE
# ══════════════════════════════════════════════════════════════════════════════
# Provides consistent error response formatting across all API walkers
# Following Jaseci tutorial best practices for error handling
# ══════════════════════════════════════════════════════════════════════════════

import from datetime { datetime }

# ═══════════════════════════════════════════════════════════════════════════════
# ERROR CODE ENUM
# ═══════════════════════════════════════════════════════════════════════════════
# Standard error codes for consistent error identification

enum ErrorCode {
    USER_NOT_FOUND = "USER_NOT_FOUND",
    PROFILE_NOT_FOUND = "PROFILE_NOT_FOUND",
    UNAUTHORIZED = "UNAUTHORIZED",
    INVALID_INPUT = "INVALID_INPUT",
    INVALID_URL = "INVALID_URL",
    QUOTA_EXCEEDED = "QUOTA_EXCEEDED",
    DAILY_LIMIT_EXCEEDED = "DAILY_LIMIT_EXCEEDED",
    BUSINESS_LIMIT_EXCEEDED = "BUSINESS_LIMIT_EXCEEDED",
    API_ERROR = "API_ERROR",
    INTERNAL_ERROR = "INTERNAL_ERROR",
    TOKEN_EXPIRED = "TOKEN_EXPIRED",
    INVALID_TOKEN = "INVALID_TOKEN",
    BUSINESS_NOT_FOUND = "BUSINESS_NOT_FOUND",
    REPORT_NOT_FOUND = "REPORT_NOT_FOUND",
    INSUFFICIENT_PERMISSIONS = "INSUFFICIENT_PERMISSIONS",

    # Payment-related errors
    PAYMENT_FAILED = "PAYMENT_FAILED",
    PAYMENT_INTENT_NOT_FOUND = "PAYMENT_INTENT_NOT_FOUND",
    SUBSCRIPTION_EXPIRED = "SUBSCRIPTION_EXPIRED",
    INVALID_BILLING_INTERVAL = "INVALID_BILLING_INTERVAL",
    CARD_DECLINED = "CARD_DECLINED",
    INSUFFICIENT_FUNDS = "INSUFFICIENT_FUNDS",

    # Credit-related errors
    INSUFFICIENT_CREDITS = "INSUFFICIENT_CREDITS"
}

# ═══════════════════════════════════════════════════════════════════════════════
# ERROR RESPONSE HELPER FUNCTIONS
# ═══════════════════════════════════════════════════════════════════════════════

# Create a standardized error response
def error_response(code: ErrorCode, message: str, details: dict) -> dict {
    result = {
        "success": False,
        "error": {
            "code": code.value,
            "message": message,
            "timestamp": str(datetime.now()),
            "details": details
        }
    };
    return result;
}

# Create a standardized success response
def success_response(data: any, metadata: dict) -> dict {
    result = {
        "success": True,
        "data": data,
        "timestamp": str(datetime.now())
    };

    # Add metadata if provided
    if metadata and len(metadata.keys()) > 0 {
        result["metadata"] = metadata;
    }

    return result;
}

# Create a validation error response
def validation_error(field: str, reason: str) -> dict {
    return error_response(
        ErrorCode.INVALID_INPUT,
        f"Validation failed for field: {field}",
        {"field": field, "reason": reason}
    );
}

# Create a quota exceeded error response
def quota_exceeded_error(quota_type: str, limit: int, current: int) -> dict {
    return error_response(
        ErrorCode.QUOTA_EXCEEDED,
        f"Quota exceeded for {quota_type}: {current}/{limit}",
        {
            "quota_type": quota_type,
            "limit": limit,
            "current": current,
            "exceeded_by": current - limit
        }
    );
}

# Create an unauthorized access error response
def unauthorized_error(reason: str) -> dict {
    return error_response(
        ErrorCode.UNAUTHORIZED,
        reason,
        {"required_action": "authenticate"}
    );
}

# Create a resource not found error response
def not_found_error(resource_type: str, identifier: str) -> dict {
    code_map = {
        "business": ErrorCode.BUSINESS_NOT_FOUND,
        "report": ErrorCode.REPORT_NOT_FOUND,
        "user": ErrorCode.USER_NOT_FOUND,
        "profile": ErrorCode.PROFILE_NOT_FOUND
    };

    error_code = code_map.get(resource_type.lower(), ErrorCode.INTERNAL_ERROR);

    return error_response(
        error_code,
        f"{resource_type.capitalize()} not found: {identifier}",
        {"resource_type": resource_type, "identifier": identifier}
    );
}

# Create an insufficient credits error response
def insufficient_credits_error(credit_type: str, required: int, available: int) -> dict {
    return error_response(
        ErrorCode.INSUFFICIENT_CREDITS,
        f"Insufficient {credit_type} credits: need {required}, have {available}",
        {
            "credit_type": credit_type,
            "required": required,
            "available": available,
            "shortage": required - available,
            "action": "Purchase more credits or upgrade your plan"
        }
    );
}
