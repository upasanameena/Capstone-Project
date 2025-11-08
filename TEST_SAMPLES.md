# Complete Test Samples Reference
## All Attack Types and Test Cases

---

## Application Layer WAF - GET Requests

### ✅ Good URLs (ALLOWED)

```
http://127.0.0.1:8081/?q=hello
http://127.0.0.1:8081/?q=world
http://127.0.0.1:8081/?q=test
http://127.0.0.1:8081/?q=search
http://127.0.0.1:8081/?q=products
http://127.0.0.1:8081/?q=about
http://127.0.0.1:8081/?q=contact
http://127.0.0.1:8081/product?id=1
http://127.0.0.1:8081/user?id=123
http://127.0.0.1:8081/api/users
```

### ❌ SQL Injection (BLOCKED)

```
http://127.0.0.1:8081/?q=1' OR '1'='1
http://127.0.0.1:8081/?q=admin'--
http://127.0.0.1:8081/?q=' OR 1=1--
http://127.0.0.1:8081/?q=1' UNION SELECT NULL--
http://127.0.0.1:8081/?q=' UNION SELECT * FROM users--
http://127.0.0.1:8081/?q=1' OR SLEEP(5)--
http://127.0.0.1:8081/?q=1' AND 1=1--
```

**URL Encoded:**
```bash
curl 'http://127.0.0.1:8081/?q=1%27%20OR%20%271%27%3D%271'
curl 'http://127.0.0.1:8081/?q=admin%27--'
curl 'http://127.0.0.1:8081/?q=%27%20UNION%20SELECT%20*%20FROM%20users--'
```

### ❌ XSS (Cross-Site Scripting) (BLOCKED)

```
http://127.0.0.1:8081/?q=<script>alert(1)</script>
http://127.0.0.1:8081/?q=<img src=x onerror=alert(1)>
http://127.0.0.1:8081/?q=<svg onload=alert(1)>
http://127.0.0.1:8081/?q=javascript:alert(1)
http://127.0.0.1:8081/?q=<body onload=alert(1)>
```

**URL Encoded:**
```bash
curl 'http://127.0.0.1:8081/?q=%3Cscript%3Ealert%281%29%3C/script%3E'
curl 'http://127.0.0.1:8081/?q=%3Cimg%20src%3Dx%20onerror%3Dalert%281%29%3E'
curl 'http://127.0.0.1:8081/?q=javascript%3Aalert%281%29'
```

### ❌ Command Injection (BLOCKED)

```
http://127.0.0.1:8081/?q=; ls -la
http://127.0.0.1:8081/?q=; cat /etc/passwd
http://127.0.0.1:8081/?q=| whoami
http://127.0.0.1:8081/?q=&& id
http://127.0.0.1:8081/?q=`whoami`
http://127.0.0.1:8081/?q=$(whoami)
```

**URL Encoded:**
```bash
curl 'http://127.0.0.1:8081/?q=%3B%20ls%20-la'
curl 'http://127.0.0.1:8081/?q=%7C%20whoami'
curl 'http://127.0.0.1:8081/?q=%26%26%20id'
```

### ❌ Path Traversal (BLOCKED)

```
http://127.0.0.1:8081/?q=../../../etc/passwd
http://127.0.0.1:8081/?q=....//....//etc/passwd
http://127.0.0.1:8081/?q=/etc/passwd
http://127.0.0.1:8081/?q=..\..\..\windows\system32
```

**URL Encoded:**
```bash
curl 'http://127.0.0.1:8081/?q=..%2F..%2F..%2Fetc%2Fpasswd'
curl 'http://127.0.0.1:8081/?q=....//....//etc/passwd'
```

### ❌ SSRF (Server-Side Request Forgery) (BLOCKED)

```
http://127.0.0.1:8081/?q=http://127.0.0.1:22
http://127.0.0.1:8081/?q=http://localhost/admin
http://127.0.0.1:8081/?q=file:///etc/passwd
http://127.0.0.1:8081/?q=gopher://127.0.0.1:6379
```

**URL Encoded:**
```bash
curl 'http://127.0.0.1:8081/?q=http%3A//127.0.0.1%3A22'
curl 'http://127.0.0.1:8081/?q=file%3A//etc/passwd'
```

### ❌ IDOR (Insecure Direct Object Reference) (BLOCKED)

```
http://127.0.0.1:8081/../user/0
http://127.0.0.1:8081/../admin/1
http://127.0.0.1:8081?user_id=0
http://127.0.0.1:8081?id=-1
http://127.0.0.1:8081?user=admin
```

---

## Application Layer WAF - POST Requests

### ✅ Good POST Requests (ALLOWED)

```bash
# Normal JSON
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"name":"test","email":"test@example.com"}'

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"action":"search","query":"products"}'

# Normal form data
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=user123&password=SecurePass123'
```

### ❌ SQL Injection in POST (BLOCKED)

```bash
curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin' OR '1'='1&password=x"

curl -X POST 'http://127.0.0.1:8081/login' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "username=admin'--&password=test"

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"query":"1'\'' OR 1=1--"}'
```

### ❌ XSS in POST (BLOCKED)

```bash
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"message":"<script>alert(1)</script>"}'

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"message":"<img src=x onerror=alert(1)>"}'
```

### ❌ Command Injection in POST (BLOCKED)

```bash
curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"cmd":"; ls -la"}'

curl -X POST 'http://127.0.0.1:8081/api' \
  -H 'Content-Type: application/json' \
  -d '{"cmd":"| cat /etc/passwd"}'
```

---

## Network Layer Firewall

### ✅ Normal Traffic (ALLOWED)

```bash
# DNS queries
ping -c 5 8.8.8.8
ping -c 5 1.1.1.1
ping -c 5 208.67.222.222

# HTTP requests
curl -s http://example.com
curl -s http://httpbin.org/get

# HTTPS requests
curl -s https://www.google.com

# Normal ports
timeout 2 bash -c 'echo > /dev/tcp/example.com/80'
timeout 2 bash -c 'echo > /dev/tcp/www.google.com/443'
timeout 2 bash -c 'echo > /dev/tcp/8.8.8.8/53'
```

### ❌ Suspicious Ports (BLOCKED)

```bash
# Port 23 - Telnet
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/23'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/23'

# Port 3389 - RDP (Remote Desktop)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3389'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/3389'

# Port 445 - SMB (File Sharing)
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/445'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/445'

# Port 1433 - MSSQL
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/1433'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/1433'

# Port 3306 - MySQL
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/3306'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/3306'

# Port 5432 - PostgreSQL
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/5432'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/5432'

# Port 5900 - VNC
timeout 1 bash -c 'echo > /dev/tcp/127.0.0.1/5900'
timeout 1 bash -c 'echo > /dev/tcp/192.168.1.1/5900'
```

### Port Scanning (Generates Many Packets)

```bash
# Using nmap
nmap -p 1-100 127.0.0.1

# Manual scan
for port in {20..100}; do
    timeout 0.2 bash -c "echo > /dev/tcp/127.0.0.1/$port" 2>/dev/null || true
done
```

---

## Complete Test Script

Save this as `test_all_attacks.sh`:

```bash
#!/bin/bash
WAF_URL="http://127.0.0.1:8081"

echo "Testing Application Layer WAF..."

# Good requests
echo "1. Good requests..."
curl -s "$WAF_URL/?q=hello" > /dev/null
curl -s "$WAF_URL/?q=products" > /dev/null

# SQL Injection
echo "2. SQL Injection..."
curl -s "$WAF_URL/?q=1%27%20OR%20%271%27%3D%271" > /dev/null
curl -s "$WAF_URL/?q=admin%27--" > /dev/null

# XSS
echo "3. XSS..."
curl -s "$WAF_URL/?q=%3Cscript%3Ealert%281%29%3C/script%3E" > /dev/null

# Command Injection
echo "4. Command Injection..."
curl -s "$WAF_URL/?q=%3B%20ls%20-la" > /dev/null

# Path Traversal
echo "5. Path Traversal..."
curl -s "$WAF_URL/?q=..%2F..%2F..%2Fetc%2Fpasswd" > /dev/null

echo "Done! Check dashboard: http://localhost:8080"
```

---

## Attack Type Summary

| Attack Type | Example | Detection Method |
|------------|---------|------------------|
| SQL Injection | `1' OR '1'='1` | Pattern matching + ML |
| XSS | `<script>alert(1)</script>` | Pattern matching + ML |
| Command Injection | `; ls -la` | Pattern matching |
| Path Traversal | `../../../etc/passwd` | Pattern matching |
| SSRF | `http://127.0.0.1:22` | Pattern matching |
| IDOR | `?user_id=0` | Pattern matching |
| Suspicious Ports | Port 23, 3389, 445 | Port list |
| Port Scanning | Multiple rapid connections | Heuristic |

---

**Use these samples for comprehensive testing and demonstration!**

