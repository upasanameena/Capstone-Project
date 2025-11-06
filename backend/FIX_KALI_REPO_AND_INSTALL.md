# Complete Fix: Kali Repository + Network Firewall Installation

## Step-by-Step Solution

### Step 1: Fix Kali Repositories Completely

```bash
# Backup current sources
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Remove old sources
sudo rm /etc/apt/sources.list.d/* 2>/dev/null || true

# Create new sources.list with official mirror
sudo tee /etc/apt/sources.list > /dev/null <<EOF
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
deb-src http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
EOF

# Update GPG keys
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6

# Clean and update
sudo apt clean
sudo apt update
```

### Step 2: Find Correct Package Versions

```bash
# Check your Kali version
cat /etc/os-release

# Search for available packages
apt-cache search libnfnetlink
apt-cache search libnetfilter-queue

# Show available versions
apt-cache policy libnfnetlink-dev
apt-cache policy libnetfilter-queue-dev
```

### Step 3: Install Required Dependencies

```bash
# Install all required packages
sudo apt install -y \
    libnfnetlink-dev \
    libnetfilter-queue-dev \
    libmnl-dev \
    libnetfilter-queue1 \
    libnfnetlink1 \
    python3-dev \
    build-essential \
    gcc \
    g++ \
    make \
    pkg-config
```

### Step 4: Install netfilterqueue via pip

```bash
cd ~/Capstone-Project/backend
source venv/bin/activate

# Install netfilterqueue
pip install --upgrade pip
pip install --no-cache-dir netfilterqueue

# Install scapy
pip install scapy
```

### Step 5: Verify Installation

```bash
# Test imports
python3 -c "import netfilterqueue; print('✅ netfilterqueue OK')"
python3 -c "import scapy; print('✅ scapy OK')"

# Test network firewall
sudo python3 network_firewall.py
# Should start without errors
```

---

## Alternative: If Repository Still Fails

### Option A: Use Debian Packages (Compatible)

```bash
# Download from Debian (usually compatible)
cd /tmp

# Download libnfnetlink-dev
wget http://http.debian.net/debian/pool/main/libn/libnfnetlink/libnfnetlink-dev_1.0.2-1_amd64.deb

# Download libnetfilter-queue-dev
wget http://http.debian.net/debian/pool/main/n/netfilter-queue/libnetfilter-queue-dev_1.0.5-2_amd64.deb

# Install
sudo dpkg -i *.deb
sudo apt install -f  # Fix dependencies
```

### Option B: Build from Source

```bash
# Download libnfnetlink source
cd /tmp
wget https://www.netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.2.tar.bz2
tar -xjf libnfnetlink-1.0.2.tar.bz2
cd libnfnetlink-1.0.2
./configure
make
sudo make install

# Download libnetfilter-queue source
cd /tmp
wget https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2
tar -xjf libnetfilter_queue-1.0.5.tar.bz2
cd libnetfilter_queue-1.0.5
./configure
make
sudo make install

# Update library path
sudo ldconfig

# Now install netfilterqueue
pip install netfilterqueue
```

---

## Quick Fix Script

Save this as `fix_and_install.sh`:

```bash
#!/bin/bash
echo "Fixing Kali repositories..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6
sudo apt clean
sudo apt update

echo "Installing dependencies..."
sudo apt install -y libnfnetlink-dev libnetfilter-queue-dev libmnl-dev python3-dev build-essential

echo "Installing Python packages..."
cd ~/Capstone-Project/backend
source venv/bin/activate
pip install netfilterqueue scapy

echo "✅ Installation complete!"
```

Run: `chmod +x fix_and_install.sh && sudo ./fix_and_install.sh`

