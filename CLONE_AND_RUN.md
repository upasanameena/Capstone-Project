# Clone and Run - Complete Instructions

## ✅ Project Successfully Pushed to GitHub

**Repository:** https://github.com/upasanameena/Capstone-Project.git

**Structure:**
```
Capstone-Project/
├── backend/          # WAF + Network Firewall (Python)
├── frontend/         # UI + API (Node.js + React)
└── README.md         # Project overview
```

---

## 📥 Clone on Kali Linux

```bash
# Clone the complete project
cd ~
git clone https://github.com/upasanameena/Capstone-Project.git
cd Capstone-Project
```

---

## 🚀 Setup and Run

### Step 1: Backend Setup

```bash
cd ~/Capstone-Project/backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# If netfilterqueue fails:
sudo apt install -y libnetfilter-queue-dev python3-dev
pip install netfilterqueue
```

### Step 2: Frontend Setup

```bash
cd ~/Capstone-Project/frontend

# Install Node.js if not installed (using NVM)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Install dependencies
npm install
```

### Step 3: Load Kernel Modules

```bash
sudo modprobe nfnetlink_queue
sudo modprobe iptable_nat
sudo modprobe iptable_filter
```

### Step 4: Start All Services (4 Terminals)

**Terminal 1 - Network Firewall (ROOT):**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
sudo python3 network_firewall.py
```

**Terminal 2 - Application WAF:**
```bash
cd ~/Capstone-Project/backend
source venv/bin/activate
python3 Proxy_server.py
```

**Terminal 3 - API Server:**
```bash
cd ~/Capstone-Project/frontend
export BACKEND_ROOT=/home/kali/Capstone-Project/backend
npm run api
```

**Terminal 4 - UI Server:**
```bash
cd ~/Capstone-Project/frontend
npm run dev
```

### Step 5: Open Dashboard

```bash
xdg-open http://localhost:8080
```

---

## ✅ Verification

```bash
# Check services
ps aux | grep network_firewall
ps aux | grep Proxy_server
ps aux | grep "node server.mjs"
ps aux | grep vite

# Test endpoints
curl http://localhost:5174/api/stats/get-requests
curl http://localhost:5174/api/stats/network-firewall
curl http://127.0.0.1:8081/test
```

---

## 📊 What You'll See

**Dashboard at http://localhost:8080:**
1. URL Filter Analysis (GET) - Good vs Bad URLs
2. Payload Classification (POST) - Benign vs Malware
3. Network Layer Firewall - Allowed vs Blocked packets
4. ML Model Training Overview - Training progress

All sections auto-update every 10 seconds!

---

## 🎯 Complete Backup Created!

Your entire dual-layer firewall project is now safely backed up on GitHub:
- ✅ Complete backend code
- ✅ Complete frontend code
- ✅ All documentation
- ✅ Setup scripts
- ✅ Test scripts

**Repository:** https://github.com/upasanameena/Capstone-Project

