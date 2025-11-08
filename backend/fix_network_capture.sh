#!/bin/bash
# Fix network firewall capture issues

echo "=========================================="
echo "  Network Firewall Capture Diagnostic"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
ALLOWED_CSV="$BACKEND_DIR/network_allowed.csv"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Check if network firewall is running
echo "1. Checking if network firewall is running..."
if pgrep -f "network_sniffer_fallback.py" > /dev/null; then
    echo "  ✓ Network firewall is running"
    ps aux | grep network_sniffer | grep -v grep
else
    echo "  ✗ Network firewall is NOT running"
    echo ""
    echo "  Starting network firewall..."
    cd "$BACKEND_DIR"
    source venv/bin/activate 2>/dev/null || true
    export BACKEND_ROOT="$BACKEND_DIR"
    nohup sudo -E env BACKEND_ROOT="$BACKEND_ROOT" python3 network_sniffer_fallback.py > network.log 2>&1 &
    sleep 3
    if pgrep -f "network_sniffer_fallback.py" > /dev/null; then
        echo "  ✓ Network firewall started"
    else
        echo "  ✗ Failed to start. Check: sudo python3 network_sniffer_fallback.py"
        exit 1
    fi
fi
echo ""

# Check CSV files
echo "2. Checking CSV files..."
if [ -f "$ALLOWED_CSV" ]; then
    ALLOWED_COUNT=$(tail -n +2 "$ALLOWED_CSV" 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ network_allowed.csv exists: $ALLOWED_COUNT rows"
else
    echo "  ✗ network_allowed.csv NOT found"
fi

if [ -f "$BLOCKED_CSV" ]; then
    BLOCKED_COUNT=$(tail -n +2 "$BLOCKED_CSV" 2>/dev/null | wc -l | tr -d ' ')
    echo "  ✓ network_blocked.csv exists: $BLOCKED_COUNT rows"
else
    echo "  ✗ network_blocked.csv NOT found"
fi
echo ""

# Check file permissions
echo "3. Checking file permissions..."
ls -la "$ALLOWED_CSV" "$BLOCKED_CSV" 2>/dev/null | head -2
echo ""

# Test packet generation
echo "4. Testing packet capture..."
echo "  Generating test packets..."

BEFORE_ALLOWED=$(tail -n +2 "$ALLOWED_CSV" 2>/dev/null | wc -l | tr -d ' ')
BEFORE_BLOCKED=$(tail -n +2 "$BLOCKED_CSV" 2>/dev/null | wc -l | tr -d ' ')

# Generate some test packets
echo "  → Sending ping packets..."
for i in {1..5}; do
    timeout 2 ping -c 1 8.8.8.8 > /dev/null 2>&1 &
done

echo "  → Testing suspicious ports..."
for port in 23 3389 3306; do
    timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null &
done

wait 2>/dev/null || true
sleep 3

AFTER_ALLOWED=$(tail -n +2 "$ALLOWED_CSV" 2>/dev/null | wc -l | tr -d ' ')
AFTER_BLOCKED=$(tail -n +2 "$BLOCKED_CSV" 2>/dev/null | wc -l | tr -d ' ')

ALLOWED_DIFF=$((AFTER_ALLOWED - BEFORE_ALLOWED))
BLOCKED_DIFF=$((AFTER_BLOCKED - BEFORE_BLOCKED))

echo "  Before: Allowed=$BEFORE_ALLOWED, Blocked=$BEFORE_BLOCKED"
echo "  After:  Allowed=$AFTER_ALLOWED, Blocked=$AFTER_BLOCKED"
echo "  Difference: Allowed=+$ALLOWED_DIFF, Blocked=+$BLOCKED_DIFF"
echo ""

if [ $ALLOWED_DIFF -gt 0 ] || [ $BLOCKED_DIFF -gt 0 ]; then
    echo "  ✓ Packets ARE being captured!"
else
    echo "  ✗ Packets are NOT being captured"
    echo ""
    echo "  Possible issues:"
    echo "    1. Network firewall not running with sudo"
    echo "    2. Network firewall not capturing on correct interface"
    echo "    3. CSV files not being written to correct location"
    echo ""
    echo "  Check network firewall logs:"
    echo "    tail -20 $BACKEND_DIR/network.log"
    echo ""
    echo "  Try restarting network firewall:"
    echo "    sudo pkill -f network_sniffer_fallback.py"
    echo "    cd $BACKEND_DIR"
    echo "    source venv/bin/activate"
    echo "    export BACKEND_ROOT=$BACKEND_DIR"
    echo "    sudo -E python3 network_sniffer_fallback.py"
fi
echo ""

# Check API
echo "5. Checking API..."
if curl -s http://localhost:5174/api/stats/network-firewall > /dev/null 2>&1; then
    API_RESPONSE=$(curl -s http://localhost:5174/api/stats/network-firewall)
    echo "  ✓ API is accessible"
    echo "  Response: $API_RESPONSE"
else
    echo "  ✗ API is not accessible"
    echo "  Start API: cd ~/Capstone-Project/frontend && npm run api"
fi
echo ""

# Check BACKEND_ROOT
echo "6. Checking BACKEND_ROOT..."
if [ -n "$BACKEND_ROOT" ]; then
    echo "  BACKEND_ROOT: $BACKEND_ROOT"
    if [ "$BACKEND_ROOT" = "$BACKEND_DIR" ]; then
        echo "  ✓ BACKEND_ROOT is correct"
    else
        echo "  ⚠️  BACKEND_ROOT doesn't match expected: $BACKEND_DIR"
    fi
else
    echo "  ✗ BACKEND_ROOT is not set"
    echo "  Set it: export BACKEND_ROOT=$BACKEND_DIR"
fi
echo ""

echo "=========================================="
echo "  Recommendations"
echo "=========================================="
echo ""

if [ $ALLOWED_DIFF -eq 0 ] && [ $BLOCKED_DIFF -eq 0 ]; then
    echo "1. Restart network firewall with correct BACKEND_ROOT:"
    echo "   sudo pkill -f network_sniffer_fallback.py"
    echo "   cd $BACKEND_DIR"
    echo "   source venv/bin/activate"
    echo "   export BACKEND_ROOT=$BACKEND_DIR"
    echo "   sudo -E env BACKEND_ROOT=\"\$BACKEND_ROOT\" python3 network_sniffer_fallback.py"
    echo ""
    echo "2. Check network firewall logs:"
    echo "   tail -f $BACKEND_DIR/network.log"
    echo ""
    echo "3. Verify CSV files are being written:"
    echo "   watch -n 1 'wc -l $ALLOWED_CSV $BLOCKED_CSV'"
fi

echo "4. Restart API to ensure it reads updated CSV files:"
echo "   cd ~/Capstone-Project/frontend"
echo "   export BACKEND_ROOT=$BACKEND_DIR"
echo "   pkill -f server.mjs"
echo "   npm run api"
echo ""

echo "5. Hard refresh browser: Ctrl+Shift+R"
echo ""

