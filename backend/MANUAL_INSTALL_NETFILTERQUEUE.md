# Manual Installation: netfilterqueue

## Problem
Missing `libnfnetlink-dev` headers causing compilation failure.

## Solution: Manual Installation Steps

### Step 1: Install libnfnetlink-dev Manually

```bash
# Try downloading .deb file directly
cd /tmp

# Download libnfnetlink-dev (replace with your Kali version)
wget http://http.kali.org/kali/pool/main/libn/libnfnetlink/libnfnetlink-dev_1.0.2-2_amd64.deb

# Or find the correct version for your system
apt-cache search libnfnetlink-dev

# Install the downloaded .deb
sudo dpkg -i libnfnetlink-dev_*.deb

# Fix any dependencies
sudo apt install -f
```

### Step 2: Install Other Required Packages

```bash
# Install build essentials (these usually work even with repo issues)
sudo apt install -y build-essential python3-dev gcc g++ make 2>/dev/null || echo "Some packages may fail"

# Try to get libnetfilter-queue-dev (may fail due to repo)
sudo apt install -y libnetfilter-queue-dev 2>/dev/null || echo "Will try alternative method"
```

### Step 3: Install netfilterqueue via pip

```bash
cd ~/Capstone-Project/backend
source venv/bin/activate

# Now try pip install
pip install netfilterqueue
```

---

## Alternative: Download All .deb Files Manually

If apt completely fails:

```bash
cd /tmp

# Download all required packages (adjust URLs for your Kali version)
wget http://http.kali.org/kali/pool/main/libn/libnfnetlink/libnfnetlink-dev_1.0.2-2_amd64.deb
wget http://http.kali.org/kali/pool/main/libn/libnfnetlink/libnfnetlink1_1.0.2-2_amd64.deb
wget http://http.kali.org/kali/pool/main/n/netfilter-queue/libnetfilter-queue-dev_1.0.5-1_amd64.deb
wget http://http.kali.org/kali/pool/main/n/netfilter-queue/libnetfilter-queue1_1.0.5-1_amd64.deb

# Install them
sudo dpkg -i *.deb
sudo apt install -f  # Fix any missing dependencies
```

---

## Best Solution: Skip Network Firewall for Demo

**The network firewall is optional!** Your capstone project works perfectly with just the Application WAF.

**Run these 3 services instead:**

```bash
# Terminal 1 - WAF
cd ~/Capstone-Project/backend
source venv/bin/activate
python3 Proxy_server.py

# Terminal 2 - API
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=/home/kali/Capstone-Project/backend
npm run api

# Terminal 3 - UI
cd ~/Capstone-Project/frontend
npm run dev
```

**You'll get:**
- ✅ URL Filter Analysis (GET)
- ✅ Payload Classification (POST)
- ✅ ML Model Training Overview
- ⚠️ Network Firewall (will show "no data" - that's okay!)

**This is still a complete capstone project!** The Application WAF is the main feature.

