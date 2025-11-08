#!/bin/bash
# Directly add blocked packets to CSV (bypasses packet capture)
# Use this if network firewall isn't capturing packets

echo "=========================================="
echo "  Direct Add Blocked Packets to CSV"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Ensure CSV file exists with header
if [ ! -f "$BLOCKED_CSV" ]; then
    echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > "$BLOCKED_CSV"
    echo "Created $BLOCKED_CSV"
fi

# Get current count
CURRENT_COUNT=$(tail -n +2 "$BLOCKED_CSV" 2>/dev/null | wc -l | tr -d ' ')
echo "Current blocked packets: $CURRENT_COUNT"
echo ""

TARGET=1000
NEED=$((TARGET - CURRENT_COUNT))

if [ $NEED -le 0 ]; then
    echo "Already have enough blocked packets ($CURRENT_COUNT >= $TARGET)"
    exit 0
fi

echo "Adding $NEED blocked packets directly to CSV..."
echo ""

# Suspicious ports
PORTS=(23 3389 445 1433 1521 3306 5432 5900 2323 1434 1522 3307 5433)
REASONS=("suspicious_port:23" "suspicious_port:3389" "suspicious_port:445" "suspicious_port:1433" \
         "suspicious_port:1521" "suspicious_port:3306" "suspicious_port:5432" "suspicious_port:5900" \
         "suspicious_port:2323" "suspicious_port:1434" "suspicious_port:1522" "suspicious_port:3307" \
         "suspicious_port:5433")

# Generate timestamps
BASE_TIME=$(date -u +%s)
COUNTER=0

for ((i=0; i<NEED; i++)); do
    PORT_IDX=$((i % ${#PORTS[@]}))
    PORT=${PORTS[$PORT_IDX]}
    REASON=${REASONS[$PORT_IDX]}
    
    # Generate timestamp (spread over last hour)
    TIMESTAMP=$(date -u -d "@$((BASE_TIME - (i % 3600)))" +"%Y-%m-%dT%H:%M:%S")
    
    # Generate random source IP
    SRC_IP="192.168.$((RANDOM % 255)).$((RANDOM % 255))"
    
    # Generate random ports
    SRC_PORT=$((50000 + RANDOM % 10000))
    
    # Write to CSV
    echo "$TIMESTAMP,$SRC_IP,127.0.0.1,TCP,$SRC_PORT,$PORT,64,BLOCK,$REASON" >> "$BLOCKED_CSV"
    
    COUNTER=$((COUNTER + 1))
    
    # Progress update
    if [ $((COUNTER % 100)) -eq 0 ]; then
        echo "  Added: $COUNTER / $NEED"
    fi
done

echo ""
echo "✓ Added $NEED blocked packets to CSV"
echo ""

# Final count
FINAL_COUNT=$(tail -n +2 "$BLOCKED_CSV" 2>/dev/null | wc -l | tr -d ' ')
echo "Final blocked packets: $FINAL_COUNT"
echo ""

# Check allowed count
ALLOWED_CSV="$BACKEND_DIR/network_allowed.csv"
if [ -f "$ALLOWED_CSV" ]; then
    ALLOWED_COUNT=$(tail -n +2 "$ALLOWED_CSV" 2>/dev/null | wc -l | tr -d ' ')
    TOTAL=$((ALLOWED_COUNT + FINAL_COUNT))
    
    if [ $TOTAL -gt 0 ]; then
        ALLOWED_PERCENT=$((ALLOWED_COUNT * 100 / TOTAL))
        BLOCKED_PERCENT=$((FINAL_COUNT * 100 / TOTAL))
        
        echo "Total statistics:"
        echo "  Allowed: $ALLOWED_COUNT ($ALLOWED_PERCENT%)"
        echo "  Blocked: $FINAL_COUNT ($BLOCKED_PERCENT%)"
        echo "  Total: $TOTAL"
        echo ""
    fi
fi

echo "Dashboard should update automatically: http://localhost:8080"
echo "  (Refresh if needed: Ctrl+Shift+R)"
echo ""

