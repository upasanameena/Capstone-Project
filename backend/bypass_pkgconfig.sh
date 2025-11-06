#!/bin/bash
# Bypass pkg-config entirely by manually patching configure script

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Bypass pkg-config: Manual Configure Patch              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

cd /tmp

# Clean and extract
if [ -d libnetfilter_queue-1.0.5 ]; then
    rm -rf libnetfilter_queue-1.0.5
fi

echo "📥 Downloading source..."
wget -q https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2
tar -xjf libnetfilter_queue-1.0.5.tar.bz2
cd libnetfilter_queue-1.0.5

# Edit configure.ac to remove LIBMNL requirement
echo "🔧 Patching configure.ac..."
sed -i 's/^PKG_CHECK_MODULES(LIBMNL, libmnl)/# LIBMNL disabled - optional\nLIBMNL_LIBS=""\nLIBMNL_CFLAGS=""/g' configure.ac

# If autoconf is available, regenerate
if command -v autoreconf &> /dev/null; then
    echo "🔄 Regenerating configure with autoreconf..."
    autoreconf -fiv
else
    echo "⚠️  autoreconf not found, patching configure directly..."
    
    # Manually patch the configure script to skip LIBMNL check
    # Find the section that checks for LIBMNL and replace it
    sed -i '/^checking for LIBMNL/,/^LIBMNL_LIBS=/{
        /^checking for LIBMNL/c\
LIBMNL_LIBS=""\
LIBMNL_CFLAGS=""
        /^LIBMNL_LIBS=/d
        /^LIBMNL_CFLAGS=/d
    }' configure
    
    # Also disable the pkg-config check for LIBMNL
    sed -i 's/^PKG_CHECK_MODULES(LIBMNL/# PKG_CHECK_MODULES(LIBMNL - disabled/g' configure 2>/dev/null || true
    
    # Set LIBMNL variables directly in configure
    sed -i '/^LIBMNL_LIBS=/d' configure
    sed -i '/^LIBMNL_CFLAGS=/d' configure
    sed -i '/^# LIBMNL disabled/a\
LIBMNL_LIBS=""\
LIBMNL_CFLAGS=""' configure
fi

# Configure with explicit environment variables to bypass pkg-config
echo "⚙️  Configuring (bypassing pkg-config)..."
export PKG_CONFIG=/bin/false
export LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink"
export LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink"
export LIBMNL_CFLAGS=""
export LIBMNL_LIBS=""

# Run configure and capture output
if ./configure --prefix=/usr 2>&1 | tee /tmp/configure.log | grep -q "error"; then
    echo "❌ Configure failed. Checking config.log..."
    tail -30 config.log
    exit 1
fi

# Check if Makefile was created
if [ ! -f Makefile ]; then
    echo "❌ Makefile not created. Configure failed."
    tail -50 config.log
    exit 1
fi

echo "✅ Configure successful!"

# Build
echo "🔨 Building..."
make -j$(nproc)

# Install
echo "📦 Installing..."
sudo make install
sudo ldconfig

# Verify headers
echo "🔍 Verifying headers..."
if [ -f /usr/include/libnetfilter_queue/libnetfilter_queue.h ]; then
    echo "✅ Headers installed: /usr/include/libnetfilter_queue/"
    ls -la /usr/include/libnetfilter_queue/
else
    echo "⚠️  Headers not in expected location, searching..."
    find /usr/include -name "*netfilter_queue*" -type f 2>/dev/null || true
    find /usr/local/include -name "*netfilter_queue*" -type f 2>/dev/null || true
fi

# Install Python package
echo ""
echo "🐍 Installing Python netfilterqueue..."
cd ~/Capstone-Project/backend
source venv/bin/activate

# Find header location
HEADER_DIR=$(find /usr/include /usr/local/include -name "libnetfilter_queue.h" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "/usr/include/libnetfilter_queue")

export CFLAGS="-I/usr/include/libnfnetlink -I${HEADER_DIR}"
export LDFLAGS="-L/usr/lib -lnfnetlink -lnetfilter_queue"

echo "Using CFLAGS: $CFLAGS"
echo "Using LDFLAGS: $LDFLAGS"

pip install --no-cache-dir netfilterqueue

# Verify
echo ""
if python3 -c "import netfilterqueue; print('✅ SUCCESS!')" 2>/dev/null; then
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅ Installation Complete! Network Firewall Ready!        ║"
    echo "║                                                          ║"
    echo "║  Start with: sudo python3 network_firewall.py            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    echo "❌ Python import failed. Check errors above."
    python3 -c "import netfilterqueue" 2>&1
    exit 1
fi

