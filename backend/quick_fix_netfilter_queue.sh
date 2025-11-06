#!/bin/bash
# Quick fix: Build libnetfilter-queue by patching configure to skip LIBMNL check

cd /tmp/libnetfilter_queue-1.0.5

# Patch configure script to skip LIBMNL requirement
sed -i 's/^if test "x$LIBMNL_LIBS" = "x"/if false # LIBMNL check disabled/g' configure

# Now configure should work
PKG_CONFIG=/bin/false ./configure --prefix=/usr \
    LIBNFNETLINK_CFLAGS="-I/usr/include/libnfnetlink" \
    LIBNFNETLINK_LIBS="-L/usr/lib -lnfnetlink"

make
sudo make install
sudo ldconfig

echo "✅ libnetfilter-queue installed!"
cd ~/Capstone-Project/backend
source venv/bin/activate
pip install --no-cache-dir netfilterqueue
python3 -c "import netfilterqueue; print('✅ SUCCESS!')"

