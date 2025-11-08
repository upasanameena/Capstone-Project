#!/bin/bash
# Script to generate test data for the dashboard
# This sends various requests to the WAF to populate CSV files

WAF_URL="http://127.0.0.1:8081"

echo "=========================================="
echo "  Generating Test Data for Dashboard"
echo "=========================================="
echo ""
echo "WAF URL: $WAF_URL"
echo ""

# Check if WAF is running
if ! curl -s "$WAF_URL/test" > /dev/null 2>&1; then
    echo "❌ ERROR: WAF is not running on $WAF_URL"
    echo "   Please start the WAF first:"
    echo "   cd ~/Capstone-Project/backend"
    echo "   source venv/bin/activate"
    echo "   python Proxy_server.py"
    exit 1
fi

echo "✓ WAF is running"
echo ""

# Good GET requests
echo "Sending GOOD GET requests..."
curl -s "$WAF_URL/?q=hello" > /dev/null
curl -s "$WAF_URL/?q=test" > /dev/null
curl -s "$WAF_URL/?q=search" > /dev/null
curl -s "$WAF_URL/?q=products" > /dev/null
curl -s "$WAF_URL/?q=about" > /dev/null
curl -s "$WAF_URL/?q=contact" > /dev/null
curl -s "$WAF_URL/?q=home" > /dev/null
curl -s "$WAF_URL/?q=user" > /dev/null
curl -s "$WAF_URL/?q=page" > /dev/null
curl -s "$WAF_URL/?q=info" > /dev/null
echo "  ✓ Sent 10 good GET requests"

# Malicious GET requests
echo "Sending MALICIOUS GET requests..."
curl -s "$WAF_URL/?q=1%27%20OR%201%3D1--" > /dev/null
curl -s "$WAF_URL/?q=admin%27--" > /dev/null
curl -s "$WAF_URL/?q=%27%20UNION%20SELECT%20NULL--" > /dev/null
curl -s "$WAF_URL/?q=<script>alert(1)</script>" > /dev/null
curl -s "$WAF_URL/?q=javascript:alert(1)" > /dev/null
curl -s "$WAF_URL/?q=1%27%20OR%20%271%27%3D%271" > /dev/null
curl -s "$WAF_URL/?q=%27%20DROP%20TABLE%20users--" > /dev/null
curl -s "$WAF_URL/?q=admin%27%20OR%20%271%27%3D%271" > /dev/null
curl -s "$WAF_URL/?q=%3Cscript%3Eeval(String.fromCharCode(97,108,101,114,116,40,49,41))%3C/script%3E" > /dev/null
curl -s "$WAF_URL/?q=1%27%20UNION%20SELECT%20password%20FROM%20users--" > /dev/null
echo "  ✓ Sent 10 malicious GET requests"

# Good POST requests
echo "Sending GOOD POST requests..."
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"name":"test"}' > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"username":"user123","email":"user@example.com"}' > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"action":"search","query":"products"}' > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"message":"hello world"}' > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"data":"normal data"}' > /dev/null
echo "  ✓ Sent 5 good POST requests"

# Malicious POST requests
echo "Sending MALICIOUS POST requests..."
curl -s -X POST "$WAF_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin' OR '1'='1&password=x" > /dev/null
curl -s -X POST "$WAF_URL/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=admin'--&password=test" > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"query":"1'\'' OR 1=1--"}' > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"cmd":"<script>alert(1)</script>"}' > /dev/null
curl -s -X POST "$WAF_URL/api" \
  -H "Content-Type: application/json" \
  -d '{"data":"'\'' UNION SELECT * FROM users--"}' > /dev/null
echo "  ✓ Sent 5 malicious POST requests"

echo ""
echo "=========================================="
echo "  Test Data Generation Complete!"
echo "=========================================="
echo ""
echo "Check CSV files:"
echo "  wc -l Data_Collection/Good_req.csv"
echo "  wc -l Data_Collection/Bad_req.csv"
echo "  wc -l benign_payloads.csv"
echo "  wc -l malicious_payloads.csv"
echo ""
echo "The dashboard should now show data after refreshing!"
echo ""

