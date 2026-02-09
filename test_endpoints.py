"""Test all major endpoints after v0.10.0 migration."""
import requests
import json
import time
import sys

BASE = "http://localhost:8002"

def test(name, method, url, data=None, headers=None, expect_status=None):
    try:
        if method == "POST":
            r = requests.post(url, json=data or {}, headers=headers or {})
        else:
            r = requests.get(url, headers=headers or {})
        body = r.json() if r.text else {}
        ok = body.get("ok", False) if isinstance(body, dict) else False
        status = "PASS" if (ok or r.status_code == 200) else "FAIL"
        print(f"  [{status}] {name} -> {r.status_code}")
        if status == "FAIL":
            print(f"         Response: {json.dumps(body, indent=2)[:300]}")
        return body
    except Exception as e:
        print(f"  [ERROR] {name} -> {e}")
        return None

# Wait for server
print("Waiting for server to start...")
for i in range(60):
    try:
        r = requests.post(f"{BASE}/walker/health_check", json={}, timeout=2)
        if r.status_code == 200:
            print("Server is ready!\n")
            break
    except:
        pass
    time.sleep(1)
else:
    print("Server failed to start!")
    sys.exit(1)

# === Public endpoints (no auth) ===
print("=== PUBLIC ENDPOINTS ===")
test("health_check", "POST", f"{BASE}/walker/health_check")
test("ready", "POST", f"{BASE}/walker/ready")

# === Auth ===
print("\n=== AUTHENTICATION ===")
reg = test("register", "POST", f"{BASE}/user/register", {
    "username": "testuser",
    "password": "testpass123"
})
token = ""
if reg and reg.get("data"):
    token = reg["data"].get("token", "")
if not token:
    print("  Registration failed or user exists, trying login...")
    login = test("login", "POST", f"{BASE}/user/login", {
        "username": "testuser",
        "password": "testpass123"
    })
    if login and login.get("data"):
        token = login["data"].get("token", "")

if not token:
    print("  No token obtained! Exiting.")
    sys.exit(1)

print(f"  Token: {token[:30]}...")
auth = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}

# === User Profile ===
print("\n=== USER PROFILE ===")
test("create_user_profile", "POST", f"{BASE}/walker/create_user_profile", {}, auth)
test("get_user_profile", "POST", f"{BASE}/walker/get_user_profile", {}, auth)

# === API Walkers ===
print("\n=== API WALKERS ===")
test("GetBusinesses", "POST", f"{BASE}/walker/GetBusinesses", {}, auth)
test("GetStats", "POST", f"{BASE}/walker/GetStats", {}, auth)

# === Credit Walkers ===
print("\n=== CREDIT WALKERS ===")
test("GetCreditBalance", "POST", f"{BASE}/walker/GetCreditBalance", {}, auth)
test("GetCreditHistory", "POST", f"{BASE}/walker/GetCreditHistory", {}, auth)

# === Content Walkers ===
print("\n=== CONTENT WALKERS ===")
test("GetResponseTemplates", "POST", f"{BASE}/walker/GetResponseTemplates", {}, auth)
test("GetReplyPromptConfig", "POST", f"{BASE}/walker/GetReplyPromptConfig", {
    "business_id": "fake-id"
}, auth)

# === Payment Walkers ===
print("\n=== PAYMENT WALKERS ===")
test("GetCreditPackages", "POST", f"{BASE}/walker/GetCreditPackages", {}, auth)

print("\n=== ALL TESTS COMPLETE ===")
