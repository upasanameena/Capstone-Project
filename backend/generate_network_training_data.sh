#!/bin/bash
# Comprehensive Network Layer Training Data Generator
# Generates 4500-5000 packets with visible allowed/blocked ratio

echo "=========================================="
echo "  Network Layer Training Data Generator"
echo "=========================================="
echo ""
echo "Target: 4500-5000 total packets"
echo "Ratio: ~80% Allowed, ~20% Blocked"
echo ""

# Check if network firewall is running
if ! pgrep -f "network_sniffer_fallback.py" > /dev/null && ! pgrep -f "network_firewall.py" > /dev/null; then
    echo "⚠️  WARNING: Network firewall doesn't appear to be running!"
    echo "   Please start it first:"
    echo "   cd ~/Capstone-Project/backend"
    echo "   source venv/bin/activate"
    echo "   export BACKEND_ROOT=\$HOME/Capstone-Project/backend"
    echo "   sudo -E python3 network_sniffer_fallback.py"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✓ Network firewall check passed"
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
ALLOWED_CSV="$BACKEND_DIR/network_allowed.csv"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Get current counts
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
BEFORE_TOTAL=$((BEFORE_ALLOWED + BEFORE_BLOCKED))

echo "Current counts:"
echo "  Allowed: $BEFORE_ALLOWED"
echo "  Blocked: $BEFORE_BLOCKED"
echo "  Total: $BEFORE_TOTAL"
echo ""

TARGET_TOTAL=5000
TARGET_ALLOWED=4000  # 80%
TARGET_BLOCKED=1000  # 20%

NEED_ALLOWED=$((TARGET_ALLOWED - BEFORE_ALLOWED))
NEED_BLOCKED=$((TARGET_BLOCKED - BEFORE_BLOCKED))

if [ $NEED_ALLOWED -lt 0 ]; then
    NEED_ALLOWED=0
fi
if [ $NEED_BLOCKED -lt 0 ]; then
    NEED_BLOCKED=0
fi

echo "Need to generate:"
echo "  Allowed: $NEED_ALLOWED packets"
echo "  Blocked: $NEED_BLOCKED packets"
echo ""

# ============================================================================
# GENERATE ALLOWED PACKETS (Normal Traffic)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generating ALLOWED Packets (Normal Traffic)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

ALLOWED_GENERATED=0
BATCH_SIZE=50

# Function to generate allowed packets
generate_allowed() {
    local count=$1
    local batch=$2
    local generated=0
    
    for ((i=0; i<count; i+=batch)); do
        local current_batch=$((count - i < batch ? count - i : batch))
        
        # DNS queries (ping)
        for ((j=0; j<current_batch/4; j++)); do
            timeout 1 ping -c 1 8.8.8.8 > /dev/null 2>&1 &
            timeout 1 ping -c 1 1.1.1.1 > /dev/null 2>&1 &
            timeout 1 ping -c 1 208.67.222.222 > /dev/null 2>&1 &
            timeout 1 ping -c 1 9.9.9.9 > /dev/null 2>&1 &
        done
        
        # HTTP requests
        for ((j=0; j<current_batch/4; j++)); do
            timeout 2 curl -s http://example.com > /dev/null 2>&1 &
            timeout 2 curl -s http://httpbin.org/get > /dev/null 2>&1 &
        done
        
        # Normal port connections
        for port in 80 443 22 53; do
            for ((j=0; j<current_batch/16; j++)); do
                timeout 0.5 bash -c "echo > /dev/tcp/example.com/$port" 2>/dev/null &
                timeout 0.5 bash -c "echo > /dev/tcp/www.google.com/$port" 2>/dev/null &
            done
        done
        
        wait 2>/dev/null || true
        generated=$((generated + current_batch))
        
        # Progress update
        if [ $((generated % 200)) -eq 0 ] || [ $generated -ge $count ]; then
            echo "  Progress: $generated / $count allowed packets generated"
        fi
    done
    
    echo $generated
}

if [ $NEED_ALLOWED -gt 0 ]; then
    echo "Generating $NEED_ALLOWED allowed packets..."
    ALLOWED_GENERATED=$(generate_allowed $NEED_ALLOWED $BATCH_SIZE)
    echo "  ✓ Generated $ALLOWED_GENERATED allowed packets"
else
    echo "  ✓ Already have enough allowed packets ($BEFORE_ALLOWED >= $TARGET_ALLOWED)"
fi

echo ""

# ============================================================================
# GENERATE BLOCKED PACKETS (Suspicious Traffic)
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Generating BLOCKED Packets (Suspicious Traffic)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

BLOCKED_GENERATED=0

# Suspicious ports that will be blocked
SUSPICIOUS_PORTS=(23 3389 445 1433 1521 3306 5432 5900 2323 1434 1522 3307 5433)

# Function to generate blocked packets
generate_blocked() {
    local count=$1
    local generated=0
    
    echo "  Generating $count blocked packets..."
    
    # Generate in batches
    for ((i=0; i<count; i+=10)); do
        local current_batch=$((count - i < 10 ? count - i : 10))
        
        # Connect to suspicious ports
        for ((j=0; j<current_batch; j++)); do
            local port=${SUSPICIOUS_PORTS[$((j % ${#SUSPICIOUS_PORTS[@]}))]}
            timeout 0.3 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null &
            timeout 0.3 bash -c "echo > /dev/tcp/192.168.1.1/$port" 2>/dev/null &
            timeout 0.3 bash -c "echo > /dev/tcp/10.0.0.1/$port" 2>/dev/null &
        done
        
        wait 2>/dev/null || true
        generated=$((generated + current_batch * 3))
        
        # Progress update
        if [ $((generated % 50)) -eq 0 ] || [ $generated -ge $count ]; then
            echo "    Progress: $generated / $count blocked packets generated"
        fi
    done
    
    echo $generated
}

if [ $NEED_BLOCKED -gt 0 ]; then
    BLOCKED_GENERATED=$(generate_blocked $NEED_BLOCKED)
    echo "  ✓ Generated $BLOCKED_GENERATED blocked packets"
else
    echo "  ✓ Already have enough blocked packets ($BEFORE_BLOCKED >= $TARGET_BLOCKED)"
fi

echo ""

# Wait for network firewall to process
echo "Waiting for network firewall to process packets..."
sleep 10

# Verify packets were captured
echo ""
echo "Verifying packet capture..."
CURRENT_ALLOWED=$(get_count "$ALLOWED_CSV")
CURRENT_BLOCKED=$(get_count "$BLOCKED_CSV")

if [ $CURRENT_ALLOWED -eq $BEFORE_ALLOWED ] && [ $CURRENT_BLOCKED -eq $BEFORE_BLOCKED ]; then
    echo "⚠️  WARNING: No new packets detected!"
    echo "   This means the network firewall may not be capturing packets."
    echo "   Check:"
    echo "     1. Is network firewall running? (ps aux | grep network_sniffer)"
    echo "     2. Is it running with sudo? (required for packet capture)"
    echo "     3. Check logs: tail -f $BACKEND_DIR/network.log"
    echo ""
    echo "   Try restarting network firewall:"
    echo "     sudo pkill -f network_sniffer_fallback.py"
    echo "     cd $BACKEND_DIR"
    echo "     source venv/bin/activate"
    echo "     export BACKEND_ROOT=$BACKEND_DIR"
    echo "     sudo -E env BACKEND_ROOT=\"\$BACKEND_ROOT\" python3 network_sniffer_fallback.py"
    echo ""
fi

# ============================================================================
# FINAL STATISTICS
# ============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Final Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

AFTER_ALLOWED=$(get_count "$ALLOWED_CSV")
AFTER_BLOCKED=$(get_count "$BLOCKED_CSV")
AFTER_TOTAL=$((AFTER_ALLOWED + AFTER_BLOCKED))

ALLOWED_DIFF=$((AFTER_ALLOWED - BEFORE_ALLOWED))
BLOCKED_DIFF=$((AFTER_BLOCKED - BEFORE_BLOCKED))

echo "Before:"
echo "  Allowed: $BEFORE_ALLOWED"
echo "  Blocked: $BEFORE_BLOCKED"
echo "  Total: $BEFORE_TOTAL"
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

if [ $AFTER_TOTAL -ge $TARGET_TOTAL ]; then
    echo "✅ Target reached! ($AFTER_TOTAL >= $TARGET_TOTAL packets)"
else
    echo "⚠️  Target not yet reached ($AFTER_TOTAL < $TARGET_TOTAL packets)"
    echo "   Run the script again to generate more packets"
fi

echo ""
echo "Check dashboard: http://localhost:8080"
echo "  (Dashboard auto-refreshes every 5 seconds)"
echo ""

