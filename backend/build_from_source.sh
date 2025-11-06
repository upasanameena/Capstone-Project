#!/bin/bash
# Build netfilterqueue from source (when Kali repo is blocked)

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Building netfilterqueue from Source                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Check if running as regular user (not root)
if [ "$EUID" -eq 0 ]; then 
    echo "❌ Don't run this script with sudo. It will use sudo for specific commands."
    exit 1
fi

# Install build tools
echo "📦 Step 1: Installing build tools..."
sudo apt install -y build-essential gcc g++ make cmake pkg-config python3-dev 2>/dev/null || echo "Some packages may fail, continuing..."

cd /tmp

# Step 2: Build libnfnetlink
echo ""
echo "📦 Step 2: Building libnfnetlink from source..."
if [ ! -f libnfnetlink-1.0.2.tar.bz2 ]; then
    wget https://www.netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.2.tar.bz2
fi

if [ -d libnfnetlink-1.0.2 ]; then
    rm -rf libnfnetlink-1.0.2
fi

tar -xjf libnfnetlink-1.0.2.tar.bz2
cd libnfnetlink-1.0.2

./configure --prefix=/usr
make
sudo make install
cd /tmp

# Step 3: Build libnetfilter-queue
echo ""
echo "📦 Step 3: Building libnetfilter-queue from source..."
if [ ! -f libnetfilter_queue-1.0.5.tar.bz2 ]; then
    wget https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2
fi

if [ -d libnetfilter_queue-1.0.5 ]; then
    rm -rf libnetfilter_queue-1.0.5
fi

tar -xjf libnetfilter_queue-1.0.5.tar.bz2
cd libnetfilter_queue-1.0.5

# Set environment variables to bypass pkg-config requirement
export LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink"
export LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink"

# Configure without pkg-config
PKG_CONFIG=/bin/false ./configure --prefix=/usr \
    LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink" \
    LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink"

make
sudo make install

# Step 4: Update library path
echo ""
echo "📦 Step 4: Updating library paths..."
sudo ldconfig

# Verify libraries
echo ""
echo "🔍 Verifying libraries..."
ldconfig -p | grep nfnetlink || echo "⚠️  libnfnetlink not found in library path"
ldconfig -p | grep netfilter_queue || echo "⚠️  libnetfilter_queue not found in library path"

# Step 5: Install Python package
echo ""
echo "🐍 Step 5: Installing Python netfilterqueue package..."
cd ~/Capstone-Project/backend

# Activate venv if it exists
if [ -d venv ]; then
    source venv/bin/activate
else
    echo "Creating virtual environment..."
    python3 -m venv venv
    source venv/bin/activate
fi

pip install --upgrade pip
pip install --no-cache-dir netfilterqueue

# Step 6: Verify
echo ""
echo "✅ Step 6: Verifying installation..."
if python3 -c "import netfilterqueue" 2>/dev/null; then
    echo "✅ netfilterqueue: SUCCESS!"
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅ Installation Complete! Network Firewall Ready!       ║"
    echo "║                                                          ║"
    echo "║  Start with: sudo python3 network_firewall.py           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    echo "❌ netfilterqueue: FAILED"
    echo ""
    echo "Troubleshooting:"
    echo "1. Check if libraries are installed: ldconfig -p | grep nfnetlink"
    echo "2. Try: export LD_LIBRARY_PATH=/usr/local/lib:\$LD_LIBRARY_PATH"
    echo "3. Rebuild: sudo ldconfig"
fi

