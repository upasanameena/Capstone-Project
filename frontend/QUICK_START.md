# Quick Start Guide

## 🚀 To Run the Visualization Dashboard

### Step 1: Check for Port Conflicts (IMPORTANT!)

**On Windows (PowerShell):**
```powershell
# Check what's using port 8080
netstat -ano | findstr :8080

# If you see output, kill that process:
# First, note the PID (last number in the output)
# Then kill it:
taskkill /PID <PID_NUMBER> /F

# Check port 5174 too
netstat -ano | findstr :5174
taskkill /PID <PID_NUMBER> /F  # if needed
```

**On Linux/Kali:**
```bash
# Check what's using port 8080
sudo lsof -i :8080

# Kill the process if found
sudo kill -9 <PID>

# Check port 5174
sudo lsof -i :5174
sudo kill -9 <PID>  # if needed
```

### Step 2: Start Both Servers

**Open TWO terminals:**

**Terminal 1 - Start API Server:**
```bash
cd sentinel-blaze-main

# If backend is not in sibling folder, set this:
export BACKEND_ROOT=/path/to/kali-vm-project-main  # Linux/Kali
# OR
set BACKEND_ROOT=C:\path\to\kali-vm-project-main    # Windows CMD

npm run api
```

**You should see:**
```
CSV read-only API listening on http://localhost:5174
Backend root: /path/to/kali-vm-project-main
CSV paths:
  goodReq: .../Good_req.csv ✓
  badReq: .../Bad_req.csv ✓
  ...
```

**Terminal 2 - Start UI Server:**
```bash
cd sentinel-blaze-main
npm run dev
```

**You should see:**
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:8080/
  ➜  Network: http://[::]:8080/
```

### Step 3: Open Browser

Open: **http://localhost:8080/** (note the trailing slash)

You should see the dashboard with:
- ✅ URL Filter Analysis (GET) - Good vs Bad URLs
- ✅ Payload Classification (POST) - Benign vs Malware
- ✅ ML Model Training Overview - Training progress chart

### Step 4: Verify Data is Loading

1. **Check browser console (F12):**
   - Should see: "GET stats: {goodCount: X, badCount: Y}"
   - Should see: "POST stats: {benignCount: X, maliciousCount: Y}"

2. **Visit debug endpoint:**
   - Open: `http://localhost:5174/api/debug/paths`
   - Should show JSON with file paths and existence status

3. **If graphs are empty:**
   - Check API server terminal for CSV file paths
   - Verify CSV files exist in backend project
   - Check browser console for errors

## ⚠️ Common Issues

### Issue: "404 -- Not Found" on port 8080
**Solution:** Another server is using port 8080. Kill it first (see Step 1 above).

### Issue: "Cannot connect to API" or CORS errors
**Solution:** Make sure API server (Terminal 1) is running on port 5174.

### Issue: Graphs are empty
**Solution:** 
1. Check API server terminal - CSV files should show ✓
2. Visit `http://localhost:5174/api/debug/paths` to verify files
3. Check browser console (F12) for errors

### Issue: "CSV file not found" in API server
**Solution:** Set BACKEND_ROOT environment variable:
```bash
export BACKEND_ROOT=/absolute/path/to/kali-vm-project-main
npm run api
```

## 📝 For Kali Linux VM

After transferring project via Git/SCP/USB:

```bash
# 1. Install Node.js (if not installed)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# 2. Install dependencies
cd ~/sentinel-blaze-main
npm install

# 3. Set backend path (if needed)
export BACKEND_ROOT=/path/to/kali-vm-project-main

# 4. Start servers (two terminals)
npm run api    # Terminal 1
npm run dev    # Terminal 2

# 5. Open browser
# Inside VM: http://localhost:8080
# From host: http://<VM_IP>:8080
```

## 🔍 Debug Checklist

- [ ] API server running on port 5174
- [ ] UI server running on port 8080
- [ ] No port conflicts (checked with netstat/lsof)
- [ ] CSV files exist (check API server output)
- [ ] Browser console shows no errors
- [ ] Debug endpoint works: `http://localhost:5174/api/debug/paths`

