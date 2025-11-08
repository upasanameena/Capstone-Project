# Network Layer Firewall Testing Guide

## Understanding the Network Layer Firewall

The **Network Layer Firewall** operates at a **lower level** than the Application Layer WAF:

- **Application Layer (WAF)**: Analyzes HTTP/HTTPS requests (URLs, POST data)
- **Network Layer Firewall**: Analyzes **raw network packets** (IP, TCP, UDP)

### What the Network Firewall Monitors

1. **Suspicious Ports** - Blocks connections to:
   - Port 23 (Telnet)
   - Port 3389 (RDP - Remote Desktop)
   - Port 445 (SMB - File Sharing)
   - Port 1433 (MSSQL)
   - Port 1521 (Oracle)
   - Port 3306 (MySQL)
   - Port 5432 (PostgreSQL)
   - Port 5900 (VNC)

2. **Malicious Payload Patterns** - Detects in packet payloads:
   - SQL injection patterns (`union select`, `or 1=1`)
   - XSS patterns (`<script>`, `javascript:`)
   - Command injection (`wget`, `curl`, `/bin/sh`)

## How to Test the Network Firewall

### Prerequisites

1. **Network firewall must be running:**
   ```bash
   cd ~/Capstone-Project/backend
   source venv/bin/activate
   sudo -E python3 network_sniffer_fallback.py
   ```
   
   **Note:** It requires `sudo` because it needs to capture network packets.

2. **Check if it's running:**
   ```bash
   ps aux | grep network_sniffer
   ```

### Method 1: Automated Testing Script

```bash
cd ~/Capstone-Project/backend
chmod +x test_network_firewall.sh
./test_network_firewall.sh
```

This script will:
- Generate normal traffic (ping, HTTP) → **ALLOWED**
- Attempt connections to suspicious ports → **BLOCKED**
- Perform port scanning → Generates many packets
- Use netcat for TCP/UDP testing

### Method 2: Manual Testing

#### Test 1: Normal Traffic (Should be ALLOWED)

```bash
# Ping test
ping -c 5 8.8.8.8

# HTTP request
curl http://example.com

# HTTPS request
curl https://www.google.com

# Normal port connections
timeout 2 bash -c 'echo > /dev/tcp/example.com/80'
timeout 2 bash -c 'echo > /dev/tcp/www.google.com/443'
```

**Expected Result:** These should appear in `network_allowed.csv`

#### Test 2: Suspicious Ports (Should be BLOCKED)

```bash
# Attempt connection to Telnet port
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23'

# Attempt connection to RDP port
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3389'

# Attempt connection to SMB port
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/445'

# Attempt connection to MySQL port
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3306'
```

**Expected Result:** These should appear in `network_blocked.csv` with reason `suspicious_port:XXXX`

#### Test 3: Port Scanning (Generates Many Packets)

```bash
# If nmap is installed
nmap -p 1-200 127.0.0.1

# Or manually test multiple ports
for port in 22 23 25 80 443 3389 3306; do
    timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
done
```

**Expected Result:** Many packets logged, some ALLOWED, some BLOCKED

#### Test 4: Using Netcat (TCP/UDP)

```bash
# TCP connection
echo "GET / HTTP/1.0" | nc example.com 80

# UDP connection
echo "test" | nc -u 8.8.8.8 53
```

#### Test 5: Generate Continuous Traffic

```bash
# Continuous ping (run for 30 seconds)
ping -i 1 8.8.8.8 &
sleep 30
killall ping

# Multiple simultaneous connections
for i in {1..10}; do
    curl -s http://example.com > /dev/null &
done
wait
```

### Method 3: Using Network Tools

#### Using hping3 (if installed)
```bash
# Generate TCP packets
hping3 -S -p 80 example.com -c 10

# Generate UDP packets
hping3 --udp -p 53 8.8.8.8 -c 10
```

#### Using tcpdump (to verify packets are being captured)
```bash
# In another terminal, monitor network traffic
sudo tcpdump -i any -n
```

## Verifying Results

### Check CSV Files

```bash
cd ~/Capstone-Project/backend

# View allowed packets
tail -20 network_allowed.csv

# View blocked packets
tail -20 network_blocked.csv

# Count total packets
echo "Allowed: $(wc -l < network_allowed.csv)"
echo "Blocked: $(wc -l < network_blocked.csv)"
```

### Check Dashboard

1. Open dashboard: `http://localhost:8080`
2. Look at "Network Layer Firewall" section
3. Should show:
   - **Allowed Packets**: Count of normal traffic
   - **Blocked Packets**: Count of suspicious traffic
   - **Total Packets**: Sum of both

### Check Network Firewall Logs

```bash
tail -f ~/Capstone-Project/backend/network.log
```

## Understanding the Data

### CSV File Format

Both `network_allowed.csv` and `network_blocked.csv` have this format:

```csv
timestamp,src_ip,dst_ip,protocol,src_port,dst_port,length,decision,reason
2024-01-01T12:00:00,192.168.1.100,8.8.8.8,TCP,54321,80,64,ALLOW,baseline
2024-01-01T12:00:01,192.168.1.100,127.0.0.1,TCP,54322,23,64,BLOCK,suspicious_port:23
```

### Decision Logic

- **ALLOW**: Normal traffic, safe ports, no malicious patterns
- **BLOCK**: 
  - Destination port in suspicious ports list
  - Payload contains SQL injection, XSS, or command injection patterns

## Troubleshooting

### Issue: No packets being logged

**Solution:**
1. Make sure network firewall is running with `sudo`:
   ```bash
   sudo -E python3 network_sniffer_fallback.py
   ```

2. Check if you have permission to capture packets:
   ```bash
   sudo tcpdump -i any -c 1
   ```

3. Verify the interface being monitored:
   ```bash
   # Check available interfaces
   ip link show
   
   # Set specific interface (optional)
   export IFACE=eth0
   sudo -E python3 network_sniffer_fallback.py
   ```

### Issue: All packets are ALLOWED

**Solution:**
- Try connecting to suspicious ports (23, 3389, 445, etc.)
- The firewall only blocks specific ports, not all traffic

### Issue: Dashboard shows 0 packets

**Solution:**
1. Check if CSV files are being written:
   ```bash
   ls -lh network_allowed.csv network_blocked.csv
   ```

2. Check if BACKEND_ROOT is set correctly:
   ```bash
   echo $BACKEND_ROOT
   ```

3. Verify API can read the files:
   ```bash
   curl http://localhost:5174/api/stats/network-firewall
   ```

## Quick Test Commands

```bash
# Quick test - generate 10 packets
for i in {1..10}; do
    ping -c 1 8.8.8.8 > /dev/null
    timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/23" 2>/dev/null || true
done

# Check results
tail -5 network_allowed.csv
tail -5 network_blocked.csv
```

## Summary

- **Normal traffic** (ping, HTTP, HTTPS) → `network_allowed.csv`
- **Suspicious ports** (23, 3389, 445, 3306, etc.) → `network_blocked.csv`
- **Malicious payloads** in packets → `network_blocked.csv`
- **Dashboard updates** automatically every 5 seconds

The network firewall captures **all network traffic** on your system, not just HTTP requests!

