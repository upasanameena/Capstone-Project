#!/bin/bash
# Test if network firewall is capturing packets

echo "=========================================="
echo "  Network Packet Capture Test"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
ALLOWED_CSV="$BACKEND_DIR/network_allowed.csv"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Check if network firewall is running
if ! pgrep -f "network_sniffer_fallback.py" > /dev/null; then
    echo "✗ Network firewall is NOT running"
    echo ""
    echo "Start it with:"
    echo "  cd $BACKEND_DIR"
    echo "  source venv/bin/activate"
    echo "  export BACKEND_ROOT=$BACKEND_DIR"
    echo "  sudo -E env BACKEND_ROOT=\"\$BACKEND_ROOT\" python3 network_sniffer_fallback.py"
    exit 1
fi

echo "✓ Network firewall is running"
echo ""

# Get initial counts
get_count() {
    local file=$1
    if [ -f "$file" ]; then
        tail -n +2 "$file" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

BEFORE_ALLOWED=$(get_count "$ALLOWED_CSV")
BEFORE_BLOCKED=$(get_count "$BLOCKED_CSV")

echo "Current counts:"
echo "  Allowed: $BEFORE_ALLOWED"
echo "  Blocked: $BEFORE_BLOCKED"
echo ""

# Generate test traffic
echo "Generating test traffic..."
echo ""

echo "1. Normal traffic (should be ALLOWED)..."
for i in {1..10}; do
    timeout 1 ping -c 1 8.8.8.8 > /dev/null 2>&1 &
    timeout 1 ping -c 1 1.1.1.1 > /dev/null 2>&1 &
done

echo "2. Suspicious ports (should be BLOCKED)..."
for port in 23 3389 3306; do
    for i in {1..5}; do
        timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null &
    done
done

wait 2>/dev/null || true

echo ""
echo "Waiting for packets to be processed..."
sleep 5

# Check if counts increased
AFTER_ALLOWED=$(get_count "$ALLOWED_CSV")
AFTER_BLOCKED=$(get_count "$BLOCKED_CSV")

ALLOWED_DIFF=$((AFTER_ALLOWED - BEFORE_ALLOWED))
BLOCKED_DIFF=$((AFTER_BLOCKED - BEFORE_BLOCKED))

echo "Results:"
echo "  Before: Allowed=$BEFORE_ALLOWED, Blocked=$BEFORE_BLOCKED"
echo "  After:  Allowed=$AFTER_ALLOWED, Blocked=$AFTER_BLOCKED"
echo "  Difference: Allowed=+$ALLOWED_DIFF, Blocked=+$BLOCKED_DIFF"
echo ""

if [ $ALLOWED_DIFF -gt 0 ] || [ $BLOCKED_DIFF -gt 0 ]; then
    echo "✅ SUCCESS: Packets ARE being captured!"
    echo ""
    echo "Recent entries:"
    echo "  Allowed (last 3):"
    tail -3 "$ALLOWED_CSV" 2>/dev/null | head -3
    echo ""
    echo "  Blocked (last 3):"
    tail -3 "$BLOCKED_CSV" 2>/dev/null | head -3
else
    echo "❌ FAILED: No packets captured"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if network firewall is running with sudo:"
    echo "   ps aux | grep network_sniffer"
    echo ""
    echo "2. Check network firewall logs:"
    echo "   tail -20 $BACKEND_DIR/network.log"
    echo ""
    echo "3. Try running network firewall in foreground to see errors:"
    echo "   sudo -E env BACKEND_ROOT=\"$BACKEND_DIR\" python3 network_sniffer_fallback.py"
    echo ""
    echo "4. Check network interface:"
    echo "   ip link show"
    echo "   # Try setting specific interface:"
    echo "   export IFACE=eth0  # or your interface name"
    echo ""
    echo "5. Test if scapy can capture packets:"
    echo "   sudo python3 -c \"from scapy.all import sniff; sniff(count=1, timeout=2)\""
fi
echo ""

