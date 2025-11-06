#!/bin/bash
# Final build: Use the actual source files to build libnetfilter_queue

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Final Build: Using Existing Source Files               ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

cd /tmp/libnetfilter_queue-1.0.5

# Check what source files we have
echo "📁 Checking source files..."
ls -la src/
ls -la include/

# The actual source is in src/libnetfilter_queue.c
# Headers are in include/libnetfilter_queue/

# Build manually using the source files
echo "🔨 Building library manually..."

# Find the actual source file
SRC_FILE=$(find src -name "*.c" | head -1)
HEADER_DIR="include/libnetfilter_queue"

if [ -z "$SRC_FILE" ]; then
    echo "❌ No source file found in src/"
    exit 1
fi

echo "Using source: $SRC_FILE"
echo "Using headers: $HEADER_DIR"

# Compile the library
gcc -fPIC -shared \
    -I./include \
    -I/usr/include/libnfnetlink \
    -o libnetfilter_queue.so \
    "$SRC_FILE" \
    -L/usr/lib -lnfnetlink \
    -Wl,-soname,libnetfilter_queue.so.1

# Check if build succeeded
if [ ! -f libnetfilter_queue.so ]; then
    echo "❌ Build failed"
    exit 1
fi

echo "✅ Library built: libnetfilter_queue.so"

# Install headers and library
echo "📦 Installing..."
sudo mkdir -p /usr/include/libnetfilter_queue
sudo cp -r include/libnetfilter_queue/* /usr/include/libnetfilter_queue/
sudo cp libnetfilter_queue.so /usr/lib/
sudo ldconfig

# Verify installation
echo "🔍 Verifying installation..."
if [ -f /usr/include/libnetfilter_queue/libnetfilter_queue.h ]; then
    echo "✅ Headers installed"
    ls -la /usr/include/libnetfilter_queue/
else
    echo "❌ Headers not found"
    exit 1
fi

if [ -f /usr/lib/libnetfilter_queue.so ]; then
    echo "✅ Library installed"
    ls -la /usr/lib/libnetfilter_queue.so*
else
    echo "❌ Library not found"
    exit 1
fi

# Install Python package
echo ""
echo "🐍 Installing Python netfilterqueue..."
cd ~/Capstone-Project/backend
source venv/bin/activate

export CFLAGS="-I/usr/include/libnfnetlink -I/usr/include/libnetfilter_queue"
export LDFLAGS="-L/usr/lib -lnfnetlink -lnetfilter_queue"

pip install --no-cache-dir netfilterqueue

# Final verification
echo ""
if python3 -c "import netfilterqueue; print('✅ SUCCESS!')" 2>/dev/null; then
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅✅✅ INSTALLATION COMPLETE! ✅✅✅                      ║"
    echo "║                                                          ║"
    echo "║  Network Firewall is ready!                              ║"
    echo "║  Start with: sudo python3 network_firewall.py            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    echo "❌ Python import failed. Checking error..."
    python3 -c "import netfilterqueue" 2>&1
    exit 1
fi

