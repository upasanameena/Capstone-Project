#!/bin/bash
# Complete script to start network firewall and generate training data

echo "=========================================="
echo "  Network Training Data Generator"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"

# Step 1: Start network firewall in background
echo "1. Starting network firewall in background..."
cd "$BACKEND_DIR
source venv/bin/activate
export BACKEND_ROOT="$BACKEND_DIR"

# Kill any existing network firewall
pkill -f "network_sniffer_fallback.py" 2>/dev/null
sleep 1

# Start in background
nohup sudo -E env BACKEND_ROOT="$BACKEND_ROOT" python3 network_sniffer_fallback.py > network.log 2>&1 &
NETWORK_PID=$!

sleep 2

if ps -p $NETWORK_PID > /dev/null 2>&1; then
    echo "  ✓ Network firewall started (PID: $NETWORK_PID)"
    echo "  Logs: $BACKEND_DIR/network.log"
else
    echo "  ✗ Failed to start network firewall"
    echo "  Check logs: tail -f $BACKEND_DIR/network.log"
    exit 1
fi

echo ""

# Step 2: Run training data generator
echo "2. Running training data generator..."
echo ""

chmod +x generate_network_training_data.sh
./generate_network_training_data.sh

echo ""

# Step 3: Keep firewall running or stop it
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Network firewall is still running in background (PID: $NETWORK_PID)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "To stop network firewall:"
echo "  sudo pkill -f network_sniffer_fallback.py"
echo ""
echo "To view logs:"
echo "  tail -f $BACKEND_DIR/network.log"
echo ""
echo "To check status:"
echo "  ps aux | grep network_sniffer"
echo ""

