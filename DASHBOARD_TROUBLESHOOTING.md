# Dashboard Not Showing Data - Troubleshooting Guide

## Problem
The dashboard shows zeros (0) for Good URLs, Bad URLs, and other metrics even though the system is running.

## Root Cause
The dashboard reads data from CSV files that are populated by the WAF when it processes requests. If no requests have been sent to the WAF, the CSV files will only contain headers and show zero counts.

## Quick Fix

### Step 1: Verify Services Are Running

```bash
# Check if all services are running
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"

# You should see:
# - Proxy_server.py (WAF on port 8081)
# - network_sniffer_fallback.py (Network firewall)
# - node server.mjs (API on port 5174)
# - vite (UI on port 8080)
```

### Step 2: Run Diagnostic Script

```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
python3 diagnose_dashboard.py
```

This will show you:
- Which CSV files exist and have data
- Whether the API is accessible
- What's missing

### Step 3: Generate Test Data

**Option A: Use the automated script**
```bash
cd ~/Capstone-Project/backend
chmod +x generate_test_data.sh
./generate_test_data.sh
```

**Option B: Send requests manually**
```bash
# Good GET requests
curl 'http://127.0.0.1:8081/?q=hello'
curl 'http://127.0.0.1:8081/?q=test'
curl 'http://127.0.0.1:8081/?q=search'

# Malicious GET requests (will be blocked)
curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'
curl 'http://127.0.0.1:8081/?q=admin%27--'
curl 'http://127.0.0.1:8081/?q=<script>alert(1)</script>'

# Good POST requests
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"test"}'

# Malicious POST requests (will be blocked)
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin' OR '1'='1&password=x"
```

### Step 4: Verify CSV Files Have Data

```bash
cd ~/Capstone-Project/backend

# Check GET request CSVs
echo "Good requests:"
wc -l Data_Collection/Good_req.csv
head -5 Data_Collection/Good_req.csv

echo "Bad requests:"
wc -l Data_Collection/Bad_req.csv
head -5 Data_Collection/Bad_req.csv

# Check POST payload CSVs
echo "Benign payloads:"
wc -l benign_payloads.csv

echo "Malicious payloads:"
wc -l malicious_payloads.csv
```

### Step 5: Check API Response

```bash
# Test API endpoints directly
curl http://localhost:5174/api/stats/get-requests
curl http://localhost:5174/api/stats/post-payloads
curl http://localhost:5174/api/stats/network-firewall

# Check API debug endpoint
curl http://localhost:5174/api/debug/paths
```

### Step 6: Refresh Dashboard

After sending test requests:
1. Wait 5 seconds (dashboard auto-refreshes every 5 seconds)
2. Or manually refresh the browser (F5)
3. Check browser console (F12) for any errors

## Common Issues and Solutions

### Issue 1: CSV Files Only Have Headers

**Symptom:** CSV files exist but only contain header row

**Solution:** Send requests to the WAF to populate data
```bash
./generate_test_data.sh
```

### Issue 2: API Returns Empty Data

**Symptom:** API responds but returns `{"goodCount": 0, "badCount": 0}`

**Solution:** 
1. Check if BACKEND_ROOT is set correctly:
   ```bash
   echo $BACKEND_ROOT
   # Should be: /home/kali/Capstone-Project/backend
   ```
2. Restart API with correct BACKEND_ROOT:
   ```bash
   cd ~/Capstone-Project/frontend
   export BACKEND_ROOT=$HOME/Capstone-Project/backend
   npm run api
   ```

### Issue 3: API Not Accessible

**Symptom:** Dashboard shows API errors in console

**Solution:**
1. Check if API is running:
   ```bash
   ps aux | grep "server.mjs"
   ```
2. Start API if not running:
   ```bash
   cd ~/Capstone-Project/frontend
   export BACKEND_ROOT=$HOME/Capstone-Project/backend
   npm run api
   ```

### Issue 4: WAF Not Writing to CSV Files

**Symptom:** Requests are processed but CSV files remain empty

**Solution:**
1. Check WAF logs:
   ```bash
   tail -f ~/Capstone-Project/backend/waf.log
   ```
2. Check file permissions:
   ```bash
   ls -la ~/Capstone-Project/backend/Data_Collection/
   ```
3. Ensure WAF has write permissions:
   ```bash
   chmod 755 ~/Capstone-Project/backend/Data_Collection
   ```

### Issue 5: CSV Files in Wrong Location

**Symptom:** API can't find CSV files

**Solution:**
1. Check where API is looking:
   ```bash
   curl http://localhost:5174/api/debug/paths
   ```
2. Set BACKEND_ROOT correctly:
   ```bash
   export BACKEND_ROOT=$HOME/Capstone-Project/backend
   ```
3. Restart API

## Verification Checklist

After following the steps above, verify:

- [ ] WAF is running and processing requests
- [ ] CSV files exist and contain data (more than just headers)
- [ ] API is running on port 5174
- [ ] API can read CSV files (check `/api/debug/paths`)
- [ ] API returns non-zero counts (check `/api/stats/get-requests`)
- [ ] Dashboard is accessible on port 8080
- [ ] Browser console shows no errors (F12)
- [ ] Dashboard auto-refreshes every 5 seconds

## Expected Results

After sending test requests, you should see:

- **Good URLs**: Count of benign GET requests
- **Bad URLs**: Count of malicious GET requests  
- **Benign Payloads**: Count of benign POST requests
- **Malicious Payloads**: Count of malicious POST requests
- **Network Firewall**: Counts of allowed/blocked packets
- **ML Training Overview**: Graph showing training metrics

## Still Not Working?

1. **Check all logs:**
   ```bash
   tail -f ~/Capstone-Project/backend/waf.log
   tail -f ~/Capstone-Project/frontend/api.log
   tail -f ~/Capstone-Project/frontend/ui.log
   ```

2. **Run full diagnostic:**
   ```bash
   cd ~/Capstone-Project/backend
   python3 diagnose_dashboard.py
   ```

3. **Check browser console:**
   - Open browser (F12)
   - Go to Console tab
   - Look for errors or failed API calls

4. **Verify environment variables:**
   ```bash
   echo "BACKEND_ROOT: $BACKEND_ROOT"
   ```

5. **Restart all services:**
   ```bash
   # Stop all
   pkill -f 'Proxy_server.py'
   pkill -f 'network_sniffer_fallback.py'
   pkill -f 'server.mjs'
   pkill -f 'vite'
   
   # Start all using the startup script
   cd ~/Capstone-Project/backend
   ./start_all.sh
   ```

## Quick Test Commands

```bash
# 1. Check if WAF is running
curl http://127.0.0.1:8081/test

# 2. Send a test request
curl 'http://127.0.0.1:8081/?q=hello'

# 3. Check if data was written
tail -1 ~/Capstone-Project/backend/Data_Collection/Good_req.csv

# 4. Check API response
curl http://localhost:5174/api/stats/get-requests

# 5. Check dashboard
curl http://localhost:8080
```

