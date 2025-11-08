#!/bin/bash
# Script to test the Network Layer Firewall
# This generates network traffic that will be monitored and logged by the network firewall

echo "=========================================="
echo "  Network Layer Firewall Test Script"
echo "=========================================="
echo ""
echo "This script generates network traffic to test the network firewall."
echo "The network firewall monitors packets at a lower level than HTTP requests."
echo ""

# Check if network firewall is running
if ! pgrep -f "network_sniffer_fallback.py" > /dev/null && ! pgrep -f "network_firewall.py" > /dev/null; then
    echo "⚠️  WARNING: Network firewall doesn't appear to be running!"
    echo "   Start it with:"
    echo "   cd ~/Capstone-Project/backend"
    echo "   source venv/bin/activate"
    echo "   sudo -E python3 network_sniffer_fallback.py"
    echo ""
    read -p "Continue anyway? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "✓ Network firewall check passed"
echo ""

# Function to test normal traffic (should be ALLOWED)
test_normal_traffic() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "1. Testing NORMAL Traffic (Should be ALLOWED)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    echo "  → Sending ping to 8.8.8.8 (Google DNS)..."
    ping -c 3 8.8.8.8 > /dev/null 2>&1
    
    echo "  → Sending ping to 1.1.1.1 (Cloudflare DNS)..."
    ping -c 3 1.1.1.1 > /dev/null 2>&1
    
    echo "  → Making HTTP request to example.com..."
    curl -s http://example.com > /dev/null
    
    echo "  → Making HTTPS request to google.com..."
    curl -s https://www.google.com > /dev/null 2>&1
    
    echo "  → Connecting to port 80 (HTTP)..."
    timeout 2 bash -c 'echo > /dev/tcp/example.com/80' 2>/dev/null || true
    
    echo "  → Connecting to port 443 (HTTPS)..."
    timeout 2 bash -c 'echo > /dev/tcp/www.google.com/443' 2>/dev/null || true
    
    echo ""
    echo "  ✓ Normal traffic sent (should appear in network_allowed.csv)"
    echo ""
}

# Function to test suspicious ports (should be BLOCKED)
test_suspicious_ports() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "2. Testing SUSPICIOUS PORTS (Should be BLOCKED)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "  The firewall blocks connections to these suspicious ports:"
    echo "  - Port 23 (Telnet)"
    echo "  - Port 3389 (RDP)"
    echo "  - Port 445 (SMB)"
    echo "  - Port 1433 (MSSQL)"
    echo "  - Port 3306 (MySQL)"
    echo "  - Port 5432 (PostgreSQL)"
    echo ""
    
    # Test suspicious ports (these will likely fail to connect, but the attempt will be logged)
    echo "  → Attempting connection to port 23 (Telnet) on localhost..."
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23' 2>/dev/null || echo "    (Connection failed - expected, but packet was logged)"
    
    echo "  → Attempting connection to port 3389 (RDP) on localhost..."
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3389' 2>/dev/null || echo "    (Connection failed - expected, but packet was logged)"
    
    echo "  → Attempting connection to port 445 (SMB) on localhost..."
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/445' 2>/dev/null || echo "    (Connection failed - expected, but packet was logged)"
    
    echo "  → Attempting connection to port 1433 (MSSQL) on localhost..."
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/1433' 2>/dev/null || echo "    (Connection failed - expected, but packet was logged)"
    
    echo "  → Attempting connection to port 3306 (MySQL) on localhost..."
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3306' 2>/dev/null || echo "    (Connection failed - expected, but packet was logged)"
    
    echo "  → Attempting connection to port 5432 (PostgreSQL) on localhost..."
    timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/5432' 2>/dev/null || echo "    (Connection failed - expected, but packet was logged)"
    
    echo ""
    echo "  ✓ Suspicious port attempts sent (should appear in network_blocked.csv)"
    echo ""
}

# Function to test port scanning (should generate many packets)
test_port_scanning() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "3. Testing PORT SCANNING (Generates many packets)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if command -v nmap &> /dev/null; then
        echo "  → Scanning localhost ports 1-100 (this will generate many packets)..."
        nmap -p 1-100 127.0.0.1 > /dev/null 2>&1
        echo "  ✓ Port scan completed"
    else
        echo "  → nmap not installed, using manual port connections..."
        for port in 22 25 53 80 443 8080; do
            timeout 0.5 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
        done
        echo "  ✓ Manual port connections completed"
    fi
    
    echo ""
}

# Function to test with netcat (if available)
test_netcat() {
    if command -v nc &> /dev/null || command -v netcat &> /dev/null; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "4. Testing with NETCAT (Generates TCP/UDP packets)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        
        echo "  → Testing TCP connection to port 80..."
        echo "GET / HTTP/1.0" | timeout 2 nc example.com 80 > /dev/null 2>&1 || true
        
        echo "  → Testing UDP connection..."
        echo "test" | timeout 2 nc -u 8.8.8.8 53 > /dev/null 2>&1 || true
        
        echo "  ✓ Netcat tests completed"
        echo ""
    fi
}

# Main execution
echo "Starting network firewall tests..."
echo ""

# Run all tests
test_normal_traffic
sleep 2

test_suspicious_ports
sleep 2

test_port_scanning
sleep 2

test_netcat

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Test Complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Check the results:"
echo ""
echo "  # View allowed packets"
echo "  tail -10 ~/Capstone-Project/backend/network_allowed.csv"
echo ""
echo "  # View blocked packets"
echo "  tail -10 ~/Capstone-Project/backend/network_blocked.csv"
echo ""
echo "  # Count packets"
echo "  wc -l ~/Capstone-Project/backend/network_allowed.csv"
echo "  wc -l ~/Capstone-Project/backend/network_blocked.csv"
echo ""
echo "  # Check dashboard - it should update automatically within 5 seconds"
echo "  # Open: http://localhost:8080"
echo ""
echo "Note: The network firewall must be running with sudo to capture packets."
echo "      If you see no data, make sure network_sniffer_fallback.py is running."
echo ""

