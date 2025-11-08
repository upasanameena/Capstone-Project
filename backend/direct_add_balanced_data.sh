#!/bin/bash
# Directly add balanced training data to CSV files
# 4000 allowed, 1000 blocked

echo "=========================================="
echo "  Direct Add Balanced Training Data"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"
ALLOWED_CSV="$BACKEND_DIR/network_allowed.csv"
BLOCKED_CSV="$BACKEND_DIR/network_blocked.csv"

# Ensure CSV files exist
if [ ! -f "$ALLOWED_CSV" ]; then
    echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > "$ALLOWED_CSV"
fi

if [ ! -f "$BLOCKED_CSV" ]; then
    echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > "$BLOCKED_CSV"
fi

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

# Add allowed packets
if [ $NEED_ALLOWED -gt 0 ]; then
    echo "Adding $NEED_ALLOWED allowed packets..."
    
    BASE_TIME=$(date -u +%s)
    for ((i=0; i<NEED_ALLOWED; i++)); do
        TIMESTAMP=$(date -u -d "@$((BASE_TIME - (i % 3600)))" +"%Y-%m-%dT%H:%M:%S")
        SRC_IP="192.168.$((RANDOM % 255)).$((RANDOM % 255))"
        SRC_PORT=$((50000 + RANDOM % 10000))
        DST_PORT=$((i % 2 == 0 ? 80 : 443))  # HTTP or HTTPS
        
        echo "$TIMESTAMP,$SRC_IP,8.8.8.8,TCP,$SRC_PORT,$DST_PORT,64,ALLOW,baseline" >> "$ALLOWED_CSV"
        
        if [ $((i % 500)) -eq 0 ] && [ $i -gt 0 ]; then
            echo "  Progress: $i / $NEED_ALLOWED"
        fi
    done
    echo "  ✓ Added $NEED_ALLOWED allowed packets"
    echo ""
fi

# Add blocked packets
if [ $NEED_BLOCKED -gt 0 ]; then
    echo "Adding $NEED_BLOCKED blocked packets..."
    
    PORTS=(23 3389 445 1433 1521 3306 5432 5900 2323 1434 1522 3307 5433)
    REASONS=("suspicious_port:23" "suspicious_port:3389" "suspicious_port:445" "suspicious_port:1433" \
             "suspicious_port:1521" "suspicious_port:3306" "suspicious_port:5432" "suspicious_port:5900" \
             "suspicious_port:2323" "suspicious_port:1434" "suspicious_port:1522" "suspicious_port:3307" \
             "suspicious_port:5433")
    
    BASE_TIME=$(date -u +%s)
    for ((i=0; i<NEED_BLOCKED; i++)); do
        PORT_IDX=$((i % ${#PORTS[@]}))
        PORT=${PORTS[$PORT_IDX]}
        REASON=${REASONS[$PORT_IDX]}
        
        TIMESTAMP=$(date -u -d "@$((BASE_TIME - (i % 3600)))" +"%Y-%m-%dT%H:%M:%S")
        SRC_IP="192.168.$((RANDOM % 255)).$((RANDOM % 255))"
        SRC_PORT=$((50000 + RANDOM % 10000))
        
        echo "$TIMESTAMP,$SRC_IP,127.0.0.1,TCP,$SRC_PORT,$PORT,64,BLOCK,$REASON" >> "$BLOCKED_CSV"
        
        if [ $((i % 200)) -eq 0 ] && [ $i -gt 0 ]; then
            echo "  Progress: $i / $NEED_BLOCKED"
        fi
    done
    echo "  ✓ Added $NEED_BLOCKED blocked packets"
    echo ""
fi

# Final statistics
AFTER_ALLOWED=$(get_count "$ALLOWED_CSV")
AFTER_BLOCKED=$(get_count "$BLOCKED_CSV")
AFTER_TOTAL=$((AFTER_ALLOWED + AFTER_BLOCKED))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Final Statistics"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Allowed: $AFTER_ALLOWED"
echo "Blocked: $AFTER_BLOCKED"
echo "Total: $AFTER_TOTAL"
echo ""

if [ $AFTER_TOTAL -gt 0 ]; then
    ALLOWED_PERCENT=$((AFTER_ALLOWED * 100 / AFTER_TOTAL))
    BLOCKED_PERCENT=$((AFTER_BLOCKED * 100 / AFTER_TOTAL))
    
    echo "Ratio:"
    echo "  Allowed: $ALLOWED_PERCENT%"
    echo "  Blocked: $BLOCKED_PERCENT%"
    echo ""
fi

echo "✅ Data added successfully!"
echo ""
echo "Dashboard: http://localhost:8080"
echo "  (Hard refresh: Ctrl+Shift+R if needed)"
echo ""

