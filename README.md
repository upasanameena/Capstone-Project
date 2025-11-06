# Dual-Layer ML-Driven Firewall System - Capstone Project

## Project Overview

This project implements an intelligent **dual-layer firewall system** combining:
- **Network Layer Firewall** - Packet-level filtering using ML + rule-based detection
- **Application Layer WAF** - HTTP request analysis using ML model

## Architecture

```
Client Traffic
    ↓
[Network Firewall] ← Packet-level filtering (netfilterqueue + iptables)
    ↓ (Allowed packets)
[Application WAF] ← HTTP-level analysis (ML + security patterns)
    ↓
[CSV Logging] ← All decisions logged
    ↓
[API Server] ← Reads CSVs, serves JSON
    ↓
[UI Dashboard] ← Real-time visualization
```

## Project Structure

```
Capstone-Project/
├── backend/                    # WAF + Network Firewall (Python)
│   ├── Proxy_server.py        # Application layer WAF
│   ├── network_firewall.py    # Network layer firewall
│   ├── requirements.txt       # Python dependencies
│   └── ...
├── frontend/                   # UI + API (Node.js + React)
│   ├── server.mjs             # Read-only CSV API
│   ├── src/                   # React components
│   └── ...
└── README.md                   # This file
```

## Quick Start

### Prerequisites
- Kali Linux (or any Linux with root access)
- Python 3.6+
- Node.js 18+
- Root/sudo access (for network firewall)

### Setup

#### Backend Setup:
```bash
cd backend
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# Load kernel modules
sudo modprobe nfnetlink_queue
```

#### Frontend Setup:
```bash
cd frontend
npm install
```

### Running

**Terminal 1 - Network Firewall (requires root):**
```bash
cd backend
source venv/bin/activate
sudo python3 network_firewall.py
```

**Terminal 2 - Application WAF:**
```bash
cd backend
source venv/bin/activate
python3 Proxy_server.py
```

**Terminal 3 - API Server:**
```bash
cd frontend
export BACKEND_ROOT=/path/to/backend
npm run api
```

**Terminal 4 - UI Server:**
```bash
cd frontend
npm run dev
```

**Open Dashboard:** `http://localhost:8080`

## Features

- ✅ Dual-layer architecture (Network + Application)
- ✅ ML-based detection (Logistic Regression)
- ✅ Multiple vulnerability detection (SQLi, XSS, RCE, LFI/RFI, SSRF, IDOR)
- ✅ Automated incremental retraining
- ✅ Real-time visualization dashboard
- ✅ Complete CSV logging system
- ✅ GET and POST request analysis
- ✅ Network packet filtering

## Documentation

- `backend/DUAL_FIREWALL_SETUP.md` - Complete setup guide
- `backend/COMPLETE_SETUP.md` - Quick start instructions
- `backend/VERIFICATION_COMMANDS.md` - Testing commands

## Technologies

- **Backend**: Python, scikit-learn, numpy, netfilterqueue, scapy
- **Frontend**: React, TypeScript, Vite, Recharts
- **API**: Node.js, Express
- **ML**: Logistic Regression (scikit-learn)

## License

Academic/Research Project

