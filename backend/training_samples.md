# Training Data Samples Reference

## Good GET Request Samples

### Normal Search Queries
```
/?q=hello
/?q=world
/?q=test
/?q=search
/?q=products
/?q=about
/?q=contact
/?q=home
/?q=page
/?q=info
```

### Normal Product Pages
```
/product?id=1
/product?id=2
/item?product_id=123
/catalog?category=electronics&page=1
```

### Normal User Pages
```
/user?id=1
/profile?user_id=123
/account?uid=456
```

### Normal API Endpoints
```
/api/users
/api/products
/api/categories
/api/orders
/api/reviews
```

### Normal Pagination
```
/list?page=1&limit=10
/results?page=2&sort=name
```

### Normal Filters
```
/search?category=electronics
/search?price_min=100&price_max=500
/search?brand=samsung&rating=4
```

---

## Bad GET Request Samples

### SQL Injection - Basic
```
/?q=1' OR '1'='1
/?q=1' OR '1'='1--
/?q=1' OR '1'='1/*
/?q=admin'--
/?q=admin'/*
/?q=' OR 1=1--
/?q=' OR 'a'='a
/?q=1' OR '1'='1'--
```

### SQL Injection - UNION
```
/?q=1' UNION SELECT NULL--
/?q=1' UNION SELECT * FROM users--
/?q=' UNION SELECT password FROM users--
/?q=1' UNION SELECT 1,2,3--
/?q=' UNION SELECT username,password FROM users--
```

### SQL Injection - Time-based
```
/?q=1'; WAITFOR DELAY '00:00:05'--
/?q=1' OR SLEEP(5)--
/?q=1'; SELECT SLEEP(5)--
```

### SQL Injection - Boolean-based
```
/?q=1' AND 1=1--
/?q=1' AND 1=2--
/?q=1' AND 'a'='a
/?q=1' AND 'a'='b
```

### XSS - Basic
```
/?q=<script>alert(1)</script>
/?q=<script>alert('XSS')</script>
/?q=<img src=x onerror=alert(1)>
/?q=<svg onload=alert(1)>
/?q=<body onload=alert(1)>
/?q=<iframe src=javascript:alert(1)>
```

### XSS - Encoded
```
/?q=%3Cscript%3Ealert(1)%3C/script%3E
/?q=javascript:alert(1)
/?q=javascript:alert('XSS')
/?q=onerror=alert(1)
/?q=onclick=alert(1)
```

### XSS - Advanced
```
/?q=<script>eval(String.fromCharCode(97,108,101,114,116,40,49,41))</script>
/?q=<img src=x onerror=eval(atob('YWxlcnQoMSk='))>
```

### Command Injection
```
/?q=; ls -la
/?q=; cat /etc/passwd
/?q=; whoami
/?q=| cat /etc/passwd
/?q=&& cat /etc/passwd
/?q=`whoami`
/?q=$(whoami)
```

### Path Traversal
```
/?q=../../../etc/passwd
/?q=....//....//etc/passwd
/?q=..%2F..%2F..%2Fetc%2Fpasswd
/?q=/etc/passwd
/?q=..\\..\\..\\windows\\system32
```

### SSRF
```
/?q=http://127.0.0.1:22
/?q=http://localhost/admin
/?q=file:///etc/passwd
/?q=gopher://127.0.0.1:6379
/?q=dict://127.0.0.1:11211
```

### IDOR
```
/../user/0
/../admin/1
?user_id=0
?id=-1
?user=admin
?account=1
?uid=0
```

---

## Good POST Request Samples

### Normal JSON Payloads
```json
POST /api
Content-Type: application/json

{"name":"user123","email":"user@example.com"}
{"action":"search","query":"products"}
{"message":"Hello world","timestamp":"1234567890"}
{"username":"john","password":"SecurePass123"}
```

### Normal Form Data
```
POST /login
Content-Type: application/x-www-form-urlencoded

username=user123&password=password123
name=User&email=user@test.com&password=SecurePass123
```

### Normal API Calls
```json
POST /api/users
Content-Type: application/json

{"action":"create","data":{"name":"test"}}
```

---

## Bad POST Request Samples

### SQL Injection in POST
```
POST /login
Content-Type: application/x-www-form-urlencoded

username=admin' OR '1'='1&password=x
username=admin'--&password=test
username=' OR 1=1--&password=x
```

### SQL Injection in JSON
```json
POST /api
Content-Type: application/json

{"query":"1' OR '1'='1"}
{"query":"admin'--"}
{"query":"' UNION SELECT * FROM users--"}
```

### XSS in POST
```json
POST /api
Content-Type: application/json

{"message":"<script>alert(1)</script>"}
{"message":"<img src=x onerror=alert(1)>"}
{"message":"javascript:alert(1)"}
```

### Command Injection in POST
```json
POST /api
Content-Type: application/json

{"cmd":"; ls -la"}
{"cmd":"; cat /etc/passwd"}
{"cmd":"| whoami"}
{"cmd":"&& id"}
```

### Path Traversal in POST
```json
POST /api
Content-Type: application/json

{"file":"../../../etc/passwd"}
{"file":"....//....//etc/passwd"}
{"file":"/etc/passwd"}
```

### SSRF in POST
```json
POST /api
Content-Type: application/json

{"url":"http://127.0.0.1:22"}
{"url":"http://localhost/admin"}
{"url":"file:///etc/passwd"}
```

### Large Payloads (DoS)
```json
POST /api
Content-Type: application/json

{"data":"AAAA... (10000+ characters)"}
```

---

## Network Layer Training Samples

### Normal Traffic (ALLOWED)
- DNS queries: `ping 8.8.8.8`, `ping 1.1.1.1`
- HTTP requests: `curl http://example.com`
- HTTPS requests: `curl https://www.google.com`
- Normal ports: 80 (HTTP), 443 (HTTPS), 22 (SSH), 53 (DNS)

### Suspicious Ports (BLOCKED)
- Port 23 (Telnet)
- Port 3389 (RDP)
- Port 445 (SMB)
- Port 1433 (MSSQL)
- Port 1521 (Oracle)
- Port 3306 (MySQL)
- Port 5432 (PostgreSQL)
- Port 5900 (VNC)

### Port Scanning
- `nmap -p 1-100 127.0.0.1`
- Multiple rapid connections to different ports

---

## Attack Pattern Categories

### 1. SQL Injection
- **Basic**: `' OR '1'='1`, `admin'--`
- **UNION**: `' UNION SELECT * FROM users--`
- **Time-based**: `' OR SLEEP(5)--`
- **Boolean-based**: `' AND 1=1--`

### 2. Cross-Site Scripting (XSS)
- **Basic**: `<script>alert(1)</script>`
- **Event handlers**: `<img onerror=alert(1)>`
- **Encoded**: `%3Cscript%3Ealert(1)%3C/script%3E`
- **Advanced**: `eval(String.fromCharCode(...))`

### 3. Command Injection
- **Basic**: `; ls -la`
- **Pipes**: `| cat /etc/passwd`
- **Backticks**: `` `whoami` ``
- **Substitution**: `$(whoami)`

### 4. Path Traversal
- **Basic**: `../../../etc/passwd`
- **Encoded**: `..%2F..%2Fetc%2Fpasswd`
- **Double slashes**: `....//....//etc/passwd`

### 5. SSRF (Server-Side Request Forgery)
- **Localhost**: `http://127.0.0.1:22`
- **File protocol**: `file:///etc/passwd`
- **Internal services**: `gopher://127.0.0.1:6379`

### 6. IDOR (Insecure Direct Object Reference)
- **Zero/negative IDs**: `?id=0`, `?id=-1`
- **Path manipulation**: `/../user/0`
- **Admin access**: `?user=admin`

---

## Training Statistics

After running `generate_training_data.sh`, you should have:

- **Good GET requests**: 100+
- **Bad GET requests**: 100+
- **Good POST requests**: 100+
- **Bad POST requests**: 50+
- **Network allowed packets**: 100+
- **Network blocked packets**: 10+

Total training samples: **450+**

---

## Usage

```bash
# Generate all training data
cd ~/Capstone-Project/backend
chmod +x generate_training_data.sh
./generate_training_data.sh

# Verify data
wc -l Data_Collection/Good_req.csv
wc -l Data_Collection/Bad_req.csv
wc -l benign_payloads.csv
wc -l malicious_payloads.csv
wc -l network_allowed.csv
wc -l network_blocked.csv
```

