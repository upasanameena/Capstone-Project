#!/bin/bash
set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "$0")" && pwd)"
FRONTEND_DIR="$(cd "$BACKEND_DIR/../frontend" && pwd)"

echo "=========================================="
echo "  ML-Driven Dual-Layer Firewall Startup"
echo "=========================================="
echo ""

# Check if venv exists
if [ ! -d "$BACKEND_DIR/venv" ]; then
    echo "[1/6] Creating Python virtual environment..."
    cd "$BACKEND_DIR"
    python3 -m venv venv
    source venv/bin/activate
    pip install --upgrade pip wheel setuptools
    pip install numpy pandas scikit-learn joblib scapy
    echo "✅ Virtual environment created"
else
    echo "[1/6] Virtual environment already exists"
fi

# Activate venv
source "$BACKEND_DIR/venv/bin/activate"

# Check if model exists
if [ ! -f "$BACKEND_DIR/training_model.pkl" ]; then
    echo "⚠️  WARNING: training_model.pkl not found!"
    echo "   The WAF will fail without a trained model."
    echo "   Please ensure the model file exists."
    read -p "   Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ensure Data_Collection directory exists
mkdir -p "$BACKEND_DIR/Data_Collection"

# Initialize CSV files if they don't exist
if [ ! -f "$BACKEND_DIR/Data_Collection/Good_req.csv" ]; then
    echo "method,path,timestamp" > "$BACKEND_DIR/Data_Collection/Good_req.csv"
fi
if [ ! -f "$BACKEND_DIR/Data_Collection/Bad_req.csv" ]; then
    echo "method,path,timestamp" > "$BACKEND_DIR/Data_Collection/Bad_req.csv"
fi
if [ ! -f "$BACKEND_DIR/benign_payloads.csv" ]; then
    touch "$BACKEND_DIR/benign_payloads.csv"
fi
if [ ! -f "$BACKEND_DIR/malicious_payloads.csv" ]; then
    touch "$BACKEND_DIR/malicious_payloads.csv"
fi
if [ ! -f "$BACKEND_DIR/network_allowed.csv" ]; then
    echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > "$BACKEND_DIR/network_allowed.csv"
fi
if [ ! -f "$BACKEND_DIR/network_blocked.csv" ]; then
    echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > "$BACKEND_DIR/network_blocked.csv"
fi

echo "[2/6] CSV files initialized"

# Kill any existing processes
echo "[3/6] Cleaning up existing processes..."
pkill -f "Proxy_server.py" 2>/dev/null || true
pkill -f "network_sniffer_fallback.py" 2>/dev/null || true
pkill -f "server.mjs" 2>/dev/null || true
pkill -f "vite" 2>/dev/null || true
sleep 2

# Start WAF (Application Layer)
echo "[4/6] Starting WAF (Application Layer) on port 8081..."
cd "$BACKEND_DIR"
export BACKEND_ROOT="$BACKEND_DIR"
nohup python Proxy_server.py > waf.log 2>&1 &
WAF_PID=$!
echo "   WAF PID: $WAF_PID"
sleep 2

# Start Network Layer Firewall (Fallback Sniffer)
echo "[5/6] Starting Network Layer Firewall (Fallback Sniffer)..."
cd "$BACKEND_DIR"
export BACKEND_ROOT="$BACKEND_DIR"
echo "   BACKEND_ROOT set to: $BACKEND_ROOT"
echo "   CSV files will be written to: $BACKEND_DIR"
nohup sudo -E env BACKEND_ROOT="$BACKEND_DIR" python network_sniffer_fallback.py > network.log 2>&1 &
NETWORK_PID=$!
echo "   Network Firewall PID: $NETWORK_PID"
sleep 2

# Start CSV API
echo "[6/6] Starting CSV Read-only API on port 5174..."
cd "$FRONTEND_DIR"
export BACKEND_ROOT="$BACKEND_DIR"
if [ ! -d "node_modules" ]; then
    echo "   Installing Node.js dependencies..."
    npm install
    npm install express react react-dom
fi
nohup node server.mjs > api.log 2>&1 &
API_PID=$!
echo "   API PID: $API_PID"
sleep 3

# Start UI
echo "[7/6] Starting UI on port 8080..."
cd "$FRONTEND_DIR"
export BACKEND_ROOT="$BACKEND_DIR"
nohup npm run dev -- --host --port 8080 > ui.log 2>&1 &
UI_PID=$!
echo "   UI PID: $UI_PID"
sleep 3

echo ""
echo "=========================================="
echo "  ✅ All Services Started Successfully!"
echo "=========================================="
echo ""
echo "Services:"
echo "  • WAF (Application Layer):     http://127.0.0.1:8081"
echo "  • CSV Read-only API:           http://127.0.0.1:5174"
echo "  • UI Dashboard:                http://127.0.0.1:8080"
echo ""
echo "Logs:"
echo "  • WAF log:                      $BACKEND_DIR/waf.log"
echo "  • Network log:                 $BACKEND_DIR/network.log"
echo "  • API log:                     $FRONTEND_DIR/api.log"
echo "  • UI log:                      $FRONTEND_DIR/ui.log"
echo ""
echo "Process IDs:"
echo "  • WAF:                         $WAF_PID"
echo "  • Network Firewall:            $NETWORK_PID"
echo "  • API:                         $API_PID"
echo "  • UI:                          $UI_PID"
echo ""
echo "To stop all services:"
echo "  pkill -f 'Proxy_server.py'; pkill -f 'network_sniffer_fallback.py'; pkill -f 'server.mjs'; pkill -f 'vite'"
echo ""
echo "To view logs in real-time:"
echo "  tail -f $BACKEND_DIR/waf.log"
echo "  tail -f $BACKEND_DIR/network.log"
echo "  tail -f $FRONTEND_DIR/api.log"
echo "  tail -f $FRONTEND_DIR/ui.log"
echo ""

