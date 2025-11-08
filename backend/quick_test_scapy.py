#!/usr/bin/env python3
# Quick test to verify scapy can capture packets

import sys
import os

print("Testing scapy packet capture...")
print("")

# Test import
try:
    from scapy.all import sniff, IP, TCP, UDP
    print("✓ Scapy imported successfully")
except Exception as e:
    print(f"✗ Failed to import scapy: {e}")
    print("  Install with: pip install scapy")
    sys.exit(1)

# Test packet capture with timeout
print("Attempting to capture 1 packet (10 second timeout)...")
print("  (Generate some traffic: ping 8.8.8.8 or curl http://example.com)")
print("")

try:
    packet_count = 0
    
    def test_handler(pkt):
        global packet_count
        packet_count += 1
        if IP in pkt:
            print(f"  ✓ Captured packet #{packet_count}: {pkt[IP].src} -> {pkt[IP].dst}")
        else:
            print(f"  ✓ Captured packet #{packet_count}: (non-IP)")
        if packet_count >= 1:
            return True  # Stop after 1 packet
    
    # Try to capture 1 packet with 10 second timeout
    sniff(count=1, timeout=10, prn=test_handler, store=False)
    
    if packet_count > 0:
        print("")
        print("✅ SUCCESS: Scapy can capture packets!")
        print("   Network firewall should work.")
    else:
        print("")
        print("⚠️  No packets captured in 10 seconds")
        print("   This might be normal if there's no network traffic.")
        print("   Try generating traffic: ping 8.8.8.8")
        
except PermissionError:
    print("")
    print("❌ Permission denied!")
    print("   Run with sudo: sudo python3 quick_test_scapy.py")
    sys.exit(1)
except Exception as e:
    print("")
    print(f"❌ Error: {e}")
    print("   Check network interface permissions")
    sys.exit(1)

print("")

