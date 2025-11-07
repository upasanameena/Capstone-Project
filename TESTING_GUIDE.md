# Complete Testing Guide

## 1. How to Train the Model

### Initial Training (One-time setup)

```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
python train_model.py
```

**What it does:**
- Generates sample training data (if CSVs don't exist)
- Trains a Logistic Regression model
- Saves model to `training_model.pkl`
- Shows accuracy and classification report

**Expected Output:**
```
✅ Loaded X benign samples
✅ Loaded Y malicious samples
✅ Model trained successfully!
   Accuracy: XX.XX%
✅ Model saved to: training_model.pkl
```

### Automatic Retraining

The WAF **automatically retrains** every 60 seconds using live traffic logs:
- Reads from `benign_payloads.csv` and `malicious_payloads.csv`
- Retrains the model with new data
- Updates `training_model.pkl`

**No manual action needed!** Just run the WAF and it learns from traffic.

---

## 2. How to Test Different URLs

### Quick Test Commands

**Test GET Requests:**

```bash
# ✅ Good/Benign GET requests (should PASS)
curl 'http://127.0.0.1:8081/'
curl 'http://127.0.0.1:8081/index.html'
curl 'http://127.0.0.1:8081/about'
curl 'http://127.0.0.1:8081/products?id=123'
curl 'http://127.0.0.1:8081/search?q=hello'

# ❌ Malicious GET requests (should be BLOCKED)
curl 'http://127.0.0.1:8081/?id=1%27%20OR%20%271%27%3D%271'
curl 'http://127.0.0.1:8081/login?user=admin%27--'
curl 'http://127.0.0.1:8081/search?q=1%27%20UNION%20SELECT%20*%20FROM%20users--'
curl 'http://127.0.0.1:8081/api?id=1;%20DROP%20TABLE%20users--'
curl 'http://127.0.0.1:8081/page?id=1%27%20OR%201%3D1--'
```

**Test POST Requests:**

```bash
# ✅ Good/Benign POST requests (should PASS)
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"test","email":"user@example.com"}'

curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=user&password=pass123'

curl -X POST 'http://127.0.0.1:8081/register' \
  -H 'Content-Type: application/json' \
  -d '{"email":"test@example.com","name":"John Doe"}'

# ❌ Malicious POST requests (should be BLOCKED)
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin' OR '1'='1&password=x"

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"<script>alert(1)</script>"}'

curl -X POST 'http://127.0.0.1:8081/upload' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'file=../../../etc/passwd'

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"cmd":"; cat /etc/passwd"}'
```

### Expected Responses

**Good Request (PASSED):**
```
Nothing malicious detected. PASSED!
```

**Malicious Request (BLOCKED):**
```
Malicious request detected!
Reason: SQL pattern | Badwords: or | ML model (confidence: 85.23%)
```

### Test Network Layer

```bash
# Generate normal traffic
ping -c 3 1.1.1.1
curl http://example.com
curl http://google.com

# Generate suspicious traffic (will be logged)
nmap -p 1-200 127.0.0.1
nmap -p 3389,445,1433 127.0.0.1
```

---

## 3. Do I Need to Run the Script Every Time?

### **NO!** Services run in background

Once you run `./start_all.sh`, all services run in the **background** and stay running until you:
- Reboot your system
- Manually stop them
- They crash (rare)

### Check if Services are Running

```bash
# Check all processes
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# Check ports
ss -ltnp | grep -E '8081|8080|5174'
```

### If Services are Running

**Just open the UI:**
```bash
# Open in browser
xdg-open http://localhost:8080
# OR manually navigate to: http://localhost:8080
```

**No need to run the script again!**

### If Services Stopped

**Only then run the startup script:**
```bash
cd ~/Capstone-Project/backend
./start_all.sh
```

### Quick Restart (if needed)

```bash
# Stop all services
pkill -f 'Proxy_server.py'
pkill -f 'network_sniffer_fallback.py'
pkill -f 'server.mjs'
pkill -f 'vite'

# Restart
cd ~/Capstone-Project/backend
./start_all.sh
```

---

## 4. Complete Testing Workflow

### Step 1: Initial Setup (One-time)

```bash
cd ~/Capstone-Project/backend
source venv/bin/activate

# Train initial model
python train_model.py

# Start all services
./start_all.sh
```

### Step 2: Test the System

```bash
# Terminal 1: Watch WAF logs
tail -f ~/Capstone-Project/backend/waf.log

# Terminal 2: Run test commands
curl 'http://127.0.0.1:8081/?q=hello'                    # Should PASS
curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'     # Should BLOCK

# Terminal 3: Check UI
# Open http://localhost:8080 in browser
```

### Step 3: Verify Results

**Check CSV files:**
```bash
# Good requests
wc -l ~/Capstone-Project/backend/Data_Collection/Good_req.csv
tail -3 ~/Capstone-Project/backend/Data_Collection/Good_req.csv

# Bad requests
wc -l ~/Capstone-Project/backend/Data_Collection/Bad_req.csv
tail -3 ~/Capstone-Project/backend/Data_Collection/Bad_req.csv

# Payloads
wc -l ~/Capstone-Project/backend/benign_payloads.csv
wc -l ~/Capstone-Project/backend/malicious_payloads.csv
```

**Check UI Dashboard:**
- Open http://localhost:8080
- Should show:
  - URL Filter Analysis (GET) with counts
  - Payload Classification (POST) with counts
  - Network Layer Firewall with counts
  - Charts updating in real-time

---

## 5. Testing Checklist

### ✅ Basic Functionality

- [ ] WAF starts without errors
- [ ] UI loads at http://localhost:8080
- [ ] API responds at http://localhost:5174/api/debug/paths
- [ ] Good GET requests are PASSED
- [ ] Malicious GET requests are BLOCKED
- [ ] Good POST requests are PASSED
- [ ] Malicious POST requests are BLOCKED
- [ ] CSV files are being written
- [ ] UI charts show data

### ✅ Attack Vectors

- [ ] SQL Injection (GET) - `?id=1' OR '1'='1`
- [ ] SQL Injection (POST) - `username=admin' OR '1'='1`
- [ ] XSS (GET) - `?q=<script>alert(1)</script>`
- [ ] XSS (POST) - `{"name":"<script>alert(1)</script>"}`
- [ ] Path Traversal - `../../../etc/passwd`
- [ ] Command Injection - `; cat /etc/passwd`
- [ ] Network layer logs packets

### ✅ UI Verification

- [ ] Dashboard loads without errors
- [ ] GET stats show correct counts
- [ ] POST stats show correct counts
- [ ] Network stats show correct counts
- [ ] Charts render properly
- [ ] Data updates every 5 seconds
- [ ] No console errors (F12)

---

## 6. Troubleshooting Tests

### Test API Endpoints

```bash
# Debug paths
curl http://localhost:5174/api/debug/paths | jq

# GET stats
curl http://localhost:5174/api/stats/get-requests | jq

# POST stats
curl http://localhost:5174/api/stats/post-payloads | jq

# Network stats
curl http://localhost:5174/api/stats/network-firewall | jq
```

### Test WAF Directly

```bash
# Check if WAF is listening
ss -ltnp | grep 8081

# Test with curl
curl -v 'http://127.0.0.1:8081/?q=test'
```

### View Logs

```bash
# WAF logs
tail -f ~/Capstone-Project/backend/waf.log

# Network logs
tail -f ~/Capstone-Project/backend/network.log

# API logs
tail -f ~/Capstone-Project/frontend/api.log

# UI logs
tail -f ~/Capstone-Project/frontend/ui.log
```

---

## Summary

1. **Train Model**: Run `python train_model.py` once (or let WAF auto-retrain)
2. **Test URLs**: Use curl commands above to test GET/POST
3. **Check UI**: Open http://localhost:8080 (no need to restart script if services are running)
4. **Services Run in Background**: Only restart if they stop or you reboot

**That's it!** Your firewall is ready for testing and demonstration. 🎉

