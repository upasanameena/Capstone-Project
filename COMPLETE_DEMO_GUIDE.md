# Complete Demonstration Guide
## Step-by-Step Commands for Full Project Demo

---

## Part 1: Initial Setup (One-Time)

### Step 1: Clone/Update Repository
```bash
cd ~
git clone https://github.com/upasanameena/Capstone-Project.git
# OR if already cloned:
cd ~/Capstone-Project
git pull origin main
```

### Step 2: Set Environment Variable
```bash
export BACKEND_ROOT=$HOME/Capstone-Project/backend
echo 'export BACKEND_ROOT=$HOME/Capstone-Project/backend' >> ~/.bashrc
source ~/.bashrc
```

### Step 3: Verify Environment
```bash
echo $BACKEND_ROOT
# Should show: /home/kali/Capstone-Project/backend
```

---

## Part 2: Start All Services

### Option A: Automated Startup (Recommended)
```bash
cd ~/Capstone-Project/backend
chmod +x start_all.sh
./start_all.sh
```

Wait 10 seconds, then verify:
```bash
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"
```

### Option B: Manual Startup (4 Terminals)

**Terminal 1 - Network Firewall:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
export BACKEND_ROOT=$HOME/Capstone-Project/backend
sudo -E env BACKEND_ROOT="$BACKEND_ROOT" python3 network_sniffer_fallback.py
```

**Terminal 2 - Application WAF:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
export BACKEND_ROOT=$HOME/Capstone-Project/backend
python3 Proxy_server.py
```

**Terminal 3 - API Server:**
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

## Part 3: Generate Training Data

### Step 1: Generate WAF Training Data
```bash
cd ~/Capstone-Project/backend
chmod +x generate_training_data_fast.sh
./generate_training_data_fast.sh
```

### Step 2: Generate Network Training Data (Direct CSV Method)
```bash
cd ~/Capstone-Project/backend
chmod +x direct_add_balanced_data.sh
./direct_add_balanced_data.sh
```

This creates:
- 4000 allowed packets
- 1000 blocked packets
- Balanced 80/20 ratio

---

## Part 4: Open Dashboard

```bash
xdg-open http://localhost:8080
```

---

## Part 5: Live Demonstration - Application Layer WAF

### Good URLs (Should be ALLOWED)

```bash
# Normal search queries
curl 'http://127.0.0.1:8081/?q=hello'
curl 'http://127.0.0.1:8081/?q=products'
curl 'http://127.0.0.1:8081/?q=search'
curl 'http://127.0.0.1:8081/?q=about'
curl 'http://127.0.0.1:8081/?q=contact'

# Normal product pages
curl 'http://127.0.0.1:8081/product?id=1'
curl 'http://127.0.0.1:8081/product?id=2'
curl 'http://127.0.0.1:8081/item?product_id=123'

# Normal user pages
curl 'http://127.0.0.1:8081/user?id=1'
curl 'http://127.0.0.1:8081/profile?user_id=123'

# Normal API endpoints
curl 'http://127.0.0.1:8081/api/users'
curl 'http://127.0.0.1:8081/api/products'
```

### SQL Injection Attacks (Should be BLOCKED)

```bash
# Basic SQL Injection
curl 'http://127.0.0.1:8081/?q=1%27%20OR%20%271%27%3D%271'
curl 'http://127.0.0.1:8081/?q=admin%27--'
curl 'http://127.0.0.1:8081/?q=%27%20OR%201%3D1--'
curl 'http://127.0.0.1:8081/?q=1%27%20OR%20%271%27%3D%271--'

# UNION-based SQL Injection
curl 'http://127.0.0.1:8081/?q=1%27%20UNION%20SELECT%20NULL--'
curl 'http://127.0.0.1:8081/?q=%27%20UNION%20SELECT%20*%20FROM%20users--'
curl 'http://127.0.0.1:8081/?q=1%27%20UNION%20SELECT%20password%20FROM%20users--'

# Time-based SQL Injection
curl 'http://127.0.0.1:8081/?q=1%27%20OR%20SLEEP%285%29--'
curl 'http://127.0.0.1:8081/?q=1%27%3B%20WAITFOR%20DELAY%20%2700%3A00%3A05%27--'

# Boolean-based SQL Injection
curl 'http://127.0.0.1:8081/?q=1%27%20AND%201%3D1--'
curl 'http://127.0.0.1:8081/?q=1%27%20AND%201%3D2--'
```

### XSS Attacks (Should be BLOCKED)

```bash
# Basic XSS
curl 'http://127.0.0.1:8081/?q=%3Cscript%3Ealert%281%29%3C/script%3E'
curl 'http://127.0.0.1:8081/?q=%3Cimg%20src%3Dx%20onerror%3Dalert%281%29%3E'
curl 'http://127.0.0.1:8081/?q=%3Csvg%20onload%3Dalert%281%29%3E'

# JavaScript protocol
curl 'http://127.0.0.1:8081/?q=javascript%3Aalert%281%29'
curl 'http://127.0.0.1:8081/?q=javascript%3Aalert%28%27XSS%27%29'

# Event handlers
curl 'http://127.0.0.1:8081/?q=%3Cbody%20onload%3Dalert%281%29%3E'
curl 'http://127.0.0.1:8081/?q=%3Ciframe%20src%3Djavascript%3Aalert%281%29%3E'

# Encoded XSS
curl 'http://127.0.0.1:8081/?q=%3Cscript%3Eeval%28String.fromCharCode%2897%2C108%2C101%2C114%2C116%2C40%2C49%2C41%29%29%3C/script%3E'
```

### Command Injection Attacks (Should be BLOCKED)

```bash
curl 'http://127.0.0.1:8081/?q=%3B%20ls%20-la'
curl 'http://127.0.0.1:8081/?q=%3B%20cat%20/etc/passwd'
curl 'http://127.0.0.1:8081/?q=%7C%20whoami'
curl 'http://127.0.0.1:8081/?q=%26%26%20id'
curl 'http://127.0.0.1:8081/?q=%60whoami%60'
curl 'http://127.0.0.1:8081/?q=%24%28whoami%29'
```

### Path Traversal Attacks (Should be BLOCKED)

```bash
curl 'http://127.0.0.1:8081/?q=..%2F..%2F..%2Fetc%2Fpasswd'
curl 'http://127.0.0.1:8081/?q=....//....//etc/passwd'
curl 'http://127.0.0.1:8081/?q=/etc/passwd'
curl 'http://127.0.0.1:8081/?q=..%5C..%5C..%5Cwindows%5Csystem32'
```

### SSRF Attacks (Should be BLOCKED)

```bash
curl 'http://127.0.0.1:8081/?q=http%3A//127.0.0.1%3A22'
curl 'http://127.0.0.1:8081/?q=http%3A//localhost/admin'
curl 'http://127.0.0.1:8081/?q=file%3A//etc/passwd'
curl 'http://127.0.0.1:8081/?q=gopher%3A//127.0.0.1%3A6379'
```

### IDOR Attacks (Should be BLOCKED)

```bash
curl 'http://127.0.0.1:8081/../user/0'
curl 'http://127.0.0.1:8081/../admin/1'
curl 'http://127.0.0.1:8081?user_id=0'
curl 'http://127.0.0.1:8081?id=-1'
curl 'http://127.0.0.1:8081?user=admin'
```

### POST Requests - Good (Should be ALLOWED)

```bash
# Normal JSON payloads
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"test","email":"test@example.com"}'

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"action":"search","query":"products"}'

# Normal form data
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=user123&password=SecurePass123'
```

### POST Requests - Malicious (Should be BLOCKED)

```bash
# SQL Injection in POST
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin' OR '1'='1&password=x"

curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin'--&password=test"

# XSS in POST
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"message":"<script>alert(1)</script>"}'

# Command Injection in POST
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"cmd":"; ls -la"}'
```

---

## Part 6: Live Demonstration - Network Layer Firewall

### Normal Traffic (Should be ALLOWED)

```bash
# DNS queries
ping -c 5 8.8.8.8
ping -c 5 1.1.1.1
ping -c 5 208.67.222.222

# HTTP requests
curl -s http://example.com
curl -s http://httpbin.org/get

# HTTPS requests
curl -s https://www.google.com

# Normal port connections
timeout 2 bash -c 'echo > /dev/tcp/example.com/80'
timeout 2 bash -c 'echo > /dev/tcp/www.google.com/443'
timeout 2 bash -c 'echo > /dev/tcp/8.8.8.8/53'
```

### Suspicious Ports (Should be BLOCKED)

```bash
# Telnet (Port 23)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/23'

# RDP (Port 3389)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3389'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/3389'

# SMB (Port 445)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/445'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/445'

# MySQL (Port 3306)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3306'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/3306'

# MSSQL (Port 1433)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/1433'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/1433'

# PostgreSQL (Port 5432)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/5432'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/5432'

# VNC (Port 5900)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/5900'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/5900'
```

### Port Scanning Simulation (Generates Many Packets)

```bash
# Using nmap (if installed)
nmap -p 1-100 127.0.0.1

# Or manual port scan
for port in {20..100}; do
    timeout 0.2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
done
```

---

## Part 7: Complete Test Suite

### Run All Tests at Once

```bash
cd ~/Capstone-Project/backend
chmod +x generate_training_data_fast.sh direct_add_balanced_data.sh
./generate_training_data_fast.sh
./direct_add_balanced_data.sh
```

### Verify Results

```bash
# Check WAF data
echo "Good URLs: $(tail -n +2 Data_Collection/Good_req.csv | wc -l)"
echo "Bad URLs: $(tail -n +2 Data_Collection/Bad_req.csv | wc -l)"
echo "Benign Payloads: $(wc -l < benign_payloads.csv)"
echo "Malicious Payloads: $(wc -l < malicious_payloads.csv)"

# Check Network data
echo "Allowed Packets: $(tail -n +2 network_allowed.csv | wc -l)"
echo "Blocked Packets: $(tail -n +2 network_blocked.csv | wc -l)"

# Check API
curl http://localhost:5174/api/stats/get-requests
curl http://localhost:5174/api/stats/network-firewall
```

---

## Part 8: Presentation Flow

### 1. Show Initial Dashboard
- Open: `http://localhost:8080`
- Explain the four sections:
  - URL Filter Analysis (GET Requests)
  - Payload Classification (POST Requests)
  - Network Layer Firewall
  - ML Model Training Overview

### 2. Demonstrate Application Layer WAF
- Show good URL requests (watch dashboard update)
- Show SQL injection attacks (watch dashboard update)
- Show XSS attacks (watch dashboard update)
- Show command injection attacks (watch dashboard update)

### 3. Demonstrate Network Layer Firewall
- Show normal traffic (ping, HTTP)
- Show suspicious port attempts (watch blocked count increase)
- Explain the difference between application and network layers

### 4. Show ML Training Metrics
- Point to the training graph
- Explain how the model learns from live traffic
- Show accuracy improvements over time

---

## Part 9: Quick Reference Commands

### Start Everything
```bash
cd ~/Capstone-Project/backend && ./start_all.sh
```

### Generate All Training Data
```bash
cd ~/Capstone-Project/backend
./generate_training_data_fast.sh
./direct_add_balanced_data.sh
```

### Test Good Requests
```bash
curl 'http://127.0.0.1:8081/?q=hello'
curl 'http://127.0.0.1:8081/?q=products'
```

### Test SQL Injection
```bash
curl 'http://127.0.0.1:8081/?q=1%27%20OR%20%271%27%3D%271'
curl 'http://127.0.0.1:8081/?q=admin%27--'
```

### Test XSS
```bash
curl 'http://127.0.0.1:8081/?q=%3Cscript%3Ealert%281%29%3C/script%3E'
```

### Test Network - Normal
```bash
ping -c 5 8.8.8.8
```

### Test Network - Blocked
```bash
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23'
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3389'
```

### Stop Everything
```bash
pkill -f 'Proxy_server.py'
pkill -f 'network_sniffer'
pkill -f 'server.mjs'
pkill -f 'vite'
```

---

## Part 10: Expected Results

After running all tests, you should see:

- **Good URLs**: 100+
- **Bad URLs**: 100+
- **Benign Payloads**: 30+
- **Malicious Payloads**: 5+
- **Allowed Packets**: 4000
- **Blocked Packets**: 1000
- **Total Packets**: 5000
- **Ratio**: ~80% Allowed, ~20% Blocked

---

**Good luck with your presentation! 🎯**

