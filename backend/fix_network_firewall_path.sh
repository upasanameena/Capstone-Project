#!/bin/bash
# Script to fix network firewall path issue

echo "=========================================="
echo "  Fix Network Firewall Path Issue"
echo "=========================================="
echo ""

BACKEND_DIR="$HOME/Capstone-Project/backend"

echo "The network firewall is writing to the wrong directory."
echo "It should write to: $BACKEND_DIR"
echo ""

# Step 1: Stop existing network firewall
echo "1. Stopping existing network firewall..."
pkill -f "network_sniffer_fallback.py"
pkill -f "network_firewall.py"
sleep 2
echo "  ✓ Stopped"
echo ""

# Step 2: Set BACKEND_ROOT
echo "2. Setting BACKEND_ROOT environment variable..."
export BACKEND_ROOT="$BACKEND_DIR"
echo "  BACKEND_ROOT=$BACKEND_ROOT"
echo ""

# Step 3: Verify CSV files location
echo "3. Verifying CSV files will be created in correct location..."
echo "  Allowed CSV:  $BACKEND_DIR/network_allowed.csv"
echo "  Blocked CSV:  $BACKEND_DIR/network_blocked.csv"
echo ""

# Step 4: Start network firewall with correct BACKEND_ROOT
echo "4. Starting network firewall with correct BACKEND_ROOT..."
echo ""
echo "  Run this command:"
echo "  cd $BACKEND_DIR"
echo "  source venv/bin/activate"
echo "  export BACKEND_ROOT=$BACKEND_DIR"
echo "  sudo -E python3 network_sniffer_fallback.py"
echo ""
echo "  OR use this one-liner:"
echo "  cd $BACKEND_DIR && source venv/bin/activate && export BACKEND_ROOT=$BACKEND_DIR && sudo -E python3 network_sniffer_fallback.py"
echo ""

# Step 5: Add to .bashrc for persistence
echo "5. Adding BACKEND_ROOT to ~/.bashrc for persistence..."
if ! grep -q "BACKEND_ROOT.*Capstone-Project" ~/.bashrc 2>/dev/null; then
    echo "" >> ~/.bashrc
    echo "# Capstone Project - Network Firewall" >> ~/.bashrc
    echo "export BACKEND_ROOT=\$HOME/Capstone-Project/backend" >> ~/.bashrc
    echo "  ✓ Added to ~/.bashrc"
    echo "  (Run 'source ~/.bashrc' or restart terminal to apply)"
else
    echo "  ✓ Already in ~/.bashrc"
fi
echo ""

echo "=========================================="
echo "  Next Steps"
echo "=========================================="
echo ""
echo "1. Start network firewall with BACKEND_ROOT set:"
echo "   cd $BACKEND_DIR"
echo "   source venv/bin/activate"
echo "   export BACKEND_ROOT=$BACKEND_DIR"
echo "   sudo -E python3 network_sniffer_fallback.py"
echo ""
echo "2. Verify it's writing to the correct location:"
echo "   (You should see: Writing allowed => $BACKEND_DIR/network_allowed.csv)"
echo ""
echo "3. Generate test traffic:"
echo "   ping -c 5 8.8.8.8"
echo "   timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23'"
echo ""
echo "4. Check CSV files:"
echo "   tail -5 $BACKEND_DIR/network_allowed.csv"
echo "   tail -5 $BACKEND_DIR/network_blocked.csv"
echo ""
echo "5. Restart API to ensure it reads from correct location:"
echo "   cd ~/Capstone-Project/frontend"
echo "   export BACKEND_ROOT=$BACKEND_DIR"
echo "   pkill -f server.mjs"
echo "   npm run api"
echo ""

