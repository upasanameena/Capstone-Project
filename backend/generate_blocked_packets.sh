#!/bin/bash
# Generate blocked packets by connecting to suspicious ports

echo "=========================================="
echo "  Generate Blocked Packets"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Get current blocked count
get_count() {
    local file=$1
    if [ -f "$file" ]; then
        tail -n +2 "$file" 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

BEFORE_BLOCKED=$(get_count "$BLOCKED_CSV")
echo "Current blocked packets: $BEFORE_BLOCKED"
echo ""

# Suspicious ports that will be blocked
SUSPICIOUS_PORTS=(23 3389 445 1433 1521 3306 5432 5900 2323 1434 1522 3307 5433)

TARGET_BLOCKED=1000
NEED_BLOCKED=$((TARGET_BLOCKED - BEFORE_BLOCKED))

if [ $NEED_BLOCKED -le 0 ]; then
    echo "Already have enough blocked packets ($BEFORE_BLOCKED >= $TARGET_BLOCKED)"
    exit 0
fi

echo "Generating $NEED_BLOCKED blocked packets..."
echo ""

# Generate blocked packets by connecting to suspicious ports
GENERATED=0
BATCH_SIZE=50

for ((i=0; i<NEED_BLOCKED; i+=BATCH_SIZE)); do
    CURRENT_BATCH=$((NEED_BLOCKED - i < BATCH_SIZE ? NEED_BLOCKED - i : BATCH_SIZE))
    
    echo "  Generating batch: $((i + 1))-$((i + CURRENT_BATCH)) / $NEED_BLOCKED"
    
    # Connect to each suspicious port multiple times
    for port in "${SUSPICIOUS_PORTS[@]}"; do
        for ((j=0; j<CURRENT_BATCH/${#SUSPICIOUS_PORTS[@]}; j++)); do
            # Try connecting to localhost
            timeout 0.1 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null &
            # Try connecting to common internal IPs
            timeout 0.1 bash -c "echo > /dev/tcp/192.168.1.1/$port" 2>/dev/null &
            timeout 0.1 bash -c "echo > /dev/tcp/10.0.0.1/$port" 2>/dev/null &
        done
    done
    
    wait 2>/dev/null || true
    GENERATED=$((GENERATED + CURRENT_BATCH))
    
    # Progress update
    if [ $((GENERATED % 100)) -eq 0 ] || [ $GENERATED -ge $NEED_BLOCKED ]; then
        echo "    Progress: $GENERATED / $NEED_BLOCKED"
    fi
done

echo ""
echo "Waiting for network firewall to process..."
sleep 5

# Check final count
AFTER_BLOCKED=$(get_count "$BLOCKED_CSV")
BLOCKED_DIFF=$((AFTER_BLOCKED - BEFORE_BLOCKED))

echo ""
echo "Results:"
echo "  Before: $BEFORE_BLOCKED blocked packets"
echo "  After:  $AFTER_BLOCKED blocked packets"
echo "  Added:  +$BLOCKED_DIFF blocked packets"
echo ""

if [ $BLOCKED_DIFF -gt 0 ]; then
    echo "✓ Successfully generated blocked packets!"
else
    echo "⚠️  No new blocked packets detected"
    echo "   Make sure network firewall is running:"
    echo "   ps aux | grep network_sniffer"
fi

echo ""
echo "Check dashboard: http://localhost:8080"
echo ""

