#!/bin/bash
# Generate balanced training data: 4000 allowed, 1000 blocked

echo "=========================================="
echo "  Generate Balanced Network Training Data"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
ALLOWED_CSV="$BACKEND_DIR/network_allowed.csv"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Check if network firewall is running
if ! pgrep -f "network_sniffer_fallback.py" > /dev/null; then
    echo "⚠️  Network firewall is not running!"
    echo "   Start it first:"
    echo "   cd $BACKEND_DIR"
    echo "   source venv/bin/activate"
    echo "   export BACKEND_ROOT=$BACKEND_DIR"
    echo "   sudo -E env BACKEND_ROOT=\"\$BACKEND_ROOT\" python3 network_sniffer_fallback.py &"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

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

TARGET_ALLOWED=4000
TARGET_BLOCKED=1000

NEED_ALLOWED=$((TARGET_ALLOWED - BEFORE_ALLOWED))
NEED_BLOCKED=$((TARGET_BLOCKED - BEFORE_BLOCKED))

if [ $NEED_ALLOWED -lt 0 ]; then NEED_ALLOWED=0; fi
if [ $NEED_BLOCKED -lt 0 ]; then NEED_BLOCKED=0; fi

echo "Need to generate:"
echo "  Allowed: $NEED_ALLOWED"
echo "  Blocked: $NEED_BLOCKED"
echo ""

# Generate allowed packets
if [ $NEED_ALLOWED -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Generating ALLOWED Packets ($NEED_ALLOWED)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    for ((i=0; i<NEED_ALLOWED; i+=20)); do
        CURRENT=$((NEED_ALLOWED - i < 20 ? NEED_ALLOWED - i : 20))
        
        for ((j=0; j<CURRENT; j++)); do
            timeout 1 ping -c 1 8.8.8.8 > /dev/null 2>&1 &
            timeout 1 ping -c 1 1.1.1.1 > /dev/null 2>&1 &
        done
        
        wait 2>/dev/null || true
        
        if [ $((i % 200)) -eq 0 ] || [ $i -ge $NEED_ALLOWED ]; then
            echo "  Progress: $i / $NEED_ALLOWED"
        fi
    done
    
    echo "  ✓ Generated allowed packets"
    echo ""
fi

# Generate blocked packets
if [ $NEED_BLOCKED -gt 0 ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Generating BLOCKED Packets ($NEED_BLOCKED)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    SUSPICIOUS_PORTS=(23 3389 445 1433 1521 3306 5432 5900 2323 1434 1522 3307 5433)
    
    for ((i=0; i<NEED_BLOCKED; i+=50)); do
        CURRENT=$((NEED_BLOCKED - i < 50 ? NEED_BLOCKED - i : 50))
        
        for port in "${SUSPICIOUS_PORTS[@]}"; do
            for ((j=0; j<CURRENT/${#SUSPICIOUS_PORTS[@]}; j++)); do
                timeout 0.1 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null &
                timeout 0.1 bash -c "echo > /dev/tcp/192.168.1.1/$port" 2>/dev/null &
            done
        done
        
        wait 2>/dev/null || true
        
        if [ $((i % 100)) -eq 0 ] || [ $i -ge $NEED_BLOCKED ]; then
            echo "  Progress: $i / $NEED_BLOCKED"
        fi
    done
    
    echo "  ✓ Generated blocked packets"
    echo ""
fi

# Wait for processing
echo "Waiting for network firewall to process packets..."
sleep 10

# Final statistics
AFTER_ALLOWED=$(get_count "$ALLOWED_CSV")
AFTER_BLOCKED=$(get_count "$BLOCKED_CSV")
AFTER_TOTAL=$((AFTER_ALLOWED + AFTER_BLOCKED))

ALLOWED_DIFF=$((AFTER_ALLOWED - BEFORE_ALLOWED))
BLOCKED_DIFF=$((AFTER_BLOCKED - BEFORE_BLOCKED))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Final Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Before:"
echo "  Allowed: $BEFORE_ALLOWED, Blocked: $BEFORE_BLOCKED"
echo ""
echo "After:"
echo "  Allowed: $AFTER_ALLOWED (+$ALLOWED_DIFF)"
echo "  Blocked: $AFTER_BLOCKED (+$BLOCKED_DIFF)"
echo "  Total: $AFTER_TOTAL"
echo ""

if [ $AFTER_TOTAL -gt 0 ]; then
    ALLOWED_PERCENT=$((AFTER_ALLOWED * 100 / AFTER_TOTAL))
    BLOCKED_PERCENT=$((AFTER_BLOCKED * 100 / AFTER_TOTAL))
    
    echo "Ratio:"
    echo "  Allowed: $ALLOWED_PERCENT%"
    echo "  Blocked: $BLOCKED_PERCENT%"
    echo ""
fi

if [ $AFTER_BLOCKED -ge $TARGET_BLOCKED ]; then
    echo "✅ Target reached! Blocked packets: $AFTER_BLOCKED >= $TARGET_BLOCKED"
else
    echo "⚠️  Still need more blocked packets. Run again or use generate_blocked_packets.sh"
fi

echo ""
echo "Dashboard: http://localhost:8080"
echo ""

