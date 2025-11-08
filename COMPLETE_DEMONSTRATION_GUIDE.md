# Complete Project Demonstration Guide
## Step-by-Step Commands for Presenter Demo

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

### Step 2: Set Environment Variable (Permanent)
```bash
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

This will automatically:
- Create virtual environment
- Install dependencies
- Initialize CSV files
- Start WAF (port 8081)
- Start Network Firewall
- Start API (port 5174)
- Start UI Dashboard (port 8080)

### Option B: Manual Startup (4 Terminals)

**Terminal 1 - Network Firewall:**
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

## Part 3: Verify Services Are Running

```bash
# Check all processes
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# Test endpoints
curl http://127.0.0.1:8081/test
curl http://localhost:5174/api/stats/get-requests
curl http://localhost:8080
```

---

## Part 4: Generate Test Data for Demonstration

### Step 1: Generate WAF Test Data (Application Layer)
```bash
cd ~/Capstone-Project/backend
chmod +x generate_test_data.sh
./generate_test_data.sh
```

**OR manually:**
```bash
# Good GET requests (10 requests)
for i in {1..10}; do
    curl -s "http://127.0.0.1:8081/?q=test$i" > /dev/null
    curl -s "http://127.0.0.1:8081/?q=product$i" > /dev/null
done

# Malicious GET requests (10 requests)
curl -s 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'
curl -s 'http://127.0.0.1:8081/?q=admin%27--'
curl -s 'http://127.0.0.1:8081/?q=%27%20UNION%20SELECT%20NULL--'
curl -s 'http://127.0.0.1:8081/?q=<script>alert(1)</script>'
curl -s 'http://127.0.0.1:8081/?q=javascript:alert(1)'
curl -s 'http://127.0.0.1:8081/?q=1%27%20OR%20%271%27%3D%271'
curl -s 'http://127.0.0.1:8081/?q=%27%20DROP%20TABLE%20users--'
curl -s 'http://127.0.0.1:8081/?q=admin%27%20OR%20%271%27%3D%271'
curl -s 'http://127.0.0.1:8081/?q=%3Cscript%3Eeval(String.fromCharCode(97,108,101,114,116,40,49,41))%3C/script%3E'
curl -s 'http://127.0.0.1:8081/?q=1%27%20UNION%20SELECT%20password%20FROM%20users--'

# Good POST requests (5 requests)
curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"test"}' > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"username":"user123","email":"user@example.com"}' > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"action":"search","query":"products"}' > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"message":"hello world"}' > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"data":"normal data"}' > /dev/null

# Malicious POST requests (5 requests)
curl -s -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin' OR '1'='1&password=x" > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin'--&password=test" > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"query":"1'\'' OR 1=1--"}' > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"cmd":"<script>alert(1)</script>"}' > /dev/null

curl -s -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"data":"'\'' UNION SELECT * FROM users--"}' > /dev/null
```

### Step 2: Generate Network Firewall Test Data (Network Layer)
```bash
cd ~/Capstone-Project/backend
chmod +x test_network_firewall.sh
./test_network_firewall.sh
```

**OR manually:**
```bash
# Normal traffic (ALLOWED)
ping -c 10 8.8.8.8
ping -c 10 1.1.1.1
curl -s http://example.com > /dev/null
curl -s https://www.google.com > /dev/null 2>&1

# Suspicious ports (BLOCKED)
for port in 23 3389 445 1433 3306 5432; do
    timeout 1 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
done

# Port scanning (generates many packets)
nmap -p 1-100 127.0.0.1 > /dev/null 2>&1 || \
for port in 22 25 53 80 443 8080; do
    timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
done
```

---

## Part 5: Verify Data Was Generated

```bash
cd ~/Capstone-Project/backend

# Check WAF data
echo "=== WAF Data ==="
echo "Good URLs: $(tail -n +2 Data_Collection/Good_req.csv 2>/dev/null | wc -l)"
echo "Bad URLs: $(tail -n +2 Data_Collection/Bad_req.csv 2>/dev/null | wc -l)"
echo "Benign Payloads: $(wc -l < benign_payloads.csv)"
echo "Malicious Payloads: $(wc -l < malicious_payloads.csv)"

# Check Network Firewall data
echo ""
echo "=== Network Firewall Data ==="
echo "Allowed Packets: $(tail -n +2 network_allowed.csv 2>/dev/null | wc -l)"
echo "Blocked Packets: $(tail -n +2 network_blocked.csv 2>/dev/null | wc -l)"

# Check API response
echo ""
echo "=== API Response ==="
curl -s http://localhost:5174/api/stats/get-requests | python3 -m json.tool
curl -s http://localhost:5174/api/stats/network-firewall | python3 -m json.tool
```

---

## Part 6: Open Dashboard

```bash
# Open in default browser
xdg-open http://localhost:8080

# OR manually navigate to:
# http://localhost:8080
```

---

## Part 7: Live Demonstration Script

### Demonstration Flow:

**1. Show Initial Dashboard State**
- Open dashboard: `http://localhost:8080`
- Show current metrics (may be low initially)

**2. Demonstrate Application Layer WAF (Real-time)**
```bash
# In terminal, send requests while showing dashboard
# Good request
curl 'http://127.0.0.1:8081/?q=demonstration'

# Malicious request (will be blocked)
curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'

# Show dashboard updating (auto-refreshes every 5 seconds)
```

**3. Demonstrate Network Layer Firewall (Real-time)**
```bash
# Generate network traffic while showing dashboard
ping -c 10 8.8.8.8

# Show suspicious port attempts
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23' 2>/dev/null || true
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3389' 2>/dev/null || true

# Show dashboard updating
```

**4. Show ML Training Overview**
- Point to the "ML Model Training Overview" graph
- Explain how it shows training progress over time
- Show how accuracy improves as more data is collected

**5. Show Detailed Logs**
```bash
# Show WAF logs
tail -20 ~/Capstone-Project/backend/waf.log

# Show network firewall logs
tail -20 ~/Capstone-Project/backend/network.log

# Show CSV data
head -10 ~/Capstone-Project/backend/Data_Collection/Good_req.csv
head -10 ~/Capstone-Project/backend/Data_Collection/Bad_req.csv
```

---

## Part 8: Complete Test Suite (For Full Demo)

```bash
cd ~/Capstone-Project/backend

# Run comprehensive test
echo "=== Running Complete Test Suite ==="

# 1. Test WAF
echo "1. Testing Application Layer WAF..."
for i in {1..20}; do
    curl -s "http://127.0.0.1:8081/?q=test$i" > /dev/null
done

for i in {1..20}; do
    curl -s "http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--$i" > /dev/null
done

# 2. Test Network Firewall
echo "2. Testing Network Layer Firewall..."
ping -c 20 8.8.8.8 > /dev/null

for port in 23 3389 445 3306; do
    timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
done

# 3. Wait for processing
echo "3. Waiting for data processing..."
sleep 5

# 4. Show results
echo "4. Final Results:"
curl -s http://localhost:5174/api/stats/get-requests | python3 -m json.tool
curl -s http://localhost:5174/api/stats/network-firewall | python3 -m json.tool

echo ""
echo "=== Demo Complete ==="
echo "Dashboard URL: http://localhost:8080"
```

---

## Part 9: Troubleshooting Commands

If something doesn't work:

```bash
# Check all services
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# Check logs
tail -f ~/Capstone-Project/backend/waf.log
tail -f ~/Capstone-Project/backend/network.log
tail -f ~/Capstone-Project/frontend/api.log

# Check API
curl http://localhost:5174/api/debug/paths

# Restart services if needed
cd ~/Capstone-Project/backend
./start_all.sh
```

---

## Part 10: Presentation Talking Points

### Key Features to Highlight:

1. **Dual-Layer Architecture**
   - Application Layer (WAF): HTTP/HTTPS request analysis
   - Network Layer: Packet-level filtering

2. **ML-Driven Detection**
   - Real-time classification using trained model
   - Automatic retraining from live traffic

3. **Real-time Visualization**
   - Live dashboard updates every 5 seconds
   - Multiple visualization types (pie charts, bar charts, line graphs)

4. **Comprehensive Detection**
   - SQL Injection
   - XSS (Cross-Site Scripting)
   - RCE (Remote Code Execution)
   - LFI/RFI (Local/Remote File Inclusion)
   - SSRF (Server-Side Request Forgery)
   - IDOR (Insecure Direct Object Reference)

5. **Network Security**
   - Suspicious port detection
   - Payload pattern analysis
   - Real-time packet monitoring

---

## Quick Reference Card

```bash
# Start everything
cd ~/Capstone-Project/backend && ./start_all.sh

# Generate test data
cd ~/Capstone-Project/backend && ./generate_test_data.sh && ./test_network_firewall.sh

# Check status
curl http://localhost:5174/api/stats/get-requests
curl http://localhost:5174/api/stats/network-firewall

# Open dashboard
xdg-open http://localhost:8080

# Stop everything
pkill -f 'Proxy_server.py'; pkill -f 'network_sniffer'; pkill -f 'server.mjs'; pkill -f 'vite'
```

---

## Expected Dashboard Metrics After Full Test

- **Good URLs**: 20-30+
- **Bad URLs**: 20-30+
- **Benign Payloads**: 5-10+
- **Malicious Payloads**: 5-10+
- **Allowed Packets**: 100+
- **Blocked Packets**: 4-10+

---

**Good luck with your presentation! 🎯**

