# Manual Build: netfilterqueue from Source (Kali Repo Blocked)

## Problem
Kali repositories are blocked (403 Forbidden). We'll build everything from source.

## Complete Manual Installation

### Step 1: Install Build Tools (if not installed)

```bash
# Install basic build tools
sudo apt install -y build-essential gcc g++ make cmake pkg-config python3-dev 2>/dev/null || echo "Some packages may fail"
```

### Step 2: Build libnfnetlink from Source

```bash
cd /tmp

# Download libnfnetlink source
wget https://www.netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.2.tar.bz2

# Extract and build
tar -xjf libnfnetlink-1.0.2.tar.bz2
cd libnfnetlink-1.0.2

# Configure and build
./configure --prefix=/usr
make
sudo make install
```

### Step 3: Build libnetfilter-queue from Source

```bash
cd /tmp

# Download libnetfilter-queue source
wget https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2

# Extract and build
tar -xjf libnetfilter_queue-1.0.5.tar.bz2
cd libnetfilter_queue-1.0.5

# Configure and build
./configure --prefix=/usr
make
sudo make install
```

### Step 4: Update Library Path

```bash
# Update dynamic linker
sudo ldconfig

# Verify libraries are found
ldconfig -p | grep nfnetlink
ldconfig -p | grep netfilter_queue
```

### Step 5: Install netfilterqueue Python Package

```bash
# Go to your project
cd ~/Capstone-Project/backend
source venv/bin/activate

# Install netfilterqueue
pip install --upgrade pip
pip install --no-cache-dir netfilterqueue

# Verify
python3 -c "import netfilterqueue; print('✅ SUCCESS!')"
```

---

## Quick All-in-One Script

Save this as `build_from_source.sh`:

```bash
#!/bin/bash
set -e

echo "Building netfilterqueue from source..."

cd /tmp

# Build libnfnetlink
echo "Building libnfnetlink..."
wget -q https://www.netfilter.org/projects/libnfnetlink/files/libnfnetlink-1.0.2.tar.bz2
tar -xjf libnfnetlink-1.0.2.tar.bz2
cd libnfnetlink-1.0.2
./configure --prefix=/usr
make
sudo make install
cd /tmp

# Build libnetfilter-queue
echo "Building libnetfilter-queue..."
wget -q https://www.netfilter.org/projects/libnetfilter_queue/files/libnetfilter_queue-1.0.5.tar.bz2
tar -xjf libnetfilter_queue-1.0.5.tar.bz2
cd libnetfilter_queue-1.0.5
./configure --prefix=/usr
make
sudo make install

# Update libraries
sudo ldconfig

# Install Python package
cd ~/Capstone-Project/backend
source venv/bin/activate
pip install --no-cache-dir netfilterqueue

echo "✅ Installation complete!"
```

Run: `chmod +x build_from_source.sh && ./build_from_source.sh`

