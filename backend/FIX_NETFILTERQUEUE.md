# Fix: netfilterqueue Installation Error

## Problem
Missing libnfnetlink development headers causing compilation error.

## Solution

Run these commands on Kali Linux:

```bash
# Update package list
sudo apt update

# Install required development libraries
sudo apt install -y \
    libnetfilter-queue-dev \
    libnfnetlink-dev \
    python3-dev \
    build-essential \
    gcc \
    g++ \
    make

# Now try installing netfilterqueue again
cd ~/Capstone-Project/backend
source venv/bin/activate
pip install netfilterqueue scapy
```

## Alternative: Use Pre-built Package

If compilation still fails, try:

```bash
# Install via apt (if available)
sudo apt install -y python3-netfilterqueue

# Or try pip with alternative method
pip install --no-cache-dir netfilterqueue
```

## Verify Installation

```bash
python3 -c "import netfilterqueue; print('✅ netfilterqueue installed successfully')"
```

