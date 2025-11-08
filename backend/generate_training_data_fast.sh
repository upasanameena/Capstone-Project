#!/bin/bash
# Fast Training Data Generator (Skips slow network tests)
# Generates diverse good and bad samples for ML model training

WAF_URL="http://127.0.0.1:8081"

echo "=========================================="
echo "  Fast Training Data Generator"
echo "=========================================="
echo ""
echo "This script generates training samples for Application Layer WAF"
echo "Network layer tests are skipped (run separately if needed)"
echo ""
echo "WAF URL: $WAF_URL"
echo ""

# Check if WAF is running
if ! curl -s "$WAF_URL/test" > /dev/null 2>&1; then
    echo "⚠️  WARNING: WAF is not running on $WAF_URL"
    echo "   Please start the WAF first!"
    exit 1
fi

echo "✓ WAF is running"
echo ""

# ============================================================================
# PART 1: GOOD GET REQUESTS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Generating GOOD GET Requests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for query in "hello" "world" "test" "search" "products" "about" "contact" "home" "page" "info" \
             "user" "login" "register" "profile" "settings" "help" "faq" "blog" "news" "events"; do
    curl -s "$WAF_URL/?q=$query" > /dev/null
done

for id in {1..20}; do
    curl -s "$WAF_URL/product?id=$id" > /dev/null
    curl -s "$WAF_URL/item?product_id=$id" > /dev/null
done

echo "  ✓ Generated 60+ good GET requests"
echo ""

# ============================================================================
# PART 2: BAD GET REQUESTS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Generating BAD GET Requests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# SQL Injection
for pattern in "1' OR '1'='1" "1' OR '1'='1--" "admin'--" "' OR 1=1--" \
               "1' UNION SELECT NULL--" "1' UNION SELECT * FROM users--"; do
    encoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))" <<< "$pattern")
    curl -s "$WAF_URL/?q=$encoded" > /dev/null
done

# XSS
for pattern in "<script>alert(1)</script>" "<img src=x onerror=alert(1)>" \
               "javascript:alert(1)" "onerror=alert(1)"; do
    encoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))" <<< "$pattern")
    curl -s "$WAF_URL/?q=$encoded" > /dev/null
done

# Command Injection
for pattern in "; ls -la" "; cat /etc/passwd" "| whoami" "&& id"; do
    encoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))" <<< "$pattern")
    curl -s "$WAF_URL/?q=$encoded" > /dev/null
done

# Path Traversal
for pattern in "../../../etc/passwd" "/etc/passwd"; do
    encoded=$(python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))" <<< "$pattern")
    curl -s "$WAF_URL/?q=$encoded" > /dev/null
done

echo "  ✓ Generated 20+ bad GET requests"
echo ""

# ============================================================================
# PART 3: GOOD POST REQUESTS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Generating GOOD POST Requests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

for i in {1..30}; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"user$i\",\"email\":\"user$i@example.com\"}" > /dev/null
done

echo "  ✓ Generated 30+ good POST requests"
echo ""

# ============================================================================
# PART 4: BAD POST REQUESTS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Generating BAD POST Requests"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# SQL Injection
for pattern in "admin' OR '1'='1" "admin'--" "' OR 1=1--"; do
    curl -s -X POST "$WAF_URL/login" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=$pattern&password=x" > /dev/null
done

# XSS
for pattern in "<script>alert(1)</script>" "javascript:alert(1)"; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"$pattern\"}" > /dev/null
done

echo "  ✓ Generated 5+ bad POST requests"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Training Data Generation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generated samples:"
echo "  ✓ 60+ Good GET requests"
echo "  ✓ 20+ Bad GET requests"
echo "  ✓ 30+ Good POST requests"
echo "  ✓ 5+ Bad POST requests"
echo ""
echo "For network layer data, run network firewall separately and generate traffic."
echo ""
echo "Check CSV files:"
echo "  wc -l Data_Collection/Good_req.csv"
echo "  wc -l Data_Collection/Bad_req.csv"
echo "  wc -l benign_payloads.csv"
echo "  wc -l malicious_payloads.csv"
echo ""

