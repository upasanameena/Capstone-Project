# ML-Driven Dual-Layer Firewall

A comprehensive dual-layer firewall system combining network-level packet filtering with an ML-driven Web Application Firewall (WAF) for application-layer security. Built and evaluated on Kali Linux.

## Features

- **Network Layer Firewall**: Packet-level filtering using ML and heuristic rules
- **Application Layer WAF**: HTTP request analysis with ML classification
- **Real-time Visualization**: Live dashboard showing firewall statistics
- **Automated Retraining**: ML model retrains using live traffic logs
- **Comprehensive Detection**: SQLi, XSS, RCE, LFI/RFI, SSRF, IDOR patterns

## Project Structure

```
Capstone-Project/
├── backend/
│   ├── Proxy_server.py              # Application layer WAF
│   ├── network_sniffer_fallback.py  # Network layer firewall (fallback)
│   ├── network_firewall.py          # Network layer firewall (full netfilterqueue)
│   ├── training_model.pkl           # Trained ML model
│   ├── start_all.sh                 # Startup script
│   ├── Data_Collection/
│   │   ├── Good_req.csv            # Good GET requests
│   │   └── Bad_req.csv             # Bad GET requests
│   ├── benign_payloads.csv         # Benign POST payloads
│   ├── malicious_payloads.csv      # Malicious POST payloads
│   ├── network_allowed.csv         # Allowed network packets
│   └── network_blocked.csv         # Blocked network packets
└── frontend/
    ├── src/
    │   ├── main.tsx                 # React entry point
    │   └── components/
    │       └── Dashboard.tsx        # Main dashboard component
    ├── server.mjs                   # CSV read-only API
    └── package.json
```

## Quick Start (Kali Linux)

### 1. Clone and Setup

```bash
cd ~
git clone https://github.com/upasanameena/Capstone-Project.git
cd Capstone-Project/backend
```

### 2. Run Everything (Automated)

```bash
chmod +x start_all.sh
./start_all.sh
```

This script will:
- Create Python virtual environment
- Install all dependencies (excluding netfilterqueue to avoid build issues)
- Initialize all CSV files
- Start WAF (port 8081)
- Start Network Firewall (fallback sniffer)
- Start CSV API (port 5174)
- Start UI Dashboard (port 8080)

### 3. Access Dashboard

Open in browser: **http://localhost:8080**

## Manual Setup

### Backend (WAF)

```bash
cd ~/Capstone-Project/backend
python3 -m venv venv
source venv/bin/activate
pip install numpy pandas scikit-learn joblib scapy

# Ensure training_model.pkl exists
# Then start WAF:
python Proxy_server.py
```

### Network Firewall

**Option 1: Fallback Sniffer (Recommended - No netfilterqueue required)**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
sudo -E python network_sniffer_fallback.py
```

**Option 2: Full Network Firewall (Requires netfilterqueue)**
```bash
# Install system dependencies
sudo apt update
sudo apt install -y build-essential libnetfilter-queue-dev libnfnetlink-dev libmnl-dev pkg-config python3-dev

# Install netfilterqueue
source venv/bin/activate
pip install --no-binary=:all: NetfilterQueue

# Start network firewall
sudo -E python network_firewall.py
```

### Frontend (UI)

```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=$HOME/Capstone-Project/backend

# Install dependencies
npm install
npm install express react react-dom

# Start API (Terminal 1)
npm run api

# Start UI (Terminal 2)
npm run dev -- --host --port 8080
```

## Testing

### Test GET Requests

```bash
# Good request
curl 'http://127.0.0.1:8081/?q=hello'

# Malicious request (SQL injection)
curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'
```

### Test POST Requests

```bash
# Benign request
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"test"}'

# Malicious request (SQL injection)
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin' OR '1'='1&password=x"
```

### Generate Network Traffic

```bash
# Normal traffic
ping -c 3 1.1.1.1
curl http://example.com

# Suspicious port scanning (will be logged)
nmap -p 1-200 127.0.0.1
```

## ML Model

- **Algorithm**: Logistic Regression
- **Features**: 12 numerical features extracted from path and body
  - Single quotes, double quotes, dashes, braces
  - Spaces, semicolons, angle brackets
  - Special characters, path length, body length
  - Badwords count, URL encoding patterns
- **Training**: Automated retraining using CSV logs
- **Output**: Binary classification (0=benign, 1=malicious) with confidence scores

## Visualization

The dashboard displays:
- **URL Filter Analysis (GET)**: Pie chart showing good vs bad URLs
- **Payload Classification (POST)**: Bar chart showing benign vs malicious payloads
- **Network Layer Firewall**: Bar chart showing allowed vs blocked packets
- **ML Model Training Overview**: Line chart showing training progress over time

All visualizations update automatically every 5 seconds.

## Troubleshooting

### UI shows blank page
- Check if `src/main.tsx` and `src/components/Dashboard.tsx` exist
- Check browser console (F12) for errors
- Verify API is running: `curl http://localhost:5174/api/debug/paths`

### CSV files not found
- Set `BACKEND_ROOT` environment variable:
  ```bash
  export BACKEND_ROOT=$HOME/Capstone-Project/backend
  ```
- Check if CSV files exist:
  ```bash
  ls -la ~/Capstone-Project/backend/Data_Collection/*.csv
  ls -la ~/Capstone-Project/backend/*.csv
  ```

### WAF fails to start
- Ensure `training_model.pkl` exists in backend directory
- Check Python dependencies: `pip list | grep -E "numpy|pandas|scikit-learn"`
- Check logs: `tail -f ~/Capstone-Project/backend/waf.log`

### Network firewall not working
- Use fallback sniffer (no netfilterqueue required)
- Ensure running with sudo: `sudo -E python network_sniffer_fallback.py`
- Check logs: `tail -f ~/Capstone-Project/backend/network.log`

## Stopping Services

```bash
pkill -f 'Proxy_server.py'
pkill -f 'network_sniffer_fallback.py'
pkill -f 'server.mjs'
pkill -f 'vite'
```

## License

This project is for educational and research purposes.

## Author

Capstone Project - MCA
