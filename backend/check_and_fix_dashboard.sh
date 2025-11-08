#!/bin/bash
# Script to diagnose and fix dashboard update issues

echo "=========================================="
echo "  Dashboard Update Diagnostic & Fix"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
FRONTEND_DIR="$HOME/Capstone-Project/frontend"

# Step 1: Check if services are running
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Checking if services are running..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

WAF_RUNNING=$(pgrep -f "Proxy_server.py" | wc -l)
NETWORK_RUNNING=$(pgrep -f "network_sniffer" | wc -l)
API_RUNNING=$(pgrep -f "server.mjs" | wc -l)
UI_RUNNING=$(pgrep -f "vite" | wc -l)

echo "  WAF (Proxy_server.py):        $([ $WAF_RUNNING -gt 0 ] && echo "✓ Running" || echo "✗ Not running")"
echo "  Network Firewall:            $([ $NETWORK_RUNNING -gt 0 ] && echo "✓ Running" || echo "✗ Not running")"
echo "  API Server (server.mjs):      $([ $API_RUNNING -gt 0 ] && echo "✓ Running" || echo "✗ Not running")"
echo "  UI Server (vite):            $([ $UI_RUNNING -gt 0 ] && echo "✓ Running" || echo "✗ Not running")"
echo ""

# Step 2: Check CSV files
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2. Checking CSV files..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

check_csv() {
    local file=$1
    local name=$2
    if [ -f "$file" ]; then
        local lines=$(wc -l < "$file" | tr -d ' ')
        local size=$(ls -lh "$file" | awk '{print $5}')
        local modified=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || stat -f "%Sm" "$file" 2>/dev/null)
        echo "  ✓ $name: $lines lines, $size, modified: $modified"
        return 0
    else
        echo "  ✗ $name: NOT FOUND"
        return 1
    fi
}

check_csv "$BACKEND_DIR/Data_Collection/Good_req.csv" "Good_req.csv"
check_csv "$BACKEND_DIR/Data_Collection/Bad_req.csv" "Bad_req.csv"
check_csv "$BACKEND_DIR/benign_payloads.csv" "benign_payloads.csv"
check_csv "$BACKEND_DIR/malicious_payloads.csv" "malicious_payloads.csv"
check_csv "$BACKEND_DIR/network_allowed.csv" "network_allowed.csv"
check_csv "$BACKEND_DIR/network_blocked.csv" "network_blocked.csv"
echo ""

# Step 3: Check BACKEND_ROOT environment variable
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3. Checking BACKEND_ROOT environment variable..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ -z "$BACKEND_ROOT" ]; then
    echo "  ✗ BACKEND_ROOT is NOT set"
    echo "  → Setting it to: $BACKEND_DIR"
    export BACKEND_ROOT="$BACKEND_DIR"
else
    echo "  ✓ BACKEND_ROOT is set to: $BACKEND_ROOT"
    if [ "$BACKEND_ROOT" != "$BACKEND_DIR" ]; then
        echo "  ⚠️  WARNING: BACKEND_ROOT doesn't match expected path!"
        echo "     Expected: $BACKEND_DIR"
        echo "     Current:  $BACKEND_ROOT"
    fi
fi
echo ""

# Step 4: Test API endpoints
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4. Testing API endpoints..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

test_api() {
    local endpoint=$1
    local name=$2
    if curl -s "$endpoint" > /dev/null 2>&1; then
        local response=$(curl -s "$endpoint")
        echo "  ✓ $name: $response"
        return 0
    else
        echo "  ✗ $name: Cannot connect"
        return 1
    fi
}

test_api "http://localhost:5174/api/stats/get-requests" "GET Requests"
test_api "http://localhost:5174/api/stats/post-payloads" "POST Payloads"
test_api "http://localhost:5174/api/stats/network-firewall" "Network Firewall"
test_api "http://localhost:5174/api/debug/paths" "Debug Paths"
echo ""

# Step 5: Check if CSV files are being updated
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5. Checking if CSV files are being updated..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

get_csv_count() {
    local file=$1
    if [ -f "$file" ]; then
        # Count data rows (excluding header)
        local count=$(tail -n +2 "$file" 2>/dev/null | wc -l | tr -d ' ')
        echo "$count"
    else
        echo "0"
    fi
}

echo "  Current counts:"
echo "    Good URLs:        $(get_csv_count "$BACKEND_DIR/Data_Collection/Good_req.csv")"
echo "    Bad URLs:         $(get_csv_count "$BACKEND_DIR/Data_Collection/Bad_req.csv")"
echo "    Benign Payloads:  $(get_csv_count "$BACKEND_DIR/benign_payloads.csv")"
echo "    Malicious:        $(get_csv_count "$BACKEND_DIR/malicious_payloads.csv")"
echo "    Allowed Packets:  $(get_csv_count "$BACKEND_DIR/network_allowed.csv")"
echo "    Blocked Packets:  $(get_csv_count "$BACKEND_DIR/network_blocked.csv")"
echo ""

# Step 6: Generate test data and monitor
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6. Generating test data and monitoring updates..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "  Before test:"
BEFORE_GOOD=$(get_csv_count "$BACKEND_DIR/Data_Collection/Good_req.csv")
BEFORE_BAD=$(get_csv_count "$BACKEND_DIR/Data_Collection/Bad_req.csv")
BEFORE_ALLOWED=$(get_csv_count "$BACKEND_DIR/network_allowed.csv")
BEFORE_BLOCKED=$(get_csv_count "$BACKEND_DIR/network_blocked.csv")

echo "    Good URLs: $BEFORE_GOOD, Bad URLs: $BEFORE_BAD"
echo "    Allowed: $BEFORE_ALLOWED, Blocked: $BEFORE_BLOCKED"
echo ""

echo "  → Sending test requests..."
# Test WAF
curl -s 'http://127.0.0.1:8081/?q=test123' > /dev/null 2>&1
curl -s 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--' > /dev/null 2>&1

# Test network (if network firewall is running)
if [ $NETWORK_RUNNING -gt 0 ]; then
    ping -c 3 8.8.8.8 > /dev/null 2>&1
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23' 2>/dev/null || true
fi

sleep 2

echo "  After test:"
AFTER_GOOD=$(get_csv_count "$BACKEND_DIR/Data_Collection/Good_req.csv")
AFTER_BAD=$(get_csv_count "$BACKEND_DIR/Data_Collection/Bad_req.csv")
AFTER_ALLOWED=$(get_csv_count "$BACKEND_DIR/network_allowed.csv")
AFTER_BLOCKED=$(get_csv_count "$BACKEND_DIR/network_blocked.csv")

echo "    Good URLs: $AFTER_GOOD, Bad URLs: $AFTER_BAD"
echo "    Allowed: $AFTER_ALLOWED, Blocked: $AFTER_BLOCKED"
echo ""

if [ "$BEFORE_GOOD" != "$AFTER_GOOD" ] || [ "$BEFORE_BAD" != "$AFTER_BAD" ]; then
    echo "  ✓ CSV files ARE being updated!"
else
    echo "  ✗ CSV files are NOT being updated"
    echo "    → Check if WAF is running and processing requests"
fi

if [ "$BEFORE_ALLOWED" != "$AFTER_ALLOWED" ] || [ "$BEFORE_BLOCKED" != "$AFTER_BLOCKED" ]; then
    echo "  ✓ Network CSV files ARE being updated!"
else
    echo "  ✗ Network CSV files are NOT being updated"
    echo "    → Check if network firewall is running with sudo"
fi
echo ""

# Step 7: Recommendations
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7. Recommendations"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $API_RUNNING -eq 0 ]; then
    echo "  ⚠️  API is not running. Start it with:"
    echo "     cd $FRONTEND_DIR"
    echo "     export BACKEND_ROOT=$BACKEND_DIR"
    echo "     npm run api"
    echo ""
fi

if [ $NETWORK_RUNNING -eq 0 ]; then
    echo "  ⚠️  Network firewall is not running. Start it with:"
    echo "     cd $BACKEND_DIR"
    echo "     source venv/bin/activate"
    echo "     sudo -E python3 network_sniffer_fallback.py"
    echo ""
fi

if [ -z "$BACKEND_ROOT" ] || [ "$BACKEND_ROOT" != "$BACKEND_DIR" ]; then
    echo "  ⚠️  BACKEND_ROOT needs to be set. Add to your ~/.bashrc:"
    echo "     export BACKEND_ROOT=$BACKEND_DIR"
    echo "     Then restart API: pkill -f server.mjs && cd $FRONTEND_DIR && npm run api"
    echo ""
fi

echo "  → To force dashboard refresh:"
echo "    1. Hard refresh browser: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "    2. Check browser console (F12) for errors"
echo "    3. Verify API response: curl http://localhost:5174/api/stats/get-requests"
echo ""

echo "=========================================="
echo "  Diagnostic Complete"
echo "=========================================="

