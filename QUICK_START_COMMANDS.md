# Quick Start Commands - Copy & Paste

## Complete Setup in One Go

```bash
# Step 1: Clone repository
cd ~
git clone https://github.com/upasanameena/Capstone-Project.git
cd Capstone-Project/backend

# Step 2: Install Node.js (if needed)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Step 3: Start everything
chmod +x start_all.sh
./start_all.sh

# Step 4: Open dashboard
xdg-open http://localhost:8080
```

---

## Individual Commands (Step by Step)

### 1. Clone Repository
```bash
cd ~
git clone https://github.com/upasanameena/Capstone-Project.git
cd Capstone-Project
```

### 2. Install Node.js (if not installed)
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
node --version
```

### 3. Quick Start (Automated)
```bash
cd ~/Capstone-Project/backend
chmod +x start_all.sh
./start_all.sh
```

### 4. Access Dashboard
```bash
xdg-open http://localhost:8080
```

---

## Manual Setup Commands

### Backend Setup
```bash
cd ~/Capstone-Project/backend
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip wheel setuptools
pip install numpy pandas scikit-learn joblib scapy
```

### Frontend Setup
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=$HOME/Capstone-Project/backend
npm install
```

### Initialize CSV Files
```bash
cd ~/Capstone-Project/backend
mkdir -p Data_Collection
echo "method,path,timestamp" > Data_Collection/Good_req.csv
echo "method,path,timestamp" > Data_Collection/Bad_req.csv
touch benign_payloads.csv
touch malicious_payloads.csv
echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > network_allowed.csv
echo "timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason" > network_blocked.csv
```

### Start Services (4 Terminals)

**Terminal 1 - Network Firewall:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
export BACKEND_ROOT=$HOME/Capstone-Project/backend
sudo -E python3 network_sniffer_fallback.py
```

**Terminal 2 - WAF:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
export BACKEND_ROOT=$HOME/Capstone-Project/backend
python3 Proxy_server.py
```

**Terminal 3 - API:**
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=$HOME/Capstone-Project/backend
npm run api
```

**Terminal 4 - UI:**
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=$HOME/Capstone-Project/backend
npm run dev -- --host --port 8080
```

---

## Verification Commands

```bash
# Check if services are running
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# Test WAF
curl http://127.0.0.1:8081/test

# Test API
curl http://localhost:5174/api/stats/get-requests

# Test UI
curl http://localhost:8080
```

---

## Stop All Services

```bash
pkill -f 'Proxy_server.py'
pkill -f 'network_sniffer_fallback.py'
pkill -f 'server.mjs'
pkill -f 'vite'
```

---

## View Logs

```bash
# All logs at once
tail -f ~/Capstone-Project/backend/waf.log ~/Capstone-Project/backend/network.log ~/Capstone-Project/frontend/api.log ~/Capstone-Project/frontend/ui.log

# Individual logs
tail -f ~/Capstone-Project/backend/waf.log
tail -f ~/Capstone-Project/backend/network.log
tail -f ~/Capstone-Project/frontend/api.log
tail -f ~/Capstone-Project/frontend/ui.log
```

---

## Test Commands

```bash
# Test good GET request
curl 'http://127.0.0.1:8081/?q=hello'

# Test malicious GET request
curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'

# Test benign POST request
curl -X POST 'http://127.0.0.1:8081/api' -H 'Content-Type: application/json' -d '{"name":"test"}'

# Test malicious POST request
curl -X POST 'http://127.0.0.1:8081/login' -H 'Content-Type: application/x-www-form-urlencoded' -d "username=admin' OR '1'='1&password=x"
```

