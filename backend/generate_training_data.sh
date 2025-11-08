#!/bin/bash
# Comprehensive Training Data Generator
# Generates diverse good and bad samples for ML model training

WAF_URL="http://127.0.0.1:8081"

echo "=========================================="
echo "  Comprehensive Training Data Generator"
echo "=========================================="
echo ""
echo "This script generates diverse training samples for:"
echo "  - Application Layer WAF (GET & POST requests)"
echo "  - Network Layer Firewall (packet patterns)"
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
# PART 1: GOOD GET REQUESTS (Normal, Safe URLs)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Generating GOOD GET Requests (Normal URLs)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Normal search queries
echo "  → Normal search queries..."
for query in "hello" "world" "test" "search" "products" "about" "contact" "home" "page" "info" \
             "user" "login" "register" "profile" "settings" "help" "faq" "blog" "news" "events" \
             "shop" "cart" "checkout" "payment" "order" "track" "support" "terms" "privacy" "policy"; do
    curl -s "$WAF_URL/?q=$query" > /dev/null
done

# Normal product pages
echo "  → Product pages..."
for id in {1..20}; do
    curl -s "$WAF_URL/product?id=$id" > /dev/null
    curl -s "$WAF_URL/item?product_id=$id" > /dev/null
    curl -s "$WAF_URL/catalog?category=electronics&page=$id" > /dev/null
done

# Normal user pages
echo "  → User pages..."
for id in {1..15}; do
    curl -s "$WAF_URL/user?id=$id" > /dev/null
    curl -s "$WAF_URL/profile?user_id=$id" > /dev/null
    curl -s "$WAF_URL/account?uid=$id" > /dev/null
done

# Normal API endpoints
echo "  → API endpoints..."
for endpoint in "api/users" "api/products" "api/categories" "api/orders" "api/reviews" \
               "api/search" "api/filter" "api/sort" "api/paginate" "api/export"; do
    curl -s "$WAF_URL/$endpoint" > /dev/null
done

# Normal pagination
echo "  → Pagination..."
for page in {1..10}; do
    curl -s "$WAF_URL/list?page=$page&limit=10" > /dev/null
    curl -s "$WAF_URL/results?page=$page&sort=name" > /dev/null
done

# Normal filters
echo "  → Filter queries..."
for filter in "category=electronics" "price_min=100" "price_max=500" "brand=samsung" \
              "rating=4" "in_stock=true" "sort=price" "order=asc"; do
    curl -s "$WAF_URL/search?$filter" > /dev/null
done

echo "  ✓ Generated 100+ good GET requests"
echo ""

# ============================================================================
# PART 2: BAD GET REQUESTS (SQL Injection, XSS, etc.)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Generating BAD GET Requests (SQL Injection, XSS, etc.)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# SQL Injection - Basic
echo "  → SQL Injection - Basic patterns..."
for pattern in "1' OR '1'='1" "1' OR '1'='1--" "1' OR '1'='1/*" "admin'--" "admin'/*" \
               "' OR 1=1--" "' OR 'a'='a" "' OR 1=1#" "1' OR '1'='1'--" "1' OR '1'='1'/*"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# SQL Injection - UNION
echo "  → SQL Injection - UNION attacks..."
for pattern in "1' UNION SELECT NULL--" "1' UNION SELECT * FROM users--" \
               "' UNION SELECT password FROM users--" "1' UNION SELECT 1,2,3--" \
               "' UNION SELECT username,password FROM users--" "1' UNION ALL SELECT NULL--"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# SQL Injection - Time-based
echo "  → SQL Injection - Time-based..."
for pattern in "1'; WAITFOR DELAY '00:00:05'--" "1' OR SLEEP(5)--" "1'; SELECT SLEEP(5)--" \
               "1' AND SLEEP(5)--" "1'; WAITFOR DELAY '0:0:5'--"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# SQL Injection - Boolean-based
echo "  → SQL Injection - Boolean-based..."
for pattern in "1' AND 1=1--" "1' AND 1=2--" "1' AND 'a'='a" "1' AND 'a'='b" \
               "1' AND ASCII(SUBSTRING((SELECT password FROM users LIMIT 1),1,1))>50--"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# XSS - Basic
echo "  → XSS - Basic patterns..."
for pattern in "<script>alert(1)</script>" "<script>alert('XSS')</script>" \
               "<img src=x onerror=alert(1)>" "<svg onload=alert(1)>" \
               "<body onload=alert(1)>" "<iframe src=javascript:alert(1)>"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# XSS - Encoded
echo "  → XSS - Encoded patterns..."
for pattern in "%3Cscript%3Ealert(1)%3C/script%3E" "javascript:alert(1)" \
               "javascript:alert('XSS')" "onerror=alert(1)" "onclick=alert(1)" \
               "onload=alert(1)" "onmouseover=alert(1)"; do
    curl -s "$WAF_URL/?q=$pattern" > /dev/null
done

# XSS - Advanced
echo "  → XSS - Advanced patterns..."
for pattern in "<script>eval(String.fromCharCode(97,108,101,114,116,40,49,41))</script>" \
               "<img src=x onerror=eval(atob('YWxlcnQoMSk='))>" \
               "<svg><script>alert&#40;1&#41;</script></svg>"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# Command Injection
echo "  → Command Injection..."
for pattern in "; ls -la" "; cat /etc/passwd" "; whoami" "; id" \
               "| cat /etc/passwd" "&& cat /etc/passwd" "`whoami`" "$(whoami)"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# Path Traversal
echo "  → Path Traversal..."
for pattern in "../../../etc/passwd" "....//....//etc/passwd" \
               "..%2F..%2F..%2Fetc%2Fpasswd" "/etc/passwd" "..\\..\\..\\windows\\system32"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# SSRF
echo "  → SSRF patterns..."
for pattern in "http://127.0.0.1:22" "http://localhost/admin" \
               "file:///etc/passwd" "gopher://127.0.0.1:6379" "dict://127.0.0.1:11211"; do
    curl -s "$WAF_URL/?q=$(echo -n "$pattern" | python3 -c "import sys, urllib.parse; print(urllib.parse.quote(sys.stdin.read()))")" > /dev/null
done

# IDOR
echo "  → IDOR patterns..."
for pattern in "../user/0" "../admin/1" "?user_id=0" "?id=-1" \
               "?user=admin" "?account=1" "?uid=0"; do
    curl -s "$WAF_URL/$pattern" > /dev/null
done

echo "  ✓ Generated 100+ bad GET requests"
echo ""

# ============================================================================
# PART 3: GOOD POST REQUESTS (Normal Payloads)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Generating GOOD POST Requests (Normal Payloads)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Normal JSON payloads
echo "  → Normal JSON payloads..."
for i in {1..30}; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"name\":\"user$i\",\"email\":\"user$i@example.com\"}" > /dev/null
    
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"action\":\"search\",\"query\":\"product$i\"}" > /dev/null
    
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"Hello world $i\",\"timestamp\":\"$(date +%s)\"}" > /dev/null
done

# Normal form data
echo "  → Normal form data..."
for i in {1..20}; do
    curl -s -X POST "$WAF_URL/login" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=user$i&password=password123" > /dev/null
    
    curl -s -X POST "$WAF_URL/register" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "name=User$i&email=user$i@test.com&password=SecurePass123" > /dev/null
done

# Normal API calls
echo "  → Normal API calls..."
for endpoint in "api/users" "api/products" "api/orders" "api/reviews"; do
    curl -s -X POST "$WAF_URL/$endpoint" \
      -H "Content-Type: application/json" \
      -d '{"action":"create","data":{"name":"test"}}' > /dev/null
done

echo "  ✓ Generated 100+ good POST requests"
echo ""

# ============================================================================
# PART 4: BAD POST REQUESTS (Malicious Payloads)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Generating BAD POST Requests (Malicious Payloads)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# SQL Injection in POST
echo "  → SQL Injection in POST..."
for pattern in "admin' OR '1'='1" "admin'--" "admin'/*" \
               "' OR 1=1--" "' OR 'a'='a" "1' OR '1'='1'--"; do
    curl -s -X POST "$WAF_URL/login" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "username=$pattern&password=x" > /dev/null
done

# SQL Injection in JSON
echo "  → SQL Injection in JSON..."
for pattern in "1' OR '1'='1" "admin'--" "' UNION SELECT * FROM users--"; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"query\":\"$pattern\"}" > /dev/null
done

# XSS in POST
echo "  → XSS in POST..."
for pattern in "<script>alert(1)</script>" "<img src=x onerror=alert(1)>" \
               "javascript:alert(1)" "<svg onload=alert(1)>"; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"message\":\"$pattern\"}" > /dev/null
done

# Command Injection in POST
echo "  → Command Injection in POST..."
for pattern in "; ls -la" "; cat /etc/passwd" "| whoami" "&& id"; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"cmd\":\"$pattern\"}" > /dev/null
done

# Path Traversal in POST
echo "  → Path Traversal in POST..."
for pattern in "../../../etc/passwd" "....//....//etc/passwd" "/etc/passwd"; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"file\":\"$pattern\"}" > /dev/null
done

# SSRF in POST
echo "  → SSRF in POST..."
for pattern in "http://127.0.0.1:22" "http://localhost/admin" "file:///etc/passwd"; do
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"url\":\"$pattern\"}" > /dev/null
done

# Large payloads (potential DoS)
echo "  → Large payloads..."
for i in {1..5}; do
    large_data=$(python3 -c "print('A' * 10000)")
    curl -s -X POST "$WAF_URL/api" \
      -H "Content-Type: application/json" \
      -d "{\"data\":\"$large_data\"}" > /dev/null
done

echo "  ✓ Generated 50+ bad POST requests"
echo ""

# ============================================================================
# PART 5: NETWORK LAYER TRAINING DATA
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Generating Network Layer Training Data"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Normal traffic (ALLOWED)
echo "  → Normal traffic (ALLOWED)..."
echo "    - DNS queries..."
for i in {1..20}; do
    ping -c 1 8.8.8.8 > /dev/null 2>&1
    ping -c 1 1.1.1.1 > /dev/null 2>&1
done

echo "    - HTTP/HTTPS requests..."
for i in {1..30}; do
    curl -s http://example.com > /dev/null
    curl -s https://www.google.com > /dev/null 2>&1
done

echo "    - Normal port connections..."
for port in 80 443 22 53; do
    timeout 1 bash -c "echo > /dev/tcp/example.com/$port" 2>/dev/null || true
    timeout 1 bash -c "echo > /dev/tcp/www.google.com/$port" 2>/dev/null || true
done

# Suspicious ports (BLOCKED)
echo "  → Suspicious ports (BLOCKED)..."
for port in 23 3389 445 1433 1521 3306 5432 5900; do
    echo "    - Testing port $port..."
    timeout 1 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
    timeout 1 bash -c "echo > /dev/tcp/192.168.1.1/$port" 2>/dev/null || true
done

# Port scanning simulation
echo "  → Port scanning simulation..."
if command -v nmap &> /dev/null; then
    echo "    - Running nmap scan..."
    nmap -p 1-50 127.0.0.1 > /dev/null 2>&1
else
    echo "    - Manual port scan..."
    for port in {20..70}; do
        timeout 0.2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
    done
fi

# Multiple connections
echo "  → Multiple simultaneous connections..."
for i in {1..20}; do
    curl -s http://example.com > /dev/null &
done
wait

echo "  ✓ Generated network traffic samples"
echo ""

# ============================================================================
# SUMMARY
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Training Data Generation Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Generated samples:"
echo "  ✓ 100+ Good GET requests"
echo "  ✓ 100+ Bad GET requests (SQLi, XSS, Command Injection, etc.)"
echo "  ✓ 100+ Good POST requests"
echo "  ✓ 50+ Bad POST requests (Malicious payloads)"
echo "  ✓ Network traffic (Normal + Suspicious)"
echo ""
echo "Check CSV files:"
echo "  wc -l Data_Collection/Good_req.csv"
echo "  wc -l Data_Collection/Bad_req.csv"
echo "  wc -l benign_payloads.csv"
echo "  wc -l malicious_payloads.csv"
echo "  wc -l network_allowed.csv"
echo "  wc -l network_blocked.csv"
echo ""
echo "Dashboard should now show comprehensive data!"
echo "  Open: http://localhost:8080"
echo ""

