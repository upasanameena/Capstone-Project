# Troubleshooting Guide

## Problem: 404 Error on localhost:8080

If you see "404 -- Not Found" or "Cannot locate document: /" on port 8080, it means the Vite dev server is not running correctly.

### Solution 1: Stop any conflicting servers

**On Windows:**
```powershell
# Find what's using port 8080
netstat -ano | findstr :8080

# Kill the process (replace PID with the number from above)
taskkill /PID <PID> /F
```

**On Linux/Kali:**
```bash
# Find what's using port 8080
sudo lsof -i :8080
# or
sudo netstat -tulpn | grep :8080

# Kill the process (replace PID with the number from above)
sudo kill -9 <PID>
```

### Solution 2: Start Vite dev server correctly

**Make sure you're in the correct directory:**
```bash
cd sentinel-blaze-main
```

**Start the dev server:**
```bash
npm run dev
```

**You should see output like:**
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:8080/
  ➜  Network: http://[::]:8080/
```

If you see this, the server is running correctly. Open `http://localhost:8080/` (with trailing slash).

### Solution 3: Check if ports are already in use

**Windows:**
```powershell
netstat -ano | findstr :8080
netstat -ano | findstr :5174
```

**Linux/Kali:**
```bash
sudo lsof -i :8080
sudo lsof -i :5174
```

If ports are in use, either:
- Stop the conflicting service
- Change ports in `vite.config.ts` (for UI) and `server.mjs` (for API)

### Solution 4: Verify both servers are running

You need **TWO terminals** running:

**Terminal 1 - API Server:**
```bash
cd sentinel-blaze-main
npm run api
# Should show: "CSV read-only API listening on http://localhost:5174"
```

**Terminal 2 - UI Server:**
```bash
cd sentinel-blaze-main
npm run dev
# Should show: "Local: http://localhost:8080/"
```

### Solution 5: Clear cache and reinstall

```bash
# Remove node_modules and lock files
rm -rf node_modules package-lock.json

# Reinstall
npm install

# Try again
npm run dev
```

### Solution 6: Check firewall

**Windows:**
- Allow ports 8080 and 5174 in Windows Firewall

**Linux/Kali:**
```bash
# Check firewall status
sudo ufw status

# Allow ports if needed
sudo ufw allow 8080
sudo ufw allow 5174
```

## Problem: Graphs are empty but UI loads

1. **Check API server is running:**
   - Visit: `http://localhost:5174/api/debug/paths`
   - Should show JSON with file paths and existence status

2. **Check browser console (F12):**
   - Look for errors in Console tab
   - Check Network tab for failed API requests

3. **Verify CSV files exist:**
   - Check the paths shown in API server terminal
   - Ensure CSV files are in the backend project folder

4. **Check BACKEND_ROOT environment variable:**
   ```bash
   # If backend is not a sibling folder, set this:
   export BACKEND_ROOT=/path/to/kali-vm-project-main
   npm run api
   ```

## Problem: CORS errors

The API server should handle CORS, but if you see CORS errors:
- Make sure API server is running on port 5174
- Check that Vite proxy is configured in `vite.config.ts`
- Try accessing API directly: `http://localhost:5174/api/stats/get-requests`

## Still having issues?

1. Check all terminal output for error messages
2. Open browser DevTools (F12) and check Console/Network tabs
3. Visit the debug endpoint: `http://localhost:5174/api/debug/paths`
4. Verify Node.js version: `node -v` (should be 18+)

