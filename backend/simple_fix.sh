#!/bin/bash
# Simple fix: Manually edit configure script to skip LIBMNL

set -e

cd /tmp/libnetfilter_queue-1.0.5

echo "🔧 Patching configure script..."

# Find and replace the LIBMNL check section
# Look for the section that checks for LIBMNL and make it optional
sed -i '/^checking for LIBMNL/,/^LIBMNL_LIBS=/c\
LIBMNL_LIBS=""\
LIBMNL_CFLAGS=""' configure

# Also skip the pkg-config check for LIBMNL
sed -i 's/^PKG_CHECK_MODULES(LIBMNL/# PKG_CHECK_MODULES(LIBMNL/g' configure 2>/dev/null || true

# Make sure configure doesn't fail on LIBMNL
sed -i 's/if test "x$LIBMNL_LIBS" = "x"; then/if false; then # LIBMNL disabled/g' configure

# Configure with minimal requirements
echo "⚙️  Configuring..."
LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink" \
LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink" \
./configure --prefix=/usr || {
    echo "⚠️  Configure failed, trying alternative approach..."
    # Try without explicit flags
    ./configure --prefix=/usr \
        LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink" \
        LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink"
}

# Build
echo "🔨 Building..."
make

# Install
echo "📦 Installing..."
sudo make install
sudo ldconfig

# Verify headers
if [ -f /usr/include/libnetfilter_queue/libnetfilter_queue.h ]; then
    echo "✅ Headers installed: /usr/include/libnetfilter_queue/"
else
    echo "⚠️  Checking header locations..."
    find /usr/include -name "*netfilter_queue*" -type f
fi

# Install Python package
echo ""
echo "🐍 Installing Python netfilterqueue..."
cd ~/Capstone-Project/backend
source venv/bin/activate

export CFLAGS="-I/usr/include/libnfnetlink -I/usr/include/libnetfilter_queue"
export LDFLAGS="-L/usr/lib -lnfnetlink -lnetfilter_queue"

pip install --no-cache-dir netfilterqueue

# Verify
if python3 -c "import netfilterqueue" 2>/dev/null; then
    echo ""
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅ SUCCESS! Network Firewall Ready!                    ║"
    echo "║                                                          ║"
    echo "║  Start: sudo python3 network_firewall.py                ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    echo "❌ Python package failed. Check CFLAGS and LDFLAGS."
    exit 1
fi

