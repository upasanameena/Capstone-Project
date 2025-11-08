# Quick Start for Presenter Demo
## Copy-Paste Commands

---

## Setup (Run Once)

```bash
cd ~/Capstone-Project
git pull origin main
export BACKEND_ROOT=$HOME/Capstone-Project/backend
echo 'export BACKEND_ROOT=$HOME/Capstone-Project/backend' >> ~/.bashrc
```

---

## Start Everything

```bash
cd ~/Capstone-Project/backend
chmod +x start_all.sh generate_test_data.sh test_network_firewall.sh
./start_all.sh
```

Wait 10 seconds, then verify:
```bash
curl http://localhost:5174/api/stats/get-requests
curl http://localhost:8080
```

---

## Generate Demo Data

```bash
cd ~/Capstone-Project/backend
./generate_test_data.sh
./test_network_firewall.sh
```

Wait 5 seconds, then open dashboard:
```bash
xdg-open http://localhost:8080
```

---

## Live Demo Commands

**While showing dashboard, run these:**

```bash
# Good request (watch dashboard update)
curl 'http://127.0.0.1:8081/?q=demo'

# Malicious request (watch dashboard update)
curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'

# Network traffic (watch dashboard update)
ping -c 10 8.8.8.8
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23' 2>/dev/null || true
```

---

## Stop Everything

```bash
pkill -f 'Proxy_server.py'
pkill -f 'network_sniffer'
pkill -f 'server.mjs'
pkill -f 'vite'
```

---

## Check Status

```bash
ps aux | grep -E "Proxy_server|network_sniffer|server.mjs|vite"
```

