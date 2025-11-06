# Kali Linux Path Setup Guide

## Your Project Structure

Based on your screenshots:
- **UI Project**: `/home/kali/capstone` (or `/kali/capstone` if it's a mount)
- **WAF Backend Project**: `/home/kali/Documents/projects/Web_Application_Firewall`

## Quick Setup

### Step 1: Navigate to UI Project

```bash
cd ~/capstone
# OR if it's at /kali/capstone:
cd /kali/capstone
```

### Step 2: Set Backend Root Path

**Option A: Set for current session (temporary)**
```bash
export BACKEND_ROOT=/home/kali/Documents/projects/Web_Application_Firewall
```

**Option B: Set permanently (add to ~/.bashrc)**
```bash
echo 'export BACKEND_ROOT=/home/kali/Documents/projects/Web_Application_Firewall' >> ~/.bashrc
source ~/.bashrc
```

### Step 3: Verify CSV Files Exist

```bash
# Check if backend directory exists
ls -la /home/kali/Documents/projects/Web_Application_Firewall

# Check for CSV files
ls -la /home/kali/Documents/projects/Web_Application_Firewall/Data_Collection/Good_req.csv
ls -la /home/kali/Documents/projects/Web_Application_Firewall/Data_Collection/Bad_req.csv
ls -la /home/kali/Documents/projects/Web_Application_Firewall/benign_payloads.csv
ls -la /home/kali/Documents/projects/Web_Application_Firewall/malicious_payloads.csv
```

### Step 4: Start API Server

```bash
cd ~/capstone
export BACKEND_ROOT=/home/kali/Documents/projects/Web_Application_Firewall
npm run api
```

**You should see output like:**
```
╔══════════════════════════════════════════════════════════╗
║  CSV read-only API listening on http://localhost:5174  ║
╚══════════════════════════════════════════════════════════╝

Backend root: /home/kali/Documents/projects/Web_Application_Firewall
Backend root exists: ✓

CSV file status:
  goodReq           : ✓ FOUND (XX.XX KB)
    Path: /home/kali/Documents/projects/Web_Application_Firewall/Data_Collection/Good_req.csv
  badReq            : ✓ FOUND (XX.XX KB)
  ...
✅ All CSV files found! Ready to serve data.
```

### Step 5: Start UI Server (in another terminal)

```bash
cd ~/capstone
npm run dev
```

### Step 6: Open Browser

Open: `http://localhost:8080`

---

## Troubleshooting

### If CSV files show "✗ NOT FOUND"

**1. Check the exact path:**
```bash
# Find your Web_Application_Firewall directory
find ~ -name "Web_Application_Firewall" -type d 2>/dev/null

# Or check Documents
ls -la ~/Documents/projects/
```

**2. Verify CSV file names:**
```bash
# Check what files are in Data_Collection
ls -la ~/Documents/projects/Web_Application_Firewall/Data_Collection/

# Check root directory for payload files
ls -la ~/Documents/projects/Web_Application_Firewall/*.csv
```

**3. Update BACKEND_ROOT with correct path:**
```bash
# If your path is different, update it:
export BACKEND_ROOT=/actual/path/to/Web_Application_Firewall
npm run api
```

### If files have different names

The server will try to find files with these variations:
- `Good_req.csv`, `good_req.csv`, `Good_req.CSV`
- `Bad_req.csv`, `bad_req.csv`, `Bad_req.CSV`
- `benign_payloads.csv`, `Benign_payloads.csv`
- `malicious_payloads.csv`, `Malicious_payloads.csv`

If your files have completely different names, you may need to rename them or update `server.mjs`.

### Check API is working

Visit in browser: `http://localhost:5174/api/debug/paths`

This will show you:
- Current backend root path
- Status of each CSV file
- Actual file paths being checked

---

## Expected CSV File Structure

Your `Web_Application_Firewall` directory should have:

```
Web_Application_Firewall/
├── Data_Collection/
│   ├── Good_req.csv      ← URL filtering: good requests
│   └── Bad_req.csv       ← URL filtering: bad requests
├── benign_payloads.csv   ← Payload classification: benign
└── malicious_payloads.csv ← Payload classification: malicious
```

---

## Quick Test Commands

```bash
# Test 1: Check backend path
echo $BACKEND_ROOT

# Test 2: Check if directory exists
test -d "$BACKEND_ROOT" && echo "✓ Directory exists" || echo "✗ Directory not found"

# Test 3: Check CSV files
for file in "$BACKEND_ROOT/Data_Collection/Good_req.csv" \
            "$BACKEND_ROOT/Data_Collection/Bad_req.csv" \
            "$BACKEND_ROOT/benign_payloads.csv" \
            "$BACKEND_ROOT/malicious_payloads.csv"; do
    test -f "$file" && echo "✓ $(basename $file)" || echo "✗ $(basename $file) - NOT FOUND"
done

# Test 4: Check API endpoint
curl http://localhost:5174/api/debug/paths
```

---

## One-Line Setup

```bash
cd ~/capstone && export BACKEND_ROOT=/home/kali/Documents/projects/Web_Application_Firewall && npm run api
```

Then in another terminal:
```bash
cd ~/capstone && npm run dev
```

