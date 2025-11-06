#!/bin/bash
# Manual fix: Directly edit configure script to bypass all LIBMNL checks

set -e

echo "╔══════════════════════════════════════════════════════════╗"
echo "║  Manual Configure Fix: Direct Patch                     ║"
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

# First, edit configure.ac
echo "🔧 Step 1: Patching configure.ac..."
sed -i 's/^PKG_CHECK_MODULES(LIBMNL, libmnl)/# LIBMNL disabled\nLIBMNL_LIBS=""\nLIBMNL_CFLAGS=""/g' configure.ac

# Try to install autoconf if not available
if ! command -v autoreconf &> /dev/null; then
    echo "⚠️  autoreconf not found. Attempting to install autoconf..."
    # Try to install from a working source or build from source
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y autoconf automake libtool || {
            echo "⚠️  Could not install autoconf via apt. Will patch configure manually..."
        }
    fi
fi

# If autoconf is now available, regenerate
if command -v autoreconf &> /dev/null; then
    echo "🔄 Regenerating configure with autoreconf..."
    autoreconf -fiv
else
    echo "🔧 Step 2: Manually patching configure script..."
    
    # Create a Python script to properly patch the configure file
    python3 << 'PYTHON_SCRIPT'
import re
import sys

with open('configure', 'r') as f:
    content = f.read()

# Find and replace the LIBMNL check section
# Look for the pattern that checks for LIBMNL using pkg-config
pattern = r'#\s*LIBMNL\n.*?pkg_failed=no.*?fi'
replacement = '''# LIBMNL disabled - using empty values
LIBMNL_LIBS=""
LIBMNL_CFLAGS=""
pkg_failed=no
# Skip pkg-config check'''

# Try multiple patterns
patterns = [
    (r'checking for LIBMNL\.\.\..*?LIBMNL_LIBS=.*?LIBMNL_CFLAGS=.*?fi', 
     'LIBMNL_LIBS=""\nLIBMNL_CFLAGS=""\n# LIBMNL check disabled'),
    (r'PKG_CHECK_MODULES\(LIBMNL.*?\)', 
     '# PKG_CHECK_MODULES(LIBMNL, libmnl) - disabled\nLIBMNL_LIBS=""\nLIBMNL_CFLAGS=""'),
]

for pattern, replacement in patterns:
    if re.search(pattern, content, re.DOTALL):
        content = re.sub(pattern, replacement, content, flags=re.DOTALL)
        print(f"✅ Patched pattern: {pattern[:50]}...")
        break
else:
    # If no pattern matched, add the variables at the top of configure
    # Find where variables are set and add LIBMNL there
    if 'LIBMNL_LIBS' not in content:
        # Add after LIBNFNETLINK variables
        content = re.sub(
            r'(LIBNFNETLINK_LIBS=.*?\n)',
            r'\1LIBMNL_LIBS=""\nLIBMNL_CFLAGS=""\n',
            content,
            count=1
        )
        print("✅ Added LIBMNL variables")

with open('configure', 'w') as f:
    f.write(content)

print("✅ Configure script patched")
PYTHON_SCRIPT

    # Also use sed as backup
    sed -i 's/^checking for LIBMNL/# LIBMNL disabled - checking skipped/g' configure
    sed -i '/^LIBMNL_LIBS=/d' configure
    sed -i '/^LIBMNL_CFLAGS=/d' configure
    
    # Add the variables early in the script
    sed -i '/^LIBNFNETLINK_LIBS=/a\
LIBMNL_LIBS=""\
LIBMNL_CFLAGS=""' configure
fi

# Configure with explicit environment variables
echo "⚙️  Step 3: Configuring..."
export PKG_CONFIG=/bin/false
export LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink"
export LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink"
export LIBMNL_CFLAGS=""
export LIBMNL_LIBS=""

# Run configure without piping to avoid signal 13
./configure --prefix=/usr > /tmp/configure_output.log 2>&1 || {
    echo "❌ Configure failed. Last 50 lines of output:"
    tail -50 /tmp/configure_output.log
    echo ""
    echo "Checking config.log..."
    tail -50 config.log 2>/dev/null || true
    exit 1
}

# Check if Makefile was created
if [ ! -f Makefile ]; then
    echo "❌ Makefile not created. Configure failed."
    cat /tmp/configure_output.log
    exit 1
fi

echo "✅ Configure successful!"

# Build
echo "🔨 Step 4: Building..."
make -j$(nproc) || make

# Install
echo "📦 Step 5: Installing..."
sudo make install
sudo ldconfig

# Verify headers
echo "🔍 Step 6: Verifying headers..."
HEADER_FOUND=0
for dir in /usr/include/libnetfilter_queue /usr/local/include/libnetfilter_queue; do
    if [ -f "$dir/libnetfilter_queue.h" ]; then
        echo "✅ Headers found: $dir"
        HEADER_FOUND=1
        HEADER_DIR="$dir"
        break
    fi
done

if [ $HEADER_FOUND -eq 0 ]; then
    echo "⚠️  Searching for headers..."
    find /usr/include /usr/local/include -name "*netfilter_queue*" -type f 2>/dev/null | head -5
    # Try to find the directory
    HEADER_DIR=$(find /usr/include /usr/local/include -name "libnetfilter_queue.h" -type f 2>/dev/null | head -1 | xargs dirname 2>/dev/null || echo "/usr/include/libnetfilter_queue")
    echo "Using header directory: $HEADER_DIR"
fi

# Install Python package
echo ""
echo "🐍 Step 7: Installing Python netfilterqueue..."
cd ~/Capstone-Project/backend
source venv/bin/activate

# Set compilation flags
export CFLAGS="-I/usr/include/libnfnetlink -I${HEADER_DIR:-/usr/include/libnetfilter_queue}"
export LDFLAGS="-L/usr/lib -lnfnetlink -lnetfilter_queue"

echo "Using CFLAGS: $CFLAGS"
echo "Using LDFLAGS: $LDFLAGS"

pip install --no-cache-dir netfilterqueue || {
    echo "❌ pip install failed. Trying with verbose output..."
    pip install --no-cache-dir -v netfilterqueue 2>&1 | tail -50
    exit 1
}

# Verify
echo ""
if python3 -c "import netfilterqueue; print('✅ SUCCESS!')" 2>/dev/null; then
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  ✅ Installation Complete! Network Firewall Ready!        ║"
    echo "║                                                          ║"
    echo "║  Start with: sudo python3 network_firewall.py            ║"
    echo "╚══════════════════════════════════════════════════════════╝"
else
    echo "❌ Python import failed."
    python3 -c "import netfilterqueue" 2>&1
    exit 1
fi

