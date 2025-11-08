# Complete Setup Guide for Kali VM

## Step-by-Step Commands to Clone and Start the Project

### Prerequisites Check
```bash
# Check if git is installed
git --version

# Check if Python 3 is installed
python3 --version

# Check if Node.js is installed (if not, we'll install it)
node --version || echo "Node.js not found - will install"
```

---

## Step 1: Clone the Repository

```bash
# Navigate to home directory
cd ~

# Clone the repository
git clone https://github.com/upasanameena/Capstone-Project.git

# Navigate into the project directory
cd Capstone-Project
```

---

## Step 2: Install Node.js (if not already installed)

```bash
# Option A: Using NVM (Recommended)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Verify Node.js installation
node --version
npm --version
```

**OR**

```bash
# Option B: Using apt (if NVM doesn't work)
sudo apt update
sudo apt install -y nodejs npm
node --version
npm --version
```

---

## Step 3: Quick Start (Automated - Recommended)

This is the easiest way to start everything:

```bash
# Navigate to backend directory
cd ~/Capstone-Project/backend

# Make the startup script executable
chmod +x start_all.sh

# Run the automated startup script
./start_all.sh
```

**What this script does:**
- Creates Python virtual environment
- Installs Python dependencies (numpy, pandas, scikit-learn, joblib, scapy)
- Initializes all required CSV files
- Starts WAF (Application Layer) on port 8081
- Starts Network Firewall (Fallback Sniffer)
- Starts CSV API on port 5174
- Starts UI Dashboard on port 8080

---

## Step 4: Access the Dashboard

After the script completes, open your browser and navigate to:

```
http://localhost:8080
```

**OR** from the terminal:

```bash
xdg-open http://localhost:8080
```

---

## Alternative: Manual Setup (Step-by-Step)

If you prefer to start services manually or the automated script doesn't work:

### Step 3A: Backend Setup

```bash
# Navigate to backend directory
cd ~/Capstone-Project/backend

# Create Python virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Upgrade pip
pip install --upgrade pip wheel setuptools

# Install Python dependencies
pip install numpy pandas scikit-learn joblib scapy

# Note: netfilterqueue is optional (only needed for full network firewall)
# If you want to install it:
# sudo apt install -y build-essential libnetfilter-queue-dev libnfnetlink-dev libmnl-dev pkg-config python3-dev
# pip install netfilterqueue
```

### Step 3B: Frontend Setup

```bash
# Navigate to frontend directory
cd ~/Capstone-Project/frontend

# Set backend root environment variable
export BACKEND_ROOT=$HOME/Capstone-Project/backend

# Install Node.js dependencies
npm install
```

### Step 3C: Initialize CSV Files

```bash
# Navigate to backend directory
cd ~/Capstone-Project/backend

# Create Data_Collection directory
mkdir -p Data_Collection

# Initialize CSV files
echo "method,path,timestamp" > Data_Collection/Good_req.csv
echo "method,path,timestamp" > Data_Collection/Bad_req.csv
touch benign_payloads.csv
touch malicious_payloads.csv
echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > network_allowed.csv
echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > network_blocked.csv
```

### Step 3D: Start Services (4 Separate Terminals)

**Terminal 1 - Network Firewall (requires sudo):**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
export BACKEND_ROOT=$HOME/Capstone-Project/backend
sudo -E python3 network_sniffer_fallback.py
```

**Terminal 2 - Application WAF:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
export BACKEND_ROOT=$HOME/Capstone-Project/backend
python3 Proxy_server.py
```

**Terminal 3 - CSV API Server:**
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=$HOME/Capstone-Project/backend
npm run api
```

**Terminal 4 - UI Dashboard:**
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=$HOME/Capstone-Project/backend
npm run dev -- --host --port 8080
```

---

## Step 5: Verify Services are Running

```bash
# Check if all processes are running
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# Test WAF endpoint
curl http://127.0.0.1:8081/test

# Test API endpoint
curl http://localhost:5174/api/stats/get-requests

# Check if UI is accessible
curl http://localhost:8080
```

---

## Step 6: Test the System

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

---

## Stopping Services

### If using automated script:
```bash
# Stop all services
pkill -f 'Proxy_server.py'
pkill -f 'network_sniffer_fallback.py'
pkill -f 'server.mjs'
pkill -f 'vite'
```

### Or stop individually:
```bash
# Find process IDs
ps aux | grep Proxy_server
ps aux | grep network_sniffer
ps aux | grep server.mjs
ps aux | grep vite

# Kill by PID (replace PID with actual process ID)
kill <PID>
```

---

## Viewing Logs

```bash
# WAF logs
tail -f ~/Capstone-Project/backend/waf.log

# Network firewall logs
tail -f ~/Capstone-Project/backend/network.log

# API logs
tail -f ~/Capstone-Project/frontend/api.log

# UI logs
tail -f ~/Capstone-Project/frontend/ui.log
```

---

## Troubleshooting

### Issue: "training_model.pkl not found"
**Solution:** The model file should exist in the backend directory. If missing, you may need to train it first:
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
python train_model.py
```

### Issue: "Permission denied" for network firewall
**Solution:** The network firewall requires sudo privileges:
```bash
sudo -E python3 network_sniffer_fallback.py
```

### Issue: Port already in use
**Solution:** Kill existing processes or change ports:
```bash
# Find what's using the port
sudo lsof -i :8081
sudo lsof -i :8080
sudo lsof -i :5174

# Kill the process
kill <PID>
```

### Issue: Node.js dependencies fail to install
**Solution:** Clear npm cache and retry:
```bash
cd ~/Capstone-Project/frontend
rm -rf node_modules package-lock.json
npm cache clean --force
npm install
```

### Issue: Python dependencies fail to install
**Solution:** Update system packages and retry:
```bash
sudo apt update
sudo apt install -y python3-pip python3-venv build-essential
cd ~/Capstone-Project/backend
rm -rf venv
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install numpy pandas scikit-learn joblib scapy
```

---

## Summary of Services

Once everything is running, you'll have:

- **WAF (Application Layer)**: `http://127.0.0.1:8081` - Web Application Firewall
- **CSV Read-only API**: `http://127.0.0.1:5174` - API for dashboard data
- **UI Dashboard**: `http://localhost:8080` - Main visualization dashboard
- **Network Firewall**: Running in background (no web interface)

---

## Quick Reference Commands

```bash
# Clone and quick start (all in one)
cd ~ && git clone https://github.com/upasanameena/Capstone-Project.git && cd Capstone-Project/backend && chmod +x start_all.sh && ./start_all.sh

# Check services status
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# Stop all services
pkill -f 'Proxy_server.py'; pkill -f 'network_sniffer_fallback.py'; pkill -f 'server.mjs'; pkill -f 'vite'

# View all logs
tail -f ~/Capstone-Project/backend/waf.log ~/Capstone-Project/backend/network.log ~/Capstone-Project/frontend/api.log ~/Capstone-Project/frontend/ui.log
```

---

**Repository:** https://github.com/upasanameena/Capstone-Project

