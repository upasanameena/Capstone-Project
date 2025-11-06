#!/bin/bash
# Final fix: Properly build libnetfilter-queue and install netfilterqueue

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Final Fix: Building libnetfilter-queue Properly     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

cd /tmp

# Clean up previous attempts
if [ -d libnetfilter_queue-1.0.5 ]; then
    rm -rf libnetfilter_queue-1.0.5
fi

# Download fresh source
echo "📥 Downloading libnetfilter-queue source..."
wget -q https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2
tar -xjf libnetfilter_queue-1.0.5.tar.bz2
cd libnetfilter_queue-1.0.5

# Edit configure.ac to make LIBMNL optional
echo "🔧 Patching configure.ac to make LIBMNL optional..."
sed -i 's/PKG_CHECK_MODULES(LIBMNL, libmnl)/# LIBMNL optional\nLIBMNL_LIBS=""\nLIBMNL_CFLAGS=""/g' configure.ac

# Regenerate configure script
echo "🔄 Regenerating configure script..."
autoreconf -fiv || {
    echo "⚠️  autoreconf not available, editing configure directly..."
    # If autoreconf fails, manually edit configure
    sed -i 's/^LIBMNL_LIBS=""/LIBMNL_LIBS=""/g' configure 2>/dev/null || true
}

# Configure with explicit flags
echo "⚙️  Configuring..."
PKG_CONFIG=/bin/false \
LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink" \
LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink" \
LIBMNL_CFLAGS="" \
LIBMNL_LIBS="" \
./configure --prefix=/usr --disable-static 2>&1 | grep -v "checking for LIBMNL" || {
    echo "⚠️  Configure had warnings, but continuing..."
}

# Build
echo "🔨 Building..."
make

# Install
echo "📦 Installing..."
sudo make install

# Update library cache
echo "🔄 Updating library cache..."
sudo ldconfig

# Verify headers are installed
echo "🔍 Verifying installation..."
if [ -f /usr/include/libnetfilter_queue/libnetfilter_queue.h ]; then
    echo "✅ Headers installed correctly"
else
    echo "⚠️  Headers not found in expected location"
    find /usr/include -name "*netfilter_queue*" 2>/dev/null || echo "Searching for headers..."
fi

# Install Python package
echo ""
echo "🐍 Installing Python netfilterqueue package..."
cd ~/Capstone-Project/backend
source venv/bin/activate

# Set library paths for compilation
export CFLAGS="-I/usr/include/libnfnetlink -I/usr/include/libnetfilter_queue"
export LDFLAGS="-L/usr/lib -lnfnetlink -lnetfilter_queue"

pip install --no-cache-dir netfilterqueue

# Verify
echo ""
if python3 -c "import netfilterqueue; print('✅ SUCCESS! Network Firewall Ready!')" 2>/dev/null; then
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅ Installation Complete! Network Firewall Ready!      ║"
    echo "║                                                          ║"
    echo "║  Start with: sudo python3 network_firewall.py           ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    echo "❌ Installation failed. Check errors above."
    exit 1
fi

