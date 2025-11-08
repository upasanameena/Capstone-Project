#!/usr/bin/env python3
"""
Diagnostic script to check why dashboard is not showing data.
This script checks:
1. CSV files existence and content
2. API connectivity
3. Data counts
"""

import os
import sys
import csv
import requests
from pathlib import Path

def check_csv_file(filepath, name):
    """Check if CSV file exists and count rows"""
    print(f"\n{'='*60}")
    print(f"Checking {name}: {filepath}")
    print('='*60)
    
    if not os.path.exists(filepath):
        print(f"❌ File does NOT exist!")
        return 0
    
    file_size = os.path.getsize(filepath)
    print(f"✓ File exists ({file_size} bytes)")
    
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            reader = csv.reader(f)
            rows = list(reader)
            total_rows = len(rows)
            
            if total_rows == 0:
                print(f"⚠️  File is EMPTY (no rows)")
                return 0
            
            # Check if first row is header
            has_header = False
            if total_rows > 0:
                first_row = rows[0]
                if 'method' in str(first_row).lower() or 'path' in str(first_row).lower() or 'timestamp' in str(first_row).lower():
                    has_header = True
                    print(f"✓ Header row detected: {first_row}")
            
            data_rows = total_rows - 1 if has_header else total_rows
            print(f"✓ Total rows: {total_rows}")
            print(f"✓ Data rows: {data_rows}")
            
            if data_rows > 0:
                print(f"✓ Sample data rows:")
                for i, row in enumerate(rows[1:6] if has_header else rows[:5], 1):
                    print(f"  Row {i}: {row}")
                if data_rows > 5:
                    print(f"  ... and {data_rows - 5} more rows")
            else:
                print(f"⚠️  No data rows (only header)")
            
            return data_rows
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return 0

def check_api_endpoint(url, name):
    """Check if API endpoint is accessible and returns data"""
    print(f"\n{'='*60}")
    print(f"Checking API: {name}")
    print(f"URL: {url}")
    print('='*60)
    
    try:
        response = requests.get(url, timeout=5)
        if response.status_code == 200:
            data = response.json()
            print(f"✓ API responded successfully")
            print(f"✓ Response: {data}")
            return True, data
        else:
            print(f"❌ API returned status code: {response.status_code}")
            print(f"   Response: {response.text}")
            return False, None
    except requests.exceptions.ConnectionError:
        print(f"❌ Cannot connect to API (is it running on port 5174?)")
        return False, None
    except Exception as e:
        print(f"❌ Error: {e}")
        return False, None

def main():
    print("\n" + "="*60)
    print("  DASHBOARD DATA DIAGNOSTIC TOOL")
    print("="*60)
    
    # Get backend directory
    backend_dir = os.path.dirname(os.path.abspath(__file__))
    data_collection_dir = os.path.join(backend_dir, 'Data_Collection')
    
    print(f"\nBackend directory: {backend_dir}")
    print(f"Data Collection directory: {data_collection_dir}")
    
    # Check CSV files
    csv_files = {
        'Good_req.csv': os.path.join(data_collection_dir, 'Good_req.csv'),
        'Bad_req.csv': os.path.join(data_collection_dir, 'Bad_req.csv'),
        'benign_payloads.csv': os.path.join(backend_dir, 'benign_payloads.csv'),
        'malicious_payloads.csv': os.path.join(backend_dir, 'malicious_payloads.csv'),
        'network_allowed.csv': os.path.join(backend_dir, 'network_allowed.csv'),
        'network_blocked.csv': os.path.join(backend_dir, 'network_blocked.csv'),
    }
    
    results = {}
    for name, filepath in csv_files.items():
        results[name] = check_csv_file(filepath, name)
    
    # Check API endpoints
    api_base = "http://localhost:5174"
    api_endpoints = {
        'GET Requests': f"{api_base}/api/stats/get-requests",
        'POST Payloads': f"{api_base}/api/stats/post-payloads",
        'Network Firewall': f"{api_base}/api/stats/network-firewall",
        'Training Metrics': f"{api_base}/api/metrics/training",
    }
    
    api_results = {}
    for name, url in api_endpoints.items():
        success, data = check_api_endpoint(url, name)
        api_results[name] = (success, data)
    
    # Summary
    print("\n" + "="*60)
    print("  SUMMARY")
    print("="*60)
    
    print("\n📊 CSV File Status:")
    total_data_rows = 0
    for name, count in results.items():
        status = "✓" if count > 0 else "⚠️"
        print(f"  {status} {name}: {count} data rows")
        total_data_rows += count
    
    print(f"\n  Total data rows across all files: {total_data_rows}")
    
    print("\n🌐 API Status:")
    for name, (success, data) in api_results.items():
        status = "✓" if success else "❌"
        print(f"  {status} {name}: {'OK' if success else 'FAILED'}")
        if success and data:
            print(f"     Data: {data}")
    
    # Recommendations
    print("\n" + "="*60)
    print("  RECOMMENDATIONS")
    print("="*60)
    
    if total_data_rows == 0:
        print("\n⚠️  ISSUE: No data in CSV files!")
        print("\nTo fix this:")
        print("1. Make sure WAF (Proxy_server.py) is running on port 8081")
        print("2. Send test requests to populate the CSV files:")
        print("   curl 'http://127.0.0.1:8081/?q=hello'")
        print("   curl 'http://127.0.0.1:8081/?q=1%27%20OR%201%3D1--'")
        print("3. Check WAF logs: tail -f waf.log")
    
    if not all(success for success, _ in api_results.values()):
        print("\n⚠️  ISSUE: API is not accessible!")
        print("\nTo fix this:")
        print("1. Make sure API server is running:")
        print("   cd frontend")
        print("   export BACKEND_ROOT=$HOME/Capstone-Project/backend")
        print("   npm run api")
        print("2. Check API logs: tail -f frontend/api.log")
    
    if total_data_rows > 0 and all(success for success, _ in api_results.values()):
        print("\n✅ Everything looks good! Dashboard should be showing data.")
        print("   If dashboard still shows zeros, check browser console (F12)")
        print("   and verify BACKEND_ROOT environment variable is set correctly.")
    
    print("\n")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\nInterrupted by user")
        sys.exit(1)

