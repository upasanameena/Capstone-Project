#!/bin/bash
# Force dashboard to update by restarting API and clearing any caches

echo "=========================================="
echo "  Force Dashboard Update"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
FRONTEND_DIR="$HOME/Capstone-Project/frontend"

# Step 1: Restart API with correct BACKEND_ROOT
echo "1. Restarting API server with correct BACKEND_ROOT..."
echo ""

# Kill existing API
pkill -f "server.mjs" 2>/dev/null
sleep 1

# Start API with correct environment
cd "$FRONTEND_DIR"
export BACKEND_ROOT="$BACKEND_DIR"

echo "  BACKEND_ROOT set to: $BACKEND_ROOT"
echo "  Starting API server..."

# Start API in background
nohup node server.mjs > api.log 2>&1 &
API_PID=$!

sleep 2

if ps -p $API_PID > /dev/null; then
    echo "  ✓ API started (PID: $API_PID)"
else
    echo "  ✗ API failed to start. Check api.log"
    exit 1
fi

echo ""

# Step 2: Verify API can read CSV files
echo "2. Verifying API can read CSV files..."
echo ""

sleep 1

# Test API endpoints
echo "  Testing API endpoints:"
GET_RESPONSE=$(curl -s "http://localhost:5174/api/stats/get-requests" 2>/dev/null)
POST_RESPONSE=$(curl -s "http://localhost:5174/api/stats/post-payloads" 2>/dev/null)
NET_RESPONSE=$(curl -s "http://localhost:5174/api/stats/network-firewall" 2>/dev/null)

if [ -n "$GET_RESPONSE" ]; then
    echo "  ✓ GET Requests API: $GET_RESPONSE"
else
    echo "  ✗ GET Requests API: Failed"
fi

if [ -n "$POST_RESPONSE" ]; then
    echo "  ✓ POST Payloads API: $POST_RESPONSE"
else
    echo "  ✗ POST Payloads API: Failed"
fi

if [ -n "$NET_RESPONSE" ]; then
    echo "  ✓ Network Firewall API: $NET_RESPONSE"
else
    echo "  ✗ Network Firewall API: Failed"
fi

echo ""

# Step 3: Check debug endpoint
echo "3. Checking API debug endpoint..."
echo ""
DEBUG_RESPONSE=$(curl -s "http://localhost:5174/api/debug/paths" 2>/dev/null)
if [ -n "$DEBUG_RESPONSE" ]; then
    echo "  ✓ Debug endpoint accessible"
    echo "$DEBUG_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$DEBUG_RESPONSE"
else
    echo "  ✗ Debug endpoint failed"
fi

echo ""

# Step 4: Generate fresh test data
echo "4. Generating fresh test data..."
echo ""

# Generate WAF data
echo "  → Sending requests to WAF..."
for i in {1..5}; do
    curl -s "http://127.0.0.1:8081/?q=test$i" > /dev/null 2>&1
    curl -s "http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--$i" > /dev/null 2>&1
done

# Generate network data (if network firewall is running)
if pgrep -f "network_sniffer" > /dev/null; then
    echo "  → Generating network traffic..."
    ping -c 5 8.8.8.8 > /dev/null 2>&1
    for port in 23 3389 3306; do
        timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
    done
fi

sleep 2

# Step 5: Check if data was written
echo "5. Verifying data was written..."
echo ""

check_count() {
    local file=$1
    local name=$2
    if [ -f "$file" ]; then
        local count=$(tail -n +2 "$file" 2>/dev/null | wc -l | tr -d ' ')
        echo "  $name: $count rows"
    else
        echo "  $name: File not found"
    fi
}

check_count "$BACKEND_DIR/Data_Collection/Good_req.csv" "Good_req.csv"
check_count "$BACKEND_DIR/Data_Collection/Bad_req.csv" "Bad_req.csv"
check_count "$BACKEND_DIR/network_allowed.csv" "network_allowed.csv"
check_count "$BACKEND_DIR/network_blocked.csv" "network_blocked.csv"

echo ""

# Step 6: Force API to re-read files
echo "6. Forcing API to re-read CSV files..."
echo ""

# Make a request to each endpoint to trigger file reads
curl -s "http://localhost:5174/api/stats/get-requests" > /dev/null
curl -s "http://localhost:5174/api/stats/post-payloads" > /dev/null
curl -s "http://localhost:5174/api/stats/network-firewall" > /dev/null

echo "  ✓ API endpoints refreshed"
echo ""

# Step 7: Instructions
echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""
echo "1. Hard refresh your browser:"
echo "   - Chrome/Edge: Ctrl+Shift+R (or Cmd+Shift+R on Mac)"
echo "   - Firefox: Ctrl+F5"
echo ""
echo "2. Check browser console (F12) for any errors"
echo ""
echo "3. Verify API is returning updated data:"
echo "   curl http://localhost:5174/api/stats/get-requests"
echo "   curl http://localhost:5174/api/stats/network-firewall"
echo ""
echo "4. If still not updating, check:"
echo "   - API logs: tail -f $FRONTEND_DIR/api.log"
echo "   - WAF logs: tail -f $BACKEND_DIR/waf.log"
echo "   - Network logs: tail -f $BACKEND_DIR/network.log"
echo ""
echo "5. Make sure BACKEND_ROOT is set in API process:"
echo "   ps aux | grep server.mjs"
echo "   (Should show BACKEND_ROOT in environment)"
echo ""

