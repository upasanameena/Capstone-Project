#!/bin/bash
# Complete Fix Script for netfilterqueue Installation

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Fixing Kali Repositories & Installing Dependencies   ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Fix Kali repositories
echo "📦 Step 1: Fixing Kali repositories..."
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup 2>/dev/null || true

# Remove problematic repos
sudo rm -f /etc/apt/sources.list.d/* 2>/dev/null || true

# Add official mirror
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list > /dev/null

# Update GPG keys
echo "🔑 Updating GPG keys..."
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6 2>/dev/null || echo "GPG key update skipped"

# Clean and update
echo "🔄 Updating package lists..."
sudo apt clean
sudo apt update

# Step 2: Install system dependencies
echo ""
echo "📦 Step 2: Installing system dependencies..."
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

if [ $? -ne 0 ]; then
    echo "⚠️  Some packages failed to install. Trying alternative method..."
    
    # Try installing from Debian (compatible)
    echo "📥 Attempting to download from Debian..."
    cd /tmp
    
    # Download compatible packages
    wget -q http://http.debian.net/debian/pool/main/libn/libnfnetlink/libnfnetlink-dev_1.0.2-1_amd64.deb 2>/dev/null
    wget -q http://http.debian.net/debian/pool/main/n/netfilter-queue/libnetfilter-queue-dev_1.0.5-2_amd64.deb 2>/dev/null
    
    if [ -f libnfnetlink-dev_*.deb ]; then
        sudo dpkg -i libnfnetlink-dev_*.deb libnetfilter-queue-dev_*.deb 2>/dev/null
        sudo apt install -f
    fi
fi

# Step 3: Install Python packages
echo ""
echo "🐍 Step 3: Installing Python packages..."
cd ~/Capstone-Project/backend
source venv/bin/activate

pip install --upgrade pip
pip install --no-cache-dir netfilterqueue
pip install scapy

# Step 4: Verify
echo ""
echo "✅ Step 4: Verifying installation..."
python3 -c "import netfilterqueue; print('✅ netfilterqueue installed!')" 2>/dev/null && echo "✅ netfilterqueue: OK" || echo "❌ netfilterqueue: FAILED"
python3 -c "import scapy; print('✅ scapy installed!')" 2>/dev/null && echo "✅ scapy: OK" || echo "❌ scapy: FAILED"

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
if python3 -c "import netfilterqueue; import scapy" 2>/dev/null; then
    echo "║  ✅ Installation Complete! Network Firewall Ready!      ║"
    echo "║                                                          ║"
    echo "║  Start with: sudo python3 network_firewall.py           ║"
else
    echo "║  ⚠️  Installation incomplete. Check errors above.        ║"
    echo "║  Try manual installation from FIX_KALI_REPO_AND_INSTALL.md║"
fi
echo "╚══════════════════════════════════════════════════════════╝"

