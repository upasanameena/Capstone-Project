# Kali Linux Setup Guide

## Problem: Kali Repository Issues

If you're getting `403 Forbidden` or repository signing errors, use one of these solutions:

---

## Solution 1: Fix Kali Repositories (Recommended)

**Update Kali's repository sources:**

```bash
# Backup current sources
sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup

# Edit sources list
sudo nano /etc/apt/sources.list
```

**Add these lines (remove old ones if they exist):**
```
deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware
```

**Or use the official mirror:**
```
deb http://kali.download/kali kali-rolling main contrib non-free non-free-firmware
```

**Save and update:**
```bash
# Update package lists
sudo apt update

# Fix any GPG key issues
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6

# Try update again
sudo apt update
```

---

## Solution 2: Install Node.js via NVM (No Root Required)

**This method doesn't require fixing repositories:**

```bash
# Install NVM (Node Version Manager)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Reload shell configuration
source ~/.bashrc

# Install Node.js 20 (LTS)
nvm install 20

# Use Node.js 20
nvm use 20

# Verify installation
node -v
npm -v
```

**Note:** Add this to `~/.bashrc` to make it permanent:
```bash
echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
```

---

## Solution 3: Install Node.js from NodeSource (After Fixing Repos)

**Only use this if Solution 1 worked:**

```bash
# Update system first
sudo apt update
sudo apt upgrade -y

# Install Node.js 20 from NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify
node -v
npm -v
```

---

## Solution 4: Use Snap (Alternative)

```bash
# Install snapd if not installed
sudo apt update
sudo apt install -y snapd

# Install Node.js via snap
sudo snap install node --classic

# Verify
node -v
npm -v
```

---

## Solution 5: Download Pre-built Binary (Fastest)

```bash
# Download Node.js 20 LTS binary for Linux x64
cd ~
wget https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.xz

# Extract
tar -xf node-v20.11.0-linux-x64.tar.xz

# Move to /opt (optional, or use in home directory)
sudo mv node-v20.11.0-linux-x64 /opt/nodejs

# Add to PATH (add to ~/.bashrc)
echo 'export PATH=/opt/nodejs/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# Verify
node -v
npm -v
```

---

## After Installing Node.js

**Once Node.js is installed, proceed with the project setup:**

```bash
# Clone your repository (if not already done)
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd sentinel-blaze-main

# Install project dependencies
npm install

# Set backend path (if kali-vm-project-main is not a sibling folder)
export BACKEND_ROOT=/path/to/kali-vm-project-main

# Start API server (Terminal 1)
npm run api

# Start UI server (Terminal 2)
npm run dev

# Open browser: http://localhost:8080
```

---

## Quick Fix for Repository Issues

**If you just want to quickly fix the repo and continue:**

```bash
# Fix GPG keys
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys ED444FF07D8D0BF6

# Update sources to use official mirror
echo "deb http://http.kali.org/kali kali-rolling main contrib non-free non-free-firmware" | sudo tee /etc/apt/sources.list

# Update
sudo apt update
```

**If still having issues, use Solution 2 (NVM) - it's the most reliable and doesn't require root or fixing repos.**

---

## Recommended: Use NVM (Solution 2)

**Why NVM is better:**
- ✅ No root/sudo required
- ✅ Works even with broken repos
- ✅ Easy to switch Node.js versions
- ✅ No system-wide changes
- ✅ Clean and isolated

**Just run:**
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
node -v  # Should show v20.x.x
```

---

## Troubleshooting

### "command not found: node" after installation
- Make sure you've run `source ~/.bashrc` or opened a new terminal
- For NVM: Run `nvm use 20` in each new terminal, or add to `~/.bashrc`

### Permission denied errors
- Use NVM (Solution 2) - doesn't require sudo
- Or use Solution 5 (binary) in your home directory

### Still having repo issues
- Use NVM (Solution 2) - completely bypasses apt/repos
- Or download binary directly (Solution 5)

