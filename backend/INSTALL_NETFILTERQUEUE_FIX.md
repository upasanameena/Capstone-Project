# Fix: Install netfilterqueue Without Broken Kali Repo

## Problem
Kali repository returns 403 Forbidden, can't install via apt.

## Solution: Install from Source with Manual Dependencies

### Step 1: Install System Dependencies Manually

```bash
# Try to install via apt (may fail, but try first)
sudo apt update || true
sudo apt install -y libnetfilter-queue-dev libnfnetlink-dev libmnl-dev python3-dev build-essential gcc g++ make || true

# If apt fails, download .deb files manually or use alternative method below
```

### Step 2: Install netfilterqueue via pip (Recommended)

```bash
cd ~/Capstone-Project/backend
source venv/bin/activate

# Install system libraries first (if apt works)
sudo apt install -y libnetfilter-queue-dev libnfnetlink-dev libmnl-dev python3-dev build-essential 2>/dev/null || echo "APT failed, continuing..."

# Install via pip (this will compile from source)
pip install --upgrade pip
pip install --no-cache-dir netfilterqueue

# If that fails, try:
pip install --no-binary netfilterqueue netfilterqueue
```

### Step 3: Alternative - Download and Install Manually

If pip still fails, download the source:

```bash
# Download netfilterqueue source
cd /tmp
wget https://github.com/kti/python-netfilterqueue/archive/refs/heads/master.zip
unzip master.zip
cd python-netfilterqueue-master

# Install
python3 setup.py install
```

### Step 4: Verify Installation

```bash
python3 -c "import netfilterqueue; print('✅ netfilterqueue installed!')"
```

---

## Alternative: Skip Network Firewall for Now

If netfilterqueue installation continues to fail, you can:

1. **Run Application WAF only** (works without network firewall)
2. **Network firewall is optional** - the system works without it
3. **Focus on WAF + Visualization** for your demo

The Application WAF (port 8081) works independently and is the main feature.

---

## Quick Test Without Network Firewall

**Terminal 1 - Application WAF:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
python3 Proxy_server.py
```

**Terminal 2 - API:**
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=/home/kali/Capstone-Project/backend
npm run api
```

**Terminal 3 - UI:**
```bash
cd ~/Capstone-Project/frontend
npm run dev
```

You'll get 3 out of 4 visualizations working (Network Firewall section will show "no data" but that's okay).

---

## Best Solution: Fix Kali Repo First

If you want to fix the repo issue:

```bash
# Fix Kali repositories
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Edit sources (use official mirror)
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

# Update
sudo apt update

# Now try installing dependencies
sudo apt install -y libnetfilter-queue-dev libnfnetlink-dev python3-dev build-essential
pip install netfilterqueue
```

